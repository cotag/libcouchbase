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
  # :lock ::
  #   (Integer) If set to true, the `exptime` field inside `options` will take to mean
  #   the time the lock should be held. While the lock is held, other operations
  #   trying to access the key will fail with an `LCB_ETMPFAIL` error. The
  #   item may be unlocked either via `lcb_unlock3()` or via a mutation
  #   operation with a supplied CAS
  class CMDGET < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :lock, :int
  end

end
