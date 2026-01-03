import dbus/middlelevel
import dbus/signatures

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

proc encodeArray*(itemType: Signature): Signature =
  Signature("a" & string(itemType))

proc encodeDictEntry*(keyType: Signature, valueType: Signature): Signature =
  doAssert string(keyType)[0].code notin dbusContainerTypes
  Signature("{" & string(keyType) & string(valueType) & "}")

proc encodeStruct*(itemTypes: seq[Signature]): Signature =
  Signature("(" & itemTypes.mapIt(string(it)).join("") & ")")

proc encode*(native: typedesc[byte]): Signature =
  scByte.getSignature

proc encode*(native: typedesc[bool]): Signature =
  scBool.getSignature

proc encode*(native: typedesc[int16]): Signature =
  scInt16.getSignature

proc encode*(native: typedesc[uint16]): Signature =
  scUint16.getSignature

proc encode*(native: typedesc[int32]): Signature =
  scInt32.getSignature

proc encode*(native: typedesc[uint32]): Signature =
  scUint32.getSignature

proc encode*(native: typedesc[int64]): Signature =
  scInt64.getSignature

proc encode*(native: typedesc[uint64]): Signature =
  scUint64.getSignature

proc encode*(native: typedesc[float64]): Signature =
  scDouble.getSignature

proc encode*(native: typedesc[float32]): Signature =
  scDouble.getSignature

proc encode*(native: typedesc[FD]): Signature =
  scUnixFd.getSignature

proc encode*(native: typedesc[cstring]): Signature =
  scString.getSignature

proc encode*(native: typedesc[string]): Signature =
  scString.getSignature

proc encode*(native: typedesc[ObjectPath]): Signature =
  scObjectPath.getSignature

proc encode*(native: typedesc[Signature]): Signature =
  scSignature.getSignature

proc encode*[T](native: typedesc[seq[T]]): Signature =
  encodeArray(encode(T))
proc encode*[I; T](native: typedesc[array[I, T]]): Signature =
  encodeArray(encode(T))

proc encode*[K, V](native: typedesc[(K, V)]): Signature =
  encodeDictEntry(encode(K), encode(V))

proc encode*(native: typedesc[Variant]): Signature =
  scVariant.getSignature
