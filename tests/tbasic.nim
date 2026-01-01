import unittest

when false:
  import dbus
else:
  import dbus {.all.}
  import std/importutils
  privateAccess Variant
  privateAccess ArrayData
  privateAccess DictEntryData

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
  var msg = makeCall(TEST_BUSNAME,
              TEST_OBJECTPATH,
              TEST_INTERFACE,
              TEST_METHOD)

  msg.append(val)

  let pending = bus.sendMessageWithReply(msg)
  let reply = pending.waitForReply()
  reply.raiseIfError()

  var it = reply.iterate
  # let v = it.unpackCurrent(DbusValue)
  # check v.asNative(string) == "Hello, world!"
  it.advanceIter
  return it.unpackCurrent(Variant)


test "basic":
  let bus = getBus(dbus.DBUS_BUS_SESSION)
  var msg = makeCall(TEST_BUSNAME,
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
  
  let pending = bus.sendMessageWithReply(msg)
  let reply = pending.waitForReply()
  reply.raiseIfError()
  
  var it = reply.iterate
  let v = it.unpackCurrent(Variant)
  check v.get(string) == "Hello, world!"
  it.advanceIter
  check it.unpackCurrent(uint32) == 6

test "int":
  let val = testEcho(uint32(6))
  check signatureOf(val) == Signature"u"
  check val.get(uint32) == 6

test "arrays":
  let val = testEcho(@["a", "b"])
  check signatureOf(val) == Signature"as"
  check val.get(seq[string]) == @["a", "b"]

test "variant":
  let val = testEcho(newVariant("hi"))
  check signatureOf(val) == Signature"s"
  check val.get(string) == "hi"

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
  check val.data.struct[0].get(string) == "hi"
  check val.data.struct[1].get(uint32) == 2

test "tables":
  let val = testEcho(@{"a":"b"})
  check signatureOf(val) == Signature"a{ss}"
  check val.get(seq[(string, string)]) == @{"a": "b"}

test "tables nested":
  let val = testEcho(@{
    "a": @{
      "c":"d"
    }
  })
  check signatureOf(val) == Signature"a{sa{ss}}"
  check val.get(seq[(string, seq[(string, string)])]) == @{
    "a": @{
      "c": "d",
    }
  }

test "tables mixed variant":
  let val = testEcho(newVariant(@{
    "a": newVariant("foo"),
    "b": newVariant(12.uint32),
  }))
  check signatureOf(val) == Signature"a{sv}"
  check val.get(seq[(string, Variant)]) == @{
    "a": newVariant("foo"),
    "b": newVariant(12.uint32),
  }

test "tables mixed variant":
  let val = testEcho(newVariant(@{
    "a": newVariant("foo"),
    "b": newVariant(@{
      "c": "d",
    })
  }))
  check signatureOf(val) == Signature("a{sv}")
  check val.get(seq[(string, Variant)]) == @{
    "a": newVariant("foo"),
    "b": newVariant(@{
      "c": "d",
    })
  }

test "notify":
  let bus = getBus(DBUS_BUS_SESSION)
  var msg = makeCall("org.freedesktop.Notifications",
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

  let pending = bus.sendMessage(msg)

