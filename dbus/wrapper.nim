import dbus/middlelevel
import dbus/bus

type DbusIfaceWrapper* {.inheritable.} = object
  uniqueBus*: UniqueBus
  path*: ObjectPath
