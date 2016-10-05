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
  # :specs ::
  #   (SDSPEC) An array of one or more command specifications. The storage
  #   for the array need only persist for the duration of the
  #   lcb_subdoc3() call.
  #
  #   The specs array must be valid only through the invocation
  #   of lcb_subdoc3(). As such, they can reside on the stack and
  #   be re-used for scheduling multiple commands. See subdoc-simple.cc
  # :nspecs ::
  #   (Integer) Number of entries in #specs
  # :error_index ::
  #   (FFI::Pointer(*Int)) If the scheduling of the command failed, the index of the entry which
  #   caused the failure will be written to this pointer.
  #
  #   If the value is -1 then the failure took place at the command level
  #   and not at the spec level.
  # :multimode ::
  #   (Integer) Operation mode to use. This can either be @ref LCB_SDMULTI_MODE_LOOKUP
  #   or @ref LCB_SDMULTI_MODE_MUTATE.
  #
  #   This field may be left empty, in which case the mode is implicitly
  #   derived from the _first_ command issued.
  class CMDSUBDOC < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :specs, SDSPEC.by_ref,
           :nspecs, :ulong,
           :error_index, :pointer,
           :multimode, :uint
  end

end
