module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :uuid ::
  #   (Integer) < Use LCB_MUTATION_TOKEN_ID()
  # :seqno ::
  #   (Integer) < Use LCB_MUTATION_TOKEN_SEQ()
  # :vbid ::
  #   (Integer) < Use LCB_MUTATION_TOKEN_VB()
  class MUTATIONTOKEN < FFI::Struct
    layout :uuid, :ulong_long,
           :seqno, :ulong_long,
           :vbid, :ushort
  end

end
