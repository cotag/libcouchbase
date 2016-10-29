# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::N1QL do
    before :each do
        @n1ql = Libcouchbase::Bucket.new.n1ql
    end

    it "should build a basic query" do
        @n1ql.select('*').from(:default).where('port == 10001')
        expect(@n1ql.to_s).to eq("SELECT *\nFROM default\nWHERE port == 10001\n")
    end
end
