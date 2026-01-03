import dbus
type ComZielmichaTestRemote* = object of DbusIfaceWrapper

proc get*(wrapperType: typedesc[ComZielmichaTestRemote], uniqueBus: UniqueBus, path: ObjectPath): ComZielmichaTestRemote =
  result.uniqueBus = uniqueBus
  result.path = path


proc helloAsync*(dbusIface: ComZielmichaTestRemote, num: uint32, sss: string): PendingCall =
  let msg = newMethodCallMessage(dbusIface.uniqueBus.uniqueName, dbusIface.path, "com.zielmicha.test", "hello")
  msg.append(num)
  msg.append(sss)
  return dbusIface.uniqueBus.connection.sendWithReply(msg)

proc helloGetReply*(reply: Message): tuple[salutation: string, retnum: uint32] =
  reply.raiseIfError
  result.salutation = reply[0][string]
  result.retnum = reply[1][uint32]

proc hello*(dbusIface: ComZielmichaTestRemote, num: uint32, sss: string): tuple[salutation: string, retnum: uint32] =
  let reply = helloAsync(dbusIface, num, sss).waitForReply()
  return helloGetReply(reply)

