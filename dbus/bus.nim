import dbus/lowlevel
import dbus/errors

type Bus* = ref object
  conn*: ptr DBusConnection

type UniqueBus* = object
  bus*: Bus
  uniqueName*: string

# we don't destroy the connection as dbus_bus_get returns shared pointer
proc destroyConnection(bus: Bus) =
  dbus_connection_close(bus.conn)

proc getBus*(busType: DBusBusType): Bus =
  doAssert dbus_threads_init_default() != 0 # enable threads
  new(result)
  DBusException.liftDbusError(err):
    result.conn = dbus_bus_get(busType, addr err)

  assert result.conn != nil

proc getUniqueBus*(bus: Bus, uniqueName: string): UniqueBus =
  result.bus = bus
  result.uniqueName = uniqueName

proc getUniqueBus*(busType: DBusBusType, uniqueName: string): UniqueBus =
  getUniqueBus(getBus(busType), uniqueName)

proc flush*(conn: Bus) =
  dbus_connection_flush(conn.conn)
