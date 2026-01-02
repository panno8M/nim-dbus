import dbus/types

import std/strutils, sequtils

proc encode*(native: typedesc[byte]): Signature
proc encode*(native: typedesc[bool]): Signature
proc encode*(native: typedesc[int16]): Signature
proc encode*(native: typedesc[uint16]): Signature
proc encode*(native: typedesc[int32]): Signature
proc encode*(native: typedesc[uint32]): Signature
proc encode*(native: typedesc[int64]): Signature
proc encode*(native: typedesc[uint64]): Signature
proc encode*(native: typedesc[float64]): Signature
proc encode*(native: typedesc[float32]): Signature
proc encode*(native: typedesc[FD]): Signature
proc encode*(native: typedesc[cstring]): Signature
proc encode*(native: typedesc[string]): Signature
proc encode*(native: typedesc[ObjectPath]): Signature
proc encode*(native: typedesc[Signature]): Signature
proc encode*[T](native: typedesc[seq[T]]): Signature
proc encode*[I; T](native: typedesc[array[I, T]]): Signature
proc encode*[K, V](native: typedesc[(K, V)]): Signature
proc encode*(native: typedesc[Variant]): Signature

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

proc encode*(native: typedesc[bool]): Signature =
  encode(scBool)

proc encode*(native: typedesc[int16]): Signature =
  encode(scInt16)

proc encode*(native: typedesc[uint16]): Signature =
  encode(scUint16)

proc encode*(native: typedesc[int32]): Signature =
  encode(scInt32)

proc encode*(native: typedesc[uint32]): Signature =
  encode(scUint32)

proc encode*(native: typedesc[int64]): Signature =
  encode(scInt64)

proc encode*(native: typedesc[uint64]): Signature =
  encode(scUint64)

proc encode*(native: typedesc[float64]): Signature =
  encode(scDouble)

proc encode*(native: typedesc[float32]): Signature =
  encode(scDouble)

proc encode*(native: typedesc[FD]): Signature =
  encode(scUnixFd)

proc encode*(native: typedesc[cstring]): Signature =
  encode(scString)

proc encode*(native: typedesc[string]): Signature =
  encode(scString)

proc encode*(native: typedesc[ObjectPath]): Signature =
  encode(scObjectPath)

proc encode*(native: typedesc[Signature]): Signature =
  encode(scSignature)

proc encode*[T](native: typedesc[seq[T]]): Signature =
  encodeArray(encode(T))
proc encode*[I; T](native: typedesc[array[I, T]]): Signature =
  encodeArray(encode(T))

proc encode*[K, V](native: typedesc[(K, V)]): Signature =
  encodeDictEntry(encode(K), encode(V))

proc encode*(native: typedesc[Variant]): Signature =
  encode(scVariant)
