import dbus/lowlevel
import dbus/middlelevel

type UniqueBus* = object
  connection*: Connection
  uniqueName*: string

proc getUniqueBus*(connection: Connection, uniqueName: string): UniqueBus =
  result.connection = connection
  result.uniqueName = uniqueName

proc getUniqueBus*(busType: DBusBusType, uniqueName: string): UniqueBus =
  getUniqueBus(getBus(busType), uniqueName)
