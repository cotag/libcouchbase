module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :version ::
  #   (Integer)
  # :v ::
  #   (DurabilityOptsStV)
  class DurabilityOptsT < FFI::Struct
    layout :version, :int,
           :v, DurabilityOptsStV.by_value
  end

end
