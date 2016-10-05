module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :contig ::
  #   (CONTIGBUF)
  # :multi ::
  #   (FRAGBUF)
  class VALBUFUBuf < FFI::Union
    layout :contig, CONTIGBUF.by_value,
           :multi, FRAGBUF.by_value
  end

end
