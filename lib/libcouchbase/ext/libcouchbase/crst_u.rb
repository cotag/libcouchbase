module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :v0 ::
  #   (CreateSt0)
  # :v1 ::
  #   (CreateSt1)
  # :v2 ::
  #   (CreateSt2)
  # :v3 ::
  #   (CreateSt3) < Use this field
  class CRSTU < FFI::Union
    layout :v0, CreateSt0.by_value,
           :v1, CreateSt1.by_value,
           :v2, CreateSt2.by_value,
           :v3, CreateSt3.by_value
  end

end
