import dbus/middlelevel
import dbus/errors

proc raiseIfError*(msg: Message) =
  tryRaise msg.getError

proc waitForReply*(call: PendingCall): Message =
  call.connection.flush()
  call.block()
  call.stealReply()
