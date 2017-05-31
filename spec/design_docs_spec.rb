# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::DesignDocs, design_docs: true do
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

    it "should provide access to view configuration" do
        config = @ddoc.design("user").view_config
        expect(config.keys).to eq([:is_sys_admin])

        config = @ddoc[:user].view_config
        expect(config.keys).to eq([:is_sys_admin])
    end
end
