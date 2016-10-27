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
        it "should set a value" do
            @reactor.run { |reactor|
                result = @bucket.set('somekey', 'woop woop')
                @log << result.key
                @log << result.value
                @log << @bucket.set('somekey2', 'woop woop2').value
            }

            expect(@log).to eq(['somekey', 'woop woop', 'woop woop2'])
        end

        it "should get a value" do
            @reactor.run { |reactor|
                @log << @bucket.get('somekey')
                @log << @bucket.get('somekey', extended: true).value
            }
            expect(@log).to eq(['woop woop', 'woop woop'])
        end

        it "should get a value quietly" do
            @reactor.run { |reactor|
                @log << @bucket.get('somekey-noexist', quiet: true)
                @log << @bucket[:noexist2]
            }
            expect(@log).to eq([nil, nil])
        end

        it "should get multiple values" do
            @reactor.run { |reactor|
                @log << @bucket.get('somekey', 'somekey2')
                @log << @bucket.get('somekey', 'somekey2', 'no-exist-sgs', quiet: true)
            }
            expect(@log).to eq([['woop woop', 'woop woop2'], ['woop woop', 'woop woop2', nil]])
        end

        it "should get multiple values as a hash" do
            @reactor.run { |reactor|
                @log << @bucket.get('somekey', 'somekey2', assemble_hash: true)
                @log << @bucket.get('somekey', 'somekey2', 'no-exist-sgs', quiet: true, assemble_hash: true)
                @log << @bucket.get('somekey', assemble_hash: true)
                @log << @bucket.get('no-exist-sgs', quiet: true, assemble_hash: true)
            }
            expect(@log).to eq([
                {'somekey' => 'woop woop', 'somekey2' => 'woop woop2'},
                {'somekey' => 'woop woop', 'somekey2' => 'woop woop2', 'no-exist-sgs' => nil},
                {'somekey' => 'woop woop'},
                {'no-exist-sgs' => nil}
            ])
        end

        it "should compare and swap a value" do
            @reactor.run { |reactor|
                @bucket.set('somekey', 'woop woop')
                result = @bucket.cas('somekey') do |current|
                    @log << current
                    "current #{current}"
                end
                @log << result.value
            }
            expect(@log).to eq(['woop woop', 'current woop woop'])
        end

        it "should retry when performing a CAS operation" do
            @reactor.run { |reactor|
                begin
                    @bucket.set('somekey', 'woop woop')
                    result = @bucket.cas('somekey', retry: 2) do |current|
                        @log << current
                        # This ensures the operation fails
                        @bucket.set('somekey', 'woop woop1')
                        "current #{current}"
                    end
                    @log << result.value
                rescue Libcouchbase::Error::KeyExists
                    @log << :error
                end
            }
            expect(@log).to eq(['woop woop', 'woop woop1', 'woop woop1', :error])
        end

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

    describe 'native ruby' do
        it "should set a value" do
            result = @bucket.set('somekey', 'woop woop')
            @log << result.key
            @log << result.value
            @log << @bucket.set('somekey2', 'woop woop2').value

            expect(@log).to eq(['somekey', 'woop woop', 'woop woop2'])
        end

        it "should get a value" do
            @log << @bucket.get('somekey')
            @log << @bucket.get('somekey', extended: true).value

            expect(@log).to eq(['woop woop', 'woop woop'])
        end

        it "should get a value quietly" do
            @log << @bucket.get('somekey-noexist', quiet: true)
            @log << @bucket[:noexist2]

            expect(@log).to eq([nil, nil])
        end

        it "should get multiple values" do
            @log << @bucket.get('somekey', 'somekey2')
            @log << @bucket.get('somekey', 'somekey2', 'no-exist-sgs', quiet: true)

            expect(@log).to eq([['woop woop', 'woop woop2'], ['woop woop', 'woop woop2', nil]])
        end

        it "should get multiple values as a hash" do
            @log << @bucket.get('somekey', 'somekey2', assemble_hash: true)
            @log << @bucket.get('somekey', 'somekey2', 'no-exist-sgs', quiet: true, assemble_hash: true)
            @log << @bucket.get('somekey', assemble_hash: true)
            @log << @bucket.get('no-exist-sgs', quiet: true, assemble_hash: true)
            
            expect(@log).to eq([
                {'somekey' => 'woop woop', 'somekey2' => 'woop woop2'},
                {'somekey' => 'woop woop', 'somekey2' => 'woop woop2', 'no-exist-sgs' => nil},
                {'somekey' => 'woop woop'},
                {'no-exist-sgs' => nil}
            ])
        end

        it "should compare and swap a value" do
            @bucket.set('somekey', 'woop woop')
            result = @bucket.cas('somekey') do |current|
                @log << current
                "current #{current}"
            end
            @log << result.value

            expect(@log).to eq(['woop woop', 'current woop woop'])
        end

        it "should retry when performing a CAS operation" do
            begin
                @bucket.set('somekey', 'woop woop')
                result = @bucket.cas('somekey', retry: 2) do |current|
                    @log << current
                    # This ensures the operation fails
                    @bucket.set('somekey', 'woop woop1')
                    "current #{current}"
                end
                @log << result.value
            rescue Libcouchbase::Error::KeyExists
                @log << :error
            end

            expect(@log).to eq(['woop woop', 'woop woop1', 'woop woop1', :error])
        end

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

        it "should iterate a full text search", full_text_search: true do
            view = @bucket.full_text_search(:default, 'Toshiba').to_a.length
            expect(view).to eq(4)
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
end
