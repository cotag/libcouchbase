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
  # :row ::
  #   (String) A query hit, or response metadta
  #   (if #rflags contains @ref LCB_RESP_F_FINAL). The format of the row will
  #   be JSON, and should be decoded by a JSON decoded in your application.
  # :nrow ::
  #   (Integer) Length of #row
  # :htresp ::
  #   (RESPHTTP) Original HTTP response obejct
  class RESPFTS < FFI::Struct
    layout :cookie, :pointer,
           :key, :pointer,
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :row, :string,
           :nrow, :ulong,
           :htresp, RESPHTTP.by_ref
  end

end
