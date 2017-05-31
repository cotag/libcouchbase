# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'
require 'uv-rays'


class MockQuery
    def initialize(log, preloaded = 0)
        @count = 4
        @preloaded = preloaded
        @log = log
    end

    attr_accessor :preloaded

    def get_count(metadata)
        metadata[:total_rows]
    end

    def perform(limit: @count, **options, &blk)
        @curr = 0
        @callback = blk
        @limit = limit
        
        if @sched
            @sched.cancel
            @sched = nil
        end
        @error = nil

        preloaded.times { |i| blk.call(false, i) }
        next_item(preloaded)
    end

    def next_item(i = 0)
        if i == @limit
            @sched = reactor.scheduler.in(50) do
                @callback.call(:final, {total_rows: @count})
            end
        else
            @sched = reactor.scheduler.in(100) do
                @log << :new_row
                next_item(i + 1)
                @callback.call(false, i)
            end
        end
    end

    def cancel
        return if @error
        if @sched
            @sched.cancel
            @sched = nil
        end
        @error = :cancelled
        @sched = reactor.scheduler.in(50) do
            @callback.call(:final, {total_rows: @count})
        end
    end
end


describe Libcouchbase::ResultsLibuv do
    before :each do
        @log = []
        @reactor = ::Libuv::Reactor.default
        @reactor.notifier do |err|
            @reactor.stop
            @log << err
        end
        @timeout = @reactor.timer do
            @timeout.close
            @reactor.stop
            @log << "test timed out"
        end
        @timeout.start(5000)
        @timeout.unref
        @query = MockQuery.new(@log)
        @view = Libcouchbase::ResultsLibuv.new(@query)
        expect(@log).to eq([])
    end

    after :each do
        @timeout.close
    end

    it "should stream the response" do
        @reactor.run { |reactor|
            @view.each {|i| @log << i }
        }

        expect(@log).to eq([:new_row, 0, :new_row, 1, :new_row, 2, :new_row, 3])
        expect(@view.complete_result_set).to be(true)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
    end

    it "should continue to stream the response even if some has already been loaded" do
        @reactor.run { |reactor|
            @query.preloaded = 2
            @view.each {|i| @log << i }
        }

        expect(@view.complete_result_set).to be(true)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@log).to eq([0, 1, :new_row, 2, :new_row, 3])
    end

    it "should only load what is required" do
        @reactor.run { |reactor|
            @log << @view.take(2)
            @log << @view.first
            expect(@view.complete_result_set).to be(false)
            expect(@view.query_in_progress).to be(false)
            expect(@view.query_completed).to be(true)
            @log << @view.to_a
        }

        expect(@view.complete_result_set).to be(true)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@log).to eq([:new_row, :new_row, [0, 1], 0, :new_row, :new_row, :new_row, :new_row, [0, 1, 2, 3]])
    end

    it "should load only once" do
        @reactor.run { |reactor|
            @log << @view.to_a
            @log << @view.to_a
        }

        expect(@log).to eq([:new_row, :new_row, :new_row, :new_row, [0, 1, 2, 3], [0, 1, 2, 3]])
    end

    it "should work as an enumerable" do
        @reactor.run { |reactor|
            enum = @view.each
            @log << enum.next
            @log << enum.next
        }

        expect(@log).to eq([:new_row, :new_row, :new_row, :new_row, 0, 1])
    end

    it "should return count" do
        @reactor.run { |reactor|
            @log << @view.count
            @log << @view.count
        }

        expect(@log).to eq([:new_row, 4, 4])
    end

    it "should handle exceptions" do
        @reactor.run { |reactor|
            begin
                @view.each {|i|
                    @log << i
                    raise 'what what'
                }
            rescue => e
                @log << e.message
            end
        }

        expect(@log).to eq([:new_row, 0, 'what what'])
    end

    it "should handle row modifier exceptions" do
        count = 0

        @view = Libcouchbase::ResultsLibuv.new(@query) { |view|
            if count == 1
                raise 'what what'
            end
            count += 1
            view
        }

        @reactor.run { |reactor|
            begin
                @view.each {|i| @log << i }
            rescue => e
                @log << e.message
            end
        }

        expect(@log).to eq([:new_row, 0, :new_row, 'what what'])
    end

    it "should handle row modifier exceptions on a short query" do
        count = 0

        @view = Libcouchbase::ResultsLibuv.new(@query) { |view|
            raise 'what what'
        }

        @reactor.run { |reactor|
            begin
                @view.first
            rescue => e
                @log << e.message
            end
        }

        expect(@log).to eq([:new_row, 'what what'])
    end

    it "should handle multiple exceptions" do
        count = 0

        @view = Libcouchbase::ResultsLibuv.new(@query) { |view|
            if count == 1
                raise 'second'
            end
            count += 1
            view
        }

        @reactor.run { |reactor|
            begin
                @view.each {|i|
                    @log << i
                    raise 'first'
                }
            rescue => e
                @log << e.message
            end
        }

        expect(@log).to eq([:new_row, 0, 'first'])
    end

    it "should support streaming the response so results are not all stored in memory" do
        @reactor.run { |reactor|
            @view.stream {|i| @log << i }
        }

        expect(@view.complete_result_set).to be(false)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@log).to eq([:new_row, 0, :new_row, 1, :new_row, 2, :new_row, 3])
    end
end
