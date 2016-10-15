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

    def perform(limit: @count, **options, &blk)
        @curr = 0
        @callback = blk
        @limit = limit
        
        cancel

        preloaded.times { |i| blk.call(false, i) }
        next_item(preloaded)
    end

    def next_item(i = 0)
        if i == @limit
            @sched = reactor.scheduler.in(50) do
                @callback.call(true, {count: @count})
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
        if @sched
            @sched.cancel
            @sched = nil
        end
    end
end


describe Libcouchbase::ResultsLibuv do
    before :each do
        @log = []
        @query = MockQuery.new(@log)
        @view = Libcouchbase::ResultsLibuv.new(@query)
        expect(@log).to eq([])
    end

    it "should stream the response" do
        reactor.run { |reactor|
            @view.each {|i| @log << i }
        }

        expect(@view.complete_result_set).to be(true)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@log).to eq([:new_row, 0, :new_row, 1, :new_row, 2, :new_row, 3])
    end

    it "should continue to stream the response even if some has already been loaded" do
        reactor.run { |reactor|
            @query.preloaded = 2
            @view.each {|i| @log << i }
        }

        expect(@view.complete_result_set).to be(true)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@log).to eq([0, 1, :new_row, 2, :new_row, 3])
    end

    it "should only load what is required" do
        reactor.run { |reactor|
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
        reactor.run { |reactor|
            @log << @view.to_a
            @log << @view.to_a
        }

        expect(@log).to eq([:new_row, :new_row, :new_row, :new_row, [0, 1, 2, 3], [0, 1, 2, 3]])
    end

    it "should work as an enumerable" do
        reactor.run { |reactor|
            enum = @view.each
            @log << enum.next
            @log << enum.next
        }

        expect(@log).to eq([:new_row, :new_row, :new_row, :new_row, 0, 1])
    end

    it "should return count" do
        reactor.run { |reactor|
            @log << @view.count
            @log << @view.count
        }

        expect(@log).to eq([:new_row, :new_row, :new_row, :new_row, 4, 4])
    end

    it "should support streaming the response so results are not all stored in memory" do
        reactor.run { |reactor|
            @view.stream {|i| @log << i }
        }

        expect(@view.complete_result_set).to be(false)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@log).to eq([:new_row, 0, :new_row, 1, :new_row, 2, :new_row, 3])
    end
end
