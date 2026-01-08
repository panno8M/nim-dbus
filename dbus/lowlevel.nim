import dynlib

import
  dbus/private/findlib

type
  dbus_int64_t* = clong
  dbus_uint64_t* = culong
  dbus_int32_t* = cint
  dbus_uint32_t* = cuint
  dbus_int16_t* = cshort
  dbus_uint16_t* = cushort
  dbus_unichar_t* = dbus_uint32_t
  dbus_bool_t* = dbus_uint32_t
  DBus8ByteStruct* = object
    first32*: dbus_uint32_t   #*< first 32 bits in the 8 bytes (beware endian issues)
    second32*: dbus_uint32_t  #*< second 32 bits in the 8 bytes (beware endian issues)
  DBusBasicValue* {.union.} = object
    bytes*: array[8, char]  #*< as 8 individual bytes
    i16*: dbus_int16_t        #*< as int16
    u16*: dbus_uint16_t       #*< as int16
    i32*: dbus_int32_t        #*< as int32
    u32*: dbus_uint32_t       #*< as int32
    bool_val*: dbus_bool_t    #*< as boolean
    i64*: dbus_int64_t        #*< as int64
    u64*: dbus_uint64_t       #*< as int64
    eight*: DBus8ByteStruct   #*< as 8-byte struct
    dbl*: cdouble             #*< as double
    byt*: char              #*< as byte
    str*: cstring             #*< as char* (string, object path or signature)
    fd*: cint                 #*< as Unix file descriptor
  DBusError* = object
    name*: cstring            #*< public error name field
    message*: cstring         #*< public error message field
    dummy5bits*: cuint        #*< placeholder
    padding1*: pointer        #*< placeholder
  DBusAddressEntry* = object
  DBusFreeFunction* = proc (memory: pointer) {.cdecl.}
  DBusMessage* = object
  DBusMessageIter* = object
    dummy1*: pointer          #*< Don't use this
    dummy2*: pointer          #*< Don't use this
    dummy3*: dbus_uint32_t    #*< Don't use this
    dummy4*: cint             #*< Don't use this
    dummy5*: cint             #*< Don't use this
    dummy6*: cint             #*< Don't use this
    dummy7*: cint             #*< Don't use this
    dummy8*: cint             #*< Don't use this
    dummy9*: cint             #*< Don't use this
    dummy10*: cint            #*< Don't use this
    dummy11*: cint            #*< Don't use this
    pad1*: cint               #*< Don't use this
    pad2*: cint               #*< Don't use this
    pad3*: pointer            #*< Don't use this
  DBusBusType* {.size: sizeof(cint).} = enum
    DBUS_BUS_SESSION,         #*< The login session bus
    DBUS_BUS_SYSTEM,          #*< The systemwide bus
    DBUS_BUS_STARTER          #*< The bus that started us, if any
  DBusHandlerResult* {.size: sizeof(cint).} = enum
    DBUS_HANDLER_RESULT_HANDLED, #*< Message has had its effect - no need to run more handlers.
    DBUS_HANDLER_RESULT_NOT_YET_HANDLED, #*< Message has not had any effect - see if other handlers want it.
    DBUS_HANDLER_RESULT_NEED_MEMORY #*< Need more memory in order to return #DBUS_HANDLER_RESULT_HANDLED or #DBUS_HANDLER_RESULT_NOT_YET_HANDLED. Please try again later with more memory.
  DBusWatch* = object
  DBusTimeout* = object
  DBusPreallocatedSend* = object
  DBusPendingCall* = object
  DBusConnection* = object
  DBusWatchFlags* {.size: sizeof(cint).} = enum
    DBUS_WATCH_READABLE = 1 shl 0, #*< As in POLLIN
    DBUS_WATCH_WRITABLE = 1 shl 1, #*< As in POLLOUT
    DBUS_WATCH_ERROR = 1 shl 2, #*< As in POLLERR (can't watch for
                                #                                    this, but can be present in
                                #                                    current state passed to
                                #                                    dbus_watch_handle()).
                                #
    DBUS_WATCH_HANGUP = 1 shl 3
  DBusDispatchStatus* {.size: sizeof(cint).} = enum
    DBUS_DISPATCH_DATA_REMAINS, #*< There is more data to potentially convert to messages.
    DBUS_DISPATCH_COMPLETE,   #*< All currently available data has been processed.
    DBUS_DISPATCH_NEED_MEMORY #*< More memory is needed to continue.
  DBusAddWatchFunction* = proc (watch: ptr DBusWatch; data: pointer): dbus_bool_t {.
      cdecl.}
  DBusWatchToggledFunction* = proc (watch: ptr DBusWatch; data: pointer) {.cdecl.}
  DBusRemoveWatchFunction* = proc (watch: ptr DBusWatch; data: pointer) {.cdecl.}
  DBusAddTimeoutFunction* = proc (timeout: ptr DBusTimeout; data: pointer): dbus_bool_t {.
      cdecl.}
  DBusTimeoutToggledFunction* = proc (timeout: ptr DBusTimeout; data: pointer) {.
      cdecl.}
  DBusRemoveTimeoutFunction* = proc (timeout: ptr DBusTimeout; data: pointer) {.
      cdecl.}
  DBusDispatchStatusFunction* = proc (connection: ptr DBusConnection;
                                      new_status: DBusDispatchStatus;
                                      data: pointer) {.cdecl.}
  DBusWakeupMainFunction* = proc (data: pointer) {.cdecl.}
  DBusAllowUnixUserFunction* = proc (connection: ptr DBusConnection;
                                     uid: culong; data: pointer): dbus_bool_t {.
      cdecl.}
  DBusAllowWindowsUserFunction* = proc (connection: ptr DBusConnection;
                                        user_sid: cstring; data: pointer): dbus_bool_t {.
      cdecl.}
  DBusPendingCallNotifyFunction* = proc (pending: ptr DBusPendingCall;
      user_data: pointer) {.cdecl.}
  DBusHandleMessageFunction* = proc (connection: ptr DBusConnection;
                                     message: ptr DBusMessage;
                                     user_data: pointer): DBusHandlerResult {.
      cdecl.}
  DBusObjectPathUnregisterFunction* = proc (connection: ptr DBusConnection;
      user_data: pointer) {.cdecl.}
  DBusObjectPathMessageFunction* = proc (connection: ptr DBusConnection;
      message: ptr DBusMessage; user_data: pointer): DBusHandlerResult {.cdecl.}
  DBusObjectPathVTable* = object
    unregister_function*: DBusObjectPathUnregisterFunction #*< Function to unregister this handler
    message_function*: DBusObjectPathMessageFunction #*< Function to handle messages
    dbus_internal_pad1*: proc (a2: pointer) {.cdecl.} #*< Reserved for future expansion
    dbus_internal_pad2*: proc (a2: pointer) {.cdecl.} #*< Reserved for future expansion
    dbus_internal_pad3*: proc (a2: pointer) {.cdecl.} #*< Reserved for future expansion
    dbus_internal_pad4*: proc (a2: pointer) {.cdecl.} #*< Reserved for future expansion
  DBusServer* = object
  DBusNewConnectionFunction* = proc (server: ptr DBusServer;
                                     new_connection: ptr DBusConnection;
                                     data: pointer) {.cdecl.}
  DBusSignatureIter* = object
    dummy1*: pointer          #*< Don't use this
    dummy2*: pointer          #*< Don't use this
    dummy8*: dbus_uint32_t    #*< Don't use this
    dummy12*: cint            #*< Don't use this
    dummy17*: cint            #*< Don't use this
  DBusMutex* = object
  DBusCondVar* = object
  DBusMutexNewFunction* = proc (): ptr DBusMutex {.cdecl.}
  DBusMutexFreeFunction* = proc (mutex: ptr DBusMutex) {.cdecl.}
  DBusMutexLockFunction* = proc (mutex: ptr DBusMutex): dbus_bool_t {.cdecl.}
  DBusMutexUnlockFunction* = proc (mutex: ptr DBusMutex): dbus_bool_t {.cdecl.}
  DBusRecursiveMutexNewFunction* = proc (): ptr DBusMutex {.cdecl.}
  DBusRecursiveMutexFreeFunction* = proc (mutex: ptr DBusMutex) {.cdecl.}
  DBusRecursiveMutexLockFunction* = proc (mutex: ptr DBusMutex) {.cdecl.}
  DBusRecursiveMutexUnlockFunction* = proc (mutex: ptr DBusMutex) {.cdecl.}
  DBusCondVarNewFunction* = proc (): ptr DBusCondVar {.cdecl.}
  DBusCondVarFreeFunction* = proc (cond: ptr DBusCondVar) {.cdecl.}
  DBusCondVarWaitFunction* = proc (cond: ptr DBusCondVar; mutex: ptr DBusMutex) {.
      cdecl.}
  DBusCondVarWaitTimeoutFunction* = proc (cond: ptr DBusCondVar;
      mutex: ptr DBusMutex; timeout_milliseconds: cint): dbus_bool_t {.cdecl.}
  DBusCondVarWakeOneFunction* = proc (cond: ptr DBusCondVar) {.cdecl.}
  DBusCondVarWakeAllFunction* = proc (cond: ptr DBusCondVar) {.cdecl.}
  DBusThreadFunctionsMask* {.size: sizeof(cint).} = enum
    DBUS_THREAD_FUNCTIONS_MUTEX_NEW_MASK = 1 shl 0,
    DBUS_THREAD_FUNCTIONS_MUTEX_FREE_MASK = 1 shl 1,
    DBUS_THREAD_FUNCTIONS_MUTEX_LOCK_MASK = 1 shl 2,
    DBUS_THREAD_FUNCTIONS_MUTEX_UNLOCK_MASK = 1 shl 3,
    DBUS_THREAD_FUNCTIONS_CONDVAR_NEW_MASK = 1 shl 4,
    DBUS_THREAD_FUNCTIONS_CONDVAR_FREE_MASK = 1 shl 5,
    DBUS_THREAD_FUNCTIONS_CONDVAR_WAIT_MASK = 1 shl 6,
    DBUS_THREAD_FUNCTIONS_CONDVAR_WAIT_TIMEOUT_MASK = 1 shl 7,
    DBUS_THREAD_FUNCTIONS_CONDVAR_WAKE_ONE_MASK = 1 shl 8,
    DBUS_THREAD_FUNCTIONS_CONDVAR_WAKE_ALL_MASK = 1 shl 9,
    DBUS_THREAD_FUNCTIONS_RECURSIVE_MUTEX_NEW_MASK = 1 shl 10,
    DBUS_THREAD_FUNCTIONS_RECURSIVE_MUTEX_FREE_MASK = 1 shl 11,
    DBUS_THREAD_FUNCTIONS_RECURSIVE_MUTEX_LOCK_MASK = 1 shl 12,
    DBUS_THREAD_FUNCTIONS_RECURSIVE_MUTEX_UNLOCK_MASK = 1 shl 13,
    DBUS_THREAD_FUNCTIONS_ALL_MASK = (1 shl 14) - 1
  DBusThreadFunctions* = object
    mask*: cuint              #*< Mask indicating which functions are present.
    mutex_new*: DBusMutexNewFunction #*< Function to create a mutex; optional and deprecated.
    mutex_free*: DBusMutexFreeFunction #*< Function to free a mutex; optional and deprecated.
    mutex_lock*: DBusMutexLockFunction #*< Function to lock a mutex; optional and deprecated.
    mutex_unlock*: DBusMutexUnlockFunction #*< Function to unlock a mutex; optional and deprecated.
    condvar_new*: DBusCondVarNewFunction #*< Function to create a condition variable
    condvar_free*: DBusCondVarFreeFunction #*< Function to free a condition variable
    condvar_wait*: DBusCondVarWaitFunction #*< Function to wait on a condition
    condvar_wait_timeout*: DBusCondVarWaitTimeoutFunction #*< Function to wait on a condition with a timeout
    condvar_wake_one*: DBusCondVarWakeOneFunction #*< Function to wake one thread waiting on the condition
    condvar_wake_all*: DBusCondVarWakeAllFunction #*< Function to wake all threads waiting on the condition
    recursive_mutex_new*: DBusRecursiveMutexNewFunction #*< Function to create a recursive mutex
    recursive_mutex_free*: DBusRecursiveMutexFreeFunction #*< Function to free a recursive mutex
    recursive_mutex_lock*: DBusRecursiveMutexLockFunction #*< Function to lock a recursive mutex
    recursive_mutex_unlock*: DBusRecursiveMutexUnlockFunction #*< Function to unlock a recursive mutex
    padding1*: proc () {.cdecl.} #*< Reserved for future expansion
    padding2*: proc () {.cdecl.} #*< Reserved for future expansion
    padding3*: proc () {.cdecl.} #*< Reserved for future expansion
    padding4*: proc () {.cdecl.} #*< Reserved for future expansion

proc dbus_error_init*(error: ptr DBusError) {.cdecl, importc: "dbus_error_init", dynlib: libdbus.}
proc dbus_error_free*(error: ptr DBusError) {.cdecl, importc: "dbus_error_free", dynlib: libdbus.}
proc dbus_set_error*(error: ptr DBusError; name: cstring; message: cstring) {.varargs, cdecl, importc: "dbus_set_error", dynlib: libdbus.}
proc dbus_set_error_const*(error: ptr DBusError; name: cstring; message: cstring) {.cdecl, importc: "dbus_set_error_const", dynlib: libdbus.}
proc dbus_move_error*(src: ptr DBusError; dest: ptr DBusError) {.cdecl, importc: "dbus_move_error", dynlib: libdbus.}
proc dbus_error_has_name*(error: ptr DBusError; name: cstring): dbus_bool_t {.  cdecl, importc: "dbus_error_has_name", dynlib: libdbus.}
proc dbus_error_is_set*(error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_error_is_set", dynlib: libdbus.}
proc dbus_parse_address*(address: cstring; entry: ptr ptr ptr DBusAddressEntry; array_len: ptr cint; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_parse_address", dynlib: libdbus.}
proc dbus_address_entry_get_value*(entry: ptr DBusAddressEntry; key: cstring): cstring {.cdecl, importc: "dbus_address_entry_get_value", dynlib: libdbus.}
proc dbus_address_entry_get_method*(entry: ptr DBusAddressEntry): cstring {.cdecl, importc: "dbus_address_entry_get_method", dynlib: libdbus.}
proc dbus_address_entries_free*(entries: ptr ptr DBusAddressEntry) {.cdecl, importc: "dbus_address_entries_free", dynlib: libdbus.}
proc dbus_address_escape_value*(value: cstring): cstring {.cdecl, importc: "dbus_address_escape_value", dynlib: libdbus.}
proc dbus_address_unescape_value*(value: cstring; error: ptr DBusError): cstring {.cdecl, importc: "dbus_address_unescape_value", dynlib: libdbus.}
proc dbus_malloc*(bytes: csize_t): pointer {.cdecl, importc: "dbus_malloc", dynlib: libdbus.}
proc dbus_malloc0*(bytes: csize_t): pointer {.cdecl, importc: "dbus_malloc0", dynlib: libdbus.}
proc dbus_realloc*(memory: pointer; bytes: csize_t): pointer {.cdecl, importc: "dbus_realloc", dynlib: libdbus.}
proc dbus_free*(memory: pointer) {.cdecl, importc: "dbus_free", dynlib: libdbus.}
proc dbus_free_string_array*(str_array: cstringArray) {.cdecl, importc: "dbus_free_string_array", dynlib: libdbus.}
proc dbus_shutdown*() {.cdecl, importc: "dbus_shutdown", dynlib: libdbus.}
proc dbus_message_new*(message_type: cint): ptr DBusMessage {.cdecl, importc: "dbus_message_new", dynlib: libdbus.}
proc dbus_message_new_method_call*(bus_name: cstring; path: cstring; iface: cstring; `method`: cstring): ptr DBusMessage {.cdecl, importc: "dbus_message_new_method_call", dynlib: libdbus.}
proc dbus_message_new_method_return*(method_call: ptr DBusMessage): ptr DBusMessage {.cdecl, importc: "dbus_message_new_method_return", dynlib: libdbus.}
proc dbus_message_new_signal*(path: cstring; iface: cstring; name: cstring): ptr DBusMessage {.cdecl, importc: "dbus_message_new_signal", dynlib: libdbus.}
proc dbus_message_new_error*(reply_to: ptr DBusMessage; error_name: cstring; error_message: cstring): ptr DBusMessage {.cdecl, importc: "dbus_message_new_error", dynlib: libdbus.}
proc dbus_message_new_error_printf*(reply_to: ptr DBusMessage; error_name: cstring; error_format: cstring): ptr DBusMessage {.varargs, cdecl, importc: "dbus_message_new_error_printf", dynlib: libdbus.}
proc dbus_message_copy*(message: ptr DBusMessage): ptr DBusMessage {.cdecl, importc: "dbus_message_copy", dynlib: libdbus.}
proc dbus_message_ref*(message: ptr DBusMessage): ptr DBusMessage {.cdecl, importc: "dbus_message_ref", dynlib: libdbus.}
proc dbus_message_unref*(message: ptr DBusMessage) {.cdecl, importc: "dbus_message_unref", dynlib: libdbus.}
proc dbus_message_get_type*(message: ptr DBusMessage): cint {.cdecl, importc: "dbus_message_get_type", dynlib: libdbus.}
proc dbus_message_set_path*(message: ptr DBusMessage; object_path: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_set_path", dynlib: libdbus.}
proc dbus_message_get_path*(message: ptr DBusMessage): cstring {.cdecl, importc: "dbus_message_get_path", dynlib: libdbus.}
proc dbus_message_has_path*(message: ptr DBusMessage; object_path: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_has_path", dynlib: libdbus.}
proc dbus_message_set_interface*(message: ptr DBusMessage; iface: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_set_interface", dynlib: libdbus.}
proc dbus_message_get_interface*(message: ptr DBusMessage): cstring {.cdecl, importc: "dbus_message_get_interface", dynlib: libdbus.}
proc dbus_message_has_interface*(message: ptr DBusMessage; iface: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_has_interface", dynlib: libdbus.}
proc dbus_message_set_member*(message: ptr DBusMessage; member: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_set_member", dynlib: libdbus.}
proc dbus_message_get_member*(message: ptr DBusMessage): cstring {.cdecl, importc: "dbus_message_get_member", dynlib: libdbus.}
proc dbus_message_has_member*(message: ptr DBusMessage; member: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_has_member", dynlib: libdbus.}
proc dbus_message_set_error_name*(message: ptr DBusMessage; name: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_set_error_name", dynlib: libdbus.}
proc dbus_message_get_error_name*(message: ptr DBusMessage): cstring {.cdecl, importc: "dbus_message_get_error_name", dynlib: libdbus.}
proc dbus_message_set_destination*(message: ptr DBusMessage; destination: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_set_destination", dynlib: libdbus.}
proc dbus_message_get_destination*(message: ptr DBusMessage): cstring {.cdecl, importc: "dbus_message_get_destination", dynlib: libdbus.}
proc dbus_message_set_sender*(message: ptr DBusMessage; sender: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_set_sender", dynlib: libdbus.}
proc dbus_message_get_sender*(message: ptr DBusMessage): cstring {.cdecl, importc: "dbus_message_get_sender", dynlib: libdbus.}
proc dbus_message_get_signature*(message: ptr DBusMessage): cstring {.cdecl, importc: "dbus_message_get_signature", dynlib: libdbus.}
proc dbus_message_set_no_reply*(message: ptr DBusMessage; no_reply: dbus_bool_t) {.cdecl, importc: "dbus_message_set_no_reply", dynlib: libdbus.}
proc dbus_message_get_no_reply*(message: ptr DBusMessage): dbus_bool_t {.cdecl, importc: "dbus_message_get_no_reply", dynlib: libdbus.}
proc dbus_message_is_method_call*(message: ptr DBusMessage; iface: cstring; `method`: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_is_method_call", dynlib: libdbus.}
proc dbus_message_is_signal*(message: ptr DBusMessage; iface: cstring; signal_name: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_is_signal", dynlib: libdbus.}
proc dbus_message_is_error*(message: ptr DBusMessage; error_name: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_is_error", dynlib: libdbus.}
proc dbus_message_has_destination*(message: ptr DBusMessage; bus_name: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_has_destination", dynlib: libdbus.}
proc dbus_message_has_sender*(message: ptr DBusMessage; unique_bus_name: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_has_sender", dynlib: libdbus.}
proc dbus_message_has_signature*(message: ptr DBusMessage; signature: cstring): dbus_bool_t {.cdecl, importc: "dbus_message_has_signature", dynlib: libdbus.}
proc dbus_message_get_serial*(message: ptr DBusMessage): dbus_uint32_t {.cdecl, importc: "dbus_message_get_serial", dynlib: libdbus.}
proc dbus_message_set_serial*(message: ptr DBusMessage; serial: dbus_uint32_t) {.cdecl, importc: "dbus_message_set_serial", dynlib: libdbus.}
proc dbus_message_set_reply_serial*(message: ptr DBusMessage; reply_serial: dbus_uint32_t): dbus_bool_t {.cdecl, importc: "dbus_message_set_reply_serial", dynlib: libdbus.}
proc dbus_message_get_reply_serial*(message: ptr DBusMessage): dbus_uint32_t {.cdecl, importc: "dbus_message_get_reply_serial", dynlib: libdbus.}
proc dbus_message_set_auto_start*(message: ptr DBusMessage; auto_start: dbus_bool_t) {.cdecl, importc: "dbus_message_set_auto_start", dynlib: libdbus.}
proc dbus_message_get_auto_start*(message: ptr DBusMessage): dbus_bool_t {.cdecl, importc: "dbus_message_get_auto_start", dynlib: libdbus.}
proc dbus_message_get_path_decomposed*(message: ptr DBusMessage; path: ptr cstringArray): dbus_bool_t {.cdecl, importc: "dbus_message_get_path_decomposed", dynlib: libdbus.}
proc dbus_message_append_args*(message: ptr DBusMessage; first_arg_type: cint): dbus_bool_t {.varargs, cdecl, importc: "dbus_message_append_args", dynlib: libdbus.}
proc dbus_message_get_args*(message: ptr DBusMessage; error: ptr DBusError; first_arg_type: cint): dbus_bool_t {.varargs, cdecl, importc: "dbus_message_get_args", dynlib: libdbus.}
proc dbus_message_contains_unix_fds*(message: ptr DBusMessage): dbus_bool_t {.cdecl, importc: "dbus_message_contains_unix_fds", dynlib: libdbus.}
proc dbus_message_iter_init*(message: ptr DBusMessage; iter: ptr DBusMessageIter): dbus_bool_t {.cdecl, importc: "dbus_message_iter_init", dynlib: libdbus.}
proc dbus_message_iter_has_next*(iter: ptr DBusMessageIter): dbus_bool_t {.cdecl, importc: "dbus_message_iter_has_next", dynlib: libdbus.}
proc dbus_message_iter_next*(iter: ptr DBusMessageIter): dbus_bool_t {.cdecl, importc: "dbus_message_iter_next", dynlib: libdbus.}
proc dbus_message_iter_get_signature*(iter: ptr DBusMessageIter): cstring {.cdecl, importc: "dbus_message_iter_get_signature", dynlib: libdbus.}
proc dbus_message_iter_get_arg_type*(iter: ptr DBusMessageIter): cint {.cdecl, importc: "dbus_message_iter_get_arg_type", dynlib: libdbus.}
proc dbus_message_iter_get_element_type*(iter: ptr DBusMessageIter): cint {.cdecl, importc: "dbus_message_iter_get_element_type", dynlib: libdbus.}
proc dbus_message_iter_recurse*(iter: ptr DBusMessageIter; sub: ptr DBusMessageIter) {.cdecl, importc: "dbus_message_iter_recurse", dynlib: libdbus.}
proc dbus_message_iter_get_basic*(iter: ptr DBusMessageIter; value: pointer) {.cdecl, importc: "dbus_message_iter_get_basic", dynlib: libdbus.}
proc dbus_message_iter_get_array_len*(iter: ptr DBusMessageIter): cint {.cdecl, importc: "dbus_message_iter_get_array_len", dynlib: libdbus.}
proc dbus_message_iter_get_fixed_array*(iter: ptr DBusMessageIter; value: pointer; n_elements: ptr cint) {.cdecl, importc: "dbus_message_iter_get_fixed_array", dynlib: libdbus.}
proc dbus_message_iter_init_append*(message: ptr DBusMessage; iter: ptr DBusMessageIter) {.cdecl, importc: "dbus_message_iter_init_append", dynlib: libdbus.}
proc dbus_message_iter_append_basic*(iter: ptr DBusMessageIter; `type`: cint; value: pointer): dbus_bool_t {.cdecl, importc: "dbus_message_iter_append_basic", dynlib: libdbus.}
proc dbus_message_iter_append_fixed_array*(iter: ptr DBusMessageIter; element_type: cint; value: pointer; n_elements: cint): dbus_bool_t {.cdecl, importc: "dbus_message_iter_append_fixed_array", dynlib: libdbus.}
proc dbus_message_iter_open_container*(iter: ptr DBusMessageIter; `type`: cint; contained_signature: cstring; sub: ptr DBusMessageIter): dbus_bool_t {.cdecl, importc: "dbus_message_iter_open_container", dynlib: libdbus.}
proc dbus_message_iter_close_container*(iter: ptr DBusMessageIter; sub: ptr DBusMessageIter): dbus_bool_t {.cdecl, importc: "dbus_message_iter_close_container", dynlib: libdbus.}
proc dbus_message_iter_abandon_container*(iter: ptr DBusMessageIter; sub: ptr DBusMessageIter) {.cdecl, importc: "dbus_message_iter_abandon_container", dynlib: libdbus.}
proc dbus_message_lock*(message: ptr DBusMessage) {.cdecl, importc: "dbus_message_lock", dynlib: libdbus.}
proc dbus_set_error_from_message*(error: ptr DBusError; message: ptr DBusMessage): dbus_bool_t {.cdecl, importc: "dbus_set_error_from_message", dynlib: libdbus.}
proc dbus_message_allocate_data_slot*(slot_p: ptr dbus_int32_t): dbus_bool_t {.cdecl, importc: "dbus_message_allocate_data_slot", dynlib: libdbus.}
proc dbus_message_free_data_slot*(slot_p: ptr dbus_int32_t) {.cdecl, importc: "dbus_message_free_data_slot", dynlib: libdbus.}
proc dbus_message_set_data*(message: ptr DBusMessage; slot: dbus_int32_t; data: pointer; free_data_func: DBusFreeFunction): dbus_bool_t {.cdecl, importc: "dbus_message_set_data", dynlib: libdbus.}
proc dbus_message_get_data*(message: ptr DBusMessage; slot: dbus_int32_t): pointer {.cdecl, importc: "dbus_message_get_data", dynlib: libdbus.}
proc dbus_message_type_from_string*(type_str: cstring): cint {.cdecl, importc: "dbus_message_type_from_string", dynlib: libdbus.}
proc dbus_message_type_to_string*(`type`: cint): cstring {.cdecl, importc: "dbus_message_type_to_string", dynlib: libdbus.}
proc dbus_message_marshal*(msg: ptr DBusMessage; marshalled_data_p: cstringArray; len_p: ptr cint): dbus_bool_t {.cdecl, importc: "dbus_message_marshal", dynlib: libdbus.}
proc dbus_message_demarshal*(str: cstring; len: cint; error: ptr DBusError): ptr DBusMessage {.cdecl, importc: "dbus_message_demarshal", dynlib: libdbus.}
proc dbus_message_demarshal_bytes_needed*(str: cstring; len: cint): cint {.cdecl, importc: "dbus_message_demarshal_bytes_needed", dynlib: libdbus.}
proc dbus_connection_open*(address: cstring; error: ptr DBusError): ptr DBusConnection {.cdecl, importc: "dbus_connection_open", dynlib: libdbus.}
proc dbus_connection_open_private*(address: cstring; error: ptr DBusError): ptr DBusConnection {.cdecl, importc: "dbus_connection_open_private", dynlib: libdbus.}
proc dbus_connection_ref*(connection: ptr DBusConnection): ptr DBusConnection {.cdecl, importc: "dbus_connection_ref", dynlib: libdbus.}
proc dbus_connection_unref*(connection: ptr DBusConnection) {.cdecl, importc: "dbus_connection_unref", dynlib: libdbus.}
proc dbus_connection_close*(connection: ptr DBusConnection) {.cdecl, importc: "dbus_connection_close", dynlib: libdbus.}
proc dbus_connection_get_is_connected*(connection: ptr DBusConnection): dbus_bool_t {.cdecl, importc: "dbus_connection_get_is_connected", dynlib: libdbus.}
proc dbus_connection_get_is_authenticated*(connection: ptr DBusConnection): dbus_bool_t {.cdecl, importc: "dbus_connection_get_is_authenticated", dynlib: libdbus.}
proc dbus_connection_get_is_anonymous*(connection: ptr DBusConnection): dbus_bool_t {.cdecl, importc: "dbus_connection_get_is_anonymous", dynlib: libdbus.}
proc dbus_connection_get_server_id*(connection: ptr DBusConnection): cstring {.cdecl, importc: "dbus_connection_get_server_id", dynlib: libdbus.}
proc dbus_connection_can_send_type*(connection: ptr DBusConnection; `type`: cint): dbus_bool_t {.cdecl, importc: "dbus_connection_can_send_type", dynlib: libdbus.}
proc dbus_connection_set_exit_on_disconnect*(connection: ptr DBusConnection; exit_on_disconnect: dbus_bool_t) {.cdecl, importc: "dbus_connection_set_exit_on_disconnect", dynlib: libdbus.}
proc dbus_connection_flush*(connection: ptr DBusConnection) {.cdecl, importc: "dbus_connection_flush", dynlib: libdbus.}
proc dbus_connection_read_write_dispatch*(connection: ptr DBusConnection; timeout_milliseconds: cint): dbus_bool_t {.cdecl, importc: "dbus_connection_read_write_dispatch", dynlib: libdbus.}
proc dbus_connection_read_write*(connection: ptr DBusConnection; timeout_milliseconds: cint): dbus_bool_t {.cdecl, importc: "dbus_connection_read_write", dynlib: libdbus.}
proc dbus_connection_borrow_message*(connection: ptr DBusConnection): ptr DBusMessage {.cdecl, importc: "dbus_connection_borrow_message", dynlib: libdbus.}
proc dbus_connection_return_message*(connection: ptr DBusConnection; message: ptr DBusMessage) {.cdecl, importc: "dbus_connection_return_message", dynlib: libdbus.}
proc dbus_connection_steal_borrowed_message*(connection: ptr DBusConnection; message: ptr DBusMessage) {.cdecl, importc: "dbus_connection_steal_borrowed_message", dynlib: libdbus.}
proc dbus_connection_pop_message*(connection: ptr DBusConnection): ptr DBusMessage {.cdecl, importc: "dbus_connection_pop_message", dynlib: libdbus.}
proc dbus_connection_get_dispatch_status*(connection: ptr DBusConnection): DBusDispatchStatus {.cdecl, importc: "dbus_connection_get_dispatch_status", dynlib: libdbus.}
proc dbus_connection_dispatch*(connection: ptr DBusConnection): DBusDispatchStatus {.cdecl, importc: "dbus_connection_dispatch", dynlib: libdbus.}
proc dbus_connection_has_messages_to_send*(connection: ptr DBusConnection): dbus_bool_t {.cdecl, importc: "dbus_connection_has_messages_to_send", dynlib: libdbus.}
proc dbus_connection_send*(connection: ptr DBusConnection; message: ptr DBusMessage; client_serial: ptr dbus_uint32_t): dbus_bool_t {.cdecl, importc: "dbus_connection_send", dynlib: libdbus.}
proc dbus_connection_send_with_reply*(connection: ptr DBusConnection; message: ptr DBusMessage; pending_return: ptr ptr DBusPendingCall; timeout_milliseconds: cint): dbus_bool_t {.cdecl, importc: "dbus_connection_send_with_reply", dynlib: libdbus.}
proc dbus_connection_send_with_reply_and_block*(connection: ptr DBusConnection; message: ptr DBusMessage; timeout_milliseconds: cint; error: ptr DBusError): ptr DBusMessage {.cdecl, importc: "dbus_connection_send_with_reply_and_block", dynlib: libdbus.}
proc dbus_connection_set_watch_functions*(connection: ptr DBusConnection; add_function: DBusAddWatchFunction; remove_function: DBusRemoveWatchFunction; toggled_function: DBusWatchToggledFunction; data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.cdecl, importc: "dbus_connection_set_watch_functions", dynlib: libdbus.}
proc dbus_connection_set_timeout_functions*(connection: ptr DBusConnection; add_function: DBusAddTimeoutFunction; remove_function: DBusRemoveTimeoutFunction; toggled_function: DBusTimeoutToggledFunction; data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.cdecl, importc: "dbus_connection_set_timeout_functions", dynlib: libdbus.}
proc dbus_connection_set_wakeup_main_function*(connection: ptr DBusConnection; wakeup_main_function: DBusWakeupMainFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl, importc: "dbus_connection_set_wakeup_main_function", dynlib: libdbus.}
proc dbus_connection_set_dispatch_status_function*(connection: ptr DBusConnection; function: DBusDispatchStatusFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl, importc: "dbus_connection_set_dispatch_status_function", dynlib: libdbus.}
proc dbus_connection_get_unix_user*(connection: ptr DBusConnection; uid: ptr culong): dbus_bool_t {.cdecl, importc: "dbus_connection_get_unix_user", dynlib: libdbus.}
proc dbus_connection_get_unix_process_id*(connection: ptr DBusConnection; pid: ptr culong): dbus_bool_t {.cdecl, importc: "dbus_connection_get_unix_process_id", dynlib: libdbus.}
proc dbus_connection_get_adt_audit_session_data*(connection: ptr DBusConnection; data: ptr pointer; data_size: ptr dbus_int32_t): dbus_bool_t {.cdecl, importc: "dbus_connection_get_adt_audit_session_data", dynlib: libdbus.}
proc dbus_connection_set_unix_user_function*(connection: ptr DBusConnection; function: DBusAllowUnixUserFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl, importc: "dbus_connection_set_unix_user_function", dynlib: libdbus.}
proc dbus_connection_get_windows_user*(connection: ptr DBusConnection; windows_sid_p: cstringArray): dbus_bool_t {.cdecl, importc: "dbus_connection_get_windows_user", dynlib: libdbus.}
proc dbus_connection_set_windows_user_function*(connection: ptr DBusConnection; function: DBusAllowWindowsUserFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl, importc: "dbus_connection_set_windows_user_function", dynlib: libdbus.}
proc dbus_connection_set_allow_anonymous*(connection: ptr DBusConnection; value: dbus_bool_t) {.cdecl, importc: "dbus_connection_set_allow_anonymous", dynlib: libdbus.}
proc dbus_connection_set_route_peer_messages*(connection: ptr DBusConnection; value: dbus_bool_t) {.cdecl, importc: "dbus_connection_set_route_peer_messages", dynlib: libdbus.}

# Filters
proc dbus_connection_add_filter*(connection: ptr DBusConnection; function: DBusHandleMessageFunction; user_data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.  cdecl, importc: "dbus_connection_add_filter", dynlib: libdbus.}
proc dbus_connection_remove_filter*(connection: ptr DBusConnection; function: DBusHandleMessageFunction; user_data: pointer) {.cdecl, importc: "dbus_connection_remove_filter", dynlib: libdbus.}

# Other
proc dbus_connection_allocate_data_slot*(slot_p: ptr dbus_int32_t): dbus_bool_t {.  cdecl, importc: "dbus_connection_allocate_data_slot", dynlib: libdbus.}
proc dbus_connection_free_data_slot*(slot_p: ptr dbus_int32_t) {.cdecl, importc: "dbus_connection_free_data_slot", dynlib: libdbus.}
proc dbus_connection_set_data*(connection: ptr DBusConnection; slot: dbus_int32_t; data: pointer; free_data_func: DBusFreeFunction): dbus_bool_t {.cdecl, importc: "dbus_connection_set_data", dynlib: libdbus.}
proc dbus_connection_get_data*(connection: ptr DBusConnection; slot: dbus_int32_t): pointer {.cdecl, importc: "dbus_connection_get_data", dynlib: libdbus.}
proc dbus_connection_set_change_sigpipe*(will_modify_sigpipe: dbus_bool_t) {.cdecl, importc: "dbus_connection_set_change_sigpipe", dynlib: libdbus.}
proc dbus_connection_set_max_message_size*(connection: ptr DBusConnection; size: clong) {.cdecl, importc: "dbus_connection_set_max_message_size", dynlib: libdbus.}
proc dbus_connection_get_max_message_size*(connection: ptr DBusConnection): clong {.cdecl, importc: "dbus_connection_get_max_message_size", dynlib: libdbus.}
proc dbus_connection_set_max_received_size*(connection: ptr DBusConnection; size: clong) {.cdecl, importc: "dbus_connection_set_max_received_size", dynlib: libdbus.}
proc dbus_connection_get_max_received_size*(connection: ptr DBusConnection): clong {.cdecl, importc: "dbus_connection_get_max_received_size", dynlib: libdbus.}
proc dbus_connection_set_max_message_unix_fds*(connection: ptr DBusConnection; n: clong) {.cdecl, importc: "dbus_connection_set_max_message_unix_fds", dynlib: libdbus.}
proc dbus_connection_get_max_message_unix_fds*(connection: ptr DBusConnection): clong {.cdecl, importc: "dbus_connection_get_max_message_unix_fds", dynlib: libdbus.}
proc dbus_connection_set_max_received_unix_fds*(connection: ptr DBusConnection; n: clong) {.cdecl, importc: "dbus_connection_set_max_received_unix_fds", dynlib: libdbus.}
proc dbus_connection_get_max_received_unix_fds*(connection: ptr DBusConnection): clong {.cdecl, importc: "dbus_connection_get_max_received_unix_fds", dynlib: libdbus.}
proc dbus_connection_get_outgoing_size*(connection: ptr DBusConnection): clong {.cdecl, importc: "dbus_connection_get_outgoing_size", dynlib: libdbus.}
proc dbus_connection_get_outgoing_unix_fds*(connection: ptr DBusConnection): clong {.cdecl, importc: "dbus_connection_get_outgoing_unix_fds", dynlib: libdbus.}
proc dbus_connection_preallocate_send*(connection: ptr DBusConnection): ptr DBusPreallocatedSend {.cdecl, importc: "dbus_connection_preallocate_send", dynlib: libdbus.}
proc dbus_connection_free_preallocated_send*(connection: ptr DBusConnection; preallocated: ptr DBusPreallocatedSend) {.cdecl, importc: "dbus_connection_free_preallocated_send", dynlib: libdbus.}
proc dbus_connection_send_preallocated*(connection: ptr DBusConnection; preallocated: ptr DBusPreallocatedSend; message: ptr DBusMessage; client_serial: ptr dbus_uint32_t) {.cdecl, importc: "dbus_connection_send_preallocated", dynlib: libdbus.}
proc dbus_connection_try_register_object_path*(connection: ptr DBusConnection; path: cstring; vtable: ptr DBusObjectPathVTable; user_data: pointer; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_connection_try_register_object_path", dynlib: libdbus.}
proc dbus_connection_register_object_path*(connection: ptr DBusConnection; path: cstring; vtable: ptr DBusObjectPathVTable; user_data: pointer): dbus_bool_t {.  cdecl, importc: "dbus_connection_register_object_path", dynlib: libdbus.}
proc dbus_connection_try_register_fallback*(connection: ptr DBusConnection; path: cstring; vtable: ptr DBusObjectPathVTable; user_data: pointer; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_connection_try_register_fallback", dynlib: libdbus.}
proc dbus_connection_register_fallback*(connection: ptr DBusConnection; path: cstring; vtable: ptr DBusObjectPathVTable; user_data: pointer): dbus_bool_t {.cdecl, importc: "dbus_connection_register_fallback", dynlib: libdbus.}
proc dbus_connection_unregister_object_path*(connection: ptr DBusConnection; path: cstring): dbus_bool_t {.cdecl, importc: "dbus_connection_unregister_object_path", dynlib: libdbus.}
proc dbus_connection_get_object_path_data*(connection: ptr DBusConnection; path: cstring; data_p: ptr pointer): dbus_bool_t {.cdecl, importc: "dbus_connection_get_object_path_data", dynlib: libdbus.}
proc dbus_connection_list_registered*(connection: ptr DBusConnection; parent_path: cstring; child_entries: ptr cstringArray): dbus_bool_t {.cdecl, importc: "dbus_connection_list_registered", dynlib: libdbus.}
proc dbus_connection_get_unix_fd*(connection: ptr DBusConnection; fd: ptr cint): dbus_bool_t {.cdecl, importc: "dbus_connection_get_unix_fd", dynlib: libdbus.}
proc dbus_connection_get_socket*(connection: ptr DBusConnection; fd: ptr cint): dbus_bool_t {.cdecl, importc: "dbus_connection_get_socket", dynlib: libdbus.}
proc dbus_watch_get_fd*(watch: ptr DBusWatch): cint {.cdecl, importc: "dbus_watch_get_fd", dynlib: libdbus.}
proc dbus_watch_get_unix_fd*(watch: ptr DBusWatch): cint {.cdecl, importc: "dbus_watch_get_unix_fd", dynlib: libdbus.}
proc dbus_watch_get_socket*(watch: ptr DBusWatch): cint {.cdecl, importc: "dbus_watch_get_socket", dynlib: libdbus.}
proc dbus_watch_get_flags*(watch: ptr DBusWatch): cuint {.cdecl, importc: "dbus_watch_get_flags", dynlib: libdbus.}
proc dbus_watch_get_data*(watch: ptr DBusWatch): pointer {.cdecl, importc: "dbus_watch_get_data", dynlib: libdbus.}
proc dbus_watch_set_data*(watch: ptr DBusWatch; data: pointer; free_data_function: DBusFreeFunction) {.cdecl, importc: "dbus_watch_set_data", dynlib: libdbus.}
proc dbus_watch_handle*(watch: ptr DBusWatch; flags: cuint): dbus_bool_t {.cdecl, importc: "dbus_watch_handle", dynlib: libdbus.}
proc dbus_watch_get_enabled*(watch: ptr DBusWatch): dbus_bool_t {.cdecl, importc: "dbus_watch_get_enabled", dynlib: libdbus.}
proc dbus_timeout_get_interval*(timeout: ptr DBusTimeout): cint {.cdecl, importc: "dbus_timeout_get_interval", dynlib: libdbus.}
proc dbus_timeout_get_data*(timeout: ptr DBusTimeout): pointer {.cdecl, importc: "dbus_timeout_get_data", dynlib: libdbus.}
proc dbus_timeout_set_data*(timeout: ptr DBusTimeout; data: pointer; free_data_function: DBusFreeFunction) {.cdecl, importc: "dbus_timeout_set_data", dynlib: libdbus.}
proc dbus_timeout_handle*(timeout: ptr DBusTimeout): dbus_bool_t {.cdecl, importc: "dbus_timeout_handle", dynlib: libdbus.}
proc dbus_timeout_get_enabled*(timeout: ptr DBusTimeout): dbus_bool_t {.cdecl, importc: "dbus_timeout_get_enabled", dynlib: libdbus.}
proc dbus_bus_get*(`type`: DBusBusType; error: ptr DBusError): ptr DBusConnection {.cdecl, importc: "dbus_bus_get", dynlib: libdbus.}
proc dbus_bus_get_private*(`type`: DBusBusType; error: ptr DBusError): ptr DBusConnection {.cdecl, importc: "dbus_bus_get_private", dynlib: libdbus.}
proc dbus_bus_register*(connection: ptr DBusConnection; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_bus_register", dynlib: libdbus.}
proc dbus_bus_set_unique_name*(connection: ptr DBusConnection; unique_name: cstring): dbus_bool_t {.cdecl, importc: "dbus_bus_set_unique_name", dynlib: libdbus.}
proc dbus_bus_get_unique_name*(connection: ptr DBusConnection): cstring {.cdecl, importc: "dbus_bus_get_unique_name", dynlib: libdbus.}
proc dbus_bus_get_unix_user*(connection: ptr DBusConnection; name: cstring; error: ptr DBusError): culong {.cdecl, importc: "dbus_bus_get_unix_user", dynlib: libdbus.}
proc dbus_bus_get_id*(connection: ptr DBusConnection; error: ptr DBusError): cstring {.cdecl, importc: "dbus_bus_get_id", dynlib: libdbus.}
proc dbus_bus_request_name*(connection: ptr DBusConnection; name: cstring; flags: cuint; error: ptr DBusError): cint {.cdecl, importc: "dbus_bus_request_name", dynlib: libdbus.}
proc dbus_bus_release_name*(connection: ptr DBusConnection; name: cstring; error: ptr DBusError): cint {.cdecl, importc: "dbus_bus_release_name", dynlib: libdbus.}
proc dbus_bus_name_has_owner*(connection: ptr DBusConnection; name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_bus_name_has_owner", dynlib: libdbus.}
proc dbus_bus_start_service_by_name*(connection: ptr DBusConnection; name: cstring; flags: dbus_uint32_t; reply: ptr dbus_uint32_t; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_bus_start_service_by_name", dynlib: libdbus.}
proc dbus_bus_add_match*(connection: ptr DBusConnection; rule: cstring; error: ptr DBusError) {.cdecl, importc: "dbus_bus_add_match", dynlib: libdbus.}
proc dbus_bus_remove_match*(connection: ptr DBusConnection; rule: cstring; error: ptr DBusError) {.cdecl, importc: "dbus_bus_remove_match", dynlib: libdbus.}
proc dbus_get_local_machine_id*(): cstring {.cdecl, importc: "dbus_get_local_machine_id", dynlib: libdbus.}
proc dbus_get_version*(major_version_p: ptr cint; minor_version_p: ptr cint; micro_version_p: ptr cint) {.cdecl, importc: "dbus_get_version", dynlib: libdbus.}
proc dbus_pending_call_ref*(pending: ptr DBusPendingCall): ptr DBusPendingCall {.cdecl, importc: "dbus_pending_call_ref", dynlib: libdbus.}
proc dbus_pending_call_unref*(pending: ptr DBusPendingCall) {.cdecl, importc: "dbus_pending_call_unref", dynlib: libdbus.}
proc dbus_pending_call_set_notify*(pending: ptr DBusPendingCall; function: DBusPendingCallNotifyFunction; user_data: pointer; free_user_data: DBusFreeFunction): dbus_bool_t {.cdecl, importc: "dbus_pending_call_set_notify", dynlib: libdbus.}
proc dbus_pending_call_cancel*(pending: ptr DBusPendingCall) {.cdecl, importc: "dbus_pending_call_cancel", dynlib: libdbus.}
proc dbus_pending_call_get_completed*(pending: ptr DBusPendingCall): dbus_bool_t {.cdecl, importc: "dbus_pending_call_get_completed", dynlib: libdbus.}
proc dbus_pending_call_steal_reply*(pending: ptr DBusPendingCall): ptr DBusMessage {.cdecl, importc: "dbus_pending_call_steal_reply", dynlib: libdbus.}
proc dbus_pending_call_block*(pending: ptr DBusPendingCall) {.cdecl, importc: "dbus_pending_call_block", dynlib: libdbus.}
proc dbus_pending_call_allocate_data_slot*(slot_p: ptr dbus_int32_t): dbus_bool_t {.cdecl, importc: "dbus_pending_call_allocate_data_slot", dynlib: libdbus.}
proc dbus_pending_call_free_data_slot*(slot_p: ptr dbus_int32_t) {.cdecl, importc: "dbus_pending_call_free_data_slot", dynlib: libdbus.}
proc dbus_pending_call_set_data*(pending: ptr DBusPendingCall; slot: dbus_int32_t; data: pointer; free_data_func: DBusFreeFunction): dbus_bool_t {.  cdecl, importc: "dbus_pending_call_set_data", dynlib: libdbus.}
proc dbus_pending_call_get_data*(pending: ptr DBusPendingCall; slot: dbus_int32_t): pointer {.cdecl, importc: "dbus_pending_call_get_data", dynlib: libdbus.}
proc dbus_server_listen*(address: cstring; error: ptr DBusError): ptr DBusServer {.cdecl, importc: "dbus_server_listen", dynlib: libdbus.}
proc dbus_server_ref*(server: ptr DBusServer): ptr DBusServer {.cdecl, importc: "dbus_server_ref", dynlib: libdbus.}
proc dbus_server_unref*(server: ptr DBusServer) {.cdecl, importc: "dbus_server_unref", dynlib: libdbus.}
proc dbus_server_disconnect*(server: ptr DBusServer) {.cdecl, importc: "dbus_server_disconnect", dynlib: libdbus.}
proc dbus_server_get_is_connected*(server: ptr DBusServer): dbus_bool_t {.cdecl, importc: "dbus_server_get_is_connected", dynlib: libdbus.}
proc dbus_server_get_address*(server: ptr DBusServer): cstring {.cdecl, importc: "dbus_server_get_address", dynlib: libdbus.}
proc dbus_server_get_id*(server: ptr DBusServer): cstring {.cdecl, importc: "dbus_server_get_id", dynlib: libdbus.}
proc dbus_server_set_new_connection_function*(server: ptr DBusServer; function: DBusNewConnectionFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl, importc: "dbus_server_set_new_connection_function", dynlib: libdbus.}
proc dbus_server_set_watch_functions*(server: ptr DBusServer; add_function: DBusAddWatchFunction; remove_function: DBusRemoveWatchFunction; toggled_function: DBusWatchToggledFunction; data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.cdecl, importc: "dbus_server_set_watch_functions", dynlib: libdbus.}
proc dbus_server_set_timeout_functions*(server: ptr DBusServer; add_function: DBusAddTimeoutFunction; remove_function: DBusRemoveTimeoutFunction; toggled_function: DBusTimeoutToggledFunction; data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.cdecl, importc: "dbus_server_set_timeout_functions", dynlib: libdbus.}
proc dbus_server_set_auth_mechanisms*(server: ptr DBusServer; mechanisms: cstringArray): dbus_bool_t {.cdecl, importc: "dbus_server_set_auth_mechanisms", dynlib: libdbus.}
proc dbus_server_allocate_data_slot*(slot_p: ptr dbus_int32_t): dbus_bool_t {.cdecl, importc: "dbus_server_allocate_data_slot", dynlib: libdbus.}
proc dbus_server_free_data_slot*(slot_p: ptr dbus_int32_t) {.cdecl, importc: "dbus_server_free_data_slot", dynlib: libdbus.}
proc dbus_server_set_data*(server: ptr DBusServer; slot: cint; data: pointer; free_data_func: DBusFreeFunction): dbus_bool_t {.  cdecl, importc: "dbus_server_set_data", dynlib: libdbus.}
proc dbus_server_get_data*(server: ptr DBusServer; slot: cint): pointer {.cdecl, importc: "dbus_server_get_data", dynlib: libdbus.}
proc dbus_signature_iter_init*(iter: ptr DBusSignatureIter; signature: cstring) {.cdecl, importc: "dbus_signature_iter_init", dynlib: libdbus.}
proc dbus_signature_iter_get_current_type*(iter: ptr DBusSignatureIter): cint {.cdecl, importc: "dbus_signature_iter_get_current_type", dynlib: libdbus.}
proc dbus_signature_iter_get_signature*(iter: ptr DBusSignatureIter): cstring {.cdecl, importc: "dbus_signature_iter_get_signature", dynlib: libdbus.}
proc dbus_signature_iter_get_element_type*(iter: ptr DBusSignatureIter): cint {.cdecl, importc: "dbus_signature_iter_get_element_type", dynlib: libdbus.}
proc dbus_signature_iter_next*(iter: ptr DBusSignatureIter): dbus_bool_t {.cdecl, importc: "dbus_signature_iter_next", dynlib: libdbus.}
proc dbus_signature_iter_recurse*(iter: ptr DBusSignatureIter; subiter: ptr DBusSignatureIter) {.cdecl, importc: "dbus_signature_iter_recurse", dynlib: libdbus.}
proc dbus_signature_validate*(signature: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_signature_validate", dynlib: libdbus.}
proc dbus_signature_validate_single*(signature: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_signature_validate_single", dynlib: libdbus.}
proc dbus_type_is_valid*(typecode: cint): dbus_bool_t {.cdecl, importc: "dbus_type_is_valid", dynlib: libdbus.}
proc dbus_type_is_basic*(typecode: cint): dbus_bool_t {.cdecl, importc: "dbus_type_is_basic", dynlib: libdbus.}
proc dbus_type_is_container*(typecode: cint): dbus_bool_t {.cdecl, importc: "dbus_type_is_container", dynlib: libdbus.}
proc dbus_type_is_fixed*(typecode: cint): dbus_bool_t {.cdecl, importc: "dbus_type_is_fixed", dynlib: libdbus.}
proc dbus_validate_path*(path: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_validate_path", dynlib: libdbus.}
proc dbus_validate_interface*(name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_validate_interface", dynlib: libdbus.}
proc dbus_validate_member*(name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_validate_member", dynlib: libdbus.}
proc dbus_validate_error_name*(name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_validate_error_name", dynlib: libdbus.}
proc dbus_validate_bus_name*(name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_validate_bus_name", dynlib: libdbus.}
proc dbus_validate_utf8*(alleged_utf8: cstring; error: ptr DBusError): dbus_bool_t {.cdecl, importc: "dbus_validate_utf8", dynlib: libdbus.}
proc dbus_threads_init*(functions: ptr DBusThreadFunctions): dbus_bool_t {.cdecl, importc: "dbus_threads_init", dynlib: libdbus.}
proc dbus_threads_init_default*(): dbus_bool_t {.cdecl, importc: "dbus_threads_init_default", dynlib: libdbus.}
