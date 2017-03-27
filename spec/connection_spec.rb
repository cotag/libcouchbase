# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::Connection do
    before :each do
        @log = []
        expect(@log).to eq([])
        @reactor = ::Libuv::Reactor.default
    end

    after :each do
        @reactor = nil
        @log = nil
    end

    it "should connect and disconnect from the default bucket" do
        @reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then {
                @log << true
            }.finally { connection.destroy }
        }

        expect(@log).to eq([true])
    end

    it "should store a raw key on the bucket" do
        @reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.store('sometestkey', 'rawdata', format: :plain).then(proc {|resp|
                    @log << resp.callback
                    prom = connection.store('sometestkey', 'moredata', operation: :append)
                    prom.then(proc { |success|
                        connection.get('sometestkey').then(proc {|resp|
                            @log << resp.value
                        }, proc { |error|
                            @log << error
                        })
                    }, proc { |error|
                        @log << error
                    })
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([:callback_store, 'rawdatamoredata'])
    end

    it "should store a key on the default bucket" do
        @reactor.run { |reactor|
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
        @reactor.run { |reactor|
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
        @reactor.run { |reactor|
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

        @reactor.run { |reactor|
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
        @reactor.run { |reactor|
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
        @reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                expect(co(connection.configure(:operation_timeout, 1500000))).to be(connection)
                expect { co(connection.configure(:bob, 1500000)) }.to raise_error(Libcouchbase::Error)
                @log << :success
                connection.destroy
            end
        }

        expect(@log).to eq([:success])
    end

    it "should return the server list" do
        @reactor.run { |reactor|
            begin
                connection = Libcouchbase::Connection.new
                co connection.connect
                @log = co(connection.get_server_list)
            ensure
                connection.destroy
            end
        }

        expect(@log).to eq(['127.0.0.1:11210'])
    end

    it "should support counter operations" do
        @reactor.run { |reactor|
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
        @reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.store('testtouch', 34).then(proc {|resp|
                    @log << resp.value
                    connection.touch('testtouch', expire_in: 1).then(proc {
                        @log << 'set'
                        sleep 2
                        connection.get('testtouch').catch(proc {|err|
                            @log << err.is_a?(Libcouchbase::Error::KeyNotFound)
                        })
                    })
                }, proc { |error|
                    @log << error
                }).finally { connection.destroy }
            end
        }

        expect(@log).to eq([34, 'set', true])
    end

    it "should fail to flush unless the connection specifies it is enabled" do
        @reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                begin
                    connection.flush.then(proc {
                        @log << :error
                    }, proc {
                        @log << :error
                    }).finally { connection.destroy }
                rescue => e
                    @log << :success
                    connection.destroy
                end
            end
        }

        expect(@log).to eq([:success])
    end

    it "should flush when enabled explicitly" do
        @reactor.run { |reactor|
            connection = Libcouchbase::Connection.new(bucket: :test, password: 'password123')
            connection.connect(flush_enabled: true).then do
                begin
                    connection.flush.then(proc { |resp|
                        @log << resp.callback
                    }, proc { |error|
                        @log << error
                    }).finally { connection.destroy }
                rescue => e
                    @log << e
                    connection.destroy
                end
            end
        }

        expect(@log).to eq([:callback_cbflush])
    end

    it "should perform a HTTP request" do
        @reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.http("/pools/default/buckets/#{connection.bucket}/ddocs", type: :management).then(
                    proc { |resp|
                        @log << resp.headers.empty?
                        @log << resp.body.empty?
                    },
                    proc { |err|
                        @log << err
                    }
                ).finally { connection.destroy }
            end
        }

        expect(@log).to eq([false, false])
    end

    it "should fail a HTTP request" do
        @reactor.run { |reactor|
            connection = Libcouchbase::Connection.new
            connection.connect.then do
                connection.http("/pools/default/buckets/#{connection.bucket}/ddocs").then(
                    proc { |resp|
                        @log << resp.headers.empty?
                        @log << resp.body.empty?
                    },
                    proc { |err|
                        @log << err.message
                        @log << err.code
                    }
                ).finally { connection.destroy }
            end
        }

        expect(@log).to eq(['non success response for /pools/default/buckets/default/ddocs', 400])
    end
end
