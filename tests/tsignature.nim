import std/unittest
import dbus

suite "Signature":
  test "basic signatures":
    check Signature("i").type == dtInt32
    check Signature("s").type == dtString
    check Signature("b").type == dtBool

  test "array signature":
    let sig = Signature("ai")
    check sig.type == dtArray
    check sig.sons == @[Signature("i")]
    check sig.sons[0].type == dtInt32

  test "struct signature":
    let sig = Signature("(is)")
    check sig.type == dtStruct
    check sig.sons == @[Signature("i"), Signature("s")]
    check sig.sons[0].type == dtInt32
    check sig.sons[1].type == dtString

  test "variant signature":
    let sig = Signature("v")
    check sig.type == dtVariant

  test "dictionary entry signature":
    let sig = Signature("a{sv}")
    check sig.type == dtArray
    check sig.sons == @[Signature("{sv}")]
    check sig.sons[0].type == dtDictEntry
    check sig.sons[0].sons == @[Signature("s"), Signature("v")]
    check sig.sons[0].sons[0].type == dtString
    check sig.sons[0].sons[1].type == dtVariant
  
  test "nested dictionary signature":
    let sig = Signature("a{sa{is}}")
    check sig.type == dtArray
    check sig.sons == @[Signature("{sa{is}}")]
    check sig.sons[0].type == dtDictEntry
    check sig.sons[0].sons == @[Signature("s"), Signature("a{is}")]
    check sig.sons[0].sons[0].type == dtString
    check sig.sons[0].sons[1].type == dtArray
    check sig.sons[0].sons[1].sons == @[Signature("{is}")]
    check sig.sons[0].sons[1].sons[0].type == dtDictEntry
    check sig.sons[0].sons[1].sons[0].sons == @[Signature("i"), Signature("s")]
    check sig.sons[0].sons[1].sons[0].sons[0].type == dtInt32
    check sig.sons[0].sons[1].sons[0].sons[1].type == dtString