import strutils, tables

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
  of 'r', '{', '}': dtStruct
  of 'v': dtVariant
  of 'e', '(', ')': dtDictEntry
  else:
    raise newException(DbusException, "invalid D-Bus type char: " & $c)

const dbusFixedTypes* = {dtByte..dtUnixFd}
const dbusStringTypes* = {dtString..dtSignature}
const dbusContainerTypes* = {dtArray..dtDictEntry}

type DbusType* = ref object
  case kind*: DbusTypeChar
  of dtArray:
    itemType*: DbusType
  of dtDictEntry:
    keyType*: DbusType
    valueType*: DbusType
  of dtStruct:
    itemTypes*: seq[DbusType]
  of dtVariant:
    variantType*: DbusType
  else:
    discard

converter fromScalar*(ch: DbusTypeChar): DbusType =
  # assert ch notin dbusContainerTypes
  DbusType(kind: ch)

proc initArrayType*(itemType: DbusType): DbusType =
  DbusType(kind: dtArray, itemType: itemType)

proc initDictEntryType*(keyType: DbusType, valueType: DbusType): DbusType =
  doAssert keyType.kind notin dbusContainerTypes
  DbusType(kind: dtDictEntry, keyType: keyType, valueType: valueType)

proc initStructType*(itemTypes: seq[DbusType]): DbusType =
  DbusType(kind: dtStruct, itemTypes: itemTypes)

proc initVariantType*(variantType: DbusType): DbusType =
  DbusType(kind: dtVariant, variantType: variantType)

proc parseDbusFragment(signature: string): tuple[kind: DbusType, rest: string] =
  case signature[0]:
    of 'a':
      let ret = parseDbusFragment(signature[1..^1])
      return (initArrayType(ret.kind), ret.rest)
    of '{':
      let keyRet = parseDbusFragment(signature[1..^1])
      let valueRet = parseDbusFragment(keyRet.rest)
      assert valueRet.rest[0] == "}"[0]
      return (initDictEntryType(keyRet.kind, valueRet.kind), valueRet.rest[1..^1])
    of '(':
      var left = signature[1..^1]
      var types: seq[DbusType] = @[]
      while left[0] != ')':
        let ret = parseDbusFragment(left)
        left = ret.rest
        types.add ret.kind
      return (initStructType(types), left[1..^1])
    else:
      let kind = signature[0].type
      return (fromScalar(kind), signature[1..^1])

proc parseDbusType*(signature: string): DbusType =
  let ret = parseDbusFragment(signature)
  if ret.rest != "":
    raise newException(Exception, "leftover data in signature: $1" % signature)
  return ret.kind

proc `$`*(kind: DbusType): string =
  case kind.kind:
    of dtArray:
      result = "a" & $kind.itemType
    of dtDictEntry:
      result = "{" & $kind.keyType & $kind.valueType & "}"
    of dtStruct:
      result = "("
      for t in kind.itemTypes:
        result.add $t
      result.add ")"
    else:
      result = $(kind.kind.serialize)

proc getDbusType(native: typedesc[uint32]): DbusType =
  dtUint32

proc getDbusType(native: typedesc[uint16]): DbusType =
  dtUint16

proc getDbusType(native: typedesc[uint8]): DbusType =
  dtByte

proc getDbusType(native: typedesc[int32]): DbusType =
  dtInt32

proc getDbusType(native: typedesc[int16]): DbusType =
  dtInt16

proc getDbusType(native: typedesc[cstring]): DbusType =
  dtString

proc getDbusType(native: typedesc[ObjectPath]): DbusType =
  dtObjectPath

proc getAnyDbusType*[T](native: typedesc[T]): DbusType
proc getAnyDbusType*(native: typedesc[string]): DbusType
proc getAnyDbusType*(native: typedesc[ObjectPath]): DbusType
proc getAnyDbusType*[T](native: typedesc[seq[T]]): DbusType
proc getAnyDbusType*[K, V](native: typedesc[Table[K, V]]): DbusType
proc getAnyDbusType*[K, V](native: typedesc[TableRef[K, V]]): DbusType

proc getDbusType[T](native: typedesc[Variant[T]]): DbusType =
  initVariantType(getAnyDbusType(T))

proc getAnyDbusType*[T](native: typedesc[T]): DbusType =
  getDbusType(native)

proc getAnyDbusType*(native: typedesc[string]): DbusType =
  getDbusType(cstring)

proc getAnyDbusType*(native: typedesc[ObjectPath]): DbusType =
  getDbusType(ObjectPath)

proc getAnyDbusType*[T](native: typedesc[seq[T]]): DbusType =
  initArrayType(getDbusType(T))

proc getAnyDbusType*[K, V](native: typedesc[Table[K, V]]): DbusType =
  initArrayType(initDictEntryType(getAnyDbusType(K), getAnyDbusType(V)))

proc getAnyDbusType*[K, V](native: typedesc[TableRef[K, V]]): DbusType =
  initArrayType(initDictEntryType(getAnyDbusType(K), getAnyDbusType(V)))
