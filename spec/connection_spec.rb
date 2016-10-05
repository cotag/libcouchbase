# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::Connection do
	before :each do
		@log = []
	end
	
	it "should connect and disconnect from the default bucket" do
		expect(@log).to eq([])

        begin
            connection = Libcouchbase::Connection.new do |success|
                @log << success
            end
        rescue => e
            @log << e.message
            @log << e.backtrace
        end

        expect(@log).to eq([true])
	end
end
