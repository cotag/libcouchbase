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
  # :type ::
  #   (HttpTypeT) Type of request to issue. LCB_HTTP_TYPE_VIEW will issue a request
  #   against a random node's view API. LCB_HTTP_TYPE_MANAGEMENT will issue
  #   a request against a random node's administrative API, and
  #   LCB_HTTP_TYPE_RAW will issue a request against an arbitrary host.
  # :method ::
  #   (HttpMethodT) < HTTP Method to use
  # :body ::
  #   (String) If the request requires a body (e.g. `PUT` or `POST`) then it will
  #   go here. Be sure to indicate the length of the body too.
  # :nbody ::
  #   (Integer) Length of the body for the request
  # :reqhandle ::
  #   (FFI::Pointer(*HttpRequestT)) If non-NULL, will be assigned a handle which may be used to
  #   subsequently cancel the request
  # :content_type ::
  #   (String) For views, set this to `application/json`
  # :username ::
  #   (String) Username to authenticate with, if left empty, will use the credentials
  #   passed to lcb_create()
  # :password ::
  #   (String) Password to authenticate with, if left empty, will use the credentials
  #   passed to lcb_create()
  # :host ::
  #   (String) If set, this must be a string in the form of `http://host:port`. Should
  #   only be used for raw requests.
  class CMDHTTP < FFI::Struct
    layout :cmdflags, :uint,
           :exptime, :uint,
           :cas, :ulong_long,
           :key, KEYBUF.by_value,
           :hashkey, KEYBUF.by_value,
           :type, HttpTypeT,
           :method, HttpMethodT,
           :body, :pointer,
           :nbody, :ulong,
           :reqhandle, :pointer,
           :content_type, :pointer,
           :username, :pointer,
           :password, :pointer,
           :host, :pointer
  end

end
