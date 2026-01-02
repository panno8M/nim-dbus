

proc raiseIfError*(msg: Message) =
  if msg of ErrorMessage:
    DbusRemoteException.liftDbusError(err):
      err = ErrorMessage(msg).getError

proc waitForReply*(call: PendingCall): Message =
  call.bus.flush()
  dbus_pending_callblock(call.call)
  var msg = dbus_pending_call_steal_reply(call.call)
  result = newMessage(msg)

  defer: dbus_pending_call_unref(call.call)

iterator iterate*(msg: Message): (int, ref DbusMessageIter) =
  var iter = new DbusMessageIter
  var i: int
  if dbus_message_iter_init(msg.raw, addr iter[]) == 0:
    raise newException(DbusException, "dbus_message_iter_init")
  yield (i, iter)
  while dbus_message_iter_next(addr iter[]) != 0:
    inc i
    yield (i, iter)

iterator iterate*(iter: ref DbusMessageIter): (int, ref DbusMessageIter) =
  var subiter = new DbusMessageIter
  var i: int
  dbus_message_iter_recurse(addr iter[], addr subiter[])
  yield (i, subiter)
  while dbus_message_iter_next(addr subiter[]) != 0:
    inc i
    yield (i, subiter)

proc `[]`*(msg: Message; i: int): ref DbusMessageIter =
  for j, iter in msg.iterate:
    if i == j: return iter

proc `[]`*(iter: ref DbusMessageIter; i: int): ref DbusMessageIter =
  for j, subiter in iter.iterate:
    if i == j: return subiter

proc sign(iter: ref DbusMessageIter): Signature =
  let cs = dbus_message_iter_get_signature(addr iter[])
  result = Signature($cs)
  dbus_free(cs)

proc decode*(iter: ref DbusMessageIter; _: typedesc[bool]): bool =
  var b: dbus_bool_t
  dbus_message_iter_get_basic(addr iter[], addr b)
  bool(b)

proc decode*(iter: ref DbusMessageIter; _: typedesc[byte]): byte =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[int16]): int16 =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[uint16]): uint16 =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[int32]): int32 =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[uint32]): uint32 =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[int64]): int64 =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[uint64]): uint64 =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[float64]): float64 =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[FD]): FD =
  dbus_message_iter_get_basic(addr iter[], addr result)

proc decode*(iter: ref DbusMessageIter; _: typedesc[string]): string =
  var s: cstring
  dbus_message_iter_get_basic(addr iter[], addr s)
  $s

proc decode*(iter: ref DbusMessageIter; _: typedesc[ObjectPath]): ObjectPath =
  ObjectPath(iter.decode(string))

proc decode*(iter: ref DbusMessageIter; _: typedesc[Signature]): Signature =
  Signature(iter.decode(string))

proc decode*(iter: ref DbusMessageIter; _: typedesc[DictEntryData]): DictEntryData =
  var items: seq[tuple[sig: Signature, item: Variant]]
  for i, subiter in iter.iterate:
    items.add (subiter.sign, subiter.decode(Variant))
  DictEntryData(
    typ: (items[0].sig, items[1].sig),
    value: (items[0].item, items[1].item),
  )

proc decode*(iter: ref DbusMessageIter; _: typedesc[ArrayData]): ArrayData =
  var items: seq[Variant]
  for i, subiter in iter.iterate:
    items.add subiter.decode(Variant)
  ArrayData(
    typ: Signature(string(iter.sign)[1..^1]),
    values: items,
  )

proc decode*(iter: ref DbusMessageIter; _: typedesc[Variant]): Variant =
  let kind = dbus_message_iter_get_arg_type(addr iter[]).char.code
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
    var items: seq[Variant]
    for i, subiter in iter.iterate:
      items.add subiter.decode(Variant)
    return Variant(
      typ: Signature("(" & items.mapIt(string(it.typ)).join("") & ")"),
      data: VariantData(struct: items)
    )
  of scVariant:
    var item: Variant
    for i, subiter in iter.iterate:
      item = subiter.decode(Variant)
    return item
