module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :cookie ::
  #   (FFI::Pointer(*Void))
  # :key ::
  #   (FFI::Pointer(*Void))
  # :nkey ::
  #   (Integer)
  # :cas ::
  #   (Integer)
  # :rc ::
  #   (ErrorT)
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
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :status, :uchar,
           :ismaster, :uchar,
           :ttp, :uint,
           :ttr, :uint
  end

end
