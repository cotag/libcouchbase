require 'set'


module Libcouchbase
    class ResultsLibuv
        include Enumerable

        def initialize(query, &row_modifier)
            @loaded = false
            @performed = false

            @results = []
            @fiber = nil

            # This could be a view or n1ql query
            @query = query
            @row_modifier = row_modifier
            @reactor = reactor
        end

        attr_reader :loaded, :performed, :metadata

        def stream(&blk)
            if @loaded
                @results.each &blk
            else
                perform
                @fiber = Fiber.current

                begin
                    while true do
                        if @results.length > 0
                            yield @results.shift
                        elsif @loaded
                            break
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
            @loaded = false
            @performed = false
            @results.clear
            cancel
        end

        def each(&blk)
            # return a valid enumerator
            return load_all.each unless block_given?

            if @loaded
                @results.each &blk
            else
                perform

                index = 0
                @fiber = Fiber.current

                begin
                    while true do
                        if index < @results.length
                            yield @results[index]
                            index += 1
                        elsif @loaded
                            break
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
            if @results.length > 0
                @results[0]
            else
                perform

                @fiber = Fiber.current
                resume
                @fiber = nil

                result = @results[0]
                cancel
                result
            end
        end

        def take(num)
            if @results.length >= num
                @results[0...num]
            else
                perform

                index = 0
                @fiber = Fiber.current

                result = []
                while index < num do
                    if index < @results.length
                        result << @results[index]
                        index += 1
                    elsif @loaded
                        break
                    else
                        resume
                    end
                end
                @fiber = nil

                cancel
                result
            end
        end

        def take_while(&blk)
            return load_all.take_while unless block_given?

            if @loaded
                @results.take_while(&blk)
            else
                perform

                index = 0
                @fiber = Fiber.current
                result = []

                begin
                    while true do
                        if index < @results.length
                            break unless yield(@results[index])
                            result << @results[index]
                            index += 1
                        elsif @loaded
                            break
                        else
                            resume
                        end
                    end
                ensure
                    @fiber = nil
                    cancel
                end
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
            return @results if @loaded
            perform

            @fiber = Fiber.current
            while !@loaded do; resume; end
            @fiber = nil
            @results
        end

        def cancel
            return if @loaded
            @query.cancel
            @performed = false
        end

        def perform
            return if @performed 
            @performed = true
            @results.clear

            # This performs the query against the server
            @query.perform { |final, item|
                @reactor.schedule {
                    # Don't modify unless we are expecting data
                    if @performed
                        # Has the operation completed?
                        if final
                            if final == :error
                                @error = item
                            else
                                @metadata = item
                                @loaded = true
                            end

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
                    end
                }
            }
        end
    end
end
