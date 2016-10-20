# frozen_string_literal: true, encoding: ASCII-8BIT

require 'forwardable'
require 'thread'


module Libcouchbase
    class Bucket
        extend Forwardable

        # Finalizer done right
        # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
        def self.finalize(connection)
            proc { connection.destroy }
        end

        def initialize(**options)
            @connection = Connection.new(**options)
            connect

            # This obtains the connections reactor
            @reactor = reactor

            # clean up the connection once this object is garbage collected
            ObjectSpace.define_finalizer( self, self.class.finalize(@connection) )
        end


        attr_reader :connection
        def_delegators :@connection, :bucket, :reactor


        def get(*keys, extended: false, async: false, **opts)
            if keys.length == 1
                result @connection.get(keys[0], **opts).then(proc { |resp|
                    extended ? resp : resp.value
                }), async
            else
                promises = keys.collect { |key|
                    @connection.get(key, **opts)
                }
                result @reactor.all(promises).then(proc { |results|
                    if extended
                        results
                    else
                        results.collect { |resp| resp.value }
                    end
                }), async
            end
        end
        alias_method :[], :get

        AddDefaults = {operation: :add}.freeze
        def add(key, value, async: false, **opts)
            result @connection.store(key, value, **AddDefaults.merge(opts)), async
        end

        def set(key, value, async: false, **opts)
            # default operation is set
            result @connection.store(key, value, **opts), async
        end
        alias_method :[]=, :set

        ReplaceDefaults = {operation: :replace}.freeze
        def replace(key, value, async: false, **opts)
            result @connection.store(key, value, **ReplaceDefaults.merge(opts)), async
        end

        AppendDefaults = {operation: :append}.freeze
        def append(key, value, async: false, **opts)
            result @connection.store(key, value, **AppendDefaults.merge(opts)), async
        end

        PrependDefaults = {operation: :prepend}.freeze
        def prepend(key, value, async: false, **opts)
            result @connection.store(key, value, **PrependDefaults.merge(opts)), async
        end

        def incr(key, by = 1, create: false, async: false, **opts)
            opts[:delta] ||= by
            opts[:initial] = 0 if create
            result @connection.counter(key, **opts), async
        end

        def delete(key, async: false, **opts)
            result @connection.remove(key, **opts), async
        end

        # Delete contents of the bucket
        #
        # @see http://docs.couchbase.com/admin/admin/REST/rest-bucket-flush.html
        #
        # @raise [Libcouchbase::Error::HttpError] in case of an error is
        #   encountered.
        #
        # @return [Libcouchbase::Response]
        #
        # @example Simple flush the bucket
        #   c.flush
        def flush(async: false)
            result @connection.flush, async
        end

        def design_docs(**opts)
            DesignDocs.new(self, @connection, method(:result), **opts)
        end

        ViewDefaults = {
            on_error: :stop,
            stale: false
        }
        ViewDefaultRowModifier = proc { |entry| entry.value }
        def view(design, view, extended: false, **opts, &row_modifier)
            view = @connection.query_view(design, view, **ViewDefaults.merge(opts))

            unless block_given? || extended
                row_modifier = ViewDefaultRowModifier
            end
            current = ::Libuv::Reactor.current

            if current && current.running?
                ResultsLibuv.new(view, current, &row_modifier)
            elsif Object.const_defined?(:EventMachine) && EM.reactor_thread?
                # TODO::
            else
                ResultsNative.new(view, &row_modifier)
            end
        end

        # http://docs.couchbase.com/admin/admin/REST/rest-ddocs-delete.html
        def save_design_doc(data, id = nil)
            attrs = case data
            when String
                JSON.parse(data, Connection::DECODE_OPTIONS)
            when IO
                JSON.parse(data.read, Connection::DECODE_OPTIONS)
            when Hash
                data
            else
                raise ArgumentError, "Document should be Hash, String or IO instance"
            end
            attrs[:language] ||= :javascript

            id ||= attrs.delete(:_id)
            id = id.sub(/^_design\//, '')
            
            result @connection.http("/_design/#{id}",
                method: :put,
                body: attrs,
                type: :view
            )
        end

        # http://docs.couchbase.com/admin/admin/REST/rest-ddocs-create.html
        def delete_design_doc(id, rev = nil)
            id = id.sub(/^_design\//, '')
            rev = "?rev=#{rev}" if rev
            result @connection.http("/_design/#{id}#{rev}", method: :delete, type: :view)
        end

        # Compare and swap value.
        #
        # Reads a key's value from the server and yields it to a block. Replaces
        # the key's value with the result of the block as long as the key hasn't
        # been updated in the meantime, otherwise raises
        # {Libcouchbase::Error::KeyExists}.
        #
        # Setting the +:retry+ option to a positive number will cause this method
        # to rescue the {Libcouchbase::Error::KeyExists} error that happens when
        # an update collision is detected, and automatically get a fresh copy
        # of the value and retry the block. This will repeat as long as there
        # continues to be conflicts, up to the maximum number of retries specified.
        #
        # @param [String, Symbol] key
        #
        # @param [Hash] options the options for "swap" part
        # @option options [Fixnum] :retry (0) maximum number of times to autmatically retry upon update collision
        #
        # @yieldparam [Object] value existing value
        # @yieldreturn [Object] new value.
        #
        # @raise [Couchbase::Error::KeyExists] if the key was updated before the the
        #   code in block has been completed (the CAS value has been changed).
        # @raise [ArgumentError] if the block is missing
        #
        # @example Implement append to JSON encoded value
        #
        #     c.set("foo", {"bar" => 1})
        #     c.cas("foo") do |val|
        #       val["baz"] = 2
        #       val
        #     end
        #     c.get("foo")      #=> {"bar" => 1, "baz" => 2}
        #
        # @return [Libcouchbase::Response] the transaction details including the new CAS
        def compare_and_swap(key, **opts)
            retries = opts.delete(:retry) || 0
            begin
                current = result(@connection.get(key))
                new_value = yield current.value, opts
                opts[:cas] = current.cas

                set(key, new_value, **opts)
            rescue Libcouchbase::Error::KeyExists
                retries -= 1
                retry if retries >= 0
                raise
            end
        end
        alias_method :cas, :compare_and_swap


        protected


        def result(promise, async = false)
            return promise if async

            current = ::Libuv::Reactor.current
            if current && current.running?
                co promise
            elsif Object.const_defined?(:EventMachine) && EM.reactor_thread?
                # TODO::
            else
                request = Mutex.new
                result = ConditionVariable.new
                error = nil
                response = nil

                request.synchronize {
                    @connection.reactor.next_tick do
                        begin
                            response = co(promise)
                        rescue => e
                            error = e
                        end

                        # Odds are we won't actually block here
                        request.synchronize {
                            result.signal
                        }
                    end
                    result.wait(request)
                }

                raise error if error
                response
            end
        end

        def connect
            if @connection.reactor.running?
                # We don't need to start a reactor so we use the regular helper
                result(@connection.connect)
            elsif Object.const_defined?(:EventMachine) && EM.reactor_thread?
                # TODO::
            else
                start_reactor_and_connect
            end
        end

        # This blocks on the current thread
        def start_reactor_and_connect
            connecting = Mutex.new
            result = ConditionVariable.new
            error = nil

            connecting.synchronize {
                Thread.new do
                    @connection.reactor.run do
                        begin
                            co @connection.connect
                        rescue => e
                            error = e
                        end

                        # Odds are we won't actually block here
                        connecting.synchronize {
                            result.signal
                        }
                    end
                end
                result.wait(connecting)
            }

            raise error if error
        end

        def start_reactor_and_em_connect
            
        end
    end
end
