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
  # :servers ::
  #   (FFI::Pointer(*U16)) For internal use: This determines the servers the command should be
  #   routed to. Each entry is an index within the server.
  # :nservers ::
  #   (Integer)
  class CMDOBSERVE < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :servers, :pointer,
           :nservers, :ulong
  end

end
