# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::QueryView do
    before :each do
        # This will load the couchbase connection on a different thread
        @bucket = Libcouchbase::Bucket.new
        @reactor = ::Libuv::Reactor.default
        @log = []
    end

    describe 'perform native queries' do
        it "should iterate a view" do
            view = @bucket.view('zone', 'all')
            expect(view.first.value[:type]).to eq('zone')
            @log << view.metadata[:total_rows]
            @log << view.count

            expect(@log).to eq([2, 2])
        end

        it "should iterate a view without getting documents" do
            view = @bucket.view('zone', 'all', include_docs: false)
            expect(view.first.key).to eq('zone_1-10')
            expect(view.first.value).to be(nil)
            @log << view.metadata[:total_rows]
            @log << view.count

            expect(@log).to eq([2, 2])
        end

        it "should fail if a view doesn't exist" do
            view = @bucket.view('zone', 'alling')
            expect { view.first }.to raise_error(Libcouchbase::Error::HttpError)
        end

        it "should cancel the request on error" do
            view = @bucket.view('zone', 'all')
            begin
                view.each do |item|
                    @log << :callback
                    raise 'runtime error'
                end
                @log << :wtf
            rescue => e
                @log << view.metadata[:total_rows]
            end

            expect(@log).to eq([:callback, 2])
        end

        it "should create a design document" do
            doc = {
                _id: "_design/blog",
                    language: "javascript",
                    views: {
                    recent_posts: {
                        map: "function(doc){if(doc.date && doc.title){emit(doc.date, doc.title);}}"
                    }
                }
            }
            @log << @bucket.save_design_doc(doc).status
            expect(@log).to eq([201])
        end

        it "should delete a design document" do
            @log << @bucket.delete_design_doc('_design/blog').status
            expect(@log).to eq([200])
        end
    end

    describe 'perform queries in libuv reactor' do
        it "should iterate a view" do
            @reactor.run { |reactor|
                begin
                    view = @bucket.view('zone', 'all')
                    expect(view.first.value[:type]).to eq('zone')
                    @log << view.metadata[:total_rows]
                    @log << view.count
                ensure
                    @bucket = nil
                end
            }
            expect(@log).to eq([2, 2])
        end

        it "should iterate a view without getting documents" do
            @reactor.run { |reactor|
                begin
                    view = @bucket.view('zone', 'all', include_docs: false)
                    expect(view.first.key).to eq('zone_1-10')
                    expect(view.first.value).to be(nil)
                    @log << view.metadata[:total_rows]
                    @log << view.count
                ensure
                    @bucket = nil
                end
            }
            expect(@log).to eq([2, 2])
        end

        it "should fail if a view doesn't exist" do
            @reactor.run { |reactor|
                view = @bucket.view('zone', 'alling')
                expect { view.first }.to raise_error(Libcouchbase::Error::HttpError)
            }
        end

        it "should cancel the request on error" do
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

    describe 'perform queries in event machine' do
        require 'em-synchrony'
        
        it "should iterate a view" do
            EM.synchrony {
                begin
                    view = @bucket.view('zone', 'all')
                    expect(view.first.value[:type]).to eq('zone')
                    @log << view.metadata[:total_rows]
                    @log << view.count
                ensure
                    @bucket = nil
                end

                EM.stop
            }
            expect(@log).to eq([2, 2])
        end

        it "should iterate a view without getting documents" do
            EM.synchrony {
                begin
                    view = @bucket.view('zone', 'all', include_docs: false)
                    expect(view.first.key).to eq('zone_1-10')
                    expect(view.first.value).to be(nil)
                    @log << view.metadata[:total_rows]
                    @log << view.count
                ensure
                    @bucket = nil
                end

                EM.stop
            }
            expect(@log).to eq([2, 2])
        end

        it "should fail if a view doesn't exist" do
            EM.synchrony {
                begin
                    view = @bucket.view('zone', 'alling')
                    expect { view.first }.to raise_error(Libcouchbase::Error::HttpError)
                    @log << :made_it_here
                ensure
                    EM.stop
                end
            }
            expect(@log).to eq([:made_it_here])
        end

        it "should cancel the request on error" do
            EM.synchrony {
                view = @bucket.view('zone', 'all')
                begin
                    view.each do |item|
                        @log << :callback
                        raise 'runtime error'
                    end
                rescue => e
                    @log << view.metadata[:total_rows]
                end

                EM.stop
            }

            expect(@log).to eq([:callback, 2])
        end
    end
end
