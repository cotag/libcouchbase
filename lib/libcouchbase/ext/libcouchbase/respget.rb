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
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :value, :pointer,
           :nvalue, :ulong,
           :bufh, :pointer,
           :datatype, :uchar,
           :itmflags, :uint
  end

end
