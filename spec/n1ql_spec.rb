# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::N1QL, n1ql_query: true do
    before :each do
        @bucket = Libcouchbase::Bucket.new
        @n1ql = @bucket.n1ql
        @log = []
    end

    it "should build a basic query" do
        @n1ql.select('*').from(:default).where('port == 10001')
        expect(@n1ql.to_s).to eq("SELECT *\nFROM default\nWHERE port == 10001\n")
    end

    describe 'perform native queries' do
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
                results.collect { |res|
                    raise 'err' if count > 0
                    @log << res.nil?
                    count += 1
                }
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
                results.collect { |res|
                    @log << res.nil?
                }
            rescue => e
                @log << e.message
            end
            expect(@log).to eq([false, 'err'])
        end
    end

    describe 'perform queries in libuv reactor' do
        before :each do
            @n1ql.select('*').from(:default).where('type == "mod"')
            @reactor = ::Libuv::Reactor.default
        end

        it "should iterate results" do
            @reactor.run { |reactor|
                results = @n1ql.results
                @log << results.to_a.count
                @log << results.count
                @log << results.collect { |res| res.nil? }
            }

            expect(@log).to eq([12, 12,
                [false, false, false, false, false,
                 false, false, false, false, false,
                 false, false
                ]]
            )
        end

        it "should cancel iteration when an error occurs" do
            @reactor.run { |reactor|
                results = @n1ql.results
                begin
                    count = 0
                    results.collect { |res|
                        raise 'err' if count > 0
                        @log << res.nil?
                        count += 1
                    }
                rescue => e
                    @log << :error
                end
                @log << results.count
            }
            expect(@log).to eq([false, :error, 12])
        end

        it "should cancel iteration when an error occurs in row modifer" do
            @reactor.run { |reactor|
                count = 0
                results = @n1ql.results do |row|
                    raise 'err' if count > 0
                    count += 1
                    row
                end

                begin
                    count = 0
                    results.collect { |res|
                        @log << res.nil?
                    }
                rescue => e
                    @log << e.message
                end
            }
            expect(@log).to eq([false, 'err'])
        end
    end

    describe 'perform queries in event machine' do
        require 'em-synchrony'

        before :each do
            @n1ql.select('*').from(:default).where('type == "mod"')
        end

        it "should iterate results" do
            EM.synchrony {
                results = @n1ql.results
                @log << results.to_a.count
                @log << results.count
                @log << results.collect { |res| res.nil? }

                EM.stop
            }

            expect(@log).to eq([12, 12,
                [false, false, false, false, false,
                 false, false, false, false, false,
                 false, false
                ]]
            )
        end

        it "should cancel iteration when an error occurs" do
            EM.synchrony {
                results = @n1ql.results
                begin
                    count = 0
                    results.collect { |res|
                        raise 'err' if count > 0
                        @log << res.nil?
                        count += 1
                    }
                rescue => e
                    @log << :error
                end
                @log << results.count

                EM.stop
            }
            expect(@log).to eq([false, :error, 12])
        end

        it "should cancel iteration when an error occurs in row modifer" do
            EM.synchrony {
                count = 0
                results = @n1ql.results do |row|
                    raise 'err' if count > 0
                    count += 1
                    row
                end

                begin
                    count = 0
                    results.collect { |res|
                        @log << res.nil?
                    }
                rescue => e
                    @log << e.message
                end

                EM.stop
            }
            expect(@log).to eq([false, 'err'])
        end
    end
end
