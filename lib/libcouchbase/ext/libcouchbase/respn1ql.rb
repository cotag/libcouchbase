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
  #   (String) Current result row. If #rflags has the ::LCB_RESP_F_FINAL bit set, then
  #   this field does not contain the actual row, but the remainder of the
  #   data not included with the resultset; e.g. the JSON surrounding
  #   the "results" field with any errors or metadata for the response.
  # :nrow ::
  #   (Integer) Length of the row
  # :htresp ::
  #   (RESPHTTP) Raw HTTP response, if applicable
  class RESPN1QL < FFI::Struct
    layout :cookie, :pointer,
           :key, :pointer,
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :row, :pointer,
           :nrow, :ulong,
           :htresp, RESPHTTP.by_ref
  end

end
