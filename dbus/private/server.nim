# RAW

proc requestName*(bus: Bus, name: string) =
  DbusException.liftDbusError(err):
    discard dbus_bus_request_name(bus.conn, name, 0, addr err)

proc registerObject(bus: Bus, path: ObjectPath,
                    messageFunc: DBusObjectPathMessageFunction,
                    unregisterFunc: DBusObjectPathUnregisterFunction,
                    userData: pointer) =
  var vtable: DBusObjectPathVTable
  reset(vtable)
  vtable.message_function = messageFunc
  vtable.unregister_function = unregisterFunc

  DbusException.liftDbusError(err):
    discard dbus_connection_try_register_object_path(bus.conn, path.string.cstring, addr vtable, userData, addr err)

# TYPES

type
  MessageCallback* = proc(bus: Bus; incoming: Message): bool

  PackedMessageCallback = ref object
    bus: Bus
    callback: MessageCallback

proc name*(incoming: Message): string =
  $dbus_message_get_member(incoming.raw)

proc interfaceName*(incoming: Message): string =
  $dbus_message_get_interface(incoming.raw)

proc unpackValueSeq*(incoming: Message): seq[Variant] =
  for i, iter in incoming.iterate:
    result.add iter[Variant]

proc messageFunc(connection: ptr DBusConnection, message: ptr DBusMessage, user_data: pointer): DBusHandlerResult {.cdecl.} =
  let msg = newMessage(message)

  let packed = cast[PackedMessageCallback](userData)
  let ok = packed.callback(packed.bus, msg)
  if ok:
    return DBUS_HANDLER_RESULT_HANDLED
  else:
    return DBUS_HANDLER_RESULT_NOT_YET_HANDLED

proc unregisterFunc(connection: ptr DBusConnection, userData: pointer) {.cdecl.} =
  GC_unref cast[PackedMessageCallback](userData)

proc registerObject*(bus: Bus, path: ObjectPath, callback: MessageCallback) =
  var packed: PackedMessageCallback
  new(packed)
  packed.bus = bus
  packed.callback = callback
  GC_ref packed

  registerObject(bus, path, messageFunc.DBusObjectPathMessageFunction, unregisterFunc, cast[pointer](packed))
