# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::Error do
    it "define the error classes" do
        expect(Libcouchbase::Error::MapChanged.new.is_a? StandardError).to be(true)
    end

    it "should be able to look up errors" do
        expect(Libcouchbase::Error::Lookup[:empty_key]).to   be(Libcouchbase::Error::EmptyKey)
        expect(Libcouchbase::Error.lookup(:empty_key)).to    be(Libcouchbase::Error::EmptyKey)
        expect(Libcouchbase::Error.lookup(:whatwhat_key)).to be(Libcouchbase::Error::UnknownError)
        expect(Libcouchbase::Error.lookup(2)).to             be(Libcouchbase::Error::AuthError)
        expect(Libcouchbase::Error.lookup(-2)).to            be(Libcouchbase::Error::UnknownError)
    end
end
