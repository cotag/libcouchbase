# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::Bucket do
    before :each do
        # This will load the couchbase connection on a different thread
        @bucket = Libcouchbase::Bucket.new
        @reactor = ::Libuv::Reactor.default
        @log = []
    end

    describe 'reactor loop' do
        it "should set a value in a reactor loop" do
            @reactor.run { |reactor|
                result = @bucket.set('somekey', 'woop woop')
                @log << result.key
                @log << result.value
            }

            expect(@log).to eq(['somekey', 'woop woop'])
        end

        it "should get a value in a reactor loop" do
            @reactor.run { |reactor|
                @log << @bucket.get('somekey')
                @log << @bucket.get('somekey', extended: true).value
            }
            expect(@log).to eq(['woop woop', 'woop woop'])
        end

        it "should iterate a view in a reactor loop" do
            @reactor.run { |reactor|
                begin
                    view = @bucket.view('zone', 'all')
                    expect(view.first[:type]).to eq('zone')
                    @log << view.metadata[:total_rows]
                    @log << view.count
                ensure
                    @bucket = nil
                end
            }
            expect(@log).to eq([2, 2])
        end

        it "should cancel the request on error in a reactor loop" do
            @reactor.run { |reactor|
                view = @bucket.view('zone', 'all')
                begin
                    view.each do |item|
                        @log << :callback
                        raise 'runtime error'
                    end
                rescue => e
                    @log << view.metadata[:total_rows]
                end
            }

            expect(@log).to eq([:callback, 2])
        end
    end

    describe 'native ruby' do
        it "should iterate a view without a reactor loop" do
            view = @bucket.view('zone', 'all')
            expect(view.first[:type]).to eq('zone')
            @log << view.metadata[:total_rows]
            @log << view.count

            expect(@log).to eq([2, 2])
        end

        it "should cancel the request on error without a reactor loop" do
            view = @bucket.view('zone', 'all')
            begin
                view.each do |item|
                    @log << :callback
                    raise 'runtime error'
                end
            rescue => e
                @log << view.metadata[:total_rows]
            end

            expect(@log).to eq([:callback, 2])
        end
    end
end
