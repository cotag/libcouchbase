module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :value ::
  #   (FFI::Pointer(*Void)) Value for the mutation (only applicable for ::LCB_SUBDOC_COUNTER, currently)
  # :nvalue ::
  #   (Integer) Length of the value
  # :status ::
  #   (ErrorT) Status code
  # :index ::
  #   (Integer) Request index which this result pertains to. This field only
  #   makes sense for multi mutations where not all request specs are returned
  #   in the result
  class SDENTRY < FFI::Struct
    layout :value, :pointer,
           :nvalue, :ulong,
           :status, ErrorT,
           :index, :uchar
  end

end
