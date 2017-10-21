module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :sdcmd ::
  #   (Integer) The command code, @ref lcb_SUBDOCOP. There is no default for this
  #   value, and it therefore must be set.
  # :options ::
  #   (Integer) Set of option flags for the command. Currently the only option known
  #   is @ref LCB_SDSPEC_F_MKINTERMEDIATES
  # :path ::
  #   (KEYBUF) Path for the operation. This should be assigned using
  #   @ref LCB_SDSPEC_SET_PATH. The contents of the path should be valid
  #   until the operation is scheduled (lcb_subdoc3())
  # :value ::
  #   (VALBUF) @value for the operation. This should be assigned using
  #   @ref LCB_SDSPEC_SET_VALUE. The contents of the value should be valid
  #   until the operation is scheduled (i.e. lcb_subdoc3())
  class SDSPEC < FFI::Struct
    MKINTERMEDIATES = (1<<16) # Create intermediate paths
    XATTRPATH = (1<<18) # Access document XATTR path 
    XATTR_MACROVALUES = (1<<19) # Access document virtual/materialized path
    XATTR_DELETED_OK = (1<<20) # Access Xattrs of deleted documents

    layout :sdcmd, :uint,
           :options, :uint,
           :path, KEYBUF.by_value,
           :value, VALBUF.by_value
  end

end
