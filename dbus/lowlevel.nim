import dynlib, macros

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

var
  dbus_error_init*: proc(error: ptr DBusError) {.cdecl.}
  dbus_error_free*: proc(error: ptr DBusError) {.cdecl.}
  dbus_set_error*: proc(error: ptr DBusError; name: cstring; message: cstring) {.varargs, cdecl.}
  dbus_set_error_const*: proc(error: ptr DBusError; name: cstring; message: cstring) {.cdecl.}
  dbus_move_error*: proc(src: ptr DBusError; dest: ptr DBusError) {.cdecl.}
  dbus_error_has_name*: proc(error: ptr DBusError; name: cstring): dbus_bool_t {.  cdecl.}
  dbus_error_is_set*: proc(error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_parse_address*: proc(address: cstring; entry: ptr ptr ptr DBusAddressEntry; array_len: ptr cint; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_address_entry_get_value*: proc(entry: ptr DBusAddressEntry; key: cstring): cstring {.cdecl.}
  dbus_address_entry_get_method*: proc(entry: ptr DBusAddressEntry): cstring {.cdecl.}
  dbus_address_entries_free*: proc(entries: ptr ptr DBusAddressEntry) {.cdecl.}
  dbus_address_escape_value*: proc(value: cstring): cstring {.cdecl.}
  dbus_address_unescape_value*: proc(value: cstring; error: ptr DBusError): cstring {.cdecl.}
  dbus_malloc*: proc(bytes: csize_t): pointer {.cdecl.}
  dbus_malloc0*: proc(bytes: csize_t): pointer {.cdecl.}
  dbus_realloc*: proc(memory: pointer; bytes: csize_t): pointer {.cdecl.}
  dbus_free*: proc(memory: pointer) {.cdecl.}
  dbus_free_string_array*: proc(str_array: cstringArray) {.cdecl.}
  dbus_shutdown*: proc() {.cdecl.}
  dbus_message_new*: proc(message_type: cint): ptr DBusMessage {.cdecl.}
  dbus_message_new_method_call*: proc(bus_name: cstring; path: cstring; iface: cstring; `method`: cstring): ptr DBusMessage {.cdecl.}
  dbus_message_new_method_return*: proc(method_call: ptr DBusMessage): ptr DBusMessage {.cdecl.}
  dbus_message_new_signal*: proc(path: cstring; iface: cstring; name: cstring): ptr DBusMessage {.cdecl.}
  dbus_message_new_error*: proc(reply_to: ptr DBusMessage; error_name: cstring; error_message: cstring): ptr DBusMessage {.cdecl.}
  dbus_message_new_error_printf*: proc(reply_to: ptr DBusMessage; error_name: cstring; error_format: cstring): ptr DBusMessage {.varargs, cdecl.}
  dbus_message_copy*: proc(message: ptr DBusMessage): ptr DBusMessage {.cdecl.}
  dbus_message_ref*: proc(message: ptr DBusMessage): ptr DBusMessage {.cdecl.}
  dbus_message_unref*: proc(message: ptr DBusMessage) {.cdecl.}
  dbus_message_get_type*: proc(message: ptr DBusMessage): cint {.cdecl.}
  dbus_message_set_path*: proc(message: ptr DBusMessage; object_path: cstring): dbus_bool_t {.cdecl.}
  dbus_message_get_path*: proc(message: ptr DBusMessage): cstring {.cdecl.}
  dbus_message_has_path*: proc(message: ptr DBusMessage; object_path: cstring): dbus_bool_t {.cdecl.}
  dbus_message_set_interface*: proc(message: ptr DBusMessage; iface: cstring): dbus_bool_t {.cdecl.}
  dbus_message_get_interface*: proc(message: ptr DBusMessage): cstring {.cdecl.}
  dbus_message_has_interface*: proc(message: ptr DBusMessage; iface: cstring): dbus_bool_t {.cdecl.}
  dbus_message_set_member*: proc(message: ptr DBusMessage; member: cstring): dbus_bool_t {.cdecl.}
  dbus_message_get_member*: proc(message: ptr DBusMessage): cstring {.cdecl.}
  dbus_message_has_member*: proc(message: ptr DBusMessage; member: cstring): dbus_bool_t {.cdecl.}
  dbus_message_set_error_name*: proc(message: ptr DBusMessage; name: cstring): dbus_bool_t {.cdecl.}
  dbus_message_get_error_name*: proc(message: ptr DBusMessage): cstring {.cdecl.}
  dbus_message_set_destination*: proc(message: ptr DBusMessage; destination: cstring): dbus_bool_t {.cdecl.}
  dbus_message_get_destination*: proc(message: ptr DBusMessage): cstring {.cdecl.}
  dbus_message_set_sender*: proc(message: ptr DBusMessage; sender: cstring): dbus_bool_t {.cdecl.}
  dbus_message_get_sender*: proc(message: ptr DBusMessage): cstring {.cdecl.}
  dbus_message_get_signature*: proc(message: ptr DBusMessage): cstring {.cdecl.}
  dbus_message_set_no_reply*: proc(message: ptr DBusMessage; no_reply: dbus_bool_t) {.cdecl.}
  dbus_message_get_no_reply*: proc(message: ptr DBusMessage): dbus_bool_t {.cdecl.}
  dbus_message_is_method_call*: proc(message: ptr DBusMessage; iface: cstring; `method`: cstring): dbus_bool_t {.cdecl.}
  dbus_message_is_signal*: proc(message: ptr DBusMessage; iface: cstring; signal_name: cstring): dbus_bool_t {.cdecl.}
  dbus_message_is_error*: proc(message: ptr DBusMessage; error_name: cstring): dbus_bool_t {.cdecl.}
  dbus_message_has_destination*: proc(message: ptr DBusMessage; bus_name: cstring): dbus_bool_t {.cdecl.}
  dbus_message_has_sender*: proc(message: ptr DBusMessage; unique_bus_name: cstring): dbus_bool_t {.cdecl.}
  dbus_message_has_signature*: proc(message: ptr DBusMessage; signature: cstring): dbus_bool_t {.cdecl.}
  dbus_message_get_serial*: proc(message: ptr DBusMessage): dbus_uint32_t {.cdecl.}
  dbus_message_set_serial*: proc(message: ptr DBusMessage; serial: dbus_uint32_t) {.cdecl.}
  dbus_message_set_reply_serial*: proc(message: ptr DBusMessage; reply_serial: dbus_uint32_t): dbus_bool_t {.cdecl.}
  dbus_message_get_reply_serial*: proc(message: ptr DBusMessage): dbus_uint32_t {.cdecl.}
  dbus_message_set_auto_start*: proc(message: ptr DBusMessage; auto_start: dbus_bool_t) {.cdecl.}
  dbus_message_get_auto_start*: proc(message: ptr DBusMessage): dbus_bool_t {.cdecl.}
  dbus_message_get_path_decomposed*: proc(message: ptr DBusMessage; path: ptr cstringArray): dbus_bool_t {.cdecl.}
  dbus_message_append_args*: proc(message: ptr DBusMessage; first_arg_type: cint): dbus_bool_t {.varargs, cdecl.}
  dbus_message_get_args*: proc(message: ptr DBusMessage; error: ptr DBusError; first_arg_type: cint): dbus_bool_t {.varargs, cdecl.}
  dbus_message_contains_unix_fds*: proc(message: ptr DBusMessage): dbus_bool_t {.cdecl.}
  dbus_message_iter_init*: proc(message: ptr DBusMessage; iter: ptr DBusMessageIter): dbus_bool_t {.cdecl.}
  dbus_message_iter_has_next*: proc(iter: ptr DBusMessageIter): dbus_bool_t {.cdecl.}
  dbus_message_iter_next*: proc(iter: ptr DBusMessageIter): dbus_bool_t {.cdecl.}
  dbus_message_iter_get_signature*: proc(iter: ptr DBusMessageIter): cstring {.cdecl.}
  dbus_message_iter_get_arg_type*: proc(iter: ptr DBusMessageIter): cint {.cdecl.}
  dbus_message_iter_get_element_type*: proc(iter: ptr DBusMessageIter): cint {.cdecl.}
  dbus_message_iter_recurse*: proc(iter: ptr DBusMessageIter; sub: ptr DBusMessageIter) {.cdecl.}
  dbus_message_iter_get_basic*: proc(iter: ptr DBusMessageIter; value: pointer) {.cdecl.}
  dbus_message_iter_get_array_len*: proc(iter: ptr DBusMessageIter): cint {.cdecl.}
  dbus_message_iter_get_fixed_array*: proc(iter: ptr DBusMessageIter; value: pointer; n_elements: ptr cint) {.cdecl.}
  dbus_message_iter_init_append*: proc(message: ptr DBusMessage; iter: ptr DBusMessageIter) {.cdecl.}
  dbus_message_iter_append_basic*: proc(iter: ptr DBusMessageIter; `type`: cint; value: pointer): dbus_bool_t {.cdecl.}
  dbus_message_iter_append_fixed_array*: proc(iter: ptr DBusMessageIter; element_type: cint; value: pointer; n_elements: cint): dbus_bool_t {.cdecl.}
  dbus_message_iter_open_container*: proc(iter: ptr DBusMessageIter; `type`: cint; contained_signature: cstring; sub: ptr DBusMessageIter): dbus_bool_t {.cdecl.}
  dbus_message_iter_close_container*: proc(iter: ptr DBusMessageIter; sub: ptr DBusMessageIter): dbus_bool_t {.cdecl.}
  dbus_message_iter_abandon_container*: proc(iter: ptr DBusMessageIter; sub: ptr DBusMessageIter) {.cdecl.}
  dbus_message_lock*: proc(message: ptr DBusMessage) {.cdecl.}
  dbus_set_error_from_message*: proc(error: ptr DBusError; message: ptr DBusMessage): dbus_bool_t {.cdecl.}
  dbus_message_allocate_data_slot*: proc(slot_p: ptr dbus_int32_t): dbus_bool_t {.cdecl.}
  dbus_message_free_data_slot*: proc(slot_p: ptr dbus_int32_t) {.cdecl.}
  dbus_message_set_data*: proc(message: ptr DBusMessage; slot: dbus_int32_t; data: pointer; free_data_func: DBusFreeFunction): dbus_bool_t {.cdecl.}
  dbus_message_get_data*: proc(message: ptr DBusMessage; slot: dbus_int32_t): pointer {.cdecl.}
  dbus_message_type_from_string*: proc(type_str: cstring): cint {.cdecl.}
  dbus_message_type_to_string*: proc(`type`: cint): cstring {.cdecl.}
  dbus_message_marshal*: proc(msg: ptr DBusMessage; marshalled_data_p: cstringArray; len_p: ptr cint): dbus_bool_t {.cdecl.}
  dbus_message_demarshal*: proc(str: cstring; len: cint; error: ptr DBusError): ptr DBusMessage {.cdecl.}
  dbus_message_demarshal_bytes_needed*: proc(str: cstring; len: cint): cint {.cdecl.}
  dbus_connection_open*: proc(address: cstring; error: ptr DBusError): ptr DBusConnection {.cdecl.}
  dbus_connection_open_private*: proc(address: cstring; error: ptr DBusError): ptr DBusConnection {.cdecl.}
  dbus_connection_ref*: proc(connection: ptr DBusConnection): ptr DBusConnection {.cdecl.}
  dbus_connection_unref*: proc(connection: ptr DBusConnection) {.cdecl.}
  dbus_connection_close*: proc(connection: ptr DBusConnection) {.cdecl.}
  dbus_connection_get_is_connected*: proc(connection: ptr DBusConnection): dbus_bool_t {.cdecl.}
  dbus_connection_get_is_authenticated*: proc(connection: ptr DBusConnection): dbus_bool_t {.cdecl.}
  dbus_connection_get_is_anonymous*: proc(connection: ptr DBusConnection): dbus_bool_t {.cdecl.}
  dbus_connection_get_server_id*: proc(connection: ptr DBusConnection): cstring {.cdecl.}
  dbus_connection_can_send_type*: proc(connection: ptr DBusConnection; `type`: cint): dbus_bool_t {.cdecl.}
  dbus_connection_set_exit_on_disconnect*: proc(connection: ptr DBusConnection; exit_on_disconnect: dbus_bool_t) {.cdecl.}
  dbus_connection_flush*: proc(connection: ptr DBusConnection) {.cdecl.}
  dbus_connection_read_write_dispatch*: proc(connection: ptr DBusConnection; timeout_milliseconds: cint): dbus_bool_t {.cdecl.}
  dbus_connection_read_write*: proc(connection: ptr DBusConnection; timeout_milliseconds: cint): dbus_bool_t {.cdecl.}
  dbus_connection_borrow_message*: proc(connection: ptr DBusConnection): ptr DBusMessage {.cdecl.}
  dbus_connection_return_message*: proc(connection: ptr DBusConnection; message: ptr DBusMessage) {.cdecl.}
  dbus_connection_steal_borrowed_message*: proc(connection: ptr DBusConnection; message: ptr DBusMessage) {.cdecl.}
  dbus_connection_pop_message*: proc(connection: ptr DBusConnection): ptr DBusMessage {.cdecl.}
  dbus_connection_get_dispatch_status*: proc(connection: ptr DBusConnection): DBusDispatchStatus {.cdecl.}
  dbus_connection_dispatch*: proc(connection: ptr DBusConnection): DBusDispatchStatus {.cdecl.}
  dbus_connection_has_messages_to_send*: proc(connection: ptr DBusConnection): dbus_bool_t {.cdecl.}
  dbus_connection_send*: proc(connection: ptr DBusConnection; message: ptr DBusMessage; client_serial: ptr dbus_uint32_t): dbus_bool_t {.cdecl.}
  dbus_connection_send_with_reply*: proc(connection: ptr DBusConnection; message: ptr DBusMessage; pending_return: ptr ptr DBusPendingCall; timeout_milliseconds: cint): dbus_bool_t {.cdecl.}
  dbus_connection_send_with_reply_and_block*: proc(connection: ptr DBusConnection; message: ptr DBusMessage; timeout_milliseconds: cint; error: ptr DBusError): ptr DBusMessage {.cdecl.}
  dbus_connection_set_watch_functions*: proc(connection: ptr DBusConnection; add_function: DBusAddWatchFunction; remove_function: DBusRemoveWatchFunction; toggled_function: DBusWatchToggledFunction; data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.cdecl.}
  dbus_connection_set_timeout_functions*: proc(connection: ptr DBusConnection; add_function: DBusAddTimeoutFunction; remove_function: DBusRemoveTimeoutFunction; toggled_function: DBusTimeoutToggledFunction; data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.cdecl.}
  dbus_connection_set_wakeup_main_function*: proc(connection: ptr DBusConnection; wakeup_main_function: DBusWakeupMainFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl.}
  dbus_connection_set_dispatch_status_function*: proc(connection: ptr DBusConnection; function: DBusDispatchStatusFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl.}
  dbus_connection_get_unix_user*: proc(connection: ptr DBusConnection; uid: ptr culong): dbus_bool_t {.cdecl.}
  dbus_connection_get_unix_process_id*: proc(connection: ptr DBusConnection; pid: ptr culong): dbus_bool_t {.cdecl.}
  dbus_connection_get_adt_audit_session_data*: proc(connection: ptr DBusConnection; data: ptr pointer; data_size: ptr dbus_int32_t): dbus_bool_t {.cdecl.}
  dbus_connection_set_unix_user_function*: proc(connection: ptr DBusConnection; function: DBusAllowUnixUserFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl.}
  dbus_connection_get_windows_user*: proc(connection: ptr DBusConnection; windows_sid_p: cstringArray): dbus_bool_t {.cdecl.}
  dbus_connection_set_windows_user_function*: proc(connection: ptr DBusConnection; function: DBusAllowWindowsUserFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl.}
  dbus_connection_set_allow_anonymous*: proc(connection: ptr DBusConnection; value: dbus_bool_t) {.cdecl.}
  dbus_connection_set_route_peer_messages*: proc(connection: ptr DBusConnection; value: dbus_bool_t) {.cdecl.}

# Filters
  dbus_connection_add_filter*: proc(connection: ptr DBusConnection; function: DBusHandleMessageFunction; user_data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.  cdecl.}
  dbus_connection_remove_filter*: proc(connection: ptr DBusConnection; function: DBusHandleMessageFunction; user_data: pointer) {.cdecl.}

# Other
  dbus_connection_allocate_data_slot*: proc(slot_p: ptr dbus_int32_t): dbus_bool_t {.  cdecl.}
  dbus_connection_free_data_slot*: proc(slot_p: ptr dbus_int32_t) {.cdecl.}
  dbus_connection_set_data*: proc(connection: ptr DBusConnection; slot: dbus_int32_t; data: pointer; free_data_func: DBusFreeFunction): dbus_bool_t {.cdecl.}
  dbus_connection_get_data*: proc(connection: ptr DBusConnection; slot: dbus_int32_t): pointer {.cdecl.}
  dbus_connection_set_change_sigpipe*: proc(will_modify_sigpipe: dbus_bool_t) {.cdecl.}
  dbus_connection_set_max_message_size*: proc(connection: ptr DBusConnection; size: clong) {.cdecl.}
  dbus_connection_get_max_message_size*: proc(connection: ptr DBusConnection): clong {.cdecl.}
  dbus_connection_set_max_received_size*: proc(connection: ptr DBusConnection; size: clong) {.cdecl.}
  dbus_connection_get_max_received_size*: proc(connection: ptr DBusConnection): clong {.cdecl.}
  dbus_connection_set_max_message_unix_fds*: proc(connection: ptr DBusConnection; n: clong) {.cdecl.}
  dbus_connection_get_max_message_unix_fds*: proc(connection: ptr DBusConnection): clong {.cdecl.}
  dbus_connection_set_max_received_unix_fds*: proc(connection: ptr DBusConnection; n: clong) {.cdecl.}
  dbus_connection_get_max_received_unix_fds*: proc(connection: ptr DBusConnection): clong {.cdecl.}
  dbus_connection_get_outgoing_size*: proc(connection: ptr DBusConnection): clong {.cdecl.}
  dbus_connection_get_outgoing_unix_fds*: proc(connection: ptr DBusConnection): clong {.cdecl.}
  dbus_connection_preallocate_send*: proc(connection: ptr DBusConnection): ptr DBusPreallocatedSend {.cdecl.}
  dbus_connection_free_preallocated_send*: proc(connection: ptr DBusConnection; preallocated: ptr DBusPreallocatedSend) {.cdecl.}
  dbus_connection_send_preallocated*: proc(connection: ptr DBusConnection; preallocated: ptr DBusPreallocatedSend; message: ptr DBusMessage; client_serial: ptr dbus_uint32_t) {.cdecl.}
  dbus_connection_try_register_object_path*: proc(connection: ptr DBusConnection; path: cstring; vtable: ptr DBusObjectPathVTable; user_data: pointer; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_connection_register_object_path*: proc(connection: ptr DBusConnection; path: cstring; vtable: ptr DBusObjectPathVTable; user_data: pointer): dbus_bool_t {.  cdecl.}
  dbus_connection_try_register_fallback*: proc(connection: ptr DBusConnection; path: cstring; vtable: ptr DBusObjectPathVTable; user_data: pointer; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_connection_register_fallback*: proc(connection: ptr DBusConnection; path: cstring; vtable: ptr DBusObjectPathVTable; user_data: pointer): dbus_bool_t {.cdecl.}
  dbus_connection_unregister_object_path*: proc(connection: ptr DBusConnection; path: cstring): dbus_bool_t {.cdecl.}
  dbus_connection_get_object_path_data*: proc(connection: ptr DBusConnection; path: cstring; data_p: ptr pointer): dbus_bool_t {.cdecl.}
  dbus_connection_list_registered*: proc(connection: ptr DBusConnection; parent_path: cstring; child_entries: ptr cstringArray): dbus_bool_t {.cdecl.}
  dbus_connection_get_unix_fd*: proc(connection: ptr DBusConnection; fd: ptr cint): dbus_bool_t {.cdecl.}
  dbus_connection_get_socket*: proc(connection: ptr DBusConnection; fd: ptr cint): dbus_bool_t {.cdecl.}
  dbus_watch_get_fd*: proc(watch: ptr DBusWatch): cint {.cdecl.}
  dbus_watch_get_unix_fd*: proc(watch: ptr DBusWatch): cint {.cdecl.}
  dbus_watch_get_socket*: proc(watch: ptr DBusWatch): cint {.cdecl.}
  dbus_watch_get_flags*: proc(watch: ptr DBusWatch): cuint {.cdecl.}
  dbus_watch_get_data*: proc(watch: ptr DBusWatch): pointer {.cdecl.}
  dbus_watch_set_data*: proc(watch: ptr DBusWatch; data: pointer; free_data_function: DBusFreeFunction) {.cdecl.}
  dbus_watch_handle*: proc(watch: ptr DBusWatch; flags: cuint): dbus_bool_t {.cdecl.}
  dbus_watch_get_enabled*: proc(watch: ptr DBusWatch): dbus_bool_t {.cdecl.}
  dbus_timeout_get_interval*: proc(timeout: ptr DBusTimeout): cint {.cdecl.}
  dbus_timeout_get_data*: proc(timeout: ptr DBusTimeout): pointer {.cdecl.}
  dbus_timeout_set_data*: proc(timeout: ptr DBusTimeout; data: pointer; free_data_function: DBusFreeFunction) {.cdecl.}
  dbus_timeout_handle*: proc(timeout: ptr DBusTimeout): dbus_bool_t {.cdecl.}
  dbus_timeout_get_enabled*: proc(timeout: ptr DBusTimeout): dbus_bool_t {.cdecl.}
  dbus_bus_get*: proc(`type`: DBusBusType; error: ptr DBusError): ptr DBusConnection {.cdecl.}
  dbus_bus_get_private*: proc(`type`: DBusBusType; error: ptr DBusError): ptr DBusConnection {.cdecl.}
  dbus_bus_register*: proc(connection: ptr DBusConnection; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_bus_set_unique_name*: proc(connection: ptr DBusConnection; unique_name: cstring): dbus_bool_t {.cdecl.}
  dbus_bus_get_unique_name*: proc(connection: ptr DBusConnection): cstring {.cdecl.}
  dbus_bus_get_unix_user*: proc(connection: ptr DBusConnection; name: cstring; error: ptr DBusError): culong {.cdecl.}
  dbus_bus_get_id*: proc(connection: ptr DBusConnection; error: ptr DBusError): cstring {.cdecl.}
  dbus_bus_request_name*: proc(connection: ptr DBusConnection; name: cstring; flags: cuint; error: ptr DBusError): cint {.cdecl.}
  dbus_bus_release_name*: proc(connection: ptr DBusConnection; name: cstring; error: ptr DBusError): cint {.cdecl.}
  dbus_bus_name_has_owner*: proc(connection: ptr DBusConnection; name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_bus_start_service_by_name*: proc(connection: ptr DBusConnection; name: cstring; flags: dbus_uint32_t; reply: ptr dbus_uint32_t; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_bus_add_match*: proc(connection: ptr DBusConnection; rule: cstring; error: ptr DBusError) {.cdecl.}
  dbus_bus_remove_match*: proc(connection: ptr DBusConnection; rule: cstring; error: ptr DBusError) {.cdecl.}
  dbus_get_local_machine_id*: proc(): cstring {.cdecl.}
  dbus_get_version*: proc(major_version_p: ptr cint; minor_version_p: ptr cint; micro_version_p: ptr cint) {.cdecl.}
  dbus_pending_call_ref*: proc(pending: ptr DBusPendingCall): ptr DBusPendingCall {.cdecl.}
  dbus_pending_call_unref*: proc(pending: ptr DBusPendingCall) {.cdecl.}
  dbus_pending_call_set_notify*: proc(pending: ptr DBusPendingCall; function: DBusPendingCallNotifyFunction; user_data: pointer; free_user_data: DBusFreeFunction): dbus_bool_t {.cdecl.}
  dbus_pending_call_cancel*: proc(pending: ptr DBusPendingCall) {.cdecl.}
  dbus_pending_call_get_completed*: proc(pending: ptr DBusPendingCall): dbus_bool_t {.cdecl.}
  dbus_pending_call_steal_reply*: proc(pending: ptr DBusPendingCall): ptr DBusMessage {.cdecl.}
  dbus_pending_call_block*: proc(pending: ptr DBusPendingCall) {.cdecl.}
  dbus_pending_call_allocate_data_slot*: proc(slot_p: ptr dbus_int32_t): dbus_bool_t {.cdecl.}
  dbus_pending_call_free_data_slot*: proc(slot_p: ptr dbus_int32_t) {.cdecl.}
  dbus_pending_call_set_data*: proc(pending: ptr DBusPendingCall; slot: dbus_int32_t; data: pointer; free_data_func: DBusFreeFunction): dbus_bool_t {.  cdecl.}
  dbus_pending_call_get_data*: proc(pending: ptr DBusPendingCall; slot: dbus_int32_t): pointer {.cdecl.}
  dbus_server_listen*: proc(address: cstring; error: ptr DBusError): ptr DBusServer {.cdecl.}
  dbus_server_ref*: proc(server: ptr DBusServer): ptr DBusServer {.cdecl.}
  dbus_server_unref*: proc(server: ptr DBusServer) {.cdecl.}
  dbus_server_disconnect*: proc(server: ptr DBusServer) {.cdecl.}
  dbus_server_get_is_connected*: proc(server: ptr DBusServer): dbus_bool_t {.cdecl.}
  dbus_server_get_address*: proc(server: ptr DBusServer): cstring {.cdecl.}
  dbus_server_get_id*: proc(server: ptr DBusServer): cstring {.cdecl.}
  dbus_server_set_new_connection_function*: proc(server: ptr DBusServer; function: DBusNewConnectionFunction; data: pointer; free_data_function: DBusFreeFunction) {.cdecl.}
  dbus_server_set_watch_functions*: proc(server: ptr DBusServer; add_function: DBusAddWatchFunction; remove_function: DBusRemoveWatchFunction; toggled_function: DBusWatchToggledFunction; data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.cdecl.}
  dbus_server_set_timeout_functions*: proc(server: ptr DBusServer; add_function: DBusAddTimeoutFunction; remove_function: DBusRemoveTimeoutFunction; toggled_function: DBusTimeoutToggledFunction; data: pointer; free_data_function: DBusFreeFunction): dbus_bool_t {.cdecl.}
  dbus_server_set_auth_mechanisms*: proc(server: ptr DBusServer; mechanisms: cstringArray): dbus_bool_t {.cdecl.}
  dbus_server_allocate_data_slot*: proc(slot_p: ptr dbus_int32_t): dbus_bool_t {.cdecl.}
  dbus_server_free_data_slot*: proc(slot_p: ptr dbus_int32_t) {.cdecl.}
  dbus_server_set_data*: proc(server: ptr DBusServer; slot: cint; data: pointer; free_data_func: DBusFreeFunction): dbus_bool_t {.  cdecl.}
  dbus_server_get_data*: proc(server: ptr DBusServer; slot: cint): pointer {.cdecl.}
  dbus_signature_iter_init*: proc(iter: ptr DBusSignatureIter; signature: cstring) {.cdecl.}
  dbus_signature_iter_get_current_type*: proc(iter: ptr DBusSignatureIter): cint {.cdecl.}
  dbus_signature_iter_get_signature*: proc(iter: ptr DBusSignatureIter): cstring {.cdecl.}
  dbus_signature_iter_get_element_type*: proc(iter: ptr DBusSignatureIter): cint {.cdecl.}
  dbus_signature_iter_next*: proc(iter: ptr DBusSignatureIter): dbus_bool_t {.cdecl.}
  dbus_signature_iter_recurse*: proc(iter: ptr DBusSignatureIter; subiter: ptr DBusSignatureIter) {.cdecl.}
  dbus_signature_validate*: proc(signature: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_signature_validate_single*: proc(signature: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_type_is_valid*: proc(typecode: cint): dbus_bool_t {.cdecl.}
  dbus_type_is_basic*: proc(typecode: cint): dbus_bool_t {.cdecl.}
  dbus_type_is_container*: proc(typecode: cint): dbus_bool_t {.cdecl.}
  dbus_type_is_fixed*: proc(typecode: cint): dbus_bool_t {.cdecl.}
  dbus_validate_path*: proc(path: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_validate_interface*: proc(name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_validate_member*: proc(name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_validate_error_name*: proc(name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_validate_bus_name*: proc(name: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_validate_utf8*: proc(alleged_utf8: cstring; error: ptr DBusError): dbus_bool_t {.cdecl.}
  dbus_threads_init*: proc(functions: ptr DBusThreadFunctions): dbus_bool_t {.cdecl.}
  dbus_threads_init_default*: proc(): dbus_bool_t {.cdecl.}

proc loadAPI*() =
  let handle = dynlib.loadLib("libdbus-1.so.3")
  macro str(sym): string = newLit($sym)
  template load(sym): untyped =
    sym = cast[typeof sym](handle.symAddr(str(sym)))
  load(dbus_error_init)
  load(dbus_error_free)
  load(dbus_set_error)
  load(dbus_set_error_const)
  load(dbus_move_error)
  load(dbus_error_has_name)
  load(dbus_error_is_set)
  load(dbus_parse_address)
  load(dbus_address_entry_get_value)
  load(dbus_address_entry_get_method)
  load(dbus_address_entries_free)
  load(dbus_address_escape_value)
  load(dbus_address_unescape_value)
  load(dbus_malloc)
  load(dbus_malloc0)
  load(dbus_realloc)
  load(dbus_free)
  load(dbus_free_string_array)
  load(dbus_shutdown)
  load(dbus_message_new)
  load(dbus_message_new_method_call)
  load(dbus_message_new_method_return)
  load(dbus_message_new_signal)
  load(dbus_message_new_error)
  load(dbus_message_new_error_printf)
  load(dbus_message_copy)
  load(dbus_message_ref)
  load(dbus_message_unref)
  load(dbus_message_get_type)
  load(dbus_message_set_path)
  load(dbus_message_get_path)
  load(dbus_message_has_path)
  load(dbus_message_set_interface)
  load(dbus_message_get_interface)
  load(dbus_message_has_interface)
  load(dbus_message_set_member)
  load(dbus_message_get_member)
  load(dbus_message_has_member)
  load(dbus_message_set_error_name)
  load(dbus_message_get_error_name)
  load(dbus_message_set_destination)
  load(dbus_message_get_destination)
  load(dbus_message_set_sender)
  load(dbus_message_get_sender)
  load(dbus_message_get_signature)
  load(dbus_message_set_no_reply)
  load(dbus_message_get_no_reply)
  load(dbus_message_is_method_call)
  load(dbus_message_is_signal)
  load(dbus_message_is_error)
  load(dbus_message_has_destination)
  load(dbus_message_has_sender)
  load(dbus_message_has_signature)
  load(dbus_message_get_serial)
  load(dbus_message_set_serial)
  load(dbus_message_set_reply_serial)
  load(dbus_message_get_reply_serial)
  load(dbus_message_set_auto_start)
  load(dbus_message_get_auto_start)
  load(dbus_message_get_path_decomposed)
  load(dbus_message_append_args)
  load(dbus_message_get_args)
  load(dbus_message_contains_unix_fds)
  load(dbus_message_iter_init)
  load(dbus_message_iter_has_next)
  load(dbus_message_iter_next)
  load(dbus_message_iter_get_signature)
  load(dbus_message_iter_get_arg_type)
  load(dbus_message_iter_get_element_type)
  load(dbus_message_iter_recurse)
  load(dbus_message_iter_get_basic)
  load(dbus_message_iter_get_array_len)
  load(dbus_message_iter_get_fixed_array)
  load(dbus_message_iter_init_append)
  load(dbus_message_iter_append_basic)
  load(dbus_message_iter_append_fixed_array)
  load(dbus_message_iter_open_container)
  load(dbus_message_iter_close_container)
  load(dbus_message_iter_abandon_container)
  load(dbus_message_lock)
  load(dbus_set_error_from_message)
  load(dbus_message_allocate_data_slot)
  load(dbus_message_free_data_slot)
  load(dbus_message_set_data)
  load(dbus_message_get_data)
  load(dbus_message_type_from_string)
  load(dbus_message_type_to_string)
  load(dbus_message_marshal)
  load(dbus_message_demarshal)
  load(dbus_message_demarshal_bytes_needed)
  load(dbus_connection_open)
  load(dbus_connection_open_private)
  load(dbus_connection_ref)
  load(dbus_connection_unref)
  load(dbus_connection_close)
  load(dbus_connection_get_is_connected)
  load(dbus_connection_get_is_authenticated)
  load(dbus_connection_get_is_anonymous)
  load(dbus_connection_get_server_id)
  load(dbus_connection_can_send_type)
  load(dbus_connection_set_exit_on_disconnect)
  load(dbus_connection_flush)
  load(dbus_connection_read_write_dispatch)
  load(dbus_connection_read_write)
  load(dbus_connection_borrow_message)
  load(dbus_connection_return_message)
  load(dbus_connection_steal_borrowed_message)
  load(dbus_connection_pop_message)
  load(dbus_connection_get_dispatch_status)
  load(dbus_connection_dispatch)
  load(dbus_connection_has_messages_to_send)
  load(dbus_connection_send)
  load(dbus_connection_send_with_reply)
  load(dbus_connection_send_with_reply_and_block)
  load(dbus_connection_set_watch_functions)
  load(dbus_connection_set_timeout_functions)
  load(dbus_connection_set_wakeup_main_function)
  load(dbus_connection_set_dispatch_status_function)
  load(dbus_connection_get_unix_user)
  load(dbus_connection_get_unix_process_id)
  load(dbus_connection_get_adt_audit_session_data)
  load(dbus_connection_set_unix_user_function)
  load(dbus_connection_get_windows_user)
  load(dbus_connection_set_windows_user_function)
  load(dbus_connection_set_allow_anonymous)
  load(dbus_connection_set_route_peer_messages)

  # Filters
  load(dbus_connection_add_filter)
  load(dbus_connection_remove_filter)

  # Other
  load(dbus_connection_allocate_data_slot)
  load(dbus_connection_free_data_slot)
  load(dbus_connection_set_data)
  load(dbus_connection_get_data)
  load(dbus_connection_set_change_sigpipe)
  load(dbus_connection_set_max_message_size)
  load(dbus_connection_get_max_message_size)
  load(dbus_connection_set_max_received_size)
  load(dbus_connection_get_max_received_size)
  load(dbus_connection_set_max_message_unix_fds)
  load(dbus_connection_get_max_message_unix_fds)
  load(dbus_connection_set_max_received_unix_fds)
  load(dbus_connection_get_max_received_unix_fds)
  load(dbus_connection_get_outgoing_size)
  load(dbus_connection_get_outgoing_unix_fds)
  load(dbus_connection_preallocate_send)
  load(dbus_connection_free_preallocated_send)
  load(dbus_connection_send_preallocated)
  load(dbus_connection_try_register_object_path)
  load(dbus_connection_register_object_path)
  load(dbus_connection_try_register_fallback)
  load(dbus_connection_register_fallback)
  load(dbus_connection_unregister_object_path)
  load(dbus_connection_get_object_path_data)
  load(dbus_connection_list_registered)
  load(dbus_connection_get_unix_fd)
  load(dbus_connection_get_socket)
  load(dbus_watch_get_fd)
  load(dbus_watch_get_unix_fd)
  load(dbus_watch_get_socket)
  load(dbus_watch_get_flags)
  load(dbus_watch_get_data)
  load(dbus_watch_set_data)
  load(dbus_watch_handle)
  load(dbus_watch_get_enabled)
  load(dbus_timeout_get_interval)
  load(dbus_timeout_get_data)
  load(dbus_timeout_set_data)
  load(dbus_timeout_handle)
  load(dbus_timeout_get_enabled)
  load(dbus_bus_get)
  load(dbus_bus_get_private)
  load(dbus_bus_register)
  load(dbus_bus_set_unique_name)
  load(dbus_bus_get_unique_name)
  load(dbus_bus_get_unix_user)
  load(dbus_bus_get_id)
  load(dbus_bus_request_name)
  load(dbus_bus_release_name)
  load(dbus_bus_name_has_owner)
  load(dbus_bus_start_service_by_name)
  load(dbus_bus_add_match)
  load(dbus_bus_remove_match)
  load(dbus_get_local_machine_id)
  load(dbus_get_version)
  load(dbus_pending_call_ref)
  load(dbus_pending_call_unref)
  load(dbus_pending_call_set_notify)
  load(dbus_pending_call_cancel)
  load(dbus_pending_call_get_completed)
  load(dbus_pending_call_steal_reply)
  load(dbus_pending_call_block)
  load(dbus_pending_call_allocate_data_slot)
  load(dbus_pending_call_free_data_slot)
  load(dbus_pending_call_set_data)
  load(dbus_pending_call_get_data)
  load(dbus_server_listen)
  load(dbus_server_ref)
  load(dbus_server_unref)
  load(dbus_server_disconnect)
  load(dbus_server_get_is_connected)
  load(dbus_server_get_address)
  load(dbus_server_get_id)
  load(dbus_server_set_new_connection_function)
  load(dbus_server_set_watch_functions)
  load(dbus_server_set_timeout_functions)
  load(dbus_server_set_auth_mechanisms)
  load(dbus_server_allocate_data_slot)
  load(dbus_server_free_data_slot)
  load(dbus_server_set_data)
  load(dbus_server_get_data)
  load(dbus_signature_iter_init)
  load(dbus_signature_iter_get_current_type)
  load(dbus_signature_iter_get_signature)
  load(dbus_signature_iter_get_element_type)
  load(dbus_signature_iter_next)
  load(dbus_signature_iter_recurse)
  load(dbus_signature_validate)
  load(dbus_signature_validate_single)
  load(dbus_type_is_valid)
  load(dbus_type_is_basic)
  load(dbus_type_is_container)
  load(dbus_type_is_fixed)
  load(dbus_validate_path)
  load(dbus_validate_interface)
  load(dbus_validate_member)
  load(dbus_validate_error_name)
  load(dbus_validate_bus_name)
  load(dbus_validate_utf8)
  load(dbus_threads_init)
  load(dbus_threads_init_default)
