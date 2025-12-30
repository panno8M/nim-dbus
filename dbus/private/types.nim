import strutils, sequtils

type ObjectPath* = distinct string
type Signature* = distinct string

type Variant[T] = object
  value: T

proc newVariant*[T](val: T): Variant[T] = Variant[T](value: val)

type SigCode* = enum
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

proc code*(s: Signature): SigCode =
  if string(s).len == 0:
    raise newException(DbusException, "empty D-Bus signature")
  string(s)[0].code

proc inner(s: Signature): Signature =
  case s.code
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
  of dbusFixedTypes, dbusStringTypes, scVariant:
    result = @[]
  of scArray:
    result = @[Signature(string(s)[1..^1])]
  of scDictEntry, scStruct:
    result = s.inner.split

converter fromScalar*(ch: SigCode): Signature =
  # assert ch notin dbusContainerTypes
  Signature($ch.serialize)

proc initArraySignature*(itemType: Signature): Signature =
  Signature("a" & string(itemType))

proc initDictEntrySignature*(keyType: Signature, valueType: Signature): Signature =
  doAssert string(keyType)[0].code notin dbusContainerTypes
  Signature("{" & string(keyType) & string(valueType) & "}")

proc initStructSignature*(itemTypes: seq[Signature]): Signature =
  Signature("(" & itemTypes.mapIt(string(it)).join("") & ")")

proc sign*(native: typedesc[uint32]): Signature =
  scUint32

proc sign*(native: typedesc[uint16]): Signature =
  scUint16

proc sign*(native: typedesc[uint8]): Signature =
  scByte

proc sign*(native: typedesc[int32]): Signature =
  scInt32

proc sign*(native: typedesc[int16]): Signature =
  scInt16

proc sign*(native: typedesc[cstring]): Signature =
  scString
proc sign*(native: typedesc[string]): Signature =
  scString

proc sign*(native: typedesc[ObjectPath]): Signature =
  scObjectPath

proc sign*[T](native: typedesc[Variant[T]]): Signature =
  scVariant

proc sign*[K, V](native: typedesc[(K, V)]): Signature =
  initDictEntrySignature(K.sign, V.sign)

proc sign*[T](native: typedesc[seq[T]]): Signature =
  initArraySignature(T.sign)
