
type
  MessageObj* = object of RootObj
    raw: ptr DBusMessage

  Message* = ref MessageObj
  MethodCallMessage* = ref object of Message
  MethodReturnMessage* = ref object of Message
  ErrorMessage* = ref object of Message
  SignalMessage* = ref object of Message

  MessageType* = enum
    mtInvalid = 0, mtMethodCall = 1, mtMethodReturn = 2,
    mtError = 3, mtSignal = 4

proc `=destroy`*(a: MessageObj) =
  if a.raw.isNil: return
  dbus_message_unref(a.raw)
proc `=copy`*(a: var MessageObj; b: MessageObj) =
  `=destroy` a
  wasMoved a
  a.raw = dbus_message_ref(b.raw)

proc newSignalMessage*(path: string, iface: string, name: string): SignalMessage =
  SignalMessage(raw: dbus_message_new_signal(path, iface, name))

proc newMethodCallMessage*(uniqueName: string, path: ObjectPath, iface: string, name: string): MethodCallMessage =
  MethodCallMessage(raw: dbus_message_new_method_call(uniqueName, path.string.cstring, iface, name))

proc newMethodReturnMessage*(methodCall: MethodCallMessage): MethodReturnMessage =
  MethodReturnMessage(raw: dbus_message_new_method_return(methodCall.raw))

proc newErrorMessage*(methodCall: MethodCallMessage; name: string; message: string): ErrorMessage =
  ErrorMessage(raw: dbus_message_new_error(methodCall.raw, cstring(name), cstring(message)))

proc type*(msg: ptr DBusMessage): MessageType =
  if msg.isNil:
    mtInvalid
  else:
    MessageType(dbus_message_get_type(msg))
proc type*(msg: Message): MessageType =
  msg.raw.type

proc name*(msg: ErrorMessage): string =
  $dbus_message_get_error_name(msg.raw)

proc message*(msg: ErrorMessage): string =
  var error: DBusError
  doAssert(dbus_set_error_from_message(addr error, msg.raw))
  defer: dbus_error_free(addr error)
  return $error.message

proc send*(conn: Bus, msg: Message): dbus_uint32_t {.discardable.} =
  if not bool(dbus_connection_send(conn.conn, msg.raw, addr result)):
      raise newException(DbusException, "dbus_connection_send")

type PendingCall* = object
  call: ptr DBusPendingCall
  bus: Bus

proc sendWithReply*(bus: Bus, msg: Message): PendingCall =
  result.bus = bus
  if not bool(dbus_connection_send_with_reply(bus.conn, msg.raw, addr result.call, -1)):
    raise newException(DbusException, "dbus_connection_send_with_reply")
  if result.call == nil:
    raise newException(DbusException, "pending call still nil")

# Serialization
proc initIter*(msg: Message): DbusMessageIter =
  dbus_message_iter_init_append(msg.raw, addr result)

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
  iter.append newArrayData(x)

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
