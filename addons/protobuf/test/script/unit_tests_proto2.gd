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

const VERSION : String = "2"
var P
var Test

func _init(path : String, compiled_file_path : String):
	P = load(compiled_file_path)
	Test = load(path + "/script/unit_tests_common.gd").new(P, path, VERSION)

func exec_all(save_to_file) -> bool:
	return Test.exec(self, save_to_file, [
		["f_double", 	P.Test1], 
		["f_float", 	P.Test1], 
		["f_int32", 	P.Test1], 
		["f_int64", 	P.Test1], 
		["f_uint32", 	P.Test1], 
		["f_uint64", 	P.Test1], 
		["f_sint32", 	P.Test1], 
		["f_sint64", 	P.Test1],
		["f_fixed32", 	P.Test1], 
		["f_fixed64", 	P.Test1], 
		["f_sfixed32", 	P.Test1], 
		["f_sfixed64", 	P.Test1], 
		["f_bool", 		P.Test1], 
		["f_string", 	P.Test1], 
		["f_bytes", 	P.Test1], 
		["f_map", 		P.Test1, 1], 
		["f_oneof_f1", 	P.Test1], 
		["f_oneof_f2", 	P.Test1],
		["f_empty_out", 	P.Test1],
		["f_enum_out", 		P.Test1],
		["f_empty_inner", 	P.Test1],
		["f_enum_inner", 	P.Test1],
		
		["rf_double", 	P.Test1], 
		["rf_float", 	P.Test1], 
		["rf_int32", 	P.Test1], 
		["rf_int32_with_clear", 	P.Test1], 
		["rf_int64", 	P.Test1], 
		["rf_uint32", 	P.Test1], 
		["rf_uint64", 	P.Test1], 
		["rf_sint32", 	P.Test1], 
		["rf_sint64", 	P.Test1],
		["rf_fixed32", 	P.Test1], 
		["rf_fixed64", 	P.Test1], 
		["rf_sfixed32", P.Test1], 
		["rf_sfixed64", P.Test1], 
		["rf_bool", 	P.Test1], 
		["rf_string", 	P.Test1], 
		["rf_bytes", 	P.Test1], 
		["rf_empty_out", 	P.Test1],
		["rf_enum_out", 	P.Test1],
		["rf_empty_inner", 	P.Test1],
		["rf_enum_inner", 	P.Test1],
		
		["rf_double_empty", 	P.Test1], 
		["rf_float_empty", 		P.Test1], 
		["rf_int32_empty", 		P.Test1], 
		["rf_int64_empty", 		P.Test1], 
		["rf_uint32_empty", 	P.Test1], 
		["rf_uint64_empty", 	P.Test1],
		["rf_sint32_empty", 	P.Test1], 
		["rf_sint64_empty", 	P.Test1], 
		["rf_fixed32_empty", 	P.Test1], 
		["rf_fixed64_empty", 	P.Test1], 
		["rf_sfixed32_empty", 	P.Test1], 
		["rf_sfixed64_empty",	P.Test1],
		["rf_bool_empty", 		P.Test1], 
		["rf_string_empty", 	P.Test1], 
		["rf_bytes_empty", 		P.Test1],
		
		["rfu_double", 		P.Test1], 
		["rfu_float", 		P.Test1], 
		["rfu_int32", 		P.Test1], 
		["rfu_int64", 		P.Test1], 
		["rfu_uint32", 		P.Test1], 
		["rfu_uint64", 		P.Test1], 
		["rfu_sint32", 		P.Test1], 
		["rfu_sint64", 		P.Test1],
		["rfu_fixed32",		P.Test1], 
		["rfu_fixed64",		P.Test1], 
		["rfu_sfixed32", 	P.Test1], 
		["rfu_sfixed64", 	P.Test1], 
		["rfu_bool", 		P.Test1], 
		
		["f_int32_default", 	P.Test1], 
		["f_string_default", 	P.Test1], 
		["f_bytes_default", 	P.Test1], 
		["test2_testinner3_testinner32", 		P.Test2.TestInner3.TestInner3_2], 
		["test2_testinner3_testinner32_empty", 	P.Test2.TestInner3.TestInner3_2], 
		["rf_inner_ene", 		P.Test1], 
		["rf_inner_nen", 		P.Test1], 
		
		["simple_all", 	P.Test1, 1],

		["test2_1",		P.Test2],
		["test2_2",		P.Test2, 1],
		["test2_3",		P.Test2],
		["test2_4",		P.Test2, 1],
		
		["test4",			P.Test4],
		["test4_map",		P.Test4, 1, 2, 3, 4, 5],
		["test4_map_dup",	P.Test4],
		["test4_map_zero_key",	P.Test4]
	])


#######################
######## Test1 ########
#######################

# single values #
func f_double(t):
	t.set_f_double(1.2340000152587890625e1)
	return t.to_bytes()

func f_float(t):
	t.set_f_float(1.2340000152587890625e1)
	return t.to_bytes()

func f_int32(t):
	t.set_f_int32(1234)
	return t.to_bytes()

func f_int64(t):
	t.set_f_int64(1234)
	return t.to_bytes()

func f_uint32(t):
	t.set_f_uint32(1234)
	return t.to_bytes()

func f_uint64(t):
	t.set_f_uint64(1234)
	return t.to_bytes()

func f_sint32(t):
	t.set_f_sint32(1234)
	return t.to_bytes()

func f_sint64(t):
	t.set_f_sint64(1234)
	return t.to_bytes()

func f_fixed32(t):
	t.set_f_fixed32(1234)
	return t.to_bytes()

func f_fixed64(t):
	t.set_f_fixed64(1234)
	return t.to_bytes()

func f_sfixed32(t):
	t.set_f_sfixed32(1234)
	return t.to_bytes()

func f_sfixed64(t):
	t.set_f_sfixed64(1234)
	return t.to_bytes()

func f_bool(t):
	t.set_f_bool(false)
	return t.to_bytes()

func f_string(t):
	t.set_f_string("string value")
	return t.to_bytes()

func f_bytes(t):
	t.set_f_bytes([1, 2, 3, 4])
	return t.to_bytes()

func f_map(t):
	t.add_f_map(1, 2)
	t.add_f_map(1000, 2000)
	return t.to_bytes()

func f_oneof_f1(t):
	t.set_f_oneof_f1("oneof value")
	return t.to_bytes()

func f_oneof_f2(t):
	t.set_f_oneof_f2(1234)
	return t.to_bytes()

func f_empty_out(t):
	t.new_f_empty_out()
	return t.to_bytes()

func f_enum_out(t):
	t.set_f_enum_out(P.Enum0.ONE)
	return t.to_bytes()

func f_empty_inner(t):
	t.new_f_empty_inner()
	return t.to_bytes()

func f_enum_inner(t):
	t.set_f_enum_inner(P.Test2.TestEnum.VALUE_1)
	return t.to_bytes()

# repeated values #
func rf_double(t):
	t.add_rf_double(1.2340000152587890625e1)
	t.add_rf_double(5.6779998779296875e1)
	return t.to_bytes()

func rf_float(t):
	t.add_rf_float(1.2340000152587890625e1)
	t.add_rf_float(5.6779998779296875e1)
	return t.to_bytes()

func rf_int32(t):
	t.add_rf_int32(1234)
	t.add_rf_int32(5678)
	return t.to_bytes()

func rf_int32_with_clear(t):
	t.add_rf_int32(10)
	t.add_rf_int32(20)
	t.clear_rf_int32()
	t.add_rf_int32(1234)
	t.add_rf_int32(5678)
	return t.to_bytes()

func rf_int64(t):
	t.add_rf_int64(1234)
	t.add_rf_int64(5678)
	return t.to_bytes()

func rf_uint32(t):
	t.add_rf_uint32(1234)
	t.add_rf_uint32(5678)
	return t.to_bytes()

func rf_uint64(t):
	t.add_rf_uint64(1234)
	t.add_rf_uint64(5678)
	return t.to_bytes()

func rf_sint32(t):
	t.add_rf_sint32(1234)
	t.add_rf_sint32(5678)
	return t.to_bytes()

func rf_sint64(t):
	t.add_rf_sint64(1234)
	t.add_rf_sint64(5678)
	return t.to_bytes()

func rf_fixed32(t):
	t.add_rf_fixed32(1234)
	t.add_rf_fixed32(5678)
	return t.to_bytes()

func rf_fixed64(t):
	t.add_rf_fixed64(1234)
	t.add_rf_fixed64(5678)
	return t.to_bytes()

func rf_sfixed32(t):
	t.add_rf_sfixed32(1234)
	t.add_rf_sfixed32(5678)
	return t.to_bytes()

func rf_sfixed64(t):
	t.add_rf_sfixed64(1234)
	t.add_rf_sfixed64(5678)
	return t.to_bytes()

func rf_bool(t):
	t.add_rf_bool(false)
	t.add_rf_bool(true)
	t.add_rf_bool(false)
	return t.to_bytes()

func rf_string(t):
	t.add_rf_string("string value one")
	t.add_rf_string("string value two")
	return t.to_bytes()

func rf_bytes(t):
	t.add_rf_bytes([1, 2, 3, 4])
	t.add_rf_bytes([5, 6, 7, 8])
	return t.to_bytes()

func rf_empty_out(t):
	t.add_rf_empty_out()
	t.add_rf_empty_out()
	t.add_rf_empty_out()
	return t.to_bytes()

func rf_enum_out(t):
	t.add_rf_enum_out(P.Enum0.ONE)
	t.add_rf_enum_out(P.Enum0.TWO)
	t.add_rf_enum_out(P.Enum0.THREE)
	return t.to_bytes()

func rf_empty_inner(t):
	t.add_rf_empty_inner()
	t.add_rf_empty_inner()
	t.add_rf_empty_inner()
	return t.to_bytes()

func rf_enum_inner(t):
	t.add_rf_enum_inner(P.Test2.TestEnum.VALUE_1)
	t.add_rf_enum_inner(P.Test2.TestEnum.VALUE_2)
	t.add_rf_enum_inner(P.Test2.TestEnum.VALUE_3)
	return t.to_bytes()

func rf_double_empty(t):
	return t.to_bytes()

func rf_float_empty(t):
	return t.to_bytes()

func rf_int32_empty(t):
	return t.to_bytes()

func rf_int64_empty(t):
	return t.to_bytes()

func rf_uint32_empty(t):
	return t.to_bytes()

func rf_uint64_empty(t):
	return t.to_bytes()

func rf_sint32_empty(t):
	return t.to_bytes()

func rf_sint64_empty(t):
	return t.to_bytes()

func rf_fixed32_empty(t):
	return t.to_bytes()

func rf_fixed64_empty(t):
	return t.to_bytes()

func rf_sfixed32_empty(t):
	return t.to_bytes()

func rf_sfixed64_empty(t):
	return t.to_bytes()

func rf_bool_empty(t):
	return t.to_bytes()

func rf_string_empty(t):
	return t.to_bytes()

func rf_bytes_empty(t):
	return t.to_bytes()

func rfu_double(t):
	t.add_rfu_double(1.2340000152587890625e1)
	t.add_rfu_double(5.6779998779296875e1)
	return t.to_bytes()

func rfu_float(t):
	t.add_rfu_float(1.2340000152587890625e1)
	t.add_rfu_float(5.6779998779296875e1)
	return t.to_bytes()

func rfu_int32(t):
	t.add_rfu_int32(1234)
	t.add_rfu_int32(5678)
	return t.to_bytes()

func rfu_int64(t):
	t.add_rfu_int64(1234)
	t.add_rfu_int64(5678)
	return t.to_bytes()

func rfu_uint32(t):
	t.add_rfu_uint32(1234)
	t.add_rfu_uint32(5678)
	return t.to_bytes()

func rfu_uint64(t):
	t.add_rfu_uint64(1234)
	t.add_rfu_uint64(5678)
	return t.to_bytes()

func rfu_sint32(t):
	t.add_rfu_sint32(1234)
	t.add_rfu_sint32(5678)
	return t.to_bytes()

func rfu_sint64(t):
	t.add_rfu_sint64(1234)
	t.add_rfu_sint64(5678)
	return t.to_bytes()

func rfu_fixed32(t):
	t.add_rfu_fixed32(1234)
	t.add_rfu_fixed32(5678)
	return t.to_bytes()

func rfu_fixed64(t):
	t.add_rfu_fixed64(1234)
	t.add_rfu_fixed64(5678)
	return t.to_bytes()

func rfu_sfixed32(t):
	t.add_rfu_sfixed32(1234)
	t.add_rfu_sfixed32(5678)
	return t.to_bytes()

func rfu_sfixed64(t):
	t.add_rfu_sfixed64(1234)
	t.add_rfu_sfixed64(5678)
	return t.to_bytes()

func rfu_bool(t):
	t.add_rfu_bool(false)
	t.add_rfu_bool(true)
	t.add_rfu_bool(false)
	return t.to_bytes()

func f_int32_default(t):
	t.set_f_int32(0)
	return t.to_bytes()

func f_string_default(t):
	t.set_f_string("")
	return t.to_bytes()

func f_bytes_default(t):
	t.set_f_bytes([])
	return t.to_bytes()

func test2_testinner3_testinner32(t):
	t.set_f1(12)
	t.set_f2(34)
	return t.to_bytes()

func test2_testinner3_testinner32_empty(t):
	return t.to_bytes()

func rf_inner_ene(t):
	var i0 = t.add_rf_inner()
	var i1 = t.add_rf_inner()
	var i2 = t.add_rf_inner()
	
	i1.set_f1(12)
	i1.set_f2(34)
	
	return t.to_bytes()

func rf_inner_nen(t):
	var i0 = t.add_rf_inner()
	var i1 = t.add_rf_inner()
	var i2 = t.add_rf_inner()
	
	i0.set_f1(12)
	i0.set_f2(34)
	i2.set_f1(12)
	i2.set_f2(34)
		
	return t.to_bytes()

func simple_all(t):
	t.set_f_double(1.2340000152587890625e1)
	t.set_f_float(1.2340000152587890625e1)
	t.set_f_int32(1234)
	t.set_f_int64(1234)
	t.set_f_uint32(1234)
	t.set_f_uint64(1234)
	t.set_f_sint32(1234)
	t.set_f_sint64(1234)
	t.set_f_fixed32(1234)
	t.set_f_fixed64(1234)
	t.set_f_sfixed32(1234)
	t.set_f_sfixed64(1234)
	t.set_f_bool(false)
	t.set_f_string("string value")
	t.set_f_bytes([1, 2, 3, 4])
	t.add_f_map(1, 2)
	t.add_f_map(1000, 2000)
	t.set_f_oneof_f1("oneof value")
	t.new_f_empty_out()
	t.set_f_enum_out(P.Enum0.ONE)
	t.new_f_empty_inner()
	t.set_f_enum_inner(P.Test2.TestEnum.VALUE_1)
	# -----
	t.add_rf_double(1.2340000152587890625e1)
	t.add_rf_double(5.6779998779296875e1)
	
	t.add_rf_float(1.2340000152587890625e1)
	t.add_rf_float(5.6779998779296875e1)
	
	t.add_rf_int32(1234)
	t.add_rf_int32(5678)
	
	t.add_rf_int64(1234)
	t.add_rf_int64(5678)
	
	t.add_rf_uint32(1234)
	t.add_rf_uint32(5678)
	
	t.add_rf_uint64(1234)
	t.add_rf_uint64(5678)
	
	t.add_rf_sint32(1234)
	t.add_rf_sint32(5678)
	
	t.add_rf_sint64(1234)
	t.add_rf_sint64(5678)
	
	t.add_rf_fixed32(1234)
	t.add_rf_fixed32(5678)
	
	t.add_rf_fixed64(1234)
	t.add_rf_fixed64(5678)
	
	t.add_rf_sfixed32(1234)
	t.add_rf_sfixed32(5678)
	
	t.add_rf_sfixed64(1234)
	t.add_rf_sfixed64(5678)
	
	t.add_rf_bool(false)
	t.add_rf_bool(true)
	t.add_rf_bool(false)
	
	t.add_rf_string("string value one")
	t.add_rf_string("string value two")
	
	t.add_rf_bytes([1, 2, 3, 4])
	t.add_rf_bytes([5, 6, 7, 8])
	
	t.add_rf_empty_out()
	t.add_rf_empty_out()
	t.add_rf_empty_out()
	
	t.add_rf_enum_out(P.Enum0.ONE)
	t.add_rf_enum_out(P.Enum0.TWO)
	t.add_rf_enum_out(P.Enum0.THREE)
	
	t.add_rf_empty_inner()
	t.add_rf_empty_inner()
	t.add_rf_empty_inner()
	
	t.add_rf_enum_inner(P.Test2.TestEnum.VALUE_1)
	t.add_rf_enum_inner(P.Test2.TestEnum.VALUE_2)
	t.add_rf_enum_inner(P.Test2.TestEnum.VALUE_3)
	# -----
	t.add_rfu_double(1.2340000152587890625e1)
	t.add_rfu_double(5.6779998779296875e1)
	
	t.add_rfu_float(1.2340000152587890625e1)
	t.add_rfu_float(5.6779998779296875e1)
	
	t.add_rfu_int32(1234)
	t.add_rfu_int32(5678)
	
	t.add_rfu_int64(1234)
	t.add_rfu_int64(5678)
	
	t.add_rfu_uint32(1234)
	t.add_rfu_uint32(5678)
	
	t.add_rfu_uint64(1234)
	t.add_rfu_uint64(5678)
	
	t.add_rfu_sint32(1234)
	t.add_rfu_sint32(5678)
	
	t.add_rfu_sint64(1234)
	t.add_rfu_sint64(5678)
	
	t.add_rfu_fixed32(1234)
	t.add_rfu_fixed32(5678)
	
	t.add_rfu_fixed64(1234)
	t.add_rfu_fixed64(5678)
	
	t.add_rfu_sfixed32(1234)
	t.add_rfu_sfixed32(5678)
	
	t.add_rfu_sfixed64(1234)
	t.add_rfu_sfixed64(5678)
	
	t.add_rfu_bool(false)
	t.add_rfu_bool(true)
	t.add_rfu_bool(false)
	
	return t.to_bytes()

#######################
######## Test2 ########
#######################

func test2_1(t):
	
	# repeated string
	t.add_f1("test text-1")
	t.add_f1("test text-2")
	t.add_f1("test text-3")
	
	# fixed64
	t.set_f2(1234)
	
	# oneof string
	t.set_f3("yet another text")
	
	# empty message
	t.new_f5()
	
	return t.to_bytes()

func test2_2(t):
	
	# Test2.TestInner3
	var f6 = t.new_f6()
	var f6_f1 = f6.add_f1("one")
	f6_f1.set_f1(111)
	f6_f1.set_f2(1111)
	f6_f1 = f6.add_f1("two")
	f6_f1.set_f1(222)
	f6_f1.set_f2(2222)
	
	f6.set_f2(P.Test2.TestEnum.VALUE_1)
	
	f6.new_f3()
	
	return t.to_bytes()

func test2_3(t):
	# repeated string
	t.add_f1("test text-1")
	t.add_f1("test text-2")
	t.add_f1("test text-3")
	
	# fixed64
	t.set_f2(1234)
	
	# oneof 
	var f4 = t.new_f4()
	var f4_f1 = f4.add_f1("one")
	f4_f1.set_f1(111)
	f4_f1.set_f2(1111)
	
	f4.set_f2(t.TestEnum.VALUE_1)
	f4.new_f3()
	
	# empty message
	t.new_f5()
	
	# Test2.TestInner3
	var f6 = t.new_f6()
	var f6_f1 = f6.add_f1("two")
	f6_f1.set_f1(111)
	f6_f1.set_f2(1111)
	
	f6.set_f2(t.TestEnum.VALUE_1)
	
	f6.new_f3()
	
	# Test2.TestInner1
	var f7 = t.new_f7()
	f7.add_f1(1.2340000152587890625e1)
	f7.add_f1(5.6779998779296875e1)
	
	f7.set_f2(1.2340000152587890625e1)
	
	f7.set_f3("sample text")
	
	return t.to_bytes()

func test2_4(t):	
	# Test2.TestInner3
	var f6 = t.new_f6()
	var f6_f1 = f6.add_f1("one")
	f6_f1.set_f1(111)
	f6_f1.set_f2(1111)
	f6_f1 = f6.add_f1("two")
	f6_f1.set_f1(222)
	f6_f1.set_f2(2222)
	f6_f1 = f6.add_f1("one")
	f6_f1.set_f1(333)
	f6_f1.set_f2(3333)
	f6_f1 = f6.add_f1("two")
	f6_f1.set_f1(444)
	f6_f1.set_f2(4444)
	
	return t.to_bytes()

func test4(t):
	t.set_f1(1234)
	t.set_f2("hello")
	t.set_f3(1.2340000152587890625e1)
	t.set_f4(1.2340000152587890625e1)
	return t.to_bytes()

func test4_map(t):
	t.add_f5(5, 6)
	t.add_f5(1, 2)
	t.add_f5(3, 4)
	return t.to_bytes()

func test4_map_dup(t): # 1, 10}, {2, 20}, {1, 20}, {2, 200
	t.add_f5(1, 10)
	t.add_f5(2, 20)
	t.add_f5(1, 20)
	t.add_f5(2, 200)
	return t.to_bytes()
	
func test4_map_zero_key(t):
	t.add_f5(0, 1)
	return t.to_bytes()
