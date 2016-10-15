require 'set'


module Libcouchbase
    class ResultsLibuv
        include Enumerable

        def initialize(query, &row_modifier)
            @query_in_progress = false
            @query_completed = false
            @complete_result_set = false

            @results = []
            @fiber = nil

            # This could be a view or n1ql query
            @query = query
            @row_modifier = row_modifier
            @reactor = reactor
        end

        def options(**opts)
            reset
            @query.options.merge!(opts)
        end

        attr_reader :complete_result_set, :query_in_progress
        attr_reader :query_completed, :metadata

        def stream(&blk)
            if @complete_result_set
                @results.each &blk
            else
                perform is_complete: false
                @fiber = Fiber.current

                begin
                    while not @query_completed do
                        if @results.length > 0
                            yield @results.shift
                        else
                            resume
                        end
                    end
                ensure
                    @fiber = nil
                    reset
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

                index = 0
                @fiber = Fiber.current

                begin
                    while not @query_completed do
                        if index < @results.length
                            yield @results[index]
                            index += 1
                        else
                            resume
                        end
                    end
                ensure
                    @fiber = nil
                end
            end
            self
        end

        def first
            if @complete_result_set || @results.length > 0
                @results[0]
            else
                perform is_complete: false, limit: 1

                @fiber = Fiber.current
                while not @query_completed do
                    resume
                end
                @fiber = nil

                result = @results[0]
                result
            end
        end

        def count
            first
            @metadata[:total_rows]
        end

        def take(num)
            if @complete_result_set || @results.length >= num
                @results[0...num]
            else
                perform is_complete: false, limit: num

                index = 0
                @fiber = Fiber.current

                result = []
                while not @query_completed do
                    if index < @results.length && index < num
                        result << @results[index]
                        index += 1
                    else
                        resume
                    end
                end
                @fiber = nil

                result
            end
        end


        protected


        def resume
            raise @error if @error
            @reactor = reactor
            Fiber.yield
            raise @error if @error
        end

        def load_all
            return @results if @complete_result_set
            perform

            @fiber = Fiber.current
            while not @query_completed do; resume; end
            @fiber = nil
            @results
        end

        def perform(is_complete: true, **opts)
            return if @query_in_progress
            @query_in_progress = true
            @query_completed = false
            @results.clear

            # This performs the query against the server
            @query.perform(**opts) { |final, item|
                @reactor.schedule {
                    # Has the operation completed?
                    if final
                        if final == :error
                            @error = item
                        else
                            @metadata = item
                            @complete_result_set = is_complete
                        end
                        @query_completed = true
                        @query_in_progress = false

                    # Do we want to transform the results
                    elsif @row_modifier
                        begin
                            @results << @row_modifier.call(item)
                        rescue => e
                            @error = e
                            reset
                        end
                    else
                        @results << item
                    end

                    # Resume processing
                    @fiber.resume if @fiber
                }
            }
        end
    end
end
