module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :v0 ::
  #   (DURABILITYOPTSv0)
  class DurabilityOptsStV < FFI::Union
    layout :v0, DURABILITYOPTSv0.by_value
  end

end
