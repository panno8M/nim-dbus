

proc raiseIfError*(msg: Message) =
  if msg of ErrorMessage:
    let err = ErrorMessage(msg)
    raise newException(DbusRemoteException, err.name & ": " & err.message)

proc waitForReply*(call: PendingCall): Message =
  call.bus.flush()
  dbus_pending_callblock(call.call)
  var msg = dbus_pending_call_steal_reply(call.call)
  result = newMessage(msg)

  defer: dbus_pending_call_unref(call.call)

iterator iterate*(msg: Message): (int, ptr DbusMessageIter) =
  var iter = new DbusMessageIter
  var i: int
  if dbus_message_iter_init(msg.raw, addr iter[]) == 0:
    raise newException(DbusException, "dbus_message_iter_init")
  yield (i, addr iter[])
  while dbus_message_iter_next(addr iter[]):
    inc i
    yield (i, addr iter[])

iterator iterate*(iter: ptr DbusMessageIter): (int, ptr DbusMessageIter) =
  var subiter = new DbusMessageIter
  var i: int
  dbus_message_iter_recurse(iter, addr subiter[])
  yield (i, addr subiter[])
  while dbus_message_iter_next(addr subiter[]):
    inc i
    yield (i, addr subiter[])

proc sign(iter: ptr DbusMessageIter): Signature =
  let cs = dbus_message_iter_get_signature(iter)
  result = Signature($cs)
  dbus_free(cs)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[bool]): bool =
  var b: dbus_bool_t
  dbus_message_iter_get_basic(iter, addr b)
  bool(b)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[byte]): byte =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[int16]): int16 =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[uint16]): uint16 =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[int32]): int32 =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[uint32]): uint32 =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[int64]): int64 =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[uint64]): uint64 =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[float64]): float64 =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[FD]): FD =
  dbus_message_iter_get_basic(iter, addr result)

proc decode*(iter: ptr DbusMessageIter; _: typedesc[string]): string =
  var s: cstring
  dbus_message_iter_get_basic(iter, addr s)
  $s

proc decode*(iter: ptr DbusMessageIter; _: typedesc[ObjectPath]): ObjectPath =
  ObjectPath(iter.decode(string))

proc decode*(iter: ptr DbusMessageIter; _: typedesc[Signature]): Signature =
  Signature(iter.decode(string))

proc decode*(iter: ptr DbusMessageIter; _: typedesc[DictEntryData]): DictEntryData =
  var items: seq[tuple[sig: Signature, item: Variant]]
  for i, subiter in iter.iterate:
    items.add (subiter.sign, subiter.decode(Variant))
  DictEntryData(
    typ: (items[0].sig, items[1].sig),
    value: (items[0].item, items[1].item),
  )

proc decode*(iter: ptr DbusMessageIter; _: typedesc[ArrayData]): ArrayData =
  var items: seq[Variant]
  for i, subiter in iter.iterate:
    items.add subiter.decode(Variant)
  ArrayData(
    typ: Signature(string(iter.sign)[1..^1]),
    values: items,
  )

proc decode*(iter: ptr DbusMessageIter; _: typedesc[Variant]): Variant =
  let kind = dbus_message_iter_get_arg_type(iter).char.code
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
