# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::Bucket do
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

        it "should get multiple results asynchronously and then wait for the results" do
            results = []
            results << @bucket.get('somekey', async: true)
            results << @bucket.get('somekey2', async: true)
            
            @log = @bucket.wait_results results

            expect(@log).to eq(['woop woop', 'woop woop2'])
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
    end

    describe 'eventmachine loop' do
        require 'em-synchrony'

        it "should set a value" do
            EM.synchrony {
                result = @bucket.set('somekey', 'woop woop')
                @log << result.key
                @log << result.value
                @log << @bucket.set('somekey2', 'woop woop2').value
                EM.stop
            }

            expect(@log).to eq(['somekey', 'woop woop', 'woop woop2'])
        end

        it "should get a value" do
            EM.synchrony {
                @log << @bucket.get('somekey')
                @log << @bucket.get('somekey', extended: true).value
                EM.stop
            }
            expect(@log).to eq(['woop woop', 'woop woop'])
        end

        it "should get a value quietly" do
            EM.synchrony {
                @log << @bucket.get('somekey-noexist', quiet: true)
                @log << @bucket[:noexist2]
                EM.stop
            }
            expect(@log).to eq([nil, nil])
        end

        it "should get multiple values" do
            EM.synchrony {
                @log << @bucket.get('somekey', 'somekey2')
                @log << @bucket.get('somekey', 'somekey2', 'no-exist-sgs', quiet: true)
                EM.stop
            }
            expect(@log).to eq([['woop woop', 'woop woop2'], ['woop woop', 'woop woop2', nil]])
        end

        it "should get multiple values as a hash" do
            EM.synchrony {
                @log << @bucket.get('somekey', 'somekey2', assemble_hash: true)
                @log << @bucket.get('somekey', 'somekey2', 'no-exist-sgs', quiet: true, assemble_hash: true)
                @log << @bucket.get('somekey', assemble_hash: true)
                @log << @bucket.get('no-exist-sgs', quiet: true, assemble_hash: true)
                EM.stop
            }
            expect(@log).to eq([
                {'somekey' => 'woop woop', 'somekey2' => 'woop woop2'},
                {'somekey' => 'woop woop', 'somekey2' => 'woop woop2', 'no-exist-sgs' => nil},
                {'somekey' => 'woop woop'},
                {'no-exist-sgs' => nil}
            ])
        end

        it "should compare and swap a value" do
            EM.synchrony {
                @bucket.set('somekey', 'woop woop')
                result = @bucket.cas('somekey') do |current|
                    @log << current
                    "current #{current}"
                end
                @log << result.value
                EM.stop
            }
            expect(@log).to eq(['woop woop', 'current woop woop'])
        end

        it "should retry when performing a CAS operation" do
            EM.synchrony {
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
                EM.stop
            }
            expect(@log).to eq(['woop woop', 'woop woop1', 'woop woop1', :error])
        end
    end
end
