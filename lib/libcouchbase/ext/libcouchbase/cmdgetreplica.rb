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
  # :strategy ::
  #   (ReplicaT) Strategy for selecting a replica. The default is ::LCB_REPLICA_FIRST
  #   which results in the client trying each replica in sequence until a
  #   successful reply is found, and returned in the callback.
  #
  #   ::LCB_REPLICA_FIRST evaluates to 0.
  #
  #   Other options include:
  #   <ul>
  #   <li>::LCB_REPLICA_ALL - queries all replicas concurrently and dispatches
  #   a callback for each reply</li>
  #   <li>::LCB_REPLICA_SELECT - queries a specific replica indicated in the
  #   #index field</li>
  #   </ul>
  #
  #   @note When ::LCB_REPLICA_ALL is selected, the callback will be invoked
  #   multiple times, one for each replica. The final callback will have the
  #   ::LCB_RESP_F_FINAL bit set in the lcb_RESPBASE::rflags field. The final
  #   response will also contain the response from the last replica to
  #   respond.
  # :index ::
  #   (Integer) Valid only when #strategy is ::LCB_REPLICA_SELECT, specifies the replica
  #   index number to query. This should be no more than `nreplicas-1`
  #   where `nreplicas` is the number of replicas the bucket is configured with.
  class CMDGETREPLICA < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :strategy, ReplicaT,
           :index, :int
  end

end
