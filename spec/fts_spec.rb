# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::QueryFullText, full_text_search: true do
    before :each do
        # This will load the couchbase connection on a different thread
        @bucket = Libcouchbase::Bucket.new
        @reactor = ::Libuv::Reactor.default
        @log = []
    end

    describe 'perform native queries' do
        it "should iterate a full text search with results" do
            results = @bucket.full_text_search(:default, 'Toshiba')
            @log << results.to_a.count
            @log << results.count
            @log << results.collect { |res| res.value.nil? }
            expect(@log).to eq([4, 4, [false, false, false, false]])
        end

        it "should iterate a full text search without results" do
            results = @bucket.full_text_search(:default, 'Toshiba', include_docs: false)
            @log << results.to_a.count
            @log << results.count
            @log << results.collect { |res| res.value.nil? }
            expect(@log).to eq([4, 4, [true, true, true, true]])
        end

        it "should cancel a full text search when an error occurs" do
            results = @bucket.full_text_search(:default, 'Toshiba')
            begin
                count = 0
                results.collect { |res|
                    raise 'err' if count > 0
                    @log << res.value.nil?
                    count += 1
                }
            rescue => e
                @log << :error
            end
            expect(@log).to eq([false, :error])
        end
    end

    describe 'perform queries in libuv reactor' do
        it "should iterate a full text search with results" do
            @reactor.run { |reactor|
                results = @bucket.full_text_search(:default, 'Toshiba')
                @log << results.to_a.count
                @log << results.count
                @log << results.collect { |res| res.value.nil? }
            }
            expect(@log).to eq([4, 4, [false, false, false, false]])
        end

        it "should iterate a full text search without results" do
            @reactor.run { |reactor|
                results = @bucket.full_text_search(:default, 'Toshiba', include_docs: false)
                @log << results.to_a.count
                @log << results.count
                @log << results.collect { |res| res.value.nil? }
            }
            expect(@log).to eq([4, 4, [true, true, true, true]])
        end

        it "should cancel a full text search when an error occurs" do
            @reactor.run { |reactor|
                results = @bucket.full_text_search(:default, 'Toshiba')
                begin
                    count = 0
                    results.collect { |res|
                        raise 'err' if count > 0
                        @log << res.value.nil?
                        count += 1
                    }
                rescue => e
                    @log << :error
                end
            }
            expect(@log).to eq([false, :error])
        end
    end

    describe 'perform queries in event machine' do
        require 'em-synchrony'
        
        it "should iterate a full text search with results" do
            EM.synchrony {
                results = @bucket.full_text_search(:default, 'Toshiba')
                @log << results.to_a.count
                @log << results.count
                @log << results.collect { |res| res.value.nil? }
                EM.stop
            }
            expect(@log).to eq([4, 4, [false, false, false, false]])
        end

        it "should iterate a full text search without results" do
            EM.synchrony {
                results = @bucket.full_text_search(:default, 'Toshiba', include_docs: false)
                @log << results.to_a.count
                @log << results.count
                @log << results.collect { |res| res.value.nil? }
                EM.stop
            }
            expect(@log).to eq([4, 4, [true, true, true, true]])
        end

        it "should cancel a full text search when an error occurs" do
            EM.synchrony {
                results = @bucket.full_text_search(:default, 'Toshiba')
                begin
                    count = 0
                    results.collect { |res|
                        raise 'err' if count > 0
                        @log << res.value.nil?
                        count += 1
                    }
                rescue => e
                    @log << :error
                end
                EM.stop
            }
            expect(@log).to eq([false, :error])
        end
    end
end
