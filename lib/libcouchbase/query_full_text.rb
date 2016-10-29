# frozen_string_literal: true, encoding: ASCII-8BIT

module Libcouchbase
    class QueryFullText
        def initialize(connection, reactor, include_docs: true, **opts)
            @connection = connection
            @reactor = reactor

            @options = opts
            @include_docs = include_docs
            @request_handle = FFI::MemoryPointer.new :pointer, 1
        end

        attr_reader :options, :connection
        attr_accessor :include_docs

        def index
            @options[:indexName]
        end

        def get_count(metadata)
            metadata[:total_hits]
        end

        def perform(limit: nil, **options, &blk)
            raise 'not connected' unless @connection.handle
            raise 'query already in progress' if @query_cstr
            raise 'callback required' unless block_given?

            # customise the size based on the request being made
            orig_size = @options[:size] || 10 # 10 is the couchbase default
            new_size = limit || orig_size
            begin
                @options[:size] = new_size if orig_size > new_size
                @query_text = JSON.generate(@options)
                @query_cstr = FFI::MemoryPointer.from_string(@query_text)
            rescue
                @query_cstr = nil
                @query_text = nil
                raise
            ensure
                @options[:size] = orig_size
            end

            @reactor.schedule {
                @error = nil
                @doc_count = 0
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

        # Example Row:
        # {:index=>"default_3f230bec977a680e_b7ff6b68", :id=>"dep_1-18", :score=>1.3540229098345296,
        #  :locations=>{:class_name=>{:toshiba=>[{:pos=>1, :start=>2, :end=>9, :array_positions=>nil}]},
        #  :name=>{:toshiba=>[{:pos=>1, :start=>0, :end=>7, :array_positions=>nil}]}}}
        def received(row)
            return if @error

            resp = Response.new(:fts_callback, row[:id])
            resp.metadata = row

            # TODO:: this could cause results to be returned out of order
            if @include_docs
                @doc_count += 1
                doc = co @connection.get(resp.key)
                resp.value = doc.value
                resp.cas = doc.cas
                resp.metadata.merge! doc.metadata
            end

            @callback.call(false, resp)
        rescue => e
            @error = e
        ensure
            if @include_docs
                @doc_count -= 1
                process_final if @metadata && @doc_count == 0
            end
        end

        # Example metadata
        # {:status=>{:total=>2, :failed=>0, :successful=>2}, :request=>{:query=>{:query=>"Toshiba", :boost=>1},
        #  :size=>10, :from=>0, :highlight=>nil, :fields=>nil, :facets=>nil, :explain=>false}, :hits=>[],
        #  :total_hits=>4, :max_score=>1.6405488681166451, :took=>10182765, :facets=>{}}
        def received_final(metadata)
            @metadata = metadata
            process_final unless @doc_count > 0
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


        protected


        def process_final
            metadata = @metadata
            @metadata = nil
            @cmd = nil
            @query_cstr = nil
            @query_text = nil

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
    end
end
