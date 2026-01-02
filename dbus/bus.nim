import dbus/lowlevel
import dbus/errors

type
  BusObj* = object
    conn*: ptr DBusConnection
  Bus* = ref BusObj

type UniqueBus* = object
  bus*: Bus
  uniqueName*: string

proc `=destroy`*(bus: BusObj) =
  dbus_connection_unref(bus.conn)
proc `=copy`*(dst: var BusObj; src: BusObj) =
  `=destroy` dst
  wasMoved dst
  dst.conn = dbus_connection_ref(src.conn)

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
