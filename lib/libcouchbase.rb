# frozen_string_literal: true, encoding: ASCII-8BIT


require 'libcouchbase/callbacks'
require 'libcouchbase/ext/libcouchbase_libuv'


module Libcouchbase
    class Connection
        include Callbacks
        define_callback function: :bootstrap_callback, params: [:pointer, Ext::ErrorT.native_type], ret_val: :void


        def initialize(hosts: 'localhost', bucket: 'default', password: nil, callback: nil, thread: nil, **opts, &blk)
            @on_bootstrap = callback || blk

            # build host string http://docs.couchbase.com/sdk-api/couchbase-c-client-2.5.6/group__lcb-init.html
            hosts = hosts.join(',') if hosts.is_a?(Array)
            connstr = "couchbase://#{hosts}/#{bucket}"
            connstr = "#{connstr}?#{opts.map { |k, v| "#{k}=#{v}" }.join('&') }" unless opts.empty?

            # Configure the event loop settings
            @io_opts = Ext::UVOptions.new
            @io_opts[:version] = 0
            @io_opts[:loop] = (thread || reactor).handle
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

        def connect
            raise 'already connected' if @handle

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
            # TODO:
=begin
            lcb_set_cookie(bucket->handle, bucket);
            (void)lcb_set_bootstrap_callback(bucket->handle, bootstrap_callback);
            (void)lcb_set_store_callback(bucket->handle, cb_storage_callback);
            (void)lcb_set_get_callback(bucket->handle, cb_get_callback);
            (void)lcb_set_touch_callback(bucket->handle, cb_touch_callback);
            (void)lcb_set_remove_callback(bucket->handle, cb_delete_callback);
            (void)lcb_set_stat_callback(bucket->handle, cb_stat_callback);
            (void)lcb_set_arithmetic_callback(bucket->handle, cb_arithmetic_callback);
            (void)lcb_set_version_callback(bucket->handle, cb_version_callback);
            (void)lcb_set_http_complete_callback(bucket->handle, cb_http_complete_callback);
            (void)lcb_set_http_data_callback(bucket->handle, cb_http_data_callback);
            (void)lcb_set_observe_callback(bucket->handle, cb_observe_callback);
            (void)lcb_set_unlock_callback(bucket->handle, cb_unlock_callback);

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


        private


        def handle_destroyed
            @handle = nil
            cleanup_callbacks
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
    end
end
