require 'fileutils'

# Ensure the submodule is cloned
file 'ext/libcouchbase/include' do
    system "git", "submodule", "update", "--init"
end


if FFI::Platform.windows?
    
else # UNIX
    file 'ext/libcouchbase/build' => 'ext/libcouchbase/include' do
        FileUtils.mkdir('ext/libcouchbase/build')
    end

    file 'ext/libcouchbase/build/makefile' => 'ext/libcouchbase/build' do
        Dir.chdir("ext/libcouchbase") do |path|
            system "./cmake/configure"
        end
    end

    file "ext/libcouchbase/build/lib/libcouchbase.#{FFI::Platform::LIBSUFFIX}" => 'ext/libcouchbase/build/makefile' do
        Dir.chdir("ext/libcouchbase/build") do |path|
            system "make"
        end
    end
end
