# frozen_string_literal: true, encoding: ASCII-8BIT

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

        def get_count(metadata)
            metadata[:total_rows]
        end

        def perform(**options, &blk)
            raise 'not connected' unless @connection.handle
            raise 'query already in progress' if @cmd
            raise 'callback required' unless block_given?

            options = @options.merge(options)
            # We should never exceed the users results limit
            orig_limit = @options[:limit]
            limit = options[:limit]
            if orig_limit && limit
                options[:limit] = orig_limit if limit > orig_limit
            end

            pairs = []
            options.each { |key, val|
                if key.to_s.include?('key') && val[0] != "["
                    pairs << "#{key}=#{[val].to_json[1...-1]}"
                else
                    pairs << "#{key}=#{val}"
                end
            }
            opts = pairs.join('&')

            @reactor.schedule {
                @error = nil
                @callback = blk

                @cmd = Ext::CMDVIEWQUERY.new
                Ext.view_query_initcmd(@cmd, @design.to_s, @view.to_s, opts, @connection.get_callback(:viewquery_callback))
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
            cas = row[:cas]
            emitted = row[:value].read_string(row[:nvalue]) if row[:nvalue] > 0
            geometry = row[:geometry].read_string(row[:ngeometry]) if row[:ngeometry] > 0
            doc_id = row[:docid].read_string(row[:ndocid]) if row[:ndocid] > 0

            meta = {
                emitted: emitted,
                geometry: geometry,
                key: key
            }

            resp = Response.new(:viewquery_callback, doc_id, cas)
            resp.metadata = meta

            # check for included document here
            if @include_docs && row[:docresp]
                doc = row[:docresp]
                raw_string = doc[:value].read_string(doc[:nvalue])
                resp.value, meta[:format] = @connection.parse_document(raw_string, flags: doc[:itmflags])
                meta[:flags] = doc[:itmflags]
            end

            @callback.call(false, resp)
        rescue => e
            @error = e
        end

        def received_final(metadata)
            @connection.requests.delete(@cmd.to_ptr.address)
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
            @error = obj
            received_final(nil)
        end

        # We don't ever actually cancel a request here.
        # There is an API however it indicates that @connection.handle might be destroyed
        # Testing also indicated that @connection.handle was destroyed with seg faults
        def cancel
            @error = :cancelled
        end
    end
end
