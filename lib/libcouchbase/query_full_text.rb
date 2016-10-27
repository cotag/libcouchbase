# frozen_string_literal: true, encoding: ASCII-8BIT

module Libcouchbase
    class QueryFullText
        def initialize(connection, reactor, **opts)
            @connection = connection
            @reactor = reactor

            @query = opts
            @query_text = JSON.generate(opts)
            @query_cstr = FFI::MemoryPointer.from_string(@query_text)
            @request_handle = FFI::MemoryPointer.new :pointer, 1
        end

        attr_reader :options, :query, :connection

        def get_count(metadata)
            metadata[:total_hits]
        end

        def perform(**options, &blk)
            raise 'not connected' unless @connection.handle
            raise 'query already in progress' if @cmd
            raise 'callback required' unless block_given?

            @reactor.schedule {
                @error = nil
                @callback = blk

                @cmd = Ext::CMDFTS.new
                @cmd[:query] = @query_cstr
                @cmd[:nquery] = @query_text.bytesize
                @cmd[:callback] = @connection.get_callback(:fts_callback)
                @cmd[:handle] = @request_handle

                pointer = @cmd.to_ptr
                @connection.requests[pointer.address] = self

                err = Ext.fts_query(@connection.handle, pointer, @cmd)
                if err != :success
                    error(Error.lookup(err).new('full text search not scheduled'))
                end
            }
        end

        def received(row)
            return if @error

            resp = Response.new(:fts_callback, @query)
            resp.value = row

            @callback.call(false, resp)
        rescue => e
            @error = e
        end

        def received_final(metadata)
            @cmd = nil

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
            @cmd = nil
            @callback.call(:error, obj)
        end

        def cancel
            @error = :cancelled
            @reactor.schedule {
                if @connection.handle && @cmd
                    Ext.fts_cancel(@connection.handle, @handle_ptr.get_pointer(0))
                    received_final(nil)
                end
            }
        end
    end
end
