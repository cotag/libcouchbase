# frozen_string_literal: true, encoding: ASCII-8BIT

module Libcouchbase
    class N1QL
        Ordering = [
            :build_index, :create_index, :drop_index, :create_primary_index,
            :drop_primary_index, :grant, :on, :to, :infer, :select, :insert_into,
            :delete_from, :update, :from, :with, :use_keys, :unnest, :join, :where,
            :group_by, :order_by, :limit, :offset, :upsert_into, :merge_into
        ]

        def initialize(bucket, explain: false, **options)
            @bucket = bucket
            @connection = bucket.connection
            @explain = !!explain
            options.each do |key, value|
                if self.respond_to? key
                    self.public_send key, value
                end
            end
        end

        attr_accessor *Ordering
        attr_accessor :explain
        attr_reader   :bucket, :connection
        attr_accessor :string

        def query(val = nil)
            return @string if val.nil?

            @string = val.to_s
            self
        end

        def explain(val = nil)
            return @explain if val.nil?
            @explain = !!val
            self
        end

        Ordering.each do |helper|
            define_method helper do |*args|
                return instance_variable_get :"@#{helper}" if args.empty?
                if args.length == 1
                    instance_variable_set :"@#{helper}", args[0]
                else
                    instance_variable_set :"@#{helper}", args
                end
                self
            end
        end

        def to_s
            res = String.new
            res << "EXPLAIN\n" if @explain
            return (res << @string) if @string

            Ordering.each do |statement|
                val = public_send statement
                unless val.nil?
                    res << "#{statement.to_s.gsub('_', ' ').upcase} "

                    if val.is_a? Array
                        res << val.collect { |obj| obj.to_s }.join(', ')
                    else
                        res << val.to_s
                    end

                    res << "\n"
                end
            end
            res
        end

        def results(&row_modifier)
            n1ql_view = @connection.n1ql_query(self)

            current = ::Libuv::Reactor.current
            if current && current.running?
                ResultsLibuv.new(n1ql_view, current, &row_modifier)
            elsif Object.const_defined?(:EventMachine) && EM.reactor_thread?
                ResultsEM.new(n1ql_view, &row_modifier)
            else
                ResultsNative.new(n1ql_view, &row_modifier)
            end
        end
    end
end
