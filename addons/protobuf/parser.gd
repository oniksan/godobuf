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

extends Node

const PROTO_VERSION_CONST : String = "const PROTO_VERSION = "
const PROTO_VERSION_DEFAULT : String = PROTO_VERSION_CONST + "0"

class Document:
	
	func _init(doc_name : String, doc_text : String):
		name = doc_name
		text = doc_text
	
	var name : String
	var text : String

class TokenPosition:
	func _init(b : int, e : int):
		begin = b
		end = e
	var begin : int = 0
	var end : int = 0

class Helper:

	class StringPosition:
		func _init(s : int, c : int, l : int):
			str_num = s
			column = c
			length = l
		var str_num : int
		var column : int
		var length : int
	
	static func str_pos(text : String, position : TokenPosition) -> StringPosition:
		var cur_str : int = 1
		var cur_col : int = 1
		var res_str : int = 0
		var res_col : int = 0
		var res_length : int = 0
		for i in range(text.length()):
			if text[i] == "\n":
				cur_str += 1
				cur_col = 0
			if position.begin == i:
				res_str = cur_str
				res_col = cur_col
				res_length = position.end - position.begin + 1
				break
			cur_col += 1
		return StringPosition.new(res_str, res_col, res_length)
	
	static func text_pos(tokens : Array, index : int) -> TokenPosition:
		var res_begin : int = 0
		var res_end : int = 0
		if index < tokens.size() && index >= 0:
			res_begin = tokens[index].position.begin
			res_end = tokens[index].position.end
		return TokenPosition.new(res_begin, res_end)
	
	static func error_string(file_name, col, row, error_text):
		return file_name + ":" + str(col) + ":" + str(row) + ": error: " + error_text

class AnalyzeResult:
	var classes : Array = []
	var fields : Array = []
	var groups : Array = []
	var version : int = 0
	var state : bool = false
	var tokens : Array = []
	var syntax : Analysis.TranslationResult
	var imports : Array = []
	var doc : Document
	
	func soft_copy() -> AnalyzeResult:
		var res : AnalyzeResult = AnalyzeResult.new()
		res.classes = classes
		res.fields = fields
		res.groups = groups
		res.version = version
		res.state = state
		res.tokens = tokens
		res.syntax = syntax
		res.imports = imports
		res.doc = doc
		return res

class Analysis:
	
	func _init(path : String, doc : Document):
		path_dir = path
		document = doc
	
	var document : Document
	var path_dir : String
	
	const LEX = {
		LETTER = "[A-Za-z]",
		DIGIT_DEC = "[0-9]",
		DIGIT_OCT = "[0-7]",
		DIGIT_HEX = "[0-9]|[A-F]|[a-f]",
		BRACKET_ROUND_LEFT = "\\(",
		BRACKET_ROUND_RIGHT = "\\)",
		BRACKET_CURLY_LEFT = "\\{",
		BRACKET_CURLY_RIGHT = "\\}",
		BRACKET_SQUARE_LEFT = "\\[",
		BRACKET_SQUARE_RIGHT = "\\]",
		BRACKET_ANGLE_LEFT = "\\<",
		BRACKET_ANGLE_RIGHT = "\\>",
		SEMICOLON = ";",
		COMMA = ",",
		EQUAL = "=",
		SIGN = "\\+|\\-",
		SPACE = "\\s",
		QUOTE_SINGLE = "'",
		QUOTE_DOUBLE = "\"",
	}
	
	const TOKEN_IDENT : String = "(" + LEX.LETTER + "+" + "(" + LEX.LETTER + "|" + LEX.DIGIT_DEC + "|" + "_)*)"
	const TOKEN_FULL_IDENT : String = TOKEN_IDENT + "{0,1}(\\." + TOKEN_IDENT + ")+"
	const TOKEN_BRACKET_ROUND_LEFT : String = "(" + LEX.BRACKET_ROUND_LEFT + ")"
	const TOKEN_BRACKET_ROUND_RIGHT : String = "(" + LEX.BRACKET_ROUND_RIGHT + ")"
	const TOKEN_BRACKET_CURLY_LEFT : String = "(" + LEX.BRACKET_CURLY_LEFT + ")"
	const TOKEN_BRACKET_CURLY_RIGHT : String = "(" + LEX.BRACKET_CURLY_RIGHT + ")"
	const TOKEN_BRACKET_SQUARE_LEFT : String = "(" + LEX.BRACKET_SQUARE_LEFT + ")"
	const TOKEN_BRACKET_SQUARE_RIGHT : String = "(" + LEX.BRACKET_SQUARE_RIGHT + ")"
	const TOKEN_BRACKET_ANGLE_LEFT : String = "(" + LEX.BRACKET_ANGLE_LEFT + ")"
	const TOKEN_BRACKET_ANGLE_RIGHT : String = "(" + LEX.BRACKET_ANGLE_RIGHT + ")"
	const TOKEN_SEMICOLON : String = "(" + LEX.SEMICOLON + ")"
	const TOKEN_EUQAL : String = "(" + LEX.EQUAL + ")"
	const TOKEN_SIGN : String = "(" + LEX.SIGN + ")"
	const TOKEN_LITERAL_DEC : String = "(([1-9])" + LEX.DIGIT_DEC +"*)"
	const TOKEN_LITERAL_OCT : String = "(0" + LEX.DIGIT_OCT +"*)"
	const TOKEN_LITERAL_HEX : String = "(0(x|X)(" + LEX.DIGIT_HEX +")+)"
	const TOKEN_LITERAL_INT : String = "((\\+|\\-){0,1}" + TOKEN_LITERAL_DEC + "|" + TOKEN_LITERAL_OCT + "|" + TOKEN_LITERAL_HEX + ")"
	const TOKEN_LITERAL_FLOAT_DEC : String = "(" + LEX.DIGIT_DEC + "+)"
	const TOKEN_LITERAL_FLOAT_EXP : String = "((e|E)(\\+|\\-)?" + TOKEN_LITERAL_FLOAT_DEC + "+)"
	const TOKEN_LITERAL_FLOAT : String = "((\\+|\\-){0,1}(" + TOKEN_LITERAL_FLOAT_DEC + "\\." + TOKEN_LITERAL_FLOAT_DEC + "?" + TOKEN_LITERAL_FLOAT_EXP + "?)|(" + TOKEN_LITERAL_FLOAT_DEC + TOKEN_LITERAL_FLOAT_EXP + ")|(\\." + TOKEN_LITERAL_FLOAT_DEC + TOKEN_LITERAL_FLOAT_EXP + "?))"
	const TOKEN_SPACE : String = "(" + LEX.SPACE + ")+"
	const TOKEN_COMMA : String = "(" + LEX.COMMA + ")"
	const TOKEN_CHAR_ESC : String = "[\\\\(a|b|f|n|r|t|v|\\\\|'|\")]"
	const TOKEN_OCT_ESC : String = "[\\\\" + LEX.DIGIT_OCT + "{3}]"
	const TOKEN_HEX_ESC : String = "[\\\\(x|X)" + LEX.DIGIT_HEX + "{2}]"
	const TOKEN_CHAR_EXCLUDE : String = "[^\\0\\n\\\\]"
	const TOKEN_CHAR_VALUE : String = "(" + TOKEN_HEX_ESC + "|" + TOKEN_OCT_ESC + "|" + TOKEN_CHAR_ESC + "|" + TOKEN_CHAR_EXCLUDE + ")"
	const TOKEN_STRING_SINGLE : String = "('" + TOKEN_CHAR_VALUE + "*?')"
	const TOKEN_STRING_DOUBLE : String = "(\"" + TOKEN_CHAR_VALUE + "*?\")"
	const TOKEN_COMMENT_SINGLE : String = "((//[^\\n\\r]*[^\\s])|//)"
	const TOKEN_COMMENT_MULTI : String = "/\\*(.|[\\n\\r])*?\\*/"
	
	const TOKEN_SECOND_MESSAGE : String = "^message$"
	const TOKEN_SECOND_SIMPLE_DATA_TYPE : String = "^(double|float|int32|int64|uint32|uint64|sint32|sint64|fixed32|fixed64|sfixed32|sfixed64|bool|string|bytes)$"
	const TOKEN_SECOND_ENUM : String = "^enum$"
	const TOKEN_SECOND_MAP : String = "^map$"
	const TOKEN_SECOND_ONEOF : String = "^oneof$"
	const TOKEN_SECOND_LITERAL_BOOL : String = "^(true|false)$"
	const TOKEN_SECOND_SYNTAX : String = "^syntax$"
	const TOKEN_SECOND_IMPORT : String = "^import$"
	const TOKEN_SECOND_PACKAGE : String = "^package$"
	const TOKEN_SECOND_OPTION : String = "^option$"
	const TOKEN_SECOND_SERVICE : String = "^service$"
	const TOKEN_SECOND_RESERVED : String = "^reserved$"
	const TOKEN_SECOND_IMPORT_QUALIFICATION : String = "^(weak|public)$"
	const TOKEN_SECOND_FIELD_QUALIFICATION : String = "^(repeated|required|optional)$"
	const TOKEN_SECOND_ENUM_OPTION : String = "^allow_alias$"
	const TOKEN_SECOND_QUALIFICATION : String = "^(custom_option|extensions)$"
	const TOKEN_SECOND_FIELD_OPTION : String = "^packed$"
	
	class TokenEntrance:
		func _init(i : int, b : int, e : int, t : String):
			position = TokenPosition.new(b, e)
			text = t
			id = i
		var position : TokenPosition
		var text : String
		var id : int
	
	enum RANGE_STATE {
		INCLUDE = 0,
		EXCLUDE_LEFT = 1,
		EXCLUDE_RIGHT = 2,
		OVERLAY = 3,
		EQUAL = 4,
		ENTERS = 5
	}
	
	class TokenRange:
		func _init(b : int, e : int, s):
			position = TokenPosition.new(b, e)
			state = s
		var position : TokenPosition
		var state
	
	class Token:
		var _regex : RegEx
		var _entrance : TokenEntrance = null
		var _entrances : Array = []
		var _entrance_index : int = 0
		var _id : int
		var _ignore : bool
		var _clarification : String
		
		func _init(id : int, clarification : String, regex_str : String, ignore = false):
			_id = id
			_regex = RegEx.new()
			_regex.compile(regex_str)
			_clarification = clarification
			_ignore = ignore
			
		func find(text : String, start : int) -> TokenEntrance:
			_entrance = null
			if !_regex.is_valid():
				return null
			var match_result : RegExMatch = _regex.search(text, start)
			if match_result != null:
				var capture
				capture = match_result.get_string(0)
				if capture.is_empty():
					return null
				_entrance = TokenEntrance.new(_id, match_result.get_start(0), capture.length() - 1 + match_result.get_start(0), capture)
			return _entrance
			
		func find_all(text : String) -> Array:
			var pos : int = 0
			clear()
			while find(text, pos) != null:
				_entrances.append(_entrance)
				pos = _entrance.position.end + 1
			return _entrances
		
		func add_entrance(entrance) -> void:
			_entrances.append(entrance)
		
		func clear() -> void:
			_entrance = null
			_entrances = []
			_entrance_index = 0
			
		func get_entrances() -> Array:
			return _entrances
		
		func remove_entrance(index) -> void:
			if index < _entrances.size():
				_entrances.remove_at(index)
		
		func get_index() -> int:
			return _entrance_index
			
		func set_index(index : int) -> void:
			if index < _entrances.size():
				_entrance_index = index
			else:
				_entrance_index = 0
		
		func is_ignore() -> bool:
			return _ignore
			
		func get_clarification() -> String:
			return _clarification
	
	class TokenResult:
		var tokens : Array = []
		var errors : Array = []
	
	enum TOKEN_ID {
		UNDEFINED = -1,
		IDENT = 0,
		FULL_IDENT = 1,
		BRACKET_ROUND_LEFT = 2,
		BRACKET_ROUND_RIGHT = 3,
		BRACKET_CURLY_LEFT = 4,
		BRACKET_CURLY_RIGHT = 5,
		BRACKET_SQUARE_LEFT = 6,
		BRACKET_SQUARE_RIGHT = 7,
		BRACKET_ANGLE_LEFT = 8,
		BRACKET_ANGLE_RIGHT = 9,
		SEMICOLON = 10,
		EUQAL = 11,
		SIGN = 12,
		INT = 13,
		FLOAT = 14,
		SPACE = 15,
		COMMA = 16,
		STRING_SINGLE = 17,
		STRING_DOUBLE = 18,
		COMMENT_SINGLE = 19,
		COMMENT_MULTI = 20,
		
		MESSAGE = 21,
		SIMPLE_DATA_TYPE = 22,
		ENUM = 23,
		MAP = 24,
		ONEOF = 25,
		LITERAL_BOOL = 26,
		SYNTAX = 27,
		IMPORT = 28,
		PACKAGE = 29,
		OPTION = 30,
		SERVICE = 31,
		RESERVED = 32,
		IMPORT_QUALIFICATION = 33,
		FIELD_QUALIFICATION = 34,
		ENUM_OPTION = 35,
		QUALIFICATION = 36,
		FIELD_OPTION = 37,
		
		STRING = 38
	}
	
	var TOKEN = {
		TOKEN_ID.IDENT: Token.new(TOKEN_ID.IDENT, "Identifier", TOKEN_IDENT),
		TOKEN_ID.FULL_IDENT: Token.new(TOKEN_ID.FULL_IDENT, "Full identifier", TOKEN_FULL_IDENT),
		TOKEN_ID.BRACKET_ROUND_LEFT: Token.new(TOKEN_ID.BRACKET_ROUND_LEFT, "(", TOKEN_BRACKET_ROUND_LEFT),
		TOKEN_ID.BRACKET_ROUND_RIGHT: Token.new(TOKEN_ID.BRACKET_ROUND_RIGHT, ")", TOKEN_BRACKET_ROUND_RIGHT),
		TOKEN_ID.BRACKET_CURLY_LEFT: Token.new(TOKEN_ID.BRACKET_CURLY_LEFT, "{", TOKEN_BRACKET_CURLY_LEFT),
		TOKEN_ID.BRACKET_CURLY_RIGHT: Token.new(TOKEN_ID.BRACKET_CURLY_RIGHT, "}", TOKEN_BRACKET_CURLY_RIGHT),
		TOKEN_ID.BRACKET_SQUARE_LEFT: Token.new(TOKEN_ID.BRACKET_SQUARE_LEFT, "[", TOKEN_BRACKET_SQUARE_LEFT),
		TOKEN_ID.BRACKET_SQUARE_RIGHT: Token.new(TOKEN_ID.BRACKET_SQUARE_RIGHT, "]", TOKEN_BRACKET_SQUARE_RIGHT),
		TOKEN_ID.BRACKET_ANGLE_LEFT: Token.new(TOKEN_ID.BRACKET_ANGLE_LEFT, "<", TOKEN_BRACKET_ANGLE_LEFT),
		TOKEN_ID.BRACKET_ANGLE_RIGHT: Token.new(TOKEN_ID.BRACKET_ANGLE_RIGHT, ">", TOKEN_BRACKET_ANGLE_RIGHT),
		TOKEN_ID.SEMICOLON: Token.new(TOKEN_ID.SEMICOLON, ";", TOKEN_SEMICOLON),
		TOKEN_ID.EUQAL: Token.new(TOKEN_ID.EUQAL, "=", TOKEN_EUQAL),
		TOKEN_ID.INT: Token.new(TOKEN_ID.INT, "Integer", TOKEN_LITERAL_INT),
		TOKEN_ID.FLOAT: Token.new(TOKEN_ID.FLOAT, "Float", TOKEN_LITERAL_FLOAT),
		TOKEN_ID.SPACE: Token.new(TOKEN_ID.SPACE, "Space", TOKEN_SPACE),
		TOKEN_ID.COMMA: Token.new(TOKEN_ID.COMMA, ",", TOKEN_COMMA),
		TOKEN_ID.STRING_SINGLE: Token.new(TOKEN_ID.STRING_SINGLE, "'String'", TOKEN_STRING_SINGLE),
		TOKEN_ID.STRING_DOUBLE: Token.new(TOKEN_ID.STRING_DOUBLE, "\"String\"", TOKEN_STRING_DOUBLE),
		TOKEN_ID.COMMENT_SINGLE: Token.new(TOKEN_ID.COMMENT_SINGLE, "//Comment", TOKEN_COMMENT_SINGLE),
		TOKEN_ID.COMMENT_MULTI: Token.new(TOKEN_ID.COMMENT_MULTI, "/*Comment*/", TOKEN_COMMENT_MULTI),
		
		TOKEN_ID.MESSAGE: Token.new(TOKEN_ID.MESSAGE, "Message", TOKEN_SECOND_MESSAGE, true),
		TOKEN_ID.SIMPLE_DATA_TYPE: Token.new(TOKEN_ID.SIMPLE_DATA_TYPE, "Data type", TOKEN_SECOND_SIMPLE_DATA_TYPE, true),
		TOKEN_ID.ENUM: Token.new(TOKEN_ID.ENUM, "Enum", TOKEN_SECOND_ENUM, true),
		TOKEN_ID.MAP: Token.new(TOKEN_ID.MAP, "Map", TOKEN_SECOND_MAP, true),
		TOKEN_ID.ONEOF: Token.new(TOKEN_ID.ONEOF, "OneOf", TOKEN_SECOND_ONEOF, true),
		TOKEN_ID.LITERAL_BOOL: Token.new(TOKEN_ID.LITERAL_BOOL, "Bool literal", TOKEN_SECOND_LITERAL_BOOL, true),
		TOKEN_ID.SYNTAX: Token.new(TOKEN_ID.SYNTAX, "Syntax", TOKEN_SECOND_SYNTAX, true),
		TOKEN_ID.IMPORT: Token.new(TOKEN_ID.IMPORT, "Import", TOKEN_SECOND_IMPORT, true),
		TOKEN_ID.PACKAGE: Token.new(TOKEN_ID.PACKAGE, "Package", TOKEN_SECOND_PACKAGE, true),
		TOKEN_ID.OPTION: Token.new(TOKEN_ID.OPTION, "Option", TOKEN_SECOND_OPTION, true),
		TOKEN_ID.SERVICE: Token.new(TOKEN_ID.SERVICE, "Service", TOKEN_SECOND_SERVICE, true),
		TOKEN_ID.RESERVED: Token.new(TOKEN_ID.RESERVED, "Reserved", TOKEN_SECOND_RESERVED, true),
		TOKEN_ID.IMPORT_QUALIFICATION: Token.new(TOKEN_ID.IMPORT_QUALIFICATION, "Import qualification", TOKEN_SECOND_IMPORT_QUALIFICATION, true),
		TOKEN_ID.FIELD_QUALIFICATION: Token.new(TOKEN_ID.FIELD_QUALIFICATION, "Field qualification", TOKEN_SECOND_FIELD_QUALIFICATION, true),
		TOKEN_ID.ENUM_OPTION: Token.new(TOKEN_ID.ENUM_OPTION, "Enum option", TOKEN_SECOND_ENUM_OPTION, true),
		TOKEN_ID.QUALIFICATION: Token.new(TOKEN_ID.QUALIFICATION, "Qualification", TOKEN_SECOND_QUALIFICATION, true),
		TOKEN_ID.FIELD_OPTION: Token.new(TOKEN_ID.FIELD_OPTION, "Field option", TOKEN_SECOND_FIELD_OPTION, true),
		
		TOKEN_ID.STRING: Token.new(TOKEN_ID.STRING, "String", "", true)
	}
	
	static func check_range(main : TokenEntrance, current : TokenEntrance) -> TokenRange:
		if main.position.begin > current.position.begin:
			if main.position.end > current.position.end:
				if main.position.begin >= current.position.end:
					return TokenRange.new(current.position.begin, current.position.end, RANGE_STATE.EXCLUDE_LEFT)
				else:
					return TokenRange.new(main.position.begin, current.position.end, RANGE_STATE.OVERLAY)
			else:
				return TokenRange.new(current.position.begin, current.position.end, RANGE_STATE.ENTERS)
		elif main.position.begin < current.position.begin:
			if main.position.end >= current.position.end:
				return TokenRange.new(main.position.begin, main.position.end, RANGE_STATE.INCLUDE)
			else:
				if main.position.end < current.position.begin:
					return TokenRange.new(main.position.begin, main.position.end, RANGE_STATE.EXCLUDE_RIGHT)
				else:
					return TokenRange.new(main.position.begin, current.position.end, RANGE_STATE.OVERLAY)
		else:
			if main.position.end == current.position.end:
				return TokenRange.new(main.position.begin, main.position.end, RANGE_STATE.EQUAL)
			elif main.position.end > current.position.end:
				return TokenRange.new(main.position.begin, main.position.end, RANGE_STATE.INCLUDE)
			else:
				return TokenRange.new(current.position.begin, current.position.end, RANGE_STATE.ENTERS)

	func tokenizer() -> TokenResult:
		for k in TOKEN:
			if !TOKEN[k].is_ignore():
				TOKEN[k].find_all(document.text)
		var second_tokens : Array = []
		second_tokens.append(TOKEN[TOKEN_ID.MESSAGE])
		second_tokens.append(TOKEN[TOKEN_ID.SIMPLE_DATA_TYPE])
		second_tokens.append(TOKEN[TOKEN_ID.ENUM])
		second_tokens.append(TOKEN[TOKEN_ID.MAP])
		second_tokens.append(TOKEN[TOKEN_ID.ONEOF])
		second_tokens.append(TOKEN[TOKEN_ID.LITERAL_BOOL])
		second_tokens.append(TOKEN[TOKEN_ID.SYNTAX])
		second_tokens.append(TOKEN[TOKEN_ID.IMPORT])
		second_tokens.append(TOKEN[TOKEN_ID.PACKAGE])
		second_tokens.append(TOKEN[TOKEN_ID.OPTION])
		second_tokens.append(TOKEN[TOKEN_ID.SERVICE])
		second_tokens.append(TOKEN[TOKEN_ID.RESERVED])
		second_tokens.append(TOKEN[TOKEN_ID.IMPORT_QUALIFICATION])
		second_tokens.append(TOKEN[TOKEN_ID.FIELD_QUALIFICATION])
		second_tokens.append(TOKEN[TOKEN_ID.ENUM_OPTION])
		second_tokens.append(TOKEN[TOKEN_ID.QUALIFICATION])
		second_tokens.append(TOKEN[TOKEN_ID.FIELD_OPTION])
		
		var ident_token : Token = TOKEN[TOKEN_ID.IDENT]
		for sec_token in second_tokens:
			var remove_indexes : Array = []
			for i in range(ident_token.get_entrances().size()):
				var entrance : TokenEntrance = sec_token.find(ident_token.get_entrances()[i].text, 0)
				if entrance != null:
					entrance.position.begin = ident_token.get_entrances()[i].position.begin
					entrance.position.end = ident_token.get_entrances()[i].position.end
					sec_token.add_entrance(entrance)
					remove_indexes.append(i)
			for i in range(remove_indexes.size()):
				ident_token.remove_entrance(remove_indexes[i] - i)
		for v in TOKEN[TOKEN_ID.STRING_DOUBLE].get_entrances():
			v.id = TOKEN_ID.STRING
			TOKEN[TOKEN_ID.STRING].add_entrance(v)
		TOKEN[TOKEN_ID.STRING_DOUBLE].clear()
		for v in TOKEN[TOKEN_ID.STRING_SINGLE].get_entrances():
			v.id = TOKEN_ID.STRING
			TOKEN[TOKEN_ID.STRING].add_entrance(v)
		TOKEN[TOKEN_ID.STRING_SINGLE].clear()
		var main_token : TokenEntrance
		var cur_token : TokenEntrance
		var main_index : int = -1
		var token_index_flag : bool = false
		var result : TokenResult = TokenResult.new()
		var check : TokenRange
		var end : bool = false
		var all : bool = false
		var repeat : bool = false
		while true:
			all = true
			for k in TOKEN:
				if main_index == k:
					continue
				repeat = false
				while TOKEN[k].get_entrances().size() > 0:
					all = false
					if !token_index_flag:
						main_index = k
						main_token = TOKEN[main_index].get_entrances()[0]
						token_index_flag = true
						break
					else:
						cur_token = TOKEN[k].get_entrances()[0]
						check = check_range(main_token, cur_token)
						if check.state == RANGE_STATE.INCLUDE:
							TOKEN[k].remove_entrance(0)
							end = true
						elif check.state == RANGE_STATE.EXCLUDE_LEFT:
							main_token = cur_token
							main_index = k
							end = false
							repeat = true
							break
						elif check.state == RANGE_STATE.EXCLUDE_RIGHT:
							end = true
							break
						elif check.state == RANGE_STATE.OVERLAY || check.state == RANGE_STATE.EQUAL:
							result.errors.append(check)
							TOKEN[main_index].remove_entrance(0)
							TOKEN[k].remove_entrance(0)
							token_index_flag = false
							end = false
							repeat = true
							break
						elif check.state == RANGE_STATE.ENTERS:
							TOKEN[main_index].remove_entrance(0)
							main_token = cur_token
							main_index = k
							end = false
							repeat = true
							break
				if repeat:
					break
			if end:
				if TOKEN[main_index].get_entrances().size() > 0:
					result.tokens.append(main_token)
					TOKEN[main_index].remove_entrance(0)
				token_index_flag = false
			if all:
				break
		return result

	static func check_tokens_integrity(tokens : Array, end : int) -> Array:
		var cur_index : int = 0
		var result : Array = []
		for v in tokens:
			if v.position.begin > cur_index:
				result.append(TokenPosition.new(cur_index, v.position.begin))
			cur_index = v.position.end + 1
		if cur_index < end:
			result.append(TokenPosition.new(cur_index, end))
		return result

	static func comment_space_processing(tokens : Array) -> void:
		var remove_indexes : Array = []
		for i in range(tokens.size()):
			if tokens[i].id == TOKEN_ID.COMMENT_SINGLE || tokens[i].id == TOKEN_ID.COMMENT_MULTI:
				tokens[i].id = TOKEN_ID.SPACE
		var space_index : int = -1
		for i in range(tokens.size()):
			if tokens[i].id == TOKEN_ID.SPACE:
				if space_index >= 0:
					tokens[space_index].position.end = tokens[i].position.end
					tokens[space_index].text = tokens[space_index].text + tokens[i].text
					remove_indexes.append(i)
				else:
					space_index = i
			else:
				space_index = -1
		for i in range(remove_indexes.size()):
			tokens.remove_at(remove_indexes[i] - i)
	
	#Analysis rule
	enum AR {
		MAYBE = 1,
		MUST_ONE = 2,
		ANY = 3,
		OR = 4,
		MAYBE_BEGIN = 5,
		MAYBE_END = 6,
		ANY_BEGIN = 7,
		ANY_END = 8
	}

	#Space rule (space after token)
	enum SP {
		MAYBE = 1,
		MUST = 2,
		NO = 3
	}

	#Analysis Syntax Description
	class ASD:
		func _init(t, s : int = SP.MAYBE, r : int = AR.MUST_ONE, i : bool = false):
			token = t
			space = s
			rule = r
			importance = i
		var token
		var space : int
		var rule : int
		var importance : bool
	
	var TEMPLATE_SYNTAX : Array = [
		Callable(self, "desc_syntax"),
		ASD.new(TOKEN_ID.SYNTAX),
		ASD.new(TOKEN_ID.EUQAL),
		ASD.new(TOKEN_ID.STRING, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.SEMICOLON)
	]
	
	var TEMPLATE_IMPORT : Array = [
		Callable(self, "desc_import"),
		ASD.new(TOKEN_ID.IMPORT, SP.MUST),
		ASD.new(TOKEN_ID.IMPORT_QUALIFICATION, SP.MUST, AR.MAYBE, true),
		ASD.new(TOKEN_ID.STRING, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.SEMICOLON)
	]
	
	var TEMPLATE_PACKAGE : Array = [
		Callable(self, "desc_package"),
		ASD.new(TOKEN_ID.PACKAGE, SP.MUST),
		ASD.new([TOKEN_ID.IDENT, TOKEN_ID.FULL_IDENT], SP.MAYBE, AR.OR, true),
		ASD.new(TOKEN_ID.SEMICOLON)
	]
	
	var TEMPLATE_OPTION : Array = [
		Callable(self, "desc_option"),
		ASD.new(TOKEN_ID.OPTION, SP.MUST),
		ASD.new([TOKEN_ID.IDENT, TOKEN_ID.FULL_IDENT], SP.MAYBE, AR.OR, true),
		ASD.new(TOKEN_ID.EUQAL),
		ASD.new([TOKEN_ID.STRING, TOKEN_ID.INT, TOKEN_ID.FLOAT, TOKEN_ID.LITERAL_BOOL], SP.MAYBE, AR.OR, true),
		ASD.new(TOKEN_ID.SEMICOLON)
	]
	
	var TEMPLATE_FIELD : Array = [
		Callable(self, "desc_field"),
		ASD.new(TOKEN_ID.FIELD_QUALIFICATION, SP.MUST, AR.MAYBE, true),
		ASD.new([TOKEN_ID.SIMPLE_DATA_TYPE, TOKEN_ID.IDENT, TOKEN_ID.FULL_IDENT], SP.MAYBE, AR.OR, true),
		ASD.new(TOKEN_ID.IDENT, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.EUQAL),
		ASD.new(TOKEN_ID.INT, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.BRACKET_SQUARE_LEFT, SP.MAYBE, AR.MAYBE_BEGIN),
		ASD.new(TOKEN_ID.FIELD_OPTION, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.EUQAL),
		ASD.new(TOKEN_ID.LITERAL_BOOL, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.BRACKET_SQUARE_RIGHT, SP.MAYBE, AR.MAYBE_END),
		ASD.new(TOKEN_ID.SEMICOLON)
	]
	
	var TEMPLATE_FIELD_ONEOF : Array = TEMPLATE_FIELD
	
	var TEMPLATE_MAP_FIELD : Array = [
		Callable(self, "desc_map_field"),
		ASD.new(TOKEN_ID.MAP),
		ASD.new(TOKEN_ID.BRACKET_ANGLE_LEFT),
		ASD.new(TOKEN_ID.SIMPLE_DATA_TYPE, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.COMMA),
		ASD.new([TOKEN_ID.SIMPLE_DATA_TYPE, TOKEN_ID.IDENT, TOKEN_ID.FULL_IDENT], SP.MAYBE, AR.OR, true),
		ASD.new(TOKEN_ID.BRACKET_ANGLE_RIGHT, SP.MUST),
		ASD.new(TOKEN_ID.IDENT, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.EUQAL),
		ASD.new(TOKEN_ID.INT, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.BRACKET_SQUARE_LEFT, SP.MAYBE, AR.MAYBE_BEGIN),
		ASD.new(TOKEN_ID.FIELD_OPTION, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.EUQAL),
		ASD.new(TOKEN_ID.LITERAL_BOOL, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.BRACKET_SQUARE_RIGHT, SP.MAYBE, AR.MAYBE_END),
		ASD.new(TOKEN_ID.SEMICOLON)
	]
	
	var TEMPLATE_MAP_FIELD_ONEOF : Array = TEMPLATE_MAP_FIELD
	
	var TEMPLATE_ENUM : Array = [
		Callable(self, "desc_enum"),
		ASD.new(TOKEN_ID.ENUM, SP.MUST),
		ASD.new(TOKEN_ID.IDENT, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.BRACKET_CURLY_LEFT),
		ASD.new(TOKEN_ID.OPTION, SP.MUST, AR.MAYBE_BEGIN),
		ASD.new(TOKEN_ID.ENUM_OPTION, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.EUQAL),
		ASD.new(TOKEN_ID.LITERAL_BOOL, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.SEMICOLON, SP.MAYBE, AR.MAYBE_END),
		ASD.new(TOKEN_ID.IDENT, SP.MAYBE, AR.ANY_BEGIN, true),
		ASD.new(TOKEN_ID.EUQAL),
		ASD.new(TOKEN_ID.INT, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.SEMICOLON, SP.MAYBE, AR.ANY_END),
		ASD.new(TOKEN_ID.BRACKET_CURLY_RIGHT)
	]
	
	var TEMPLATE_MESSAGE_HEAD : Array = [
		Callable(self, "desc_message_head"),
		ASD.new(TOKEN_ID.MESSAGE, SP.MUST),
		ASD.new(TOKEN_ID.IDENT, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.BRACKET_CURLY_LEFT)
	]
	
	var TEMPLATE_MESSAGE_TAIL : Array = [
		Callable(self, "desc_message_tail"),
		ASD.new(TOKEN_ID.BRACKET_CURLY_RIGHT)
	]
	
	var TEMPLATE_ONEOF_HEAD : Array = [
		Callable(self, "desc_oneof_head"),
		ASD.new(TOKEN_ID.ONEOF, SP.MUST),
		ASD.new(TOKEN_ID.IDENT, SP.MAYBE, AR.MUST_ONE, true),
		ASD.new(TOKEN_ID.BRACKET_CURLY_LEFT),
	]
	
	var TEMPLATE_ONEOF_TAIL : Array = [
		Callable(self, "desc_oneof_tail"),
		ASD.new(TOKEN_ID.BRACKET_CURLY_RIGHT)
	]
	
	var TEMPLATE_BEGIN : Array = [
		null,
		ASD.new(TOKEN_ID.SPACE, SP.NO, AR.MAYBE)
	]
	
	var TEMPLATE_END : Array = [
		null
	]
	
	func get_token_id(tokens : Array, index : int) -> int:
		if index < tokens.size():
			return tokens[index].id
		return TOKEN_ID.UNDEFINED
	
	enum COMPARE_STATE {
		DONE = 0,
		MISMATCH = 1,
		INCOMPLETE = 2,
		ERROR_VALUE = 3
	}

	class TokenCompare:
		func _init(s : int, i : int, d : String = ""):
			state = s
			index = i
			description = d
		var state : int
		var index : int
		var description : String
	
	func check_space(tokens : Array, index : int, space) -> int:
		if get_token_id(tokens, index) == TOKEN_ID.SPACE:
			if space == SP.MAYBE:
				return 1
			elif space == SP.MUST:
				return 1
			elif space == SP.NO:
				return -1
		else:
			if space == SP.MUST:
				return -2
		return 0
	
	class IndexedToken:
		func _init(t : TokenEntrance, i : int):
			token = t
			index = i
		var token : TokenEntrance
		var index : int
	
	func token_importance_checkadd(template : ASD, token : TokenEntrance, index : int, importance : Array) -> void:
		if template.importance:
			importance.append(IndexedToken.new(token, index))
	
	class CompareSettings:
		func _init(ci : int, n : int, pi : int, pn : String = ""):
			construction_index = ci
			nesting = n
			parent_index = pi
			parent_name = pn
			
		var construction_index : int
		var nesting : int
		var parent_index : int
		var parent_name : String
	
	func description_compare(template : Array, tokens : Array, index : int, settings : CompareSettings) -> TokenCompare:
		var j : int = index
		var space : int
		var rule : int
		var rule_flag : bool
		var cont : bool
		var check : int
		var maybe_group_skip : bool = false
		var any_group_index : int = -1
		var any_end_group_index : int = -1
		var i : int = 0
		var importance : Array = []
		while true:
			i += 1
			if i >= template.size():
				break
			rule_flag = false
			cont = false
			rule = template[i].rule
			space = template[i].space
			if rule == AR.MAYBE_END && maybe_group_skip:
				maybe_group_skip = false
				continue
			if maybe_group_skip:
				continue
			if rule == AR.MAYBE:
				if template[i].token == get_token_id(tokens, j):
					token_importance_checkadd(template[i], tokens[j], j, importance)
					rule_flag = true
				else:
					continue
			elif rule == AR.MUST_ONE || rule == AR.MAYBE_END || rule == AR.ANY_END:
				if template[i].token == get_token_id(tokens, j):
					token_importance_checkadd(template[i], tokens[j], j, importance)
					rule_flag = true
			elif rule == AR.ANY:
				var find_any : bool = false
				while true:
					if template[i].token == get_token_id(tokens, j):
						token_importance_checkadd(template[i], tokens[j], j, importance)
						find_any = true
						j += 1
						check = check_space(tokens, j, space)
						if check < 0:
							return TokenCompare.new(COMPARE_STATE.INCOMPLETE, j)
						else:
							j += check
					else:
						if find_any:
							cont = true
						break
			elif rule == AR.OR:
				var or_tokens = template[i].token
				for v in or_tokens:
					if v == get_token_id(tokens, j):
						token_importance_checkadd(template[i], tokens[j], j, importance)
						j += 1
						check = check_space(tokens, j, space)
						if check < 0:
							return TokenCompare.new(COMPARE_STATE.INCOMPLETE, j)
						else:
							j += check
							cont = true
							break
			elif rule == AR.MAYBE_BEGIN:
				if template[i].token == get_token_id(tokens, j):
					token_importance_checkadd(template[i], tokens[j], j, importance)
					rule_flag = true
				else:
					maybe_group_skip = true
					continue
			elif rule == AR.ANY_BEGIN:
				if template[i].token == get_token_id(tokens, j):
					token_importance_checkadd(template[i], tokens[j], j, importance)
					rule_flag = true
					any_group_index = i
				else:
					if any_end_group_index > 0:
						any_group_index = -1
						i = any_end_group_index
						any_end_group_index = -1
						continue
			if cont:
				continue
			if rule_flag:
				j += 1
				check = check_space(tokens, j, space)
				if check < 0:
					return TokenCompare.new(COMPARE_STATE.INCOMPLETE, j)
				else:
					j += check
			else:
				if j > index:
					return TokenCompare.new(COMPARE_STATE.INCOMPLETE, j)
				else:
					return TokenCompare.new(COMPARE_STATE.MISMATCH, j)
			if any_group_index >= 0 && rule == AR.ANY_END:
				any_end_group_index = i
				i = any_group_index - 1
		if template[0] != null:
			var result : DescriptionResult = template[0].call(importance, settings)
			if !result.success:
				return TokenCompare.new(COMPARE_STATE.ERROR_VALUE, result.error, result.description)
		return TokenCompare.new(COMPARE_STATE.DONE, j)
	
	var DESCRIPTION : Array = [
		TEMPLATE_BEGIN,				#0
		TEMPLATE_SYNTAX,			#1
		TEMPLATE_IMPORT,			#2
		TEMPLATE_PACKAGE,			#3
		TEMPLATE_OPTION,			#4
		TEMPLATE_FIELD,				#5
		TEMPLATE_FIELD_ONEOF,		#6
		TEMPLATE_MAP_FIELD,			#7
		TEMPLATE_MAP_FIELD_ONEOF,	#8
		TEMPLATE_ENUM,				#9
		TEMPLATE_MESSAGE_HEAD,		#10
		TEMPLATE_MESSAGE_TAIL,		#11
		TEMPLATE_ONEOF_HEAD,		#12
		TEMPLATE_ONEOF_TAIL,		#13
		TEMPLATE_END				#14
	]
	
	enum JUMP {
		NOTHING = 0,				#nothing
		SIMPLE = 1,					#simple jump
		NESTED_INCREMENT = 2,		#nested increment
		NESTED_DECREMENT = 3,		#nested decrement
		MUST_NESTED_SIMPLE = 4,		#check: must be nested > 0
		MUST_NESTED_INCREMENT = 5,	#check: must be nested > 0, then nested increment
		MUST_NESTED_DECREMENT = 6,	#nested decrement, then check: must be nested > 0
	}
	
	var TRANSLATION_TABLE : Array = [
	#   BEGIN	SYNTAX	IMPORT	PACKAGE	OPTION	FIELD	FIELD_O	MAP_F	MAP_F_O	ENUM	MES_H	MES_T	ONEOF_H	ONEOF_T	END
	[	0, 		1, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0], #BEGIN
	[	0, 		0, 		1, 		1, 		1, 		0, 		0, 		0, 		0, 		1, 		2, 		0, 		0, 		0, 		1], #SYNTAX
	[	0, 		0, 		1, 		1, 		1, 		0, 		0, 		0, 		0, 		1, 		2, 		0, 		0, 		0, 		1], #IMPORT
	[	0, 		0, 		1, 		1, 		1, 		0, 		0, 		0, 		0, 		1, 		2, 		0, 		0, 		0, 		1], #PACKAGE
	[	0, 		0, 		1, 		1, 		1, 		0, 		0, 		0, 		0, 		1, 		2, 		0, 		0, 		0, 		1], #OPTION
	[	0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		1, 		2, 		3, 		5, 		0, 		0], #FIELD
	[	0, 		0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		0, 		0, 		0, 		6, 		0], #FIELD_ONEOF
	[	0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		1, 		2, 		3, 		5, 		0, 		0], #MAP_F
	[	0, 		0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		0, 		0, 		0, 		6, 		0], #MAP_F_ONEOF
	[	0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		1, 		2, 		3, 		5, 		0, 		1], #ENUM
	[	0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		1, 		2, 		3, 		5, 		0, 		0], #MES_H
	[	0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		1, 		2, 		3, 		5, 		0, 		1], #MES_T
	[	0, 		0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		0, 		0, 		0, 		0, 		0], #ONEOF_H
	[	0, 		0, 		0, 		0, 		0, 		4, 		0, 		4, 		0, 		1, 		2, 		3, 		5, 		0, 		1], #ONEOF_T
	[	0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0, 		0]  #END
	]
	
	class Construction:
		func _init(b : int, e : int, d : int):
			begin_token_index = b
			end_token_index = e
			description = d
		var begin_token_index : int
		var end_token_index : int
		var description : int
	
	class TranslationResult:
		var constructions : Array = []
		var done : bool = false
		var error_description_id : int = -1
		var error_description_text : String = ""
		var parse_token_index : int = 0
		var error_token_index : int = 0
	
	func analyze_tokens(tokens : Array) -> TranslationResult:
		var i : int = 0
		var result : TranslationResult = TranslationResult.new()
		var comp : TokenCompare
		var cur_template_id : int = 0
		var error : bool = false
		var template_index : int
		var comp_set : CompareSettings = CompareSettings.new(result.constructions.size(), 0, -1)
		comp = description_compare(DESCRIPTION[cur_template_id], tokens, i, comp_set)
		if comp.state == COMPARE_STATE.DONE:
			i = comp.index
			while true:
				var end : bool = true
				var find : bool = false
				for j in range(TRANSLATION_TABLE[cur_template_id].size()):
					template_index = j
					if j == DESCRIPTION.size() - 1 && i < tokens.size():
						end = false
						if result.error_description_id < 0:
							error = true
						break
					if TRANSLATION_TABLE[cur_template_id][j] > 0:
						end = false
						comp_set.construction_index = result.constructions.size()
						comp = description_compare(DESCRIPTION[j], tokens, i, comp_set)
						if comp.state == COMPARE_STATE.DONE:
							if TRANSLATION_TABLE[cur_template_id][j] == JUMP.NESTED_INCREMENT:
								comp_set.nesting += 1
							elif TRANSLATION_TABLE[cur_template_id][j] == JUMP.NESTED_DECREMENT:
								comp_set.nesting -= 1
								if comp_set.nesting < 0:
									error = true
									break
							elif TRANSLATION_TABLE[cur_template_id][j] == JUMP.MUST_NESTED_SIMPLE:
								if comp_set.nesting <= 0:
									error = true
									break
							elif TRANSLATION_TABLE[cur_template_id][j] == JUMP.MUST_NESTED_INCREMENT:
								if comp_set.nesting <= 0:
									error = true
									break
								comp_set.nesting += 1
							elif TRANSLATION_TABLE[cur_template_id][j] == JUMP.MUST_NESTED_DECREMENT:
								comp_set.nesting -= 1
								if comp_set.nesting <= 0:
									error = true
									break
							result.constructions.append(Construction.new(i, comp.index, j))
							find = true
							i = comp.index
							cur_template_id = j
							if i == tokens.size():
								if TRANSLATION_TABLE[cur_template_id][DESCRIPTION.size() - 1] == JUMP.SIMPLE:
									if comp_set.nesting == 0:
										end = true
									else:
										error = true
								else:
									error = true
							elif i > tokens.size():
								error = true
							break
						elif comp.state == COMPARE_STATE.INCOMPLETE:
							error = true
							break
						elif comp.state == COMPARE_STATE.ERROR_VALUE:
							error = true
							break
				if error:
					result.error_description_text = comp.description
					result.error_description_id = template_index
					result.parse_token_index = i
					if comp.index >= tokens.size():
						result.error_token_index = tokens.size() - 1
					else:
						result.error_token_index = comp.index
				if end:
					result.done = true
					result.error_description_id = -1
					break
				if !find:
					break
		return result
	
	enum CLASS_TYPE {
		ENUM = 0,
		MESSAGE = 1,
		MAP = 2
	}
	
	enum FIELD_TYPE {
		UNDEFINED = -1,
		INT32 = 0,
		SINT32 = 1,
		UINT32 = 2,
		INT64 = 3,
		SINT64 = 4,
		UINT64 = 5,
		BOOL = 6,
		ENUM = 7,
		FIXED32 = 8,
		SFIXED32 = 9,
		FLOAT = 10,
		FIXED64 = 11,
		SFIXED64 = 12,
		DOUBLE = 13,
		STRING = 14,
		BYTES = 15,
		MESSAGE = 16,
		MAP = 17
	}
	
	enum FIELD_QUALIFICATOR {
		OPTIONAL = 0,
		REQUIRED = 1,
		REPEATED = 2,
		RESERVED = 3
	}
	
	enum FIELD_OPTION {
		PACKED = 0,
		NOT_PACKED = 1
	}
	
	class ASTClass:
		func _init(n : String, t : int, p : int, pn : String, o : String, ci : int):
			name = n
			type = t
			parent_index = p
			parent_name = pn
			option = o
			construction_index = ci
			values = []
		
		var name : String
		var type : int
		var parent_index : int
		var parent_name : String
		var option : String
		var construction_index
		var values : Array
		
		func copy() -> ASTClass:
			var res : ASTClass = ASTClass.new(name, type, parent_index, parent_name, option, construction_index)
			for v in values:
				res.values.append(v.copy())
			return res
	
	class ASTEnumValue:
		func _init(n : String, v : String):
			name = n
			value = v
		
		var name : String
		var value : String
		
		func copy() -> ASTEnumValue:
			return ASTEnumValue.new(name, value)
	
	class ASTField:
		func _init(t, n : String, tn : String, p : int, q : int, o : int, ci : int, mf : bool):
			tag = t
			name = n
			type_name = tn
			parent_class_id = p
			qualificator = q
			option = o
			construction_index = ci
			is_map_field = mf
		
		var tag
		var name : String
		var type_name : String
		var parent_class_id : int
		var qualificator : int
		var option : int
		var construction_index : int
		var is_map_field : bool
		var field_type : int = FIELD_TYPE.UNDEFINED
		var type_class_id : int = -1
		
		func copy() -> ASTField:
			var res : ASTField = ASTField.new(tag, name, type_name, parent_class_id, qualificator, option, construction_index, is_map_field)
			res.field_type = field_type
			res.type_class_id = type_class_id
			return res
	
	enum AST_GROUP_RULE {
		ONEOF = 0,
		ALL = 1
	}
	
	class ASTFieldGroup:
		func _init(n : String, pi : int, r : int):
			name = n
			parent_class_id = pi
			rule = r
			opened = true
			
		var name : String
		var parent_class_id : int
		var rule : int
		var field_indexes : Array = []
		var opened : bool
		
		func copy() -> ASTFieldGroup:
			var res : ASTFieldGroup = ASTFieldGroup.new(name, parent_class_id, rule)
			res.opened = opened
			for fi in field_indexes:
				res.field_indexes.append(fi)
			return res
	
	class ASTImport:
		func _init(a_path : String, a_public : bool, sha : String):
			path = a_path
			public = a_public
			sha256 = sha
			
		var path : String
		var public : bool
		var sha256 : String
	
	var class_table : Array = []
	var field_table : Array = []
	var group_table : Array = []
	var import_table : Array = []
	var proto_version : int = 0
	
	class DescriptionResult:
		func _init(s : bool = true, e = null, d : String = ""):
			success = s
			error = e
			description = d
		var success : bool
		var error
		var description : String
	
	static func get_text_from_token(string_token : TokenEntrance) -> String:
		return string_token.text.substr(1, string_token.text.length() - 2)
	
	func desc_syntax(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		var result : DescriptionResult = DescriptionResult.new()
		var s : String = get_text_from_token(indexed_tokens[0].token)
		if s == "proto2":
			proto_version = 2
		elif s == "proto3":
			proto_version = 3
		else:
			result.success = false
			result.error = indexed_tokens[0].index
			result.description = "Unspecified version of the protocol. Use \"proto2\" or \"proto3\" syntax string."
		return result
		
	func desc_import(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		var result : DescriptionResult = DescriptionResult.new()
		var offset : int = 0
		var public : bool = false
		if indexed_tokens[offset].token.id == TOKEN_ID.IMPORT_QUALIFICATION:
			if indexed_tokens[offset].token.text == "public":
				public = true
			offset += 1
		var f_name : String = path_dir + get_text_from_token(indexed_tokens[offset].token)
		var sha : String = FileAccess.get_sha256(f_name)
		if FileAccess.file_exists(f_name):
			for i in import_table:
				if i.path == f_name:
					result.success = false
					result.error = indexed_tokens[offset].index
					result.description = "File '" + f_name + "' already imported."
					return result
				if i.sha256 == sha:
					result.success = false
					result.error = indexed_tokens[offset].index
					result.description = "File '" + f_name + "' with matching SHA256 already imported."
					return result
			import_table.append(ASTImport.new(f_name, public, sha))
		else:
			result.success = false
			result.error = indexed_tokens[offset].index
			result.description = "Import file '" + f_name + "' not found."
		return result
		
	func desc_package(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		printerr("UNRELEASED desc_package: ", indexed_tokens.size(), ", nesting: ", settings.nesting)
		var result : DescriptionResult = DescriptionResult.new()
		return result
		
	func desc_option(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		printerr("UNRELEASED desc_option: ", indexed_tokens.size(), ", nesting: ", settings.nesting)
		var result : DescriptionResult = DescriptionResult.new()
		return result
	
	func desc_field(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		var result : DescriptionResult = DescriptionResult.new()
		var qualifcator : int = FIELD_QUALIFICATOR.OPTIONAL
		var option : int
		var offset : int = 0
		
		if proto_version == 3:
			option = FIELD_OPTION.PACKED
			if indexed_tokens[offset].token.id == TOKEN_ID.FIELD_QUALIFICATION:
				if indexed_tokens[offset].token.text == "repeated":
					qualifcator = FIELD_QUALIFICATOR.REPEATED
				elif indexed_tokens[offset].token.text == "required" || indexed_tokens[offset].token.text == "optional":
					result.success = false
					result.error = indexed_tokens[offset].index
					result.description = "Using the 'required' or 'optional' qualificator is unacceptable in Protobuf v3."
					return result
				offset += 1
		if proto_version == 2:
			option = FIELD_OPTION.NOT_PACKED
			if !(group_table.size() > 0 && group_table[group_table.size() - 1].opened):
				if indexed_tokens[offset].token.id == TOKEN_ID.FIELD_QUALIFICATION:
					if indexed_tokens[offset].token.text == "repeated":
						qualifcator = FIELD_QUALIFICATOR.REPEATED
					elif indexed_tokens[offset].token.text == "required":
						qualifcator = FIELD_QUALIFICATOR.REQUIRED
					elif indexed_tokens[offset].token.text == "optional":
						qualifcator = FIELD_QUALIFICATOR.OPTIONAL
					offset += 1
				else:
					if class_table[settings.parent_index].type == CLASS_TYPE.MESSAGE:
						result.success = false
						result.error = indexed_tokens[offset].index
						result.description = "Using the 'required', 'optional' or 'repeated' qualificator necessarily in Protobuf v2."
						return result
		var type_name : String = indexed_tokens[offset].token.text; offset += 1
		var field_name : String = indexed_tokens[offset].token.text; offset += 1
		var tag : String = indexed_tokens[offset].token.text; offset += 1
		
		if indexed_tokens.size() == offset + 2:
			if indexed_tokens[offset].token.text == "packed":
				offset += 1
				if indexed_tokens[offset].token.text == "true":
					option = FIELD_OPTION.PACKED
				else:
					option = FIELD_OPTION.NOT_PACKED
			else:
				result.success = false
				result.error = indexed_tokens[offset].index
				result.description = "Undefined field option."
				return result
				
		if group_table.size() > 0:
			if group_table[group_table.size() - 1].opened:
				if indexed_tokens[0].token.id == TOKEN_ID.FIELD_QUALIFICATION:
					result.success = false
					result.error = indexed_tokens[0].index
					result.description = "Using the 'required', 'optional' or 'repeated' qualificator is unacceptable in 'OneOf' field."
					return result
				group_table[group_table.size() - 1].field_indexes.append(field_table.size())
		field_table.append(ASTField.new(tag, field_name, type_name, settings.parent_index, qualifcator, option, settings.construction_index, false))
		return result
	
	func desc_map_field(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		var result : DescriptionResult = DescriptionResult.new()
		var qualifcator : int = FIELD_QUALIFICATOR.REPEATED
		var option : int
		var offset : int = 0
		
		if proto_version == 3:
			option = FIELD_OPTION.PACKED
		if proto_version == 2:
			option = FIELD_OPTION.NOT_PACKED
			
		var key_type_name : String = indexed_tokens[offset].token.text; offset += 1
		if key_type_name == "float" || key_type_name == "double" || key_type_name == "bytes":
			result.success = false
			result.error = indexed_tokens[offset - 1].index
			result.description = "Map 'key_type' can't be floating point types and bytes."
		var type_name : String  = indexed_tokens[offset].token.text; offset += 1
		var field_name : String  = indexed_tokens[offset].token.text; offset += 1
		var tag : String = indexed_tokens[offset].token.text; offset += 1
		
		if indexed_tokens.size() == offset + 2:
			if indexed_tokens[offset].token.text == "packed":
				offset += 1
				if indexed_tokens[offset] == "true":
					option = FIELD_OPTION.PACKED
				else:
					option = FIELD_OPTION.NOT_PACKED
			else:
				result.success = false
				result.error = indexed_tokens[offset].index
				result.description = "Undefined field option."
		
		if group_table.size() > 0:
			if group_table[group_table.size() - 1].opened:
				group_table[group_table.size() - 1].field_indexes.append(field_table.size())
				
		class_table.append(ASTClass.new("map_type_" + field_name, CLASS_TYPE.MAP, settings.parent_index, settings.parent_name, "", settings.construction_index))
		field_table.append(ASTField.new(tag, field_name, "map_type_" + field_name, settings.parent_index, qualifcator, option, settings.construction_index, false))
		
		field_table.append(ASTField.new(1, "key", key_type_name, class_table.size() - 1, FIELD_QUALIFICATOR.REQUIRED, option, settings.construction_index, true))
		field_table.append(ASTField.new(2, "value", type_name, class_table.size() - 1, FIELD_QUALIFICATOR.REQUIRED, option, settings.construction_index, true))
		
		return result
	
	func desc_enum(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		var result : DescriptionResult = DescriptionResult.new()
		var option : String = ""
		var offset : int = 0
		var type_name : String = indexed_tokens[offset].token.text; offset += 1
		if indexed_tokens[offset].token.id == TOKEN_ID.ENUM_OPTION:
			if indexed_tokens[offset].token.text == "allow_alias" && indexed_tokens[offset + 1].token.text == "true":
				option = "allow_alias"
			offset += 2
		var value : ASTEnumValue
		var enum_class : ASTClass = ASTClass.new(type_name, CLASS_TYPE.ENUM, settings.parent_index, settings.parent_name, option, settings.construction_index)
		var first_value : bool = true
		while offset < indexed_tokens.size():
			if first_value:
				if indexed_tokens[offset + 1].token.text != "0":
					result.success = false
					result.error = indexed_tokens[offset + 1].index
					result.description = "For Enums, the default value is the first defined enum value, which must be 0."
					break
				first_value = false
			#if indexed_tokens[offset + 1].token.text[0] == "+" || indexed_tokens[offset + 1].token.text[0] == "-":
			#	result.success = false
			#	result.error = indexed_tokens[offset + 1].index
			#	result.description = "For Enums, signed values are not allowed."
			#	break
			value = ASTEnumValue.new(indexed_tokens[offset].token.text, indexed_tokens[offset + 1].token.text)
			enum_class.values.append(value)
			offset += 2
		
		class_table.append(enum_class)
		return result
		
	func desc_message_head(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		var result : DescriptionResult = DescriptionResult.new()
		class_table.append(ASTClass.new(indexed_tokens[0].token.text, CLASS_TYPE.MESSAGE, settings.parent_index, settings.parent_name, "", settings.construction_index))
		settings.parent_index = class_table.size() - 1
		settings.parent_name = settings.parent_name + "." + indexed_tokens[0].token.text
		return result
		
	func desc_message_tail(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		settings.parent_index = class_table[settings.parent_index].parent_index
		settings.parent_name = class_table[settings.parent_index + 1].parent_name
		var result : DescriptionResult = DescriptionResult.new()
		return result
	
	func desc_oneof_head(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		var result : DescriptionResult = DescriptionResult.new()
		for g in group_table:
			if g.parent_class_id == settings.parent_index && g.name == indexed_tokens[0].token.text:
				result.success = false
				result.error = indexed_tokens[0].index
				result.description = "OneOf name must be unique."
				return result
		group_table.append(ASTFieldGroup.new(indexed_tokens[0].token.text, settings.parent_index, AST_GROUP_RULE.ONEOF))
		return result
		
	func desc_oneof_tail(indexed_tokens : Array, settings : CompareSettings) -> DescriptionResult:
		group_table[group_table.size() - 1].opened = false
		var result : DescriptionResult = DescriptionResult.new()
		return result
		
	func analyze() -> AnalyzeResult:
		var analyze_result : AnalyzeResult = AnalyzeResult.new()
		analyze_result.doc = document
		analyze_result.classes = class_table
		analyze_result.fields = field_table
		analyze_result.groups = group_table
		analyze_result.state = false
		var result : TokenResult = tokenizer()
		if result.errors.size() > 0:
			for v in result.errors:
				var spos : Helper.StringPosition = Helper.str_pos(document.text, v.position)
				var err_text : String = "Unexpected token intersection " + "'" + document.text.substr(v.position.begin, spos.length) + "'"
				printerr(Helper.error_string(document.name, spos.str_num, spos.column, err_text))
		else:
			var integrity = check_tokens_integrity(result.tokens, document.text.length() - 1)
			if integrity.size() > 0:
				for v in integrity:
					var spos: Helper.StringPosition = Helper.str_pos(document.text, TokenPosition.new(v.begin, v.end))
					var err_text : String = "Unexpected token " + "'" + document.text.substr(v.begin, spos.length) + "'"
					printerr(Helper.error_string(document.name, spos.str_num, spos.column, err_text))
			else:
				analyze_result.tokens = result.tokens
				comment_space_processing(result.tokens)
				var syntax : TranslationResult = analyze_tokens(result.tokens)
				if !syntax.done:
					var pos_main : TokenPosition = Helper.text_pos(result.tokens, syntax.parse_token_index)
					var pos_inner : TokenPosition = Helper.text_pos(result.tokens, syntax.error_token_index)
					var spos_main : Helper.StringPosition = Helper.str_pos(document.text, pos_main)
					var spos_inner : Helper.StringPosition = Helper.str_pos(document.text, pos_inner)
					var err_text : String = "Syntax error in construction '" + result.tokens[syntax.parse_token_index].text + "'. "
					err_text += "Unacceptable use '" + result.tokens[syntax.error_token_index].text + "' at:" + str(spos_inner.str_num) + ":" + str(spos_inner.column)
					err_text += "\n" + syntax.error_description_text
					printerr(Helper.error_string(document.name, spos_main.str_num, spos_main.column, err_text))
				else:
					analyze_result.version = proto_version
					analyze_result.imports = import_table
					analyze_result.syntax = syntax
					analyze_result.state = true
		return analyze_result

class Semantic:
	
	var class_table : Array
	var field_table : Array
	var group_table : Array
	var syntax : Analysis.TranslationResult
	var tokens : Array
	var document : Document
	
	func _init(analyze_result : AnalyzeResult):
		class_table = analyze_result.classes
		field_table = analyze_result.fields
		group_table = analyze_result.groups
		syntax = analyze_result.syntax
		tokens = analyze_result.tokens
		document = analyze_result.doc
		
	
	enum CHECK_SUBJECT {
		CLASS_NAME = 0,
		FIELD_NAME = 1,
		FIELD_TAG_NUMBER = 2,
		FIELD_TYPE = 3
	}
	
	var STRING_FIELD_TYPE = {
		"int32": Analysis.FIELD_TYPE.INT32,
		"sint32": Analysis.FIELD_TYPE.SINT32,
		"uint32": Analysis.FIELD_TYPE.UINT32,
		"int64": Analysis.FIELD_TYPE.INT64,
		"sint64": Analysis.FIELD_TYPE.SINT64,
		"uint64": Analysis.FIELD_TYPE.UINT64,
		"bool": Analysis.FIELD_TYPE.BOOL,
		"fixed32": Analysis.FIELD_TYPE.FIXED32,
		"sfixed32": Analysis.FIELD_TYPE.SFIXED32,
		"float": Analysis.FIELD_TYPE.FLOAT,
		"fixed64": Analysis.FIELD_TYPE.FIXED64,
		"sfixed64": Analysis.FIELD_TYPE.SFIXED64,
		"double": Analysis.FIELD_TYPE.DOUBLE,
		"string": Analysis.FIELD_TYPE.STRING,
		"bytes": Analysis.FIELD_TYPE.BYTES,
		"map": Analysis.FIELD_TYPE.MAP
	}
	
	class CheckResult:
		func _init(mci : int, aci : int, ti : int, s : int):
			main_construction_index = mci
			associated_construction_index = aci
			table_index = ti
			subject = s
			
		var main_construction_index: int = -1
		var associated_construction_index: int = -1
		var table_index: int = -1
		var subject : int
	
	func check_class_names() -> Array:
		var result : Array = []
		for i in range(class_table.size()):
			var the_class_name : String = class_table[i].parent_name + "." + class_table[i].name
			for j in range(i + 1, class_table.size(), 1):
				var inner_name : String = class_table[j].parent_name + "." + class_table[j].name
				if inner_name == the_class_name:
					var check : CheckResult = CheckResult.new(class_table[j].construction_index, class_table[i].construction_index, j, CHECK_SUBJECT.CLASS_NAME)
					result.append(check)
					break
		return result
	
	func check_field_names() -> Array:
		var result : Array = []
		for i in range(field_table.size()):
			var the_class_name : String = class_table[field_table[i].parent_class_id].parent_name + "." + class_table[field_table[i].parent_class_id].name
			for j in range(i + 1, field_table.size(), 1):
				var inner_name : String = class_table[field_table[j].parent_class_id].parent_name + "." + class_table[field_table[j].parent_class_id].name
				if inner_name == the_class_name:
					if field_table[i].name == field_table[j].name:
						var check : CheckResult = CheckResult.new(field_table[j].construction_index, field_table[i].construction_index, j, CHECK_SUBJECT.FIELD_NAME)
						result.append(check)
						break
					if field_table[i].tag == field_table[j].tag:
						var check : CheckResult = CheckResult.new(field_table[j].construction_index, field_table[i].construction_index, j, CHECK_SUBJECT.FIELD_TAG_NUMBER)
						result.append(check)
						break
		return result
	
	func find_full_class_name(the_class_name : String) -> int:
		for i in range(class_table.size()):
			if the_class_name == class_table[i].parent_name + "." + class_table[i].name:
				return i
		return -1
	
	func find_class_name(the_class_name : String) -> int:
		for i in range(class_table.size()):
			if the_class_name == class_table[i].name:
				return i
		return -1
	
	func get_class_childs(class_index : int) -> Array:
		var result : Array = []
		for i in range(class_table.size()):
			if class_table[i].parent_index == class_index:
				result.append(i)
		return result
	
	func find_in_childs(the_class_name : String, child_indexes : Array) -> int:
		for c in child_indexes:
			if the_class_name == class_table[c].name:
				return c
		return -1
	
	func determine_field_types() -> Array:
		var result : Array = []
		for f in field_table:
			if STRING_FIELD_TYPE.has(f.type_name):
				f.field_type = STRING_FIELD_TYPE[f.type_name]
			else:
				if f.type_name[0] == ".":
					f.type_class_id = find_full_class_name(f.type_name)
				else:
					var splited_name : Array = f.type_name.split(".", false)
					var cur_class_index : int = f.parent_class_id
					var exit : bool = false
					while(true):
						var find : bool = false
						if cur_class_index == -1:
							break
						for n in splited_name:
							var childs_and_parent : Array = get_class_childs(cur_class_index)
							var res_index : int = find_in_childs(n, childs_and_parent)
							if res_index >= 0:
								find = true
								cur_class_index = res_index
							else:
								if find:
									exit = true
								else:
									cur_class_index = class_table[cur_class_index].parent_index
								break
						if exit:
							break
						if find:
							f.type_class_id = cur_class_index
							break
				if f.type_class_id == -1:
					f.type_class_id = find_full_class_name("." + f.type_name)
		for i in range(field_table.size()):
			if field_table[i].field_type == Analysis.FIELD_TYPE.UNDEFINED:
				if field_table[i].type_class_id == -1:
					result.append(CheckResult.new(field_table[i].construction_index, field_table[i].construction_index, i, CHECK_SUBJECT.FIELD_TYPE))
				else:
					if class_table[field_table[i].type_class_id].type == Analysis.CLASS_TYPE.ENUM:
						field_table[i].field_type = Analysis.FIELD_TYPE.ENUM
					elif class_table[field_table[i].type_class_id].type == Analysis.CLASS_TYPE.MESSAGE:
						field_table[i].field_type = Analysis.FIELD_TYPE.MESSAGE
					elif class_table[field_table[i].type_class_id].type == Analysis.CLASS_TYPE.MAP:
						field_table[i].field_type = Analysis.FIELD_TYPE.MAP
					else:
						result.append(CheckResult.new(field_table[i].construction_index, field_table[i].construction_index, i, CHECK_SUBJECT.FIELD_TYPE))
		return result
	
	func check_constructions() -> Array:
		var cl : Array = check_class_names()
		var fl : Array = check_field_names()
		var ft : Array = determine_field_types()
		return cl + fl + ft
		
	func check() -> bool:
		var check_result : Array = check_constructions()
		if check_result.size() == 0:
			return true
		else:
			for v in check_result:
				var main_tok : int = syntax.constructions[v.main_construction_index].begin_token_index
				var assoc_tok : int = syntax.constructions[v.associated_construction_index].begin_token_index
				var main_err_pos : Helper.StringPosition = Helper.str_pos(document.text, Helper.text_pos(tokens, main_tok))
				var assoc_err_pos : Helper.StringPosition = Helper.str_pos(document.text, Helper.text_pos(tokens, assoc_tok))
				var err_text : String
				if v.subject == CHECK_SUBJECT.CLASS_NAME:
					var class_type = "Undefined"
					if class_table[v.table_index].type == Analysis.CLASS_TYPE.ENUM:
						class_type = "Enum"
					elif class_table[v.table_index].type == Analysis.CLASS_TYPE.MESSAGE:
						class_type = "Message"
					elif class_table[v.table_index].type == Analysis.CLASS_TYPE.MAP:
						class_type = "Map"
					err_text = class_type + " name '" + class_table[v.table_index].name + "' is already defined at:" + str(assoc_err_pos.str_num) + ":" + str(assoc_err_pos.column)
				elif v.subject == CHECK_SUBJECT.FIELD_NAME:
					err_text = "Field name '" + field_table[v.table_index].name + "' is already defined at:" + str(assoc_err_pos.str_num) + ":" + str(assoc_err_pos.column)
				elif v.subject == CHECK_SUBJECT.FIELD_TAG_NUMBER:
					err_text = "Tag number '" + field_table[v.table_index].tag + "' is already defined at:" + str(assoc_err_pos.str_num) + ":" + str(assoc_err_pos.column)
				elif v.subject == CHECK_SUBJECT.FIELD_TYPE:
					err_text = "Type '" + field_table[v.table_index].type_name + "' of the '" + field_table[v.table_index].name + "' field undefined"
				else:
					err_text = "Undefined error"
				printerr(Helper.error_string(document.name, main_err_pos.str_num, main_err_pos.column, err_text))
		return false

class Translator:
	
	var class_table : Array
	var field_table : Array
	var group_table : Array
	var proto_version : int
	
	func _init(analyzer_result : AnalyzeResult):
		class_table = analyzer_result.classes
		field_table = analyzer_result.fields
		group_table = analyzer_result.groups
		proto_version = analyzer_result.version
	
	func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for i in range(nesting):
			tab += "\t"
		return tab + text
	
	func default_dict_text() -> String:
		if proto_version == 2:
			return "DEFAULT_VALUES_2"
		elif proto_version == 3:
			return "DEFAULT_VALUES_3"
		return "TRANSLATION_ERROR"
	
	func generate_field_type(field : Analysis.ASTField) -> String:
		var text : String = "PB_DATA_TYPE."
		if field.field_type == Analysis.FIELD_TYPE.INT32:
			return text + "INT32"
		elif field.field_type == Analysis.FIELD_TYPE.SINT32:
			return text + "SINT32"
		elif field.field_type == Analysis.FIELD_TYPE.UINT32:
			return text + "UINT32"
		elif field.field_type == Analysis.FIELD_TYPE.INT64:
			return text + "INT64"
		elif field.field_type == Analysis.FIELD_TYPE.SINT64:
			return text + "SINT64"
		elif field.field_type == Analysis.FIELD_TYPE.UINT64:
			return text + "UINT64"
		elif field.field_type == Analysis.FIELD_TYPE.BOOL:
			return text + "BOOL"
		elif field.field_type == Analysis.FIELD_TYPE.ENUM:
			return text + "ENUM"
		elif field.field_type == Analysis.FIELD_TYPE.FIXED32:
			return text + "FIXED32"
		elif field.field_type == Analysis.FIELD_TYPE.SFIXED32:
			return text + "SFIXED32"
		elif field.field_type == Analysis.FIELD_TYPE.FLOAT:
			return text + "FLOAT"
		elif field.field_type == Analysis.FIELD_TYPE.FIXED64:
			return text + "FIXED64"
		elif field.field_type == Analysis.FIELD_TYPE.SFIXED64:
			return text + "SFIXED64"
		elif field.field_type == Analysis.FIELD_TYPE.DOUBLE:
			return text + "DOUBLE"
		elif field.field_type == Analysis.FIELD_TYPE.STRING:
			return text + "STRING"
		elif field.field_type == Analysis.FIELD_TYPE.BYTES:
			return text + "BYTES"
		elif field.field_type == Analysis.FIELD_TYPE.MESSAGE:
			return text + "MESSAGE"
		elif field.field_type == Analysis.FIELD_TYPE.MAP:
			return text + "MAP"
		return text
	
	func generate_field_rule(field : Analysis.ASTField) -> String:
		var text : String = "PB_RULE."
		if field.qualificator == Analysis.FIELD_QUALIFICATOR.OPTIONAL:
			return text + "OPTIONAL"
		elif field.qualificator == Analysis.FIELD_QUALIFICATOR.REQUIRED:
			return text + "REQUIRED"
		elif field.qualificator == Analysis.FIELD_QUALIFICATOR.REPEATED:
			return text + "REPEATED"
		elif field.qualificator == Analysis.FIELD_QUALIFICATOR.RESERVED:
			return text + "RESERVED"
		return text
	
	func generate_gdscript_simple_type(field : Analysis.ASTField) -> String:
		if field.field_type == Analysis.FIELD_TYPE.INT32:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.SINT32:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.UINT32:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.INT64:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.SINT64:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.UINT64:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.BOOL:
			return "bool"
		elif field.field_type == Analysis.FIELD_TYPE.ENUM:
			return ""
		elif field.field_type == Analysis.FIELD_TYPE.FIXED32:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.SFIXED32:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.FLOAT:
			return "float"
		elif field.field_type == Analysis.FIELD_TYPE.FIXED64:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.SFIXED64:
			return "int"
		elif field.field_type == Analysis.FIELD_TYPE.DOUBLE:
			return "float"
		elif field.field_type == Analysis.FIELD_TYPE.STRING:
			return "String"
		elif field.field_type == Analysis.FIELD_TYPE.BYTES:
			return "PackedByteArray"
		return ""
	
	func generate_field_constructor(field_index : int, nesting : int) -> String:
		var text : String = ""
		var f : Analysis.ASTField = field_table[field_index]
		var field_name : String = "_" + f.name
		var pbfield_text : String = field_name + " = PBField.new("
		pbfield_text += "\"" + f.name + "\", "
		pbfield_text += generate_field_type(f) + ", "
		pbfield_text += generate_field_rule(f) + ", "
		pbfield_text += str(f.tag) + ", "
		if f.option == Analysis.FIELD_OPTION.PACKED:
			pbfield_text += "true"
		elif f.option == Analysis.FIELD_OPTION.NOT_PACKED:
			pbfield_text += "false"
		if f.qualificator == Analysis.FIELD_QUALIFICATOR.REPEATED:
			pbfield_text += ", []"
		else:
			pbfield_text += ", " + default_dict_text() + "[" + generate_field_type(f) + "]"
		pbfield_text += ")\n"
		text += tabulate(pbfield_text, nesting)
		if f.is_map_field:
			text += tabulate(field_name + ".is_map_field = true\n", nesting)
		text += tabulate("service = PBServiceField.new()\n", nesting)
		text += tabulate("service.field = " + field_name + "\n", nesting)
		if f.field_type == Analysis.FIELD_TYPE.MESSAGE:
			if f.qualificator == Analysis.FIELD_QUALIFICATOR.REPEATED:
				text += tabulate("service.func_ref = Callable(self, \"add" + field_name + "\")\n", nesting)
			else:
				text += tabulate("service.func_ref = Callable(self, \"new" + field_name + "\")\n", nesting)
		elif f.field_type == Analysis.FIELD_TYPE.MAP:
			text += tabulate("service.func_ref = Callable(self, \"add_empty" + field_name + "\")\n", nesting)
		text += tabulate("data[" + field_name + ".tag] = service\n", nesting)
		
		return text
	
	func generate_group_clear(field_index : int, nesting : int) -> String:
		for g in group_table:
			var text : String = ""
			var find : bool = false
			if g.parent_class_id == field_table[field_index].parent_class_id:
				for i in g.field_indexes:
					if field_index == i:
						find = true
						text += tabulate("data[" + field_table[i].tag + "].state = PB_SERVICE_STATE.FILLED\n", nesting)
					else:
						text += tabulate("_" + field_table[i].name + ".value = " + default_dict_text() + "[" + generate_field_type(field_table[i]) + "]\n", nesting)
						text += tabulate("data[" + field_table[i].tag + "].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
			if find:
				return text
		return ""
	
	func generate_has_oneof(field_index : int, nesting : int) -> String:
		for g in group_table:
			var text : String = ""
			if g.parent_class_id == field_table[field_index].parent_class_id:
				for i in g.field_indexes:
					if field_index == i:
						text += tabulate("func has_" + field_table[i].name + "() -> bool:\n", nesting)
						nesting += 1
						text += tabulate("return data[" + field_table[i].tag + "].state == PB_SERVICE_STATE.FILLED\n", nesting)
						return text
		return ""
	
	func generate_field(field_index : int, nesting : int) -> String:
		var text : String = ""
		var f : Analysis.ASTField = field_table[field_index]
		text += tabulate("var _" + f.name + ": PBField\n", nesting)
		if f.field_type == Analysis.FIELD_TYPE.MESSAGE:
			var the_class_name : String = class_table[f.type_class_id].parent_name + "." + class_table[f.type_class_id].name
			the_class_name = the_class_name.substr(1, the_class_name.length() - 1)
			text += generate_has_oneof(field_index, nesting)
			if f.qualificator == Analysis.FIELD_QUALIFICATOR.REPEATED:
				text += tabulate("func get_" + f.name + "() -> Array:\n", nesting)
			else:
				text += tabulate("func get_" + f.name + "() -> " + the_class_name + ":\n", nesting)
			nesting += 1
			text += tabulate("return _" + f.name + ".value\n", nesting)
			nesting -= 1
			text += tabulate("func clear_" + f.name + "() -> void:\n", nesting)
			nesting += 1
			text += tabulate("data[" + str(f.tag) + "].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
			if f.qualificator == Analysis.FIELD_QUALIFICATOR.REPEATED:
				text += tabulate("_" + f.name + ".value = []\n", nesting)
				nesting -= 1
				text += tabulate("func add_" + f.name + "() -> " + the_class_name + ":\n", nesting)
				nesting += 1
				text += tabulate("var element = " + the_class_name + ".new()\n", nesting)
				text += tabulate("_" + f.name + ".value.append(element)\n", nesting)
				text += tabulate("return element\n", nesting)
			else:
				text += tabulate("_" + f.name + ".value = " + default_dict_text() + "[" + generate_field_type(f) + "]\n", nesting)
				nesting -= 1
				text += tabulate("func new_" + f.name + "() -> " + the_class_name + ":\n", nesting)
				nesting += 1
				text += generate_group_clear(field_index, nesting)
				text += tabulate("_" + f.name + ".value = " + the_class_name + ".new()\n", nesting)
				text += tabulate("return _" + f.name + ".value\n", nesting)
		elif f.field_type == Analysis.FIELD_TYPE.MAP:
			var the_parent_class_name : String = class_table[f.type_class_id].parent_name
			the_parent_class_name = the_parent_class_name.substr(1, the_parent_class_name.length() - 1)
			var the_class_name : String = the_parent_class_name + "." + class_table[f.type_class_id].name
			
			text += generate_has_oneof(field_index, nesting)
			text += tabulate("func get_raw_" + f.name + "():\n", nesting)
			nesting += 1
			text += tabulate("return _" + f.name + ".value\n", nesting)
			nesting -= 1
			text += tabulate("func get_" + f.name + "():\n", nesting)
			nesting += 1
			text += tabulate("return PBPacker.construct_map(_" + f.name + ".value)\n", nesting)
			nesting -= 1
			text += tabulate("func clear_" + f.name + "():\n", nesting)
			nesting += 1
			text += tabulate("data[" + str(f.tag) + "].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
			text += tabulate("_" + f.name + ".value = " + default_dict_text() + "[" + generate_field_type(f) + "]\n", nesting)
			nesting -= 1
			for i in range(field_table.size()):
				if field_table[i].parent_class_id == f.type_class_id && field_table[i].name == "value":
					var gd_type : String = generate_gdscript_simple_type(field_table[i])
					var return_type : String = " -> " + the_class_name
					var value_return_type : String = ""
					if gd_type != "":
						value_return_type = return_type
					elif field_table[i].field_type == Analysis.FIELD_TYPE.MESSAGE:
						value_return_type = " -> " + the_parent_class_name + "." + field_table[i].type_name
					text += tabulate("func add_empty_" + f.name + "()" + return_type + ":\n", nesting)
					nesting += 1
					text += generate_group_clear(field_index, nesting)
					text += tabulate("var element = " + the_class_name + ".new()\n", nesting)
					text += tabulate("_" + f.name + ".value.append(element)\n", nesting)
					text += tabulate("return element\n", nesting)
					nesting -= 1
					if field_table[i].field_type == Analysis.FIELD_TYPE.MESSAGE:
						text += tabulate("func add_" + f.name + "(a_key)" + value_return_type + ":\n", nesting)
						nesting += 1
						text += generate_group_clear(field_index, nesting)
						text += tabulate("var idx = -1\n", nesting)
						text += tabulate("for i in range(_" + f.name + ".value.size()):\n", nesting)
						nesting += 1
						text += tabulate("if _" + f.name + ".value[i].get_key() == a_key:\n", nesting)
						nesting += 1
						text += tabulate("idx = i\n", nesting)
						text += tabulate("break\n", nesting)
						nesting -= 2
						text += tabulate("var element = " + the_class_name + ".new()\n", nesting)
						text += tabulate("element.set_key(a_key)\n", nesting)
						text += tabulate("if idx != -1:\n", nesting)
						nesting += 1
						text += tabulate("_" + f.name + ".value[idx] = element\n", nesting)
						nesting -= 1
						text += tabulate("else:\n", nesting)
						nesting += 1
						text += tabulate("_" + f.name + ".value.append(element)\n", nesting)
						nesting -= 1
						text += tabulate("return element.new_value()\n", nesting)
					else:
						text += tabulate("func add_" + f.name + "(a_key, a_value) -> void:\n", nesting)
						nesting += 1
						text += generate_group_clear(field_index, nesting)
						text += tabulate("var idx = -1\n", nesting)
						text += tabulate("for i in range(_" + f.name + ".value.size()):\n", nesting)
						nesting += 1
						text += tabulate("if _" + f.name + ".value[i].get_key() == a_key:\n", nesting)
						nesting += 1
						text += tabulate("idx = i\n", nesting)
						text += tabulate("break\n", nesting)
						nesting -= 2
						text += tabulate("var element = " + the_class_name + ".new()\n", nesting)
						text += tabulate("element.set_key(a_key)\n", nesting)
						text += tabulate("element.set_value(a_value)\n", nesting)
						text += tabulate("if idx != -1:\n", nesting)
						nesting += 1
						text += tabulate("_" + f.name + ".value[idx] = element\n", nesting)
						nesting -= 1
						text += tabulate("else:\n", nesting)
						nesting += 1
						text += tabulate("_" + f.name + ".value.append(element)\n", nesting)
						nesting -= 1
					break
		else:
			var gd_type : String = generate_gdscript_simple_type(f)
			var return_type : String = ""
			var argument_type : String = ""
			if gd_type != "":
				return_type = " -> " + gd_type
				argument_type = " : " + gd_type
			text += generate_has_oneof(field_index, nesting)
			if f.qualificator == Analysis.FIELD_QUALIFICATOR.REPEATED:
				text += tabulate("func get_" + f.name + "() -> Array:\n", nesting)
			else:
				text += tabulate("func get_" + f.name + "()" + return_type + ":\n", nesting)
			nesting += 1
			text += tabulate("return _" + f.name + ".value\n", nesting)
			nesting -= 1
			text += tabulate("func clear_" + f.name + "() -> void:\n", nesting)
			nesting += 1
			text += tabulate("data[" + str(f.tag) + "].state = PB_SERVICE_STATE.UNFILLED\n", nesting)
			if f.qualificator == Analysis.FIELD_QUALIFICATOR.REPEATED:
				text += tabulate("_" + f.name + ".value = []\n", nesting)
				nesting -= 1
				text += tabulate("func add_" + f.name + "(value" + argument_type + ") -> void:\n", nesting)
				nesting += 1
				text += tabulate("_" + f.name + ".value.append(value)\n", nesting)
			else:
				text += tabulate("_" + f.name + ".value = " + default_dict_text() + "[" + generate_field_type(f) + "]\n", nesting)
				nesting -= 1
				text += tabulate("func set_" + f.name + "(value" + argument_type + ") -> void:\n", nesting)
				nesting += 1
				text += generate_group_clear(field_index, nesting)
				text += tabulate("_" + f.name + ".value = value\n", nesting)
		return text
	
	func generate_class(class_index : int, nesting : int) -> String:
		var text : String = ""
		if class_table[class_index].type == Analysis.CLASS_TYPE.MESSAGE || class_table[class_index].type == Analysis.CLASS_TYPE.MAP:
			var cls_pref : String = ""
			cls_pref += tabulate("class " + class_table[class_index].name + ":\n", nesting)
			nesting += 1
			cls_pref += tabulate("func _init():\n", nesting)
			text += cls_pref
			nesting += 1
			text += tabulate("var service\n", nesting)
			text += tabulate("\n", nesting)
			var field_text : String = ""
			for i in range(field_table.size()):
				if field_table[i].parent_class_id == class_index:
					text += generate_field_constructor(i, nesting)
					text += tabulate("\n", nesting)
					field_text += generate_field(i, nesting - 1)
					field_text += tabulate("\n", nesting - 1)
			nesting -= 1
			text += tabulate("var data = {}\n", nesting)
			text += tabulate("\n", nesting)
			text += field_text
			for j in range(class_table.size()):
				if class_table[j].parent_index == class_index:
					var cl_text = generate_class(j, nesting)
					text += cl_text
					if class_table[j].type == Analysis.CLASS_TYPE.MESSAGE || class_table[j].type == Analysis.CLASS_TYPE.MAP:
						text += generate_class_services(nesting + 1)
						text += tabulate("\n", nesting + 1)
		elif class_table[class_index].type == Analysis.CLASS_TYPE.ENUM:
			text += tabulate("enum " + class_table[class_index].name + " {\n", nesting)
			nesting += 1
			for en in range(class_table[class_index].values.size()):
				var enum_val = class_table[class_index].values[en].name + " = " + class_table[class_index].values[en].value
				if en == class_table[class_index].values.size() - 1:
					text += tabulate(enum_val + "\n", nesting)
				else:
					text += tabulate(enum_val + ",\n", nesting)
			nesting -= 1
			text += tabulate("}\n", nesting)
			text += tabulate("\n", nesting)
			
		return text
	
	func generate_class_services(nesting : int) -> String:
		var text : String = ""
		text += tabulate("func _to_string() -> String:\n", nesting)
		nesting += 1
		text += tabulate("return PBPacker.message_to_string(data)\n", nesting)
		text += tabulate("\n", nesting)
		nesting -= 1
		text += tabulate("func to_bytes() -> PackedByteArray:\n", nesting)
		nesting += 1
		text += tabulate("return PBPacker.pack_message(data)\n", nesting)
		text += tabulate("\n", nesting)
		nesting -= 1
		text += tabulate("func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:\n", nesting)
		nesting += 1
		text += tabulate("var cur_limit = bytes.size()\n", nesting)
		text += tabulate("if limit != -1:\n", nesting)
		nesting += 1
		text += tabulate("cur_limit = limit\n", nesting)
		nesting -= 1
		text += tabulate("var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)\n", nesting)
		text += tabulate("if result == cur_limit:\n", nesting)
		nesting += 1
		text += tabulate("if PBPacker.check_required(data):\n", nesting)
		nesting += 1
		text += tabulate("if limit == -1:\n", nesting)
		nesting += 1
		text += tabulate("return PB_ERR.NO_ERRORS\n", nesting)
		nesting -= 2
		text += tabulate("else:\n", nesting)
		nesting += 1
		text += tabulate("return PB_ERR.REQUIRED_FIELDS\n", nesting)
		nesting -= 2
		text += tabulate("elif limit == -1 && result > 0:\n", nesting)
		nesting += 1
		text += tabulate("return PB_ERR.PARSE_INCOMPLETE\n", nesting)
		nesting -= 1
		text += tabulate("return result\n", nesting)
		return text
	
	func translate(file_name : String, core_file_name : String) -> bool:

		var file : FileAccess = FileAccess.open(file_name, FileAccess.WRITE)
		if file == null:
			printerr("File: '", file_name, "' save error.")
			return false
		
		if !FileAccess.file_exists(core_file_name):
			printerr("File: '", core_file_name, "' not found.")
			return false
			
		var core_file : FileAccess = FileAccess.open(core_file_name, FileAccess.READ)
		if core_file == null:
			printerr("File: '", core_file_name, "' read error.")
			return false
		var core_text : String = core_file.get_as_text()
		core_file.close()
		
		var text : String = ""
		var nesting : int = 0
		core_text = core_text.replace(PROTO_VERSION_DEFAULT, PROTO_VERSION_CONST + str(proto_version))
		text += core_text + "\n\n\n"
		text += "############### USER DATA BEGIN ################\n"
		var cls_user : String = ""
		for i in range(class_table.size()):
			if class_table[i].parent_index == -1:
				var cls_text = generate_class(i, nesting)
				cls_user += cls_text
				if class_table[i].type == Analysis.CLASS_TYPE.MESSAGE:
					nesting += 1
					cls_user += generate_class_services(nesting)
					cls_user += tabulate("\n", nesting)
					nesting -= 1
		text += "\n\n"
		text += cls_user
		text += "################ USER DATA END #################\n"
		file.store_string(text)
		file.close()
		if !FileAccess.file_exists(file_name):
			printerr("File: '", file_name, "' save error.")
			return false
		return true
	

class ImportFile:
	func _init(sha : String, a_path : String, a_parent : int):
		sha256 = sha
		path = a_path
		parent_index = a_parent
		
	var sha256 : String
	var path : String
	var parent_index : int

func parse_all(analyzes : Dictionary, imports : Array, path : String, full_name : String, parent_index : int) -> bool:
	
	if !FileAccess.file_exists(full_name):
		printerr(full_name, ": not found.")
		return false
		
	var file : FileAccess = FileAccess.open(full_name, FileAccess.READ)
	if file == null:
		printerr(full_name, ": read error.")
		return false
	var doc : Document = Document.new(full_name, file.get_as_text())
	var sha : String = file.get_sha256(full_name)
	file.close()
	
	if !analyzes.has(sha):
		print(full_name, ": parsing.")
		var analysis : Analysis = Analysis.new(path, doc)
		var an_result : AnalyzeResult = analysis.analyze()
		if an_result.state:
			analyzes[sha] = an_result
			var parent : int = imports.size()
			imports.append(ImportFile.new(sha, doc.name, parent_index))
			for im in an_result.imports:
				if !parse_all(analyzes, imports, path, im.path, parent):
					return false
		else:
			printerr(doc.name + ": parsing error.")
			return false
	else:
		print(full_name, ": retrieving data from cache.")
		imports.append(ImportFile.new(sha, doc.name, parent_index))
	return true

func union_analyses(a1 : AnalyzeResult, a2 : AnalyzeResult, only_classes : bool = true) -> void:
	var class_offset : int = a1.classes.size()
	var field_offset = a1.fields.size()
	for cl in a2.classes:
		var cur_class : Analysis.ASTClass = cl.copy()
		if cur_class.parent_index != -1:
			cur_class.parent_index += class_offset
		a1.classes.append(cur_class)
	if only_classes:
		return
	for fl in a2.fields:
		var cur_field : Analysis.ASTField = fl.copy()
		cur_field.parent_class_id += class_offset
		cur_field.type_class_id = -1
		a1.fields.append(cur_field)
	for gr in a2.groups:
		var cur_group : Analysis.ASTFieldGroup = gr.copy()
		cur_group.parent_class_id += class_offset
		var indexes : Array = []
		for i in cur_group.field_indexes:
			indexes.append(i + field_offset)
		cur_group.field_indexes = indexes
		a1.groups.append(cur_group)

func union_imports(analyzes : Dictionary, key : String, result : AnalyzeResult, keys : Array, nesting : int, use_public : bool = true, only_classes : bool = true) -> void:
	nesting += 1
	for im in analyzes[key].imports:
		var find : bool = false
		for k in keys:
			if im.sha256 == k:
				find = true
				break
		if find:
			continue
		if (!use_public) || (use_public && ((im.public && nesting > 1) || nesting < 2)):
			keys.append(im.sha256)
			union_analyses(result, analyzes[im.sha256], only_classes)
			union_imports(analyzes, im.sha256, result, keys, nesting, use_public, only_classes)

func semantic_all(analyzes : Dictionary, imports : Array)-> bool:
	for k in analyzes.keys():
		print(analyzes[k].doc.name, ": analysis.")
		var keys : Array = []
		var analyze : AnalyzeResult = analyzes[k].soft_copy()
		keys.append(k)
		analyze.classes = []
		for cl in analyzes[k].classes:
			analyze.classes.append(cl.copy())
		union_imports(analyzes, k, analyze, keys, 0)
		var semantic : Semantic = Semantic.new(analyze)
		if !semantic.check():
			printerr(analyzes[k].doc.name, ": analysis error.")
			return false
	return true
	
func translate_all(analyzes : Dictionary, file_name : String, core_file_name : String) -> bool:
	var first_key : String = analyzes.keys()[0]
	var analyze : AnalyzeResult = analyzes[first_key]
	var keys : Array = []
	keys.append(first_key)
	union_imports(analyzes, first_key, analyze, keys, 0, false, false)
	print("Performing full semantic analysis.")
	var semantic : Semantic = Semantic.new(analyze)
	if !semantic.check():
		return false
	print("Performing translation.")
	var translator : Translator = Translator.new(analyze)
	if !translator.translate(file_name, core_file_name):
		return false
	var first : bool = true
	return true

func work(path : String, in_file : String, out_file : String, core_file : String) -> bool:
	var in_full_name : String = path + in_file
	var imports : Array = []
	var analyzes : Dictionary = {}
	
	print("Compiling source: '", in_full_name, "', output: '", out_file, "'.")
	print("\n1. Parsing:")
	if parse_all(analyzes, imports, path, in_full_name, -1):
		print("* Parsing completed successfully. *")
	else:
		return false
	print("\n2. Perfoming semantic analysis:")
	if semantic_all(analyzes, imports):
		print("* Semantic analysis completed successfully. *")
	else:
		return false
	print("\n3. Output file creating:")
	if translate_all(analyzes, out_file, core_file):
		print("* Output file was created successfully. *")
	else:
		return false
	return true

func _ready():
	pass
