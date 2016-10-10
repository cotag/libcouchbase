require 'fileutils'
require 'libuv'

# Ensure the submodule is cloned
file 'ext/libcouchbase/include' do
    system 'git', 'submodule', 'update', '--init'
end

if FFI::Platform.windows?
    # -----------
    # Win32 BUILD
    # -----------

    arch = FFI::Platform.x64? ? ' Win64' : ''

    file 'ext/libcouchbase/lcb-build' => 'ext/libcouchbase/include' do
        FileUtils.mkdir('ext/libcouchbase/lcb-build')
    end

    file "ext/libcouchbase/build/lib/libcouchbase.#{FFI::Platform::LIBSUFFIX}" => 'ext/libcouchbase/lcb-build' do
        Dir.chdir('ext/libcouchbase/lcb-build') do |path|
            system 'cmake', '-with-libuv', ::File.expand_path('../../', ::Libuv::Ext.path_to_internal_libuv), '-G', "Visual Studio 10#{arch}", '..\libcouchbase'
            system 'cmake', '--build', '.'
        end
    end

else
    # -----------
    # UNIX  BUILD
    # -----------

    file 'ext/libcouchbase/build' => 'ext/libcouchbase/include' do
        FileUtils.mkdir('ext/libcouchbase/build')
    end

    file 'ext/libcouchbase/build/makefile' => 'ext/libcouchbase/build' do
        Dir.chdir("ext/libcouchbase") do |path|
            system './cmake/configure', '-with-libuv', ::File.expand_path('../../', ::Libuv::Ext.path_to_internal_libuv)
        end
    end

    file "ext/libcouchbase/build/lib/libcouchbase.#{FFI::Platform::LIBSUFFIX}" => 'ext/libcouchbase/build/makefile' do
        Dir.chdir('ext/libcouchbase/build') do |path|
            system 'make'
        end
    end
end
