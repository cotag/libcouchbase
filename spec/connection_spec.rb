# frozen_string_literal: true, encoding: ASCII-8BIT

require 'libcouchbase'


describe Libcouchbase::Connection do
	before :each do
		@log = []
        expect(@log).to eq([])
	end
	
	it "should connect and disconnect from the default bucket" do
        reactor.run { |reactor|
            begin
                connection = Libcouchbase::Connection.new
                connection.connect do |success, error|
                    @log << error
                    connection.destroy
                end
            rescue => e
                @log << e.message
                @log << e.backtrace
                connection.destroy
            end
        }

        expect(@log).to eq([:success])
	end

    it "should store a key on the default bucket" do
        reactor.run { |reactor|
            begin
                connection = Libcouchbase::Connection.new
                connection.connect do |success, error|
                    if success
                        connection.store('sometestkey', '{"json":"data"}').then(proc {|resp|
                            @log << :success
                        }, proc { |error|
                            @log << error
                        }).finally { connection.destroy }
                    end
                end
            rescue => e
                @log << e.message
                @log << e.backtrace
                connection.destroy
            end
        }

        expect(@log).to eq([:success])
    end

    it "should fetch a key from the default bucket" do
        reactor.run { |reactor|
            begin
                connection = Libcouchbase::Connection.new
                connection.connect do |success, error|
                    if success
                        connection.get('sometestkey').then(proc {|resp|
                            @log << resp.value
                        }, proc { |error|
                            @log << error
                        }).finally { connection.destroy }
                    end
                end
            rescue => e
                @log << e.message
                @log << e.backtrace
                connection.destroy
            end
        }

        expect(@log).to eq(['{"json":"data"}'])
    end

    it "should remove a key on the default bucket" do
        reactor.run { |reactor|
            begin
                connection = Libcouchbase::Connection.new
                connection.connect do |success, error|
                    if success
                        connection.remove('sometestkey').then(proc {|resp|
                            @log << :success
                        }, proc { |error|
                            @log << error
                        }).finally { connection.destroy }
                    end
                end
            rescue => e
                @log << e.message
                @log << e.backtrace
                connection.destroy
            end
        }

        expect(@log).to eq([:success])
    end
end
