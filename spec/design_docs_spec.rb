# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::DesignDocs do
    before :each do
        @ddoc = Libcouchbase::Bucket.new.design_docs
    end

    it "should list the available designs" do
        designs = @ddoc.designs
        expect(designs.count).to eq(23)
    end

    it "should list the available views" do
        views = @ddoc.design("user").views
        expect(views).to eq([:is_sys_admin])

        views = @ddoc[:user].views
        expect(views).to eq([:is_sys_admin])
    end
end
