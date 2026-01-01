# RAW

proc requestName*(bus: Bus, name: string) =
  var err: DBusError
  dbus_error_init(addr err)

  let ret = dbus_bus_request_name(bus.conn, name, 0, addr err)

  if ret < 0:
    defer: dbus_error_free(addr err)
    raise newException(DbusException, $err.message)

proc registerObject(bus: Bus, path: ObjectPath,
                    messageFunc: DBusObjectPathMessageFunction,
                    unregisterFunc: DBusObjectPathUnregisterFunction,
                    userData: pointer) =
  var err: DBusError
  dbus_error_init(addr err)

  var vtable: DBusObjectPathVTable
  reset(vtable)
  vtable.message_function = messageFunc
  vtable.unregister_function = unregisterFunc

  let ok = dbus_connection_try_register_object_path(bus.conn, path.string.cstring, addr vtable, userData, addr err)

  if ok == 0:
    defer: dbus_error_free(addr err)
    raise newException(DbusException, $err.message)

# TYPES

type
  MessageCallback* = proc(incoming: Message): bool

  PackedMessageCallback = ref object
    callback: MessageCallback

proc name*(incoming: Message): string =
  $dbus_message_get_member(incoming.raw)

proc interfaceName*(incoming: Message): string =
  $dbus_message_get_interface(incoming.raw)

proc unpackValueSeq*(incoming: Message): seq[Variant] =
  for i, iter in incoming.iterate:
    result.add iter.decode(Variant)

# VTABLE

const
  DBUS_MESSAGE_TYPE_METHOD_CALL = 1
  DBUS_MESSAGE_TYPE_SIGNAL = 4

proc messageFunc(connection: ptr DBusConnection, message: ptr DBusMessage, user_data: pointer): DBusHandlerResult {.cdecl.} =
  let rawType = dbus_message_get_type(message)
  var msg: Message
  if rawType == DBUS_MESSAGE_TYPE_METHOD_CALL:
    msg = MethodCallMessage(raw: message)
  elif rawType == DBUS_MESSAGE_TYPE_SIGNAL:
    msg = SignalMessage(raw: message)
  else:
    raise newException(DbusException, "unknown message(" & $rawType & ")")

  let ok = cast[PackedMessageCallback](userData).callback(msg)
  if ok:
    return DBUS_HANDLER_RESULT_HANDLED
  else:
    return DBUS_HANDLER_RESULT_NOT_YET_HANDLED

proc unregisterFunc(connection: ptr DBusConnection, userData: pointer) {.cdecl.} =
  GC_unref cast[PackedMessageCallback](userData)

proc registerObject*(bus: Bus, path: ObjectPath, callback: MessageCallback) =
  var packed: PackedMessageCallback
  new(packed)
  packed.callback = callback
  GC_ref packed

  registerObject(bus, path, messageFunc.DBusObjectPathMessageFunction, unregisterFunc, cast[pointer](packed))
