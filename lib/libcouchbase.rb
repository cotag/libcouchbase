# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libuv'

module Libcouchbase
    require 'libcouchbase/ext/libcouchbase'
    require 'libcouchbase/error'
    require 'libcouchbase/callbacks'
    require 'libcouchbase/connection'

    class Results
        include Enumerable

        # streams results as they are returned from the database
        #
        # unlike other operations, such as each, the results are not stored
        # for later use and are discarded as soon as possible to save memory
        #
        # @yieldparam [Object] value the value of the current row
        def stream; end

        attr_reader :complete_result_set, :query_in_progress
        attr_reader :query_completed, :metadata
    end

    autoload :N1QL,          'libcouchbase/n1ql'
    autoload :Bucket,        'libcouchbase/bucket'
    autoload :QueryView,     'libcouchbase/query_view'
    autoload :QueryN1QL,     'libcouchbase/query_n1ql'
    autoload :QueryFullText, 'libcouchbase/query_full_text'
    autoload :DesignDoc,     'libcouchbase/design_docs'
    autoload :DesignDocs,    'libcouchbase/design_docs'
    autoload :ResultsLibuv,  'libcouchbase/results_libuv'
    autoload :ResultsNative, 'libcouchbase/results_native'
end
