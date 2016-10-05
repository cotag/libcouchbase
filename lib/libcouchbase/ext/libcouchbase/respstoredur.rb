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
  # :dur_resp ::
  #   (RESPENDURE) Internal durability response structure. This should never be NULL
  # :store_ok ::
  #   (Integer) If the #rc field is not @ref LCB_SUCCESS, this field indicates
  #   what failed. If this field is nonzero, then the store operation failed,
  #   but the durability checking failed. If this field is zero then the
  #   actual storage operation failed.
  class RESPSTOREDUR < FFI::Struct
    layout :cookie, :pointer,
           :key, :pointer,
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :dur_resp, RESPENDURE.by_ref,
           :store_ok, :int
  end

end
