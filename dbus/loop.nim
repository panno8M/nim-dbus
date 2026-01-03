import dbus, posix, os

const maxWatches = 128

type
  MainLoop* = ref object
    conn: Connection
    watchesCount: int
    watches: array[maxWatches, ptr DbusWatch]

proc addWatch(newWatch: ptr DBusWatch, loopPtr: pointer): dbus_bool_t {.cdecl.} =
  let loop = cast[MainLoop](loopPtr)
  #echo "addWatch ", dbus_watch_get_fd(watch)
  if loop.watchesCount == maxWatches:
    raise newException(ValueError, "too many watches")
  for watch in loop.watches.mitems:
    if watch == nil:
      watch = newWatch
      break
  inc loop.watchesCount
  return 1

proc removeWatch(oldWatch: ptr DBusWatch, loopPtr: pointer) {.cdecl.} =
  let loop = cast[MainLoop](loopPtr)
  #echo "removeWatch"
  for watch in loop.watches.mitems:
    if watch == oldWatch:
      watch = nil
      break
  dec loop.watchesCount

proc toggleWatch(watch: ptr DBusWatch, loopPtr: pointer) {.cdecl.} =
  discard

proc freeLoop(loopPtr: pointer) {.cdecl.} =
  discard

proc newMainLoop*(conn: Connection): MainLoop =
  result = MainLoop(conn: conn)
  assert conn.setWatchFunctions(
    add_function=DBusAddWatchFunction(addWatch),
    remove_function=DBusRemoveWatchFunction(removeWatch),
    toggled_function=DBusWatchToggledFunction(toggleWatch),
    data=addr result[],
    free_data_function=freeLoop)
  conn.addMatch("type='signal'")
  conn.addMatch("type='method_call'")

proc tick*(self: MainLoop; timeout: int = -1) =
  var
    fds: array[maxWatches, TPollfd]
    activeWatches: seq[ptr DbusWatch] = @[]
    nfds: int = 0
    checkedWatches = 0

  for i, watch in self.watches:
    if checkedWatches == self.watchesCount: break
    if watch.isNil: continue
    inc checkedWatches
    if dbus_watch_get_enabled(watch) == 0: continue

    var cond: int16 = POLLHUP or POLLERR
    let fd = dbus_watch_get_fd(watch)
    let flags = dbus_watch_get_flags(watch)

    if (flags and DBUS_WATCH_READABLE.cuint) != 0:
      cond = cond or POLLIN;
    if (flags and DBUS_WATCH_WRITABLE.cuint) != 0:
      cond = cond or POLLOUT;

    fds[nfds].fd = fd
    fds[nfds].events = cond
    fds[nfds].revents = 0
    activeWatches.add watch
    nfds += 1

  if poll(cast[ptr TPollfd](addr fds), Tnfds(nfds), cint(timeout)) <= 0:
    return

  for i in 0..<nfds:
    let events = fds[i].revents
    let watch = activeWatches[i]

    var flags: cuint = 0;

    if (events and POLLIN) != 0:
      flags = flags or DBUS_WATCH_READABLE.cuint
    if (events and POLLOUT) != 0:
      flags = flags or DBUS_WATCH_WRITABLE.cuint
    if (events and POLLHUP) != 0:
      flags = flags or DBUS_WATCH_HANGUP.cuint
    if (events and POLLERR) != 0:
      flags = flags or DBUS_WATCH_ERROR.cuint

    let ok = dbus_watch_handle(watch, flags)
    assert ok != 0

    while self.conn.dispatch == DBUS_DISPATCH_DATA_REMAINS:
      discard

proc runForever*(self: MainLoop) =
  while true:
    self.tick()
