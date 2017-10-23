# frozen_string_literal: true, encoding: ASCII-8BIT

module Libcouchbase; end;
class Libcouchbase::SubdocRequest

    def initialize(key)
        raise ArgumentError.new("invalid document key #{key.inspect}") unless key.present?
        @key = key.to_s
        @refs = []
        @mode = nil
        @specs = []
        @response = []
    end

    attr_reader :mode, :key, :response

    # Internal use only
    def to_specs_array
        return @mem if @mem # effectively freezes this object
        @mem = FFI::MemoryPointer.new(Ext::SDSPEC, @specs.length, false)
        @specs.each_with_index do |spec, index|
            struct_bytes = spec.get_bytes(0, Ext::SDSPEC.size) # (offset, length)
            @mem[index].put_bytes(0, struct_bytes) # (offset, byte_string)
        end
        @specs = nil
        @mem
    end

    # Internal use only
    def free_memory
        @refs = nil
        @mem = nil
    end


    # =========
    #  Lookups
    # =========

    [ :get, :exists, :get_count ].each do |cmd|
        command = :"sdcmd_#{cmd}"
        define_method cmd do |path, defer: nil, **opts|
            new_spec(defer, path, command, :lookup)
            self
        end
    end


    # ===========
    #  Mutations
    # ===========

    def remove(path, defer: nil, **opts)
        new_spec(defer, path, :sdcmd_remove, :mutate)
        self
    end

    [
        :replace, :dict_add, :dict_upsert, :array_add_first, :array_add_last,
        :array_add_unique, :array_insert, :counter
    ].each do |cmd|
        command = :"sdcmd_#{cmd}"
        define_method cmd do |path, value, defer: nil, create_intermediates: true, **opts|
            spec = new_spec(defer, path, command, :mutate, create_intermediates)
            set_value(spec, value)
            self
        end
    end


    protected


    # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.8.2/group__lcb-subdoc.html#ga53e89dd6b480e81b82fb305d04d92e18
    def new_spec(defer, path, cmd, mode, create_intermediates = false)
        @mode ||= mode
        raise "unable to perform #{cmd} as mode is currently #{@mode}" if @mode != mode

        spec = Ext::SDSPEC.new
        spec[:sdcmd] = Ext::SUBDOCOP[cmd]
        spec[:options] = Ext::SDSPEC::MKINTERMEDIATES if create_intermediates

        loc = path.to_s
        str = ref(loc)
        spec[:path][:type] = :kv_copy
        spec[:path][:contig][:bytes] = str
        spec[:path][:contig][:nbytes] = loc.bytesize

        @response << (defer || @reactor.defer)
        @specs << spec
        spec
    end

    # http://docs.couchbase.com/sdk-api/couchbase-c-client-2.8.2/group__lcb-subdoc.html#ga61009762f6b23ae2a9685ddb888dc406
    def set_value(spec, value)
        # Create a JSON version of the value.
        #  We throw it into an array so strings and numbers etc are valid, then we remove the array.
        val = [value].to_json[1...-1]
        str = ref(val)
        spec[:value][:vtype] = :kv_copy
        spec[:value][:u_buf][:contig][:bytes] = str
        spec[:value][:u_buf][:contig][:nbytes] = val.bytesize
        value
    end

    # We need to hold a reference to c-strings so they are not GC'd
    def ref(string)
        str = FFI::MemoryPointer.from_string(string)
        @refs << str
        str
    end
end
