extends Node

var Parser = preload("res://addons/protobuf/parser.gd")

func _assert(condition: bool, message: String) -> bool:
	if !condition:
		printerr(message)
	return condition

func exec_all() -> bool:
	var source_dir = "res://addons/protobuf/test/source/batch"
	var output_dir = "res://addons/protobuf/test/temp/batch"
	var parser = Parser.new()

	if !parser.work_directory(source_dir, output_dir, "res://addons/protobuf/protobuf_core.gd"):
		printerr("Batch compilation failed.")
		return false

	var common_out = output_dir + "/net/common.gd"
	var auth_out = output_dir + "/net/auth.gd"
	var envelope_out = output_dir + "/net/envelope.gd"

	if !_assert(FileAccess.file_exists(common_out), "Missing generated file: " + common_out):
		return false
	if !_assert(FileAccess.file_exists(auth_out), "Missing generated file: " + auth_out):
		return false
	if !_assert(FileAccess.file_exists(envelope_out), "Missing generated file: " + envelope_out):
		return false

	var envelope_script = load(envelope_out)
	if !_assert(envelope_script != null, "Failed to load envelope script."):
		return false

	var packet = envelope_script.Capsule.new()
	if !_assert(packet != null, "Failed to instantiate Capsule."):
		return false
	if !_assert(packet.has_method("new_lorem"), "Capsule missing new_lorem()."):
		return false
	if !_assert(packet.has_method("new_amet"), "Capsule missing new_amet()."):
		return false

	var hello = packet.new_lorem()
	hello.set_schema_rev(46)
	var bytes = packet.to_bytes()
	if !_assert(bytes.size() > 0, "Packet bytes should not be empty after setting oneof payload."):
		return false

	var restored_packet = envelope_script.Capsule.new()
	var state = restored_packet.from_bytes(bytes)
	if !_assert(state == envelope_script.PB_ERR.NO_ERRORS, "Failed to parse Packet from bytes."):
		return false
	if !_assert(restored_packet.has_lorem(), "Expected oneof lorem payload to be present after deserialize."):
		return false

	return true
