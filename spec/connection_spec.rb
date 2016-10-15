# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::Connection do
    before :each do
        @log = []
        expect(@log).to eq([])
    end

    it "should connect and disconnect from the default bucket" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect do |success, error|
                @log << error
                connection.destroy
            end
        }

        expect(@log).to eq([:success])
    end

    it "should store a key on the default bucket" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.store('sometestkey', {"json" => "data"}).then(proc {|resp|
                    @log << resp.callback
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([:callback_store])
    end

    it "should durably store a key on the default bucket" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.store('sometestkey', {"json" => "data2"}, persist_to: -1, replicate_to: -1).then(proc {|resp|
                    @log << resp.callback
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([:callback_storedur])
    end

    it "should fetch a key from the default bucket" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.get('sometestkey').then(proc {|resp|
                    @log << resp.value
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([{json: "data2"}])
    end

    it "should unlock a key on the default bucket" do

        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.get('sometestkey', lock: 2).then(proc {|resp|
                    @log << resp.callback
                    connection.unlock('sometestkey', cas: resp.cas).then(proc {|resp|
                        @log << resp.callback
                    }, proc { |error|
                        @log << error
                    })
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([:callback_get, :callback_unlock])
    end

    it "should remove a key on the default bucket" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.remove('sometestkey').then(proc {|resp|
                    @log << :success
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([:success])
    end

    it "should allow settings to be configured" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                expect(connection.configure(:operation_timeout, 1500000)).to be(connection)
                expect { connection.configure(:bob, 1500000) }.to raise_error(RuntimeError)
                @log << :success
                connection.destroy
            end
        }

        expect(@log).to eq([:success])
    end

    it "should support counter operations" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.counter('testcount', initial: 10, expire_in: 2)
                .then(proc { |resp|
                    @log << resp.value
                    connection.get('testcount').then do |resp|
                        @log << resp.value
                    end
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([10, 10])
    end

    it "should support touch operations" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.store('testtouch', 34).then(proc {|resp|
                    @log << resp.value
                    connection.touch('testtouch', expire_in: 1).then(proc {
                        @log << 'set'
                        sleep 2
                        connection.get('testtouch').catch(proc {|err|
                            @log << err
                        })
                    })
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([34, 'set', :key_enoent])
    end

    it "should obtain view results" do
        reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                view = connection.query_view('zone', 'all')
                @log << view.first.metadata
                @log << view.metadata
                connection.destroy
            end
        }

        expect(@log).to eq([:new_row, 0, :new_row, 1, :new_row, 2, :new_row, 3])
    end
end
