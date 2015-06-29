require 'fileutils'

# Ensure the submodule is cloned
file 'ext/libcouchbase/include' do
    system 'git', 'submodule', 'update', '--init'
end


# Check for libuv
libuv = begin
    require 'libuv'
    ::Libuv::Ext.path_to_internal_libuv
    true
rescue LoadError, StandardError
    false
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
            if libuv
                system 'cmake', '-with-libuv', ::File.expand_path('../../', ::Libuv::Ext.path_to_internal_libuv), '-G', "Visual Studio 10#{arch}", '..\libcouchbase'
            else
                system 'cmake', '-G', "Visual Studio 10#{arch}", '..\libcouchbase'
            end

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
            if libuv
                libuv_path = ::File.expand_path('../../', ::Libuv::Ext.path_to_internal_libuv)
                system './cmake/configure', '-with-libuv', libuv_path
            else
                system './cmake/configure'
            end
        end
    end

    file "ext/libcouchbase/build/lib/libcouchbase.#{FFI::Platform::LIBSUFFIX}" => 'ext/libcouchbase/build/makefile' do
        Dir.chdir('ext/libcouchbase/build') do |path|
            system 'make'
        end
    end
end
