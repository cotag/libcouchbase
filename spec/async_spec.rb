require 'libcouchbase'

describe Libcouchbase do
	before :each do
		@log = []
	end
	
	it "should pass" do
		expect(@log).to eq([])
	end
end
