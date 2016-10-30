# frozen_string_literal: true, encoding: ASCII-8BIT

module Libcouchbase
    class QueryN1QL
        N1P_QUERY_STATEMENT = 1


        def initialize(connection, reactor, n1ql, **opts)
            @connection = connection
            @reactor = reactor

            @n1ql = n1ql
            @request_handle = FFI::MemoryPointer.new :pointer, 1
        end


        attr_reader :connection, :n1ql


        def get_count(metadata)
            metadata[:metrics][:resultCount]
        end

        def perform(limit: nil, **options, &blk)
            raise 'not connected' unless @connection.handle
            raise 'query already in progress' if @query_text
            raise 'callback required' unless block_given?

            # customise the size based on the request being made
            orig_limit = @n1ql.limit
            begin
                if orig_limit && limit
                    @n1ql.limit = limit if orig_limit > limit
                end
                @query_text = @n1ql.to_s
            rescue
                @query_text = nil
                raise
            ensure
                @n1ql.limit = orig_limit
            end

            @reactor.schedule {
                @error = nil
                @callback = blk

                @cmd = Ext::CMDN1QL.new
                @params = Ext.n1p_new
                err = Ext.n1p_setquery(@params, @query_text, @query_text.bytesize, N1P_QUERY_STATEMENT)
                if err == :success

                    err = Ext.n1p_mkcmd(@params, @cmd)
                    if err == :success

                        pointer = @cmd.to_ptr
                        @connection.requests[pointer.address] = self

                        @cmd[:callback] = @connection.get_callback(:n1ql_callback)
                        @cmd[:handle] = @request_handle

                        err = Ext.n1ql_query(@connection.handle, pointer, @cmd)
                        if err != :success
                            error(Error.lookup(err).new('full text search not scheduled'))
                        end
                    else
                        error(Error.lookup(err).new('failed to build full text search command'))
                    end
                else
                    error(Error.lookup(err).new('failed to build full text search query structure'))
                end
            }
        end

        # Row is JSON value representing the result
        def received(row)
            return if @error
            @callback.call(false, row)
        rescue => e
            @error = e
            cancel
        end

        # Example metadata
        # {:requestID=>"36162fce-ef39-4821-bf03-449e4073185d", :signature=>{:*=>"*"}, :results=>[], :status=>"success",
        #  :metrics=>{:elapsedTime=>"15.298243ms", :executionTime=>"15.256975ms", :resultCount=>12, :resultSize=>8964}}
        def received_final(metadata)
            @query_text = nil

            @connection.requests.delete(@cmd.to_ptr.address)
            @cmd = nil

            Ext.n1p_free(@params)
            @params = nil

            if @error
                if @error == :cancelled
                    @callback.call(:final, metadata)
                else
                    @callback.call(:error, @error)
                end
            else
                @callback.call(:final, metadata)
            end
        end

        def error(obj)
            @error = obj
            received_final(nil)
        end

        def cancel
            @error = :cancelled unless @error
            @reactor.schedule {
                if @connection.handle && @cmd
                    Ext.n1ql_cancel(@connection.handle, @handle_ptr.get_pointer(0))
                    received_final(nil)
                end
            }
        end
    end
end
