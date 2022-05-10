#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2022, Oleg Malyavkin
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

tool
extends VBoxContainer

var Parser = preload("res://addons/protobuf/parser.gd")
var Util = preload("res://addons/protobuf/protobuf_util.gd")

var input_file_name = null
var output_file_name = null

func _ready():
	var screen_size = OS.get_screen_size()
	pass

func _on_InputFileButton_pressed():
	show_dialog($InputFileDialog)
	$InputFileDialog.invalidate()

func _on_OutputFileButton_pressed():
	show_dialog($OutputFileDialog)
	$OutputFileDialog.invalidate()

func _on_InputFileDialog_file_selected(path):
	input_file_name = path
	$HBoxContainer/InputFileEdit.text = path

func _on_OutputFileDialog_file_selected(path):
	output_file_name = path
	$HBoxContainer2/OutputFileEdit.text = path

func show_dialog(dialog):
	var posX
	var posY
	if get_viewport().size.x <= dialog.get_rect().size.x:
		posX = 0
	else:
		posX = (get_viewport().size.x - dialog.get_rect().size.x) / 2
	if get_viewport().size.y <= dialog.get_rect().size.y:
		posY = 0
	else:
		posY = (get_viewport().size.y - dialog.get_rect().size.y) / 2
	dialog.set_position(Vector2(posX, posY))
	dialog.show_modal(true)

func _on_CompileButton_pressed():
	if input_file_name == null || output_file_name == null:
		show_dialog($FilesErrorAcceptDialog)
		return
	
	var file = File.new()
	if file.open(input_file_name, File.READ) < 0:
		print("File: '", input_file_name, "' not found.")
		show_dialog($FailAcceptDialog)
		return
	
	var parser = Parser.new()
	
	if parser.work(Util.extract_dir(input_file_name), Util.extract_filename(input_file_name), \
		output_file_name, "res://addons/protobuf/protobuf_core.gd"):
		show_dialog($SuccessAcceptDialog)
	else:
		show_dialog($FailAcceptDialog)
	
	return

func execute_unit_tests(source_name, script_name, compiled_script_name):
	
	var test_path = "res://addons/protobuf/test/"
	var test_file = File.new()
	var input_file_path = test_path + "source/" + source_name
	var output_dir_path = test_path + "temp"
	var output_file_path = output_dir_path + "/" + compiled_script_name
	
	var output_dir = Directory.new();
	output_dir.make_dir(output_dir_path)
	
	if test_file.open(input_file_path, File.READ) < 0:
		print("File: '", input_file_path, "' not found.")
		show_dialog($FailAcceptDialog)
		return
	
	var parser = Parser.new()
	
	if parser.work("", input_file_path, output_file_path, "res://addons/protobuf/protobuf_core.gd"):
		var test_script = load(test_path + "script/" + script_name).new(test_path, output_file_path)
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
