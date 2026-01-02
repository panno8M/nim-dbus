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

const dbusFixedTypes* = {scByte..scUnixFd}
const dbusStringTypes* = {scString..scSignature}
const dbusContainerTypes* = {scArray..scDictEntry}

proc `==`*(a, b: Signature): bool {.borrow.}
proc `$`*(s: Signature): string {.borrow.}

proc `==`*(a, b: FD): bool {.borrow.}
proc `$`*(f: FD): string {.borrow.}

proc `==`*(a, b: ObjectPath): bool {.borrow.}
proc `$`*(f: ObjectPath): string {.borrow.}
