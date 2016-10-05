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
  # :type ::
  #   (TypeT)
  # :mchosts ::
  #   (String)
  # :transports ::
  #   (FFI::Pointer(*ConfigTransportT))
  class CreateSt2 < FFI::Struct
    layout :host, :string,
           :user, :string,
           :passwd, :string,
           :bucket, :string,
           :io, :pointer,
           :type, TypeT,
           :mchosts, :string,
           :transports, :pointer
  end

end
