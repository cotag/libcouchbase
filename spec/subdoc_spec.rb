# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::SubdocRequest do
    before :each do
        # This will load the couchbase connection on a different thread
        @bucket = Libcouchbase::Bucket.new
        @bucket.set('subkeytest', {
            bob: 1234,
            hello: 'this value',
            complex: {
                more: "information",
                age: 12
            },
            another: false
        })
        @reactor = ::Libuv::Reactor.default
        @log = []
    end

    after :each do
        @bucket = nil
        @reactor = nil
        @log = nil
    end

    describe 'reactor loop' do
        it "should lookup a subkey" do
            @reactor.run { |reactor|
                @log = @bucket.subdoc(:subkeytest) do |subdoc|
                    subdoc.get(:hello)
                end
            }

            expect(@log).to eq('this value')
        end

        it "should perform multiple lookup operations" do
            @reactor.run { |reactor|
                @log = @bucket.subdoc(:subkeytest) do |subdoc|
                    subdoc.get(:hello).exists?('bob')
                end
            }

            expect(@log).to eq(['this value', true])
        end

        it "should raise an error on failure" do
            @reactor.run { |reactor|
                begin
                    @log = @bucket.subdoc(:subkeytest).exists?('boby').execute!
                rescue => e
                    @log << e.class
                end
            }
            expect(@log).to eq([::Libcouchbase::Error::SubdocPathNotFound])
        end

        it "should return nil when quiet is true" do
            @reactor.run { |reactor|
                begin
                    @log << @bucket.subdoc(:subkeytest).exists?('boby', quiet: true).execute!
                    @log << @bucket.subdoc(:subkeytest, quiet: true).exists?('boby').execute!
                rescue => e
                    @log << e.class
                end
            }
            expect(@log).to eq([nil, nil])
        end

        it "should perform mutate operations" do
            @reactor.run { |reactor|
                @log << @bucket.subdoc(:subkeytest).dict_upsert(:bob, 4567).execute!
                @log << @bucket.subdoc(:subkeytest).get(:bob).execute!
            }
            expect(@log).to eq([true, 4567])
        end

        it "should perform multiple mutate operations" do
            @reactor.run { |reactor|
                @log << @bucket.subdoc(:subkeytest) { |subdoc|
                    subdoc.dict_upsert(:bob, 4568)
                    subdoc.dict_upsert(:another, {hello: true})
                }
                @log << @bucket.subdoc(:subkeytest).get(:bob).get(:another).execute!
            }
            expect(@log).to eq([true, [4568, {hello: true}]])
        end

        it "should perform a counter mutate operation" do
            @reactor.run { |reactor|
                @log << @bucket.subdoc(:subkeytest).counter(:bob, 1).execute!
                @log << @bucket.subdoc(:subkeytest).get(:bob).execute!
            }
            expect(@log).to eq([1235, 1235])
        end

        it "should perform multiple counter mutate operations" do
            @reactor.run { |reactor|
                @log << @bucket.subdoc(:subkeytest) { |subdoc|
                    subdoc.dict_upsert(:another, {hello: true})
                    subdoc.counter(:bob, 1).counter('complex.age', 1)
                }
                @log << @bucket.subdoc(:subkeytest).get(:bob).get(:another).get('complex.age').execute!
            }
            expect(@log).to eq([[1235, 13], [1235, {hello: true}, 13]])
        end
    end

    describe 'native ruby' do
        it "should lookup a subkey" do
            @log = @bucket.subdoc(:subkeytest) do |subdoc|
                subdoc.get(:hello)
            end

            expect(@log).to eq('this value')
        end

        it "should perform multiple lookup operations" do
            @log = @bucket.subdoc(:subkeytest) do |subdoc|
                subdoc.get(:hello).exists?('bob')
            end

            expect(@log).to eq(['this value', true])
        end

        it "should raise an error on failure" do
            begin
                @log = @bucket.subdoc(:subkeytest).exists?('boby').execute!
            rescue => e
                @log << e.class
            end
            expect(@log).to eq([::Libcouchbase::Error::SubdocPathNotFound])
        end

        it "should return nil when quiet is true" do
            begin
                @log << @bucket.subdoc(:subkeytest).exists?('boby', quiet: true).execute!
                @log << @bucket.subdoc(:subkeytest, quiet: true).exists?('boby').execute!
            rescue => e
                @log << e.class
            end
            expect(@log).to eq([nil, nil])
        end

        it "should perform mutate operations" do
            @log << @bucket.subdoc(:subkeytest).dict_upsert(:bob, 4567).execute!
            @log << @bucket.subdoc(:subkeytest).get(:bob).execute!
            expect(@log).to eq([true, 4567])
        end

        it "should perform multiple mutate operations" do
            @log << @bucket.subdoc(:subkeytest) { |subdoc|
                subdoc.dict_upsert(:bob, 4568)
                subdoc.dict_upsert(:another, {hello: true})
            }
            @log << @bucket.subdoc(:subkeytest).get(:bob).get(:another).execute!
            expect(@log).to eq([true, [4568, {hello: true}]])
        end

        it "should perform a counter mutate operation" do
            @log << @bucket.subdoc(:subkeytest).counter(:bob, 1).execute!
            @log << @bucket.subdoc(:subkeytest).get(:bob).execute!
            expect(@log).to eq([1235, 1235])
        end

        it "should perform multiple counter mutate operations" do
            @log << @bucket.subdoc(:subkeytest) { |subdoc|
                subdoc.dict_upsert(:another, {hello: true})
                subdoc.counter(:bob, 1).counter('complex.age', 1)
            }
            @log << @bucket.subdoc(:subkeytest).get(:bob).get(:another).get('complex.age').execute!
            expect(@log).to eq([[1235, 13], [1235, {hello: true}, 13]])
        end
    end

    describe 'eventmachine loop' do
        require 'em-synchrony'

        it "should get a subkey" do
            EM.synchrony {
                @log = @bucket.subdoc(:subkeytest) do |subdoc|
                    subdoc.get(:hello).exists?('bob')
                end
                EM.stop
            }
            expect(@log).to eq(['this value', true])
        end
    end
end
