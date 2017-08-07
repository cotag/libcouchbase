# frozen_string_literal: true, encoding: ASCII-8BIT

require 'concurrent'
require 'ffi'

module Libcouchbase
    module Callbacks


        private


        module ClassMethods
            def dispatch_callback(func_name, lookup, args)
                instance_id = __send__(lookup, *args)
                inst = @callback_lookup[instance_id]
                inst.__send__(func_name, *args) if inst.respond_to?(func_name, true)
            end

            def define_callback(function:, params: [:pointer, :int, :pointer], ret_val: :void, lookup: :default_lookup)
                @callback_funcs[function] = ::FFI::Function.new(ret_val, params) do |*args|
                    dispatch_callback(function, lookup, args)
                end
            end

            # Much like include to support inheritance properly
            # We keep existing callbacks and inherit the lookup (as this will never clash)
            def inherited(subclass)
                subclass.instance_variable_set(:@callback_funcs, {}.merge(@callback_funcs))
                subclass.instance_variable_set(:@callback_lookup, @callback_lookup)
                subclass.instance_variable_set(:@callback_lock, @callback_lock)
            end


            # Provide accessor methods to the class level instance variables
            attr_reader :callback_lookup, :callback_funcs, :callback_lock


            # This function is used to work out the instance the callback is for
            def default_lookup(req, *args)
                req.address
            end
        end

        def self.included(base)
            base.instance_variable_set(:@callback_funcs, {})
            base.instance_variable_set(:@callback_lookup, ::Concurrent::Hash.new)
            base.instance_variable_set(:@callback_lock, ::Mutex.new)
            base.extend(ClassMethods)
        end


        def callback(name, instance_id = @ref)
            klass = self.class
            klass.callback_lock.synchronize do
                klass.callback_lookup[instance_id] = self
            end
            klass.callback_funcs[name]
        end

        def cleanup_callbacks(instance_id = @ref)
            klass = self.class
            klass.callback_lock.synchronize do
                inst = klass.callback_lookup[instance_id]
                klass.callback_lookup.delete(instance_id) if inst == self
            end
        end
    end
end
