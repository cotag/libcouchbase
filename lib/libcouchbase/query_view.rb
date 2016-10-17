
module Libcouchbase
    class QueryView
        # Set this flag to execute an actual get with each response
        F_INCLUDE_DOCS = 1 << 16

        # Set this flag to only parse the top level row, and not its constituent
        # parts. Note this is incompatible with `F_INCLUDE_DOCS`
        F_NOROWPARSE = 1 << 17

        # This view is spatial. Modifies how the final view path will be constructed
        F_SPATIAL = 1 << 18


        def initialize(connection, reactor, design, view, **opts)
            @connection = connection
            @reactor = reactor

            @design = design
            @view = view
            @options = opts

            @include_docs = true
            @is_spatial = false
        end

        attr_reader :options, :design, :view, :connection
        attr_accessor :include_docs, :is_spatial

        def perform(**options, &blk)
            raise 'not connected' unless @connection.handle
            raise 'query already in progress' if @cmd

            options = @options.merge(options)
            pairs = []
            @options.each { |key, val| pairs << "#{key}=#{val}" }
            opts = pairs.join('&')

            @error = nil

            @reactor.schedule {
                @callback = blk
                @cmd = Ext::CMDVIEWQUERY.new
                Ext.view_query_initcmd(@cmd, @design, @view, opts, @connection.get_callback(:viewquery_callback))
                @cmd[:cmdflags] |= F_INCLUDE_DOCS if include_docs
                @cmd[:cmdflags] |= F_SPATIAL if is_spatial

                pointer = @cmd.to_ptr

                @connection.requests[pointer.address] = self
                err = Ext.view_query(@connection.handle, pointer, @cmd)
                if err != :success
                    error(Error.lookup(err).new('view request not scheduled'))
                end
            }
        end

        def received(row)
            return if @error

            key = row[:key].read_string(row[:nkey])
            meta = {
                emitted: row[:value],
                geometry: row[:geometry]
            }
            cas = row[:cas]

            resp = Connection::Response.new(:viewquery_callback, key, cas)
            resp.metadata = meta

            # check for included document here
            if @include_docs && row[:docresp]
                doc = row[:docresp]
                resp.value = JSON.parse("[#{doc[:value].read_string(doc[:nvalue])}]", Connection::DECODE_OPTIONS)[0]
            end

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
                    @callback.call(:error, obj)
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
        end
    end
end
