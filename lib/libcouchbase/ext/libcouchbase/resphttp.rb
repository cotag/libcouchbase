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
  # :htstatus ::
  #   (Integer) HTTP status code. The value is only valid if #rc is ::LCB_SUCCESS
  #   (if #rc is not LCB_SUCCESS then this field may be 0 as the response may
  #   have not been read/sent)
  # :headers ::
  #   (FFI::Pointer(**CharS)) List of key-value headers. This field itself may be `NULL`. The list
  #   is terminated by a `NULL` pointer to indicate no more headers.
  # :body ::
  #   (FFI::Pointer(*Void)) If @ref LCB_CMDHTTP_F_STREAM is true, contains the current chunk
  #   of response content. Otherwise, contains the entire response body.
  # :nbody ::
  #   (Integer) Length of buffer in #body
  # :htreq ::
  #   (HttpRequestT) @private
  class RESPHTTP < FFI::Struct
    layout :cookie, :pointer,
           :key, :pointer,
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :htstatus, :short,
           :headers, :pointer,
           :body, :pointer,
           :nbody, :ulong,
           :htreq, HttpRequestT.by_ref
  end

end
