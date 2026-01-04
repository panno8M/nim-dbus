import dbus/lowlevel
import dbus/middlelevel {.all.}
import dbus/errors
import dbus/signatures
import dbus/variants

import std/[sequtils, strutils, macros, importutils]

iterator iterate*(msg: Message): (int, MessageIter) =
  let iter = newMessageIter(msg)
  var i: int
  yield (i, iter)
  while iter.next:
    inc i
    yield (i, iter)

iterator iterate*(iter: MessageIter): (int, MessageIter) =
  let subiter = iter.recurse
  var i: int
  yield (i, subiter)
  while subiter.next:
    inc i
    yield (i, subiter)

proc `[]`*(iter: MessageIter; _: typedesc[bool]): bool
proc `[]`*(iter: MessageIter; _: typedesc[byte]): byte
proc `[]`*(iter: MessageIter; _: typedesc[int16]): int16
proc `[]`*(iter: MessageIter; _: typedesc[uint16]): uint16
proc `[]`*(iter: MessageIter; _: typedesc[int32]): int32
proc `[]`*(iter: MessageIter; _: typedesc[uint32]): uint32
proc `[]`*(iter: MessageIter; _: typedesc[int64]): int64
proc `[]`*(iter: MessageIter; _: typedesc[uint64]): uint64
proc `[]`*(iter: MessageIter; _: typedesc[float64]): float64
proc `[]`*(iter: MessageIter; _: typedesc[FD]): FD
proc `[]`*(iter: MessageIter; _: typedesc[string]): string
proc `[]`*(iter: MessageIter; _: typedesc[ObjectPath]): ObjectPath
proc `[]`*(iter: MessageIter; _: typedesc[Signature]): Signature
proc `[]`*(iter: MessageIter; _: typedesc[DictEntryData]): DictEntryData
proc `[]`*[T](iter: MessageIter; _: typedesc[seq[T]]): seq[T]
proc `[]`*(iter: MessageIter; _: typedesc[ArrayData]): ArrayData
proc `[]`*(iter: MessageIter; _: typedesc[Variant]): Variant

proc `[]`*(msg: Message; i: int): MessageIter =
  for j, iter in msg.iterate:
    if i == j: return iter

proc `[]`*(iter: MessageIter; i: int): MessageIter =
  for j, subiter in iter.iterate:
    if i == j: return subiter

proc `[]`*(iter: MessageIter; _: typedesc[bool]): bool =
  var b: dbus_bool_t
  iter.getBasic(addr b)
  bool(b)

proc `[]`*(iter: MessageIter; _: typedesc[byte]): byte =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[int16]): int16 =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[uint16]): uint16 =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[int32]): int32 =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[uint32]): uint32 =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[int64]): int64 =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[uint64]): uint64 =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[float64]): float64 =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[FD]): FD =
  iter.getBasic(addr result)

proc `[]`*(iter: MessageIter; _: typedesc[string]): string =
  var s: cstring
  iter.getBasic(addr s)
  $s

proc `[]`*(iter: MessageIter; _: typedesc[ObjectPath]): ObjectPath =
  ObjectPath(iter[string])

proc `[]`*(iter: MessageIter; _: typedesc[Signature]): Signature =
  Signature(iter[string])

proc `[]`*[A, B](iter: MessageIter; _: typedesc[(A, B)]): (A, B) =
  var subiter = iter.recurse
  result[0] = subiter[A]
  if not next subiter: return
  result[1] = subiter[B]

proc `[]`*(iter: MessageIter; _: typedesc[DictEntryData]): DictEntryData =
  var items: seq[tuple[sig: Signature, item: Variant]]
  for i, subiter in iter.iterate:
    items.add (subiter.getSignature, subiter[Variant])
  DictEntryData(
    typ: (items[0].sig, items[1].sig),
    value: (items[0].item, items[1].item),
  )

proc `[]`*[T](iter: MessageIter; _: typedesc[seq[T]]): seq[T] =
  let count = iter.elementCount
  if count == 0: return
  result = newSeqOfCap[T](count)
  for i, subiter in iter.iterate:
    result.add subiter[T]

proc `[]`*(iter: MessageIter; _: typedesc[ArrayData]): ArrayData =
  ArrayData(
    typ: Signature(string(iter.getSignature)[1..^1]),
    values: iter[seq[Variant]],
  )

proc `[]`*(iter: MessageIter; _: typedesc[Variant]): Variant =
  privateAccess Variant
  let kind = iter.getSignature.code
  case kind:
  of scNull:
    raise newException(DbusException, "cannot unpack null value")
  of scBool:
    return newVariant(iter[bool])
  of scByte:
    return newVariant(iter[byte])
  of scInt16:
    return newVariant(iter[int16])
  of scUint16:
    return newVariant(iter[uint16])
  of scInt32:
    return newVariant(iter[int32])
  of scUint32:
    return newVariant(iter[uint32])
  of scInt64:
    return newVariant(iter[int64])
  of scUint64:
    return newVariant(iter[uint64])
  of scDouble:
    return newVariant(iter[float64])
  of scUnixFd:
    return newVariant(iter[FD])
  of scString:
    return newVariant(iter[string])
  of scObjectPath:
    return newVariant(iter[ObjectPath])
  of scSignature:
    return newVariant(iter[Signature])
  of scDictEntry:
    return newVariant(iter[DictEntryData])
  of scArray:
    return newVariant(iter[ArrayData])
  of scStruct:
    var items: seq[Variant]
    for i, subiter in iter.iterate:
      items.add subiter[Variant]
    return Variant(
      typ: Signature("(" & items.mapIt(string(it.typ)).join("") & ")"),
      data: VariantData(struct: items)
    )
  of scVariant:
    return iter.recurse[Variant]

proc deserialize*[T: MethodArgs](msg: Message; Args: typedesc[T]): T =
  var iter = newMessageIter(msg)
  for field in result.fields:
    field = iter[typeof(field)]
    if not next iter:
      return

proc deserialize*[T: MethodArgs](msg: Message; Args: typedesc[ref T]): ref T =
  new result
  result[] = msg.deserialize(T)
