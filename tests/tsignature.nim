import std/unittest
import dbus

suite "Signature":
  test "basic signatures":
    check Signature("i").code == scInt32
    check Signature("s").code == scString
    check Signature("b").code == scBool

  test "array signature":
    let sig = Signature("ai")
    check sig.code == scArray
    check sig.sons == @[Signature("i")]
    check sig.sons[0].code == scInt32

  test "struct signature":
    let sig = Signature("(is)")
    check sig.code == scStruct
    check sig.sons == @[Signature("i"), Signature("s")]
    check sig.sons[0].code == scInt32
    check sig.sons[1].code == scString

  test "variant signature":
    let sig = Signature("v")
    check sig.code == scVariant

  test "dictionary entry signature":
    let sig = Signature("a{sv}")
    check sig.code == scArray
    check sig.sons == @[Signature("{sv}")]
    check sig.sons[0].code == scDictEntry
    check sig.sons[0].sons == @[Signature("s"), Signature("v")]
    check sig.sons[0].sons[0].code == scString
    check sig.sons[0].sons[1].code == scVariant
  
  test "nested dictionary signature":
    let sig = Signature("a{sa{is}}")
    check sig.code == scArray
    check sig.sons == @[Signature("{sa{is}}")]
    check sig.sons[0].code == scDictEntry
    check sig.sons[0].sons == @[Signature("s"), Signature("a{is}")]
    check sig.sons[0].sons[0].code == scString
    check sig.sons[0].sons[1].code == scArray
    check sig.sons[0].sons[1].sons == @[Signature("{is}")]
    check sig.sons[0].sons[1].sons[0].code == scDictEntry
    check sig.sons[0].sons[1].sons[0].sons == @[Signature("i"), Signature("s")]
    check sig.sons[0].sons[1].sons[0].sons[0].code == scInt32
    check sig.sons[0].sons[1].sons[0].sons[1].code == scString