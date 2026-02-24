@tool
#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

extends VBoxContainer

const IDENTIFIER_INVALID: String = "NO_VALID_IDENTIFIER"

var Parser = preload("res://addons/protobuf/parser.gd")
var Util = preload("res://addons/protobuf/protobuf_util.gd")

@onready var select_folder: CheckButton = $SelectFolder

var input_file_path = null
var input_folder_path = null
var output_file_path = null
var output_folder_path = null

func _ready():
	pass

func _on_InputFileButton_pressed():
	if select_folder.button_pressed:
		show_dialog($InputFolderDialog)
		$InputFolderDialog.invalidate()
	else:
		show_dialog($InputFileDialog)
		$InputFileDialog.invalidate()

func _on_OutputFileButton_pressed():
	if select_folder.button_pressed:
		show_dialog($OutputFolderDialog)
		$OutputFolderDialog.invalidate()
	else:
		show_dialog($OutputFileDialog)
		$OutputFileDialog.invalidate()

func _on_InputFileDialog_file_selected(path):
	
	input_file_path = path
	$HBoxContainer/InputFileEdit.text = path

func _on_input_folder_dialog_dir_selected(dir: String) -> void:
	input_folder_path = dir
	$HBoxContainer/InputFileEdit.text = dir

func _on_OutputFileDialog_file_selected(path):
	
	output_file_path = path
	$HBoxContainer2/OutputFileEdit.text = path

func _on_output_folder_dialog_dir_selected(dir: String) -> void:
	output_folder_path = dir
	$HBoxContainer2/OutputFileEdit.text = dir

func show_dialog(dialog):
	
	dialog.popup_centered()

func get_custom_message_prefix() -> String:
	var prefix: String = ""
	if $MessagePrefixCheckButton.is_pressed():
		prefix = $HBoxContainer3/MessagePrefixEdit.text

		if !prefix.is_valid_identifier():
			show_dialog($PrefixErrorAcceptDialog)
			return IDENTIFIER_INVALID
	return prefix

func get_custom_class_name() -> String:
	var custom_class_name = ""
	if $ClassNameCheckButton.is_pressed():
		custom_class_name = $HBoxContainer4/ClassNameEdit.text

		if !custom_class_name.is_valid_identifier():
			show_dialog($ClassNameErrorAcceptDialog)
			return IDENTIFIER_INVALID
	return custom_class_name

func parse_file(parser: Parser, file: FileAccess, message_prefix: String, should_prefix_enums: bool, custom_class_name: String) -> bool: 
	if file == null:
		print("File: '", input_file_path, "' not found.")
		show_dialog($FailAcceptDialog)
		return false
	
	if parser.work(Util.extract_dir(input_file_path), Util.extract_filename(input_file_path), \
		output_file_path, "res://addons/protobuf/protobuf_core.gd", message_prefix, should_prefix_enums, custom_class_name):
		show_dialog($SuccessAcceptDialog)
	else:
		show_dialog($FailAcceptDialog)
		return false
	
	return true

func _on_CompileButton_pressed():
	if input_file_path == null || output_file_path == null:
		show_dialog($FilesErrorAcceptDialog)
		return
	
	var message_prefix = get_custom_message_prefix()
	if message_prefix == IDENTIFIER_INVALID: return

	var should_prefix_enums = $EnumPrefixCheckButton.is_pressed()

	var custom_class_name = get_custom_class_name()
	if custom_class_name == IDENTIFIER_INVALID: return
	
	var parser = Parser.new()
	var file = FileAccess.open(input_file_path, FileAccess.READ)
	parse_file(parser, file, message_prefix, should_prefix_enums, custom_class_name)
	file.close()
	return

func _on_compile_all_button_pressed() -> void:
	if input_folder_path == null || output_folder_path == null:
		show_dialog($FilesErrorAcceptDialog)
		return
	
	var dir: DirAccess = DirAccess.open(input_folder_path)
	if dir == null:
		show_dialog($FilesErrorAcceptDialog)
		return
	
	var message_prefix = get_custom_message_prefix()
	if message_prefix == IDENTIFIER_INVALID: return

	var should_prefix_enums = $EnumPrefixCheckButton.is_pressed()

	var custom_class_name = get_custom_class_name()
	if custom_class_name == IDENTIFIER_INVALID: return
	
	dir.list_dir_begin()
	for file_string: String in dir.get_files():
		if file_string.split(".")[1] != "proto":
			print("Not proto: {0} ({1})".format([file_string, file_string.split(".")[1] ]))
			continue
		input_file_path = "{0}/{1}".format([input_folder_path, file_string])
		var output_file = "{0}.{1}".format([file_string.split(".")[0], "gd"])
		output_file_path = "{0}/{1}".format([output_folder_path, output_file])
		
		
		var parser = Parser.new()
		var file: FileAccess = FileAccess.open(input_file_path, FileAccess.READ)
		parse_file(parser, file, message_prefix, should_prefix_enums, custom_class_name)
		file.close()

func execute_unit_tests(source_name, script_name, compiled_script_name):
	
	var test_path = "res://addons/protobuf/test/"
	var test_input_file_path = test_path + "source/" + source_name
	var test_output_dir_path = test_path + "temp"
	var test_output_file_path = test_output_dir_path + "/" + compiled_script_name
	
	var output_dir = DirAccess.make_dir_absolute(test_output_dir_path)
	if output_dir == null:
		print("Cannot create output directory: '", test_output_dir_path, "'.")
		show_dialog($FailAcceptDialog)
		return
	
	var test_file = FileAccess.open(test_input_file_path, FileAccess.READ)
	if test_file == null:
		print("File: '", input_file_path, "' not found.")
		show_dialog($FailAcceptDialog)
		return
	
	var parser = Parser.new()
	
	if parser.work("", test_input_file_path, test_output_file_path, "res://addons/protobuf/protobuf_core.gd"):
		var test_script = load(test_path + "script/" + script_name).new(test_path, test_output_file_path)
		if test_script.exec_all(false):
			show_dialog($SuccessTestDialog)
		else:
			show_dialog($FailTestDialog)
	else:
		show_dialog($FailAcceptDialog)
	
	test_file.close()
	
	return

func _on_TestButton2_pressed() :
	
	execute_unit_tests("pbtest2.proto", "unit_tests_proto2.gd", "proto2.gd")

func _on_TestButton3_pressed() :
	
	execute_unit_tests("pbtest3.proto", "unit_tests_proto3.gd", "proto3.gd")
