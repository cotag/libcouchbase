module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :host ::
  #   (String)
  # :user ::
  #   (String)
  # :passwd ::
  #   (String)
  # :bucket ::
  #   (String)
  # :io ::
  #   (FFI::Pointer(*IoOptSt))
  class CreateSt0 < FFI::Struct
    layout :host, :string,
           :user, :string,
           :passwd, :string,
           :bucket, :string,
           :io, :pointer
  end

end
