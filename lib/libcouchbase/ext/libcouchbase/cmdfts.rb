module Libcouchbase::Ext
  # @brief Search Command
  #
  # ## Fields:
  # :cmdflags ::
  #   (Integer) Modifiers for command. Currently none are defined
  # :query ::
  #   (String) Encoded JSON query
  # :nquery ::
  #   (Integer) Length of JSON query
  # :callback ::
  #   (Proc(callback_ftscallback)) Callback to be invoked. This must be supplied
  # :handle ::
  #   (FFI::Pointer(*FTSHANDLE)) Optional pointer to store the handle. The handle may then be
  #   used for query cancellation via lcb_fts_cancel()
  class CMDFTS < FFI::Struct
    layout :cmdflags, :uint,
           :query, :pointer,
           :nquery, :ulong,
           :callback, :ftscallback,
           :handle, :pointer
  end

end
