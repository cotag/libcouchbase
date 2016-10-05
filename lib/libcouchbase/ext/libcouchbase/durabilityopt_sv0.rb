module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :timeout ::
  #   (Integer) Upper limit in microseconds from the scheduling of the command. When
  #   this timeout occurs, all remaining non-verified keys will have their
  #   callbacks invoked with @ref LCB_ETIMEDOUT.
  #
  #   If this field is not set, the value of @ref LCB_CNTL_DURABILITY_TIMEOUT
  #   will be used.
  # :interval ::
  #   (Integer) The durability check may involve more than a single call to observe - or
  #   more than a single packet sent to a server to check the key status. This
  #   value determines the time to wait (in microseconds)
  #   between multiple probes for the same server.
  #   If not set, the @ref LCB_CNTL_DURABILITY_INTERVAL will be used
  #   instead.
  # :persist_to ::
  #   (Integer) how many nodes the key should be persisted to (including master).
  #   If set to 0 then persistence will not be checked. If set to a large
  #   number (i.e. UINT16_MAX) and #cap_max is also set, will be set to the
  #   maximum number of nodes to which persistence is possible (which will
  #   always contain at least the master node).
  #
  #   The maximum valid value for this field is
  #   1 + the total number of configured replicas for the bucket which are part
  #   of the cluster. If this number is higher then it will either be
  #   automatically capped to the maximum available if (#cap_max is set) or
  #   will result in an ::LCB_DURABILITY_ETOOMANY error.
  # :replicate_to ::
  #   (Integer) how many nodes the key should be persisted to (excluding master).
  #   If set to 0 then replication will not be checked. If set to a large
  #   number (i.e. UINT16_MAX) and #cap_max is also set, will be set to the
  #   maximum number of nodes to which replication is possible (which may
  #   be 0 if the bucket is not configured for replicas).
  #
  #   The maximum valid value for this field is the total number of configured
  #   replicas which are part of the cluster. If this number is higher then
  #   it will either be automatically capped to the maximum available
  #   if (#cap_max is set) or will result in an ::LCB_DURABILITY_ETOOMANY
  #   error.
  # :check_delete ::
  #   (Integer) this flag inverts the sense of the durability check and ensures that
  #   the key does *not* exist. This should be used if checking durability
  #   after an lcb_remove3() operation.
  # :cap_max ::
  #   (Integer) If replication/persistence requirements are excessive, cap to
  #   the maximum available
  # :pollopts ::
  #   (Integer) Set the polling method to use.
  #   The value for this field should be one of the @ref lcb_DURMODE constants.
  class DURABILITYOPTSv0 < FFI::Struct
    layout :timeout, :uint,
           :interval, :uint,
           :persist_to, :ushort,
           :replicate_to, :ushort,
           :check_delete, :uchar,
           :cap_max, :uchar,
           :pollopts, :uchar
  end

end
