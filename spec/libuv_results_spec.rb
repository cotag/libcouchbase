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

    def perform(&blk)
        @curr = 0
        @callback = blk
        @cancel = false

        preloaded.times { |i| blk.call(false, i) }
        next_item(preloaded)
    end

    def next_item(i = 0)
        if i == @count
            @callback.call(true, {count: @count})
        else
            reactor.scheduler.in(rand(50..100)) do
                @log << :new_row
                @callback.call(false, i)
                next_item(i + 1) unless @cancel
            end
        end
    end

    def cancel
        @cancel = true
    end
end


describe Libcouchbase::LibuvResults do
    before :each do
        @log = []
        @query = MockQuery.new(@log)
        @view = Libcouchbase::LibuvResults.new(@query)
        expect(@log).to eq([])
    end

    it "should stream the response" do
        reactor.run { |reactor|
            @view.each {|i| @log << i}
        }

        expect(@log).to eq([:new_row, 0, :new_row, 1, :new_row, 2, :new_row, 3])
    end

    it "should stream the response even if some has already been loaded" do
        reactor.run { |reactor|
            @query.preloaded = 2
            @view.each {|i| @log << i }
        }

        expect(@log).to eq([0, 1, :new_row, 2, :new_row, 3])
    end

    it "should only load what is required" do
        reactor.run { |reactor|
            @log << @view.take(2)
            @log << @view.first
        }

        expect(@log).to eq([:new_row, :new_row, [0, 1], 0])
    end
end
