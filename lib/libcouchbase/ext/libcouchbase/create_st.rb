module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :version ::
  #   (Integer) Indicates which field in the @ref lcb_CRST_u union should be used. Set this to `3`
  # :v ::
  #   (CRSTU) This union contains the set of current and historical options. The
  #   The #v3 field should be used.
  class CreateSt < FFI::Struct
    layout :version, :int,
           :v, CRSTU.by_value
  end

end
