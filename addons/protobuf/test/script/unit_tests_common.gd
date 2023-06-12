@tool
#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2022, Kittenseater, Oleg Malyavkin
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

extends Node

var P
var root_path : String
var protobuf_version : String


func _init(proto, path : String, version : String):
	P = proto
	root_path = path
	protobuf_version = version


class BinCheckResult:
	
	func _init(bs : String, rs : String, ra : Array, r : bool):
			binary_string = bs
			result_string = rs
			reference_array = ra
			result = r
	
	var binary_string : String
	var result_string : String
	var reference_array : Array
	var result : bool

func binary_check(test_name : String, godot_rv) -> BinCheckResult:
	var result_string : String
	var result : bool = false
	var binary_string : String = "[no data]"
	var ref_file_path = root_path + "/expected_bin/proto" + protobuf_version + "/" + test_name + ".v" + protobuf_version + "ref"
	var ref_rv = null
	if FileAccess.file_exists(ref_file_path):
		var ref_file = FileAccess.open(ref_file_path, FileAccess.READ)
		if ref_file != null:
			ref_rv = ref_file.get_buffer(ref_file.get_length())
			binary_string = str_raw_array(ref_rv)
			if godot_rv.size() == ref_rv.size():
				var equal = true
				var fail_index
				for index in range(godot_rv.size()):
					if godot_rv[index] != ref_rv[index]:
						equal = false
						fail_index = index
						break
				if equal:
					result_string = "SUCCESS"
					result = true
				else:
					result_string = "FAIL: test data for '" + test_name + "' not equal at " + str(fail_index)
			else:
				result_string = "FAIL: test data length for '" + test_name + "' not equal"
			ref_file.close()
		else:
			result_string = "FAIL: can't read '" + ref_file_path + "'"
	else:
		result_string = "FAIL: '" + ref_file_path + "' not exist"
	return BinCheckResult.new(binary_string, result_string, ref_rv, result)

const FUNC_NAME = 0
const CLASS_NAME = 1

func exec(test, save_to_file, test_names) -> bool:
	print("======================= BEGIN TESTS v" + protobuf_version + " =======================")
	var tests_counter = 0
	var success_pack_counter = 0
	var godot_success_unpack_counter = 0
	var protobuf_success_unpack_counter = 0
	for test_name in test_names:
		tests_counter += 1
		print("----- ", test_name[FUNC_NAME], " -----")
		var test_func = Callable(test, test_name[FUNC_NAME])
		var packed_object = test_name[CLASS_NAME].new()
		var godot_rv = test_func.call(packed_object)
		if save_to_file:
			var out_file_name = root_path + "/temp/" + test_name[FUNC_NAME] + ".v" + protobuf_version + "godobuf"
			var out_file = FileAccess.open(out_file_name, FileAccess.WRITE)
			if out_file != null:
				out_file.store_buffer(godot_rv)
				out_file.close()
			else:
				print("failed write out file: ", out_file_name)
				
		# compare bin dumps
		var iteration = 0
		var bin_result = binary_check(test_name[FUNC_NAME], godot_rv)
		if !bin_result.result:
			while test_name.size() > iteration + 2:
				iteration += 1
				bin_result = binary_check(test_name[FUNC_NAME] + "_" + str(test_name[iteration + 1]), godot_rv)
				if bin_result.result:
					break
		
		if bin_result.result:
			success_pack_counter += 1

		print(packed_object.to_string())
		print("[bin actual     ] ", str_raw_array(godot_rv))
		print("[bin expected   ] ", bin_result.binary_string)
		print("[bin compare    ] ", bin_result.result_string)
		
		var restored_object_godot = test_name[CLASS_NAME].new()
		var error_godot = restored_object_godot.from_bytes(godot_rv)
		if object_equal(packed_object, restored_object_godot):
			godot_success_unpack_counter += 1
			if error_godot == P.PB_ERR.NO_ERRORS:
				print("[unpack godobuf ] SUCCESS")
			else:
				print("[unpack godobuf ] FAIL: ", err_to_str(error_godot))
		else:
			print("[unpack godobuf ] FAIL: packed_object & restored_object not equals")
		
		if bin_result.reference_array != null:
			var restored_object_erl = test_name[CLASS_NAME].new()
			var error_erl = restored_object_erl.from_bytes(bin_result.reference_array)
			if object_equal(packed_object, restored_object_erl):
				protobuf_success_unpack_counter += 1
				if error_erl == P.PB_ERR.NO_ERRORS:
					print("[unpack protobuf] SUCCESS")
				else:
					print("[unpack protobuf] FAIL: ", err_to_str(error_erl))
			else:
				print("[unpack protobuf] FAIL: packed_object & restored_object not equals")
		else:
			print("[unpack protobuf] FAIL: no protobuf binary")
		print("")
	print("===================== TESTS v" + protobuf_version + " COMLETED ======================")
	print("godobuf & protobuf compare success done " + str(success_pack_counter) + " of " + str(tests_counter))
	print("godobuf unpack success done " + str(godot_success_unpack_counter) + " of " + str(tests_counter))
	print("protobuf unpack success done " + str(protobuf_success_unpack_counter) + " of " + str(tests_counter))
	
	return success_pack_counter == tests_counter \
	 && godot_success_unpack_counter == tests_counter \
	 && protobuf_success_unpack_counter == tests_counter

func object_equal(packed_object, restored_object):
	for data_key in packed_object.data:
		# checks for existence of a key
		if !restored_object.data.has(data_key):
			return false
		
		var po_rule = packed_object.data[data_key].field.rule
		var ro_rule = restored_object.data[data_key].field.rule
		
		var po_value = packed_object.data[data_key].field.value
		var ro_value = restored_object.data[data_key].field.value
		
		if po_value == null && ro_value == null:
			return true
		
		if (po_value == null && ro_value != null) \
			|| (po_value != null && ro_value == null):
			return false
		
		var po_type = packed_object.data[data_key].field.type
		var ro_type = restored_object.data[data_key].field.type
		
		# checks for existence of a repeated
		if po_rule != ro_rule:
			return false
		# checks for type matching
		if po_type != ro_type:
			return false
			
		# differents checks according the types
		if po_type == P.PB_DATA_TYPE.INT32 			\
			|| po_type == P.PB_DATA_TYPE.SINT32 	\
			|| po_type == P.PB_DATA_TYPE.UINT32 	\
			|| po_type == P.PB_DATA_TYPE.INT64 		\
			|| po_type == P.PB_DATA_TYPE.SINT64 	\
			|| po_type == P.PB_DATA_TYPE.UINT64 	\
			|| po_type == P.PB_DATA_TYPE.BOOL 		\
			|| po_type == P.PB_DATA_TYPE.ENUM 		\
			|| po_type == P.PB_DATA_TYPE.FIXED32	\
			|| po_type == P.PB_DATA_TYPE.SFIXED32	\
			|| po_type == P.PB_DATA_TYPE.FLOAT		\
			|| po_type == P.PB_DATA_TYPE.FIXED64	\
			|| po_type == P.PB_DATA_TYPE.SFIXED64	\
			|| po_type == P.PB_DATA_TYPE.DOUBLE		\
			|| po_type == P.PB_DATA_TYPE.STRING:
			
			# checks objects values
			if po_rule == P.PB_RULE.REPEATED:
				# ...for repeated fields
				if po_value.size() != ro_value.size():
					return false
				for i in range(po_value.size()):
					if po_value[i] != ro_value[i]:
						return false
			else:
				# ...for not-repeated fields
				if po_value != ro_value:
					return false
		elif po_type == P.PB_DATA_TYPE.BYTES:
			if po_rule == P.PB_RULE.REPEATED:
				# ...for repeated fields
				if po_value.size() != ro_value.size():
					return false
				for i in range(po_value.size()):
					for j in range(po_value[i].size()):
						if po_value[i][j] != ro_value[i][j]:
							return false
			else:
				# ...for not-repeated fields
				if po_value.size() != ro_value.size():
					return false
				for i in range(po_value.size()):
					if po_value[i] != ro_value[i]:
						return false
		elif po_type == P.PB_DATA_TYPE.MESSAGE:
			if po_rule == P.PB_RULE.REPEATED:
				# ...for repeated fields
				if po_value.size() != ro_value.size():
					return false
				for i in range(po_value.size()):
					if !object_equal(po_value[i], ro_value[i]):
						return false
			else:
				# ...for not-repeated fields
				if !object_equal(po_value, ro_value):
					return false
		elif po_type == P.PB_DATA_TYPE.MAP:
			var po_map = P.PBPacker.construct_map(po_value)
			var ro_map = P.PBPacker.construct_map(ro_value)
			if po_map.size() != po_map.size():
				return false
			
			for key in po_map.keys():
				var po_found = -1
				for i in range(po_value.size() - 1, -1, -1):
					if key == po_value[i].get_key():
						if !ro_map.has(key):
							return false
						po_found = i
						break
				
				if po_found == -1:
					return false
					
				var ro_found = -1
				for i in range(ro_value.size() - 1, -1, -1):
					if key == ro_value[i].get_key():
						ro_found = i
						break
				
				if ro_found == -1:
					return false
				
				if !object_equal(po_value[po_found], ro_value[ro_found]):
					return false
		elif po_type == P.PB_DATA_TYPE.ONEOF:
			return object_equal(po_value, ro_value)
	return true

func err_to_str(err_code):
	if err_code == P.PB_ERR.NO_ERRORS:
		return "NO_ERRORS(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.VARINT_NOT_FOUND:
		return "VARINT_NOT_FOUND(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.REPEATED_COUNT_NOT_FOUND:
		return "REPEATED_COUNT_NOT_FOUND(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.REPEATED_COUNT_MISMATCH:
		return "REPEATED_COUNT_MISMATCH(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.LENGTHDEL_SIZE_NOT_FOUND:
		return "LENGTHDEL_SIZE_NOT_FOUND(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.LENGTHDEL_SIZE_MISMATCH:
		return "LENGTHDEL_SIZE_MISMATCH(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.PACKAGE_SIZE_MISMATCH:
		return "PACKAGE_SIZE_MISMATCH(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.UNDEFINED_STATE:
		return "UNDEFINED_STATE(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.PARSE_INCOMPLETE:
		return "PARSE_INCOMPLETE(" + str(err_code) + ")"
	elif err_code == P.PB_ERR.REQUIRED_FIELDS:
		return "REQUIRED_FIELDS(" + str(err_code) + ")"
	else:
		return "UNKNOWN(" + str(err_code) + ")"
		
		
static func str_raw_array(arr):
	if arr.size() == 0:
		return "[]"
		
	var res = "["
	for i in range(arr.size()):
		var hex : String = "%X" % arr[i]
		if hex.length() == 1:
			hex = "0" + hex
		if i == (arr.size() - 1):
			res += hex + "]"
		else:
			res += hex + " "
	return res
