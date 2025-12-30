type
  FD* = cint

  DbusValue* = ref object
    case kind*: SigCode
    of scArray:
      arrayValueType*: Signature
      arrayValue*: seq[DbusValue]
    of scBool:
      boolValue*: bool
    of scDictEntry:
      dictKey*, dictValue*: DbusValue
    of scDouble:
      doubleValue*: float64
    of scSignature:
      signatureValue*: Signature
    of scUnixFd:
      fdValue*: FD
    of scInt32:
      int32Value*: int32
    of scInt16:
      int16Value*: int16
    of scObjectPath:
      objectPathValue*: ObjectPath
    of scUint16:
      uint16Value*: uint16
    of scString:
      stringValue*: string
    of scStruct:
      structValues*: seq[DbusValue]
    of scUint64:
      uint64Value*: uint64
    of scUint32:
      uint32Value*: uint32
    of scInt64:
      int64Value*: int64
    of scByte:
      byteValue*: uint8
    of scVariant:
      variantType*: Signature
      variantValue*: DbusValue

proc `$`*(val: DbusValue): string =
  result.add("<DbusValue " & $val.kind & " ")
  case val.kind
  of scArray:
    result.add(string(val.arrayValueType) & ' ' & $val.arrayValue)
  of scBool:
    result.add($val.boolValue)
  of scDictEntry:
    result.add($val.dictKey & ' ' & $val.dictValue)
  of scDouble:
    result.add($val.doubleValue)
  of scSignature:
    result.add(val.signatureValue.string)
  of scUnixFd:
    result.add($val.fdValue)
  of scInt32:
    result.add($val.int32Value)
  of scInt16:
    result.add($val.int16Value)
  of scObjectPath:
    result.add(val.objectPathValue.string)
  of scUint16:
    result.add($val.uint16Value)
  of scString:
    result.add(val.stringValue)
  of scStruct:
    result.add($val.structValues)
  of scUint64:
    result.add($val.uint64Value)
  of scUint32:
    result.add($val.uint32Value.uint64)
  of scInt64:
    result.add($val.int64Value)
  of scByte:
    result.add($val.byteValue)
  of scVariant:
    result.add(string(val.variantType) & ' ' & $val.variantValue)
  result.add('>')

proc getPrimitive(val: DbusValue): pointer =
  case val.kind
  of scDouble:
    return addr val.doubleValue
  of scInt32:
    return addr val.int32Value
  of scInt16:
    return addr val.int16Value
  of scUint16:
    return addr val.uint16Value
  of scUint64:
    return addr val.uint64Value
  of scUint32:
    return addr val.uint32Value
  of scInt64:
    return addr val.int64Value
  of scByte:
    return addr val.byteValue
  else:
    raise newException(ValueError, "value is not primitive")

proc getString(val: DbusValue): var string =
  case val.kind
  of scString:
    return val.stringValue
  of scSignature:
    return val.signatureValue.string
  of scObjectPath:
    return val.objectPathValue.string
  else:
    raise newException(ValueError, "value is not string")

proc createStringDbusValue(kind: SigCode, val: string): DbusValue =
  case kind
  of scString:
    result = DbusValue(kind: kind, stringValue: val)
  of scSignature:
    result = DbusValue(kind: kind, signatureValue: val.Signature)
  of scObjectPath:
    result = DbusValue(kind: kind, objectPathValue: val.ObjectPath)
  else:
    raise newException(ValueError, "value is not string")

proc createScalarDbusValue(kind: SigCode): tuple[value: DbusValue, scalarPtr: pointer] =
  var value = DBusValue(kind: kind)
  (value, getPrimitive(value))

proc asDbusValue*(val: bool): DbusValue =
  DbusValue(kind: scBool, boolValue: val)

proc asDbusValue*(val: float64): DbusValue =
  DbusValue(kind: scDouble, doubleValue: val)

proc asDbusValue*(val: int16): DbusValue =
  DbusValue(kind: scInt16, int16Value: val)

proc asDbusValue*(val: int32): DbusValue =
  DbusValue(kind: scInt32, int32Value: val)

proc asDbusValue*(val: int64): DbusValue =
  DbusValue(kind: scInt64, int64Value: val)

proc asDbusValue*(val: uint16): DbusValue =
  DbusValue(kind: scUint16, uint16Value: val)

proc asDbusValue*(val: uint32): DbusValue =
  DbusValue(kind: scUint32, uint32Value: val)

proc asDbusValue*(val: uint64): DbusValue =
  DbusValue(kind: scUint64, uint64Value: val)

proc asDbusValue*(val: uint8): DbusValue =
  DbusValue(kind: scByte, byteValue: val)

proc asDbusValue*(val: string): DbusValue =
  DbusValue(kind: scString, stringValue: val)

proc asDbusValue*(val: ObjectPath): DbusValue =
  DbusValue(kind: scObjectPath, objectPathValue: val)

proc asDbusValue*(val: Signature): DbusValue =
  DbusValue(kind: scSignature, signatureValue: val)

proc asDbusValue*(val: DbusValue): DbusValue =
  val

proc sign*(val: DbusValue): Signature =
  case val.kind
  of dbusFixedTypes:
    return val.kind
  of dbusStringTypes:
    return val.kind
  of scArray:
    return initArraySignature(val.arrayValueType)
  of scDictEntry:
    return initDictEntrySignature(val.dictKey.sign, val.dictValue.sign)
  of scStruct:
    return initStructSignature(val.structValues.mapIt(it.sign))
  of scVariant:
    return val.kind

proc asDbusValue*[T](val: seq[T]): DbusValue =
  result = DbusValue(kind: scArray, arrayValueType: T.sign)
  for x in val:
    result.arrayValue.add x.asDbusValue

proc asDbusValue*[K, V](val: (K, V)): DbusValue =
  result = DbusValue(kind: scDictEntry,
    dictKey: asDbusValue(val[0]),
    dictValue: asDbusValue(val[1]))

proc asDbusValue*(val: Variant[DbusValue]): DbusValue =
  DbusValue(kind: scVariant, variantType: val.value.sign,
            variantValue: val.value)

proc asDbusValue*[T](val: Variant[T]): DbusValue =
  DbusValue(kind: scVariant, variantType: T.sign,
            variantValue: asDbusValue(val.value))

proc asNative*(value: DbusValue, native: typedesc[bool]): bool =
  value.boolValue

proc asNative*(value: DbusValue, native: typedesc[float64]): float64 =
  value.doubleValue

proc asNative*(value: DbusValue, native: typedesc[int16]): int16 =
  value.int16Value

proc asNative*(value: DbusValue, native: typedesc[int32]): int32 =
  value.int32Value

proc asNative*(value: DbusValue, native: typedesc[int64]): int64 =
  value.int64Value

proc asNative*(value: DbusValue, native: typedesc[uint16]): uint16 =
  value.uint16Value

proc asNative*(value: DbusValue, native: typedesc[uint32]): uint32 =
  value.uint32Value

proc asNative*(value: DbusValue, native: typedesc[uint64]): uint64 =
  value.uint64Value

proc asNative*(value: DbusValue, native: typedesc[uint8]): uint8 =
  value.byteValue

proc asNative*(value: DbusValue, native: typedesc[string]): string =
  value.stringValue

proc asNative*(value: DbusValue, native: typedesc[ObjectPath]): ObjectPath =
  value.objectPathValue

proc asNative*(value: DbusValue, native: typedesc[Signature]): Signature =
  value.signatureValue

proc asNative*[T](value: DbusValue, native: typedesc[seq[T]]): seq[T] =
  for str in value.arrayValue:
    result.add asNative(str, T)

proc asNative*[T, K](value: DbusValue, native: typedesc[(T, K)]): (T, K) =
  if value == nil: return
  (asNative(value.dictKey, T), asNative(value.dictValue, K))

proc add*(dict: DbusValue, value: DbusValue) =
  doAssert dict.kind == scArray
  dict.arrayValue.add(value)
