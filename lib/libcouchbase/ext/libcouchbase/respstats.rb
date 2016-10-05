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
  # :server ::
  #   (String)
  # :value ::
  #   (String) < The value, if any, for the given statistic
  # :nvalue ::
  #   (Integer) < Length of value
  class RESPSTATS < FFI::Struct
    layout :cookie, :pointer,
           :key, :pointer,
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :server, :string,
           :value, :string,
           :nvalue, :ulong
  end

end
