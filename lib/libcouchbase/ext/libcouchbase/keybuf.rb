module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :type ::
  #   (KVBUFTYPE) The type of key to provide. This can currently be LCB_KV_COPY (Default)
  #   to copy the key into the pipeline buffers, or LCB_KV_HEADER_AND_KEY
  #   to provide a buffer with the header storage and the key.
  #
  #   TODO:
  #   Currently only LCB_KV_COPY should be used. LCB_KV_HEADER_AND_KEY is used
  #   internally but may be exposed later on
  # :contig ::
  #   (CONTIGBUF)
  class KEYBUF < FFI::Struct
    layout :type, KVBUFTYPE,
           :contig, CONTIGBUF.by_value
  end

end
