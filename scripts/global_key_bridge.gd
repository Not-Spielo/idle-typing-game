extends Node

# Global Key Bridge - Receives global key characters from external helper via localhost TCP

class_name GlobalKeyBridge

signal global_char_received(char: String)

const BRIDGE_HOST: String = "127.0.0.1"
const BRIDGE_PORT: int = 37193
const HELPER_EMBEDDED_EXE: String = "res://resources/global_key_helper.exe"
const HELPER_EMBEDDED_BIN_PATH: String = "res://resources/global_key_helper.win64.bin"
const HELPER_EMBEDDED_B64_PATH: String = "res://resources/global_key_helper.win64.b64"
const HELPER_EXE_NAME: String = "global_key_helper.exe"

var server: TCPServer = TCPServer.new()
var clients: Array[StreamPeerTCP] = []
var client_buffers: Dictionary = {}
var helper_pid: int = -1

func start_bridge() -> bool:
	if OS.get_name() != "Windows":
		return false

	if not _start_server():
		return false

	var helper_path := _ensure_helper_executable()
	if helper_path == "":
		return false

	helper_pid = OS.create_process(
		helper_path,
		PackedStringArray(["--host", BRIDGE_HOST, "--port", str(BRIDGE_PORT)]),
		false
	)

	if helper_pid == -1:
		push_warning("Failed to launch global key helper process.")
		return false

	set_process(true)
	return true

func _start_server() -> bool:
	if server.is_listening():
		return true

	var err := server.listen(BRIDGE_PORT, BRIDGE_HOST)
	if err != OK:
		push_warning("Global key bridge failed to listen on %s:%d" % [BRIDGE_HOST, BRIDGE_PORT])
		return false

	return true

func _process(_delta: float):
	_poll_new_connections()
	_poll_clients()

func _poll_new_connections():
	while server.is_connection_available():
		var client := server.take_connection()
		if client == null:
			break
		client.set_no_delay(true)
		clients.append(client)
		client_buffers[client.get_instance_id()] = ""

func _poll_clients():
	for i in range(clients.size() - 1, -1, -1):
		var client := clients[i]
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_remove_client(i)
			continue

		var available := client.get_available_bytes()
		if available <= 0:
			continue

		var response := client.get_data(available)
		if response.size() < 2 or response[0] != OK:
			_remove_client(i)
			continue

		var data: PackedByteArray = response[1]
		var client_id: int = client.get_instance_id()
		var buffer: String = client_buffers.get(client_id, "")
		buffer += data.get_string_from_utf8()

		var lines: Array = buffer.split("\n")
		var trailing := ""
		if not lines.is_empty():
			trailing = String(lines[lines.size() - 1])
			lines.remove_at(lines.size() - 1)
		client_buffers[client_id] = trailing

		for line in lines:
			_process_message_line(line.strip_edges())

func _process_message_line(line: String):
	if line == "":
		return

	var payload = JSON.parse_string(line)
	if payload is Dictionary and payload.has("char"):
		var char_value := String(payload["char"])
		if char_value != "":
			global_char_received.emit(char_value)

func _ensure_helper_executable() -> String:
	var install_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("IdleTypingGame").path_join("bin")
	DirAccess.make_dir_recursive_absolute(install_dir)
	var install_path := install_dir.path_join(HELPER_EXE_NAME)
	print("[GlobalKeyBridge] Attempting to extract helper to: ", install_path)

	if _extract_embedded_helper_to(install_path):
		print("[GlobalKeyBridge] Successfully extracted helper")
		return install_path

	# Fallback 1: Check for helper alongside executable
	var adjacent := OS.get_executable_path().get_base_dir().path_join(HELPER_EXE_NAME)
	print("[GlobalKeyBridge] Checking adjacent exe path: ", adjacent)
	if FileAccess.file_exists(adjacent):
		print("[GlobalKeyBridge] Found helper at adjacent path")
		return adjacent

	# Fallback 2: Check for binary payload adjacent to exe
	var adjacent_bin := OS.get_executable_path().get_base_dir().path_join("global_key_helper.win64.bin")
	print("[GlobalKeyBridge] Checking for adjacent binary payload: ", adjacent_bin)
	if FileAccess.file_exists(adjacent_bin):
		print("[GlobalKeyBridge] Found binary payload adjacent to exe, extracting...")
		if _extract_from_file(adjacent_bin, install_path):
			print("[GlobalKeyBridge] Successfully extracted from adjacent binary")
			return install_path

	push_error("[GlobalKeyBridge] No embedded global helper found at %s, %s, or %s" % [HELPER_EMBEDDED_EXE, HELPER_EMBEDDED_BIN_PATH, HELPER_EMBEDDED_B64_PATH])
	print("[GlobalKeyBridge] Helper exe exists: ", FileAccess.file_exists(HELPER_EMBEDDED_EXE))
	print("[GlobalKeyBridge] Binary resource exists: ", FileAccess.file_exists(HELPER_EMBEDDED_BIN_PATH))
	print("[GlobalKeyBridge] Base64 resource exists: ", FileAccess.file_exists(HELPER_EMBEDDED_B64_PATH))
	return ""

func _extract_from_file(source_path: String, target_path: String) -> bool:
	if not FileAccess.file_exists(source_path):
		print("[GlobalKeyBridge] Source file not found: ", source_path)
		return false

	var in_file := FileAccess.open(source_path, FileAccess.READ)
	if in_file == null:
		push_error("[GlobalKeyBridge] Failed to open source file: ", source_path)
		return false

	var bytes := in_file.get_buffer(in_file.get_length())
	if bytes.is_empty():
		push_error("[GlobalKeyBridge] Source file is empty: ", source_path)
		return false

	var out_file := FileAccess.open(target_path, FileAccess.WRITE)
	if out_file == null:
		push_error("[GlobalKeyBridge] Unable to write to target: ", target_path)
		return false

	out_file.store_buffer(bytes)
	print("[GlobalKeyBridge] Extracted %d bytes from %s to %s" % [bytes.size(), source_path, target_path])
	return true

func _extract_embedded_helper_to(target_path: String) -> bool:
	if _extract_embedded_helper_from_exe(target_path):
		return true

	if _extract_embedded_helper_from_bin(target_path):
		return true

	if _extract_embedded_helper_from_b64(target_path):
		return true

	return false

func _extract_embedded_helper_from_exe(target_path: String) -> bool:
	if not FileAccess.file_exists(HELPER_EMBEDDED_EXE):
		print("[GlobalKeyBridge] Helper exe not found at: ", HELPER_EMBEDDED_EXE)
		return false

	print("[GlobalKeyBridge] Opening helper exe: ", HELPER_EMBEDDED_EXE)
	var in_file := FileAccess.open(HELPER_EMBEDDED_EXE, FileAccess.READ)
	if in_file == null:
		push_error("[GlobalKeyBridge] Failed to open helper exe: ", HELPER_EMBEDDED_EXE)
		return false

	var bytes := in_file.get_buffer(in_file.get_length())
	if bytes.is_empty():
		push_error("[GlobalKeyBridge] Helper exe is empty")
		return false

	print("[GlobalKeyBridge] Read %d bytes from helper exe" % bytes.size())
	var out_file := FileAccess.open(target_path, FileAccess.WRITE)
	if out_file == null:
		push_error("[GlobalKeyBridge] Unable to write helper executable to %s" % target_path)
		return false

	out_file.store_buffer(bytes)
	print("[GlobalKeyBridge] Successfully wrote %d bytes to %s" % [bytes.size(), target_path])
	return true

func _extract_embedded_helper_from_bin(target_path: String) -> bool:
	if not FileAccess.file_exists(HELPER_EMBEDDED_BIN_PATH):
		print("[GlobalKeyBridge] Binary resource not found at: ", HELPER_EMBEDDED_BIN_PATH)
		return false

	print("[GlobalKeyBridge] Opening binary resource: ", HELPER_EMBEDDED_BIN_PATH)
	var in_file := FileAccess.open(HELPER_EMBEDDED_BIN_PATH, FileAccess.READ)
	if in_file == null:
		push_error("[GlobalKeyBridge] Failed to open binary resource: ", HELPER_EMBEDDED_BIN_PATH)
		return false

	var bytes := in_file.get_buffer(in_file.get_length())
	if bytes.is_empty():
		push_error("[GlobalKeyBridge] Binary resource is empty")
		return false

	print("[GlobalKeyBridge] Read %d bytes from binary resource" % bytes.size())
	var out_file := FileAccess.open(target_path, FileAccess.WRITE)
	if out_file == null:
		push_error("[GlobalKeyBridge] Unable to write helper executable to %s" % target_path)
		return false

	out_file.store_buffer(bytes)
	print("[GlobalKeyBridge] Successfully wrote %d bytes to %s" % [bytes.size(), target_path])
	return true

func _extract_embedded_helper_from_b64(target_path: String) -> bool:
	if not FileAccess.file_exists(HELPER_EMBEDDED_B64_PATH):
		print("[GlobalKeyBridge] Base64 resource not found at: ", HELPER_EMBEDDED_B64_PATH)
		return false

	print("[GlobalKeyBridge] Opening base64 resource: ", HELPER_EMBEDDED_B64_PATH)
	var file := FileAccess.open(HELPER_EMBEDDED_B64_PATH, FileAccess.READ)
	if file == null:
		push_error("[GlobalKeyBridge] Failed to open base64 resource")
		return false

	var b64 := file.get_as_text().strip_edges()
	if b64 == "":
		push_error("[GlobalKeyBridge] Base64 resource is empty")
		return false

	print("[GlobalKeyBridge] Decoding %d bytes of base64 data" % b64.length())
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.is_empty():
		push_error("[GlobalKeyBridge] Base64 decoding resulted in empty bytes")
		return false

	print("[GlobalKeyBridge] Decoded to %d bytes" % bytes.size())
	var out_file := FileAccess.open(target_path, FileAccess.WRITE)
	if out_file == null:
		push_error("[GlobalKeyBridge] Unable to write helper executable to %s" % target_path)
		return false

	out_file.store_buffer(bytes)
	print("[GlobalKeyBridge] Successfully wrote %d bytes to %s" % [bytes.size(), target_path])
	return true

func _exit_tree():
	_stop_bridge()

func _stop_bridge():
	for i in range(clients.size() - 1, -1, -1):
		_remove_client(i)

	if server.is_listening():
		server.stop()

	if helper_pid != -1:
		OS.kill(helper_pid)
		helper_pid = -1

func _remove_client(index: int):
	if index < 0 or index >= clients.size():
		return

	var client := clients[index]
	client.disconnect_from_host()
	client_buffers.erase(client.get_instance_id())
	clients.remove_at(index)
