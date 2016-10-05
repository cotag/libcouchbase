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
  # :vbid ::
  #   (Integer) < vBucket ID (for potential mapping)
  # :server_index ::
  #   (Integer) < Input server index
  # :cur_uuid ::
  #   (Integer) < UUID for this vBucket as known to the server
  # :persisted_seqno ::
  #   (Integer) < Highest persisted sequence
  # :mem_seqno ::
  #   (Integer) < Highest known sequence
  # :old_uuid ::
  #   (Integer) In the case where the command's uuid is not the most current, this
  #   contains the last known UUID
  # :old_seqno ::
  #   (Integer) If #old_uuid is nonzero, contains the highest sequence number persisted
  #   in the #old_uuid snapshot.
  class RESPOBSEQNO < FFI::Struct
    layout :cookie, :pointer,
           :key, :pointer,
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :vbid, :ushort,
           :server_index, :ushort,
           :cur_uuid, :ulong_long,
           :persisted_seqno, :ulong_long,
           :mem_seqno, :ulong_long,
           :old_uuid, :ulong_long,
           :old_seqno, :ulong_long
  end

end
