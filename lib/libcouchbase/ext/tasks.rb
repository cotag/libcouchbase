# frozen_string_literal: true, encoding: ASCII-8BIT

require 'fileutils'
require 'libuv'

module FFI::Platform
    def self.ia32?
        ARCH == "i386"
    end

    def self.x64?
        ARCH == "x86_64"
    end
end

# Ensure the submodule is cloned
file 'ext/libcouchbase/include' do
    system 'git', 'submodule', 'update', '--init'
end

file 'ext/libcouchbase/build' => 'ext/libcouchbase/include' do
    FileUtils.mkdir('ext/libcouchbase/build')
end

file 'ext/libcouchbase/build/makefile' => 'ext/libcouchbase/build' do
    result = nil
    Dir.chdir("ext/libcouchbase") do |path|
        result = system './cmake/configure', '-with-libuv', ::File.expand_path('../../', ::Libuv::Ext.path_to_internal_libuv)
    end
    raise 'could not find cmake on path' unless result
end

file "ext/libcouchbase/build/lib/libcouchbase_libuv.#{FFI::Platform::LIBSUFFIX}" => 'ext/libcouchbase/build/makefile' do
    result = nil
    Dir.chdir('ext/libcouchbase/build') do |path|
        result = system 'make'
    end
    raise 'make failed' unless result
end
