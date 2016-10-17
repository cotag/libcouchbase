# frozen_string_literal: true, encoding: ASCII-8BIT

module Libcouchbase
    module Error
        class UnknownError < ::StandardError; end
        Lookup = {}

        # Borrowed from:
        # https://github.com/rails/rails/blob/f2489f493b794ee83a86e746b6240031acb8994e/activesupport/lib/active_support/inflector/methods.rb#L66
        def self.camelize(term, uppercase_first_letter = true)
            string = term.to_s
            if uppercase_first_letter
                string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
            else
                string = string.sub(/^(?:#{inflections.acronym_regex}(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
            end
            string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
            string.gsub!('/', '::')
            string
        end

        # Dynamically define the error classes
        Ext::ErrorT.symbols.map { |val| [val, camelize(val.to_s)] }.each do |enum, name|
            klass = Class.new(::StandardError)
            Libcouchbase::Error.send(:const_set, name, klass)
            Lookup[enum] = klass
        end

        # Re-assign the ones that makes sense
        Lookup[:not_stored] = KeyEnoent

        # Provide a helper
        def self.lookup(key)
            look = key.is_a?(Numeric) ? Ext::ErrorT[key] : key.to_sym
            Lookup[look] || UnknownError
        end
    end
end
