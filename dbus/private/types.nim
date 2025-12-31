import strutils, sequtils

type ObjectPath* = distinct string
# TODO: validate Signature runes
type Signature* = distinct string
type FD* = distinct FileHandle

type SigCode* = enum
  scNull
  scByte
  scBool
  scInt16
  scUint16
  scInt32
  scUint32
  scInt64
  scUint64
  scDouble
  scUnixFd

  scString
  scObjectPath
  scSignature

  scArray
  scStruct
  scVariant
  scDictEntry

proc serialize*(kind: SigCode): char =
  case kind
  of scNull:
    raise newException(DbusException, "cannot serialize null type")

  of scByte: 'y'
  of scBool: 'b'
  of scInt16: 'n'
  of scUint16: 'q'
  of scInt32: 'i'
  of scUint32: 'u'
  of scInt64: 'x'
  of scUint64: 't'
  of scDouble: 'd'
  of scUnixFd: 'h'

  of scString: 's'
  of scObjectPath: 'o'
  of scSignature: 'g'

  of scArray: 'a'
  of scStruct: 'r'
  of scVariant: 'v'
  of scDictEntry: 'e'

proc code*(c: char): SigCode =
  case c
  of 'y': scByte
  of 'b': scBool
  of 'n': scInt16
  of 'q': scUint16
  of 'i': scInt32
  of 'u': scUint32
  of 'x': scInt64
  of 't': scUint64
  of 'd': scDouble
  of 'h': scUnixFd

  of 's': scString
  of 'o': scObjectPath
  of 'g': scSignature

  of 'a': scArray
  of 'r', '(', ')': scStruct
  of 'v': scVariant
  of 'e', '{', '}': scDictEntry
  else:
    raise newException(DbusException, "invalid D-Bus type char: " & $c)

const dbusFixedTypes* = {scByte..scUnixFd}
const dbusStringTypes* = {scString..scSignature}
const dbusContainerTypes* = {scArray..scDictEntry}

proc `==`*(a, b: Signature): bool {.borrow.}
proc `$`*(s: Signature): string {.borrow.}

proc `$`*(f: FD): string {.borrow.}

proc code*(s: Signature): SigCode =
  if string(s).len == 0:
    raise newException(DbusException, "empty D-Bus signature")
  string(s)[0].code

type
  ArrayData = object
    typ: Signature
    values: seq[Variant]
  DictEntryData = object
    typ: tuple[key, value: Signature]
    value: tuple[key, value: Variant]
  VariantData {.union.} = ref object
    int64*: int64
    int32*: int32
    int16*: int16
    uint64*: uint64
    uint32*: uint32
    uint16*: uint16
    byte*: byte
    bool*: bool
    float64*: float64
    string*: string
    ObjectPath*: ObjectPath
    Signature*: Signature
    struct*: seq[Variant]
    array*: ArrayData
    dictEntry*: DictEntryData
    FD*: FD

  Variant* = object
    typ: Signature
    data: VariantData

proc signatureOf*(v: Variant): Signature =
  v.typ

proc inner(s: Signature): Signature =
  case s.code
  of scNull:
    raise newException(DbusException, "null signature has no inner type")
  of dbusFixedTypes, dbusStringTypes, scVariant:
    return Signature("")
  of scArray:
    return Signature(string(s)[1..^1])
  of scDictEntry, scStruct:
    return Signature(string(s)[1..^2])

proc split(sig: Signature): seq[Signature] =
  var s = string(sig)
  var searching: seq[char]
  var start = 0
  for i, c in s:
    case c.code
    of scNull:
      raise newException(DbusException, "null signature has no subtypes")
    of dbusFixedTypes, dbusStringTypes, scVariant:
      if searching.len == 0:
        result.add(Signature(s[start..i]))
        start = i + 1
    of scArray:
      continue
    of scDictEntry:
      if c == '{':
        searching.add('}')
      elif c == '}':
        if searching.pop() != '}':
          raise newException(DbusException, "unmatched } in signature: " & s)
        if searching.len == 0:
          result.add(Signature(s[start..i]))
          start = i + 1
    of scStruct:
      if c == '(':
        searching.add(')')
      elif c == ')':
        if searching.pop() != ')':
          raise newException(DbusException, "unmatched ) in signature: " & s)
        if searching.len == 0:
          result.add(Signature(s[start..i]))
          start = i + 1
  if searching.len != 0:
    raise newException(DbusException, "unmatched container in signature: " & s)

proc sons*(s: Signature): seq[Signature] =
  case s.code
  of scNull:
    raise newException(DbusException, "null signature has no subtypes")
  of dbusFixedTypes, dbusStringTypes, scVariant:
    result = @[]
  of scArray:
    result = @[Signature(string(s)[1..^1])]
  of scDictEntry, scStruct:
    result = s.inner.split

proc sign*(ch: SigCode): Signature =
  Signature($ch.serialize)

proc initArraySignature*(itemType: Signature): Signature =
  Signature("a" & string(itemType))

proc initDictEntrySignature*(keyType: Signature, valueType: Signature): Signature =
  doAssert string(keyType)[0].code notin dbusContainerTypes
  Signature("{" & string(keyType) & string(valueType) & "}")

proc initStructSignature*(itemTypes: seq[Signature]): Signature =
  Signature("(" & itemTypes.mapIt(string(it)).join("") & ")")

proc sign*(native: typedesc[byte]): Signature =
  scByte.sign
proc sign*(native: byte): Signature =
  scByte.sign

proc sign*(native: typedesc[bool]): Signature =
  scBool.sign
proc sign*(native: bool): Signature =
  scBool.sign

proc sign*(native: typedesc[int16]): Signature =
  scInt16.sign
proc sign*(native: int16): Signature =
  scInt16.sign

proc sign*(native: typedesc[uint16]): Signature =
  scUint16.sign
proc sign*(native: uint16): Signature =
  scUint16.sign

proc sign*(native: typedesc[int32]): Signature =
  scInt32.sign
proc sign*(native: int32): Signature =
  scInt32.sign

proc sign*(native: typedesc[uint32]): Signature =
  scUint32.sign
proc sign*(native: uint32): Signature =
  scUint32.sign

proc sign*(native: typedesc[int64]): Signature =
  scInt64.sign
proc sign*(native: int64): Signature =
  scInt64.sign

proc sign*(native: typedesc[uint64]): Signature =
  scUint64.sign
proc sign*(native: uint64): Signature =
  scUint64.sign

proc sign*(native: typedesc[float64]): Signature =
  scDouble.sign
proc sign*(native: float64): Signature =
  scDouble.sign

proc sign*(native: typedesc[float32]): Signature =
  scDouble.sign
proc sign*(native: float32): Signature =
  scDouble.sign

proc sign*(native: typedesc[FD]): Signature =
  scUnixFd.sign
proc sign*(native: FD): Signature =
  scUnixFd.sign

proc sign*(native: typedesc[cstring]): Signature =
  scString.sign
proc sign*(native: cstring): Signature =
  scString.sign

proc sign*(native: typedesc[string]): Signature =
  scString.sign
proc sign*(native: string): Signature =
  scString.sign

proc sign*(native: typedesc[ObjectPath]): Signature =
  scObjectPath.sign
proc sign*(native: ObjectPath): Signature =
  scObjectPath.sign

proc sign*(native: typedesc[Signature]): Signature =
  scSignature.sign
proc sign*(native: Signature): Signature =
  scSignature.sign

proc sign*[T](native: typedesc[seq[T]]): Signature =
  initArraySignature(T.sign)
proc sign*[I: static int; T](native: typedesc[array[I, T]]): Signature =
  initArraySignature(T.sign)
proc sign*[T](native: openArray[T]): Signature =
  initArraySignature(T.sign)

# TODO: check if it works
proc sign*[T: object](native: typedesc[T]): Signature =
  initStructSignature(T.fields.mapIt(it.typ.sign))
proc sign*[T: object](native: T): Signature =
  initStructSignature(T.fields.mapIt(it.typ.sign))

proc sign*(native: typedesc[Variant]): Signature =
  scVariant.sign
proc sign*(native: Variant): Signature =
  scVariant.sign

proc sign*[K, V](native: typedesc[(K, V)]): Signature =
  initDictEntrySignature(K.sign, V.sign)
proc sign*[K, V](native: (K, V)): Signature =
  initDictEntrySignature(K.sign, V.sign)

proc newVariant*(value: byte): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(byte: value)
  )

proc newVariant*(value: bool): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(bool: value)
  )

proc newVariant*(value: int16): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(int16: value)
  )

proc newVariant*(value: uint16): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(uint16: value)
  )

proc newVariant*(value: int32): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(int32: value)
  )

proc newVariant*(value: uint32): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(uint32: value)
  )

proc newVariant*(value: int64): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(int64: value)
  )

proc newVariant*(value: uint64): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(uint64: value)
  )

proc newVariant*(value: float64): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(float64: value)
  )
proc newVariant*(value: float32): Variant =
  newVariant(float64(value))

proc newVariant*(value: FD): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(FD: value)
  )

proc newVariant*(value: string): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(string: value)
  )
proc newVariant*(value: cstring): Variant =
  newVariant($value)

proc newVariant*(value: ObjectPath): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(ObjectPath: value)
  )

proc newVariant*(value: Signature): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(Signature: value)
  )

proc newVariant*(value: ArrayData): Variant =
  Variant(
    typ: initArraySignature(value.typ),
    data: VariantData(array: value),
  )

proc newVariant*[T](value: openArray[T]): Variant =
  newVariant(ArrayData(
    typ: T.sign,
    values: value.mapIt(newVariant(it)),
  ))

proc newVariant*[T: object](value: T): Variant =
  Variant(
    typ: value.sign,
    data: VariantData(struct: value.fields.mapIt(newVariant(it)))
  )

proc newVariant*(value: Variant): Variant =
  `=dup`(value)

proc newVariant*(value: DictEntryData): Variant =
  Variant(
    typ: initDictEntrySignature(value.typ.key, value.typ.value),
    data: VariantData(dictEntry: value),
  )

proc newVariant*[K, V](value: (K, V)): Variant =
  newVariant(DictEntryData(
    typ: (K.sign, V.sign),
    value: (newVariant(value[0]), newVariant(value[1]))
  ))
