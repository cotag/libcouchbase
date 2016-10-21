# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase/ext/libcouchbase_libuv'
require 'libcouchbase/error'
require 'libcouchbase/callbacks'
require 'libcouchbase/connection'

module Libcouchbase
    class Results
        include Enumerable

        # streams results as they are returned from the database
        #
        # unlike other operations, such as each, the results are not stored
        # for later use and are discarded as soon as possible
        #
        # @yieldparam [Object] value the value of the current row
        def stream; end

        attr_reader :complete_result_set, :query_in_progress
        attr_reader :query_completed, :metadata
    end

    autoload :Bucket,        'libcouchbase/bucket'
    autoload :QueryView,     'libcouchbase/query_view'
    autoload :DesignDoc,     'libcouchbase/design_docs'
    autoload :DesignDocs,    'libcouchbase/design_docs'
    autoload :ResultsLibuv,  'libcouchbase/results_libuv'
    autoload :ResultsNative, 'libcouchbase/results_native'
end
