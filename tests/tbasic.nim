import unittest

import tables
import dbus

const
  TEST_BUSNAME = "com.zielmicha.test"
  TEST_OBJECTPATH = ObjectPath("/com/zielmicha/test")
  TEST_INTERFACE = "com.zielmicha.test"
  TEST_METHOD = "hello"

proc testEcho[T](val: T): DbusValue =
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
  return it.unpackCurrent(DbusValue)


test "basic":
  let bus = getBus(dbus.DBUS_BUS_SESSION)
  var msg = makeCall(TEST_BUSNAME,
              TEST_OBJECTPATH,
              TEST_INTERFACE,
              TEST_METHOD)
  
  msg.append(uint32(6))
  msg.append("hello")
  msg.append(1'i32)
  msg.append("hello".asDbusValue)
  msg.append(@["a", "b"])
  msg.append({"a": "b"}.toTable)
  msg.append(ObjectPath("/a"))
  msg.append(@[ObjectPath("/b")])
  
  let pending = bus.sendMessageWithReply(msg)
  let reply = pending.waitForReply()
  reply.raiseIfError()
  
  var it = reply.iterate
  let v = it.unpackCurrent(DbusValue)
  check v.asNative(string) == "Hello, world!"
  it.advanceIter
  check it.unpackCurrent(uint32) == 6

test "int":
  let val = testEcho(uint32(6))
  check val.kind == dtUint32
  check val.asNative(uint32) == 6

test "arrays":
  let val = testEcho(@["a", "b"])
  check val.kind == dtArray
  check val.arrayValue[0].asNative(string) == "a"
  check val.arrayValue[1].asNative(string) == "b"

test "variant":
  let val = testEcho(newVariant("hi"))
  check val.variantType.kind == dtString
  check val.variantValue.asNative(string) == "hi"

test "struct":
  let val = testEcho(DbusValue(kind: dtStruct, structValues: @[
    "hi".asDbusValue(),
    uint32(2).asDbusValue(),
  ]))
  check val.kind == dtStruct
  check val.structValues.len == 2
  check val.structValues[0].asNative(string) == "hi"
  check val.structValues[1].asNative(uint32) == 2

test "tables":
  let val = testEcho({"a":"b"}.toTable())
  check val.kind == dtArray
  check val.arrayValueType.kind == dtDictEntry
  check val.arrayValue[0].dictKey.asNative(string) == "a"
  check val.arrayValue[0].dictValue.asNative(string) == "b"

test "tables nested":
  let val = testEcho({
    "a": newVariant({
      "c":"d"
    }.toTable())
  }.toTable())
  check val.kind == dtArray
  check val.arrayValue[0].dictKey.asNative(string) == "a"
  check val.arrayValue[0].dictValue.variantValue.arrayValue[0].dictKey.asNative(string) == "c"
  check val.arrayValue[0].dictValue.variantValue.arrayValue[0].dictValue.asNative(string) == "d"

test "tables mixed variant":
  let var1 = newVariant("foo").asDbusValue()
  let var2 = newVariant(12.uint32).asDbusValue()
  var dict = DbusValue(
    kind: dtArray,
    arrayValueType: DbusType(
      kind: dtDictEntry,
      keyType: dtString,
      valueType: dtVariant,
    )
  )
  dict.add("a".asDbusValue(), var1)
  dict.add("b".asDbusValue(), var2)
  let val = testEcho(dict)
  check val.kind == dtArray
  check val.arrayValue[0].dictKey.asNative(string) == "a"
  check val.arrayValue[0].dictValue.variantValue.asNative(string) == "foo"
  check val.arrayValue[1].dictKey.asNative(string) == "b"
  check val.arrayValue[1].dictValue.variantValue.asNative(uint32) == 12

test "tables mixed variant":
  # TODO: make a nicer syntax for this
  var outer = DbusValue(
    kind: dtArray,
    arrayValueType: DbusType(
      kind: dtDictEntry,
      keyType: dtString,
      valueType: dtVariant,
    )
  )
  var inner = DbusValue(
    kind: dtArray,
    arrayValueType: DbusType(
      kind: dtDictEntry,
      keyType: dtString,
      valueType: dtString,
    )
  )
  outer.add("a".asDbusValue(), newVariant("foo").asDbusValue())
  inner.add("c".asDbusValue(), "d".asDbusValue())
  outer.add("b".asDbusValue(), newVariant(inner).asDbusValue())
  let val = testEcho(outer)
  check val.kind == dtArray
  check val.arrayValue[0].dictKey.asNative(string) == "a"
  check val.arrayValue[0].dictValue.variantValue.asNative(string) == "foo"
  check val.arrayValue[1].dictKey.asNative(string) == "b"
  check val.arrayValue[1].dictValue.variantValue.arrayValue[0].dictKey.asNative(string) == "c"
  check val.arrayValue[1].dictValue.variantValue.arrayValue[0].dictValue.asNative(string) == "d"

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
  msg.append({"urgency": newVariant(1'u8)}.toTable)
  msg.append(-1'i32)

  let pending = bus.sendMessage(msg)

