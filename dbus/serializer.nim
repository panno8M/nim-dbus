import dbus/lowlevel
import dbus/middlelevel {.all.}

import dbus/errors
import dbus/signatures
import dbus/variants

import std/[importutils]
privateAccess Variant

proc appendElement(iter: MessageIter; sign: Signature; x: Variant)

template withContainer(iter: MessageIter; subIter; code: SigCode; sig: Signature; body) =
  var subIter {.inject.} = iter.openContainer(code, sig)
  body
  closeContainer subIter

proc append*(iter: MessageIter, data: ArrayData) =
  iter.withContainer(subIter, scArray, data.typ):
    for item in data.values:
      subIter.appendElement(data.typ, item)

proc append*(iter: MessageIter; data: DictEntryData) =
  iter.withContainer(subIter, scDictEntry, Signature""):
    subIter.appendElement(data.typ.key, data.value.key)
    subIter.appendElement(data.typ.value, data.value.value)

proc appendStruct(iter: MessageIter, arr: openarray[Variant]) =
  iter.withContainer(subIter, scStruct, Signature""):
    for item in arr:
      subIter.appendElement(item.typ, item)

proc append*(iter: MessageIter; x: bool) =
  var val = dbus_bool_t(x)
  iter.appendBasic(scBool, addr val)

proc append*(iter: MessageIter; x: byte) =
  iter.appendBasic(scByte, addr x)

proc append*(iter: MessageIter; x: int16) =
  iter.appendBasic(scInt16, addr x)

proc append*(iter: MessageIter; x: uint16) =
  iter.appendBasic(scUint16, addr x)

proc append*(iter: MessageIter; x: int32) =
  iter.appendBasic(scInt32, addr x)

proc append*(iter: MessageIter; x: uint32) =
  iter.appendBasic(scUint32, addr x)

proc append*(iter: MessageIter; x: int64) =
  iter.appendBasic(scInt64, addr x)

proc append*(iter: MessageIter; x: uint64) =
  iter.appendBasic(scUint64, addr x)

proc append*(iter: MessageIter; x: float64) =
  iter.appendBasic(scDouble, addr x)

proc append*(iter: MessageIter; x: FD) =
  iter.appendBasic(scUnixFd, addr x)

proc append*(iter: MessageIter; x: string) =
  var str = cstring(x)
  iter.appendBasic(scString, addr str)

proc append*(iter: MessageIter; x: ObjectPath) =
  var str = cstring(x)
  iter.appendBasic(scObjectPath, addr str)

proc append*(iter: MessageIter; x: Signature) =
  var str = cstring(x)
  iter.appendBasic(scSignature, addr str)

proc append*[T](iter: MessageIter; x: seq[T]) =
  iter.append newArrayData(x)

proc append*(iter: MessageIter, val: Variant) =
  iter.withContainer(subIter, scVariant, signatureOf(val)):
    subIter.appendElement(val.typ, val)

proc appendElement(iter: MessageIter; sign: Signature; x: Variant) =
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
  newMessageIterAppend(msg).append(x)

proc serialize*[T: MethodArgs](msg: Message; args: T) =
  var iter = newMessageIterAppend(msg)
  for field in args.fields:
    iter.append(field)