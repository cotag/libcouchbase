# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::Connection do
	before :each do
		@log = []
	end
	
	it "should connect and disconnect from the default bucket" do
		expect(@log).to eq([])

        reactor.run { |reactor|
            begin
                connection = Libcouchbase::Connection.new do |success, error|
                    @log << error
                    connection.destroy
                end
                connection.connect
            rescue => e
                @log << e.message
                @log << e.backtrace
                connection.destroy
            end
        }

        expect(@log).to eq([:success])
	end
end
