# frozen_string_literal: true, encoding: ASCII-8BIT

require 'forwardable'
require 'thread'


module Libcouchbase
    class Bucket
        extend Forwardable

        # Finalizer done right
        # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
        def self.finalize(connection)
            proc {
                connection.destroy.finally do
                    connection.reactor.unref
                end
            }
        end

        def initialize(**options)
            @connection_options = options
            @connection = Connection.new(**options)
            connect

            # This obtains the connections reactor
            @reactor = reactor
            @quiet = false

            # clean up the connection once this object is garbage collected
            ObjectSpace.define_finalizer( self, self.class.finalize(@connection) )
        end


        attr_reader   :connection
        attr_accessor :quiet
        def_delegators :@connection, :bucket, :reactor


        # Obtain an object stored in Couchbase by given key.
        #
        # @param keys [String, Symbol, Array] One or several keys to fetch
        # @param options [Hash] Options for operation.
        # @option options [Integer] :lock time to lock this key for. Max time 30s
        # @option options [true, false] :extended (false) If set to +true+, the
        #   operation will return a +Libcouchbase::Result+, otherwise (by default)
        #   it returns just the value.
        # @option options [true, false] :quiet (self.quiet) If set to +true+, the
        #  operation won't raise error for missing key, it will return +nil+.
        #  Otherwise it will raise a not found error.
        # @option options [true, false] :assemble_hash (false) Assemble Hash for
        #   results.
        #
        # @return [Object, Array, Hash, Libcouchbase::Result] the value(s)
        #
        # @raise [Libcouchbase::Error::KeyExists] if the key already exists on the server
        #   with a different CAS value to that provided
        # @raise [Libouchbase::Error::Timedout] if timeout interval for observe exceeds
        # @raise [Libouchbase::Error::NetworkError] if there was a communication issue
        # @raise [Libcouchbase::Error::KeyNotFound] if the key doesn't exists
        #
        # @example Get single value in quiet mode (the default)
        #   c.get("foo")     #=> the associated value or nil
        #
        # @example Use alternative hash-like syntax
        #   c["foo"]         #=> the associated value or nil
        #
        # @example Get single value in verbose mode
        #   c.get("missing-foo", quiet: false)  #=> raises Libcouchbase::Error::NotFound
        #
        # @example Get multiple keys
        #   c.get("foo", "bar", "baz")   #=> [val1, val2, val3]
        #
        # @example Get multiple keys with assembing result into the Hash
        #   c.get("foo", "bar", "baz", assemble_hash: true)
        #   #=> {"foo" => val1, "bar" => val2, "baz" => val3}
        #
        # @example Get and lock key using default timeout
        #   c.get("foo", lock: true)  # This locks for the maximum time of 30 seconds
        #
        # @example Get and lock key using custom timeout
        #   c.get("foo", lock: 3)
        #
        # @example Get and lock multiple keys using custom timeout
        #   c.get("foo", "bar", lock: 3)
        def get(key, *keys, extended: false, async: false, quiet: @quiet, assemble_hash: false, **opts)
            was_array = key.respond_to?(:to_a) || keys.length > 0
            keys.unshift Array(key) # Convert enumerables
            keys.flatten!           # Ensure we're left with a list of keys

            if keys.length == 1
                promise = @connection.get(keys[0], **opts)

                unless extended
                    promise = promise.then(proc { |resp|
                        resp.value
                    })
                end

                if quiet
                    promise = promise.catch { |err|
                        if err.is_a? Libcouchbase::Error::KeyNotFound
                            nil
                        else
                            ::Libuv::Q.reject(@reactor, err)
                        end
                    }
                end

                if assemble_hash
                    promise = promise.then(proc { |val|
                        hash = defined?(::HashWithIndifferentAccess) ? ::HashWithIndifferentAccess.new : {}
                        hash[keys[0]] = val
                        hash
                    })
                elsif was_array
                    promise = promise.then(proc { |val|
                        Array(val)
                    })
                end

                result(promise, async)
            else
                promises = keys.collect { |key|
                    @connection.get(key, **opts)
                }

                if quiet
                    promises.map! { |prom|
                        prom.catch { |err|
                            if err.is_a? Libcouchbase::Error::KeyNotFound
                                nil
                            else
                                ::Libuv::Q.reject(@reactor, err)
                            end
                        }
                    }
                end

                result(@reactor.all(*promises).then(proc { |results|
                    if extended
                        results.compact!
                    else
                        results.collect! { |resp| resp.value if resp }
                    end

                    if assemble_hash
                        hash = defined?(::HashWithIndifferentAccess) ? ::HashWithIndifferentAccess.new : {}
                        keys.each_with_index do |key, index|
                            hash[key] = results[index]
                        end
                        hash
                    else
                        results
                    end
                }), async)
            end
        end

        # Quietly obtain an object stored in Couchbase by given key. 
        def [](key)
            get(key, quiet: true)
        end

        # A helper method for returning a default value if one doesn't exist for the key
        def fetch(key, value = nil, async: false, **opts)
            cached_obj = get(key, quiet: true, async: false, extended: false)
            return cached_obj if cached_obj
            value = value || yield
            set(key, value, opts.merge(async: false, extended: false))
            value
        end

        # Add the item to the database, but fail if the object exists already
        #
        # @param key [String, Symbol] Key used to reference the value.
        # @param value [Object] Value to be stored
        # @param options [Hash] Options for operation.
        # @option options [Integer] :ttl Expiry time for key in seconds
        # @option options [Integer] :expire_in Expiry time for key in seconds
        # @option options [Integer, Time] :expire_at Unix epoc or time at which a key
        #   should expire
        # @option options [Integer] :cas The CAS value for an object. This value is
        #   created on the server and is guaranteed to be unique for each value of
        #   a given key. This value is used to provide simple optimistic
        #   concurrency control when multiple clients or threads try to update an
        #   item simultaneously.
        # @option options [Integer] :persist_to persist to a number of nodes before returing
        #   a result. Use -1 to persist to the maximum number of nodes
        # @option options [Integer] :replicate_to replicate to a number of nodes before
        #   returning a result. Use -1 to replicate to the maximum number of nodes
        #
        # @return [Libcouchbase::Result] this includes the CAS value of the object.
        #
        # @raise [Libcouchbase::Error::KeyExists] if the key already exists on the server
        # @raise [Libouchbase::Error::Timedout] if timeout interval for observe exceeds
        # @raise [Libouchbase::Error::NetworkError] if there was a communication issue
        #
        # @example Store the key which will be expired in 2 seconds using relative TTL.
        #   c.add("foo", "bar", expire_in: 2)
        #
        # @example Store the key which will be expired in 2 seconds using absolute TTL.
        #   c.add(:foo, :bar, expire_at: Time.now.to_i + 2)
        #
        # @example Set application specific flags
        #   c.add("foo", "bar", flags: 0x1000)
        #
        # @example Ensure that the key will be persisted at least on the one node
        #   c.add("foo", "bar", persist_to: 1)
        def add(key, value, async: false, **opts)
            result @connection.store(key, value, **AddDefaults.merge(opts)), async
        end
        AddDefaults = {operation: :add}.freeze

        # Unconditionally store the object in the Couchbase
        #
        # @param key [String, Symbol] Key used to reference the value.
        # @param value [Object] Value to be stored
        # @param options [Hash] Options for operation.
        # @option options [Integer] :ttl Expiry time for key in seconds
        # @option options [Integer] :expire_in Expiry time for key in seconds
        # @option options [Integer, Time] :expire_at Unix epoc or time at which a key
        #   should expire
        # @option options [Integer] :cas The CAS value for an object. This value is
        #   created on the server and is guaranteed to be unique for each value of
        #   a given key. This value is used to provide simple optimistic
        #   concurrency control when multiple clients or threads try to update an
        #   item simultaneously.
        # @option options [Integer] :persist_to persist to a number of nodes before returing
        #   a result. Use -1 to persist to the maximum number of nodes
        # @option options [Integer] :replicate_to replicate to a number of nodes before
        #   returning a result. Use -1 to replicate to the maximum number of nodes
        #
        # @return [Libcouchbase::Result] this includes the CAS value of the object.
        #
        # @raise [Libcouchbase::Error::KeyExists] if the key already exists on the server
        #   with a different CAS value to that provided
        # @raise [Libouchbase::Error::Timedout] if timeout interval for observe exceeds
        # @raise [Libouchbase::Error::NetworkError] if there was a communication issue
        #
        # @example Store the key which will be expired in 2 seconds using relative TTL.
        #   c.set("foo", "bar", expire_in: 2)
        #
        # @example Store the key which will be expired in 2 seconds using absolute TTL.
        #   c.set(:foo, :bar, expire_at: Time.now.to_i + 2)
        #
        # @example Use hash-like syntax to store the value
        #   c[:foo] = {bar: :baz}
        #
        # @example Set application specific flags
        #   c.set("foo", "bar", flags: 0x1000)
        #
        # @example Perform optimistic locking by specifying last known CAS version
        #   c.set("foo", "bar", cas: 8835713818674332672)
        #
        # @example Ensure that the key will be persisted at least on the one node
        #   c.set("foo", "bar", persist_to: 1)
        def set(key, value, async: false, **opts)
            # default operation is set
            result @connection.store(key, value, **opts), async
        end
        alias_method :[]=, :set

        # Replace the existing object in the database
        #
        # @param key [String, Symbol] Key used to reference the value.
        # @param value [Object] Value to be stored
        # @param options [Hash] Options for operation.
        # @option options [Integer] :ttl Expiry time for key in seconds
        # @option options [Integer] :expire_in Expiry time for key in seconds
        # @option options [Integer, Time] :expire_at Unix epoc or time at which a key
        #   should expire
        # @option options [Integer] :cas The CAS value for an object. This value is
        #   created on the server and is guaranteed to be unique for each value of
        #   a given key. This value is used to provide simple optimistic
        #   concurrency control when multiple clients or threads try to update an
        #   item simultaneously.
        # @option options [Integer] :persist_to persist to a number of nodes before returing
        #   a result. Use -1 to persist to the maximum number of nodes
        # @option options [Integer] :replicate_to replicate to a number of nodes before
        #   returning a result. Use -1 to replicate to the maximum number of nodes
        #
        # @return [Libcouchbase::Result] this includes the CAS value of the object.
        #
        # @raise [Libcouchbase::Error::KeyExists] if the key already exists on the server
        #   with a different CAS value to that provided
        # @raise [Libouchbase::Error::Timedout] if timeout interval for observe exceeds
        # @raise [Libouchbase::Error::NetworkError] if there was a communication issue
        # @raise [Libcouchbase::Error::KeyNotFound] if the key doesn't exists
        #
        # @example Store the key which will be expired in 2 seconds using relative TTL.
        #   c.replace("foo", "bar", expire_in: 2)
        #
        # @example Store the key which will be expired in 2 seconds using absolute TTL.
        #   c.replace(:foo, :bar, expire_at: Time.now.to_i + 2)
        #
        # @example Set application specific flags
        #   c.replace("foo", "bar", flags: 0x1000)
        #
        # @example Ensure that the key will be persisted at least on the one node
        #   c.replace("foo", "bar", persist_to: 1)
        def replace(key, value, async: false, **opts)
            result @connection.store(key, value, **ReplaceDefaults.merge(opts)), async
        end
        ReplaceDefaults = {operation: :replace}.freeze

        # Increment the value of an existing numeric key
        #
        # The increment method allow you to increase or decrease a given stored 
        # integer value. Updating the value of a key if it can be parsed to an integer. 
        # The update operation occurs on the server and is provided at the protocol
        # level. This simplifies what would otherwise be a two-stage get and set
        # operation.
        #
        # @param key [String, Symbol] Key used to reference the value.
        # @param by [Integer] Integer (up to 64 bits) value to increment or decrement
        # @param options [Hash] Options for operation.
        # @option options [true, false] :create (false) If set to +true+, it will
        #   initialize the key with zero value and zero flags (use +:initial+
        #   option to set another initial value). Note: it won't increment the
        #   missing value.
        # @option options [Integer] :initial (0) Integer (up to 64 bits) value for
        #   missing key initialization. This option imply +:create+ option is +true+
        # @option options [Integer] :ttl Expiry time for key in seconds
        # @option options [Integer] :expire_in Expiry time for key in seconds
        # @option options [Integer, Time] :expire_at Unix epoc or time at which a key
        #   should expire
        # @option options [true, false] :extended (false) If set to +true+, the
        #   operation will return a +Libcouchbase::Result+, otherwise (by default)
        #   it returns just the value.
        #
        # @return [Integer] the actual value of the key.
        #
        # @raise [Libouchbase::Error::Timedout] if timeout interval for observe exceeds
        # @raise [Libouchbase::Error::NetworkError] if there was a communication issue
        # @raise [Libcouchbase::Error::KeyNotFound] if the key doesn't exists
        # @raise [Libcouchbase::Error::DeltaBadval] if the key contains non-numeric value
        #
        # @example Increment key by one
        #   c.incr(:foo)
        #
        # @example Increment key by 50
        #   c.incr("foo", 50)
        #
        # @example Increment key by one <b>OR</b> initialize with zero
        #   c.incr("foo", create: true)   #=> will return old+1 or 0
        #
        # @example Increment key by one <b>OR</b> initialize with three
        #   c.incr("foo", 50, initial: 3) #=> will return old+50 or 3
        #
        # @example Increment key and get its CAS value
        #   resp = c.incr("foo", :extended => true)
        #   resp.cas   #=> 12345
        #   resp.value #=> 2
        def incr(key, by = 1, create: false, extended: false, async: false, **opts)
            opts[:delta] ||= by
            opts[:initial] = 0 if create
            promise = @connection.counter(key, **opts)
            if not extended
                promise = promise.then { |resp| resp.value }
            end
            result promise, async
        end

        # Decrement the value of an existing numeric key
        #
        # Helper method, see incr
        def decr(key, by = 1, **opts)
            incr(key, -by, **opts)
        end

        # Delete the specified key
        #
        # @param key [String, Symbol] Key used to reference the value.
        # @param options [Hash] Options for operation.
        # @option options [Integer] :cas The CAS value for an object. This value is
        #   created on the server and is guaranteed to be unique for each value of
        #   a given key. This value is used to provide simple optimistic
        #   concurrency control when multiple clients or threads try to modify an
        #   item simultaneously.
        # @option options [true, false] :quiet (self.quiet) If set to +true+, the
        #   operation won't raise error for missing key, it will return +nil+.
        #   Otherwise it will raise error.
        #
        # @return [true, false] the result of the operation.
        #
        # @raise [Libcouchbase::Error::KeyExists] if the key already exists on the server
        #   with a different CAS value to that provided
        # @raise [Libouchbase::Error::Timedout] if timeout interval for observe exceeds
        # @raise [Libouchbase::Error::NetworkError] if there was a communication issue
        # @raise [Libcouchbase::Error::KeyNotFound] if the key doesn't exists
        #
        # @example Delete the key in quiet mode (default)
        #   c.set("foo", "bar")
        #   c.delete("foo")        #=> true
        #   c.delete("foo")        #=> false
        #
        # @example Delete the key verbosely
        #   c.set("foo", "bar")
        #   c.delete("foo", quiet: false)   #=> true
        #   c.delete("foo", quiet: true)    #=> nil (default behaviour)
        #   c.delete("foo", quiet: false)   #=> will raise Libcouchbase::Error::KeyNotFound
        #
        # @example Delete the key with version check
        #   res = c.set("foo", "bar")       #=> #<struct Libcouchbase::Response callback=:callback_set, key="foo", cas=1975457268957184, value="bar", metadata={:flags=>0}>
        #   c.delete("foo", cas: 123456)    #=> will raise Libcouchbase::Error::KeyExists
        #   c.delete("foo", cas: res.cas)   #=> true
        def delete(key, async: false, quiet: true, **opts)
            promise = @connection.remove(key, **opts).then { true }
            if quiet
                promise = promise.catch { |error|
                    if error.is_a? Libcouchbase::Error::KeyNotFound
                        false
                    else
                        ::Libuv::Q.reject(@reactor, error)
                    end
                }
            end
            result promise, async
        end

        # Delete contents of the bucket
        #
        # @see http://docs.couchbase.com/admin/admin/REST/rest-bucket-flush.html
        #
        # @raise [Libcouchbase::Error::HttpError] in case of an error is
        #   encountered.
        #
        # @return [Libcouchbase::Response]
        #
        # @example Simple flush the bucket
        #   c.flush
        def flush(async: false)
            result @connection.flush, async
        end

        # Touch a key, changing its CAS and optionally setting a timeout
        def touch(key, async: false, **opts)
            result @connection.touch(key, **opts), async
        end

        # Perform subdocument operations on a key.
        #
        # Yields a request builder to a block and applies the operations performed
        #
        # @param [String, Symbol] key
        #
        # @yieldparam [Libcouchbase::SubdocRequest] the subdocument request object used to define the request
        #
        # @example Perform a subdocument operation using a block
        #     c.subdoc(:foo) { |subdoc|
        #       subdoc.get('sub.key')
        #       subdoc.exists?('other.key')
        #       subdoc.get_count('some.array')
        #     } # => ["sub key val", true, 23]
        #
        # @example perform a subdocument operation using execute!
        #     c.subdoc(:foo).get(:bob).execute! # => { age: 13, working: false }
        #
        # @example perform multiple subdocument operations using execute!
        #     c.subdoc(:foo)
        #      .get(:bob).get(:jane).execute! # => [{ age: 13, working: false }, { age: 47, working: true }]
        #
        # @example perform a subdocument mutation operation
        #     c.subdoc(:foo).counter('bob.age', 1).execute! # => 14
        def subdoc(key, quiet: @quiet, **opts)
            if block_given?
                sd = SubdocRequest.new(key, quiet)
                yield sd
                subdoc_execute!(sd, opts)
            else
                SubdocRequest.new(key, quiet, bucket: self, exec_opts: opts)
            end
        end

        def subdoc_execute!(sd, extended: false, async: false, **opts)
            promise = @connection.subdoc(sd, **opts).then { |resp|
                raise resp.value if resp.value.is_a?(::Exception)
                extended ? resp : resp.value
            }
            result promise, async
        end

        # Fetch design docs stored in current bucket
        #
        # @return [Libcouchbase::DesignDocs]
        def design_docs(**opts)
            DesignDocs.new(self, @connection, proc { |promise, async| result(promise, async) }, **opts)
        end

        # Returns an enumerable for the results in a view.
        #
        # Results are lazily loaded when an operation is performed on the enum
        #
        # @return [Libcouchbase::Results]
        def view(design, view, include_docs: true, is_spatial: false, **opts, &row_modifier)
            view = @connection.query_view(design, view, **ViewDefaults.merge(opts))
            view.include_docs = include_docs
            view.is_spatial = is_spatial

            current = ::Libuv::Reactor.current

            if current && current.running?
                ResultsLibuv.new(view, current, &row_modifier)
            elsif Object.const_defined?(:EventMachine) && EM.reactor_thread?
                ResultsEM.new(view, &row_modifier)
            else
                ResultsNative.new(view, &row_modifier)
            end
        end
        ViewDefaults = {
            on_error: :stop,
            stale: false
        }

        # Returns an enumerable for the results in a full text search.
        #
        # Results are lazily loaded when an operation is performed on the enum
        #
        # @return [Libcouchbase::Results]
        def full_text_search(index, query, **opts, &row_modifier)
            if query.is_a? Hash
                opts[:query] = query
            else
                opts[:query] = {query: query}
            end
            fts = @connection.full_text_search(index, **FtsDefaults.merge(opts))

            current = ::Libuv::Reactor.current
            if current && current.running?
                ResultsLibuv.new(fts, current, &row_modifier)
            elsif Object.const_defined?(:EventMachine) && EM.reactor_thread?
                ResultsEM.new(fts, &row_modifier)
            else
                ResultsNative.new(fts, &row_modifier)
            end
        end
        FtsDefaults = {
            include_docs: true,
            size: 10000, # Max result size
            from: 0,
            explain: false
        }

        # Returns an n1ql query builder.
        #
        # @return [Libcouchbase::N1QL]
        def n1ql(**options)
            N1QL.new(self, **options)
        end

        # Update or create design doc with supplied views
        #
        # @see http://docs.couchbase.com/admin/admin/REST/rest-ddocs-create.html
        #
        # @param [Hash, IO, String] data The source object containing JSON
        #   encoded design document.
        def save_design_doc(data, id = nil, async: false)
            attrs = case data
            when String
                JSON.parse(data, Connection::DECODE_OPTIONS)
            when IO
                JSON.parse(data.read, Connection::DECODE_OPTIONS)
            when Hash
                data
            else
                raise ArgumentError, "Document should be Hash, String or IO instance"
            end
            attrs[:language] ||= :javascript

            id ||= attrs.delete(:_id)
            id = id.to_s.sub(/^_design\//, '')

            prom = @connection.http("/_design/#{id}",
                method: :put,
                body: attrs,
                type: :view
            ).then { |res|
                # Seems to require a moment before the view is usable
                @reactor.sleep 100
                res
            }

            result prom, async
        end

        # Delete design doc with given id and optional revision.
        #
        # @see http://docs.couchbase.com/admin/admin/REST/rest-ddocs-delete.html
        #
        # @param [String, Symbol] id ID of the design doc
        # @param [String] rev Optional revision
        def delete_design_doc(id, rev = nil, async: false)
            id = id.to_s.sub(/^_design\//, '')
            rev = "?rev=#{rev}" if rev
            result @connection.http("/_design/#{id}#{rev}", method: :delete, type: :view), async
        end

        # Compare and swap value.
        #
        # Reads a key's value from the server and yields it to a block. Replaces
        # the key's value with the result of the block as long as the key hasn't
        # been updated in the meantime, otherwise raises
        # {Libcouchbase::Error::KeyExists}.
        #
        # Setting the +:retry+ option to a positive number will cause this method
        # to rescue the {Libcouchbase::Error::KeyExists} error that happens when
        # an update collision is detected, and automatically get a fresh copy
        # of the value and retry the block. This will repeat as long as there
        # continues to be conflicts, up to the maximum number of retries specified.
        #
        # @param [String, Symbol] key
        #
        # @param [Hash] options the options for "swap" part
        # @option options [Integer] :retry (0) maximum number of times to autmatically retry upon update collision
        #
        # @yieldparam [Object] value existing value
        # @yieldreturn [Object] new value.
        #
        # @raise [Couchbase::Error::KeyExists] if the key was updated before the the
        #   code in block has been completed (the CAS value has been changed).
        # @raise [ArgumentError] if the block is missing
        #
        # @example Implement append to JSON encoded value
        #
        #     c.set(:foo, {bar: 1})
        #     c.cas(:foo) do |val|
        #       val[:baz] = 2
        #       val
        #     end
        #     c.get(:foo)      #=> {bar: 1, baz: 2}
        #
        # @return [Libcouchbase::Response] the transaction details including the new CAS
        def compare_and_swap(key, **opts)
            retries = opts.delete(:retry) || 0
            begin
                current = result(@connection.get(key))
                new_value = yield current.value, opts
                opts[:cas] = current.cas

                set(key, new_value, **opts)
            rescue Libcouchbase::Error::KeyExists
                retries -= 1
                retry if retries >= 0
                raise
            end
        end
        alias_method :cas, :compare_and_swap

        # The numbers of the replicas for each node in the cluster
        # @return [Integer]
        def get_num_replicas
            result @connection.get_num_replicas
        end

        # The numbers of nodes in the cluster
        # @return [Integer]
        def get_num_nodes
            result @connection.get_num_nodes
        end

        # Waits for all the async operations to complete and returns the results
        #
        # @return [Array]
        def wait_results(*results)
            result ::Libuv::Q.all(@reactor, *results.flatten)
        end


        protected


        def result(promise, async = false)
            return promise if async

            current = ::Libuv::Reactor.current
            if current && current.running?
                promise.value
            elsif Object.const_defined?(:EventMachine) && EM.reactor_thread?
                # Assume this is being run in em-synchrony
                f = Fiber.current
                error = nil
                response = nil

                @connection.reactor.next_tick do
                    begin
                        response = promise.value
                    rescue Exception => e
                        error = e
                    end

                    EM.next_tick {
                        f.resume
                    }
                end

                Fiber.yield

                update_backtrace(error) if error
                response
            else
                request = Mutex.new
                result = ConditionVariable.new
                error = nil
                response = nil

                request.synchronize {
                    @connection.reactor.next_tick do
                        begin
                            response = promise.value
                        rescue Exception => e
                            error = e
                        end

                        # Odds are we won't actually block here
                        request.synchronize {
                            result.signal
                        }
                    end
                    result.wait(request)
                }

                update_backtrace(error) if error
                response
            end
        end

        def connect
            if @connection.reactor.running?
                # We don't need to start a reactor so we use the regular helper
                result(@connection.connect)
            elsif Object.const_defined?(:EventMachine) && EM.reactor_thread?
                start_reactor_and_em_connect
            else
                start_reactor_and_connect
            end
        end

        # This blocks on the current thread
        def start_reactor_and_connect
            connecting = Mutex.new
            result = ConditionVariable.new
            error = nil

            connecting.synchronize {
                Thread.new do
                    @connection.reactor.run do |reactor|
                        reactor.ref

                        attempt = 0
                        begin
                            @connection.connect.value
                        rescue Libcouchbase::Error::ConnectError => e
                            attempt += 1
                            if attempt < 3
                                reactor.sleep 200
                                # Requires a new connection object or the retry will always fail
                                @connection = Connection.new(**@connection_options)
                                retry
                            end
                            error = e
                        rescue Exception => e
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

            update_backtrace(error) if error
        end

        # Assume this is being run in em-synchrony
        def start_reactor_and_em_connect
            f = Fiber.current
            error = nil

            Thread.new do
                @connection.reactor.run do |reactor|
                    reactor.ref

                    attempt = 0
                    begin
                        @connection.connect.value
                    rescue Libcouchbase::Error::ConnectError => e
                        attempt += 1
                        if attempt < 3
                            reactor.sleep 200
                            # Requires a new connection object or the retry will always fail
                            @connection = Connection.new(**@connection_options)
                            retry
                        end
                        error = e
                    rescue Exception => e
                        error = e
                    end

                    EM.next_tick {
                        f.resume
                    }
                end
            end

            Fiber.yield

            update_backtrace(error) if error
        end

        def update_backtrace(error)
            backtrace = caller
            backtrace.shift(2)
            if error.respond_to?(:backtrace) && error.backtrace
                backtrace << '---- continuation ----'
                backtrace.concat(error.backtrace)
            end
            error.set_backtrace(backtrace)
            raise error
        end
    end
end
