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
  # :docid ::
  #   (String) < Document ID (i.e. memcached key) associated with this row
  # :ndocid ::
  #   (Integer) < Length of document ID
  # :value ::
  #   (String) Emitted value. If `rflags & LCB_RESP_F_FINAL` is true then this will
  #   contain the _metadata_ of the view response itself. This includes the
  #   `total_rows` field among other things, and should be parsed as JSON
  # :nvalue ::
  #   (Integer) < Length of emitted value
  # :geometry ::
  #   (String) If this is a spatial view, the GeoJSON geometry fields will be here
  # :ngeometry ::
  #   (Integer)
  # :htresp ::
  #   (RESPHTTP) If the request failed, this will contain the raw underlying request.
  #   You may inspect this request and perform some other processing on
  #   the underlying HTTP data. Note that this may not necessarily contain
  #   the entire response body; just the chunk at which processing failed.
  # :docresp ::
  #   (RESPGET) If @ref LCB_CMDVIEWQUERY_F_INCLUDE_DOCS was specified in the request,
  #   this will contain the response for the _GET_ command. This is the same
  #   response as would be received in the `LCB_CALLBACK_GET` for
  #   lcb_get3().
  #
  #   Note that this field should be checked for various errors as well, as it
  #   is remotely possible the get request did not succeed.
  #
  #   If the @ref LCB_CMDVIEWQUERY_F_INCLUDE_DOCS flag was not specified, this
  #   field will be `NULL`.
  class RESPVIEWQUERY < FFI::Struct
    layout :cookie, :pointer,
           :key, :pointer,
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :docid, :string,
           :ndocid, :ulong,
           :value, :string,
           :nvalue, :ulong,
           :geometry, :string,
           :ngeometry, :ulong,
           :htresp, RESPHTTP.by_ref,
           :docresp, RESPGET.by_ref
  end

end
