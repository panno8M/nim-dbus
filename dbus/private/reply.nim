

proc raiseIfError*(msg: Message) =
  if msg of ErrorMessage:
    DbusRemoteException.liftDbusError(err):
      err = ErrorMessage(msg).getError

proc waitForReply*(call: PendingCall): Message =
  call.bus.flush()
  dbus_pending_callblock(call.call)
  var msg = dbus_pending_call_steal_reply(call.call)
  result = newMessage(msg)

  defer: dbus_pending_call_unref(call.call)
