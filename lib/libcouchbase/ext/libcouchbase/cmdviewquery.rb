module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :cmdflags ::
  #   (Integer) Common command flags; e.g. @ref LCB_CMDVIEWQUERY_F_INCLUDE_DOCS
  # :ddoc ::
  #   (String) The design document as a string; e.g. `"beer"`
  # :nddoc ::
  #   (Integer) Length of design document name
  # :view ::
  #   (String) The name of the view as a string; e.g. `"brewery_beers"`
  # :nview ::
  #   (Integer) Length of the view name
  # :optstr ::
  #   (String) Any URL parameters to be passed to the view should be specified here.
  #   The library will internally insert a `?` character before the options
  #   (if specified), so do not place one yourself.
  #
  #   The format of the options follows the standard for passing parameters
  #   via HTTP requests; thus e.g. `key1=value1&key2=value2`. This string
  #   is itself not parsed by the library but simply appended to the URL.
  # :noptstr ::
  #   (Integer) Length of the option string
  # :postdata ::
  #   (String) Some query parameters (in particular; 'keys') may be send via a POST
  #   request within the request body, since it might be too long for the
  #   URI itself. If you have such data, place it here.
  # :npostdata ::
  #   (Integer)
  # :docs_concurrent_max ::
  #   (Integer) The maximum number of internal get requests to issue concurrently for
  #   @c F_INCLUDE_DOCS. This is useful for large view responses where
  #   there is a potential for a large number of responses resulting in a large
  #   number of get requests; increasing memory usage.
  #
  #   Setting this value will attempt to throttle the number of get requests,
  #   so that no more than this number of requests will be in progress at any
  #   given time.
  # :callback ::
  #   (Proc(callback_viewquerycallback)) Callback to invoke for each row. If not provided, @ref LCB_EINVAL will
  #   be returned from lcb_view_query()
  # :handle ::
  #   (FFI::Pointer(*VIEWHANDLE)) If not NULL, this will be set to a handle which may be passed to
  #   lcb_view_cancel(). See that function for more details
  class CMDVIEWQUERY < FFI::Struct
    layout :cmdflags, :uint,
           :ddoc, :string,
           :nddoc, :ulong,
           :view, :string,
           :nview, :ulong,
           :optstr, :string,
           :noptstr, :ulong,
           :postdata, :string,
           :npostdata, :ulong,
           :docs_concurrent_max, :uint,
           :callback, :viewquerycallback,
           :handle, :pointer
  end

end
