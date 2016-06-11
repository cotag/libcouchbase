require 'ffi'

module Libcouchbase::Ext
    extend FFI::Library
    ffi_lib ::File.dirname(__FILE__) + "/../../../ext/libcouchbase/build/lib/libcouchbase.#{FFI::Platform::LIBSUFFIX}"

    LIBCOUCHBASE_COUCHBASE_H = 1
    CONFIG_MCD_PORT = 11210
    CONFIG_MCD_SSL_PORT = 11207
    CONFIG_HTTP_PORT = 8091
    CONFIG_HTTP_SSL_PORT = 18091
    CONFIG_MCCOMPAT_PORT = 11211
    CMD_F_INTERNAL_CALLBACK = (1<<0)
    CALLBACK_VIEWQUERY = -1
    CALLBACK_N1QL = -2
    CALLBACK_IXMGMT = -3
    CMDGET_F_CLEAREXP = (1<<16)
    CMDENDURE_F_MUTATION_TOKEN = 1<<16
    DURABILITY_VALIDATE_CAPMAX = 1<<1
    CMDOBSERVE_F_MASTER_ONLY = 1<<16
    CMDSTATS_F_KV = (1<<16)
    CMDHTTP_F_STREAM = 1<<16
    CMDHTTP_F_CASTMO = 1<<17
    CMDHTTP_F_NOUPASS = 1<<18
    DATATYPE_JSON = 0x01
    GETNODE_UNAVAILABLE = "invalid_host:0"
    SUPPORTS_SSL = 1
    SUPPORTS_SNAPPY = 2

    # (Not documented)
    class St < FFI::Struct
      layout :dummy, :char
    end

    # (Not documented)
    class HttpRequestSt < FFI::Struct
      layout :dummy, :char
    end

    # @brief Handle types @see lcb_create_st3::type
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:type_t).</em>
    #
    # === Options:
    # :bucket ::
    #
    # :cluster ::
    #   < Handle for data access (default)
    #
    # @method _enum_type_t_
    # @return [Symbol]
    # @scope class
    enum :type_t, [
      :bucket, 0,
      :cluster, 1
    ]

    # These are definitions for some of the older fields of the `lcb_create_st`
    # structure. They are here for backwards compatibility and should not be
    # used by new code
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:config_transport_t).</em>
    #
    # === Options:
    # :list_end ::
    #
    # :http ::
    #
    # :cccp ::
    #
    # :max ::
    #
    #
    # @method _enum_config_transport_t_
    # @return [Symbol]
    # @scope class
    enum :config_transport_t, [
      :list_end, 0,
      :http, 1,
      :cccp, 2,
      :max, 3
    ]

    # (Not documented)
    #
    # = Fields:
    # :host ::
    #   (String)
    # :user ::
    #   (String)
    # :passwd ::
    #   (String)
    # :bucket ::
    #   (String)
    # :io ::
    #   (FFI::Pointer(*IoOptSt))
    class CreateSt0 < FFI::Struct
      layout :host, :string,
             :user, :string,
             :passwd, :string,
             :bucket, :string,
             :io, :pointer
    end

    # (Not documented)
    #
    # = Fields:
    # :host ::
    #   (String)
    # :user ::
    #   (String)
    # :passwd ::
    #   (String)
    # :bucket ::
    #   (String)
    # :io ::
    #   (FFI::Pointer(*IoOptSt))
    # :type ::
    #   (Symbol from _enum_type_t_)
    class CreateSt1 < FFI::Struct
      layout :host, :string,
             :user, :string,
             :passwd, :string,
             :bucket, :string,
             :io, :pointer,
             :type, :type_t
    end

    # (Not documented)
    #
    # = Fields:
    # :host ::
    #   (String)
    # :user ::
    #   (String)
    # :passwd ::
    #   (String)
    # :bucket ::
    #   (String)
    # :io ::
    #   (FFI::Pointer(*IoOptSt))
    # :type ::
    #   (Symbol from _enum_type_t_)
    # :mchosts ::
    #   (String)
    # :transports ::
    #   (FFI::Pointer(*ConfigTransportT))
    class CreateSt2 < FFI::Struct
      layout :host, :string,
             :user, :string,
             :passwd, :string,
             :bucket, :string,
             :io, :pointer,
             :type, :type_t,
             :mchosts, :string,
             :transports, :pointer
    end

    # @brief Innser structure for lcb_create().
    #
    # = Fields:
    # :connstr ::
    #   (String) < Connection string
    # :username ::
    #   (String) < Username for bucket. Unused as of Server 2.5
    # :passwd ::
    #   (String) < Password for bucket
    # :pad_bucket ::
    #   (FFI::Pointer(*Void)) < @private
    # :io ::
    #   (FFI::Pointer(*IoOptSt)) < IO Options
    # :type ::
    #   (Symbol from _enum_type_t_)
    class CreateSt3 < FFI::Struct
      layout :connstr, :string,
             :username, :string,
             :passwd, :string,
             :pad_bucket, :pointer,
             :io, :pointer,
             :type, :type_t
    end

    # (Not documented)
    #
    # = Fields:
    # :v0 ::
    #   (CreateSt0)
    # :v1 ::
    #   (CreateSt1)
    # :v2 ::
    #   (CreateSt2)
    # :v3 ::
    #   (CreateSt3) < Use this field
    class CRSTU < FFI::Union
      layout :v0, CreateSt0.by_value,
             :v1, CreateSt1.by_value,
             :v2, CreateSt2.by_value,
             :v3, CreateSt3.by_value
    end

    # @brief Wrapper structure for lcb_create()
    # @see lcb_create_st3
    #
    # = Fields:
    # :version ::
    #   (Integer) Indicates which field in the @ref lcb_CRST_u union should be used. Set this to `3`
    # :v ::
    #   (CRSTU) This union contains the set of current and historical options. The
    #   The #v3 field should be used.
    class CreateSt < FFI::Struct
      layout :version, :int,
             :v, CRSTU.by_value
    end

    # @brief Create an instance of lcb.
    # @param instance Where the instance should be returned
    # @param options How to create the libcouchbase instance
    # @return LCB_SUCCESS on success
    #
    #
    # ### Examples
    # Create an instance using the default values:
    #
    # @code{.c}
    # lcb_t instance;
    # lcb_error_t err = lcb_create(&instance, NULL);
    # if (err != LCB_SUCCESS) {
    #    fprintf(stderr, "Failed to create instance: %s\n", lcb_strerror(NULL, err));
    #    exit(EXIT_FAILURE);
    # }
    # @endcode
    #
    # Specify server list
    #
    # @code{.c}
    # struct lcb_create_st options;
    # memset(&options, 0, sizeof(options));
    # options.version = 3;
    # options.v.v3.connstr = "couchbase://host1,host2,host3";
    # err = lcb_create(&instance, &options);
    # @endcode
    #
    #
    # Create a handle for data requests to protected bucket
    #
    # @code{.c}
    # struct lcb_create_st options;
    # memset(&options, 0, sizeof(options));
    # options.version = 3;
    # options.v.v3.host = "couchbase://example.com,example.org/protected"
    # options.v.v3.passwd = "secret";
    # err = lcb_create(&instance, &options);
    # @endcode
    # @committed
    # @see lcb_create_st3
    #
    # @method create(instance, options)
    # @param [FFI::Pointer(*T)] instance
    # @param [CreateSt] options
    # @return [unknown]
    # @scope class
    attach_function :create, :lcb_create, [:pointer, CreateSt], :char

    # @brief Schedule the initial connection
    # This function will schedule the initial connection for the handle. This
    # function _must_ be called before any operations can be performed.
    #
    # lcb_set_bootstrap_callback() or lcb_get_bootstrap_status() can be used to
    # determine if the scheduled connection completed successfully.
    #
    # @par Synchronous Usage
    # @code{.c}
    # lcb_error_t rc = lcb_connect(instance);
    # if (rc != LCB_SUCCESS) {
    #    your_error_handling(rc);
    # }
    # lcb_wait(instance);
    # rc = lcb_get_bootstrap_status(instance);
    # if (rc != LCB_SUCCESS) {
    #    your_error_handler(rc);
    # }
    # @endcode
    # @committed
    #
    # @method connect(instance)
    # @param [St] instance
    # @return [unknown]
    # @scope class
    attach_function :connect, :lcb_connect, [St], :char

    # Bootstrap callback. Invoked once the instance is ready to perform operations
    # @param instance The instance which was bootstrapped
    # @param err The error code received. If this is not LCB_SUCCESS then the
    # instance is not bootstrapped and must be recreated
    #
    # @attention This callback only receives information during instantiation.
    # @committed
    #
    # <em>This entry is only for documentation and no real method.</em>
    #
    # @method _callback_bootstrap_callback_(instance, err)
    # @param [St] instance
    # @param [unknown] err
    # @return [St]
    # @scope class
    callback :bootstrap_callback, [St, :char], St

    # @brief Set the callback for notification of success or failure of
    # initial connection.
    #
    # @param instance the instance
    # @param callback the callback to set. If `NULL`, return the existing callback
    # @return The existing (and previous) callback.
    # @see lcb_connect()
    # @see lcb_get_bootstrap_status()
    #
    # @method set_bootstrap_callback(instance, callback)
    # @param [St] instance
    # @param [Proc(_callback_bootstrap_callback_)] callback
    # @return [Proc(_callback_bootstrap_callback_)]
    # @scope class
    attach_function :set_bootstrap_callback, :lcb_set_bootstrap_callback, [St, :bootstrap_callback], :bootstrap_callback

    # @brief Gets the initial bootstrap status
    #
    # This is an alternative to using the lcb_bootstrap_callback() and may be used
    # after the initial lcb_connect() and lcb_wait() sequence.
    # @param instance
    # @return LCB_SUCCESS if properly bootstrapped or an error code otherwise.
    #
    # @attention
    # Calling this function only makes sense during instantiation.
    # @committed
    #
    # @method get_bootstrap_status(instance)
    # @param [St] instance
    # @return [unknown]
    # @scope class
    attach_function :get_bootstrap_status, :lcb_get_bootstrap_status, [St], :char

    # @brief Common ABI header for all commands. _Any_ command may be safely
    # casted to this type.
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    class CMDBASE < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char
    end

    # @brief
    # Base response structure for callbacks.
    # All responses structures derive from this ABI.
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    class RESPBASE < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int
    end

    # @brief Base structure for informational commands from servers
    # This contains an additional lcb_RESPSERVERBASE::server field containing the
    # server which emitted this response.
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :server ::
    #   (String)
    class RESPSERVERBASE < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :server, :string
    end

    # @ingroup lcb-mutation-tokens
    #
    # = Fields:
    # :uuid ::
    #   (Integer) < Use LCB_MUTATION_TOKEN_ID()
    # :seqno ::
    #   (Integer) < Use LCB_MUTATION_TOKEN_SEQ()
    # :vbid ::
    #   (Integer) < Use LCB_MUTATION_TOKEN_VB()
    class MUTATIONTOKEN < FFI::Struct
      layout :uuid, :int,
             :seqno, :int,
             :vbid, :int
    end

    # @brief Response flags.
    # These provide additional 'meta' information about the response
    # One of more of these values can be set in @ref lcb_RESPBASE::rflags
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:respflags).</em>
    #
    # === Options:
    # :resp_f_final ::
    #   No more responses are to be received for this request
    # :resp_f_clientgen ::
    #   The response was artificially generated inside the client.
    #   This does not contain reply data from the server for the command, but
    #   rather contains the basic fields to indicate success or failure and is
    #   otherwise empty.
    # :resp_f_nmvgen ::
    #   The response was a result of a not-my-vbucket error
    # :resp_f_extdata ::
    #   The response has additional internal data.
    #   Used by lcb_resp_get_mutation_token()
    # :resp_f_sdsingle ::
    #   Flag, only valid for subdoc responses, indicates that the response was
    #   processed using the single-operation protocol.
    #
    # @method _enum_respflags_
    # @return [Symbol]
    # @scope class
    enum :respflags, [
      :resp_f_final, 1,
      :resp_f_clientgen, 2,
      :resp_f_nmvgen, 4,
      :resp_f_extdata, 8,
      :resp_f_sdsingle, 16
    ]

    # The type of response passed to the callback. This is used to install callbacks
    # for the library and to distinguish between responses if a single callback
    # is used for multiple response types.
    #
    # @note These callbacks may conflict with the older version 2 callbacks. The
    # rules are as follows:
    # * If a callback has been installed using lcb_install_callback3(), then
    # the older version 2 callback will not be invoked for that operation. The order
    # of installation does not matter.
    # * If the LCB_CALLBACK_DEFAULT callback is installed, _none_ of the version 2
    # callbacks are invoked.
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:callbacktype).</em>
    #
    # === Options:
    # :callback_default ::
    #
    # :callback_get ::
    #   < Default callback invoked as a fallback
    # :callback_store ::
    #   < lcb_get3()
    # :callback_counter ::
    #   < lcb_store3()
    # :callback_touch ::
    #   < lcb_counter3()
    # :callback_remove ::
    #   < lcb_touch3()
    # :callback_unlock ::
    #   < lcb_remove3()
    # :callback_stats ::
    #   < lcb_unlock3()
    # :callback_versions ::
    #   < lcb_stats3()
    # :callback_verbosity ::
    #   < lcb_server_versions3()
    # :callback_flush ::
    #   < lcb_server_verbosity3()
    # :callback_observe ::
    #   < lcb_flush3()
    # :callback_getreplica ::
    #   < lcb_observe3_ctxnew()
    # :callback_endure ::
    #   < lcb_rget3()
    # :callback_http ::
    #   < lcb_endure3_ctxnew()
    # :callback_cbflush ::
    #   < lcb_http3()
    # :callback_obseqno ::
    #   < lcb_cbflush3()
    # :callback_storedur ::
    #   < For lcb_observe_seqno3()
    # :callback_sdlookup ::
    #   <for lcb_storedur3()
    # :callback_sdmutate ::
    #
    # :callback_max ::
    #
    #
    # @method _enum_callbacktype_
    # @return [Symbol]
    # @scope class
    enum :callbacktype, [
      :callback_default, 0,
      :callback_get, 1,
      :callback_store, 2,
      :callback_counter, 3,
      :callback_touch, 4,
      :callback_remove, 5,
      :callback_unlock, 6,
      :callback_stats, 7,
      :callback_versions, 8,
      :callback_verbosity, 9,
      :callback_flush, 10,
      :callback_observe, 11,
      :callback_getreplica, 12,
      :callback_endure, 13,
      :callback_http, 14,
      :callback_cbflush, 15,
      :callback_obseqno, 16,
      :callback_storedur, 17,
      :callback_sdlookup, 18,
      :callback_sdmutate, 19,
      :callback_max, 20
    ]

    # @committed
    #
    # Callback invoked for responses.
    # @param instance The handle
    # @param cbtype The type of callback - or in other words, the type of operation
    # this callback has been invoked for.
    # @param resp The response for the operation. Depending on the operation this
    # response structure should be casted into a more specialized type.
    #
    # <em>This entry is only for documentation and no real method.</em>
    #
    # @method _callback_respcallback_(instance, cbtype, resp)
    # @param [St] instance
    # @param [Integer] cbtype
    # @param [RESPBASE] resp
    # @return [St]
    # @scope class
    callback :respcallback, [St, :int, RESPBASE], St

    # @committed
    #
    # Install a new-style callback for an operation. The callback will be invoked
    # with the relevant response structure.
    #
    # @param instance the handle
    # @param cbtype the type of operation for which this callback should be installed.
    #        The value should be one of the lcb_CALLBACKTYPE constants
    # @param cb the callback to install
    # @return the old callback
    #
    # @note LCB_CALLBACK_DEFAULT is initialized to the default handler which proxies
    # back to the older 2.x callbacks. If you set `cbtype` to LCB_CALLBACK_DEFAULT
    # then your `2.x` callbacks _will not work_.
    #
    # @note The old callback may be `NULL`. It is usually not an error to have a
    # `NULL` callback installed. If the callback is `NULL`, then the default callback
    # invocation pattern will take place (as desribed above). However it is an error
    # to set the default callback to `NULL`.
    #
    # @method install_callback3(instance, cbtype, cb)
    # @param [St] instance
    # @param [Integer] cbtype
    # @param [Proc(_callback_respcallback_)] cb
    # @return [Proc(_callback_respcallback_)]
    # @scope class
    attach_function :install_callback3, :lcb_install_callback3, [St, :int, :respcallback], :respcallback

    # @committed
    #
    # Get the current callback installed as `cbtype`. Note that this does not
    # perform any kind of resolution (as described in lcb_install_callback3) and
    # will only return a non-`NULL` value if a callback had specifically been
    # installed via lcb_install_callback3() with the given `cbtype`.
    #
    # @param instance the handle
    # @param cbtype the type of callback to retrieve
    # @return the installed callback for the type.
    #
    # @method get_callback3(instance, cbtype)
    # @param [St] instance
    # @param [Integer] cbtype
    # @return [Proc(_callback_respcallback_)]
    # @scope class
    attach_function :get_callback3, :lcb_get_callback3, [St, :int], :respcallback


    # @brief Command for retrieving a single item
    #
    # @see lcb_get3()
    # @see lcb_RESPGET
    #
    # @note The #cas member should be set to 0 for this operation. If the #cas is
    # not 0, lcb_get3() will fail with ::LCB_OPTIONS_CONFLICT.
    #
    # ### Use of the `exptime` field
    #
    # <ul>
    # <li>Get And Touch:
    #
    # It is possible to retrieve an item and concurrently modify its expiration
    # time (thus keeping it "alive"). The item's expiry time can be set using
    # the #exptime field.
    # </li>
    #
    # <li>Lock
    # If the #lock field is set to non-zero, the #exptime field indicates the amount
    # of time the lock should be held for
    # </li>
    # </ul>
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :lock ::
    #   (Integer) If set to true, the `exptime` field inside `options` will take to mean
    #   the time the lock should be held. While the lock is held, other operations
    #   trying to access the key will fail with an `LCB_ETMPFAIL` error. The
    #   item may be unlocked either via `lcb_unlock3()` or via a mutation
    #   operation with a supplied CAS
    class CMDGET < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :lock, :int
    end

    # @brief Response structure when retrieving a single item
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :value ::
    #   (FFI::Pointer(*Void)) < Value buffer for the item
    # :nvalue ::
    #   (Integer) < Length of value
    # :bufh ::
    #   (FFI::Pointer(*Void))
    # :datatype ::
    #   (Integer) < @private
    # :itmflags ::
    #   (Integer) < User-defined flags for the item
    class RESPGET < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :value, :pointer,
             :nvalue, :int,
             :bufh, :pointer,
             :datatype, :int,
             :itmflags, :int
    end

    # @committed
    #
    # @brief Spool a single get operation
    # @param instance the handle
    # @param cookie a pointer to be associated with the command
    # @param cmd the command structure
    # @return LCB_SUCCESS if successful, an error code otherwise
    #
    # @par Request
    # @code{.c}
    # lcb_CMDGET cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "Hello", 5);
    # lcb_get3(instance, cookie, &cmd);
    # @endcode
    #
    # @par Response
    # @code{.c}
    # lcb_install_callback3(instance, LCB_CALLBACK_GET, get_callback);
    # static void get_callback(lcb_t instance, int cbtype, const lcb_RESPBASE *rb) {
    #     const lcb_RESPGET *resp = (const lcb_RESPGET*)rb;
    #     printf("Got response for key: %.*s\n", (int)resp->key, resp->nkey);
    #
    #     if (resp->rc != LCB_SUCCESS) {
    #         printf("Couldn't get item: %s\n", lcb_strerror(NULL, resp->rc));
    #     } else {
    #         printf("Got value: %.*s\n", (int)resp->nvalue, resp->value);
    #         printf("Got CAS: 0x%llx\n", resp->cas);
    #         printf("Got item/formatting flags: 0x%x\n", resp->itmflags);
    #     }
    # }
    #
    # @endcode
    #
    # @par Errors
    # @cb_err ::LCB_KEY_ENOENT if the item does not exist in the cluster
    # @cb_err ::LCB_ETMPFAIL if the lcb_CMDGET::lock option was set but the item
    # was already locked. Note that this error may also be returned (as a generic
    # error) if there is a resource constraint within the server itself.
    #
    # @method get3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDGET] cmd
    # @return [unknown]
    # @scope class
    attach_function :get3, :lcb_get3, [St, :pointer, CMDGET], :char

    # @brief Select get-replica mode
    # @see lcb_rget3_cmd_t
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:replica_t).</em>
    #
    # === Options:
    # :first ::
    #   Query all the replicas sequentially, retrieving the first successful
    #   response
    # :all ::
    #   Query all the replicas concurrently, retrieving all the responses
    # :select ::
    #   Query the specific replica specified by the
    #   lcb_rget3_cmd_t#index field
    #
    # @method _enum_replica_t_
    # @return [Symbol]
    # @scope class
    enum :replica_t, [
      :first, 0,
      :all, 1,
      :select, 2
    ]

    # @brief Command for requesting an item from a replica
    # @note The `options.exptime` and `options.cas` fields are ignored for this
    # command.
    #
    # This structure is similar to @ref lcb_RESPGET with the addition of an
    # `index` and `strategy` field which allow you to control and select how
    # many replicas are queried.
    #
    # @see lcb_rget3(), lcb_RESPGET
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :strategy ::
    #   (Symbol from _enum_replica_t_) Strategy for selecting a replica. The default is ::LCB_REPLICA_FIRST
    #   which results in the client trying each replica in sequence until a
    #   successful reply is found, and returned in the callback.
    #
    #   ::LCB_REPLICA_FIRST evaluates to 0.
    #
    #   Other options include:
    #   <ul>
    #   <li>::LCB_REPLICA_ALL - queries all replicas concurrently and dispatches
    #   a callback for each reply</li>
    #   <li>::LCB_REPLICA_SELECT - queries a specific replica indicated in the
    #   #index field</li>
    #   </ul>
    #
    #   @note When ::LCB_REPLICA_ALL is selected, the callback will be invoked
    #   multiple times, one for each replica. The final callback will have the
    #   ::LCB_RESP_F_FINAL bit set in the lcb_RESPBASE::rflags field. The final
    #   response will also contain the response from the last replica to
    #   respond.
    # :index ::
    #   (Integer) Valid only when #strategy is ::LCB_REPLICA_SELECT, specifies the replica
    #   index number to query. This should be no more than `nreplicas-1`
    #   where `nreplicas` is the number of replicas the bucket is configured with.
    class CMDGETREPLICA < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :strategy, :replica_t,
             :index, :int
    end

    # @committed
    #
    # @brief Spool a single get-with-replica request
    # @param instance
    # @param cookie
    # @param cmd
    # @return LCB_SUCCESS on success, error code otherwise.
    #
    # When a response is received, the callback installed for ::LCB_CALLBACK_GETREPLICA
    # will be invoked. The response will be an @ref lcb_RESPGET pointer.
    #
    # ### Request
    # @code{.c}
    # lcb_CMDGETREPLICA cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "key", 3);
    # lcb_rget3(instance, cookie, &cmd);
    # @endcode
    #
    # ### Response
    # @code{.c}
    # lcb_install_callback3(instance, LCB_CALLBACK_GETREPLICA, rget_callback);
    # static void rget_callback(lcb_t instance, int cbtype, const lcb_RESPBASE *rb)
    # {
    #     const lcb_RESPGET *resp = (const lcb_RESPGET *)rb;
    #     printf("Got Get-From-Replica response for %.*s\n", (int)resp->key, resp->nkey);
    #     if (resp->rc == LCB_SUCCESS) {
    #         printf("Got response: %.*s\n", (int)resp->value, resp->nvalue);
    #     else {
    #         printf("Couldn't retrieve: %s\n", lcb_strerror(NULL, resp->rc));
    #     }
    # }
    # @endcode
    #
    # @warning As this function queries a replica node for data it is possible
    # that the returned document may not reflect the latest document in the server.
    #
    # @warning This function should only be used in cases where a normal lcb_get3()
    # has failed, or where there is reason to believe it will fail. Because this
    # function may query more than a single replica it may cause additional network
    # and server-side CPU load. Use sparingly and only when necessary.
    #
    # @cb_err ::LCB_KEY_ENOENT if the key is not found on the replica(s),
    # ::LCB_NO_MATCHING_SERVER if there are no replicas (either configured or online),
    # or if the given replica
    # (if lcb_CMDGETREPLICA::strategy is ::LCB_REPLICA_SELECT) is not available or
    # is offline.
    #
    # @method rget3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDGETREPLICA] cmd
    # @return [unknown]
    # @scope class
    attach_function :rget3, :lcb_rget3, [St, :pointer, CMDGETREPLICA], :char

    # @brief Values for lcb_CMDSTORE::operation
    #
    # Storing an item in couchbase is only one operation with a different
    # set of attributes / constraints.
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:storage_t).</em>
    #
    # === Options:
    # :add ::
    #   Will cause the operation to fail if the key already exists in the
    #   cluster.
    # :replace ::
    #   Will cause the operation to fail _unless_ the key already exists in the
    #   cluster.
    # :set ::
    #   Unconditionally store the item in the cluster
    # :append ::
    #   Rather than setting the contents of the entire document, take the value
    #   specified in lcb_CMDSTORE::value and _append_ it to the existing bytes in
    #   the value.
    #
    #   This is functionally equivalent to the following:
    #   @code{.c}
    #   static void get_callback(lcb_t instance, int cbtype, const lcb_RESPBASE *rb)
    #   {
    #       const lcb_RESPGET *resp = (const lcb_RESPGET *)rb;
    #       const char *to_append = "stuff to append";
    #       char *new_value;
    #       size_t new_value_len;
    #       lcb_CMDSTORE cmd = { 0 };
    #       lcb_IOV iov(2);
    #       cmd.operation = LCB_APPEND;
    #       iov(0).iov_base = (void *)resp->value;
    #       iov(0).iov_len = resp->nvalue;
    #       iov(1).iov_base = (void *)to_append;
    #       iov(1).iov_len = strlen(to_append);
    #       LCB_CMD_SET_VALUEIOV(&cmd, iov, 2);
    #       LCB_CMD_SET_KEY(&cmd, resp->key, resp->nkey);
    #       lcb_store3(instance, NULL, &cmd);
    #   }
    #   @endcode
    # :prepend ::
    #   Like ::LCB_APPEND, but prepends the new value to the existing value.
    #
    # @method _enum_storage_t_
    # @return [Symbol]
    # @scope class
    enum :storage_t, [
      :add, 1,
      :replace, 2,
      :set, 3,
      :append, 4,
      :prepend, 5
    ]

    # @brief
    #
    # Command for storing an item to the server. This command must contain the
    # key to mutate, the value which should be set (or appended/prepended) in the
    # lcb_CMDSTORE::value field (see LCB_CMD_SET_VALUE()) and the operation indicating
    # the mutation type (lcb_CMDSTORE::operation).
    #
    # @warning #exptime *cannot* be used with #operation set to @ref LCB_APPEND
    # or @ref LCB_PREPEND.
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :value ::
    #   (unknown) Value to store on the server. The value may be set using the
    #   LCB_CMD_SET_VALUE() or LCB_CMD_SET_VALUEIOV() API
    # :flags ::
    #   (Integer) Format flags used by clients to determine the underlying encoding of
    #   the value. This value is also returned during retrieval operations in the
    #   lcb_RESPGET::itmflags field
    # :datatype ::
    #   (Integer) Do not set this value for now
    # :operation ::
    #   (Symbol from _enum_storage_t_) Controls *how* the operation is perfomed. See the documentation for
    #   @ref lcb_storage_t for the options. There is no default value for this
    #   field.
    class CMDSTORE < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :value, :char,
             :flags, :int,
             :datatype, :int,
             :operation, :storage_t
    end

    # @brief Response structure for lcb_store3()
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :op ::
    #   (Symbol from _enum_storage_t_) The type of operation which was performed
    class RESPSTORE < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :op, :storage_t
    end

    # @committed
    # @brief Schedule a single storage request
    # @param instance the handle
    # @param cookie pointer to associate with the command
    # @param cmd the command structure
    # @return LCB_SUCCESS on success, error code on failure
    #
    # ### Request
    #
    # @code{.c}
    # lcb_CMDSTORE cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "Key", 3);
    # LCB_CMD_SET_VALUE(&cmd, "value", 5);
    # cmd.operation = LCB_ADD; // Only create if it does not exist
    # cmd.exptime = 60; // expire in a minute
    # lcb_store3(instance, cookie, &cmd);
    # lcb_wait3(instance, LCB_WAIT_NOCHECK);
    # @endcode
    #
    # ### Response
    # @code{.c}
    # lcb_install_callback3(instance, LCB_CALLBACK_STORE, store_callback);
    # void store_callback(lcb_t instance, int cbtype, const lcb_RESPBASE *rb)
    # {
    #     if (rb->rc == LCB_SUCCESS) {
    #         printf("Store success: CAS=%llx\n", rb->cas);
    #     } else {
    #         printf("Store failed: %s\n", lcb_strerorr(NULL, rb->rc);
    #     }
    # }
    # @endcode
    #
    # Operation-specific error codes include:
    # @cb_err ::LCB_KEY_ENOENT if ::LCB_REPLACE was used and the key does not exist
    # @cb_err ::LCB_KEY_EEXISTS if ::LCB_ADD was used and the key already exists
    # @cb_err ::LCB_KEY_EEXISTS if the CAS was specified (for an operation other
    #          than ::LCB_ADD) and the item exists on the server with a different
    #          CAS
    # @cb_err ::LCB_KEY_EEXISTS if the item was locked and the CAS supplied did
    # not match the locked item's CAS (or if no CAS was supplied)
    # @cb_err ::LCB_NOT_STORED if an ::LCB_APPEND or ::LCB_PREPEND operation was
    # performed and the item did not exist on the server.
    # @cb_err ::LCB_E2BIG if the size of the value exceeds the cluster per-item
    #         value limit (currently 20MB).
    #
    #
    # @note After a successful store operation you can use lcb_endure3_ctxnew()
    # to wait for the item to be persisted and/or replicated to other nodes.
    #
    # @method store3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDSTORE] cmd
    # @return [unknown]
    # @scope class
    attach_function :store3, :lcb_store3, [St, :pointer, CMDSTORE], :char

    # @committed
    # @brief Spool a removal of an item
    # @param instance the handle
    # @param cookie pointer to associate with the request
    # @param cmd the command
    # @return LCB_SUCCESS on success, other code on failure
    #
    # ### Request
    # @code{.c}
    # lcb_CMDREMOVE cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "deleteme", strlen("deleteme"));
    # lcb_remove3(instance, cookie, &cmd);
    # @endcode
    #
    # ### Response
    # @code{.c}
    # lcb_install_callback3(instance, LCB_CALLBACK_REMOVE, rm_callback);
    # void rm_callback(lcb_t instance, int cbtype, const lcb_RESPBASE *rb)
    # {
    #     printf("Key: %.*s...", (int)resp->nkey, resp->key);
    #     if (rb->rc != LCB_SUCCESS) {
    #         printf("Failed to remove item!: %s\n", lcb_strerror(NULL, rb->rc));
    #     } else {
    #         printf("Removed item!\n");
    #     }
    # }
    # @endcode
    #
    # The following operation-specific error codes are returned in the callback
    # @cb_err ::LCB_KEY_ENOENT if the key does not exist
    # @cb_err ::LCB_KEY_EEXISTS if the CAS was specified and it does not match the
    #         CAS on the server
    # @cb_err ::LCB_KEY_EEXISTS if the item was locked and no CAS (or an incorrect
    #         CAS) was specified.
    #
    # @method remove3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDBASE] cmd
    # @return [unknown]
    # @scope class
    attach_function :remove3, :lcb_remove3, [St, :pointer, CMDBASE], :char

    # Multi Command Context API
    # Some commands (notably, OBSERVE and its higher level equivalent, endue)
    # are handled more efficiently at the cluster side by stuffing multiple
    # items into a single packet.
    #
    # This structure defines three function pointers to invoke. The #addcmd()
    # function will add a new command to the current packet, the #done()
    # function will schedule the packet(s) into the current scheduling context
    # and the #fail() function will destroy the context without progressing
    # further.
    #
    # Some commands will return an lcb_MULTICMD_CTX object to be used for this
    # purpose:
    #
    # @code{.c}
    # lcb_MUTLICMD_CTX *ctx = lcb_observe3_ctxnew(instance);
    #
    # lcb_CMDOBSERVE cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "key1", strlen("key1"));
    # ctx->addcmd(ctx, &cmd);
    # LCB_CMD_SET_KEY(&cmd.key, "key2", strlen("key2"));
    # ctx->addcmd(ctx, &cmd);
    # LCB_CMD_SET_KEY(&cmd.key, "key3", strlen("key3"));
    # ctx->addcmd(ctx, &cmd);
    #
    # ctx->done(ctx);
    # lcb_wait(instance);
    # @endcode
    #
    # = Fields:
    # :addcmd ::
    #   (FFI::Pointer(*)) Add a command to the current context
    #   @param ctx the context
    #   @param cmd the command to add. Note that `cmd` may be a subclass of lcb_CMDBASE
    #   @return LCB_SUCCESS, or failure if a command could not be added.
    # :done ::
    #   (FFI::Pointer(*)) Indicate that no more commands are added to this context, and that the
    #   context should assemble the packets and place them in the current
    #   scheduling context
    #   @param ctx The multi context
    #   @param cookie The cookie for all commands
    #   @return LCB_SUCCESS if scheduled successfully, or an error code if there
    #   was a problem constructing the packet(s).
    # :fail ::
    #   (FFI::Pointer(*)) Indicate that no more commands should be added to this context, and that
    #   the context should not add its contents to the packet queues, but rather
    #   release its resources. Called if you don't want to actually perform
    #   the operations.
    #   @param ctx
    class MULTICMDCTXSt < FFI::Struct
      layout :addcmd, :pointer,
             :done, :pointer,
             :fail, :pointer
    end

    # Type of durability polling to use.
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:durmode).</em>
    #
    # === Options:
    # :durability_mode_default ::
    #   Use the preferred durability. If ::LCB_CNTL_FETCH_MUTATION_TOKENS is
    #   enabled and the server version is 4.0 or greater then ::LCB_DURABILITY_MODE_SEQNO
    #   is used. Otherwise ::LCB_DURABILITY_MODE_CAS is used.
    # :durability_mode_cas ::
    #   Explicitly request CAS-based durability. This is done by checking the
    #   CAS of the item on each server with the item specified in the input.
    #   The durability operation is considered complete when all items' CAS
    #   values match. If the CAS value on the master node changes then the
    #   durability operation will fail with ::LCB_KEY_EEXISTS.
    #
    #   @note
    #   CAS may change either because of a failover or because of another
    #   subsequent mutation. These scenarios are possible (though unlikely).
    #   The ::LCB_DURABILITY_MODE_SEQNO mode is not subject to these constraints.
    # :durability_mode_seqno ::
    #   Use sequence-number based polling. This is done by checking the current
    #   "mutation sequence number" for the given mutation. To use this mode
    #   either an explicit @ref lcb_MUTATION_TOKEN needs to be passed, or
    #   the ::LCB_CNTL_DURABILITY_MUTATION_TOKENS should be set, allowing
    #   the caching of the latest mutation token for each vBucket.
    #
    # @method _enum_durmode_
    # @return [Symbol]
    # @scope class
    enum :durmode, [
      :durability_mode_default, 0,
      :durability_mode_cas, 1,
      :durability_mode_seqno, 2
    ]

    # @brief Options for lcb_endure3_ctxnew()
    #
    # = Fields:
    # :timeout ::
    #   (Integer) Upper limit in microseconds from the scheduling of the command. When
    #   this timeout occurs, all remaining non-verified keys will have their
    #   callbacks invoked with @ref LCB_ETIMEDOUT.
    #
    #   If this field is not set, the value of @ref LCB_CNTL_DURABILITY_TIMEOUT
    #   will be used.
    # :interval ::
    #   (Integer) The durability check may involve more than a single call to observe - or
    #   more than a single packet sent to a server to check the key status. This
    #   value determines the time to wait (in microseconds)
    #   between multiple probes for the same server.
    #   If not set, the @ref LCB_CNTL_DURABILITY_INTERVAL will be used
    #   instead.
    # :persist_to ::
    #   (Integer) how many nodes the key should be persisted to (including master).
    #   If set to 0 then persistence will not be checked. If set to a large
    #   number (i.e. UINT16_MAX) and #cap_max is also set, will be set to the
    #   maximum number of nodes to which persistence is possible (which will
    #   always contain at least the master node).
    #
    #   The maximum valid value for this field is
    #   1 + the total number of configured replicas for the bucket which are part
    #   of the cluster. If this number is higher then it will either be
    #   automatically capped to the maximum available if (#cap_max is set) or
    #   will result in an ::LCB_DURABILITY_ETOOMANY error.
    # :replicate_to ::
    #   (Integer) how many nodes the key should be persisted to (excluding master).
    #   If set to 0 then replication will not be checked. If set to a large
    #   number (i.e. UINT16_MAX) and #cap_max is also set, will be set to the
    #   maximum number of nodes to which replication is possible (which may
    #   be 0 if the bucket is not configured for replicas).
    #
    #   The maximum valid value for this field is the total number of configured
    #   replicas which are part of the cluster. If this number is higher then
    #   it will either be automatically capped to the maximum available
    #   if (#cap_max is set) or will result in an ::LCB_DURABILITY_ETOOMANY
    #   error.
    # :check_delete ::
    #   (Integer) this flag inverts the sense of the durability check and ensures that
    #   the key does *not* exist. This should be used if checking durability
    #   after an lcb_remove3() operation.
    # :cap_max ::
    #   (Integer) If replication/persistence requirements are excessive, cap to
    #   the maximum available
    # :pollopts ::
    #   (Integer) Set the polling method to use.
    #   The value for this field should be one of the @ref lcb_DURMODE constants.
    class DURABILITYOPTSv0 < FFI::Struct
      layout :timeout, :int,
             :interval, :int,
             :persist_to, :int,
             :replicate_to, :int,
             :check_delete, :int,
             :cap_max, :int,
             :pollopts, :int
    end

    # (Not documented)
    #
    # = Fields:
    # :v0 ::
    #   (DURABILITYOPTSv0)
    class DurabilityOptsStV < FFI::Union
      layout :v0, DURABILITYOPTSv0.by_value
    end

    # @brief Options for lcb_endure3_ctxnew() (wrapper)
    # @see lcb_DURABILITYOPTSv0
    #
    # = Fields:
    # :version ::
    #   (Integer)
    # :v ::
    #   (DurabilityOptsStV)
    class DurabilityOptsSt < FFI::Struct
      layout :version, :int,
             :v, DurabilityOptsStV.by_value
    end

    # @brief Command structure for endure.
    # If the lcb_CMDENDURE::cas field is specified, the operation will check and
    # verify that the CAS found on each of the nodes matches the CAS specified
    # and only then consider the item to be replicated and/or persisted to the
    # nodes. If the item exists on the master's cache with a different CAS then
    # the operation will fail
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :mutation_token ::
    #   (MUTATIONTOKEN)
    class CMDENDURE < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :mutation_token, MUTATIONTOKEN
    end

    # @brief Response structure for endure
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :nresponses ::
    #   (Integer) Total number of polls (i.e. how many packets per server) did this
    #   operation require
    # :exists_master ::
    #   (Integer) Whether this item exists in the master in its current form. This can be
    #   true even if #rc is not successful
    # :persisted_master ::
    #   (Integer) True if item was persisted on the master node. This may be true even if
    #   #rc is not successful.
    # :npersisted ::
    #   (Integer) Total number of nodes (including master) on which this mutation has
    #   been persisted. Valid even if #rc is not successful.
    # :nreplicated ::
    #   (Integer) Total number of replica nodes to which this mutation has been replicated.
    #   Valid even if #rc is not successful.
    class RESPENDURE < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :nresponses, :int,
             :exists_master, :int,
             :persisted_master, :int,
             :npersisted, :int,
             :nreplicated, :int
    end

    # @committed
    #
    # @details
    # Ensure a key is replicated to a set of nodes
    #
    # The lcb_endure3_ctxnew() API is used to wait asynchronously until the item
    # have been persisted and/or replicated to at least the number of nodes
    # specified in the durability options.
    #
    # The command is implemented by sending a series of `OBSERVE` broadcasts
    # (see lcb_observe3_ctxnew()) to all the nodes in the cluster which are either
    # master or replica for a specific key. It polls repeatedly
    # (see lcb_DURABILITYOPTSv0::interval) until all the items have been persisted and/or
    # replicated to the number of nodes specified in the criteria, or the timeout
    # (aee lcb_DURABILITYOPTsv0::timeout) has been reached.
    #
    # The lcb_DURABILITYOPTSv0::persist_to and lcb_DURABILITYOPTS::replicate_to
    # control the number of nodes the item must be persisted/replicated to
    # in order for the durability polling to succeed.
    #
    # @brief Return a new command context for scheduling endure operations
    # @param instance the instance
    # @param options a structure containing the various criteria needed for
    # durability requirements
    # @param(out) err Error code if a new context could not be created
    # @return the new context, or NULL on error. Note that in addition to memory
    # allocation failure, this function might also return NULL because the `options`
    # structure contained bad values. Always check the `err` result.
    #
    # @par Scheduling Errors
    # The following errors may be encountered when scheduling:
    #
    # @cb_err ::LCB_DURABILITY_ETOOMANY if either lcb_DURABILITYOPTS::persist_to or
    # lcb_DURABILITYOPTS::replicate_to is too big. `err` may indicate this.
    # @cb_err ::LCB_DURABILITY_NO_MUTATION_TOKENS if no relevant mutation token
    # could be found for a given command (this is returned from the relevant
    # lcb_MULTICMD_CTX::addcmd call).
    # @cb_err ::LCB_DUPLICATE_COMMANDS if using CAS-based durability and the
    # same key was submitted twice to lcb_MULTICMD_CTX::addcmd(). This error is
    # returned from lcb_MULTICMD_CTX::done()
    #
    # @par Callback Errors
    # The following errors may be returned in the callback:
    # @cb_err ::LCB_ETIMEDOUT if the criteria could not be verified within the
    # accepted timeframe (see lcb_DURABILITYOPTSv0::timeout)
    # @cb_err ::LCB_KEY_EEXISTS if using CAS-based durability and the item's
    # CAS has been changed on the master node
    # @cb_err ::LCB_MUTATION_LOST if using sequence-based durability and the
    # server has detected that data loss has occurred due to a failover.
    #
    # @par Creating request context
    # @code{.c}
    # lcb_durability_opts_t dopts;
    # lcb_error_t rc;
    # memset(&dopts, 0, sizeof dopts);
    # dopts.v.v0.persist_to = -1;
    # dopts.v.v0.replicate_to = -1;
    # dopts.v.v0.cap_max = 1;
    # mctx = lcb_endure3_ctxnew(instance, &dopts, &rc);
    # // Check mctx != NULL and rc == LCB_SUCCESS
    # @endcode
    #
    # @par Adding keys - CAS
    # This can be used to add keys using CAS-based durability. This shows an
    # example within a store callback.
    # @code{.c}
    # lcb_RESPSTORE *resp = get_store_response();
    # lcb_CMDENDURE cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, resp->key, resp->nkey);
    # cmd.cas = resp->cas;
    # rc = mctx->addcmd(mctx, (const lcb_CMDBASE*)&cmd);
    # rc = mctx->done(mctx, cookie);
    # @endcode
    #
    # @par Adding keys - explicit sequence number
    # Shows how to use an explicit sequence number as a basis for polling
    # @code{.c}
    # // during instance creation:
    # lcb_cntl_string(instance, "fetch_mutation_tokens", "true");
    # lcb_connect(instance);
    # // ...
    # lcb_RESPSTORE *resp = get_store_response();
    # lcb_CMDENDURE cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, resp->key, resp->nkey);
    # cmd.mutation_token = &resp->mutation_token;
    # cmd.cmdflags |= LCB_CMDENDURE_F_MUTATION_TOKEN;
    # rc = mctx->addcmd(mctx, (const lcb_CMDBASE*)&cmd);
    # rc = mctx->done(mctx, cookie);
    # @endcode
    #
    # @par Adding keys - implicit sequence number
    # Shows how to use an implicit mutation token (internally tracked by the
    # library) for durability:
    # @code{.c}
    # // during instance creation
    # lcb_cntl_string(instance, "fetch_mutation_tokens", "true");
    # lcb_cntl_string(instance, "dur_mutation_tokens", "true");
    # lcb_connect(instance);
    # // ...
    # lcb_CMDENDURE cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "key", strlen("key"));
    # mctx->addcmd(mctx, (const lcb_CMDBASE*)&cmd);
    # mctx->done(mctx, cookie);
    # @endcode
    #
    # @par Response
    # @code{.c}
    # lcb_install_callback3(instance, LCB_CALLBACK_ENDURE, dur_callback);
    # void dur_callback(lcb_t instance, int cbtype, const lcb_RESPBASE *rb)
    # {
    #     const lcb_RESPENDURE *resp = (const lcb_RESPENDURE*)rb;
    #     printf("Durability polling result for %.*s.. ", (int)resp->nkey, resp->key);
    #     if (resp->rc != LCB_SUCCESS) {
    #         printf("Failed: %s\n", lcb_strerror(NULL, resp->rc);
    #         return;
    #     }
    # }
    # @endcode
    #
    # @method endure3_ctxnew(instance, options, err)
    # @param [St] instance
    # @param [DurabilityOptsSt] options
    # @param [FFI::Pointer(*ErrorT)] err
    # @return [MULTICMDCTXSt]
    # @scope class
    attach_function :endure3_ctxnew, :lcb_endure3_ctxnew, [St, DurabilityOptsSt, :pointer], MULTICMDCTXSt

    # Command structure for lcb_storedur3()
    # This is much like @ref lcb_CMDSTORE, but also includes durability options.
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :value ::
    #   (unknown) < @see lcb_CMDSTORE::value
    # :flags ::
    #   (Integer) < @see lcb_CMDSTORE::flags
    # :datatype ::
    #   (Integer) < @private
    # :operation ::
    #   (Symbol from _enum_storage_t_) < @see lcb_CMDSTORE::operation
    # :persist_to ::
    #   (Integer) Number of nodes to persist to. If negative, will be capped at the maximum
    #   allowable for the current cluster.
    #   @see lcb_DURABILITYOPTSv0::persist_to
    # :replicate_to ::
    #   (Integer) Number of nodes to replicate to. If negative, will be capped at the maximum
    #   allowable for the current cluster.
    #   @see lcb_DURABILITYOPTSv0::replicate_to
    class CMDSTOREDUR < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :value, :char,
             :flags, :int,
             :datatype, :int,
             :operation, :storage_t,
             :persist_to, :char,
             :replicate_to, :char
    end

    # Response structure for `LCB_CALLBACK_STOREDUR.
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :dur_resp ::
    #   (RESPENDURE) Internal durability response structure. This should never be NULL
    # :store_ok ::
    #   (Integer) If the #rc field is not @ref LCB_SUCCESS, this field indicates
    #   what failed. If this field is nonzero, then the store operation failed,
    #   but the durability checking failed. If this field is zero then the
    #   actual storage operation failed.
    class RESPSTOREDUR < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :dur_resp, RESPENDURE,
             :store_ok, :int
    end

    # @brief Structure for an observe request.
    # To request the status from _only_ the master node of the key, set the
    # LCB_CMDOBSERVE_F_MASTERONLY bit inside the lcb_CMDOBSERVE::cmdflags field
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :servers ::
    #   (FFI::Pointer(*U16)) For internal use: This determines the servers the command should be
    #   routed to. Each entry is an index within the server.
    # :nservers ::
    #   (Integer)
    class CMDOBSERVE < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :servers, :pointer,
             :nservers, :int
    end

    # @brief Possible statuses for keys in OBSERVE response
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:observe_t).</em>
    #
    # === Options:
    # :found ::
    #   The item found in the memory, but not yet on the disk
    # :persisted ::
    #   The item hit the disk
    # :not_found ::
    #   The item missing on the disk and the memory
    # :logically_deleted ::
    #   No knowledge of the key :)
    # :max ::
    #
    #
    # @method _enum_observe_t_
    # @return [Symbol]
    # @scope class
    enum :observe_t, [
      :found, 0,
      :persisted, 1,
      :not_found, 128,
      :logically_deleted, 129,
      :max, 130
    ]

    # @brief Response structure for an observe command.
    # Note that the lcb_RESPOBSERVE::cas contains the CAS of the item as it is
    # stored within that specific server. The CAS may be incorrect or stale
    # unless lcb_RESPOBSERVE::ismaster is true.
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :status ::
    #   (Integer) <Bit set of flags
    # :ismaster ::
    #   (Integer) < Set to true if this response came from the master node
    # :ttp ::
    #   (Integer) <Unused. For internal requests, contains the server index
    # :ttr ::
    #   (Integer) <Unused
    class RESPOBSERVE < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :status, :int,
             :ismaster, :int,
             :ttp, :int,
             :ttr, :int
    end

    # @committed
    # @brief Create a new multi context for an observe operation
    # @param instance the instance
    # @return a new multi command context, or NULL on allocation failure.
    #
    # Note that the callback for this command will be invoked multiple times,
    # one for each node. To determine when no more callbacks will be invoked,
    # check for the LCB_RESP_F_FINAL flag inside the lcb_RESPOBSERVE::rflags
    # field.
    #
    # @code{.c}
    # void callback(lcb_t, lcb_CALLBACKTYPE, const lcb_RESPOBSERVE *resp)
    # {
    #   if (resp->rflags & LCB_RESP_F_FINAL) {
    #     return;
    #   }
    #
    #   printf("Got status for key %.*s\n", (int)resp->nkey, resp->key);
    #   printf("  Node Type: %s\n", resp->ismaster ? "MASTER" : "REPLICA");
    #   printf("  Status: 0x%x\n", resp->status);
    #   printf("  Current CAS: 0x%"PRIx64"\n", resp->cas);
    # }
    #
    # lcb_MULTICMD_CTX *mctx = lcb_observe3_ctxnew(instance);
    # lcb_CMDOBSERVE cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "key", 3);
    # mctx->addcmd(mctx, (lcb_CMDBASE *)&cmd);
    # mctx->done(mctx, cookie);
    # lcb_install_callback3(instance, LCB_CALLBACK_OBSERVE, (lcb_RESP_cb)callback);
    # @endcode
    #
    # @warning
    # Operations created by observe cannot be undone using lcb_sched_fail().
    #
    # @method observe3_ctxnew(instance)
    # @param [St] instance
    # @return [MULTICMDCTXSt]
    # @scope class
    attach_function :observe3_ctxnew, :lcb_observe3_ctxnew, [St], MULTICMDCTXSt

    # @brief Command structure for lcb_observe_seqno3().
    # Note #key, #nkey, and #cas are not used in this command.
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :server_index ::
    #   (Integer) Server index to target. The server index must be valid and must also
    #   be either a master or a replica for the vBucket indicated in #vbid
    # :vbid ::
    #   (Integer) < vBucket ID to query
    # :uuid ::
    #   (Integer) < UUID known to client which should be queried
    class CMDOBSEQNO < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :server_index, :int,
             :vbid, :int,
             :uuid, :int
    end

    # @brief Response structure for lcb_observe_seqno3()
    #
    # Note that #key, #nkey and #cas are empty because the operand is the relevant
    # mutation token fields in @ref lcb_CMDOBSEQNO
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :vbid ::
    #   (Integer) < vBucket ID (for potential mapping)
    # :server_index ::
    #   (Integer) < Input server index
    # :cur_uuid ::
    #   (Integer) < UUID for this vBucket as known to the server
    # :persisted_seqno ::
    #   (Integer) < Highest persisted sequence
    # :mem_seqno ::
    #   (Integer) < Highest known sequence
    # :old_uuid ::
    #   (Integer) In the case where the command's uuid is not the most current, this
    #   contains the last known UUID
    # :old_seqno ::
    #   (Integer) If #old_uuid is nonzero, contains the highest sequence number persisted
    #   in the #old_uuid snapshot.
    class RESPOBSEQNO < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :vbid, :int,
             :server_index, :int,
             :cur_uuid, :int,
             :persisted_seqno, :int,
             :mem_seqno, :int,
             :old_uuid, :int,
             :old_seqno, :int
    end

    # @volatile
    # @brief Get the persistence/replication status for a given mutation token
    # @param instance the handle
    # @param cookie callback cookie
    # @param cmd the command
    #
    # @method observe_seqno3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDOBSEQNO] cmd
    # @return [unknown]
    # @scope class
    attach_function :observe_seqno3, :lcb_observe_seqno3, [St, :pointer, CMDOBSEQNO], :char

    # @brief Command for counter operations.
    # @see lcb_counter3(), lcb_RESPCOUNTER.
    #
    # @warning You may only set the #exptime member if the #create member is set
    # to a true value. Setting `exptime` otherwise will cause the operation to
    # fail with @ref LCB_OPTIONS_CONFLICT
    #
    # @warning The #cas member should be set to 0 for this operation. As this
    # operation itself is atomic, specifying a CAS is not necessary.
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :delta ::
    #   (Integer) Delta value. If this number is negative the item on the server is
    #   decremented. If this number is positive then the item on the server
    #   is incremented
    # :initial ::
    #   (Integer) If the item does not exist on the server (and `create` is true) then
    #   this will be the initial value for the item.
    # :create ::
    #   (Integer) Boolean value. Create the item and set it to `initial` if it does not
    #   already exist
    class CMDCOUNTER < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :delta, :int,
             :initial, :int,
             :create, :int
    end

    # @brief Response structure for counter operations
    # @see lcb_counter3()
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :value ::
    #   (Integer) Contains the _current_ value after the operation was performed
    class RESPCOUNTER < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :value, :int
    end

    # @committed
    # @brief Schedule single counter operation
    # @param instance the instance
    # @param cookie the pointer to associate with the request
    # @param cmd the command to use
    # @return LCB_SUCCESS on success, other error on failure
    #
    # @par Request
    # @code{.c}
    # lcb_CMDCOUNTER cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "counter", strlen("counter"));
    # cmd.delta = 1; // Increment by one
    # cmd.initial = 42; // Default value is 42 if it does not exist
    # cmd.exptime = 300; // Expire in 5 minutes
    # lcb_counter3(instance, NULL, &cmd);
    # lcb_wait3(instance, LCB_WAIT_NOCHECK);
    # @endcode
    #
    # @par Response
    # @code{.c}
    # lcb_install_callback3(instance, LCB_CALLBACKTYPE_COUNTER, counter_cb);
    # void counter_cb(lcb_t instance, int cbtype, const lcb_RESPBASE *rb)
    # {
    #     const lcb_RESPCOUNTER *resp = (const lcb_RESPCOUNTER *)rb;
    #     if (resp->rc == LCB_SUCCESS) {
    #         printf("Incremented counter for %.*s. Current value %llu\n",
    #                (int)resp->nkey, resp->key, resp->value);
    #     }
    # }
    # @endcode
    #
    # @par Callback Errors
    # In addition to generic errors, the following errors may be returned in the
    # callback (via lcb_RESPBASE::rc):
    #
    # @cb_err ::LCB_KEY_ENOENT if the counter doesn't exist
    # (and lcb_CMDCOUNTER::create was not set)
    # @cb_err ::LCB_DELTA_BADVAL if the existing document's content could not
    # be parsed as a number by the server.
    #
    # @method counter3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDCOUNTER] cmd
    # @return [unknown]
    # @scope class
    attach_function :counter3, :lcb_counter3, [St, :pointer, CMDCOUNTER], :char

    # @committed
    # @brief
    # Unlock a previously locked item using lcb_CMDGET::lock
    #
    # @param instance the instance
    # @param cookie the context pointer to associate with the command
    # @param cmd the command containing the information about the locked key
    # @return LCB_SUCCESS if successful, an error code otherwise
    # @see lcb_get3()
    #
    # @par Request
    #
    # @code{.c}
    # void locked_callback(lcb_t, lcb_CALLBACKTYPE, const lcb_RESPBASE *resp) {
    #   lcb_CMDUNLOCK cmd = { 0 };
    #   LCB_CMD_SET_KEY(&cmd, resp->key, resp->nkey);
    #   cmd.cas = resp->cas;
    #   lcb_unlock3(instance, cookie, &cmd);
    # }
    #
    # @endcode
    #
    # @method unlock3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDBASE] cmd
    # @return [unknown]
    # @scope class
    attach_function :unlock3, :lcb_unlock3, [St, :pointer, CMDBASE], :char

    # @committed
    # @brief Spool a touch request
    # @param instance the handle
    # @param cookie the pointer to associate with the request
    # @param cmd the command
    # @return LCB_SUCCESS on success, other error code on failure
    #
    # @par Request
    # @code{.c}
    # lcb_CMDTOUCH cmd = { 0 };
    # LCB_CMD_SET_KEY(&cmd, "keep_me", strlen("keep_me"));
    # cmd.exptime = 0; // Clear the expiration
    # lcb_touch3(instance, cookie, &cmd);
    # @endcode
    #
    # @par Response
    # @code{.c}
    # lcb_install_callback3(instance, LCB_CALLBACK_TOUCH, touch_callback);
    # void touch_callback(lcb_t instance, int cbtype, const lcb_RESPBASE *rb)
    # {
    #     if (rb->rc == LCB_SUCCESS) {
    #         printf("Touch succeeded\n");
    #     }
    # }
    # @endcode
    #
    # @method touch3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDBASE] cmd
    # @return [unknown]
    # @scope class
    attach_function :touch3, :lcb_touch3, [St, :pointer, CMDBASE], :char

    # @brief Response structure for cluster statistics.
    # The lcb_RESPSTATS::key field contains the statistic name (_not_ the same
    # as was passed in lcb_CMDSTATS::key which is the name of the statistical
    # _group_).
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :server ::
    #   (String)
    # :value ::
    #   (String) < The value, if any, for the given statistic
    # :nvalue ::
    #   (Integer) < Length of value
    class RESPSTATS < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :server, :string,
             :value, :string,
             :nvalue, :int
    end

    # @committed
    # @brief Schedule a request for statistics from the cluster.
    # @param instance the instance
    # @param cookie pointer to associate with the request
    # @param cmd the command
    # @return LCB_SUCCESS on success, other error code on failure.
    #
    # Note that the callback for this command is invoked an indeterminate amount
    # of times. The callback is invoked once for each statistic for each server.
    # When all the servers have responded with their statistics, a final callback
    # is delivered to the application with the LCB_RESP_F_FINAL flag set in the
    # lcb_RESPSTATS::rflags field. When this response is received no more callbacks
    # for this command shall be invoked.
    #
    # @par Request
    # @code{.c}
    # lcb_CMDSTATS cmd = { 0 };
    # // Using default stats, no further initialization
    # lcb_stats3(instance, fp, &cmd);
    # lcb_wait(instance);
    # @endcode
    #
    # @par Response
    # @code{.c}
    # lcb_install_callback3(instance, LCB_CALLBACK_STATS, stats_callback);
    # void stats_callback(lcb_t, int, const lcb_RESPBASE *rb)
    # {
    #     const lcb_RESPSTATS *resp = (const lcb_RESPSTATS*)rb;
    #     if (resp->key) {
    #         printf("Server %s: %.*s = %.*s\n", resp->server,
    #            (int)resp->nkey, resp->key,
    #            (int)resp->nvalue, resp->value);
    #     }
    #     if (resp->rflags & LCB_RESP_F_FINAL) {
    #       printf("No more replies remaining!\n");
    #     }
    # }
    # @endcode
    #
    # @method stats3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDBASE] cmd
    # @return [unknown]
    # @scope class
    attach_function :stats3, :lcb_stats3, [St, :pointer, CMDBASE], :char

    # @brief Response structure for the version command
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :server ::
    #   (String)
    # :mcversion ::
    #   (String) < The version string
    # :nversion ::
    #   (Integer) < Length of the version string
    class RESPMCVERSION < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :server, :string,
             :mcversion, :string,
             :nversion, :int
    end

    # @volatile
    #
    # @method server_versions3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDBASE] cmd
    # @return [unknown]
    # @scope class
    attach_function :server_versions3, :lcb_server_versions3, [St, :pointer, CMDBASE], :char

    # @brief `level` field for lcb_server_verbosity3 ()
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:verbosity_level_t).</em>
    #
    # === Options:
    # :detail ::
    #
    # :debug ::
    #
    # :info ::
    #
    # :warning ::
    #
    #
    # @method _enum_verbosity_level_t_
    # @return [Symbol]
    # @scope class
    enum :verbosity_level_t, [
      :detail, 0,
      :debug, 1,
      :info, 2,
      :warning, 3
    ]

    # (Not documented)
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :server ::
    #   (String)
    # :level ::
    #   (Symbol from _enum_verbosity_level_t_)
    class CMDVERBOSITY < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :server, :string,
             :level, :verbosity_level_t
    end

    # @volatile
    #
    # @method server_verbosity3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDVERBOSITY] cmd
    # @return [unknown]
    # @scope class
    attach_function :server_verbosity3, :lcb_server_verbosity3, [St, :pointer, CMDVERBOSITY], :char

    # @uncomitted
    #
    # Flush a bucket
    # This function will properly flush any type of bucket using the REST API
    # via HTTP. This may be used in a manner similar to the older lcb_flush3().
    #
    # The callback invoked under ::LCB_CALLBACK_CBFLUSH will be invoked with either
    # a success or failure status depending on the outcome of the operation. Note
    # that in order for lcb_cbflush3() to succeed, flush must already be enabled
    # on the bucket via the administrative interface.
    #
    # @param instance the library handle
    # @param cookie the cookie passed in the callback
    # @param cmd empty command structure. Currently there are no options for this
    #  command.
    # @return status code for scheduling.
    #
    # @attention
    # Because this command is built using HTTP, this is not subject to operation
    # pipeline calls such as lcb_sched_enter()/lcb_sched_leave()
    #
    # @method cbflush3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDBASE] cmd
    # @return [unknown]
    # @scope class
    attach_function :cbflush3, :lcb_cbflush3, [St, :pointer, CMDBASE], :char

    # @volatile
    # @deprecated
    #
    # @method flush3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDBASE] cmd
    # @return [unknown]
    # @scope class
    attach_function :flush3, :lcb_flush3, [St, :pointer, CMDBASE], :char

    # @brief The type of HTTP request to execute
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:http_type_t).</em>
    #
    # === Options:
    # :view ::
    #   Execute a request against the bucket. The handle must be of
    #   @ref LCB_TYPE_BUCKET and must be connected.
    # :management ::
    #   Execute a management API request. The credentials used will match
    #   those passed during the instance creation time. Thus is the instance
    #   type is @ref LCB_TYPE_BUCKET then only bucket-level credentials will
    #   be used.
    # :raw ::
    #   Execute an arbitrary request against a host and port
    # :n1ql ::
    #   Execute an N1QL Query
    # :fts ::
    #   Search a fulltext index
    # :max ::
    #
    #
    # @method _enum_http_type_t_
    # @return [Symbol]
    # @scope class
    enum :http_type_t, [
      :view, 0,
      :management, 1,
      :raw, 2,
      :n1ql, 3,
      :fts, 4,
      :max, 5
    ]

    # @brief HTTP Request method enumeration
    # These just enumerate the various types of HTTP request methods supported.
    # Refer to the specific cluster or view API to see which method is appropriate
    # for your request
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:http_method_t).</em>
    #
    # === Options:
    # :get ::
    #
    # :post ::
    #
    # :put ::
    #
    # :delete ::
    #
    # :max ::
    #
    #
    # @method _enum_http_method_t_
    # @return [Symbol]
    # @scope class
    enum :http_method_t, [
      :get, 0,
      :post, 1,
      :put, 2,
      :delete, 3,
      :max, 4
    ]

    # Structure for performing an HTTP request.
    # Note that the key and nkey fields indicate the _path_ for the API
    #
    # = Fields:
    # :cmdflags ::
    #   (Integer)
    # :exptime ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :key ::
    #   (unknown)
    # :hashkey ::
    #   (unknown)
    # :type ::
    #   (Symbol from _enum_http_type_t_) Type of request to issue. LCB_HTTP_TYPE_VIEW will issue a request
    #   against a random node's view API. LCB_HTTP_TYPE_MANAGEMENT will issue
    #   a request against a random node's administrative API, and
    #   LCB_HTTP_TYPE_RAW will issue a request against an arbitrary host.
    # :method ::
    #   (Symbol from _enum_http_method_t_) < HTTP Method to use
    # :body ::
    #   (String) If the request requires a body (e.g. `PUT` or `POST`) then it will
    #   go here. Be sure to indicate the length of the body too.
    # :nbody ::
    #   (Integer) Length of the body for the request
    # :reqhandle ::
    #   (FFI::Pointer(*HttpRequestT)) If non-NULL, will be assigned a handle which may be used to
    #   subsequently cancel the request
    # :content_type ::
    #   (String) For views, set this to `application/json`
    # :username ::
    #   (String) Username to authenticate with, if left empty, will use the credentials
    #   passed to lcb_create()
    # :password ::
    #   (String) Password to authenticate with, if left empty, will use the credentials
    #   passed to lcb_create()
    # :host ::
    #   (String) If set, this must be a string in the form of `http://host:port`. Should
    #   only be used for raw requests.
    class CMDHTTP < FFI::Struct
      layout :cmdflags, :int,
             :exptime, :int,
             :cas, :int,
             :key, :char,
             :hashkey, :char,
             :type, :http_type_t,
             :method, :http_method_t,
             :body, :string,
             :nbody, :int,
             :reqhandle, :pointer,
             :content_type, :string,
             :username, :string,
             :password, :string,
             :host, :string
    end

    # Structure for HTTP responses.
    # Note that #rc being `LCB_SUCCESS` does not always indicate that the HTTP
    # request itself was successful. It only indicates that the outgoing request
    # was submitted to the server and the client received a well-formed HTTP
    # response. Check the #hstatus field to see the actual HTTP-level status
    # code received.
    #
    # = Fields:
    # :cookie ::
    #   (FFI::Pointer(*Void))
    # :key ::
    #   (FFI::Pointer(*Void))
    # :nkey ::
    #   (Integer)
    # :cas ::
    #   (Integer)
    # :rc ::
    #   (unknown)
    # :version ::
    #   (Integer)
    # :rflags ::
    #   (Integer)
    # :htstatus ::
    #   (Integer) HTTP status code. The value is only valid if #rc is ::LCB_SUCCESS
    #   (if #rc is not LCB_SUCCESS then this field may be 0 as the response may
    #   have not been read/sent)
    # :headers ::
    #   (FFI::Pointer(**CharS)) List of key-value headers. This field itself may be `NULL`. The list
    #   is terminated by a `NULL` pointer to indicate no more headers.
    # :body ::
    #   (FFI::Pointer(*Void)) If @ref LCB_CMDHTTP_F_STREAM is true, contains the current chunk
    #   of response content. Otherwise, contains the entire response body.
    # :nbody ::
    #   (Integer) Length of buffer in #body
    # :htreq ::
    #   (HttpRequestSt) @private
    class RESPHTTP < FFI::Struct
      layout :cookie, :pointer,
             :key, :pointer,
             :nkey, :int,
             :cas, :int,
             :rc, :char,
             :version, :int,
             :rflags, :int,
             :htstatus, :short,
             :headers, :pointer,
             :body, :pointer,
             :nbody, :int,
             :htreq, HttpRequestSt
    end

    # @committed
    # Issue an HTTP API request.
    # @param instance the library handle
    # @param cookie cookie to be associated with the request
    # @param cmd the command
    # @return LCB_SUCCESS if the request was scheduled successfully.
    #
    #
    # @par Simple Response
    # @code{.c}
    # void http_callback(lcb_t, int, const lcb_RESPBASE *rb)
    # {
    #     const lcb_RESPHTTP *resp = (const lcb_RESPHTTP *)rb;
    #     if (resp->rc != LCB_SUCCESS) {
    #         printf("I/O Error for HTTP: %s\n", lcb_strerror(NULL, resp->rc));
    #         return;
    #     }
    #     printf("Got HTTP Status: %d\n", resp->htstatus);
    #     printf("Got paylod: %.*s\n", (int)resp->nbody, resp->body);
    #     const char **hdrp = resp->headers;
    #     while (*hdrp != NULL) {
    #         printf("%s: %s\n", hdrp(0), hdrp(1));
    #         hdrp += 2;
    #     }
    # }
    # @endcode
    #
    # @par Streaming Response
    # If the @ref LCB_CMDHTTP_F_STREAM flag is set in lcb_CMDHTTP::cmdflags then the
    # response callback is invoked multiple times as data arrives off the socket.
    # @code{.c}
    # void http_strm_callback(lcb_t, int, const lcb_RESPBASE *rb)
    # {
    #     const lcb_RESPHTTP *resp = (const lcb_RESPHTTP *)resp;
    #     if (resp->rflags & LCB_RESP_F_FINAL) {
    #         if (resp->rc != LCB_SUCCESS) {
    #             // ....
    #         }
    #         const char **hdrp = resp->headers;
    #         // ...
    #     } else {
    #         handle_body(resp->body, resp->nbody);
    #     }
    # }
    # @endcode
    #
    # @par Connection Reuse
    # The library will attempt to reuse connections for frequently contacted hosts.
    # By default the library will keep one idle connection to each host for a maximum
    # of 10 seconds. The number of open idle HTTP connections can be controlled with
    # @ref LCB_CNTL_HTTP_POOLSIZE.
    #
    # @method http3(instance, cookie, cmd)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [CMDHTTP] cmd
    # @return [unknown]
    # @scope class
    attach_function :http3, :lcb_http3, [St, :pointer, CMDHTTP], :char

    # @brief Cancel ongoing HTTP request
    #
    # This API will stop the current request. Any pending callbacks will not be
    # invoked any any pending data will not be delivered. Useful for a long running
    # request which is no longer needed
    #
    # @param instance The handle to lcb
    # @param request The request handle
    #
    # @committed
    #
    # @par Example
    # @code{.c}
    # lcb_CMDHTTP htcmd = { 0 };
    # populate_htcmd(&htcmd); // dummy function
    # lcb_http_request_t reqhandle;
    # htcmd.reqhandle = &reqhandle;
    # lcb_http3(instance, cookie, &htcmd);
    # do_stuff();
    # lcb_cancel_http_request(instance, reqhandle);
    # @endcode
    #
    # @method cancel_http_request(instance, request)
    # @param [St] instance
    # @param [HttpRequestSt] request
    # @return [nil]
    # @scope class
    attach_function :cancel_http_request, :lcb_cancel_http_request, [St, HttpRequestSt], :void

    # Associate a cookie with an instance of lcb. The _cookie_ is a user defined
    # pointer which will remain attached to the specified `lcb_t` for its duration.
    # This is the way to associate user data with the `lcb_t`.
    #
    # @param instance the instance to associate the cookie to
    # @param cookie the cookie to associate with this instance.
    #
    # @attention
    # There is no destructor for the specified `cookie` stored with the instance;
    # thus you must ensure to manually free resources to the pointer (if it was
    # dynamically allocated) when it is no longer required.
    # @committed
    #
    # @code{.c}
    # typedef struct {
    #   const char *status;
    #   // ....
    # } instance_info;
    #
    # static void bootstrap_callback(lcb_t instance, lcb_error_t err) {
    #   instance_info *info = (instance_info *)lcb_get_cookie(instance);
    #   if (err == LCB_SUCCESS) {
    #     info->status = "Connected";
    #   } else {
    #     info->status = "Error";
    #   }
    # }
    #
    # static void do_create(void) {
    #   instance_info *info = calloc(1, sizeof(*info));
    #   // info->status is currently NULL
    #   // .. create the instance here
    #   lcb_set_cookie(instance, info);
    #   lcb_set_bootstrap_callback(instance, bootstrap_callback);
    #   lcb_connect(instance);
    #   lcb_wait(instance);
    #   printf("Status of instance is %s\n", info->status);
    # }
    # @endcode
    #
    # @method set_cookie(instance, cookie)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @return [nil]
    # @scope class
    attach_function :set_cookie, :lcb_set_cookie, [St, :pointer], :void

    # Retrieve the cookie associated with this instance
    # @param instance the instance of lcb
    # @return The cookie associated with this instance or NULL
    # @see lcb_set_cookie()
    # @committed
    #
    # @method get_cookie(instance)
    # @param [St] instance
    # @return [FFI::Pointer(*Void)]
    # @scope class
    attach_function :get_cookie, :lcb_get_cookie, [St], :pointer

    # @brief Wait for the execution of all batched requests
    #
    # A batched request is any request which requires network I/O.
    # This includes most of the APIs. You should _not_ use this API if you are
    # integrating with an asynchronous event loop (i.e. one where your application
    # code is invoked asynchronously via event loops).
    #
    # This function will block the calling thread until either
    #
    # * All operations have been completed
    # * lcb_breakout() is explicitly called
    #
    # @param instance the instance containing the requests
    # @return whether the wait operation failed, or LCB_SUCCESS
    # @committed
    #
    # @method wait(instance)
    # @param [St] instance
    # @return [unknown]
    # @scope class
    attach_function :wait, :lcb_wait, [St], :char

    # @brief Flags for lcb_wait3()
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:waitflags).</em>
    #
    # === Options:
    # :wait_default ::
    #   Behave like the old lcb_wait()
    # :wait_nocheck ::
    #   Do not check pending operations before running the event loop. By default
    #   lcb_wait() will traverse the server list to check if any operations are
    #   pending, and if nothing is pending the function will return without
    #   running the event loop. This is usually not necessary for applications
    #   which already _only_ call lcb_wait() when they know they have scheduled
    #   at least one command.
    #
    # @method _enum_waitflags_
    # @return [Symbol]
    # @scope class
    enum :waitflags, [
      :wait_default, 0,
      :wait_nocheck, 1
    ]

    # @committed
    # @brief Wait for completion of scheduled operations.
    # @param instance the instance
    # @param flags flags to modify the behavior of lcb_wait(). Pass 0 to obtain
    # behavior identical to lcb_wait().
    #
    # @method wait3(instance, flags)
    # @param [St] instance
    # @param [Symbol from _enum_waitflags_] flags
    # @return [nil]
    # @scope class
    attach_function :wait3, :lcb_wait3, [St, :waitflags], :void

    # @brief Forcefully break from the event loop.
    #
    # You may call this function from within any callback to signal to the library
    # that it return control to the function calling lcb_wait() as soon as possible.
    # Note that if there are pending functions which have not been processed, you
    # are responsible for calling lcb_wait() a second time.
    #
    # @param instance the instance to run the event loop for.
    # @committed
    #
    # @method breakout(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :breakout, :lcb_breakout, [St], :void

    # @brief Check if instance is blocked in the event loop
    # @param instance the instance to run the event loop for.
    # @return non-zero if nobody is waiting for IO interaction
    # @uncomitted
    #
    # @method is_waiting(instance)
    # @param [St] instance
    # @return [Integer]
    # @scope class
    attach_function :is_waiting, :lcb_is_waiting, [St], :int

    # @uncommitted
    #
    # @brief Force the library to refetch the cluster configuration
    #
    # The library by default employs various heuristics to determine if a new
    # configuration is needed from the cluster. However there are some situations
    # in which an application may wish to force a refresh of the configuration:
    #
    # * If a specific node has been failed
    #   over and the library has received a configuration in which there is no
    #   master node for a given key, the library will immediately return the error
    #   `LCB_NO_MATCHING_SERVER` for the given item and will not request a new
    #   configuration. In this state, the client will not perform any network I/O
    #   until a request has been made to it using a key that is mapped to a known
    #   active node.
    #
    # * The library's heuristics may have failed to detect an error warranting
    #   a configuration change, but the application either through its own
    #   heuristics, or through an out-of-band channel knows that the configuration
    #   has changed.
    #
    #
    # This function is provided as an aid to assist in such situations
    #
    # If you wish for your application to block until a new configuration is
    # received, you _must_ call lcb_wait3() with the LCB_WAIT_NO_CHECK flag as
    # this function call is not bound to a specific operation. Additionally there
    # is no status notification as to whether this operation succeeded or failed
    # (the configuration callback via lcb_set_configuration_callback() may
    # provide hints as to whether a configuration was received or not, but by no
    # means should be considered to be part of this function's control flow).
    #
    # In general the use pattern of this function is like so:
    #
    # @code{.c}
    # unsigned retries = 5;
    # lcb_error_t err;
    # do {
    #   retries--;
    #   err = lcb_get(instance, cookie, ncmds, cmds);
    #   if (err == LCB_NO_MATCHING_SERVER) {
    #     lcb_refresh_config(instance);
    #     usleep(100000);
    #     lcb_wait3(instance, LCB_WAIT_NO_CHECK);
    #   } else {
    #     break;
    #   }
    # } while (retries);
    # if (err == LCB_SUCCESS) {
    #   lcb_wait3(instance, 0); // equivalent to lcb_wait(instance);
    # } else {
    #   printf("Tried multiple times to fetch the key, but its node is down\n");
    # }
    # @endcode
    #
    # @method refresh_config(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :refresh_config, :lcb_refresh_config, [St], :void

    # @brief Enter a scheduling context.
    #
    # @uncommitted
    #
    # A scheduling context is an ephemeral list of
    # commands issued to various servers. Operations (like lcb_get3(), lcb_store3())
    # place packets into the current context.
    #
    # The context mechanism allows you to efficiently pipeline and schedule multiple
    # operations of different types and quantities. The network is not touched
    # and nothing is scheduled until the context is exited.
    #
    # @param instance the instance
    #
    # @code{.c}
    # lcb_sched_enter(instance);
    # lcb_get3(...);
    # lcb_store3(...);
    # lcb_counter3(...);
    # lcb_sched_leave(instance);
    # lcb_wait3(instance, LCB_WAIT_NOCHECK);
    # @endcode
    #
    # @method sched_enter(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :sched_enter, :lcb_sched_enter, [St], :void

    # @uncommitted
    #
    # @brief Leave the current scheduling context, scheduling the commands within the
    # context to be flushed to the network.
    #
    # @details This will initiate a network-level flush (depending on the I/O system)
    # to the network. For completion-based I/O systems this typically means
    # allocating a temporary write context to contain the buffer. If using a
    # completion-based I/O module (for example, Windows or libuv) then it is
    # recommended to limit the number of calls to one per loop iteration. If
    # limiting the number of calls to this function is not possible (for example,
    # if the legacy API is being used, or you wish to use implicit scheduling) then
    # the flushing may be decoupled from this function - see the documentation for
    # lcb_sched_flush().
    #
    # @param instance the instance
    #
    # @method sched_leave(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :sched_leave, :lcb_sched_leave, [St], :void

    # @uncommitted
    # @brief Fail all commands in the current scheduling context.
    #
    # The commands placed within the current
    # scheduling context are released and are never flushed to the network.
    # @param instance
    #
    # @warning
    # This function only affects commands which have a direct correspondence
    # to memcached packets. Currently these are commands scheduled by:
    #
    # * lcb_get3()
    # * lcb_rget3()
    # * lcb_unlock3()
    # * lcb_touch3()
    # * lcb_store3()
    # * lcb_counter3()
    # * lcb_remove3()
    # * lcb_stats3()
    # * lcb_observe3_ctxnew()
    # * lcb_observe_seqno3()
    #
    # Other commands are _compound_ commands and thus should be in their own
    # scheduling context.
    #
    # @method sched_fail(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :sched_fail, :lcb_sched_fail, [St], :void

    # @committed
    # @brief Request commands to be flushed to the network
    #
    # By default, the library will implicitly request a flush to the network upon
    # every call to lcb_sched_leave().
    #
    # ( Note, this does not mean the items are flushed
    # and I/O is performed, but it means the relevant event loop watchers are
    # activated to perform the operations on the next iteration ). If
    # @ref LCB_CNTL_SCHED_IMPLICIT_FLUSH
    # is disabled then this behavior is disabled and the
    # application must explicitly call lcb_sched_flush(). This may be considered
    # more performant in the cases where multiple discreet operations are scheduled
    # in an lcb_sched_enter()/lcb_sched_leave() pair. With implicit flush enabled,
    # each call to lcb_sched_leave() will possibly invoke system repeatedly.
    #
    # @method sched_flush(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :sched_flush, :lcb_sched_flush, [St], :void

    # Destroy (and release all allocated resources) an instance of lcb.
    # Using instance after calling destroy will most likely cause your
    # application to crash.
    #
    # Note that any pending operations will not have their callbacks invoked.
    #
    # @param instance the instance to destroy.
    # @committed
    #
    # @method destroy(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :destroy, :lcb_destroy, [St], :void

    # @brief Set the callback to be invoked when the instance is destroyed
    # asynchronously.
    # @return the previous callback.
    #
    # @method set_destroy_callback(st, destroy_callback)
    # @param [St] st
    # @param [FFI::Pointer(DestroyCallback)] destroy_callback
    # @return [FFI::Pointer(DestroyCallback)]
    # @scope class
    attach_function :set_destroy_callback, :lcb_set_destroy_callback, [St, :pointer], :pointer

    # @brief Asynchronously schedule the destruction of an instance.
    #
    # This function provides a safe way for asynchronous environments to destroy
    # the lcb_t handle without worrying about reentrancy issues.
    #
    # @param instance
    # @param arg a pointer passed to the callback.
    #
    # While the callback and cookie are optional, they are very much recommended
    # for testing scenarios where you wish to ensure that all resources allocated
    # by the instance have been closed. Specifically when the callback is invoked,
    # all timers (save for the one actually triggering the destruction) and sockets
    # will have been closed.
    #
    # As with lcb_destroy() you may call this function only once. You may not
    # call this function together with lcb_destroy as the two are mutually
    # exclusive.
    #
    # If for whatever reason this function is being called in a synchronous
    # flow, lcb_wait() must be invoked in order for the destruction to take effect
    #
    # @see lcb_set_destroy_callback
    #
    # @committed
    #
    # @method destroy_async(instance, arg)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] arg
    # @return [nil]
    # @scope class
    attach_function :destroy_async, :lcb_destroy_async, [St, :pointer], :void

    # @private
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:valueflags).</em>
    #
    # === Options:
    # :value_raw ::
    #
    # :value_f_json ::
    #
    # :value_f_snappycomp ::
    #
    #
    # @method _enum_valueflags_
    # @return [Symbol]
    # @scope class
    enum :valueflags, [
      :value_raw, 0,
      :value_f_json, 1,
      :value_f_snappycomp, 2
    ]

    # @brief
    # Type of node to retrieve for the lcb_get_node() function
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:getnodetype).</em>
    #
    # === Options:
    # :node_htconfig ::
    #   Get an HTTP configuration (Rest API) node
    # :node_data ::
    #   Get a data (memcached) node
    # :node_views ::
    #   Get a view (CAPI) node
    # :node_connected ::
    #   Only return a node which is connected, or a node which is known to be up
    # :node_nevernull ::
    #   Specifying this flag adds additional semantics which instruct the library
    #   to search additional resources to return a host, and finally,
    #   if no host can be found, return the string
    #   constant @ref LCB_GETNODE_UNAVAILABLE.
    # :node_htconfig_connected ::
    #   Equivalent to `LCB_NODE_HTCONFIG|LCB_NODE_CONNECTED`
    # :node_htconfig_any ::
    #   Equivalent to `LCB_NODE_HTCONFIG|LCB_NODE_NEVERNULL`.
    #   When this is passed, some additional attempts may be made by the library
    #   to return any kind of host, including searching the initial list of hosts
    #   passed to the lcb_create() function.
    #
    # @method _enum_getnodetype_
    # @return [Symbol]
    # @scope class
    enum :getnodetype, [
      :node_htconfig, 1,
      :node_data, 2,
      :node_views, 4,
      :node_connected, 8,
      :node_nevernull, 16,
      :node_htconfig_connected, 9,
      :node_htconfig_any, 17
    ]

    # @brief Return a string of `host:port` for a node of the given type.
    #
    # @param instance the instance from which to retrieve the node
    # @param type the type of node to return
    # @param index the node number if index is out of bounds it will be wrapped
    # around, thus there is never an invalid value for this parameter
    #
    # @return a string in the form of `host:port`. If LCB_NODE_NEVERNULL was specified
    # as an option in `type` then the string constant LCB_GETNODE_UNAVAILABLE is
    # returned. Otherwise `NULL` is returned if the type is unrecognized or the
    # LCB_NODE_CONNECTED option was specified and no connected node could be found
    # or a memory allocation failed.
    #
    # @note The index parameter is _ignored_ if `type` is
    # LCB_NODE_HTCONFIG|LCB_NODE_CONNECTED as there will always be only a single
    # HTTP bootstrap node.
    #
    # @code{.c}
    # const char *viewnode = lcb_get_node(instance, LCB_NODE_VIEWS, 0);
    # // Get the connected REST endpoint:
    # const char *restnode = lcb_get_node(instance, LCB_NODE_HTCONFIG|LCB_NODE_CONNECTED, 0);
    # if (!restnode) {
    #   printf("Instance not connected via HTTP!\n");
    # }
    # @endcode
    #
    # Iterate over all the data nodes:
    # @code{.c}
    # unsigned ii;
    # for (ii = 0; ii < lcb_get_num_servers(instance); ii++) {
    #   const char *kvnode = lcb_get_node(instance, LCB_NODE_DATA, ii);
    #   if (kvnode) {
    #     printf("KV node %s exists at index %u\n", kvnode, ii);
    #   } else {
    #     printf("No node for index %u\n", ii);
    #   }
    # }
    # @endcode
    #
    # @committed
    #
    # @method get_node(instance, type, index)
    # @param [St] instance
    # @param [Symbol from _enum_getnodetype_] type
    # @param [Integer] index
    # @return [String]
    # @scope class
    attach_function :get_node, :lcb_get_node, [St, :getnodetype, :uint], :string

    # @brief Get the number of the replicas in the cluster
    #
    # @param instance The handle to lcb
    # @return -1 if the cluster wasn't configured yet, and number of replicas
    # otherwise. This may be `0` if there are no replicas.
    # @committed
    #
    # @method get_num_replicas(instance)
    # @param [St] instance
    # @return [Integer]
    # @scope class
    attach_function :get_num_replicas, :lcb_get_num_replicas, [St], :int

    # @brief Get the number of the nodes in the cluster
    # @param instance The handle to lcb
    # @return -1 if the cluster wasn't configured yet, and number of nodes otherwise.
    # @committed
    #
    # @method get_num_nodes(instance)
    # @param [St] instance
    # @return [Integer]
    # @scope class
    attach_function :get_num_nodes, :lcb_get_num_nodes, [St], :int

    # @brief Get a list of nodes in the cluster
    #
    # @return a NULL-terminated list of 0-terminated strings consisting of
    # node hostnames:admin_ports for the entire cluster.
    # The storage duration of this list is only valid until the
    # next call to a libcouchbase function and/or when returning control to
    # libcouchbase' event loop.
    #
    # @code{.c}
    # const char * const * curp = lcb_get_server_list(instance);
    # for (; *curp; curp++) {
    #   printf("Have node %s\n", *curp);
    # }
    # @endcode
    # @committed
    #
    # @method get_server_list(instance)
    # @param [St] instance
    # @return [FFI::Pointer(**CharS)]
    # @scope class
    attach_function :get_server_list, :lcb_get_server_list, [St], :pointer

    # @volatile
    # @brief Write a textual dump to a file.
    #
    # This function will inspect the various internal structures of the current
    # client handle (indicated by `instance`) and write the state information
    # to the file indicated by `fp`.
    # @param instance the handle to dump
    # @param fp the file to which the dump should be written
    # @param flags a set of modifiers (of @ref lcb_DUMPFLAGS) indicating what
    # information to dump. Note that a standard set of information is always
    # dumped, but by default more verbose information is hidden, and may be
    # enabled with these flags.
    #
    # @method dump(instance, fp, flags)
    # @param [St] instance
    # @param [FFI::Pointer(*Int)] fp
    # @param [Integer] flags
    # @return [nil]
    # @scope class
    attach_function :dump, :lcb_dump, [St, :pointer, :int], :void

    # This function exposes an ioctl/fcntl-like interface to read and write
    # various configuration properties to and from an lcb_t handle.
    #
    # @param instance The instance to modify
    #
    # @param mode One of LCB_CNTL_GET (to retrieve a setting) or LCB_CNTL_SET
    #      (to modify a setting). Note that not all configuration properties
    #      support SET.
    #
    # @param cmd The specific command/property to modify. This is one of the
    #      LCB_CNTL_* constants defined in this file. Note that it is safe
    #      (and even recommanded) to use the raw numeric value (i.e.
    #      to be backwards and forwards compatible with libcouchbase
    #      versions), as they are not subject to change.
    #
    #      Using the actual value may be useful in ensuring your application
    #      will still compile with an older libcouchbase version (though
    #      you may get a runtime error (see return) if the command is not
    #      supported
    #
    # @param arg The argument passed to the configuration handler.
    #      The actual type of this pointer is dependent on the
    #      command in question.  Typically for GET operations, the
    #      value of 'arg' is set to the current configuration value;
    #      and for SET operations, the current configuration is
    #      updated with the contents of *arg.
    #
    # @return ::LCB_NOT_SUPPORTED if the code is unrecognized
    # @return ::LCB_EINVAL if there was a problem with the argument
    #         (typically for LCB_CNTL_SET) other error codes depending on the command.
    #
    # The following error codes are returned if the ::LCB_CNTL_DETAILED_ERRCODES
    # are enabled.
    #
    # @return ::LCB_ECTL_UNKNOWN if the code is unrecognized
    # @return ::LCB_ECTL_UNSUPPMODE An invalid _mode_ was passed
    # @return ::LCB_ECTL_BADARG if the value was invalid
    #
    # @committed
    #
    # @see lcb_cntl_setu32()
    # @see lcb_cntl_string()
    #
    # @method cntl(instance, mode, cmd, arg)
    # @param [St] instance
    # @param [Integer] mode
    # @param [Integer] cmd
    # @param [FFI::Pointer(*Void)] arg
    # @return [unknown]
    # @scope class
    attach_function :cntl, :lcb_cntl, [St, :int, :int, :pointer], :char

    # Alternate way to set configuration settings by passing a string key
    # and value. This may be used to provide a simple interface from a command
    # line or higher level language to allow the setting of specific key-value
    # pairs.
    #
    # The format for the value is dependent on the option passed, the following
    # value types exist:
    #
    # - **Timeout**. A _timeout_ value can either be specified as fractional
    #   seconds (`"1.5"` for 1.5 seconds), or in microseconds (`"1500000"`).
    # - **Number**. This is any valid numerical value. This may be signed or
    #   unsigned depending on the setting.
    # - **Boolean**. This specifies a boolean. A true value is either a positive
    #   numeric value (i.e. `"1"`) or the string `"true"`. A false value
    #   is a zero (i.e. `"0"`) or the string `"false"`.
    # - **Float**. This is like a _Number_, but also allows fractional specification,
    #   e.g. `"2.4"`.
    #
    # | Code | Name | Type
    # |------|------|-----
    # |@ref LCB_CNTL_OP_TIMEOUT                | `"operation_timeout"` | Timeout |
    # |@ref LCB_CNTL_VIEW_TIMEOUT              | `"view_timeout"`      | Timeout |
    # |@ref LCB_CNTL_DURABILITY_TIMEOUT        | `"durability_timeout"` | Timeout |
    # |@ref LCB_CNTL_DURABILITY_INTERVAL       | `"durability_interval"`| Timeout |
    # |@ref LCB_CNTL_HTTP_TIMEOUT              | `"http_timeout"`      | Timeout |
    # |@ref LCB_CNTL_RANDOMIZE_BOOTSTRAP_HOSTS | `"randomize_nodes"`   | Boolean|
    # |@ref LCB_CNTL_CONFERRTHRESH             | `"error_thresh_count"`| Number (Positive)|
    # |@ref LCB_CNTL_CONFDELAY_THRESH          |`"error_thresh_delay"` | Timeout |
    # |@ref LCB_CNTL_CONFIGURATION_TIMEOUT     | `"config_total_timeout"`|Timeout|
    # |@ref LCB_CNTL_CONFIG_NODE_TIMEOUT       | `"config_node_timeout"` | Timeout |
    # |@ref LCB_CNTL_CONFIGCACHE               | `"config_cache"`      | Path |
    # |@ref LCB_CNTL_DETAILED_ERRCODES         | `"detailed_errcodes"` | Boolean |
    # |@ref LCB_CNTL_HTCONFIG_URLTYPE          | `"http_urlmode"`      | Number (values are the constant values) |
    # |@ref LCB_CNTL_RETRY_BACKOFF             | `"retry_backoff"`     | Float |
    # |@ref LCB_CNTL_HTTP_POOLSIZE             | `"http_poolsize"`     | Number |
    # |@ref LCB_CNTL_VBGUESS_PERSIST           | `"vbguess_persist"`   | Boolean |
    #
    #
    # @committed - Note, the actual API call is considered committed and will
    # not disappear, however the existence of the various string settings are
    # dependendent on the actual settings they map to. It is recommended that
    # applications use the numerical lcb_cntl() as the string names are
    # subject to change.
    #
    # @see lcb_cntl()
    # @see lcb-cntl-settings
    #
    # @method cntl_string(instance, key, value)
    # @param [St] instance
    # @param [String] key
    # @param [String] value
    # @return [unknown]
    # @scope class
    attach_function :cntl_string, :lcb_cntl_string, [St, :string, :string], :char

    # @brief Convenience function to set a value as an lcb_U32
    # @param instance
    # @param cmd setting to modify
    # @param arg the new value
    # @return see lcb_cntl() for details
    # @committed
    #
    # @method cntl_setu32(instance, cmd, arg)
    # @param [St] instance
    # @param [Integer] cmd
    # @param [Integer] arg
    # @return [unknown]
    # @scope class
    attach_function :cntl_setu32, :lcb_cntl_setu32, [St, :int, :int], :char

    # @brief Retrieve an lcb_U32 setting
    # @param instance
    # @param cmd setting to retrieve
    # @return the value.
    # @warning This function does not return an error code. Ensure that the cntl is
    # correct for this version, or use lcb_cntl() directly.
    # @committed
    #
    # @method cntl_getu32(instance, cmd)
    # @param [St] instance
    # @param [Integer] cmd
    # @return [Integer]
    # @scope class
    attach_function :cntl_getu32, :lcb_cntl_getu32, [St, :int], :int

    # Determine if a specific control code exists
    # @param ctl the code to check for
    # @return 0 if it does not exist, nonzero if it exists.
    #
    # @method cntl_exists(ctl)
    # @param [Integer] ctl
    # @return [Integer]
    # @scope class
    attach_function :cntl_exists, :lcb_cntl_exists, [:int], :int

    # @brief Time units reported by lcb_get_timings()
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:timeunit_t).</em>
    #
    # === Options:
    # :nsec ::
    #
    # :usec ::
    #   < @brief Time is in nanoseconds
    # :msec ::
    #   < @brief Time is in microseconds
    # :sec ::
    #   < @brief Time is in milliseconds
    #
    # @method _enum_timeunit_t_
    # @return [Symbol]
    # @scope class
    enum :timeunit_t, [
      :nsec, 0,
      :usec, 1,
      :msec, 2,
      :sec, 3
    ]

    # Start recording timing metrics for the different operations.
    # The timer is started when the command is called (and the data
    # spooled to the server), and the execution time is the time until
    # we parse the response packets. This means that you can affect
    # the timers by doing a lot of other stuff before checking if
    # there is any results available..
    #
    # @param instance the handle to lcb
    # @return Status of the operation.
    # @committed
    #
    # @method enable_timings(instance)
    # @param [St] instance
    # @return [unknown]
    # @scope class
    attach_function :enable_timings, :lcb_enable_timings, [St], :char

    # Stop recording (and release all resources from previous measurements)
    # timing metrics.
    #
    # @param instance the handle to lcb
    # @return Status of the operation.
    # @committed
    #
    # @method disable_timings(instance)
    # @param [St] instance
    # @return [unknown]
    # @scope class
    attach_function :disable_timings, :lcb_disable_timings, [St], :char

    # The following function is called for each bucket in the timings
    # histogram when you call lcb_get_timings.
    # You are guaranteed that the callback will be called with the
    # lowest (min,max) range first.
    #
    # @param instance the handle to lcb
    # @param cookie the cookie you provided that allows you to pass
    #               arbitrary user data to the callback
    # @param timeunit the "scale" for the values
    # @param min The lower bound for this histogram bucket
    # @param max The upper bound for this histogram bucket
    # @param total The number of hits in this histogram bucket
    # @param maxtotal The highest value in all of the buckets
    #
    # <em>This entry is only for documentation and no real method.</em>
    #
    # @method _callback_timings_callback_(instance, cookie, timeunit, min, max, total, maxtotal)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [Symbol from _enum_timeunit_t_] timeunit
    # @param [Integer] min
    # @param [Integer] max
    # @param [Integer] total
    # @param [Integer] maxtotal
    # @return [St]
    # @scope class
    callback :timings_callback, [St, :pointer, :timeunit_t, :int, :int, :int, :int], St

    # Get the timings histogram
    #
    # @param instance the handle to lcb
    # @param cookie a cookie that will be present in all of the callbacks
    # @param callback Callback to invoke which will handle the timings
    # @return Status of the operation.
    # @committed
    #
    # @method get_timings(instance, cookie, callback)
    # @param [St] instance
    # @param [FFI::Pointer(*Void)] cookie
    # @param [Proc(_callback_timings_callback_)] callback
    # @return [unknown]
    # @scope class
    attach_function :get_timings, :lcb_get_timings, [St, :pointer, :timings_callback], :char

    # Get the version of the library.
    #
    # @param version where to store the numeric representation of the
    #         version (or NULL if you don't care)
    #
    # @return the textual description of the version ('\0'
    #          terminated). Do <b>not</b> try to release this string.
    #
    # @method get_version(version)
    # @param [FFI::Pointer(*U32)] version
    # @return [String]
    # @scope class
    attach_function :get_version, :lcb_get_version, [:pointer], :string

    # @committed
    # Determine if this version has support for a particularl feature
    # @param n the feature ID to check for
    # @return 0 if not supported, nonzero if supported.
    #
    # @method supports_feature(n)
    # @param [Integer] n
    # @return [Integer]
    # @scope class
    attach_function :supports_feature, :lcb_supports_feature, [:int], :int

    # Functions to allocate and free memory related to libcouchbase. This is
    # mainly for use on Windows where it is possible that the DLL and EXE
    # are using two different CRTs
    #
    # @method mem_alloc(size)
    # @param [Integer] size
    # @return [FFI::Pointer(*Void)]
    # @scope class
    attach_function :mem_alloc, :lcb_mem_alloc, [:int], :pointer

    # Use this to free memory allocated with lcb_mem_alloc
    #
    # @method mem_free(ptr)
    # @param [FFI::Pointer(*Void)] ptr
    # @return [nil]
    # @scope class
    attach_function :mem_free, :lcb_mem_free, [:pointer], :void

    # @private
    #
    # These two functions unconditionally start and stop the event loop. These
    # should be used _only_ when necessary. Use lcb_wait and lcb_breakout
    # for safer variants.
    #
    # Internally these proxy to the run_event_loop/stop_event_loop calls
    #
    # @method run_loop(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :run_loop, :lcb_run_loop, [St], :void

    # @private
    #
    # @method stop_loop(instance)
    # @param [St] instance
    # @return [nil]
    # @scope class
    attach_function :stop_loop, :lcb_stop_loop, [St], :void

    # This returns the library's idea of time
    #
    # @method nstime()
    # @return [Integer]
    # @scope class
    attach_function :nstime, :lcb_nstime, [], :int

    # (Not documented)
    #
    # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:dumpflags).</em>
    #
    # === Options:
    # :dump_vbconfig ::
    #   Dump the raw vbucket configuration
    # :dump_pktinfo ::
    #   Dump information about each packet
    # :dump_bufinfo ::
    #   Dump memory usage/reservation information about buffers
    # :dump_all ::
    #   Dump everything
    #
    # @method _enum_dumpflags_
    # @return [Symbol]
    # @scope class
    enum :dumpflags, [
      :dump_vbconfig, 1,
      :dump_pktinfo, 2,
      :dump_bufinfo, 4,
      :dump_all, 255
    ]
end
