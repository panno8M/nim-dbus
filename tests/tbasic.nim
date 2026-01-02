import unittest

import dbus

when true:
  import dbus/types {.all.}
  import std/importutils
  privateAccess Variant

const
  TEST_BUSNAME = "com.zielmicha.test"
  TEST_OBJECTPATH = ObjectPath("/com/zielmicha/test")
  TEST_INTERFACE = "com.zielmicha.test"
  TEST_METHOD = "hello"

proc testEcho[T](val: T): Variant =
  ## Test helper proc that sends a value to the test echo Dbus
  ## service and returns the echoed value.  Useful for testing
  ## that values can be sent and retrieved through the bus
  let bus = getBus(dbus.DBUS_BUS_SESSION)
  var msg = newMethodCallMessage(TEST_BUSNAME,
              TEST_OBJECTPATH,
              TEST_INTERFACE,
              TEST_METHOD)

  msg.append(val)

  let pending = bus.sendWithReply(msg)
  let reply = pending.waitForReply()
  reply.raiseIfError()

  for i, iter in reply.iterate:
    case i
    of 0:
      check iter.decode(string) == "Hello, world!"
    of 1:
      return iter.decode(Variant)
    else: discard

test "basic":
  let bus = getBus(dbus.DBUS_BUS_SESSION)
  var msg = newMethodCallMessage(TEST_BUSNAME,
              TEST_OBJECTPATH,
              TEST_INTERFACE,
              TEST_METHOD)
  
  msg.append(uint32(6))
  msg.append("hello")
  msg.append(1'i32)
  msg.append(newVariant("hello"))
  msg.append(@["a", "b"])
  msg.append(@{"a": "b"})
  msg.append(ObjectPath("/a"))
  msg.append(@[ObjectPath("/b")])
  
  let pending = bus.sendWithReply(msg)
  let reply = pending.waitForReply()
  reply.raiseIfError()
  
  for i, iter in reply.iterate:
    case i
    of 0:
      check iter.decode(string) == "Hello, world!"
    of 1:
      check iter.decode(uint32) == 6
    else:
      discard

template simpleTest(sig: Signature; value) =
  let val = value
  let res = testEcho(val)
  check signatureOf(res) == sig
  check res[sig] == val

test "int":
  simpleTest(Signature"u"):
    6'u32

test "arrays":
  simpleTest(Signature"as"):
    @["a", "b"]

test "struct":
  let val = testEcho(Variant(
    typ: Signature"(su)",
    data: VariantData(
      struct: @[
        newVariant("hi"),
        newVariant(uint32(2)),
    ])))
  check signatureOf(val) == Signature"(su)"
  check val.data.struct.len == 2
  check val.data.struct[0][string] == "hi"
  check val.data.struct[1][uint32] == 2

test "tables":
  simpleTest(Signature"a{ss}"):
    @{"a":"b"}

test "tables nested":
  simpleTest(Signature"a{sa{ss}}"):
    @{
      "a": @{
        "c":"d"
      }
    }

test "tables mixed variant":
  simpleTest(Signature"a{sv}"):
    @{
      "a": newVariant("foo"),
      "b": newVariant(12.uint32),
    }

test "tables mixed variant":
  simpleTest(Signature"a{sv}"):
    @{
      "a": newVariant("foo"),
      "b": newVariant(@{
        "c": "d",
      })
    }

test "notify":
  let bus = getBus(DBUS_BUS_SESSION)
  var msg = newMethodCallMessage("org.freedesktop.Notifications",
              ObjectPath("/org/freedesktop/Notifications"),
              "org.freedesktop.Notifications",
              "Notify")

  msg.append("nim-dbus")
  msg.append(0'u32)
  msg.append("dialog-information")
  msg.append("Test notification")
  msg.append("Test notification body")
  msg.append(newSeq[string]())
  msg.append(@{"urgency": newVariant(1'u8)})
  msg.append(-1'i32)

  let pending = bus.send(msg)

