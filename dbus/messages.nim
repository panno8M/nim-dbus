import dbus/lowlevel

import dbus/errors
import dbus/bus
import dbus/types

type
  MessageObj* = object of RootObj
    raw*: ptr DBusMessage

  Message* = ref MessageObj
  MethodCallMessage* = ref object of Message
  MethodReturnMessage* = ref object of Message
  ErrorMessage* = ref object of Message
  SignalMessage* = ref object of Message

  MessageType* = enum
    mtInvalid = 0, mtMethodCall = 1, mtMethodReturn = 2,
    mtError = 3, mtSignal = 4

proc `=destroy`*(a: MessageObj) =
  if a.raw.isNil: return
  dbus_message_unref(a.raw)
proc `=copy`*(a: var MessageObj; b: MessageObj) =
  `=destroy` a
  wasMoved a
  a.raw = dbus_message_ref(b.raw)

proc type*(msg: ptr DBusMessage): MessageType =
  if msg.isNil:
    mtInvalid
  else:
    MessageType(dbus_message_get_type(msg))
proc type*(msg: Message): MessageType =
  msg.raw.type

proc newMessage*(msg: ptr DBusMessage): Message =
  if msg.isNil:
    raise newException(DbusException, "the message is nil")
  case msg.type
  of mtMethodCall:
    MethodCallMessage(raw: msg)
  of mtMethodReturn:
    MethodReturnMessage(raw: msg)
  of mtError:
    ErrorMessage(raw: msg)
  of mtSignal:
    SignalMessage(raw: msg)
  of mtInvalid:
    raise newException(DbusException, "the message is invalid")

proc newSignalMessage*(path: string, iface: string, name: string): SignalMessage =
  SignalMessage(raw: dbus_message_new_signal(path, iface, name))

proc newMethodCallMessage*(uniqueName: string, path: ObjectPath, iface: string, name: string): MethodCallMessage =
  MethodCallMessage(raw: dbus_message_new_method_call(uniqueName, path.string.cstring, iface, name))

proc newMethodReturnMessage*(methodCall: MethodCallMessage): MethodReturnMessage =
  MethodReturnMessage(raw: dbus_message_new_method_return(methodCall.raw))

proc newErrorMessage*(methodCall: MethodCallMessage; name: string; message: string): ErrorMessage =
  ErrorMessage(raw: dbus_message_new_error(methodCall.raw, cstring(name), cstring(message)))

proc getError*(msg: ErrorMessage): DBusError =
  discard dbus_set_error_from_message(addr result, msg.raw)

proc send*(conn: Bus, msg: Message): dbus_uint32_t {.discardable.} =
  if not bool(dbus_connection_send(conn.conn, msg.raw, addr result)):
      raise newException(DbusException, "dbus_connection_send")

type PendingCall* = object
  call*: ptr DBusPendingCall
  bus*: Bus

proc sendWithReply*(bus: Bus, msg: Message): PendingCall =
  result.bus = bus
  if not bool(dbus_connection_send_with_reply(bus.conn, msg.raw, addr result.call, -1)):
    raise newException(DbusException, "dbus_connection_send_with_reply")
  if result.call == nil:
    raise newException(DbusException, "pending call still nil")
