

proc raiseIfError*(msg: Message) =
  if msg of ErrorMessage:
    let err = ErrorMessage(msg)
    raise newException(DbusRemoteException, err.name & ": " & err.message)

proc waitForReply*(call: PendingCall): Message =
  call.bus.flush()
  dbus_pending_callblock(call.call)
  var msg = dbus_pending_call_steal_reply(call.call)
  result = case msg.type
  of mtMethodCall:
    MethodCallMessage(raw: msg)
  of mtMethodReturn:
    MethodReturnMessage(raw: msg)
  of mtError:
    ErrorMessage(raw: msg)
  of mtSignal:
    SignalMessage(raw: msg)
  of mtInvalid:
    raise newException(DbusException, "dbus_pending_call_steal_reply")

  defer: dbus_pending_call_unref(call.call)

type InputIter* = object
  iter: DbusMessageIter

proc iterate*(msg: Message): InputIter =
  if dbus_message_iter_init(msg.raw, addr result.iter) == 0:
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

proc decode*(iter: var InputIter; _: typedesc[bool]): bool =
  var b: dbus_bool_t
  dbus_message_iter_get_basic(addr iter.iter, addr b)
  bool(b)

proc decode*(iter: var InputIter; _: typedesc[byte]): byte =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[int16]): int16 =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[uint16]): uint16 =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[int32]): int32 =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[uint32]): uint32 =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[int64]): int64 =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[uint64]): uint64 =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[float64]): float64 =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[FD]): FD =
  dbus_message_iter_get_basic(addr iter.iter, addr result)

proc decode*(iter: var InputIter; _: typedesc[string]): string =
  var s: cstring
  dbus_message_iter_get_basic(addr iter.iter, addr s)
  $s

proc decode*(iter: var InputIter; _: typedesc[ObjectPath]): ObjectPath =
  ObjectPath(iter.decode(string))

proc decode*(iter: var InputIter; _: typedesc[Signature]): Signature =
  Signature(iter.decode(string))

proc decode*(iter: var InputIter; _: typedesc[DictEntryData]): DictEntryData =
  var subiter = iter.subIterate()
  let key = subiter.decode(Variant)
  let keysign = subiter.sign
  subiter.advanceIter()
  let val = subiter.decode(Variant)
  let valsign = subiter.sign
  subiter.ensureEnd()
  DictEntryData(
    typ: (keysign, valsign),
    value: (key, val),
  )

proc decode*(iter: var InputIter; _: typedesc[ArrayData]): ArrayData =
  var subiter = iter.subIterate()
  var subsign = subiter.sign
  var values: seq[Variant]
  while true:
    values.add(subiter.decode(Variant))
    if dbus_message_iter_has_next(addr subiter.iter) == 0:
      break
    subiter.advanceIter()
  ArrayData(
    typ: subsign,
    values: values,
  )

proc decode*(iter: var InputIter; _: typedesc[Variant]): Variant =
  let kind = dbus_message_iter_get_arg_type(addr iter.iter).char.code
  case kind:
  of scNull:
    raise newException(DbusException, "cannot unpack null value")
  of scBool:
    return newVariant(iter.decode(bool))
  of scByte:
    return newVariant(iter.decode(byte))
  of scInt16:
    return newVariant(iter.decode(int16))
  of scUint16:
    return newVariant(iter.decode(uint16))
  of scInt32:
    return newVariant(iter.decode(int32))
  of scUint32:
    return newVariant(iter.decode(uint32))
  of scInt64:
    return newVariant(iter.decode(int64))
  of scUint64:
    return newVariant(iter.decode(uint64))
  of scDouble:
    return newVariant(iter.decode(float64))
  of scUnixFd:
    return newVariant(iter.decode(FD))
  of scString:
    return newVariant(iter.decode(string))
  of scObjectPath:
    return newVariant(iter.decode(ObjectPath))
  of scSignature:
    return newVariant(iter.decode(Signature))
  of scDictEntry:
    return newVariant(iter.decode(DictEntryData))
  of scArray:
    return newVariant(iter.decode(ArrayData))
  of scStruct:
    var subiter = iter.subIterate()
    var values:seq[Variant]
    while true:
      values.add(subiter.decode(Variant))
      if dbus_message_iter_has_next(addr subiter.iter) == 0:
        break
      subiter.advanceIter()
    return Variant(
      typ: Signature("(" & values.mapIt(string(it.typ)).join("") & ")"),
      data: VariantData(struct: values)
    )
  of scVariant:
    var subiter = iter.subIterate()
    let val = subiter.decode(Variant)
    subiter.ensureEnd()
    return val
