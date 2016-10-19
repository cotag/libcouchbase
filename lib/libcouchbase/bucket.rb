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
                # We don't need to start a reactor lets use the regular helper
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
