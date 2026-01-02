import dbus/errors

import std/strutils, sequtils

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

type
  ArrayData = object
    typ*: Signature
    values*: seq[Variant]
  DictEntryData = object
    typ*: tuple[key, value: Signature]
    value*: tuple[key, value: Variant]
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

proc `==`*(a, b: FD): bool {.borrow.}
proc `$`*(f: FD): string {.borrow.}

proc `==`*(a, b: ObjectPath): bool {.borrow.}
proc `$`*(f: ObjectPath): string {.borrow.}

proc code*(s: Signature): SigCode =
  if string(s).len == 0:
    raise newException(DbusException, "empty D-Bus signature")
  string(s)[0].code

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

proc encode*(ch: SigCode): Signature =
  Signature($ch.serialize)

proc encodeArray*(itemType: Signature): Signature =
  Signature("a" & string(itemType))

proc encodeDictEntry*(keyType: Signature, valueType: Signature): Signature =
  doAssert string(keyType)[0].code notin dbusContainerTypes
  Signature("{" & string(keyType) & string(valueType) & "}")

proc encodeStruct*(itemTypes: seq[Signature]): Signature =
  Signature("(" & itemTypes.mapIt(string(it)).join("") & ")")

proc encode*(native: typedesc[byte]): Signature =
  encode(scByte)
proc encode*(native: byte): Signature =
  encode(scByte)

proc encode*(native: typedesc[bool]): Signature =
  encode(scBool)
proc encode*(native: bool): Signature =
  encode(scBool)

proc encode*(native: typedesc[int16]): Signature =
  encode(scInt16)
proc encode*(native: int16): Signature =
  encode(scInt16)

proc encode*(native: typedesc[uint16]): Signature =
  encode(scUint16)
proc encode*(native: uint16): Signature =
  encode(scUint16)

proc encode*(native: typedesc[int32]): Signature =
  encode(scInt32)
proc encode*(native: int32): Signature =
  encode(scInt32)

proc encode*(native: typedesc[uint32]): Signature =
  encode(scUint32)
proc encode*(native: uint32): Signature =
  encode(scUint32)

proc encode*(native: typedesc[int64]): Signature =
  encode(scInt64)
proc encode*(native: int64): Signature =
  encode(scInt64)

proc encode*(native: typedesc[uint64]): Signature =
  encode(scUint64)
proc encode*(native: uint64): Signature =
  encode(scUint64)

proc encode*(native: typedesc[float64]): Signature =
  encode(scDouble)
proc encode*(native: float64): Signature =
  encode(scDouble)

proc encode*(native: typedesc[float32]): Signature =
  encode(scDouble)
proc encode*(native: float32): Signature =
  encode(scDouble)

proc encode*(native: typedesc[FD]): Signature =
  encode(scUnixFd)
proc encode*(native: FD): Signature =
  encode(scUnixFd)

proc encode*(native: typedesc[cstring]): Signature =
  encode(scString)
proc encode*(native: cstring): Signature =
  encode(scString)

proc encode*(native: typedesc[string]): Signature =
  encode(scString)
proc encode*(native: string): Signature =
  encode(scString)

proc encode*(native: typedesc[ObjectPath]): Signature =
  encode(scObjectPath)
proc encode*(native: ObjectPath): Signature =
  encode(scObjectPath)

proc encode*(native: typedesc[Signature]): Signature =
  encode(scSignature)
proc encode*(native: Signature): Signature =
  encode(scSignature)

proc encode*[T](native: typedesc[seq[T]]): Signature =
  encodeArray(encode(T))
proc encode*[I: static int; T](native: typedesc[array[I, T]]): Signature =
  encodeArray(encode(T))
proc encode*[T](native: openArray[T]): Signature =
  encodeArray(encode(T))

proc encode*[K, V](native: typedesc[(K, V)]): Signature =
  encodeDictEntry(encode(K), encode(V))
proc encode*[K, V](native: (K, V)): Signature =
  encodeDictEntry(encode(K), encode(V))

proc encode*(native: typedesc[Variant]): Signature =
  encode(scVariant)
proc encode*(native: Variant): Signature =
  encode(scVariant)
