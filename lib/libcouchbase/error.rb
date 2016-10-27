# frozen_string_literal: true, encoding: ASCII-8BIT

module Libcouchbase
    class Error < ::StandardError; end

    class Error < ::StandardError
        class UnknownError < ::Libcouchbase::Error; end
        class HttpResponseError < ::Libcouchbase::Error
            attr_accessor :code, :headers, :body
        end
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
        Ignore = ['empty', 'error', 'environment']
        Map = {
            'noent'  => 'not_found',
            'nomem'  => 'no_memory',
            'noconf' => 'no_config',
            '2big'   => 'too_big',
            '2deep'  => 'too_deep',
            'inval'  => 'invalid'
        }
        Ext::ErrorT.symbols.map { |val|
            # Remove the 'e' character from the start of errors and
            # Improve descriptions
            new_val = val.to_s.split('_')
                .map { |val| (val[0] == 'e' && !Ignore.include?(val)) ? val[1..-1] : val }
                .map { |val| Map[val] || val }
                .join('_')

            [val, camelize(new_val).to_sym]
        }.each do |enum, name|
            Lookup[enum] = begin
                # Ensure the constant doesn't exist
                ::Libcouchbase::Error.const_get(name)
            rescue NameError => e 
                # Build the constants
                klass = Class.new(::Libcouchbase::Error)
                ::Libcouchbase::Error.const_set(name, klass)
                klass
            end
        end

        # Re-assign the errors that are equivalent
        Lookup[:not_stored] = KeyNotFound
        Lookup[:error]      = UnknownError

        # Provide a helper
        def self.lookup(key)
            look = key.is_a?(Numeric) ? Ext::ErrorT[key] : key.to_sym
            Lookup[look] || UnknownError
        end
    end
end
