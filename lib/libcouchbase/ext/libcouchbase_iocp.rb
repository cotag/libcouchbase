
# This file contains all the structures required to configure libcouchbase to use
# Libuv as the primary event loop

module Libcouchbase::Ext

    # ref: http://docs.couchbase.com/sdk-api/couchbase-c-client-2.6.2/group__lcb-io-plugin-api.html

    IOType = enum [
        :IO_libevent, 0x02,
        :IO_winsock, 0x03,
        :IO_libev, 0x04,
        :IO_select, 0x05,
        :IO_winIOCP, 0x06,
        :IO_libuv, 0x07
    ]

    class IOOptions < FFI::Struct
        layout :version, :int,      # Always 0
               :type,    IOType,    # Always IO_winIOCP
               :cookie,  :pointer
    end

    # pointer param returns IO opts structure
    attach_function :create_io_ops, :lcb_create_io_ops, [:pointer, IOOptions.by_ref], ErrorT
end
