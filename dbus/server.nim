import dbus/lowlevel
import dbus/middlelevel

proc registerObject(connection: Connection, path: ObjectPath,
                    messageFunc: DBusObjectPathMessageFunction,
                    unregisterFunc: DBusObjectPathUnregisterFunction,
                    userData: pointer) =
  var vtable: DBusObjectPathVTable
  reset(vtable)
  vtable.message_function = messageFunc
  vtable.unregister_function = unregisterFunc

  connection.tryRegisterObjectPath(path, addr vtable, userData)

# TYPES

type
  MessageCallback* = proc(connection: Connection; incoming: Message): bool

  PackedMessageCallback = ref object
    connection: Connection
    callback: MessageCallback

proc messageFunc(connection: ptr DBusConnection, message: ptr DBusMessage, user_data: pointer): DBusHandlerResult {.cdecl.} =
  let msg = newMessage(message)

  let packed = cast[PackedMessageCallback](userData)
  let ok = packed.callback(packed.connection, msg)
  if ok:
    return DBUS_HANDLER_RESULT_HANDLED
  else:
    return DBUS_HANDLER_RESULT_NOT_YET_HANDLED

proc unregisterFunc(connection: ptr DBusConnection, userData: pointer) {.cdecl.} =
  GC_unref cast[PackedMessageCallback](userData)

proc registerObject*(connection: Connection, path: ObjectPath, callback: MessageCallback) =
  var packed: PackedMessageCallback
  new(packed)
  packed.connection = connection
  packed.callback = callback
  GC_ref packed

  registerObject(connection, path, messageFunc.DBusObjectPathMessageFunction, unregisterFunc, cast[pointer](packed))
