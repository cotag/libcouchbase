module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :vtype ::
  #   (KVBUFTYPE) Value request type. This may be one of:
  #   - LCB_KV_COPY: Copy over the value into LCB's own buffers
  #     Use the 'contig' field to supply the information.
  #
  #   - LCB_KV_CONTIG: The buffer is a contiguous chunk of value data.
  #     Use the 'contig' field to supply the information.
  #
  #   - LCB_KV_IOV: The buffer is a series of IOV elements. Use the 'multi'
  #     field to supply the information.
  # :u_buf ::
  #   (VALBUFUBuf)
  class VALBUF < FFI::Struct
    layout :vtype, KVBUFTYPE,
           :u_buf, VALBUFUBuf.by_value
  end

end
