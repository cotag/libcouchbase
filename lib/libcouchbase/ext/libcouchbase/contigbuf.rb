module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :bytes ::
  #   (FFI::Pointer(*Void))
  # :nbytes ::
  #   (Integer) Number of total bytes
  class CONTIGBUF < FFI::Struct
    layout :bytes, :pointer,
           :nbytes, :ulong
  end

end
