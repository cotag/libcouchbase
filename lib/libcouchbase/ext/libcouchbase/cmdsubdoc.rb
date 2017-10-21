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
    # CMD flags
    UPSERT_DOC = (1<<16) # document is to be created if it does not exist.
    INSERT_DOC = (1<<17) # document must be created anew. Fail if it exists
    ACCESS_DELETED = (1<<18) # Access a potentially deleted document.

    SDMULTI_MODE_INVALID = 0
    SDMULTI_MODE_LOOKUP = 1
    SDMULTI_MODE_MUTATE = 2

    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :specs, SDSPEC.by_ref,
           :nspecs, :ulong,
           :error_index, :pointer,

           # This can either be SDMULTI_MODE_LOOKUP or SDMULTI_MODE_MUTATE
           # This field may be left empty, in which case the mode is implicitly derived from the _first_ command issued.
           :multimode, :uint
  end

end
