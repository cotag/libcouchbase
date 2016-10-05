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
  # :delta ::
  #   (Integer) Delta value. If this number is negative the item on the server is
  #   decremented. If this number is positive then the item on the server
  #   is incremented
  # :initial ::
  #   (Integer) If the item does not exist on the server (and `create` is true) then
  #   this will be the initial value for the item.
  # :create ::
  #   (Integer) Boolean value. Create the item and set it to `initial` if it does not
  #   already exist
  class CMDCOUNTER < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :delta, :long_long,
           :initial, :ulong_long,
           :create, :int
  end

end
