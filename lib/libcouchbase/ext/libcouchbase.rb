require 'ffi'
require 'libcouchbase/ext/libcouchbase/enums'

module Libcouchbase::Ext
  extend FFI::Library
  if FFI::Platform.windows?
    ffi_lib ::File.expand_path("../../../../ext/bin/libcouchbase.#{FFI::Platform::LIBSUFFIX}", __FILE__)
    require 'libcouchbase/ext/libcouchbase_iocp'
  else
    ffi_lib ::File.expand_path("../../../../ext/libcouchbase/build/lib/libcouchbase.#{FFI::Platform::LIBSUFFIX}", __FILE__)
    require 'libcouchbase/ext/libcouchbase_libuv'
  end

  autoload :T, 'libcouchbase/ext/libcouchbase/t'
  autoload :HttpRequestT, 'libcouchbase/ext/libcouchbase/http_request_t'
  autoload :CONTIGBUF, 'libcouchbase/ext/libcouchbase/contigbuf'
  autoload :KEYBUF, 'libcouchbase/ext/libcouchbase/keybuf'
  autoload :FRAGBUF, 'libcouchbase/ext/libcouchbase/fragbuf'
  autoload :VALBUFUBuf, 'libcouchbase/ext/libcouchbase/valbuf_u_buf'
  autoload :VALBUF, 'libcouchbase/ext/libcouchbase/valbuf'
  autoload :CreateSt0, 'libcouchbase/ext/libcouchbase/create_st0'
  autoload :CreateSt1, 'libcouchbase/ext/libcouchbase/create_st1'
  autoload :CreateSt2, 'libcouchbase/ext/libcouchbase/create_st2'
  autoload :CreateSt3, 'libcouchbase/ext/libcouchbase/create_st3'
  autoload :CRSTU, 'libcouchbase/ext/libcouchbase/crst_u'
  autoload :CreateSt, 'libcouchbase/ext/libcouchbase/create_st'
  autoload :CMDBASE, 'libcouchbase/ext/libcouchbase/cmdbase'
  autoload :RESPBASE, 'libcouchbase/ext/libcouchbase/respbase'
  autoload :RESPSERVERBASE, 'libcouchbase/ext/libcouchbase/respserverbase'
  autoload :MUTATIONTOKEN, 'libcouchbase/ext/libcouchbase/mutation_token'
  autoload :CMDGET, 'libcouchbase/ext/libcouchbase/cmdget'
  autoload :RESPGET, 'libcouchbase/ext/libcouchbase/respget'
  autoload :CMDGETREPLICA, 'libcouchbase/ext/libcouchbase/cmdgetreplica'
  autoload :CMDSTORE, 'libcouchbase/ext/libcouchbase/cmdstore'
  autoload :RESPSTORE, 'libcouchbase/ext/libcouchbase/respstore'
  autoload :MULTICMDCTX, 'libcouchbase/ext/libcouchbase/multicmd_ctx'
  autoload :DURABILITYOPTSv0, 'libcouchbase/ext/libcouchbase/durabilityopt_sv0'
  autoload :DurabilityOptsStV, 'libcouchbase/ext/libcouchbase/durability_opts_st_v'
  autoload :DurabilityOptsT, 'libcouchbase/ext/libcouchbase/durability_opts_t'
  autoload :CMDENDURE, 'libcouchbase/ext/libcouchbase/cmdendure'
  autoload :RESPENDURE, 'libcouchbase/ext/libcouchbase/respendure'
  autoload :CMDSTOREDUR, 'libcouchbase/ext/libcouchbase/cmdstoredur'
  autoload :RESPSTOREDUR, 'libcouchbase/ext/libcouchbase/respstoredur'
  autoload :CMDOBSERVE, 'libcouchbase/ext/libcouchbase/cmdobserve'
  autoload :RESPOBSERVE, 'libcouchbase/ext/libcouchbase/respobserve'
  autoload :CMDOBSEQNO, 'libcouchbase/ext/libcouchbase/cmdobseqno'
  autoload :RESPOBSEQNO, 'libcouchbase/ext/libcouchbase/respobseqno'
  autoload :CMDCOUNTER, 'libcouchbase/ext/libcouchbase/cmdcounter'
  autoload :RESPCOUNTER, 'libcouchbase/ext/libcouchbase/respcounter'
  autoload :RESPSTATS, 'libcouchbase/ext/libcouchbase/respstats'
  autoload :RESPMCVERSION, 'libcouchbase/ext/libcouchbase/respmcversion'
  autoload :CMDVERBOSITY, 'libcouchbase/ext/libcouchbase/cmdverbosity'
  autoload :CMDHTTP, 'libcouchbase/ext/libcouchbase/cmdhttp'
  autoload :RESPHTTP, 'libcouchbase/ext/libcouchbase/resphttp'
  autoload :HISTOGRAM, 'libcouchbase/ext/libcouchbase/histogram'
  autoload :SDSPEC, 'libcouchbase/ext/libcouchbase/sdspec'
  autoload :CMDSUBDOC, 'libcouchbase/ext/libcouchbase/cmdsubdoc'
  autoload :RESPSUBDOC, 'libcouchbase/ext/libcouchbase/respsubdoc'
  autoload :SDENTRY, 'libcouchbase/ext/libcouchbase/sdentry'
  autoload :VIEWHANDLE, 'libcouchbase/ext/libcouchbase/viewhandle'
  autoload :CMDVIEWQUERY, 'libcouchbase/ext/libcouchbase/cmdviewquery'
  autoload :RESPVIEWQUERY, 'libcouchbase/ext/libcouchbase/respviewquery'
  autoload :N1QLHANDLE, 'libcouchbase/ext/libcouchbase/n1qlhandle'
  autoload :N1QLPARAMS, 'libcouchbase/ext/libcouchbase/n1qlparams'
  autoload :CMDN1QL, 'libcouchbase/ext/libcouchbase/cmdn1ql'
  autoload :RESPN1QL, 'libcouchbase/ext/libcouchbase/respn1ql'
  autoload :RESPFTS, 'libcouchbase/ext/libcouchbase/respfts'
  autoload :FTSHANDLE, 'libcouchbase/ext/libcouchbase/ftshandle'
  autoload :CMDFTS, 'libcouchbase/ext/libcouchbase/cmdfts'

  attach_function :create_io_ops, :lcb_create_io_ops, [:pointer, :pointer], ErrorT

  # (Not documented)
  #
  # @method `callback_errmap_callback`(error_t, instance)
  # @param [T] error_t
  # @param [Integer] instance
  # @return [ErrorT]
  # @scope class
  #
  callback :errmap_callback, [T.by_ref, :ushort], ErrorT

  # (Not documented)
  #
  # @method `callback_bootstrap_callback`(instance, err)
  # @param [T] instance
  # @param [ErrorT] err
  # @return [nil]
  # @scope class
  #
  callback :bootstrap_callback, [T.by_ref, ErrorT], :void

  # (Not documented)
  #
  # @method `callback_respcallback`(instance, cbtype, resp)
  # @param [T] instance
  # @param [Integer] cbtype
  # @param [RESPBASE] resp
  # @return [nil]
  # @scope class
  #
  callback :respcallback, [T.by_ref, :int, RESPBASE.by_ref], :void

  # (Not documented)
  #
  # @method `callback_destroy_callback`(cookie)
  # @param [FFI::Pointer(*Void)] cookie
  # @return [nil]
  # @scope class
  #
  callback :destroy_callback, [:pointer], :void

  # (Not documented)
  #
  # @method `callback_timings_callback`(instance, cookie, timeunit, min, max, total, maxtotal)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [TimeunitT] timeunit
  # @param [Integer] min
  # @param [Integer] max
  # @param [Integer] total
  # @param [Integer] maxtotal
  # @return [nil]
  # @scope class
  #
  callback :timings_callback, [T.by_ref, :pointer, TimeunitT, :uint, :uint, :uint, :uint], :void

  # (Not documented)
  #
  # @method `callback_histogram_callback`(cookie, timeunit, min, max, total, maxtotal)
  # @param [FFI::Pointer(*Void)] cookie
  # @param [TimeunitT] timeunit
  # @param [Integer] min
  # @param [Integer] max
  # @param [Integer] total
  # @param [Integer] maxtotal
  # @return [nil]
  # @scope class
  #
  callback :histogram_callback, [:pointer, TimeunitT, :uint, :uint, :uint, :uint], :void

  # (Not documented)
  #
  # @method `callback_viewquerycallback`(instance, cbtype, row)
  # @param [T] instance
  # @param [Integer] cbtype
  # @param [RESPVIEWQUERY] row
  # @return [nil]
  # @scope class
  #
  callback :viewquerycallback, [T.by_ref, :int, RESPVIEWQUERY.by_ref], :void

  # (Not documented)
  #
  # @method `callback_n1qlcallback`(, , )
  # @param [T]
  # @param [Integer]
  # @param [RESPN1QL]
  # @return [nil]
  # @scope class
  #
  callback :n1qlcallback, [T.by_ref, :int, RESPN1QL.by_ref], :void

  # (Not documented)
  #
  # @method `callback_ftscallback`(, , )
  # @param [T]
  # @param [Integer]
  # @param [RESPFTS]
  # @return [nil]
  # @scope class
  #
  callback :ftscallback, [T.by_ref, :int, RESPFTS.by_ref], :void

  # (Not documented)
  #
  # @method get_errtype(err)
  # @param [ErrorT] err
  # @return [Integer]
  # @scope class
  #
  attach_function :get_errtype, :lcb_get_errtype, [ErrorT], :int

  # (Not documented)
  #
  # @method strerror(instance, error)
  # @param [T] instance
  # @param [ErrorT] error
  # @return [String]
  # @scope class
  #
  attach_function :strerror, :lcb_strerror, [T.by_ref, ErrorT], :string

  # (Not documented)
  #
  # @method errmap_default(instance, code)
  # @param [T] instance
  # @param [Integer] code
  # @return [ErrorT]
  # @scope class
  #
  attach_function :errmap_default, :lcb_errmap_default, [T.by_ref, :ushort], ErrorT

  # (Not documented)
  #
  # @method set_errmap_callback(t, errmap_callback)
  # @param [T] t
  # @param [Proc(callback_errmap_callback)] errmap_callback
  # @return [Proc(callback_errmap_callback)]
  # @scope class
  #
  attach_function :set_errmap_callback, :lcb_set_errmap_callback, [T.by_ref, :errmap_callback], :errmap_callback

  # (Not documented)
  #
  # @method create(instance, options)
  # @param [FFI::Pointer(*T)] instance
  # @param [CreateSt] options
  # @return [ErrorT]
  # @scope class
  #
  attach_function :create, :lcb_create, [:pointer, CreateSt.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method connect(instance)
  # @param [T] instance
  # @return [ErrorT]
  # @scope class
  #
  attach_function :connect, :lcb_connect, [T.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method set_bootstrap_callback(instance, callback)
  # @param [T] instance
  # @param [Proc(callback_bootstrap_callback)] callback
  # @return [Proc(callback_bootstrap_callback)]
  # @scope class
  #
  attach_function :set_bootstrap_callback, :lcb_set_bootstrap_callback, [T.by_ref, :bootstrap_callback], :bootstrap_callback

  # (Not documented)
  #
  # @method get_bootstrap_status(instance)
  # @param [T] instance
  # @return [ErrorT]
  # @scope class
  #
  attach_function :get_bootstrap_status, :lcb_get_bootstrap_status, [T.by_ref], ErrorT

  # (Not documented)
  #
  # @method install_callback3(instance, cbtype, cb)
  # @param [T] instance
  # @param [Integer] cbtype
  # @param [Proc(callback_respcallback)] cb
  # @return [Proc(callback_respcallback)]
  # @scope class
  #
  attach_function :install_callback3, :lcb_install_callback3, [T.by_ref, :int, :respcallback], :respcallback

  # (Not documented)
  #
  # @method get_callback3(instance, cbtype)
  # @param [T] instance
  # @param [Integer] cbtype
  # @return [Proc(callback_respcallback)]
  # @scope class
  #
  attach_function :get_callback3, :lcb_get_callback3, [T.by_ref, :int], :respcallback

  # (Not documented)
  #
  # @method strcbtype(cbtype)
  # @param [Integer] cbtype
  # @return [String]
  # @scope class
  #
  attach_function :strcbtype, :lcb_strcbtype, [:int], :string

  # (Not documented)
  #
  # @method get3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDGET] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :get3, :lcb_get3, [T.by_ref, :pointer, CMDGET.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method rget3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDGETREPLICA] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :rget3, :lcb_rget3, [T.by_ref, :pointer, CMDGETREPLICA.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method store3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDSTORE] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :store3, :lcb_store3, [T.by_ref, :pointer, CMDSTORE.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method remove3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDBASE] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :remove3, :lcb_remove3, [T.by_ref, :pointer, CMDBASE.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method endure3_ctxnew(instance, options, err)
  # @param [T] instance
  # @param [DurabilityOptsT] options
  # @param [FFI::Pointer(*ErrorT)] err
  # @return [MULTICMDCTX]
  # @scope class
  #
  attach_function :endure3_ctxnew, :lcb_endure3_ctxnew, [T.by_ref, DurabilityOptsT.by_ref, :pointer], MULTICMDCTX.by_ref, :blocking => true

  # (Not documented)
  #
  # @method storedur3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDSTOREDUR] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :storedur3, :lcb_storedur3, [T.by_ref, :pointer, CMDSTOREDUR.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method durability_validate(instance, persist_to, replicate_to, options)
  # @param [T] instance
  # @param [FFI::Pointer(*U16)] persist_to
  # @param [FFI::Pointer(*U16)] replicate_to
  # @param [Integer] options
  # @return [ErrorT]
  # @scope class
  #
  attach_function :durability_validate, :lcb_durability_validate, [T.by_ref, :pointer, :pointer, :int], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method observe3_ctxnew(instance)
  # @param [T] instance
  # @return [MULTICMDCTX]
  # @scope class
  #
  attach_function :observe3_ctxnew, :lcb_observe3_ctxnew, [T.by_ref], MULTICMDCTX.by_ref, :blocking => true

  # (Not documented)
  #
  # @method observe_seqno3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDOBSEQNO] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :observe_seqno3, :lcb_observe_seqno3, [T.by_ref, :pointer, CMDOBSEQNO.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method resp_get_mutation_token(cbtype, rb)
  # @param [Integer] cbtype
  # @param [RESPBASE] rb
  # @return [MUTATIONTOKEN]
  # @scope class
  #
  attach_function :resp_get_mutation_token, :lcb_resp_get_mutation_token, [:int, RESPBASE.by_ref], MUTATIONTOKEN.by_ref, :blocking => true

  # (Not documented)
  #
  # @method get_mutation_token(instance, kb, errp)
  # @param [T] instance
  # @param [KEYBUF] kb
  # @param [FFI::Pointer(*ErrorT)] errp
  # @return [MUTATIONTOKEN]
  # @scope class
  #
  attach_function :get_mutation_token, :lcb_get_mutation_token, [T.by_ref, KEYBUF.by_ref, :pointer], MUTATIONTOKEN.by_ref, :blocking => true

  # (Not documented)
  #
  # @method counter3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDCOUNTER] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :counter3, :lcb_counter3, [T.by_ref, :pointer, CMDCOUNTER.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method unlock3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDBASE] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :unlock3, :lcb_unlock3, [T.by_ref, :pointer, CMDBASE.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method touch3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDBASE] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :touch3, :lcb_touch3, [T.by_ref, :pointer, CMDBASE.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method stats3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDBASE] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :stats3, :lcb_stats3, [T.by_ref, :pointer, CMDBASE.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method server_versions3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDBASE] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :server_versions3, :lcb_server_versions3, [T.by_ref, :pointer, CMDBASE.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method server_verbosity3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDVERBOSITY] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :server_verbosity3, :lcb_server_verbosity3, [T.by_ref, :pointer, CMDVERBOSITY.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method cbflush3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDBASE] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :cbflush3, :lcb_cbflush3, [T.by_ref, :pointer, CMDBASE.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method flush3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDBASE] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :flush3, :lcb_flush3, [T.by_ref, :pointer, CMDBASE.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method http3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDHTTP] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :http3, :lcb_http3, [T.by_ref, :pointer, CMDHTTP.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method cancel_http_request(instance, request)
  # @param [T] instance
  # @param [HttpRequestT] request
  # @return [nil]
  # @scope class
  #
  attach_function :cancel_http_request, :lcb_cancel_http_request, [T.by_ref, HttpRequestT.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method set_cookie(instance, cookie)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @return [nil]
  # @scope class
  #
  attach_function :set_cookie, :lcb_set_cookie, [T.by_ref, :pointer], :void

  # (Not documented)
  #
  # @method get_cookie(instance)
  # @param [T] instance
  # @return [FFI::Pointer(*Void)]
  # @scope class
  #
  attach_function :get_cookie, :lcb_get_cookie, [T.by_ref], :pointer

  # (Not documented)
  #
  # @method wait(instance)
  # @param [T] instance
  # @return [ErrorT]
  # @scope class
  #
  attach_function :wait, :lcb_wait, [T.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method tick_nowait(instance)
  # @param [T] instance
  # @return [ErrorT]
  # @scope class
  #
  attach_function :tick_nowait, :lcb_tick_nowait, [T.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method wait3(instance, flags)
  # @param [T] instance
  # @param [WAITFLAGS] flags
  # @return [nil]
  # @scope class
  #
  attach_function :wait3, :lcb_wait3, [T.by_ref, WAITFLAGS], :void, :blocking => true

  # (Not documented)
  #
  # @method breakout(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :breakout, :lcb_breakout, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method is_waiting(instance)
  # @param [T] instance
  # @return [Integer]
  # @scope class
  #
  attach_function :is_waiting, :lcb_is_waiting, [T.by_ref], :int, :blocking => true

  # (Not documented)
  #
  # @method refresh_config(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :refresh_config, :lcb_refresh_config, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method sched_enter(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :sched_enter, :lcb_sched_enter, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method sched_leave(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :sched_leave, :lcb_sched_leave, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method sched_fail(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :sched_fail, :lcb_sched_fail, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method sched_flush(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :sched_flush, :lcb_sched_flush, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method destroy(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :destroy, :lcb_destroy, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method set_destroy_callback(t, destroy_callback)
  # @param [T] t
  # @param [Proc(callback_destroy_callback)] destroy_callback
  # @return [Proc(callback_destroy_callback)]
  # @scope class
  #
  attach_function :set_destroy_callback, :lcb_set_destroy_callback, [T.by_ref, :destroy_callback], :destroy_callback

  # (Not documented)
  #
  # @method destroy_async(instance, arg)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] arg
  # @return [nil]
  # @scope class
  #
  attach_function :destroy_async, :lcb_destroy_async, [T.by_ref, :pointer], :void, :blocking => true

  # (Not documented)
  #
  # @method get_node(instance, type, index)
  # @param [T] instance
  # @param [GETNODETYPE] type
  # @param [Integer] index
  # @return [String]
  # @scope class
  #
  attach_function :get_node, :lcb_get_node, [T.by_ref, GETNODETYPE, :uint], :string, :blocking => true

  # (Not documented)
  #
  # @method get_keynode(instance, key, nkey)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] key
  # @param [Integer] nkey
  # @return [String]
  # @scope class
  #
  attach_function :get_keynode, :lcb_get_keynode, [T.by_ref, :pointer, :ulong], :string, :blocking => true

  # (Not documented)
  #
  # @method get_num_replicas(instance)
  # @param [T] instance
  # @return [Integer]
  # @scope class
  #
  attach_function :get_num_replicas, :lcb_get_num_replicas, [T.by_ref], :int

  # (Not documented)
  #
  # @method get_num_nodes(instance)
  # @param [T] instance
  # @return [Integer]
  # @scope class
  #
  attach_function :get_num_nodes, :lcb_get_num_nodes, [T.by_ref], :int

  # (Not documented)
  #
  # @method get_server_list(instance)
  # @param [T] instance
  # @return [FFI::Pointer(**CharS)]
  # @scope class
  #
  attach_function :get_server_list, :lcb_get_server_list, [T.by_ref], :pointer, :blocking => true

  # (Not documented)
  #
  # @method dump(instance, fp, flags)
  # @param [T] instance
  # @param [FFI::Pointer(*FILE)] fp
  # @param [Integer] flags
  # @return [nil]
  # @scope class
  #
  attach_function :dump, :lcb_dump, [T.by_ref, :pointer, :uint], :void, :blocking => true

  # (Not documented)
  #
  # @method cntl(instance, mode, cmd, arg)
  # @param [T] instance
  # @param [Integer] mode
  # @param [Integer] cmd
  # @param [FFI::Pointer(*Void)] arg
  # @return [ErrorT]
  # @scope class
  #
  attach_function :cntl, :lcb_cntl, [T.by_ref, :int, :int, :pointer], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method cntl_string(instance, key, value)
  # @param [T] instance
  # @param [String] key
  # @param [String] value
  # @return [ErrorT]
  # @scope class
  #
  attach_function :cntl_string, :lcb_cntl_string, [T.by_ref, :string, :string], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method cntl_setu32(instance, cmd, arg)
  # @param [T] instance
  # @param [Integer] cmd
  # @param [Integer] arg
  # @return [ErrorT]
  # @scope class
  #
  attach_function :cntl_setu32, :lcb_cntl_setu32, [T.by_ref, :int, :uint], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method cntl_getu32(instance, cmd)
  # @param [T] instance
  # @param [Integer] cmd
  # @return [Integer]
  # @scope class
  #
  attach_function :cntl_getu32, :lcb_cntl_getu32, [T.by_ref, :int], :uint, :blocking => true

  # (Not documented)
  #
  # @method cntl_exists(ctl)
  # @param [Integer] ctl
  # @return [Integer]
  # @scope class
  #
  attach_function :cntl_exists, :lcb_cntl_exists, [:int], :int, :blocking => true

  # (Not documented)
  #
  # @method enable_timings(instance)
  # @param [T] instance
  # @return [ErrorT]
  # @scope class
  #
  attach_function :enable_timings, :lcb_enable_timings, [T.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method disable_timings(instance)
  # @param [T] instance
  # @return [ErrorT]
  # @scope class
  #
  attach_function :disable_timings, :lcb_disable_timings, [T.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method get_timings(instance, cookie, callback)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [Proc(callback_timings_callback)] callback
  # @return [ErrorT]
  # @scope class
  #
  attach_function :get_timings, :lcb_get_timings, [T.by_ref, :pointer, :timings_callback], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method get_version(version)
  # @param [FFI::Pointer(*U32)] version
  # @return [String]
  # @scope class
  #
  attach_function :get_version, :lcb_get_version, [:pointer], :string, :blocking => true

  # (Not documented)
  #
  # @method supports_feature(n)
  # @param [Integer] n
  # @return [Integer]
  # @scope class
  #
  attach_function :supports_feature, :lcb_supports_feature, [:int], :int, :blocking => true

  # (Not documented)
  #
  # @method mem_alloc(size)
  # @param [Integer] size
  # @return [FFI::Pointer(*Void)]
  # @scope class
  #
  attach_function :mem_alloc, :lcb_mem_alloc, [:ulong], :pointer, :blocking => true

  # (Not documented)
  #
  # @method mem_free(ptr)
  # @param [FFI::Pointer(*Void)] ptr
  # @return [nil]
  # @scope class
  #
  attach_function :mem_free, :lcb_mem_free, [:pointer], :void, :blocking => true

  # (Not documented)
  #
  # @method run_loop(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :run_loop, :lcb_run_loop, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method stop_loop(instance)
  # @param [T] instance
  # @return [nil]
  # @scope class
  #
  attach_function :stop_loop, :lcb_stop_loop, [T.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method nstime()
  # @return [Integer]
  # @scope class
  #
  attach_function :nstime, :lcb_nstime, [], :ulong_long, :blocking => true

  # (Not documented)
  #
  # @method histogram_create()
  # @return [HISTOGRAM]
  # @scope class
  #
  attach_function :histogram_create, :lcb_histogram_create, [], HISTOGRAM.by_ref, :blocking => true

  # (Not documented)
  #
  # @method histogram_destroy(hg)
  # @param [HISTOGRAM] hg
  # @return [nil]
  # @scope class
  #
  attach_function :histogram_destroy, :lcb_histogram_destroy, [HISTOGRAM.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method histogram_record(hg, duration)
  # @param [HISTOGRAM] hg
  # @param [Integer] duration
  # @return [nil]
  # @scope class
  #
  attach_function :histogram_record, :lcb_histogram_record, [HISTOGRAM.by_ref, :ulong_long], :void, :blocking => true

  # (Not documented)
  #
  # @method histogram_read(hg, cookie, cb)
  # @param [HISTOGRAM] hg
  # @param [FFI::Pointer(*Void)] cookie
  # @param [Proc(callback_histogram_callback)] cb
  # @return [nil]
  # @scope class
  #
  attach_function :histogram_read, :lcb_histogram_read, [HISTOGRAM.by_ref, :pointer, :histogram_callback], :void, :blocking => true

  # (Not documented)
  #
  # @method histogram_print(hg, stream)
  # @param [HISTOGRAM] hg
  # @param [FFI::Pointer(*FILE)] stream
  # @return [nil]
  # @scope class
  #
  attach_function :histogram_print, :lcb_histogram_print, [HISTOGRAM.by_ref, :pointer], :void, :blocking => true

  # (Not documented)
  #
  # @method subdoc3(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDSUBDOC] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :subdoc3, :lcb_subdoc3, [T.by_ref, :pointer, CMDSUBDOC.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method sdresult_next(resp, out, iter)
  # @param [RESPSUBDOC] resp
  # @param [SDENTRY] out
  # @param [FFI::Pointer(*SizeT)] iter
  # @return [Integer]
  # @scope class
  #
  attach_function :sdresult_next, :lcb_sdresult_next, [RESPSUBDOC.by_ref, SDENTRY.by_ref, :pointer], :int, :blocking => true

  # (Not documented)
  #
  # @method view_query(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDVIEWQUERY] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :view_query, :lcb_view_query, [T.by_ref, :pointer, CMDVIEWQUERY.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method view_query_initcmd(vq, design, view, options, callback)
  # @param [CMDVIEWQUERY] vq
  # @param [String] design
  # @param [String] view
  # @param [String] options
  # @param [Proc(callback_viewquerycallback)] callback
  # @return [nil]
  # @scope class
  #
  attach_function :view_query_initcmd, :lcb_view_query_initcmd, [CMDVIEWQUERY.by_ref, :string, :string, :string, :viewquerycallback], :void

  # (Not documented)
  #
  # @method view_cancel(instance, handle)
  # @param [T] instance
  # @param [VIEWHANDLE] handle
  # @return [nil]
  # @scope class
  #
  attach_function :view_cancel, :lcb_view_cancel, [T.by_ref, VIEWHANDLE.by_ref], :void, :blocking => true

  # (Not documented)
  #
  # @method n1p_new()
  # @return [N1QLPARAMS]
  # @scope class
  #
  attach_function :n1p_new, :lcb_n1p_new, [], N1QLPARAMS.by_ref

  # (Not documented)
  #
  # @method n1p_reset(params)
  # @param [N1QLPARAMS] params
  # @return [nil]
  # @scope class
  #
  attach_function :n1p_reset, :lcb_n1p_reset, [N1QLPARAMS.by_ref], :void

  # (Not documented)
  #
  # @method n1p_free(params)
  # @param [N1QLPARAMS] params
  # @return [nil]
  # @scope class
  #
  attach_function :n1p_free, :lcb_n1p_free, [N1QLPARAMS.by_ref], :void

  # (Not documented)
  #
  # @method n1p_setquery(params, qstr, nqstr, type)
  # @param [N1QLPARAMS] params
  # @param [String] qstr
  # @param [Integer] nqstr
  # @param [Integer] type
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1p_setquery, :lcb_n1p_setquery, [N1QLPARAMS.by_ref, :string, :ulong, :int], ErrorT

  # (Not documented)
  #
  # @method n1p_namedparam(params, name, n_name, value, n_value)
  # @param [N1QLPARAMS] params
  # @param [String] name
  # @param [Integer] n_name
  # @param [String] value
  # @param [Integer] n_value
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1p_namedparam, :lcb_n1p_namedparam, [N1QLPARAMS.by_ref, :string, :ulong, :string, :ulong], ErrorT

  # (Not documented)
  #
  # @method n1p_posparam(params, value, n_value)
  # @param [N1QLPARAMS] params
  # @param [String] value
  # @param [Integer] n_value
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1p_posparam, :lcb_n1p_posparam, [N1QLPARAMS.by_ref, :string, :ulong], ErrorT

  # (Not documented)
  #
  # @method n1p_setopt(params, name, n_name, value, n_value)
  # @param [N1QLPARAMS] params
  # @param [String] name
  # @param [Integer] n_name
  # @param [String] value
  # @param [Integer] n_value
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1p_setopt, :lcb_n1p_setopt, [N1QLPARAMS.by_ref, :string, :ulong, :string, :ulong], ErrorT

  # (Not documented)
  #
  # @method n1p_setconsistency(params, mode)
  # @param [N1QLPARAMS] params
  # @param [Integer] mode
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1p_setconsistency, :lcb_n1p_setconsistency, [N1QLPARAMS.by_ref, :int], ErrorT

  # (Not documented)
  #
  # @method n1p_setconsistent_token(params, keyspace, st)
  # @param [N1QLPARAMS] params
  # @param [String] keyspace
  # @param [MUTATIONTOKEN] st
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1p_setconsistent_token, :lcb_n1p_setconsistent_token, [N1QLPARAMS.by_ref, :string, MUTATIONTOKEN.by_ref], ErrorT

  # (Not documented)
  #
  # @method n1p_setconsistent_handle(params, instance)
  # @param [N1QLPARAMS] params
  # @param [T] instance
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1p_setconsistent_handle, :lcb_n1p_setconsistent_handle, [N1QLPARAMS.by_ref, T.by_ref], ErrorT

  # (Not documented)
  #
  # @method n1p_encode(params, rc)
  # @param [N1QLPARAMS] params
  # @param [FFI::Pointer(*ErrorT)] rc
  # @return [String]
  # @scope class
  #
  attach_function :n1p_encode, :lcb_n1p_encode, [N1QLPARAMS.by_ref, :pointer], :string

  # (Not documented)
  #
  # @method n1p_mkcmd(params, cmd)
  # @param [N1QLPARAMS] params
  # @param [CMDN1QL] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1p_mkcmd, :lcb_n1p_mkcmd, [N1QLPARAMS.by_ref, CMDN1QL.by_ref], ErrorT

  # (Not documented)
  #
  # @method n1ql_query(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDN1QL] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :n1ql_query, :lcb_n1ql_query, [T.by_ref, :pointer, CMDN1QL.by_ref], ErrorT, :blocking => true

  # (Not documented)
  #
  # @method n1ql_cancel(instance, handle)
  # @param [T] instance
  # @param [N1QLHANDLE] handle
  # @return [nil]
  # @scope class
  #
  attach_function :n1ql_cancel, :lcb_n1ql_cancel, [T.by_ref, N1QLHANDLE.by_ref], :void, :blocking => true

  # @volatile
  # Issue a full-text query. The callback (lcb_CMDFTS::callback) will be invoked
  # for each hit. It will then be invoked one last time with the result
  # metadata (including any facets) and the lcb_RESPFTS::rflags field having
  # the @ref LCB_RESP_F_FINAL bit set
  #
  # @param instance the instance
  # @param cookie opaque user cookie to be set in the response object
  # @param cmd command containing the query and callback
  #
  # @method fts_query(instance, cookie, cmd)
  # @param [T] instance
  # @param [FFI::Pointer(*Void)] cookie
  # @param [CMDFTS] cmd
  # @return [ErrorT]
  # @scope class
  #
  attach_function :fts_query, :lcb_fts_query, [T.by_ref, :pointer, CMDFTS.by_ref], ErrorT, :blocking => true

  # @volatile
  # Cancel a full-text query in progress. The handle is usually obtained via the
  # lcb_CMDFTS::handle pointer.
  #
  # @method fts_cancel(t, ftshandle)
  # @param [T] t
  # @param [FTSHANDLE] ftshandle
  # @return [nil]
  # @scope class
  #
  attach_function :fts_cancel, :lcb_fts_cancel, [T.by_ref, FTSHANDLE.by_ref], :void, :blocking => true

end
