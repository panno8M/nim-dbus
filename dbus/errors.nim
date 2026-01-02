import dbus/lowlevel

type DBusException* = object of CatchableError
  err*: DbusError

proc `=destroy`*(e: DBusException) =
  dbus_error_free(addr e.err)

template liftDbusError*(Exc: typedesc[DBusException]; err; body): untyped =
  block:
    var err {.inject.}: DBusError
    try:
      dbus_error_init(addr err)
      body
    except Exception:
      dbus_error_free(addr err)
      raise
    if dbus_error_is_set(addr err) != 0:
      raise (ref Exc)(
        msg: $err.name & ": " & $err.message,
        err: move(err))

