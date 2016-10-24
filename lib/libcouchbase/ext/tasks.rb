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

if FFI::Platform.windows?
    require 'net/http'

    # Download a pre-built package
    url = if FFI::Platform.x64?
        "http://packages.couchbase.com/clients/c/libcouchbase-2.6.3_amd64_vc14.zip"
    else
        "http://packages.couchbase.com/clients/c/libcouchbase-2.6.3_x86_vc14.zip"
    end
    zip_file = File.expand_path("../../../../ext/libcouchbase.zip", __FILE__)

    file zip_file do
        print "downloading #{url}"
        uri = URI(url)
        Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new uri

            http.request request do |response|
                open File.expand_path("../../../../ext/libcouchbase.zip", __FILE__), 'wb' do |io|
                    response.read_body do |chunk|
                        io.write chunk
                        print '.'
                    end
                end
            end
        end
    end

    # Extract the files
    file 'ext/tmp' => zip_file do
        begin
            puts "\nextracting files..."
            raise 'error extracting files' unless system(File.expand_path("../../../../ext/win-extract.bat", __FILE__))
        ensure
            # TODO:: remove dir
        end
    end

    # Copy binary files to bin dir
    file "ext/bin/libcouchbase.#{FFI::Platform::LIBSUFFIX}" => 'ext/tmp' do
        Dir.chdir('ext/tmp') do |path|
            dir = File.expand_path("../", Dir["**/libcouchbase.#{FFI::Platform::LIBSUFFIX}"].first)
            FileUtils.mv dir, File.expand_path("../../../../ext/bin", __FILE__)
        end
        FileUtils.rm_rf(File.expand_path("../../../../ext/tmp", __FILE__))
    end
else
    # -----------
    # UNIX  BUILD
    # -----------

    # Ensure the submodule is cloned
    file 'ext/libcouchbase/include' do
        system 'git', 'submodule', 'update', '--init'
    end

    file 'ext/libcouchbase/build' => 'ext/libcouchbase/include' do
        FileUtils.mkdir('ext/libcouchbase/build')
    end

    file 'ext/libcouchbase/build/makefile' => 'ext/libcouchbase/build' do
        Dir.chdir("ext/libcouchbase") do |path|
            system './cmake/configure', '-with-libuv', ::File.expand_path('../../', ::Libuv::Ext.path_to_internal_libuv)
        end
    end

    file "ext/libcouchbase/build/lib/libcouchbase_libuv.#{FFI::Platform::LIBSUFFIX}" => 'ext/libcouchbase/build/makefile' do
        Dir.chdir('ext/libcouchbase/build') do |path|
            system 'make'
        end
    end
end
