# frozen_string_literal: true, encoding: ASCII-8BIT

require 'set'

module Libcouchbase
    class ResultsNative < Results
        def initialize(query, &row_modifier)
            @query_in_progress = false
            @query_completed = false
            @complete_result_set = false

            @results = []

            # This could be a view or n1ql query
            @query = query
            @row_modifier = row_modifier
        end

        def options(**opts)
            reset
            @query.options.merge!(opts)
        end

        def stream(&blk)
            if @complete_result_set
                @results.each &blk
            else
                perform is_complete: false
                begin
                    while !@query_completed || (cont = @results.length > 0) do
                        if cont
                            yield @results.shift
                        else
                            process_next_item
                        end
                    end
                ensure
                    # cancel is executed on break or error
                    cancel unless @query_completed
                end
            end
            self
        end

        def reset
            raise 'query in progress' if @query_in_progress
            @query_in_progress = false
            @complete_result_set = false
            @results.clear
        end

        def each(&blk)
            # return a valid enumerator
            return load_all.each unless block_given?

            if @complete_result_set
                @results.each &blk
            else
                perform

                begin
                    index = 0
                    while !@query_completed || (cont = index < @results.length) do
                        if cont
                            yield @results[index]
                            index += 1
                        else
                            process_next_item
                        end
                    end
                ensure
                    # cancel is executed on break or error
                    cancel unless @query_completed
                end
            end
            self
        end

        def first
            if @complete_result_set || @results.length > 0
                @results[0]
            else
                perform is_complete: false, limit: 1

                while not @query_completed do
                    process_next_item
                end

                result = @results[0]
                result
            end
        end

        def count
            first unless @metadata
            @metadata[:total_rows]
        end

        def take(num)
            if @complete_result_set || @results.length >= num
                @results[0...num]
            else
                perform is_complete: false, limit: num

                index = 0
                result = []
                while !@query_completed || (cont = index < @results.length && index < num) do
                    if cont
                        result << @results[index]
                        index += 1
                    else
                        process_next_item
                    end
                end

                result
            end
        end

        def cancel
            return if @cancelled
            @cancelled = true
            @query.cancel
            process_next_item
        end


        protected


        def process_next_item(can_loop = true)
            return if @query_completed
            final, item = @queue.pop
            
            if final
                if final == :error
                    error = item
                else
                    @metadata = item
                    @complete_result_set = @is_complete
                end
                @query_completed = true
                @query_in_progress = false
                raise error if error && !@cancelled

            elsif not @cancelled
                 # Do we want to transform the results
                if @row_modifier
                    @results << @row_modifier.call(item)
                else
                    @results << item
                end
            end

            # This prevents the stack from blowing out
            if can_loop
                while !@queue.empty? || (@cancelled && !final) do
                    final = process_next_item(false)
                end
            end
            final
        rescue Exception
            cancel
            raise
        end

        def load_all
            return @results if @complete_result_set
            perform

            while not @query_completed do
                process_next_item
            end

            @results
        end

        def perform(is_complete: true, **opts)
            return if @query_in_progress
            @query_in_progress = true
            @query_completed = false
            @is_complete = is_complete
            @cancelled = false

            # This flag is required so we don't 
            @results.clear
            @queue = Queue.new

            # This performs the query against the server
            # The callback will always be on another thread
            @query.perform(**opts) { |final, item|
                @queue.push([final, item])
            }
        end
    end
end
