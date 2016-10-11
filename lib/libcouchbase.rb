# frozen_string_literal: true, encoding: ASCII-8BIT


require 'libcouchbase/callbacks'
require 'libcouchbase/ext/libcouchbase_libuv'


module Libcouchbase
    class Connection
        include Callbacks
        define_callback function: :bootstrap_callback, params: [:pointer, Ext::ErrorT.native_type]
        
        # This is common for all standard request types
        define_callback function: :callback_get,       params: [:pointer, :int, :pointer]
        define_callback function: :callback_store,     params: [:pointer, :int, :pointer]
        define_callback function: :callback_counter,   params: [:pointer, :int, :pointer]
        define_callback function: :callback_touch,     params: [:pointer, :int, :pointer]
        define_callback function: :callback_remove,    params: [:pointer, :int, :pointer]
        define_callback function: :callback_stats,     params: [:pointer, :int, :pointer]

        # These are passed with the request
        define_callback function: :viewquery_callback, params: [:pointer, :int, :pointer]
        define_callback function: :n1ql_callback,      params: [:pointer, :int, :pointer]
        define_callback function: :fts_callback,       params: [:pointer, :int, :pointer]
        define_callback function: :timings_callback,   params: [:pointer, :pointer, Ext::TimeunitT.native_type, :uint, :uint, :uint, :uint]


        Request  = Struct.new(:cmd, :defer, :key, :value)
        Response = Struct.new(:callback, :key, :cas, :version, :value)


        def initialize(hosts: 'localhost', bucket: 'default', password: nil, thread: nil, **opts)
            # build host string http://docs.couchbase.com/sdk-api/couchbase-c-client-2.5.6/group__lcb-init.html
            hosts = hosts.join(',') if hosts.is_a?(Array)
            connstr = "couchbase://#{hosts}/#{bucket}"
            connstr = "#{connstr}?#{opts.map { |k, v| "#{k}=#{v}" }.join('&') }" unless opts.empty?

            # Configure the event loop settings
            @reactor = thread || reactor
            @io_opts = Ext::UVOptions.new
            @io_opts[:version] = 0
            @io_opts[:loop] = @reactor.handle
            @io_opts[:start_stop_noop] = 1 # We want to control the start and stopping of the loop
            @io_ptr = FFI::MemoryPointer.new :pointer, 1

            err = Ext.create_libuv_io_opts(0, @io_ptr, @io_opts)
            if err != :success
                raise "failed to allocate IO plugin: #{err} (#{Ext::ErrorT[err]})"
            end

            # Configure the connection to the database
            @connection = Ext::CreateSt.new
            @connection[:version] = 3
            @connection[:v][:v3][:connstr] = FFI::MemoryPointer.from_string(connstr)
            @connection[:v][:v3][:passwd]  = FFI::MemoryPointer.from_string(password) if password
            @connection[:v][:v3][:io]      = @io_ptr.get_pointer(0)
            @handle_ptr = FFI::MemoryPointer.new :pointer, 1
        end

        def connect(callback = nil, &blk)
            raise 'already connected' if @handle
            @on_bootstrap = callback || blk
            @request = 0
            @requests = {}

            # Create a library handle
            #  the create call allocates the memory and updates our pointer
            err = Ext.create(@handle_ptr, @connection)
            if err != :success
                raise "failed to allocate instance: #{err} (#{Ext::ErrorT[err]})"
            end

            # We extract the pointer and create the handle structure
            @ref = @handle_ptr.get_pointer(0).address
            @handle = Ext::T.new @handle_ptr.get_pointer(0)

            # Register the callbacks we are interested in
            Ext.set_bootstrap_callback(@handle, callback(:bootstrap_callback))

            Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_get],     callback(:callback_get))
            Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_store],   callback(:callback_store))
            Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_counter], callback(:callback_counter))
            Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_touch],   callback(:callback_touch))
            Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_remove],  callback(:callback_remove))
            Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_stats],   callback(:callback_stats))

=begin
            TODO:: configure timeouts

            lcb_cntl(bucket->handle, (bucket->timeout > 0) ? LCB_CNTL_SET : LCB_CNTL_GET,
             LCB_CNTL_OP_TIMEOUT, &bucket->timeout);
=end
            # Connect to the database
            err = Ext.connect(@handle)
            if err != :success
                destroy
                raise "failed to connect: #{err} (#{Ext::ErrorT[err]})"
            end

            self
        end

        def destroy
            return self unless @handle
            Ext.destroy(@handle)
            handle_destroyed
            self
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-store.html#ga9ac7d6294826937f4f052fde15351091
        def store(key, value, defer: nil, operation: :add, **opts)
            raise 'not connected' unless @handle
            defer ||= @reactor.defer

            cmd = Ext::CMDSTORE.new
            cmd_set_key(cmd, key)
            cmd_set_value(cmd, value)
            cmd[:operation] = operation

            # TODO:: supply options expire_in and expire_at
            # We'll convert them to the appropriate couchbase value here

            pointer = cmd.to_ptr
            @requests[pointer.address] = Request.new(cmd, defer, key, value)
            Ext.store3(@handle, pointer, cmd)

            defer.promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-get.html#gab8fabeba69124b43308c49ab2d2488b7
        def get(key, defer: nil, **opts)
            raise 'not connected' unless @handle
            defer ||= @reactor.defer

            cmd = Ext::CMDGET.new
            cmd_set_key(cmd, key)

            # TODO:: provide locking options

            pointer = cmd.to_ptr
            @requests[pointer.address] = Request.new(cmd, defer, key)
            Ext.get3(@handle, pointer, cmd)

            defer.promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-remove.html#gae66ff9c2d8019127e7b8fa6f27dcc708
        def remove(key, defer: nil, **opts)
            raise 'not connected' unless @handle
            defer ||= @reactor.defer

            cmd = Ext::CMDBASE.new
            cmd_set_key(cmd, key)

            pointer = cmd.to_ptr
            @requests[pointer.address] = Request.new(cmd, defer, key)
            Ext.remove3(@handle, pointer, cmd)

            defer.promise
        end


        private


        def cmd_set_key(cmd, key)
            cmd[:key][:type] = :kv_copy
            str = FFI::MemoryPointer.from_string(key)
            str.autorelease = true
            cmd[:key][:contig][:bytes] = str
            cmd[:key][:contig][:nbytes] = key.bytesize
            cmd
        end

        def cmd_set_value(cmd, value)
            cmd[:value][:vtype] = :kv_copy
            str = FFI::MemoryPointer.from_string(value)
            str.autorelease = true
            cmd[:value][:u_buf][:contig][:bytes] = str
            cmd[:value][:u_buf][:contig][:nbytes] = value.bytesize
        end

        def handle_destroyed
            @handle = nil
            cleanup_callbacks
            reqs = @requests
            @request = nil
            @requests = nil

            reqs.each_value do |req|
                req[0].reject(:disconnected)
            end
        end


        def bootstrap_callback(handle, error_code)
            success = error_code == Ext::ErrorT[:success]
            error_name = Ext::ErrorT[error_code]

            # Library cleans itself up
            handle_destroyed unless success

            if @on_bootstrap
                cb = @on_bootstrap
                @on_bootstrap = nil
                cb.call(success, error_name, error_code, self)
            end
        end

        # ==================
        # Response Callbacks
        # ==================
        def callback_get(handle, type, response)
            resp = Ext::RESPGET.new response
            req = @requests.delete(resp[:cookie].address)
            resp_callback_common(req, resp, :callback_get) do |cb|
                Response.new(cb, req.key, resp[:cas], resp[:version], resp[:value].read_string(resp[:nvalue]))
            end
        end

        def callback_store(handle, type, response)
            resp = Ext::RESPSTORE.new response
            req = @requests.delete(resp[:cookie].address)
            resp_callback_common(req, resp, :callback_store) do |cb|
                Response.new(cb, req.key, resp[:cas], resp[:version], req.value)
            end
        end

        def callback_counter(handle, type, response)
            puts "received callback of type #{Ext::CALLBACKTYPE[type]}"
        end

        def callback_touch(handle, type, response)
            puts "received callback of type #{Ext::CALLBACKTYPE[type]}"
        end

        def callback_remove(handle, type, response)
            resp = Ext::RESPSTORE.new response
            req = @requests.delete(resp[:cookie].address)
            resp_callback_common(req, resp, :callback_remove) do |cb|
                Response.new(cb, req.key, resp[:cas], resp[:version])
            end
        end

        def callback_stats(handle, type, response)
            puts "received callback of type #{Ext::CALLBACKTYPE[type]}"
        end

        def resp_callback_common(req, resp, callback)
            if req
                if resp[:rc] == :success
                    req.defer.resolve(yield(callback))
                else
                    req.defer.reject(resp[:rc])
                end
            else
                @reactor.log IOError.new('received response callback for unknown request')
            end
        end
        # ======================
        # End Response Callbacks
        # ======================


        def viewquery_callback(handle, type, row)

        end

        def n1ql_callback(handle, type, row)

        end

        # Full text search
        def fts_callback(handle, type, row)

        end

        def timings_callback(handle, cookie, time, min, max, total, maxtotal)

        end
    end
end
