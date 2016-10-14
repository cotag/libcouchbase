require 'set'


module Libcouchbase
    class LibuvResults
        include Enumerable

        def initialize(query)
            @loaded = false
            @performed = false

            @results = []
            @fiber = nil

            # This could be a view or n1ql query
            @query = query
        end

        attr_reader :loaded, :performed

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
                            Fiber.yield
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
                Fiber.yield
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
                        Fiber.yield
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
                            Fiber.yield
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


        def load_all
            return @results if @loaded
            perform

            @fiber = Fiber.current
            while !@loaded do; Fiber.yield; end
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
            @query.perform { |final, item|
                if final
                    @loaded = true
                else
                    @results << item
                end

                @fiber.resume if @fiber
            }
        end
    end
end
