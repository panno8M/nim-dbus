
type Message* = object
  msg: ptr DBusMessage

proc makeSignal*(path: string, iface: string, name: string): Message =
  result.msg = dbus_message_new_signal(path, iface, name)

proc makeCall*(uniqueName: string, path: ObjectPath, iface: string, name: string): Message =
  result.msg = dbus_message_new_method_call(uniqueName, path.string.cstring, iface, name)

proc sendMessage*(conn: Bus, msg: var Message): dbus_uint32_t {.discardable.} =
  var serial: dbus_uint32_t
  let ret = dbus_connection_send(conn.conn, msg.msg, addr serial)
  dbus_message_unref(msg.msg)
  msg.msg = nil
  if not bool(ret):
      raise newException(DbusException, "dbus_connection_send")
  return serial

type PendingCall* = object
  call: ptr DBusPendingCall
  bus: Bus

proc sendMessageWithReply*(bus: Bus, msg: Message): PendingCall =
  result.bus = bus
  let ret = dbus_connection_send_with_reply(bus.conn, msg.msg, addr result.call, -1)
  dbus_message_unref(msg.msg)
  if not bool(ret):
    raise newException(DbusException, "dbus_connection_send_with_reply")
  if result.call == nil:
    raise newException(DbusException, "pending call still nil")

# Serialization
proc initIter*(msg: Message): DbusMessageIter =
  dbus_message_iter_init_append(msg.msg, addr result)

proc appendPtr(iter: ptr DbusMessageIter, typecode: SigCode, data: pointer) =
  if dbus_message_iter_append_basic(iter, typecode.serialize.cint, data) == 0:
      raise newException(DbusException, "append_basic")

proc appendElement(iter: ptr DbusMessageIter; sign: Signature; x: Variant)

template withContainer(iter: ptr DbusMessageIter; subIter; code: SigCode; sig: Signature; body) =
  var subIter {.inject.}: DBusMessageIter
  let p = if sig == Signature"": cstring(nil) else: cstring(sig)
  if dbus_message_iter_open_container(iter, code.serialize.cint, p, addr subIter) == 0:
    raise newException(DbusException, "open_container")
  body
  if dbus_message_iter_close_container(iter, addr subIter) == 0:
    raise newException(DbusException, "close_container")

proc append*(iter: ptr DbusMessageIter, data: ArrayData) =
  iter.withContainer(subIter, scArray, data.typ):
    for item in data.values:
      (addr subIter).appendElement(data.typ, item)

proc append*(iter: ptr DbusMessageIter; data: DictEntryData) =
  iter.withContainer(subIter, scDictEntry, Signature""):
    (addr subIter).appendElement(data.typ.key, data.value.key)
    (addr subIter).appendElement(data.typ.value, data.value.value)

proc appendStruct(iter: ptr DbusMessageIter, arr: openarray[Variant]) =
  iter.withContainer(subIter, scStruct, Signature""):
    for item in arr:
      (addr subIter).appendElement(item.typ, item)

proc append*(iter: ptr DbusMessageIter; x: bool) =
  var val = dbus_bool_t(x)
  iter.appendPtr(scBool, addr val)

proc append*(iter: ptr DbusMessageIter; x: byte) =
  iter.appendPtr(scByte, addr x)

proc append*(iter: ptr DbusMessageIter; x: int16) =
  iter.appendPtr(scInt16, addr x)

proc append*(iter: ptr DbusMessageIter; x: uint16) =
  iter.appendPtr(scUint16, addr x)

proc append*(iter: ptr DbusMessageIter; x: int32) =
  iter.appendPtr(scInt32, addr x)

proc append*(iter: ptr DbusMessageIter; x: uint32) =
  iter.appendPtr(scUint32, addr x)

proc append*(iter: ptr DbusMessageIter; x: int64) =
  iter.appendPtr(scInt64, addr x)

proc append*(iter: ptr DbusMessageIter; x: uint64) =
  iter.appendPtr(scUint64, addr x)

proc append*(iter: ptr DbusMessageIter; x: float64) =
  iter.appendPtr(scDouble, addr x)

proc append*(iter: ptr DbusMessageIter; x: FD) =
  iter.appendPtr(scUnixFd, addr x)

proc append*(iter: ptr DbusMessageIter; x: string) =
  var str = cstring(x)
  iter.appendPtr(scString, addr str)

proc append*(iter: ptr DbusMessageIter; x: ObjectPath) =
  var str = cstring(x)
  iter.appendPtr(scObjectPath, addr str)

proc append*(iter: ptr DbusMessageIter; x: Signature) =
  var str = cstring(x)
  iter.appendPtr(scSignature, addr str)

proc append*[T](iter: ptr DbusMessageIter; x: seq[T]) =
  iter.append ArrayData(
    typ: T.sign,
    values: x.map(newVariant))

proc append*(iter: ptr DbusMessageIter, val: Variant) =
  iter.withContainer(subIter, scVariant, val.typ):
    (addr subIter).appendElement(val.typ, val)

proc appendElement(iter: ptr DbusMessageIter; sign: Signature; x: Variant) =
  case sign.code:
    of scNull:
      raise newException(DbusException, "cannot append null value")
    of scBool:
      iter.append(x.data.bool)
    of scByte:
      iter.append(x.data.byte)
    of scInt16:
      iter.append(x.data.int16)
    of scUint16:
      iter.append(x.data.uint16)
    of scInt32:
      iter.append(x.data.int32)
    of scUint32:
      iter.append(x.data.uint32)
    of scInt64:
      iter.append(x.data.int64)
    of scUint64:
      iter.append(x.data.uint64)
    of scDouble:
      iter.append(x.data.float64)
    of scUnixFd:
      iter.append(x.data.FD)
    of scString:
      iter.append(x.data.string)
    of scObjectPath:
      iter.append(x.data.ObjectPath)
    of scSignature:
      iter.append(x.data.Signature)
    of scArray:
      iter.append(x.data.array)
    of scDictEntry:
      iter.append(x.data.dictEntry)
    of scStruct:
      iter.appendStruct(x.data.struct)
    of scVariant:
      iter.append(x)

proc append*[T](msg: Message, x: T) =
  var iter = initIter(msg)
  append(addr iter, x)
