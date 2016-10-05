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
  # :nresponses ::
  #   (Integer) Total number of polls (i.e. how many packets per server) did this
  #   operation require
  # :exists_master ::
  #   (Integer) Whether this item exists in the master in its current form. This can be
  #   true even if #rc is not successful
  # :persisted_master ::
  #   (Integer) True if item was persisted on the master node. This may be true even if
  #   #rc is not successful.
  # :npersisted ::
  #   (Integer) Total number of nodes (including master) on which this mutation has
  #   been persisted. Valid even if #rc is not successful.
  # :nreplicated ::
  #   (Integer) Total number of replica nodes to which this mutation has been replicated.
  #   Valid even if #rc is not successful.
  class RESPENDURE < FFI::Struct
    layout :cookie, :pointer,
           :key, :pointer,
           :nkey, :ulong,
           :cas, :ulong_long,
           :rc, ErrorT,
           :version, :ushort,
           :rflags, :ushort,
           :nresponses, :ushort,
           :exists_master, :uchar,
           :persisted_master, :uchar,
           :npersisted, :uchar,
           :nreplicated, :uchar
  end

end
