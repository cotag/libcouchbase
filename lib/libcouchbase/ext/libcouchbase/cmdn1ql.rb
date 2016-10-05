module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :cmdflags ::
  #   (Integer)
  # :query ::
  #   (String) Query to be placed in the POST request. The library will not perform
  #   any conversions or validation on this string, so it is up to the user
  #   (or wrapping library) to ensure that the string is well formed.
  #
  #   If using the @ref lcb_N1QLPARAMS structure, the lcb_n1p_mkcmd() function
  #   will properly populate this field.
  #
  #   In general the string should either be JSON (in which case, the
  #   #content_type field should be `application/json`) or url-encoded
  #   (in which case the #content_type field should be
  #   `application/x-www-form-urlencoded`)
  # :nquery ::
  #   (Integer) Length of the query data
  # :host ::
  #   (String) Ignored since version 2.5.3
  # :content_type ::
  #   (String) Ignored since version 2.5.3
  # :callback ::
  #   (Proc(callback_n1qlcallback)) Callback to be invoked for each row
  # :handle ::
  #   (FFI::Pointer(*N1QLHANDLE)) Request handle. Will be set to the handle which may be passed to
  #   lcb_n1ql_cancel()
  class CMDN1QL < FFI::Struct
    layout :cmdflags, :uint,
           :query, :string,
           :nquery, :ulong,
           :host, :string,
           :content_type, :string,
           :callback, :n1qlcallback,
           :handle, :pointer
  end

end
