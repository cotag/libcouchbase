# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase/ext/libcouchbase_libuv'
require 'libcouchbase/error'
require 'libcouchbase/callbacks'
require 'libcouchbase/connection'

module Libcouchbase
    autoload :Bucket,        'libcouchbase/bucket'
    autoload :QueryView,     'libcouchbase/query_view'
    autoload :DesignDoc,     'libcouchbase/design_docs'
    autoload :DesignDocs,    'libcouchbase/design_docs'
    autoload :ResultsLibuv,  'libcouchbase/results_libuv'
    autoload :ResultsNative, 'libcouchbase/results_native'
end
