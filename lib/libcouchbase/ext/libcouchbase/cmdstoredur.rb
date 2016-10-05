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
  #   (VALBUF) < @see lcb_CMDSTORE::value
  # :flags ::
  #   (Integer) < @see lcb_CMDSTORE::flags
  # :datatype ::
  #   (Integer) < @private
  # :operation ::
  #   (StorageT) < @see lcb_CMDSTORE::operation
  # :persist_to ::
  #   (Integer) Number of nodes to persist to. If negative, will be capped at the maximum
  #   allowable for the current cluster.
  #   @see lcb_DURABILITYOPTSv0::persist_to
  # :replicate_to ::
  #   (Integer) Number of nodes to replicate to. If negative, will be capped at the maximum
  #   allowable for the current cluster.
  #   @see lcb_DURABILITYOPTSv0::replicate_to
  class CMDSTOREDUR < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :value, VALBUF.by_value,
           :flags, :uint,
           :datatype, :uchar,
           :operation, StorageT,
           :persist_to, :char,
           :replicate_to, :char
  end

end
