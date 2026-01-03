import dbus/lowlevel

type DBusException* = object of CatchableError
  err*: DbusError

proc `=destroy`*(e: DBusException) =
  dbus_error_free(addr e.err)

type DbusRemoteException* = object of DbusException

proc toException*[T: DBusException](err: sink DbusError; Exc: typedesc[T]): ref[T] =
  if dbus_error_is_set(addr err) != 0:
    return (ref Exc)(
      msg: $err.name & ": " & $err.message,
      err: move(err))

proc tryRaise*(exc: ref Exception) =
  if exc != nil:
    raise exc

template liftDbusError*(Exc: typedesc[DBusException]; err; body): untyped =
  block:
    var err {.inject.}: DBusError
    try:
      dbus_error_init(addr err)
      body
    except Exception:
      dbus_error_free(addr err)
      raise
    tryRaise err.toException(Exc)
