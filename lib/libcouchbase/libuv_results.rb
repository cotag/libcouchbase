require 'set'


module Libcouchbase
    class LibuvResults
        include Enumerable

        def initialize(query)
            @loaded = false
            @performed = false

            @results = []
            @fibers = Set.new

            # This could be a view or n1ql query
            @query = query
        end

        def each(&blk)
            # return a valid enumerator
            return load_all.each unless block_given?

            if @loaded
                @results.each &blk
            else
                perform unless @performed

                index = 0
                fib = Fiber.current
                @fibers << fib

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
                    @fibers.delete fib
                end
            end
            self
        end

        def first
            if @results.length > 0
                @results[0]
            else
                perform unless @performed

                fib = Fiber.current
                @fibers << fib

                Fiber.yield
                @fibers.delete fib

                result = @results[0]
                cancel
                result
            end
        end

        def take(num)
            if @results.length >= num
                @results[0...num]
            else
                perform unless @performed

                index = 0
                fib = Fiber.current
                @fibers << fib

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
                @fibers.delete fib

                cancel
                result
            end
        end

        def take_while(&blk)
            return load_all.take_while unless block_given?

            if @loaded
                @results.take_while(&blk)
            else
                perform unless @performed

                index = 0
                fib = Fiber.current
                @fibers << fib
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
                    @fibers.delete fib
                    cancel
                end
                result
            end
        end


        protected


        def load_all
            return @results if @loaded
            perform unless @performed
            
            fib = Fiber.current
            @fibers << fib
            while !@loaded do; Fiber.yield; end
            @fibers.delete fib
            @results
        end

        def cancel
            return if !@fibers.empty? || @loaded
            @query.cancel
            @performed = false
        end

        def perform
            @performed = true

            @query.perform { |final, item|
                if final
                    @loaded = true
                else
                    @results << item
                end

                @fibers.each { |f| f.resume }
            }
        end
    end
end
