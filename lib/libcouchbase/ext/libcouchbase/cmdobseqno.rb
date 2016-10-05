module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :cmdflags ::
  #   (Integer)
  # :exptime ::
  #   (Integer)
  # :cas ::
  #   (Integer)
  # :key ::
  #   (KEYBUF)
  # :hashkey ::
  #   (KEYBUF)
  # :server_index ::
  #   (Integer) Server index to target. The server index must be valid and must also
  #   be either a master or a replica for the vBucket indicated in #vbid
  # :vbid ::
  #   (Integer) < vBucket ID to query
  # :uuid ::
  #   (Integer) < UUID known to client which should be queried
  class CMDOBSEQNO < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :server_index, :ushort,
           :vbid, :ushort,
           :uuid, :ulong_long
  end

end
