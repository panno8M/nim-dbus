
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

proc asNative*(value: Variant; native: typedesc[Variant]): Variant =
  value

proc asNative*(value: Variant, native: typedesc[bool]): bool =
  value.data.bool

proc asNative*(value: Variant, native: typedesc[float64]): float64 =
  value.data.float64

proc asNative*(value: Variant, native: typedesc[int16]): int16 =
  value.data.int16

proc asNative*(value: Variant, native: typedesc[int32]): int32 =
  value.data.int32

proc asNative*(value: Variant, native: typedesc[int64]): int64 =
  value.data.int64

proc asNative*(value: Variant, native: typedesc[uint16]): uint16 =
  value.data.uint16

proc asNative*(value: Variant, native: typedesc[uint32]): uint32 =
  value.data.uint32

proc asNative*(value: Variant, native: typedesc[uint64]): uint64 =
  value.data.uint64

proc asNative*(value: Variant, native: typedesc[uint8]): uint8 =
  value.data.byte

proc asNative*(value: Variant, native: typedesc[string]): string =
  value.data.string

proc asNative*(value: Variant, native: typedesc[ObjectPath]): ObjectPath =
  value.data.ObjectPath

proc asNative*(value: Variant, native: typedesc[Signature]): Signature =
  value.data.Signature

proc asNative*(value: Variant; native: typedesc[FD]): FD =
  value.data.FD

proc asNative*(value: Variant; native: typedesc[seq[Variant]]): seq[Variant] =
  value.data.array.values

proc asNative*[T](value: Variant, native: typedesc[seq[T]]): seq[T] =
  value.data.array.values.mapIt(asNative(it, T))

proc asNative*(value: Variant, native: typedesc[(Variant, Variant)]): tuple[key: Variant, value: Variant] =
  value.data.dictEntry

proc asNative*[T, K](value: Variant, native: typedesc[(T, K)]): tuple[key: T, value: K] =
  let (key, value) = value.data.dictEntry
  (asNative(key, T), asNative(value, K))
