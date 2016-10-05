module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :cmdflags ::
  #   (Integer)
  # :exptime ::
  #   (Integer)
  # :cas ::
  #   (Integer)
  # :key ::
  #   (KEYBUF)
  # :hashkey ::
  #   (KEYBUF)
  # :value ::
  #   (VALBUF) Value to store on the server. The value may be set using the
  #   LCB_CMD_SET_VALUE() or LCB_CMD_SET_VALUEIOV() API
  # :flags ::
  #   (Integer) Format flags used by clients to determine the underlying encoding of
  #   the value. This value is also returned during retrieval operations in the
  #   lcb_RESPGET::itmflags field
  # :datatype ::
  #   (Integer) Do not set this value for now
  # :operation ::
  #   (StorageT) Controls *how* the operation is perfomed. See the documentation for
  #   @ref lcb_storage_t for the options. There is no default value for this
  #   field.
  class CMDSTORE < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :value, VALBUF.by_value,
           :flags, :uint,
           :datatype, :uchar,
           :operation, StorageT
  end

end
