# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'
require 'uv-rays'


class NativeMockQuery
    def initialize(log, thread = nil, preloaded = 0)
        @count = 4
        @preloaded = preloaded
        @log = log
        @thread = thread
    end

    attr_accessor :preloaded

    def perform(limit: @count, **options, &blk)
        @wait = Thread.new do
            @thread.run {
                @curr = 0
                @callback = blk
                @limit = limit
                
                cancel

                preloaded.times { |i| blk.call(false, i) }
                next_item(preloaded)
            }
        end
    end

    def wait_join
        @wait.join
    end

    def next_item(i = 0)
        if i == @limit
            @sched = @thread.scheduler.in(50) do
                @callback.call(true, {total_rows: @count})
            end
        else
            @sched = @thread.scheduler.in(100) do
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


describe Libcouchbase::ResultsNative do
    before :each do
        reactor = ::Libuv::Reactor.default
        @qlog = []
        @query = NativeMockQuery.new(@qlog, reactor)
        @log = []
        @view = Libcouchbase::ResultsNative.new(@query)
        expect(@log).to eq([])
    end

    it "should stream the response" do
        @view.each {|i| @log << i }

        @query.wait_join

        expect(@view.complete_result_set).to be(true)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@qlog).to eq([:new_row, :new_row, :new_row, :new_row])
        expect(@log).to eq([0, 1, 2, 3])
    end

    it "should continue to stream the response even if some has already been loaded" do
        @query.preloaded = 2
        @view.each {|i| @log << i }

        @query.wait_join

        expect(@view.complete_result_set).to be(true)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@qlog).to eq([:new_row, :new_row])
        expect(@log).to eq([0, 1, 2, 3])
    end

    it "should only load what is required" do
        @log << @view.take(2)
        expect(@view.complete_result_set).to be(false)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)

        @log << @view.first
        expect(@view.complete_result_set).to be(false)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)

        # Wait join here as the default loop will
        # be started again on a new thread
        # without this wait we might end up in a deadlock...
        # Don't worry, the test is sound - seriously
        @query.wait_join

        @log << @view.to_a
        expect(@view.complete_result_set).to be(true)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)

        @query.wait_join
        
        expect(@qlog).to eq([:new_row, :new_row, :new_row, :new_row, :new_row, :new_row])
        expect(@log).to eq([[0, 1], 0, [0, 1, 2, 3]])
    end

    it "should load only once" do
        @log << @view.to_a
        @log << @view.to_a

        @query.wait_join
        expect(@qlog).to eq([:new_row, :new_row, :new_row, :new_row])
        expect(@log).to eq([[0, 1, 2, 3], [0, 1, 2, 3]])
    end

    it "should work as an enumerable" do
        enum = @view.each
        @log << enum.next
        @log << enum.next

        @query.wait_join

        expect(@qlog).to eq([:new_row, :new_row, :new_row, :new_row])
        expect(@log).to eq([0, 1])
    end

    it "should return count" do
        @log << @view.count
        @log << @view.count

        @query.wait_join

        expect(@qlog).to eq([:new_row])
        expect(@log).to eq([4, 4])
    end

    it "should support streaming the response so results are not all stored in memory" do
        @view.stream {|i| @log << i }

        @query.wait_join

        expect(@view.complete_result_set).to be(false)
        expect(@view.query_in_progress).to be(false)
        expect(@view.query_completed).to be(true)
        expect(@qlog).to eq([:new_row, :new_row, :new_row, :new_row])
        expect(@log).to eq([0, 1, 2, 3])
    end
end
