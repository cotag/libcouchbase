# frozen_string_literal: true, encoding: ASCII-8BIT

require 'json'


# Not required on jruby - buckets are cleaned up by GC
unless defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    at_exit do
        ObjectSpace.each_object(::Libcouchbase::Connection).each do |connection|
            connection.destroy.finally do
                connection.reactor.stop
            end
        end
    end
end


module Libcouchbase
    Response = Struct.new(:callback, :key, :cas, :value, :metadata)
    HttpResponse = Struct.new(:callback, :status, :headers, :body, :request)

    class Connection
        include Callbacks
        define_callback function: :bootstrap_callback, params: [:pointer, Ext::ErrorT.native_type]

        # This is common for all standard request types
        define_callback function: :callback_get
        define_callback function: :callback_unlock
        define_callback function: :callback_store
        define_callback function: :callback_storedur
        define_callback function: :callback_counter
        define_callback function: :callback_touch
        define_callback function: :callback_remove
        define_callback function: :callback_cbflush
        define_callback function: :callback_http

        # These are passed with the request
        define_callback function: :viewquery_callback
        define_callback function: :n1ql_callback
        define_callback function: :fts_callback


        Request = Struct.new(:cmd, :defer, :key, :value) do
            # We need to hold a reference to c-strings so they are not GC'd
            def ref(string)
                @refs ||= []
                str = FFI::MemoryPointer.from_string(string)
                @refs << str
                str
            end
        end


        def initialize(hosts: '127.0.0.1', bucket: 'default', password: nil, thread: nil, **opts)
            # build host string http://docs.couchbase.com/sdk-api/couchbase-c-client-2.5.6/group__lcb-init.html
            hosts = Array(hosts).flatten.join(',')
            connstr = "couchbase://#{hosts}/#{bucket}"
            connstr = "#{connstr}?#{opts.map { |k, v| "#{k}=#{v}" }.join('&') }" unless opts.empty?

            # It's good to know
            @bucket = bucket

            # Configure the event loop settings
            @reactor = thread || ::Libuv::Reactor.current || ::Libuv::Reactor.new
            @reactor.on_program_interrupt { destroy }
            @io_ptr = FFI::MemoryPointer.new :pointer, 1

            if FFI::Platform.windows?
                @io_opts = Ext::IOOptions.new
                @io_opts[:version] = 0
                @io_opts[:type] = :IO_winIOCP

                err = Ext.create_io_ops(@io_ptr, @io_opts)
            else
                @io_opts = Ext::Libuv::UVOptions.new
                @io_opts[:version] = 0
                @io_opts[:loop] = @reactor.handle
                @io_opts[:start_stop_noop] = 1 # We want to control the start and stopping of the loop
                
                err = Ext::Libuv.create_libuv_io_opts(0, @io_ptr, @io_opts)
            end

            if err != :success
                raise Error.lookup(err), 'failed to allocate IO plugin'
            end

            # Configure the connection to the database
            @connection = Ext::CreateSt.new
            @connection[:version] = 3
            @connection[:v][:v3][:connstr] = FFI::MemoryPointer.from_string(connstr)
            @connection[:v][:v3][:passwd]  = FFI::MemoryPointer.from_string(password) if password
            @connection[:v][:v3][:io]      = @io_ptr.get_pointer(0)
            @handle_ptr = FFI::MemoryPointer.new :pointer, 1
        end


        attr_reader :requests, :handle, :bucket, :reactor

        def get_callback(cb)
            callback(cb)
        end


        def connect(defer: nil, flush_enabled: false)
            raise 'already connected' if @handle || @bootstrap_defer
            @bootstrap_defer = defer || @reactor.defer
            promise = @bootstrap_defer.promise

            @reactor.schedule {
                @flush_enabled = flush_enabled

                @requests = {}

                # Create a library handle
                #  the create call allocates the memory and updates our pointer
                err = Ext.create(@handle_ptr, @connection)
                if err != :success
                    @bootstrap_defer.reject(Error.lookup(err).new('failed to create instance'))
                    handle_destroyed
                else
                    # We extract the pointer and create the handle structure
                    @ref = @handle_ptr.get_pointer(0).address
                    @handle = Ext::T.new @handle_ptr.get_pointer(0)

                    # Register the callbacks we are interested in
                    Ext.set_bootstrap_callback(@handle, callback(:bootstrap_callback))

                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_get],     callback(:callback_get))
                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_unlock],  callback(:callback_unlock))
                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_store],   callback(:callback_store))
                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_storedur],callback(:callback_storedur))
                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_counter], callback(:callback_counter))
                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_touch],   callback(:callback_touch))
                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_remove],  callback(:callback_remove))
                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_http],    callback(:callback_http))
                    Ext.install_callback3(@handle, Ext::CALLBACKTYPE[:callback_cbflush], callback(:callback_cbflush)) if @flush_enabled

                    # Connect to the database
                    err = Ext.connect(@handle)
                    if err != :success
                        @bootstrap_defer.reject(Error.lookup(err).new('failed to schedule connect'))
                        destroy
                    end
                end
            }

            promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-cntl.html
        def configure(setting, value)
            # Ensure it is thread safe
            defer = @reactor.defer
            @reactor.schedule {
                if @handle
                    err = Ext.cntl_string(@handle, setting.to_s, value.to_s)
                    if err == :success
                        defer.resolve(self)
                    else
                        defer.reject(Error.lookup(err).new("failed to configure #{setting}=#{value}"))
                    end
                else
                    defer.reject(RuntimeError.new('not connected'))
                end
            }

            defer.promise
        end

        def destroy
            defer = @reactor.defer

            # Ensure it is thread safe
            @reactor.schedule {
                if @handle
                    Ext.destroy(@handle)
                    handle_destroyed
                end
                defer.resolve(self)
            }

            defer.promise
        end

        def get_server_list
            defer = @reactor.defer

            # Ensure it is thread safe
            @reactor.schedule {
                if @handle
                    nodes = Ext.get_num_nodes(@handle)
                    list = []
                    count = 0
                    
                    while count <= nodes
                        list << Ext.get_node(@handle, :node_data, count)
                        count += 1
                    end

                    defer.resolve(list.uniq)
                else
                    defer.reject(RuntimeError.new('not connected'))
                end
            }

            defer.promise
        end

        def get_num_replicas
            defer = @reactor.defer

            # Ensure it is thread safe
            @reactor.schedule {
                if @handle
                    defer.resolve(Ext.get_num_replicas(@handle))
                else
                    defer.reject(RuntimeError.new('not connected'))
                end
            }

            defer.promise
        end

        def get_num_nodes
            defer = @reactor.defer

            # Ensure it is thread safe
            @reactor.schedule {
                if @handle
                    defer.resolve(Ext.get_num_nodes(@handle))
                else
                    defer.reject(RuntimeError.new('not connected'))
                end
            }

            defer.promise
        end

        NonJsonValue = [:append, :prepend].freeze

        # These are client specific
        FormatFlags = {
            document: 0,
            marshal: 1,
            plain: 2
        }
        SupportedFormats = FormatFlags.keys.freeze
        FormatFlags.merge!(FormatFlags.invert)
        FormatFlags.freeze

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-store.html
        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-durability.html
        # NOTE:: first 2 bits of the flags are reserved for document format
        def store(key, value, 
                defer: nil,
                operation: :set,
                expire_in: nil,
                expire_at: nil,
                ttl: nil,
                persist_to: 0,
                replicate_to: 0,
                format: :document,
                cas: nil,
                flags: 0,
        **opts)
            raise 'not connected' unless @handle
            raise 'format not supported' unless SupportedFormats.include?(:document)
            defer ||= @reactor.defer

            # Check if this should be a durable operation
            durable = (persist_to | replicate_to) != 0
            if durable
                cmd = Ext::CMDSTOREDUR.new
                cmd[:persist_to]   = persist_to
                cmd[:replicate_to] = replicate_to
            else
                cmd = Ext::CMDSTORE.new
            end
            cmd[:operation] = operation

            # Check if we are storing a string or partial value
            if NonJsonValue.include?(operation)
                format = :plain
            else
                # Preserve any application specific flags and set the format flags
                flag_mask = flags & 3
                flags = flags ^ flag_mask
                cmd[:flags] = flags | FormatFlags[format]
            end

            # Move the data into the correct format for storage
            if format == :marshal
                str_value = Marshal.dump(value)
            elsif format == :plain
                # Use coercion as it was intended
                str_value = value.respond_to?(:to_str) ? value.to_str : value.to_s
            else
                # This will raise an error if we're not storing valid json
                str_value = JSON.generate([value])[1..-2]
            end

            req = Request.new(cmd, defer)
            req.value = value
            cmd_set_value(req, cmd, str_value)
            key = cmd_set_key(req, cmd, key)

            cmd[:cas] = cas if cas
            expire_in ||= ttl
            cmd[:exptime] = expire_in ? expires_in(expire_in) : expire_at.to_i

            @reactor.schedule {
                pointer = cmd.to_ptr
                @requests[pointer.address] = req
                check_error(key, defer, durable ? Ext.storedur3(@handle, pointer, cmd) : Ext.store3(@handle, pointer, cmd))
            }
            
            defer.promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-get.html
        def get(key, defer: nil, lock: false, cas: nil, format: nil, **opts)
            raise 'not connected' unless @handle
            defer ||= @reactor.defer

            cmd = Ext::CMDGET.new
            req = Request.new(cmd, defer)
            req.value = format
            key = cmd_set_key(req, cmd, key)
            cmd[:cas] = cas if cas

            # exptime == the lock expire time
            if lock
                time = lock == true ? 30 : lock.to_i
                time = 30 if time > 30 || time < 0

                # We only want to lock if time is between 1 and 30
                if time > 0
                    cmd[:exptime] = time
                    cmd[:lock] = 1
                end
            end

            @reactor.schedule {
                pointer = cmd.to_ptr
                @requests[pointer.address] = req
                check_error key, defer, Ext.get3(@handle, pointer, cmd)
            }

            defer.promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-lock.html
        def unlock(key, cas: , **opts)
            raise 'not connected' unless @handle
            defer ||= @reactor.defer

            cmd = Ext::CMDBASE.new
            req = Request.new(cmd, defer)
            key = cmd_set_key(req, cmd, key)
            cmd[:cas] = cas

            @reactor.schedule {
                pointer = cmd.to_ptr
                @requests[pointer.address] = Request.new(cmd, defer, key)
                check_error key, defer, Ext.unlock3(@handle, pointer, cmd)
            }

            defer.promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-remove.html
        def remove(key, defer: nil, cas: nil, **opts)
            raise 'not connected' unless @handle
            defer ||= @reactor.defer

            cmd = Ext::CMDBASE.new
            req = Request.new(cmd, defer)
            key = cmd_set_key(req, cmd, key)
            cmd[:cas] = cas if cas

            @reactor.schedule {
                pointer = cmd.to_ptr
                @requests[pointer.address] = req
                check_error key, defer, Ext.remove3(@handle, pointer, cmd)
            }

            defer.promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-counter.html
        def counter(key, delta: 1, initial: nil, expire_in: nil, ttl: nil, expire_at: nil, cas: nil, **opts)
            raise 'not connected' unless @handle
            defer ||= @reactor.defer

            cmd = Ext::CMDCOUNTER.new
            req = Request.new(cmd, defer)
            key = cmd_set_key(req, cmd, key)

            cmd[:cas] = cas if cas
            expire_in ||= ttl
            cmd[:exptime] = expire_in ? expires_in(expire_in) : expire_at.to_i
            cmd[:delta] = delta
            if initial
                cmd[:initial] = initial
                cmd[:create] = 1
            end

            @reactor.schedule {
                pointer = cmd.to_ptr
                @requests[pointer.address] = req
                check_error key, defer, Ext.counter3(@handle, pointer, cmd)
            }

            defer.promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-touch.html
        def touch(key, expire_in: nil, ttl: nil, expire_at: nil, cas: nil, **opts)
            raise 'not connected' unless @handle
            raise ArgumentError.new('requires either expire_in or expire_at to be set') unless expire_in || expire_at
            defer ||= @reactor.defer

            cmd = Ext::CMDBASE.new
            req = Request.new(cmd, defer)
            key = cmd_set_key(req, cmd, key)

            cmd[:cas] = cas if cas
            expire_in ||= ttl
            cmd[:exptime] = expire_in ? expires_in(expire_in) : expire_at.to_i

            @reactor.schedule {
                pointer = cmd.to_ptr
                @requests[pointer.address] = req
                check_error key, defer, Ext.touch3(@handle, pointer, cmd)
            }

            defer.promise
        end

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-flush.html
        def flush(defer: nil)
            raise 'not connected' unless @handle
            raise 'flush not enabled' unless @flush_enabled
            defer ||= @reactor.defer

            cmd = Ext::CMDBASE.new

            @reactor.schedule {
                pointer = cmd.to_ptr
                @requests[pointer.address] = Request.new(cmd, defer, :flush)
                check_error :flush, defer, Ext.cbflush3(@handle, pointer, cmd)
            }

            defer.promise
        end


        CMDHTTP_F_STREAM = 1<<16  # Stream the response (not used, we're only making simple requests)
        CMDHTTP_F_CASTMO = 1<<17  # If specified, the lcb_CMDHTTP::cas field becomes the timeout
        CMDHTTP_F_NOUPASS = 1<<18 # If specified, do not inject authentication header into the request.
        HttpBodyRequired = [:put, :post].freeze

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-http.html
        def http(path,
                type: :view,
                method: :get,
                body: nil,
                content_type: 'application/json',
                defer: nil,
                timeout: nil,
                username: nil,
                password: nil,
                no_auth: false,
        **opts)
            raise 'not connected' unless @handle
            raise 'unsupported request type' unless Ext::HttpTypeT[type]
            raise 'unsupported HTTP method' unless Ext::HttpMethodT[method]
            body_content = if HttpBodyRequired.include? method
                raise 'no HTTP body provided' unless body
                if body.is_a? String
                    body
                else
                    # This will raise an error if not valid json
                    JSON.generate([body])[1..-2]
                end
            end

            defer ||= @reactor.defer

            cmd = Ext::CMDHTTP.new
            req = Request.new(cmd, defer)
            req.value = {
                path: path,
                method: method,
                body: body,
                content_type: content_type,
                type: type,
                no_auth: no_auth
            }
            cmd_set_key(req, cmd, path)

            if timeout
                cmd[:cas] = timeout
                cmd[:cmdflags] |= CMDHTTP_F_CASTMO
            end
            cmd[:cmdflags] |= CMDHTTP_F_NOUPASS if no_auth
            cmd[:type] = type
            cmd[:method] = method

            if body_content
                cmd[:body] = req.ref(body_content)
                cmd[:nbody] = body_content.bytesize
            end
            cmd[:content_type] = req.ref(content_type) if content_type
            cmd[:username] = req.ref(username) if username
            cmd[:password] = req.ref(password) if password


            @reactor.schedule {
                pointer = cmd.to_ptr
                @requests[pointer.address] = req
                check_error path, defer, Ext.http3(@handle, pointer, cmd)
            }

            defer.promise
        end

        def query_view(design, view, **opts)
            QueryView.new(self, @reactor, design, view, **opts)
        end

        def full_text_search(index, **opts)
            opts[:indexName] = index
            QueryFullText.new(self, @reactor, **opts)
        end

        def n1ql_query(n1ql, **opts)
            QueryN1QL.new(self, @reactor, n1ql, **opts)
        end

        def parse_document(raw_string, flags: 0, hint: nil)
            flag_mask = flags & 3
            format = hint || FormatFlags[flag_mask] # Defaults to document
            val = begin
                case format
                when :marshal
                    Marshal.load(raw_string)
                when :document
                    JSON.parse("[#{raw_string}]", DECODE_OPTIONS)[0]
                else
                    format = :plain
                    raw_string
                end
            rescue => e
                format = :plain
                raw_string
            end
            [val, format]
        end


        private


        def cmd_set_key(req, cmd, value)
            key = value.to_s
            cmd[:key][:type] = :kv_copy
            str = req.ref(key)
            req.key = value
            cmd[:key][:contig][:bytes] = str
            cmd[:key][:contig][:nbytes] = key.bytesize
            key
        end

        def cmd_set_value(req, cmd, value)
            val = value.to_s
            cmd[:value][:vtype] = :kv_copy
            str = req.ref(val)
            cmd[:value][:u_buf][:contig][:bytes] = str
            cmd[:value][:u_buf][:contig][:nbytes] = val.bytesize
        end

        # 30 days in seconds
        MAX_EXPIRY = 2_592_000

        def expires_in(time)
            period = time.to_i
            if period > MAX_EXPIRY
                Time.now.to_i + period
            else
                period
            end
        end

        def check_error(key, defer, err)
            if err != :success
                error = Error.lookup(err).new("request not scheduled for #{key}")
                backtrace = caller
                error.set_backtrace backtrace
                defer.reject error
            end
        end

        def handle_destroyed
            @bootstrap_defer = nil
            @handle = nil

            # TODO:: cleanup IO opts?
            cleanup_callbacks

            @requests.each_value do |req|
                err = Error::Sockshutdown.new('handle destroyed')
                if req.is_a? Request
                    req.defer.reject(err)
                else
                    # this is a view, n1ql or full text query
                    req.error(err)
                end
            end
            @requests = nil
        end

        def bootstrap_callback(handle, error_code)
            error_name = Ext::ErrorT[error_code]

            if error_code == Ext::ErrorT[:success]
                @bootstrap_defer.resolve(self)
                @bootstrap_defer = nil
            else
                @bootstrap_defer.reject(Error.lookup(error_code).new("bootstrap failed"))
                handle_destroyed
            end
        end

        # ==================
        # Response Callbacks
        # ==================
        DECODE_OPTIONS = {
            symbolize_names: true
        }.freeze

        def callback_get(handle, type, response)
            resp = Ext::RESPGET.new response
            resp_callback_common(resp, :callback_get) do |req, cb|
                raw_string = resp[:value].read_string(resp[:nvalue])
                val, format = parse_document(raw_string, flags: resp[:itmflags], hint: req.value)
                Response.new(cb, req.key, resp[:cas], val, {format: format, flags: resp[:itmflags]})
            end
        end

        def callback_store(handle, type, response)
            resp = Ext::RESPSTORE.new response
            resp_callback_common(resp, :callback_store) do |req, cb|
                Response.new(cb, req.key, resp[:cas], req.value)
            end
        end

        Durability = Struct.new(:nresponses, :exists_master, :persisted_master, :npersisted, :nreplicated, :error)

        def callback_storedur(handle, type, response)
            resp = Ext::RESPSTOREDUR.new response
            resp_callback_common(resp, :callback_storedur) do |req, cb|
                info = resp[:dur_resp]
                dur = Durability.new(
                    info[:nresponses],
                    info[:exists_master],
                    info[:persisted_master],
                    info[:npersisted],
                    info[:nreplicated],
                    info[:rc]
                )
                Response.new(cb, req.key, resp[:cas], req.value, dur)
            end
        end

        def callback_counter(handle, type, response)
            resp = Ext::RESPCOUNTER.new response
            resp_callback_common(resp, :callback_counter) do |req, cb|
                Response.new(cb, req.key, resp[:cas], resp[:value])
            end
        end

        def callback_touch(handle, type, response)
            resp = Ext::RESPBASE.new response
            resp_callback_common(resp, :callback_touch) do |req, cb|
                Response.new(cb, req.key, resp[:cas])
            end
        end

        def callback_remove(handle, type, response)
            resp = Ext::RESPBASE.new response
            resp_callback_common(resp, :callback_remove) do |req, cb|
                Response.new(cb, req.key, resp[:cas])
            end
        end

        def callback_unlock(handle, type, response)
            resp = Ext::RESPBASE.new response
            resp_callback_common(resp, :callback_unlock) do |req, cb|
                Response.new(cb, req.key, resp[:cas])
            end
        end

        def callback_cbflush(handle, type, response)
            resp = Ext::RESPBASE.new response
            resp_callback_common(resp, :callback_cbflush) do |req, cb|
                Response.new(cb)
            end
        end

        def callback_http(handle, type, response)
            resp = Ext::RESPHTTP.new response
            resp_callback_common(resp, :callback_http) do |req, cb|
                headers = {}
                head_ptr = resp[:headers]
                if not head_ptr.null?
                    head_ptr.get_array_of_string(0).each_slice(2) do |key, value|
                        headers[key] = value
                    end
                end
                body = if resp[:nbody] > 0
                    resp[:body].read_string(resp[:nbody])
                else
                    ''
                end

                if (200...300).include? resp[:htstatus]
                    HttpResponse.new(cb, resp[:htstatus], headers, body, req.value)
                else
                    err = Error::HttpResponseError.new "non success response for #{req.key}"
                    err.code = resp[:htstatus]
                    err.headers = headers
                    err.body = body
                    req.defer.reject(err)
                end
            end
        end

        def resp_callback_common(resp, callback)
            req = @requests.delete(resp[:cookie].address)
            if req
                begin
                    if resp[:rc] == :success
                        req.defer.resolve(yield(req, callback))
                    else
                        req.defer.reject(Error.lookup(resp[:rc]).new("#{callback} failed for #{req.key}"))
                    end
                rescue => e
                    req.defer.reject(e)
                end
            else
                @reactor.log IOError.new("received #{callback} for unknown request")
            end
        end
        # ======================
        # End Response Callbacks
        # ======================

        # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-view-api.html
        def viewquery_callback(handle, type, row)
            row_data = Ext::RESPVIEWQUERY.new row
            view = @requests[row_data[:cookie].address]

            if row_data[:rc] == :success
                if (row_data[:rflags] & Ext::RESPFLAGS[:resp_f_final]) > 0
                    # We can assume this is JSON
                    view.received_final(JSON.parse(row_data[:value].read_string(row_data[:nvalue]), DECODE_OPTIONS))
                else
                    view.received(row_data)
                end
            else
                error_klass = Error.lookup(row_data[:rc])
                if error_klass == Error::HttpError
                    http_resp = row_data[:htresp]
                    view.error error_klass.new(http_resp[:body].read_string(http_resp[:nbody]))
                else
                    view.error error_klass.new
                end
            end
        end

        # N1QL query response
        # @see http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-n1ql-api.html
        def n1ql_callback(handle, type, row)
            query_callback_common Ext::RESPN1QL.new(row)
        end

        # Full text search
        # @see http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-cbft-api.html
        def fts_callback(handle, type, row)
            query_callback_common Ext::RESPFTS.new(row)
        end

        # Common code to process both N1QL and FTS callbacks
        def query_callback_common(row_data)
            view = @requests[row_data[:cookie].address]

            if row_data[:rc] == :success
                value = JSON.parse(row_data[:row].read_string(row_data[:nrow]), DECODE_OPTIONS)

                if (row_data[:rflags] & Ext::RESPFLAGS[:resp_f_final]) > 0
                    # We can assume this is JSON
                    view.received_final(value)
                else
                    view.received(value)
                end
            else
                error_klass = Error.lookup(row_data[:rc])
                if error_klass == Error::HttpError
                    http_resp = row_data[:htresp]
                    view.error error_klass.new(http_resp[:body].read_string(http_resp[:nbody]))
                else
                    view.error error_klass.new
                end
            end
        end
    end
end
