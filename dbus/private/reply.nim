
type Reply* = object
  msg: ptr DBusMessage

type ReplyType* = enum
  rtInvalid = 0, rtMethodCall = 1, rtMethodReturn = 2,
  rtError = 3, rtSignal = 4

proc replyFromMessage*(msg: ptr DbusMessage): Reply =
  result.msg = msg

proc type*(reply: Reply): ReplyType =
  return dbus_message_get_type(reply.msg).ReplyType

proc errorName*(reply: Reply): string =
  return $dbus_message_get_error_name(reply.msg)

proc errorMessage*(reply: Reply): string =
  var error: DBusError
  doAssert(dbus_set_error_from_message(addr error, reply.msg))
  defer: dbus_error_free(addr error)
  return $error.message

proc raiseIfError*(reply: Reply) =
  if reply.type == rtError:
    raise newException(DbusRemoteException, reply.errorName & ": " & reply.errorMessage)

proc waitForReply*(call: PendingCall): Reply =
  call.bus.flush()
  dbus_pending_callblock(call.call)
  result.msg = dbus_pending_call_steal_reply(call.call)

  defer: dbus_pending_call_unref(call.call)

  if result.msg == nil:
    raise newException(DbusException, "dbus_pending_call_steal_reply")

proc close*(reply: Reply) =
  dbus_message_unref(reply.msg)

type InputIter* = object
  iter: DbusMessageIter

proc iterate*(reply: Reply): InputIter =
  if dbus_message_iter_init(reply.msg, addr result.iter) == 0:
    raise newException(DbusException, "dbus_message_iter_init")

proc advanceIter*(iter: var InputIter) =
  if dbus_message_iter_next(addr iter.iter) == 0:
    raise newException(DbusException, "cannot advance iterator")

proc ensureEnd*(iter: var InputIter) =
  if dbus_message_iter_next(addr iter.iter) != 0:
    raise newException(DbusException, "got more arguments than expected")

proc subIterate*(iter: var InputIter): InputIter =
  # from https://leonardoce.wordpress.com/2015/03/17/dbus-tutorial-part-3/
  dbus_message_iter_recurse(addr iter.iter, addr result.iter)

proc sign(iter: var InputIter): Signature =
  let cs = dbus_message_iter_get_signature(addr iter.iter)
  result = Signature($cs)
  dbus_free(cs)

proc unpackCurrent(iter: var InputIter): Variant =
  let kind = dbus_message_iter_get_arg_type(addr iter.iter).char.code
  case kind:
  of scNull:
    raise newException(DbusException, "cannot unpack null value")
  of scBool:
    var b: dbus_bool_t
    dbus_message_iter_get_basic(addr iter.iter, addr b)
    return newVariant(bool b)
  of scByte:
    var b: byte
    dbus_message_iter_get_basic(addr iter.iter, addr b)
    return newVariant(b)
  of scInt16:
    var i: int16
    dbus_message_iter_get_basic(addr iter.iter, addr i)
    return newVariant(i)
  of scUint16:
    var u: uint16
    dbus_message_iter_get_basic(addr iter.iter, addr u)
    return newVariant(u)
  of scInt32:
    var i: int32
    dbus_message_iter_get_basic(addr iter.iter, addr i)
    return newVariant(i)
  of scUint32:
    var u: uint32
    dbus_message_iter_get_basic(addr iter.iter, addr u)
    return newVariant(u)
  of scInt64:
    var i: int64
    dbus_message_iter_get_basic(addr iter.iter, addr i)
    return newVariant(i)
  of scUint64:
    var u: uint64
    dbus_message_iter_get_basic(addr iter.iter, addr u)
    return newVariant(u)
  of scDouble:
    var d: float64
    dbus_message_iter_get_basic(addr iter.iter, addr d)
    return newVariant(d)
  of scUnixFd:
    var fd: FD
    dbus_message_iter_get_basic(addr iter.iter, addr fd)
    return newVariant(fd)
  of scString:
    var s: cstring
    dbus_message_iter_get_basic(addr iter.iter, addr s)
    return newVariant($s)
  of scObjectPath:
    var s: cstring
    dbus_message_iter_get_basic(addr iter.iter, addr s)
    return newVariant(ObjectPath($s))
  of scSignature:
    var s: cstring
    dbus_message_iter_get_basic(addr iter.iter, addr s)
    return newVariant(Signature($s))
  of scVariant:
    var subiter = iter.subIterate()
    let val = subiter.unpackCurrent()
    subiter.ensureEnd()
    return val
  of scDictEntry:
    var subiter = iter.subIterate()
    let key = subiter.unpackCurrent()
    let keysign = subiter.sign
    subiter.advanceIter()
    let val = subiter.unpackCurrent()
    let valsign = subiter.sign
    subiter.ensureEnd()
    return newVariant(DictEntryData(
      typ: (keysign, valsign),
      value: (key, val)
    ))
  of scArray:
    var subiter = iter.subIterate()
    var subsign = subiter.sign
    var values: seq[Variant]
    while true:
      values.add(subiter.unpackCurrent())
      if dbus_message_iter_has_next(addr subiter.iter) == 0:
        break
      subiter.advanceIter()
    return newVariant(ArrayData(
      typ: subsign,
      values: values)
    )
  of scStruct:
    var subiter = iter.subIterate()
    var values:seq[Variant]
    while true:
      values.add(subiter.unpackCurrent())
      if dbus_message_iter_has_next(addr subiter.iter) == 0:
        break
      subiter.advanceIter()
    return Variant(
      typ: Signature("(" & values.mapIt(string(it.typ)).join("") & ")"),
      data: VariantData(struct: values)
    )

proc unpackCurrent*(iter: var InputIter, Expected: typedesc[Variant]): Variant =
  unpackCurrent(iter)
proc unpackCurrent*[T](iter: var InputIter, Expected: typedesc[T]): T =
  unpackCurrent(iter).decode(Expected)
