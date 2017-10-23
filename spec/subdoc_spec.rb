# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::SubdocRequest do
    before :each do
        # This will load the couchbase connection on a different thread
        @bucket = Libcouchbase::Bucket.new
        @reactor = ::Libuv::Reactor.default
        @log = []
    end

    after :each do
        @bucket = nil
        @reactor = nil
        @log = nil
    end

    describe 'reactor loop' do
        it "should get a subkey" do
            @reactor.run { |reactor|
                @bucket.set('subkeytest', {
                    bob: 1234,
                    hello: 'this value',
                    another: false
                })
                @log = @bucket.subdoc(:subkeytest) do |subdoc|
                    subdoc.get(:hello).exists?('bob')
                end
            }

            expect(@log).to eq(['this value', true])
        end
    end

    describe 'native ruby' do
        it "should get a subkey" do
            @bucket.set('subkeytest', {
                bob: 1234,
                hello: 'this value',
                another: false
            })
            @log = @bucket.subdoc(:subkeytest) do |subdoc|
                subdoc.get(:hello).exists?('bob')
            end

            expect(@log).to eq(['this value', true])
        end
    end

    describe 'eventmachine loop' do
        require 'em-synchrony'

        it "should get a subkey" do
            EM.synchrony {
                @bucket.set('subkeytest', {
                    bob: 1234,
                    hello: 'this value',
                    another: false
                })
                @log = @bucket.subdoc(:subkeytest) do |subdoc|
                    subdoc.get(:hello).exists?('bob')
                end
                EM.stop
            }

            expect(@log).to eq(['this value', true])
        end
    end
end
