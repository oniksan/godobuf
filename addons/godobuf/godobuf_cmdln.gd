#
# BSD 3-Clause License
#
# Copyright (c) 2018, Oleg Malyavkin
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

extends SceneTree

var Parser = preload("res://addons/godobuf/parser.gd")
var Util = preload("res://addons/godobuf/godobuf_util.gd")
var godobuf_core_path = "res://addons/godobuf/godobuf_core.gd"

func error(msg : String):
	push_error(msg)
	quit()

func process_batch(input_batch_path, output_batch_path, message_prefix, should_prefix_enums, custom_class_name):
	print("Input batch path: " + input_batch_path)
	print("Output batch path: " + output_batch_path)
	var parser = Parser.new()
	if parser.work_directory(input_batch_path, output_batch_path, \
		godobuf_core_path, \
		message_prefix, should_prefix_enums, custom_class_name):
		print("Compiled batch from '", input_batch_path, "' to '", output_batch_path, "'.")
	else:
		error("Compilation failed.")	

func process_file(input_file_name, output_file_name, message_prefix, should_prefix_enums, custom_class_name, proto_path):
	print("Input file: " + input_file_name)
	print("Output file: " + output_file_name)
	var file = FileAccess.open(input_file_name, FileAccess.READ)
	if file == null:
		error("File: '" + input_file_name + "' not found.")
	var parser = Parser.new()
	if parser.work(Util.extract_dir(input_file_name), Util.extract_filename(input_file_name), \
		output_file_name, godobuf_core_path, \
		message_prefix, should_prefix_enums, custom_class_name, false, proto_path):
		print("Compiled '", input_file_name, "' to '", output_file_name, "'.")
	else:
		error("Compilation failed.")

func _init():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]

	var batch_mode = false
	var input_batch_path : String = ""
	var output_batch_path : String = ""
	var input_file_name : String = ""
	var output_file_name : String = ""

	if arguments.has("input-batch"):
		batch_mode = true
		input_batch_path = arguments["input-batch"]
		if !arguments.has("output-batch"):
			error("Missing required argument: output")
		output_batch_path = arguments["output-batch"]
	else:
		batch_mode = false
		if !arguments.has("input"):
			error("Missing required argument: input")
		input_file_name = arguments["input"]
		if !arguments.has("output"):
			error("Missing required argument: output")
		output_file_name = arguments["output"]

	var message_prefix = ""
	if arguments.has("prefix"):
		message_prefix = arguments["prefix"]

		if !message_prefix.is_valid_identifier():
			error("The provided prefix is not a valid identifier: " + message_prefix)

	var should_prefix_enums = false
	if arguments.has("should_prefix_enums"):
		var should_prefix_enum_arg = arguments["should_prefix_enums"]

		if should_prefix_enum_arg == "true":
			should_prefix_enums = true
		elif should_prefix_enum_arg == "false":
			should_prefix_enums = false
		else:
			error("should_prefix_enums is not true or false")

	var custom_class_name = ""
	if arguments.has("class_name"):
		custom_class_name = arguments["class_name"]

		if !custom_class_name.is_valid_identifier():
			error("The provided class_name is not a valid identifier: " + custom_class_name)

	var proto_path = ""
	if arguments.has("proto_path"):
		proto_path = arguments["proto_path"]
		if !proto_path.ends_with("/"):
			proto_path += "/"

	if batch_mode:
		process_batch(input_batch_path, output_batch_path, message_prefix, should_prefix_enums, custom_class_name)
	else:
		process_file(input_file_name, output_file_name, message_prefix, should_prefix_enums, custom_class_name, proto_path)

	quit()
