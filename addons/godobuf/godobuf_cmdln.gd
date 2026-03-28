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

func error(msg : String):
	push_error(msg)
	quit()

func _init():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]

	if !arguments.has("input"):
		error("Missing required argument: input")
	var input_file_name = arguments["input"]

	if !arguments.has("output"):
		error("Missing required argument: output")
	var output_file_name = arguments["output"]

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

	var file = FileAccess.open(input_file_name, FileAccess.READ)
	if file == null:
		error("File: '" + input_file_name + "' not found.")

	var parser = Parser.new()

	if parser.work(Util.extract_dir(input_file_name), Util.extract_filename(input_file_name), \
		output_file_name, "res://addons/godobuf/godobuf_core.gd", \
		message_prefix, should_prefix_enums, custom_class_name):

		print("Compiled '", input_file_name, "' to '", output_file_name, "'.")
	else:
		error("Compilation failed.")

	quit()
