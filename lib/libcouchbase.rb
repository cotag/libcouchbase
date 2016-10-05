# frozen_string_literal: true, encoding: ASCII-8BIT


require 'libcouchbase/callbacks'
require 'libcouchbase/ext/libcouchbase'


module Libcouchbase
    class Connection
        include Callbacks
        define_callback function: :bootstrap_callback, params: [:pointer, Ext::ErrorT.native_type], ret_val: :void
        define_callback function: :destroy_callback,   params: [:pointer], ret_val: :void


        def initialize(hosts: 'localhost', bucket: 'default', password: nil, callback: nil, **opts, &blk)
            @on_bootstrap = callback || blk

            # build host string http://docs.couchbase.com/sdk-api/couchbase-c-client-2.5.6/group__lcb-init.html
            hosts = hosts.join(',') if hosts.is_a?(Array)
            connstr = "couchbase://#{hosts}/#{bucket}"
            connstr = "#{connstr}?#{opts.map { |k, v| "#{k}=#{v}" }.join('&') }" unless opts.empty?

            @handle_ptr = FFI::MemoryPointer.new :pointer, 1
            @options = Ext::CreateSt.new
            @options[:version] = 3
            @options[:v][:v3][:connstr] = FFI::MemoryPointer.from_string(connstr)
            @options[:v][:v3][:passwd] =  FFI::MemoryPointer.from_string(password) if password

            # Create a library handle
            #  the create call allocates the memory and updates our pointer
            err = Ext.create(@handle_ptr, @options)
            if err != :success
                raise "failed to allocate instance: #{err} (#{Ext::ErrorT[err]})"
            end

            # We extract the pointer and create the dummy handle structure
            @ref = @handle_ptr.get_pointer(0).address
            @handle = Ext::T.new @handle_ptr.get_pointer(0)
            #Ext.set_bootstrap_callback(@handle, callback(:bootstrap_callback))
            #Ext.set_destroy_callback(@handle, callback(:destroy_callback))

            err = Ext.connect(@handle)
            if err != :success
                destroy
                raise "failed to connect: #{err} (#{Ext::ErrorT[err]})"
            end

            Ext.wait(@handle)

            err = Ext.get_bootstrap_status(@handle)
            if err != :success
                raise "couldn't bootstrap from cluster: #{err} (#{Ext::ErrorT[err]})"
            end

            @on_bootstrap.call(true)

            Ext.destroy(@handle)

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
        end

        def destroy(callback = nil, &blk)
            @on_destroy = callback || blk
            Ext.destroy(@handle)
        end


        private


        def bootstrap_callback(handle, error)
            sucess = error == Ext::ErrorT[:success]
            if @on_bootstrap
                cb = @on_bootstrap
                @on_bootstrap = nil
                cb.call(sucess, self)
            end
        end

        def destroy_callback(handle)
            cleanup_callbacks
            if @on_destroy
                cb = @on_destroy
                @on_destroy = nil
                cb.call(self)
            end
        end
    end
end
