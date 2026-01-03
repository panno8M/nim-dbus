import dbus/lowlevel
import dbus/errors
import dbus/signatures

type
  ObjectPath* = distinct string
  FD* = distinct FileHandle

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

type
  ConnectionObj* = object
    raw: ptr DBusConnection
  Connection* = ref ConnectionObj

  MessageObj* = object of RootObj
    raw: ptr DBusMessage
  Message* = ref MessageObj

  MessageIter* = ref object
    raw: DbusMessageIter
    parent: MessageIter

  PendingCallObj* = object
    raw: ptr DBusPendingCall
    conn: Connection
  PendingCall* = ref PendingCallObj

type
  MethodCallMessage* = ref object of Message
  MethodReturnMessage* = ref object of Message
  ErrorMessage* = ref object of Message
  SignalMessage* = ref object of Message

  MessageType* = enum
    mtInvalid = 0, mtMethodCall = 1, mtMethodReturn = 2,
    mtError = 3, mtSignal = 4


proc `=destroy`*(conn: ConnectionObj) =
  if conn.raw.isNil: return
  dbus_connection_unref(conn.raw)
proc `=copy`*(dst: var ConnectionObj; src: ConnectionObj) =
  `=destroy` dst
  wasMoved dst
  dst.raw = dbus_connection_ref(src.raw)

proc `=destroy`*(a: MessageObj) =
  if a.raw.isNil: return
  dbus_message_unref(a.raw)
proc `=copy`*(a: var MessageObj; b: MessageObj) =
  `=destroy` a
  wasMoved a
  a.raw = dbus_message_ref(b.raw)

proc `=destroy`*(a: PendingCallObj) =
  if a.raw.isNil: return
  dbus_pending_call_unref(a.raw)
proc `=copy`*(a: var PendingCallObj; b: PendingCallObj) =
  `=destroy` a
  wasMoved a
  a.raw = dbus_pending_call_ref(b.raw)
  a.conn = b.conn

# ObjectPath
proc `==`*(a, b: ObjectPath): bool {.borrow.}
proc `$`*(f: ObjectPath): string {.borrow.}

# Signature
proc `==`*(a, b: Signature): bool {.borrow.}
proc `$`*(s: Signature): string {.borrow.}

# FD
proc `==`*(a, b: FD): bool {.borrow.}
proc `$`*(f: FD): string {.borrow.}

# Connection
proc flush*(conn: Connection) =
  dbus_connection_flush(conn.raw)

proc getBus*(busType: DBusBusType): Connection =
  doAssert dbus_threads_init_default() != 0 # enable threads
  DBusException.liftDbusError(err):
    result = Connection(raw: dbus_bus_get(busType, addr err))

proc addMatch*(connection: Connection, rule: string) =
  DBusException.liftDbusError(err):
    dbus_bus_add_match(connection.raw, cstring(rule), addr err)

proc send*(conn: Connection, msg: Message): bool {.discardable.} =
  var b: dbus_bool_t
  if dbus_connection_send(conn.raw, msg.raw, addr b) == 0:
      raise newException(DbusException, "dbus_connection_send")
  result = bool(b)

proc sendWithReply*(conn: Connection, msg: Message): PendingCall =
  result = PendingCall(conn: conn)
  if dbus_connection_send_with_reply(conn.raw, msg.raw, addr result.raw, -1) == 0:
    raise newException(DbusException, "dbus_connection_send_with_reply")

proc requestName*(conn: Connection, name: string) =
  DbusException.liftDbusError(err):
    discard dbus_bus_request_name(conn.raw, name, 0, addr err)

proc tryRegisterObjectPath*(connection: Connection;
    path: ObjectPath; vtable: ptr DBusObjectPathVTable;
    user_data: pointer) =
  DBusException.liftDbusError(err):
    discard dbus_connection_try_register_object_path(
      connection.raw,
      cstring(path),
      vtable,
      user_data,
      addr err)

proc dispatch*(connection: Connection): DBusDispatchStatus =
  dbus_connection_dispatch(connection.raw)

proc setWatchFunctions*(connection: Connection;
  addFunction: DBusAddWatchFunction;
  removeFunction: DBusRemoveWatchFunction;
  toggledFunction: DBusWatchToggledFunction;
  data: pointer;
  freeDataFunction: DBusFreeFunction;
): bool =
  dbus_connection_set_watch_functions(connection.raw,
    addFunction,
    removeFunction,
    toggledFunction,
    data,
    freeDataFunction,
  ) != 0

# Message
proc type(msg: ptr DBusMessage): MessageType =
  if msg.isNil:
    mtInvalid
  else:
    MessageType(dbus_message_get_type(msg))
proc type*(msg: Message): MessageType =
  msg.raw.type

proc newMessage*(msg: ptr DBusMessage): Message =
  if msg.isNil:
    raise newException(DbusException, "the message is nil")
  case msg.type
  of mtMethodCall:
    MethodCallMessage(raw: dbus_message_ref(msg))
  of mtMethodReturn:
    MethodReturnMessage(raw: dbus_message_ref(msg))
  of mtError:
    ErrorMessage(raw: dbus_message_ref(msg))
  of mtSignal:
    SignalMessage(raw: dbus_message_ref(msg))
  of mtInvalid:
    raise newException(DbusException, "the message is invalid")

proc newSignalMessage*(path: string, iface: string, name: string): SignalMessage =
  SignalMessage(raw: dbus_message_new_signal(path, iface, name))

proc newMethodCallMessage*(uniqueName: string, path: ObjectPath, iface: string, name: string): MethodCallMessage =
  MethodCallMessage(raw: dbus_message_new_method_call(uniqueName, path.string.cstring, iface, name))

proc newMethodReturnMessage*(methodCall: MethodCallMessage): MethodReturnMessage =
  MethodReturnMessage(raw: dbus_message_new_method_return(methodCall.raw))

proc newErrorMessage*(methodCall: MethodCallMessage; name: string; message: string): ErrorMessage =
  ErrorMessage(raw: dbus_message_new_error(methodCall.raw, cstring(name), cstring(message)))

proc member*(msg: Message): string =
  $dbus_message_get_member(msg.raw)

proc `interface`*(msg: Message): string =
  $dbus_message_get_interface(msg.raw)

proc getError*(msg: Message): ref DBusException =
  var err: DBusError
  if dbus_set_error_from_message(addr err, msg.raw) != 0:
    return err.toException(DBusException)

# MessageIter
proc newMessageIter*(message: Message): MessageIter =
  var iter: DbusMessageiter
  if dbus_message_iter_init(message.raw, addr iter) != 0:
    return MessageIter(raw: move(iter))

proc newMessageIterAppend*(message: Message): MessageIter =
  new result
  dbus_message_iter_init_append(message.raw, addr result.raw)

proc next*(iter: MessageIter): bool =
  dbus_message_iter_next(addr iter.raw) != 0

proc recurse*(iter: MessageIter): MessageIter =
  new result
  dbus_message_iter_recurse(addr iter.raw, addr result.raw)

proc getSignature*(iter: MessageIter): Signature =
  let cs = dbus_message_iter_get_signature(addr iter.raw)
  result = Signature($cs)
  dbus_free(cs)

proc getBasic*(iter: MessageIter; p: pointer) =
  dbus_message_iter_get_basic(addr iter.raw, p)

proc appendBasic*(iter: MessageIter; typecode: SigCode; data: pointer): bool {.discardable.} =
  dbus_message_iter_append_basic(addr iter.raw, typecode.getChar.cint, data) != 0

proc openContainer*(iter: MessageIter; code: SigCode; contained: Signature): MessageIter =
  var subiter: DbusMessageIter
  let p = if contained == Signature"": cstring(nil) else: cstring(contained)
  if dbus_message_iter_open_container(addr iter.raw, code.getChar.cint, p, addr subIter) == 0:
    raise newException(DbusException, "open_container")
  MessageIter(raw: move(subiter), parent: iter)

proc closeContainer*(subiter: MessageIter) =
  if dbus_message_iter_close_container(addr subiter.parent.raw, addr subiter.raw) == 0:
    raise newException(DbusException, "close_container")

# PendingCall
proc connection*(pendingCall: PendingCall): Connection =
  pendingCall.conn

proc `block`*(pendingCall: PendingCall) =
  dbus_pending_call_block(pendingCall.raw)

proc stealReply*(pendingCall: PendingCall): Message =
  newMessage(dbus_pending_call_steal_reply(pendingCall.raw))
