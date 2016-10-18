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
            reactor = ::Libuv::Reactor.current
            opts[:thread] ||= reactor if reactor && reactor.running?
            @connection = Connection.new(**options)
            connect

            # This obtains the connections reactor
            @reactor = reactor

            # clean up the connection once this object is garbage collected
            ObjectSpace.define_finalizer( self, self.class.finalize(@connection) )
        end


        attr_reader :connection
        def_delegators :@connection, :bucket, :reactor


        def get(*keys, extended: false, **opts)
            if keys.length == 1
                result @connection.get(keys[0], **opts).then do |result|
                    extended ? result : result.value
                end
            else
                promises = keys.collect { |key|
                    @connection.get(key, **opts)
                }
                result @reactor.all(promises).then do |results|
                    if extended
                        results
                    else
                        results.collect { |resp| resp.value }
                    end
                end
            end
        end

        AddDefaults = {operation: :add}.freeze
        def add(key, value, **opts)
            result @connection.store(key, value, **AddDefaults.merge(opts))
        end

        def set(key, value, **opts)
            # default operation is set
            result @connection.add(key, value, **opts)
        end

        ReplaceDefaults = {operation: :replace}.freeze
        def replace(key, value, **opts)
            result @connection.add(key, value, **ReplaceDefaults.merge(opts))
        end

        AppendDefaults = {operation: :append}.freeze
        def append(key, value, **opts)
            result @connection.add(key, value, **AppendDefaults.merge(opts))
        end

        PrependDefaults = {operation: :prepend}.freeze
        def prepend(key, value, **opts)
            result @connection.add(key, value, **PrependDefaults.merge(opts))
        end

        def incr(key, by = 1, create: false, **opts)
            opts[:delta] ||= by
            opts[:initial] = 0 if create
            result @connection.counter(key, **opts)
        end

        def delete(key, **opts)
            result @connection.remove(key, **opts)
        end

        def flush
            result @connection.flush
        end

        def design_docs(**opts)
            DesignDocs.new(self, @connection, method(:result), **opts)
        end

        def query_view(design, view, **args, &blk)
            # TODO::
        end


        protected


        def result(promise)
            current = ::Libuv::Reactor.current
            if current && current.running?
                co @connection.connect
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
