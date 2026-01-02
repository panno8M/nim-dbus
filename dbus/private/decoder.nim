proc decodeSignature(sig: Signature): NimNode =
  case sig.code
  of scBool:
    bindSym"bool"
  of scByte:
    bindSym"byte"
  of scInt16:
    bindSym"int16"
  of scUint16:
    bindSym"uint16"
  of scInt32:
    bindSym"int32"
  of scUint32:
    bindSym"uint32"
  of scInt64:
    bindSym"int64"
  of scUint64:
    bindSym"uint64"
  of scDouble:
    bindSym"float64"
  of scUnixFd:
    bindSym"FD"
  of scString:
    bindSym"string"
  of scObjectPath:
    bindSym"ObjectPath"
  of scSignature:
    bindSym"Signature"
  of scVariant:
    bindSym"Variant"
  of scDictEntry:
    let sons = sig.sons
    let key = decodeSignature(sons[0])
    let val = decodeSignature(sons[1])
    quote do:
      (`key`, `val`)
  of scArray:
    let sons = sig.sons
    let item = decodeSignature(sons[0])
    quote do:
      seq[`item`]
  of scStruct:
    let sons = sig.sons
    let fields = sons.map(decodeSignature)
    nnkTupleConstr.newTree(fields)
  else:
    error "Invalid signature: undefined"

macro decode*(sig: static Signature): typedesc =
  if sig.split.len != 1:
    error "Invalid signature: Contains multiple types"
  decodeSignature(sig)

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
  value.data.array.values.mapIt(it[T])

proc `[]`*(value: Variant, native: typedesc[(Variant, Variant)]): tuple[key: Variant, value: Variant] =
  value.data.dictEntry

proc `[]`*[T, K](value: Variant, native: typedesc[(T, K)]): tuple[key: T, value: K] =
  let (key, value) = value.data.dictEntry.value
  (key[T], value[K])

template `[]`*(value: Variant; sig: static Signature): untyped =
  value.`[]`(decode(sig))