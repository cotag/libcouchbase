module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :connstr ::
  #   (String) < Connection string
  # :username ::
  #   (String) < Username for bucket. Unused as of Server 2.5
  # :passwd ::
  #   (String) < Password for bucket
  # :pad_bucket ::
  #   (FFI::Pointer(*Void)) < @private
  # :io ::
  #   (FFI::Pointer(*IoOptSt)) < IO Options
  # :type ::
  #   (TypeT)
  class CreateSt3 < FFI::Struct
    layout :connstr, :pointer,
           :username, :pointer,
           :passwd, :pointer,
           :pad_bucket, :pointer,
           :io, :pointer,
           :type, TypeT
  end

end
