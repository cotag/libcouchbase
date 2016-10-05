module Libcouchbase::Ext
  # (Not documented)
  #
  # ## Fields:
  # :addcmd ::
  #   (FFI::Pointer(*)) Add a command to the current context
  #   @param ctx the context
  #   @param cmd the command to add. Note that `cmd` may be a subclass of lcb_CMDBASE
  #   @return LCB_SUCCESS, or failure if a command could not be added.
  # :done ::
  #   (FFI::Pointer(*)) Indicate that no more commands are added to this context, and that the
  #   context should assemble the packets and place them in the current
  #   scheduling context
  #   @param ctx The multi context
  #   @param cookie The cookie for all commands
  #   @return LCB_SUCCESS if scheduled successfully, or an error code if there
  #   was a problem constructing the packet(s).
  # :fail ::
  #   (FFI::Pointer(*)) Indicate that no more commands should be added to this context, and that
  #   the context should not add its contents to the packet queues, but rather
  #   release its resources. Called if you don't want to actually perform
  #   the operations.
  #   @param ctx
  class MULTICMDCTX < FFI::Struct
    layout :addcmd, :pointer,
           :done, :pointer,
           :fail, :pointer
  end

end
