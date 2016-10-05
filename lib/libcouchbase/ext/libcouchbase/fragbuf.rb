module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :iov ::
  #   (FFI::Pointer(*IOV)) An IOV array
  # :niov ::
  #   (Integer) Number of elements in iov array
  # :total_length ::
  #   (Integer) Total length of the items. This should be set, if known, to prevent the
  #   library from manually traversing the iov array to calculate the length.
  class FRAGBUF < FFI::Struct
    layout :iov, :pointer,
           :niov, :uint,
           :total_length, :uint
  end

end
