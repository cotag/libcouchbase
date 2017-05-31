require 'rubygems'
require 'rspec/core/rake_task'  # testing framework
require 'yard'                  # yard documentation
require 'ffi'                   # loads the extension
require 'rake/clean'            # for the :clobber rake task
require File.expand_path('../lib/libcouchbase/ext/tasks', __FILE__)    # platform specific rake tasks used by compile



# By default we don't run network tests
task :default => :limited_spec
RSpec::Core::RakeTask.new(:limited_spec) do |t|
    # Exclude full text search tests until we can automate index creation
    t.rspec_opts = "--tag ~full_text_search --tag ~n1ql_query --tag ~design_docs  --fail-fast"
end
RSpec::Core::RakeTask.new(:spec)


desc 'Run all tests'
task :test => [:spec]


YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', '-', 'ext/README.md', 'README.md']
end


desc 'Compile libcouchbase from submodule'
if FFI::Platform.windows?
    task :compile => ["ext/bin/libcouchbase.#{FFI::Platform::LIBSUFFIX}"]
    CLOBBER.include("ext/bin/libcouchbase.#{FFI::Platform::LIBSUFFIX}")
else
    task :compile => ["ext/libcouchbase/build/lib/libcouchbase_libuv.#{FFI::Platform::LIBSUFFIX}"]
    CLOBBER.include("ext/libcouchbase/build/lib/libcouchbase_libuv.#{FFI::Platform::LIBSUFFIX}")
end


# NOTE:: Generated on OSX
desc 'Generate the FFI bindings'
task :generate_bindings do
    require "ffi/gen"

    # NOTE:: you must export the include dir:
    # export CPATH=./ext/libcouchbase/include/
    #
    # Once generated we need to:
    # * adjust the ffi_lib path:
    #   ffi_lib ::File.expand_path("../../../../ext/libcouchbase/build/lib/libcouchbase_libuv.#{FFI::Platform::LIBSUFFIX}", __FILE__)
    # * Rename some structs strings to pointers
    #   create_st3.rb -> connstr, username, passwd
    #   cmdhttp.rb -> body, reqhandle, content_type, username, password, host
    #   cmdfts.rb -> query
    #   respfts.rb -> row
    #   respviewquery.rb -> value, geometry, docid
    #   respn1ql.rb -> row

    FFI::Gen.generate(
        module_name: "Libcouchbase::Ext",
        ffi_lib:     "libcouchbase",
        require_path: "libcouchbase/ext/libcouchbase",
        headers:     [
            "./ext/libcouchbase/include/libcouchbase/couchbase.h",
            "./ext/libcouchbase/include/libcouchbase/error.h",
            "./ext/libcouchbase/include/libcouchbase/views.h",
            "./ext/libcouchbase/include/libcouchbase/subdoc.h",
            "./ext/libcouchbase/include/libcouchbase/n1ql.h",
            "./ext/libcouchbase/include/libcouchbase/cbft.h",
            "./ext/libcouchbase/include/libcouchbase/kvbuf.h"
        ],
        # Searching for stdarg.h
        cflags:      ["-I/System/Library/Frameworks/Kernel.framework/Versions/A/Headers"],
        prefixes:    ["LCB_", "lcb_"],
        output:      "libcouchbase.rb"
    )
end
