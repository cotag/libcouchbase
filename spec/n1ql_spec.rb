# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'

describe Libcouchbase::N1QL, n1ql_query: true do
    before :each do
        @bucket = Libcouchbase::Bucket.new
        @n1ql = @bucket.n1ql
        @log = []
    end

    after :each do
        @bucket = nil
        @log = nil
    end

    it "should build a basic query" do
        @n1ql.select('*').from(:default).where('port == 10001')
        expect(@n1ql.to_s).to eq("SELECT *\nFROM default\nWHERE port == 10001\n")
    end

    it "should build a basic query from string" do
        @n1ql.string("SELECT *\nFROM default\nWHERE port == 10001\n")
        expect(@n1ql.to_s).to eq("SELECT *\nFROM default\nWHERE port == 10001\n")
    end

    describe 'perform native queries' do
        context "without error syntax query" do
            before :each do
                @n1ql.select('*').from(:default).where('type == "mod"')
            end

            it "should iterate results" do
                results = @n1ql.results
                @log << results.to_a.count
                @log << results.count
                @log << results.collect { |res| res.nil? }
                expect(@log).to eq([12, 12,
                                    [false, false, false, false, false,
                                     false, false, false, false, false,
                                     false, false
                                    ]])
            end

            it "should cancel iteration when an error occurs" do
                results = @n1ql.results
                begin
                    count = 0
                    results.collect do |res|
                        raise 'err' if count > 0

                        @log << res.nil?
                        count += 1
                    end
                rescue => e
                    @log << :error
                end
                @log << results.count
                expect(@log).to eq([false, :error, 12])
            end

            it "should cancel iteration when an error occurs in row modifer" do
                count = 0
                results = @n1ql.results do |row|
                    raise 'err' if count > 0

                    count += 1
                    row
                end

                begin
                    count = 0
                    results.collect do |res|
                        @log << res.nil?
                    end
                rescue => e
                    @log << e.message
                end
                expect(@log).to eq([false, 'err'])
            end
        end
        context "with error syntax query" do
            before :each do
                @n1ql.select('*azdazdazdazdza').from(:default).where('type == "mod"')
            end
            it "should cancel iteration" do
                results = @n1ql.results
                expect { results.to_a }.to(raise_error do |error|
                  expect(error).to be_a(Libcouchbase::Error::HttpError)
                  expect(error.message).not_to be_empty
                end)
            end
        end
    end

    describe 'perform queries in libuv reactor' do
        context "without error syntax query" do
            before :each do
                @n1ql.select('*').from(:default).where('type == "mod"')
                @reactor = ::Libuv::Reactor.default
            end

            it "should iterate results" do
                @reactor.run do |reactor|
                    results = @n1ql.results
                    @log << results.to_a.count
                    @log << results.count
                    @log << results.collect { |res| res.nil? }
                end

                expect(@log).to eq([12, 12,
                                    [false, false, false, false, false,
                                     false, false, false, false, false,
                                     false, false
                                    ]]
                )
            end

            it "should cancel iteration when an error occurs" do
                @reactor.run do |reactor|
                    results = @n1ql.results
                    begin
                        count = 0
                        results.collect do |res|
                            raise 'err' if count > 0

                            @log << res.nil?
                            count += 1
                        end
                    rescue => e
                        @log << :error
                    end
                    @log << results.count
                end
                expect(@log).to eq([false, :error, 12])
            end

            it "should cancel iteration when an error occurs in row modifer" do
                @reactor.run do |reactor|
                    count = 0
                    results = @n1ql.results do |row|
                        raise 'err' if count > 0

                        count += 1
                        row
                    end

                    begin
                        count = 0
                        results.collect do |res|
                            @log << res.nil?
                        end
                    rescue => e
                        @log << e.message
                    end
                end
                expect(@log).to eq([false, 'err'])
            end
        end
        context "with error syntax query" do
            before :each do
                @n1ql.select('*azdzadazdzadza').from(:default).where('type == "mod"')
                @reactor = ::Libuv::Reactor.default
            end
            it "should cancel iteration" do
                results = @n1ql.results
                expect { results.to_a }.to(raise_error do |error|
                    expect(error).to be_a(Libcouchbase::Error::HttpError)
                    expect(error.message).not_to be_empty
                end)
            end
        end
    end

    describe 'perform queries in event machine' do
        require 'em-synchrony'

        context "without error syntax query" do
            before :each do
                @n1ql.select('*').from(:default).where('type == "mod"')
            end

            it "should iterate results" do
                EM.synchrony do
                    results = @n1ql.results
                    @log << results.to_a.count
                    @log << results.count
                    @log << results.collect { |res| res.nil? }

                    EM.stop
                end

                expect(@log).to eq([12, 12,
                                    [false, false, false, false, false,
                                     false, false, false, false, false,
                                     false, false
                                    ]]
                )
            end

            it "should cancel iteration when an error occurs" do
                EM.synchrony do
                    results = @n1ql.results
                    begin
                        count = 0
                        results.collect do |res|
                            raise 'err' if count > 0

                            @log << res.nil?
                            count += 1
                        end
                    rescue => e
                        @log << :error
                    end
                    @log << results.count

                    EM.stop
                end
                expect(@log).to eq([false, :error, 12])
            end

            it "should cancel iteration when an error occurs in row modifer" do
                EM.synchrony do
                    count = 0
                    results = @n1ql.results do |row|
                        raise 'err' if count > 0

                        count += 1
                        row
                    end

                    begin
                        count = 0
                        results.collect do |res|
                            @log << res.nil?
                        end
                    rescue => e
                        @log << e.message
                    end

                    EM.stop
                end
                expect(@log).to eq([false, 'err'])
            end
        end

        context "with error syntax query" do
            before :each do
                @n1ql.select('*azdzadazdzadza').from(:default).where('type == "mod"')
            end
            it "should cancel iteration" do
                results = @n1ql.results
                expect { results.to_a }.to(raise_error do |error|
                    expect(error).to be_a(Libcouchbase::Error::HttpError)
                    expect(error.message).not_to be_empty
                end)
            end
        end
    end
end
