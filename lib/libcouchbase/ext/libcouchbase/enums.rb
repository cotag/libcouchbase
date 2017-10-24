module Libcouchbase::Ext
  extend FFI::Library
  # (Not documented)
  #
  # ## Options:
  # :errtype_input ::
  #   Error type indicating a likely issue in user input
  # :errtype_network ::
  #   Error type indicating a likely network failure
  # :errtype_fatal ::
  #   Error type indicating a fatal condition within the server or library
  # :errtype_transient ::
  #   Error type indicating a transient condition within the server
  # :errtype_dataop ::
  #   Error type indicating a negative server reply for the data
  # :errtype_internal ::
  #   Error codes which should never be visible to the user
  # :errtype_plugin ::
  #   Error code indicating a plugin failure
  # :errtype_srvload ::
  #   Error code indicating the server is under load
  # :errtype_srvgen ::
  #   Error code indicating the server generated this message
  # :errtype_subdoc ::
  #   Error code indicates document (fulldoc) access ok, but
  #   error in performing subdocument operation. Note that this only
  #   covers errors which relate to a specific operation, rather than
  #   operations which prevent _any_ subdoc operation from executing.
  #
  # @method `enum_errflags_t`
  # @return [Symbol]
  # @scope class
  #
  ErrflagsT = enum [
    :errtype_input, 1,
    :errtype_network, 2,
    :errtype_fatal, 4,
    :errtype_transient, 8,
    :errtype_dataop, 16,
    :errtype_internal, 32,
    :errtype_plugin, 64,
    :errtype_srvload, 128,
    :errtype_srvgen, 256,
    :errtype_subdoc, 512
  ]

  # (Not documented)
  #
  # ## Options:
  # :kv_copy ::
  #
  # :kv_contig ::
  #   < The buffer should be copied
  # :kv_iov ::
  #   < The buffer is contiguous and should not be copied
  # :kv_vbid ::
  #   For use within the hashkey field, indicates that the _length_
  #   of the hashkey is the vBucket ID, rather than an actual hashkey
  # :kv_iovcopy ::
  #   The buffers are not contiguous (multi-part buffers) but should be
  #   copied. This avoids having to make the buffers contiguous before
  #   passing it into the library (only to have the library copy it again)
  #
  # @method `enum_kvbuftype`
  # @return [Symbol]
  # @scope class
  #
  KVBUFTYPE = enum [
    :kv_copy, 0,
    :kv_contig, 1,
    :kv_iov, 2,
    :kv_vbid, 3,
    :kv_iovcopy, 4
  ]

  # (Not documented)
  #
  # ## Options:
  # :list_end ::
  #
  # :http ::
  #
  # :cccp ::
  #
  # :max ::
  #
  #
  # @method `enum_config_transport_t`
  # @return [Symbol]
  # @scope class
  #
  ConfigTransportT = enum [
    :list_end, 0,
    :http, 1,
    :cccp, 2,
    :max, 3
  ]

  # (Not documented)
  #
  # ## Options:
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
  # @method `enum_respflags`
  # @return [Symbol]
  # @scope class
  #
  RESPFLAGS = enum [
    :resp_f_final, 1,
    :resp_f_clientgen, 2,
    :resp_f_nmvgen, 4,
    :resp_f_extdata, 8,
    :resp_f_sdsingle, 16,
    :resp_f_errinfo, 0x20
  ]

  # (Not documented)
  #
  # ## Options:
  # :first ::
  #   Query all the replicas sequentially, retrieving the first successful
  #   response
  # :all ::
  #   Query all the replicas concurrently, retrieving all the responses
  # :select ::
  #   Query the specific replica specified by the
  #   lcb_rget3_cmd_t#index field
  #
  # @method `enum_replica_t`
  # @return [Symbol]
  # @scope class
  #
  ReplicaT = enum [
    :first, 0,
    :all, 1,
    :select, 2
  ]

  # (Not documented)
  #
  # ## Options:
  # :add ::
  #   Will cause the operation to fail if the key already exists in the
  #   cluster.
  # :replace ::
  #   Will cause the operation to fail _unless_ the key already exists in the
  #   cluster.
  # :set ::
  #   Unconditionally store the item in the cluster
  # :upsert ::
  #   The default storage mode. This constant was added in version 2.6.2 for
  #   the sake of maintaining a default storage mode, eliminating the need
  #   for simple storage operations to explicitly define
  #   lcb_CMDSTORE::operation. Behaviorally it is identical to @ref LCB_SET
  #   in that it will make the server unconditionally store the item, whether
  #   it exists or not.
  # :append ::
  #   Rather than setting the contents of the entire document, take the value
  #   specified in lcb_CMDSTORE::value and _append_ it to the existing bytes in
  #   the value.
  # :prepend ::
  #   Like ::LCB_APPEND, but prepends the new value to the existing value.
  #
  # @method `enum_storage_t`
  # @return [Symbol]
  # @scope class
  #
  StorageT = enum [
    :add, 1,
    :replace, 2,
    :set, 3,
    :upsert, 0,
    :append, 4,
    :prepend, 5
  ]

  # (Not documented)
  #
  # ## Options:
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
  # @method `enum_durmode`
  # @return [Symbol]
  # @scope class
  #
  DURMODE = enum [
    :durability_mode_default, 0,
    :durability_mode_cas, 1,
    :durability_mode_seqno, 2
  ]

  # (Not documented)
  #
  # ## Options:
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
  # @method `enum_observe_t`
  # @return [Symbol]
  # @scope class
  #
  ObserveT = enum [
    :found, 0,
    :persisted, 1,
    :not_found, 128,
    :logically_deleted, 129,
    :max, 130
  ]

  # (Not documented)
  #
  # ## Options:
  # :detail ::
  #
  # :debug ::
  #
  # :info ::
  #
  # :warning ::
  #
  #
  # @method `enum_verbosity_level_t`
  # @return [Symbol]
  # @scope class
  #
  VerbosityLevelT = enum [
    :detail, 0,
    :debug, 1,
    :info, 2,
    :warning, 3
  ]

  # (Not documented)
  #
  # ## Options:
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
  # @method `enum_http_type_t`
  # @return [Symbol]
  # @scope class
  #
  HttpTypeT = enum [
    :view, 0,
    :management, 1,
    :raw, 2,
    :n1ql, 3,
    :fts, 4,
    :max, 5
  ]

  # (Not documented)
  #
  # ## Options:
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
  # @method `enum_waitflags`
  # @return [Symbol]
  # @scope class
  #
  WAITFLAGS = enum [
    :wait_default, 0,
    :wait_nocheck, 1
  ]

  # (Not documented)
  #
  # ## Options:
  # :value_raw ::
  #
  # :value_f_json ::
  #
  # :value_f_snappycomp ::
  #
  #
  # @method `enum_valueflags`
  # @return [Symbol]
  # @scope class
  #
  VALUEFLAGS = enum [
    :value_raw, 0,
    :value_f_json, 1,
    :value_f_snappycomp, 2
  ]

  # (Not documented)
  #
  # ## Options:
  # :nsec ::
  #
  # :usec ::
  #   < @brief Time is in nanoseconds
  # :msec ::
  #   < @brief Time is in microseconds
  # :sec ::
  #   < @brief Time is in milliseconds
  #
  # @method `enum_timeunit_t`
  # @return [Symbol]
  # @scope class
  #
  TimeunitT = enum [
    :nsec, 0,
    :usec, 1,
    :msec, 2,
    :sec, 3
  ]

  # (Not documented)
  #
  # ## Options:
  # :dump_vbconfig ::
  #   Dump the raw vbucket configuration
  # :dump_pktinfo ::
  #   Dump information about each packet
  # :dump_bufinfo ::
  #   Dump memory usage/reservation information about buffers
  # :dump_all ::
  #   Dump everything
  #
  # @method `enum_dumpflags`
  # @return [Symbol]
  # @scope class
  #
  DUMPFLAGS = enum [
    :dump_vbconfig, 1,
    :dump_pktinfo, 2,
    :dump_bufinfo, 4,
    :dump_all, 255
  ]

  # (Not documented)
  #
  # ## Options:
  # :sdcmd_get ::
  #   Retrieve the value for a path
  # :sdcmd_exists ::
  #   Check if the value for a path exists. If the path exists then the error
  #   code will be @ref LCB_SUCCESS
  # :sdcmd_replace ::
  #   Replace the value at the specified path. This operation can work
  #   on any existing and valid path.
  # :sdcmd_dict_add ::
  #   Add the value at the given path, if the given path does not exist.
  #   The penultimate path component must point to an array. The operation
  #   may be used in conjunction with @ref LCB_SDSPEC_F_MKINTERMEDIATES to
  #   create the parent dictionary (and its parents as well) if it does not
  #   yet exist.
  # :sdcmd_dict_upsert ::
  #   Unconditionally set the value at the path. This logically
  #   attempts to perform a @ref LCB_SDCMD_REPLACE, and if it fails, performs
  #   an @ref LCB_SDCMD_DICT_ADD.
  # :sdcmd_array_add_first ::
  #   Prepend the value(s) to the array indicated by the path. The path should
  #   reference an array. When the @ref LCB_SDSPEC_F_MKINTERMEDIATES flag
  #   is specified then the array may be created if it does not exist.
  #
  #   Note that it is possible to add more than a single value to an array
  #   in an operation (this is valid for this commnand as well as
  #   @ref LCB_SDCMD_ARRAY_ADD_LAST and @ref LCB_SDCMD_ARRAY_INSERT). Multiple
  #   items can be specified by placing a comma between then (the values should
  #   otherwise be valid JSON).
  # :sdcmd_array_add_last ::
  #   Identical to @ref LCB_SDCMD_ARRAY_ADD_FIRST but places the item(s)
  #   at the end of the array rather than at the beginning.
  # :sdcmd_array_add_unique ::
  #   Add the value to the array indicated by the path, if the value is not
  #   already in the array. The @ref LCB_SDSPEC_F_MKINTERMEDIATES flag can
  #   be specified to create the array if it does not already exist.
  #
  #   Currently the value for this operation must be a JSON primitive (i.e.
  #   no arrays or dictionaries) and the existing array itself must also
  #   contain only primitives (otherwise a @ref LCB_SUBDOC_PATH_MISMATCH
  #   error will be received).
  # :sdcmd_array_insert ::
  #   Add the value at the given array index. Unlike other array operations,
  #   the path specified should include the actual index at which the item(s)
  #   should be placed, for example `array(2)` will cause the value(s) to be
  #   the 3rd item(s) in the array.
  #
  #   The array must already exist and the @ref LCB_SDCMD_F_MKINTERMEDIATES
  #   flag is not honored.
  # :sdcmd_counter ::
  #   Increment or decrement an existing numeric path. If the number does
  #   not exist, it will be created (though its parents will not, unless
  #   @ref LCB_SDSPEC_F_MKINTERMEDIATES is specified).
  #
  #   The value for this operation should be a valid JSON-encoded integer and
  #   must be between `INT64_MIN` and `INT64_MAX`, inclusive.
  # :sdcmd_remove ::
  #   Remove an existing path in the document.
  # :sdcmd_get_count ::
  #   Count the number of elements in an array or dictionary
  # :sdcmd_max ::
  #
  #
  # @method `enum_subdocop`
  # @return [Symbol]
  # @scope class
  #
  SUBDOCOP = enum [
    :sdcmd_get, 1,
    :sdcmd_exists, 2,
    :sdcmd_replace, 3,
    :sdcmd_dict_add, 4,
    :sdcmd_dict_upsert, 5,
    :sdcmd_array_add_first, 6,
    :sdcmd_array_add_last, 7,
    :sdcmd_array_add_unique, 8,
    :sdcmd_array_insert, 9,
    :sdcmd_counter, 10,
    :sdcmd_remove, 11,
    :sdcmd_get_count, 12,
    :sdcmd_max, 13
  ]

  # (Not documented)
  #
  # ## Options:
  # :success ::
  #
  # :auth_continue ::
  #
  # :auth_error ::
  #   This error code is received in callbacks when connecting or reconnecting
  #        to the cluster. If received during initial bootstrap
  #        (i.e. lcb_get_bootstrap_status()) then it should be considered a fatal
  #        errror. This error should not be visible after initial bootstrap.
  #
  #        This error may also be received if CCCP bootstrap is used and the bucket does
  #        not exist.
  # :delta_badval ::
  #   This error is received in callbacks. It is a result of trying to perform
  #        an lcb_arithmetic() operation on an item which has an existing value that
  #        cannot be parsed as a number.
  # :e2big ::
  #   This error is received in callbacks. It indicates that the key and value
  #        exceeded the constraints within the server. The current constraints are
  #        150 bytes for a key and 20MB for a value
  # :ebusy ::
  #
  # :einternal ::
  #   Internal error within the library. This may be a result of a bug
  # :einval ::
  #   If returned from an API call, it indicates invalid values were passed
  #        to the function. If received within a callback, it indicates that a
  #        malformed packet was sent to the server.
  # :enomem ::
  #   This code is received in callbacks. It means the server has no more memory
  #        left to store or modify the item.
  # :erange ::
  #
  # :error ::
  #   Generic error
  # :etmpfail ::
  #   This error is received in callbacks from the server itself to indicate
  #       that it could not perform the requested operation. This is usually due to memory and/or
  #       resource constraints on the server. This error may also be returned if a
  #       key has been locked (see lcb_get()) and an operation has been performed on it
  #       without unlocking the item (see lcb_unlock(), or pass the correct CAS value
  #       to a mutation function).
  # :key_eexists ::
  #   The key already exists in the cluster. This error code is received within
  #       callbacks as a result of an _add_ operation in which the key already exists.
  #       It is also received for other operations in which a CAS was specified but has
  #       changed on the server.
  # :key_enoent ::
  #   Received in callbacks to indicate that the server does not contain the item
  # :dlopen_failed ::
  #   Error code thrown if an I/O plugin could not be located
  # :dlsym_failed ::
  #   Error code thrown of an I/O plugin did not contain a proper initialization routine
  # :network_error ::
  #   This is a generic error code returned for various forms of socket
  #        operation failures. Newer applications are recommended to enable the
  #        @ref LCB_CNTL_DETAILED_ERRCODES setting via lcb_cntl() and receive more
  #        detailed information about a socket error.
  #
  #        @see lcb_cntl(), @ref LCB_CNTL_DETAILED_ERRCODES
  # :not_my_vbucket ::
  #   Error code received in callbacks if the command was forwarded to the wrong
  #       server (for example, during a rebalance) and the library settings are configured
  #       that the command should not be remapped to a new server
  # :not_stored ::
  #   Received in callbacks as a response to an LCB_APPEND or LCB_PREPEND on an
  #       item that did not exist in the cluster. Equivalent to LCB_KEY_ENOENT
  # :not_supported ::
  #   Returned from API calls if a specific operation is valid but is unsupported
  #        in the current version or state of the library. May also be received in a
  #        callback if the cluster does not support the operation.
  #
  #        This will be returned for unknown settings passed to lcb_cntl() unless
  #        @ref LCB_CNTL_DETAILED_ERRCODES is set
  # :unknown_command ::
  #   Received in callbacks if the cluster does not know about the command.
  #        Similar to LCB_NOT_SUPPORTED
  # :unknown_host ::
  #   Error code received if the hostname specified could not be found. It may
  #        also be received if a socket could not be created to the host supplied.
  #
  #        A more detailed error code may be returned instead if
  #        @ref LCB_CNTL_DETAILED_ERRCODES is set.
  # :protocol_error ::
  #   Error code received if the server replied with an unexpected response
  # :etimedout ::
  #   Error code received in callbacks for operations which did not receive a
  #        reply from the server within the timeout limit.
  #        @see LCB_CNTL_OP_TIMEOUT
  # :connect_error ::
  #   @see LCB_NETWORK_ERROR, LCB_UNKNOWN_HOST, @ref LCB_CNTL_DETAILED_ERRCODES
  # :bucket_enoent ::
  #   Received on initial bootstrap if the bucket does not exist. Note that
  #        for CCCP bootstrap, @ref LCB_AUTH_ERROR will be received instead
  # :client_enomem ::
  #   Client could not allocate memory for internal structures
  # :client_enoconf ::
  #   Client could not schedule the request. This is typically received when
  #        an operation is requested before the initial bootstrap has completed
  # :ebadhandle ::
  #
  # :server_bug ::
  #
  # :plugin_version_mismatch ::
  #
  # :invalid_host_format ::
  #
  # :invalid_char ::
  #
  # :durability_etoomany ::
  #   Received in response to the durability API call, if the amount of nodes
  #        or replicas to persist/replicate to exceed the total number of replicas the
  #        bucket was configured with.
  # :duplicate_commands ::
  #   Received in scheduling if a command with the same key was specified more
  #        than once. Some commands will accept this, but others (notably `observe`)
  #        will not
  # :no_matching_server ::
  #   This error is received from API calls if the master node for the vBucket
  #        the key has been hashed to is not present. This will happen in the result
  #        of a node failover where no replica exists to replace it.
  # :bad_environment ::
  #   Received during initial creation (lcb_create()) if an environment variable
  #        was specified with an incorrect or invalid value.
  #
  #        @see @ref lcb-env-vars-page
  # :busy ::
  #
  # :invalid_username ::
  #   Received from lcb_create() if the username does not match the bucket
  # :config_cache_invalid ::
  #
  # :saslmech_unavailable ::
  #   Received during initial bootstrap if the library was configured to force
  #        the usage of a specific SASL mechanism and the server did not support this
  #        mechanism. @see LCB_CNTL_FORCE_SASL_MECH
  # :too_many_redirects ::
  #   Received in the HTTP callback if the response was redirected too many
  #        times. @see LCB_CNTL_MAX_REDIRECTS
  # :map_changed ::
  #   May be received in operation callbacks if the cluster toplogy changed
  #        and the library could not remap the command to a new node. This may be
  #        because the internal structure lacked sufficient information to recreate
  #        the packet, or because the configuration settings indicated that the command
  #        should not be retried. @see LCB_CNTL_RETRYMODE
  # :incomplete_packet ::
  #   Returned from the lcb_pktfwd3() function if an incomplete packet was
  #        passed
  # :econnrefused ::
  #   Mapped directly to the system `ECONNREFUSED` errno. This is received
  #        in callbacks if an initial connection to the node could not be established.
  #        Check your firewall settings and ensure the specified service is online.
  # :esockshutdown ::
  #   Returned in a callback if the socket connection was gracefully closed,
  #        but the library wasn't expecting it. This may happen if the system is
  #        being shut down.
  #        @lcb_see_detailed_neterr
  # :econnreset ::
  #   Returned in a callback if the socket connection was forcefully reset,
  #        Equivalent to the system `ECONNRESET`.
  #        @lcb_see_detailed_neterr
  # :ecantgetport ::
  #   Returned in a callback if the library could not allocated a local socket
  #        due to TCP local port exhaustion. This means you have either found a bug
  #        in the library or are creating too many TCP connections. Keep in mind that
  #        a TCP connection will still occupy a slot in your system socket table even
  #        after it has been closed (and will thus appear in a `TIME_WAIT` state).
  #
  #        @lcb_see_detailed_neterr
  # :efdlimitreached ::
  #   Returned if the library could not allocate a new file descriptor for a
  #        socket or other resource. This may be more common on systems (such as
  #        Mac OS X) which have relatively low limits for file descriptors. To raise
  #        the file descriptor limit, refer to the `ulimit -n` command
  #
  #        @lcb_see_detailed_neterr
  # :enetunreach ::
  #   Returned in callback if the host or subnet containing a node could
  #        not be contacted. This may be a result of a bad routing table or being
  #        physically disconnected from the network.
  #        @lcb_see_detailed_neterr.
  # :ectl_unknown ::
  #   An unrecognized setting was passed to the lcb_cntl() function
  #        @lcb_see_detailed_neterr
  # :ectl_unsuppmode ::
  #   An invalid operation was supplied for a setting to lcb_cntl(). This will
  #        happen if you try to write to a read-only setting, or retrieve a value
  #        which may only be set. Refer to the documentation for an individual setting
  #        to see what modes it supports.
  #        @lcb_see_detailed_neterr
  # :ectl_badarg ::
  #   A malformed argument was passed to lcb_cntl() for the given setting. See
  #        the documentation for the setting to see what arguments it supports and
  #        how they are to be supplied.
  #
  #        @lcb_see_detailed_neterr
  # :empty_key ::
  #   An empty key was passed to an operation. Most commands do not accept
  #         empty keys.
  # :ssl_error ::
  #   A problem with the SSL system was encountered. Use logging to discover
  #        what happened. This error will only be thrown if something internal to the
  #        SSL library failed (for example, a bad certificate or bad user input);
  #        otherwise a network error will be thrown if an SSL connection was terminated
  # :ssl_cantverify ::
  #   The certificate the server sent cannot be verified. This is a possible
  #        case of a man-in-the-middle attack, but also of forgetting to supply
  #        the path to the CA authority to the library.
  # :schedfail_internal ::
  #
  # :client_feature_unavailable ::
  #   An optional client feature was requested, but the current configuration
  #        does not allow it to be used. This might be because it is not available
  #        on a particular platform/architecture/operating system/configuration, or
  #        it has been disabled at the time the library was built.
  # :options_conflict ::
  #   An option was passed to a command which is incompatible with other
  #        options. This may happen if two fields are mutually exclusive
  # :http_error ::
  #   Received in callbacks if an operation failed because of a negative HTTP
  #        status code
  # :durability_no_mutation_tokens ::
  #   Scheduling error received if @ref LCB_CNTL_DURABILITY_MUTATION_TOKENS was
  #        enabled, but there is no available mutation token for the key.
  # :unknown_memcached_error ::
  #   The server replied with an unrecognized status code
  # :mutation_lost ::
  #   The server replied that the given mutation has been lost
  # :subdoc_path_enoent ::
  #
  # :subdoc_path_mismatch ::
  #
  # :subdoc_path_einval ::
  #
  # :subdoc_path_e2big ::
  #
  # :subdoc_doc_e2deep ::
  #
  # :subdoc_value_cantinsert ::
  #
  # :subdoc_doc_notjson ::
  #
  # :subdoc_num_erange ::
  #
  # :subdoc_bad_delta ::
  #
  # :subdoc_path_eexists ::
  #
  # :subdoc_multi_failure ::
  #
  # :subdoc_value_e2deep ::
  #
  # :einval_mcd ::
  #
  # :empty_path ::
  #
  # :unknown_sdcmd ::
  #
  # :eno_commands ::
  #
  # :query_error ::
  #
  # :max_error ::
  #   The errors below this value reserver for libcouchbase usage.
  #
  # @method `enum_error_t`
  # @return [Symbol]
  # @scope class
  #
  ErrorT = enum [
    :success, 0,
    :auth_continue, 1,
    :auth_error, 2,
    :delta_badval, 3,
    :e2big, 4,
    :ebusy, 5,
    :einternal, 6,
    :einval, 7,
    :enomem, 8,
    :erange, 9,
    :error, 10,
    :etmpfail, 11,
    :key_eexists, 12,
    :key_enoent, 13,
    :dlopen_failed, 14,
    :dlsym_failed, 15,
    :network_error, 16,
    :not_my_vbucket, 17,
    :not_stored, 18,
    :not_supported, 19,
    :unknown_command, 20,
    :unknown_host, 21,
    :protocol_error, 22,
    :etimedout, 23,
    :connect_error, 24,
    :bucket_enoent, 25,
    :client_enomem, 26,
    :client_enoconf, 27,
    :ebadhandle, 28,
    :server_bug, 29,
    :plugin_version_mismatch, 30,
    :invalid_host_format, 31,
    :invalid_char, 32,
    :durability_etoomany, 33,
    :duplicate_commands, 34,
    :no_matching_server, 35,
    :bad_environment, 36,
    :busy, 37,
    :invalid_username, 38,
    :config_cache_invalid, 39,
    :saslmech_unavailable, 40,
    :too_many_redirects, 41,
    :map_changed, 42,
    :incomplete_packet, 43,
    :econnrefused, 44,
    :esockshutdown, 45,
    :econnreset, 46,
    :ecantgetport, 47,
    :efdlimitreached, 48,
    :enetunreach, 49,
    :ectl_unknown, 50,
    :ectl_unsuppmode, 51,
    :ectl_badarg, 52,
    :empty_key, 53,
    :ssl_error, 54,
    :ssl_cantverify, 55,
    :schedfail_internal, 56,
    :client_feature_unavailable, 57,
    :options_conflict, 58,
    :http_error, 59,
    :durability_no_mutation_tokens, 60,
    :unknown_memcached_error, 61,
    :mutation_lost, 62,
    :subdoc_path_enoent, 63,
    :subdoc_path_mismatch, 64,
    :subdoc_path_einval, 65,
    :subdoc_path_e2big, 66,
    :subdoc_doc_e2deep, 67,
    :subdoc_value_cantinsert, 68,
    :subdoc_doc_notjson, 69,
    :subdoc_num_erange, 70,
    :subdoc_bad_delta, 71,
    :subdoc_path_eexists, 72,
    :subdoc_multi_failure, 73,
    :subdoc_value_e2deep, 74,
    :einval_mcd, 75,
    :empty_path, 76,
    :unknown_sdcmd, 77,
    :eno_commands, 78,
    :query_error, 79,
    :generic_tmperr, 80,
    :generic_subdocerr, 81,
    :generic_constraint_err, 82,
    :nameserver_error, 83,
    :not_authorized, 84,
    :max_error, 4096
  ]

  # (Not documented)
  #
  # ## Options:
  # :bucket ::
  #
  # :cluster ::
  #   < Handle for data access (default)
  #
  # @method `enum_type_t`
  # @return [Symbol]
  # @scope class
  #
  TypeT = enum [
    :bucket, 0,
    :cluster, 1
  ]

  # (Not documented)
  #
  # ## Options:
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
  # @method `enum_callbacktype`
  # @return [Symbol]
  # @scope class
  #
  CALLBACKTYPE = enum [
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

  # (Not documented)
  #
  # ## Options:
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
  # @method `enum_http_method_t`
  # @return [Symbol]
  # @scope class
  #
  HttpMethodT = enum [
    :get, 0,
    :post, 1,
    :put, 2,
    :delete, 3,
    :max, 4
  ]

  # (Not documented)
  #
  # ## Options:
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
  # @method `enum_getnodetype`
  # @return [Symbol]
  # @scope class
  #
  GETNODETYPE = enum [
    :node_htconfig, 1,
    :node_data, 2,
    :node_views, 4,
    :node_connected, 8,
    :node_nevernull, 16,
    :node_htconfig_connected, 9,
    :node_htconfig_any, 17
  ]

end
