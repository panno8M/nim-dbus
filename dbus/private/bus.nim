import dbus/lowlevel
import dbus/errors
export lowlevel

converter toBool(x: dbus_bool_t): bool = x != 0

type DbusRemoteException* = object of DbusException

type Bus* = ref object
  conn*: ptr DBusConnection

type UniqueBus* = object
  bus*: Bus
  uniqueName*: string

# we don't destroy the connection as dbus_bus_get returns shared pointer
proc destroyConnection(bus: Bus) =
  dbus_connection_close(bus.conn)

proc getBus*(busType: DBusBusType): Bus =
  let ok = dbus_threads_init_default() # enable threads
  assert ok
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
