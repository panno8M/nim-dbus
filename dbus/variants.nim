import dbus/types {.all.}
import std/importutils

privateAccess Variant

import std/[sequtils, macros]

func `==`*(a, b: Variant): bool =
  if a.typ == b.typ:
    if a.data != nil:
      case a.typ.code
      of scNull, scVariant:
        true
      of scBool:
        a.data.bool == b.data.bool
      of scByte:
        a.data.byte == b.data.byte
      of scInt16:
        a.data.int16 == b.data.int16
      of scUint16:
        a.data.uint16 == b.data.uint16
      of scInt32:
        a.data.int32 == b.data.int32
      of scUint32:
        a.data.uint32 == b.data.uint32
      of scInt64:
        a.data.int64 == b.data.int64
      of scUint64:
        a.data.uint64 == b.data.uint64
      of scDouble:
        a.data.float64 == b.data.float64
      of scUnixFd:
        a.data.FD == b.data.FD
      of scString:
        a.data.string == b.data.string
      of scObjectPath:
        a.data.ObjectPath == b.data.ObjectPath
      of scSignature:
        a.data.Signature == b.data.Signature
      of scArray:
        a.data.array == b.data.array
      of scDictEntry:
        a.data.dictEntry == b.data.dictEntry
      of scStruct:
        a.data.struct == b.data.struct
    else:
      false
  else:
    false

proc `$`*(val: Variant): string =
  case val.typ.code
  of scNull, scVariant:
    result.add("<null>")
  of scArray:
    result.add($val.data.array)
  of scBool:
    result.add($val.data.bool)
  of scDictEntry:
    result.add($val.data.dictEntry.value.key & ':' & $val.data.dictEntry.value.value)
  of scDouble:
    result.add($val.data.float64)
  of scSignature:
    result.add(val.data.Signature.string)
  of scUnixFd:
    result.add($val.data.FD)
  of scInt32:
    result.add($val.data.int32)
  of scInt16:
    result.add($val.data.int16)
  of scObjectPath:
    result.add(val.data.ObjectPath.string)
  of scUint16:
    result.add($val.data.uint16)
  of scString:
    result.add(val.data.string)
  of scStruct:
    result.add($val.data.struct)
  of scUint64:
    result.add($val.data.uint64)
  of scUint32:
    result.add($val.data.uint32)
  of scInt64:
    result.add($val.data.int64)
  of scByte:
    result.add($val.data.byte)

proc signatureOf*(v: Variant): Signature =
  v.typ

proc newVariant*(value: byte): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(byte: value)
  )

proc newVariant*(value: bool): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(bool: value)
  )

proc newVariant*(value: int16): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(int16: value)
  )

proc newVariant*(value: uint16): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(uint16: value)
  )

proc newVariant*(value: int32): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(int32: value)
  )

proc newVariant*(value: uint32): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(uint32: value)
  )

proc newVariant*(value: int64): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(int64: value)
  )

proc newVariant*(value: uint64): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(uint64: value)
  )

proc newVariant*(value: float64): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(float64: value)
  )
proc newVariant*(value: float32): Variant =
  newVariant(float64(value))

proc newVariant*(value: FD): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(FD: value)
  )

proc newVariant*(value: string): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(string: value)
  )
proc newVariant*(value: cstring): Variant =
  newVariant($value)

proc newVariant*(value: ObjectPath): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(ObjectPath: value)
  )

proc newVariant*(value: Signature): Variant =
  Variant(
    typ: encode(value),
    data: VariantData(Signature: value)
  )

proc newVariant*(value: Variant): Variant =
  value

proc newVariant*(value: ArrayData): Variant =
  Variant(
    typ: encodeArray(value.typ),
    data: VariantData(array: value),
  )

proc newVariant*(value: DictEntryData): Variant =
  Variant(
    typ: encodeDictEntry(value.typ.key, value.typ.value),
    data: VariantData(dictEntry: value),
  )

proc newArrayData*[T](s: openArray[T]): ArrayData
proc newVariant*[T](value: openArray[T]): Variant =
  newVariant(newArrayData(value))

proc newDictEntryData*[K, V](value: (K, V)): DictEntryData
proc newVariant*[K, V](value: (K, V)): Variant =
  newVariant(newDictEntryData(value))

proc newArrayData*[T](s: openArray[T]): ArrayData =
  ArrayData(
    typ: encode(T),
    values: s.map(newVariant)
  )

proc newDictEntryData*[K, V](value: (K, V)): DictEntryData =
  DictEntryData(
    typ: (encode(K), encode(V)),
    value: (newVariant(value[0]), newVariant(value[1]))
  )

proc `[]`*(value: Variant; native: typedesc[Variant]): Variant =
  value

proc `[]`*(value: Variant, native: typedesc[bool]): bool =
  value.data.bool

proc `[]`*(value: Variant, native: typedesc[float64]): float64 =
  value.data.float64

proc `[]`*(value: Variant, native: typedesc[int16]): int16 =
  value.data.int16

proc `[]`*(value: Variant, native: typedesc[int32]): int32 =
  value.data.int32

proc `[]`*(value: Variant, native: typedesc[int64]): int64 =
  value.data.int64

proc `[]`*(value: Variant, native: typedesc[uint16]): uint16 =
  value.data.uint16

proc `[]`*(value: Variant, native: typedesc[uint32]): uint32 =
  value.data.uint32

proc `[]`*(value: Variant, native: typedesc[uint64]): uint64 =
  value.data.uint64

proc `[]`*(value: Variant, native: typedesc[uint8]): uint8 =
  value.data.byte

proc `[]`*(value: Variant, native: typedesc[string]): string =
  value.data.string

proc `[]`*(value: Variant, native: typedesc[ObjectPath]): ObjectPath =
  value.data.ObjectPath

proc `[]`*(value: Variant, native: typedesc[Signature]): Signature =
  value.data.Signature

proc `[]`*(value: Variant; native: typedesc[FD]): FD =
  value.data.FD

proc `[]`*(value: Variant; native: typedesc[seq[Variant]]): seq[Variant] =
  value.data.array.values

proc `[]`*[T](value: Variant, native: typedesc[seq[T]]): seq[T] =
  value.data.array.values.mapIt(it.`[]`(T))

proc `[]`*(value: Variant, native: typedesc[(Variant, Variant)]): tuple[key: Variant, value: Variant] =
  value.data.dictEntry

proc `[]`*[T, K](value: Variant, native: typedesc[(T, K)]): tuple[key: T, value: K] =
  let (key, value) = value.data.dictEntry.value
  (key[T], value[K])
