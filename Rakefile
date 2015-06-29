require 'rubygems'
require 'rspec/core/rake_task'  # testing framework
require 'yard'                  # yard documentation
require 'ffi'                   # loads the extension
require 'rake/clean'            # for the :clobber rake task
require File.expand_path('../lib/libcouchbase/ext/tasks', __FILE__)    # platform specific rake tasks used by compile



# By default we don't run network tests
task :default => :spec
#RSpec::Core::RakeTask.new(:limited_spec) do |t|
    # Exclude network tests
#    t.rspec_opts = "--tag ~network" 
#end
RSpec::Core::RakeTask.new(:spec)


desc "Run all tests"
task :test => [:spec]


YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', '-', 'ext/README.md', 'README.md']
end


desc "Compile libcouchbase from submodule"
task :compile => ["ext/libcouchbase/build/lib/libcouchbase.#{FFI::Platform::LIBSUFFIX}"]

CLOBBER.include("ext/libcouchbase/build/lib/libcouchbase.#{FFI::Platform::LIBSUFFIX}")
