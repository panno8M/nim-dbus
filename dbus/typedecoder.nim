import dbus/types
import dbus/signatures {.all.}
import dbus/variants

import std/[sequtils, macros]

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

template `[]`*(value: Variant; sig: static Signature): untyped =
  value[decode(sig)]
