import strutils, sequtils

type ObjectPath* = distinct string
type Signature* = distinct string

type Variant[T] = object
  value: T

proc newVariant*[T](val: T): Variant[T] = Variant[T](value: val)

type DbusTypeChar* = enum
  dtByte
  dtBool
  dtInt16
  dtUint16
  dtInt32
  dtUint32
  dtInt64
  dtUint64
  dtDouble
  dtUnixFd

  dtString
  dtObjectPath
  dtSignature

  dtArray
  dtStruct
  dtVariant
  dtDictEntry

proc serialize*(kind: DbusTypeChar): char =
  case kind
  of dtByte: 'y'
  of dtBool: 'b'
  of dtInt16: 'n'
  of dtUint16: 'q'
  of dtInt32: 'i'
  of dtUint32: 'u'
  of dtInt64: 'x'
  of dtUint64: 't'
  of dtDouble: 'd'
  of dtUnixFd: 'h'

  of dtString: 's'
  of dtObjectPath: 'o'
  of dtSignature: 'g'

  of dtArray: 'a'
  of dtStruct: 'r'
  of dtVariant: 'v'
  of dtDictEntry: 'e'

proc type*(c: char): DbusTypeChar =
  case c
  of 'y': dtByte
  of 'b': dtBool
  of 'n': dtInt16
  of 'q': dtUint16
  of 'i': dtInt32
  of 'u': dtUint32
  of 'x': dtInt64
  of 't': dtUint64
  of 'd': dtDouble
  of 'h': dtUnixFd

  of 's': dtString
  of 'o': dtObjectPath
  of 'g': dtSignature

  of 'a': dtArray
  of 'r', '(', ')': dtStruct
  of 'v': dtVariant
  of 'e', '{', '}': dtDictEntry
  else:
    raise newException(DbusException, "invalid D-Bus type char: " & $c)

const dbusFixedTypes* = {dtByte..dtUnixFd}
const dbusStringTypes* = {dtString..dtSignature}
const dbusContainerTypes* = {dtArray..dtDictEntry}

proc `==`*(a, b: Signature): bool {.borrow.}

proc `type`*(s: Signature): DbusTypeChar =
  if string(s).len == 0:
    raise newException(DbusException, "empty D-Bus signature")
  string(s)[0].type

proc inner(s: Signature): Signature =
  case s.type
  of dbusFixedTypes, dbusStringTypes, dtVariant:
    return Signature("")
  of dtArray:
    return Signature(string(s)[1..^1])
  of dtDictEntry, dtStruct:
    return Signature(string(s)[1..^2])

proc split(sig: Signature): seq[Signature] =
  var s = string(sig)
  var searching: seq[char]
  var start = 0
  for i, c in s:
    case c.type
    of dbusFixedTypes, dbusStringTypes, dtVariant:
      if searching.len == 0:
        result.add(Signature(s[start..i]))
        start = i + 1
    of dtArray:
      continue
    of dtDictEntry:
      if c == '{':
        searching.add('}')
      elif c == '}':
        if searching.pop() != '}':
          raise newException(DbusException, "unmatched } in signature: " & s)
        if searching.len == 0:
          result.add(Signature(s[start..i]))
          start = i + 1
    of dtStruct:
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
  case s.type
  of dbusFixedTypes, dbusStringTypes, dtVariant:
    result = @[]
  of dtArray:
    result = @[Signature(string(s)[1..^1])]
  of dtDictEntry, dtStruct:
    result = s.inner.split

converter fromScalar*(ch: DbusTypeChar): Signature =
  # assert ch notin dbusContainerTypes
  Signature($ch.serialize)

proc initArraySignature*(itemType: Signature): Signature =
  Signature("a" & string(itemType))

proc initDictEntrySignature*(keyType: Signature, valueType: Signature): Signature =
  doAssert string(keyType)[0].type notin dbusContainerTypes
  Signature("{" & string(keyType) & string(valueType) & "}")

proc initStructSignature*(itemTypes: seq[Signature]): Signature =
  Signature("(" & itemTypes.mapIt(string(it)).join("") & ")")

proc sign*(native: typedesc[uint32]): Signature =
  dtUint32

proc sign*(native: typedesc[uint16]): Signature =
  dtUint16

proc sign*(native: typedesc[uint8]): Signature =
  dtByte

proc sign*(native: typedesc[int32]): Signature =
  dtInt32

proc sign*(native: typedesc[int16]): Signature =
  dtInt16

proc sign*(native: typedesc[cstring]): Signature =
  dtString
proc sign*(native: typedesc[string]): Signature =
  dtString

proc sign*(native: typedesc[ObjectPath]): Signature =
  dtObjectPath

proc sign*[T](native: typedesc[Variant[T]]): Signature =
  dtVariant

proc sign*[K, V](native: typedesc[(K, V)]): Signature =
  initDictEntrySignature(K.sign, V.sign)

proc sign*[T](native: typedesc[seq[T]]): Signature =
  initArraySignature(T.sign)
