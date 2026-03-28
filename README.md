# Godobuf v0.7.0

## Changelog in v0.7.0
- Godot 4.6 compatibility
- Added support for directory input

## Changelog in v0.6.1
- Some bugs fixed

## What's new in v0.6.0
- Added support for Godot 4
- Fixed bug with return type in add method for map

## Version
Current Godobuf master branch is compatible with Godot 4.6.<br/>
If you want to use the Godobuf plugin for other Godot versions, see:
- 3.0.x use branch tagged v0.2.2 https://github.com/oniksan/godobuf/tree/v0.2.2
- 3.1.x use branch tagged v0.3.0 https://github.com/oniksan/godobuf/tree/v0.3.0
- 3.5.x use branch tagged v0.5.0 https://github.com/oniksan/godobuf/tree/v0.5.0

## About
Godobuf is a Google Protocol Buffers compiler from a `.proto` file description to a GDScript output file.
The output file contains user protobuf messages represented by classes and protobuf core code that is responsible for data serialization/deserialization.
Godobuf is used as a plugin for Godot 4.6.<br/>
Godobuf is easy to use and does not require rebuilding the Godot engine because it is written in GDScript. All you need is to start the plugin.

## Features
### Supported
- Protobuf v2 and v3
- Message definitions (cascade messages)
- Simple Protobuf types (int32, uint32, sint32, fixed32, sfixed32<br/>int64, uint64, sint64, fixed64, sfixed64, float, double, bool, enum, string, bytes)
- Oneof type
- Map type
- Repeated fields
- Option `packed` for fields
- Protobuf imports (including the `public` modifier)
- Debug string for class (message) fields (since v0.2.1)
 
### Not supported
- Packages
- Reserved statements
- Services
- `Any` types
- Default values option for fields

## Installation

1. Create a new project in Godot or use an existing project.
2. Copy `addons` directory from the Godobuf repository to your Godot project directory.
3. In the menu, choose `Project->Project Settings`.<br/>
![Project->Project Settings](/readme-images/1.png)<br/>
4. In `Project Settings` window choose `Plugins` tab.
5. Find Godobuf plugin and set status `Active`.<br/>
![Plugins](/readme-images/2.png)<br/>
6. Close `Project Settings` window.
7. The Godobuf panel will be displayed in the Godot editor.<br/>
![Plugins](/readme-images/3.png)
8. Please note that the Godobuf panel may not be visible because it can be located on the last tab.<br/>
![Plugins](/readme-images/7.png)

## Usage

### From the User Interface
1. Open the file dialog window `Input protobuf file`.
2. Choose a `.proto` file in the dialog window.<br/>
![Input protobuf file](/readme-images/4.png)<br/>
3. Open the file dialog window `Output GDScript file`.
4. Choose a directory and enter an output file name.<br/>
![Output GDScript file](/readme-images/5.png)<br/>
5. Press `Compile` button.
6. See Godot `Output` for details.
7. All possible error details are displayed in Godot `Output`.
8. After completion, you'll see an alert window that reports the compilation result.<br/>
![Alert](/readme-images/6.png)<br/>
9. If compilation was successful a new GDScript will be created in a specified directory.
10. Use the script in your project.

### From the User Interface (Directory conversion)
1. In the `Directory conversion` section, open `Input proto directory` and select a directory with `.proto` files.
2. Open `Output directory` and select where generated `.gd` files should be written.
3. Press `Compile directory`.
4. Godobuf compiles all `.proto` files recursively and preserves the relative folder structure in the output directory.

### From the Command Line
1. From the root directory of your project, run `godot4 --headless -s addons/protobuf/protobuf_cmdln.gd --input=A.proto --output=my_proto.gd`
2. Optionally, define an alias: `alias godobuf='godot4 -s addons/protobuf/protobuf_cmdln.gd'`

### Unit tests
0. This option is mainly for those who modify the code or want to check the stability of this version.
1. Press `Run unit tests (proto 2)`, `Run unit tests (proto 3)`, or `Run batch compile tests` to start tests.
2. See Godot `Output` for details.
3. All possible error details are displayed in Godot `Output`.
4. After completion, you'll see an alert window that reports the test result.<br/>

## Mapping of protocol buffers data types to GDScript

Protobuf | GDScript | GDScript typeof
---|---|---
int32, uint32, sint32, fixed32, sfixed32<br/>int64, uint64, sint64, fixed64, sfixed64 | int | TYPE_INT
float | double / real<br/>note: *number after unpacking will be **single** precision* | TYPE_REAL
double | double / real | TYPE_REAL
bool | bool | TYPE_BOOL
enum | enum / int | TYPE_INT
string | String | TYPE_STRING
bytes | PackedByteArray | TYPE_PACKED_BYTE_ARRAY
oneof | fields described in oneof<br/>note: *fields are not grouped into a structure,<br/>but you can set the value for only one field* | different
map | Dictionary | TYPE_DICTIONARY
message | class | TYPE_OBJECT
repeated fields | Array | TYPE_ARRAY

## Default values

### Protobuf version 2
Initially all fields are set to null.<br/>
Default values in .proto syntax not supported.<br/>
Repeated fields are set as empty arrays.
### Protobuf version 3
Initially all fields are set to default values specified in the Protobuf manual.<br/>
Repeated fields are set as empty arrays.

## Keywords
Keywords cannot be used in any other constructions for which they are not intended. In particular, keywords cannot be used as field names and message names.<br/>
### Keywords:
`message, double, float, int32, int64, uint32, uint64, sint32, sint64, fixed32, fixed64, sfixed32, sfixed64, bool, string, bytes, enum, map, oneof, true, false, syntax, import, package, option, service, reserved, weak, public, repeated, required, optional, allow_alias, custom_option, extensions, packed`

## Using generated .gd file in Godot project

1. Open the script in which Protobuf will be used.
2. Preload previously generated script:
```gdscript
const MyProto = preload("res://my_proto.gd")
```
3. Use previously described messages as GDScript classes.
Example, we have .proto file:
```protobuf
syntax = "proto3";
message A {
	double f1 = 1;
	B f2 = 2;
}
```
### Pack (serialization) message
Packed message must be instantiated as a GDScript class object directly.<br/>
Pack message A:
```gdscript
# Create packed class (message)
var a = MyProto.A.new()
# Example, set field f1
a.set_f1(12.554)
# Pack message A
# Use to_bytes() method, it returns PackedByteArray
var packed_bytes = a.to_bytes()
```
### Unpack (deserialization) message
Unpacked message must be instantiated as a GDScript class object directly.<br/>
`Re-calling from_bytes() of the same object instance is not allowed. You must create new object instance.`<br/>
Unpack message A:
```gdscript
# Create unpacked class (message)
var a = MyProto.A.new()
# Unpack byte sequence to class (message) A.
# Use from_bytes(PackedByteArray my_byte_sequence) method
var result_code = a.from_bytes(my_byte_sequence)
# result_code must be checked (see Unpack result codes section)
if result_code == MyProto.PB_ERR.NO_ERRORS:
	print("OK")
else:
	return
# Use class 'a' fields. Example, get field f1
var f1 = a.get_f1()
```

## Unpack result codes

The `from_bytes()` method returns either a success or an error state.<br/>
User must check the result code to make sure the unpacking is correct (see 'Unpack message' section above).<br/>
Result codes (enum PB_ERR) are presented in table below.

Unpack result code | int representation | Description
---|---|---
NO_ERRORS | 0 | Success
VARINT_NOT_FOUND | -1 | Parse error.<br/>Byte sequence does not contain a varint attribute, but a varint is described in the `.proto` file.
REPEATED_COUNT_NOT_FOUND | -2 | Parse error.<br/>Byte sequence contains negative size of repeated block.
REPEATED_COUNT_MISMATCH | -3 | Parse error.<br/>Byte sequence size less than field type size or block size.
LENGTHDEL_SIZE_NOT_FOUND | -4 | Parse error.<br/>Byte sequence contains negative size of length delimited field type.
LENGTHDEL_SIZE_MISMATCH | -5 | Parse error.<br/>Byte sequence size less than length delimited field type size.
PACKAGE_SIZE_MISMATCH | -6 | Parse error.<br/>Byte sequence size less than package required length.
UNDEFINED_STATE | -7 | Error.<br/>Unspecified error.
PARSE_INCOMPLETE | -8 | Byte sequence error.<br/>Byte sequence is correct and corresponds to the `.proto` descriptor, but its size is incomplete. The package (byte sequence) did not arrive completely.
REQUIRED_FIELDS | -9 | Sender error.<br/>For Protobuf v2. Byte sequence is correct and corresponds to the .proto descriptor, but not all required fields are filled (data is missing in the byte sequence).

## API

### 1. Scalar types
Scalar types: int32, uint32, sint32, fixed32, sfixed32, int64, uint64, sint64, fixed64, sfixed64, float, double, bool.
#### Set value
Use method `set_<field_name>(value)`. Sets field value.<br/>
#### Get value
Use method `get_<field_name>()`. Returns field value.
#### Example
> .proto-file
```protobuf
syntax = "proto3";
message A {
	double f1 = 1;
	int32 f2 = 2;
}
```
> GDScript. Using set
```gdscript
var a = MyProto.A.new()
a.set_f1(12.554)
a.set_f2(500)
```
> GDScript. Using get
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
var my_field_f1 = a.get_f1()
var my_field_f2 = a.get_f2()
```

### 2. String
Use similarly to scalar types.
#### Set value
Use method `set_<field_name>(value)`. Sets field value.
#### Get value
Use method `get_<field_name>()`. Returns field value.
#### Example
> .proto-file
```protobuf
syntax = "proto3";
message A {
	string f1 = 1;
}
```
> GDScript. Using set
```gdscript
var a = MyProto.A.new()
a.set_f1("my string")
```
> GDScript. Using get
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
var my_field_f1 = a.get_f1()
```

### 3. Bytes
Use similarly to scalar types.
#### Set value
Use method `set_<field_name>(value)`. Sets field value.
#### Get value
Use method `get_<field_name>()`. Returns field value as PackedByteArray.
#### Example
> .proto-file
```protobuf
syntax = "proto3";
message A {
	bytes f1 = 1;
	bytes f2 = 2;
}
```
> GDScript. Using set
```gdscript
var a = MyProto.A.new()
# Correct both
a.set_f1([1,2,3,4,5])
a.set_f2(PackedByteArray([0,3,4,5,7]))
```
> GDScript. Using get
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
var my_pool_byte_array_f1 = a.get_f1()
```

### 4. Enum
Use similarly to scalar types, but values should be taken from Enum which was generated by compiler.<br/>
Generated Enums are named according to the following rule:<br/>
`<message root>.<message inner>. ... <enum name>`<br/>
Using enum name in GDScript:<br/>
`<preloaded/loaded resource instance name>.<class root>.<class inner>. ... <enum name>`
#### Set value
Use method `set_<field_name>(value)`. Sets field value.
#### Get value
Use method `get_<field_name>()`. Returns field value.
#### Example
> .proto-file
```protobuf
syntax = "proto3";
enum TestEnum {
	VALUE_0 = 0;
	VALUE_1 = 1;
	VALUE_2 = 2;
}

message B {
	enum BEnum {
		BVALUE_0 = 0;
		BVALUE_1 = 1;
		BVALUE_2 = 2;
	}
}

message A {
	TestEnum f1 = 1;
	B.BEnum f2 = 2;
}
```
> GDScript. Using set
```gdscript
var a = MyProto.A.new()
a.set_f1(MyProto.TestEnum.VALUE_1)
a.set_f2(MyProto.B.BEnum.BVALUE_2)
```
> GDScript. Using get
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
var my_field_f1 = a.get_f1()
if my_field_f1 == MyProto.TestEnum.VALUE_1:
	print("OK value-1")
```

### 5. Oneof
Use similarly to scalar types, but you can set the value for only one field grouped in oneof.<br/>
Oneof group name not used in GDScript.<br/>
If you set one field of oneof group another fields will be cleared automatically.
#### Set value
Use method `set_<field_name>(value)`. Sets field value.
#### Get value
Use method `get_<field_name>()`. Returns field value.
#### Has value
Use method `has_<field_name>()`. Returns true if the value has been set in `byte_sequence`.
#### Example
> .proto-file
```protobuf
syntax = "proto3";
message A {
	oneof my_oneof {
		string      f1 = 1;
		int32       f2 = 2;
		map<int32, int32> f3 = 3;
	}
}
```
> GDScript. Using set
```gdscript
var a = MyProto.A.new()
a.set_f1("my string")
# if you set f2: f1 and f3 will be set to default values (or null for Protobuf v2)
a.set_f2(10)
```
> GDScript. Using get
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
var my_field_f1 = a.get_f1()
```
> GDScript. Using has
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
if a.has_f1():
	print("F1")
elif a.has_f2():
	print("F2")
```

### 6. Map
#### Add value
For non-message map values, use method:<br/>
`add_<field_name>(key, value)`. Append one key-value pair to Dictionary (map) field.<br/><br/>
If map value is message (class), use method:<br/>
`add_<field_name>(key)`. Append one key-value pair to Dictionary (map) field and return value object instance.
#### Get value
Use method `get_<field_name>()`. Returns GDScript Dictionary (map).
#### Example
> .proto-file
```protobuf
syntax = "proto3";
message A {
	message B {
		int32 f1 = 1;
		int32 f2 = 2;
	}
	map<int32, string> f1 = 1;
	map<int32, B> f2 = 2;
}
```
> GDScript. Using add
```gdscript
var a = MyProto.A.new()
a.add_f1(1, "one")
a.add_f1(2, "two")
a.add_f1(4, "four")

var b
b = a.add_f2(10)
b.set_f1(100)
b.set_f2(200)
b = a.add_f2(20)
b.set_f1(1000)
b.set_f2(2000)
```
> GDScript. Using get
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
var my_dict_f1 = a.get_f1()
```

### 7. Message
#### Set value
Use method `new_<field_name>()`. Creates an object instance, sets it as the field value, and returns the instance.
#### Get value
Use method `get_<field_name>()`. Returns object instance.
#### Example
> .proto-file
```protobuf
syntax = "proto3";
message A {
	message B {
		int64 Bf1 = 1;
		float Bf2 = 2;
	}
	message C {
		string Cf1 = 1;
		B Cf2 = 2;
	}
	
	int32 Af1 = 1;
	C Af2 = 2;
}
```
> GDScript. Using new (set)
```gdscript
var a = MyProto.A.new()
a.set_Af1(10)
var c = a.new_Af2()
c.set_Cf1("my string")
var b = c.new_Cf2()
b.set_Bf1(20)
b.set_Bf2(2.5)
```
> GDScript. Using get
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
var my_class_instance_c = a.get_Af2()
var my_int32 = my_class_instance_c.get_Af1()
# ...
```

### 8. Repeated
#### Add value for non-message types
Use method `add_<field_name>(value)`. Append value to Array.
#### Add value for message fields
Use method `add_<field_name>()`. Creates an object instance, sets it as the next Array element, and returns the instance.
#### Get value
Use method `get_<field_name>()`. Returns Array of fields.
#### Example
> .proto-file
```protobuf
syntax = "proto3";
message A {
	message B {
		int64 Bf1 = 1;
		float Bf2 = 2;
	}
	
	repeated int32 Af1 = 1;
	repeated B Af2 = 2;
}
```
> GDScript. Using add
```gdscript
var a = MyProto.A.new()

a.add_Af1(10)
a.add_Af1(20)
a.add_Af1(30)

var b
b = a.add_Af2()
b.set_Bf1(100)
b.set_Bf2(1.5)

b = a.add_Af2()
b.set_Bf1(200)
b.set_Bf2(2.5)
```
> GDScript. Using get
```gdscript
var a = MyProto.A.new()
var state = a.from_bytes(byte_sequence)
# First you have to check the 'state' ...
var my_array_b = a.get_Af2()
for inst in my_array_b:
	print(inst.get_Bf1())
```

### 9. Debug method to_string()
All message classes have to_string() method.<br/>
`to_string()` generates a debug string that contains field names and their values. Default values are ignored.
#### String output format:
```field_<type>``` - field name
```
field_int: 12;
field_float: 12.34;
field_bool: True;
field_string: "test";
field_enum: ENUM::2;

field_message_1: {
  field_message_2: {
    field_int: 12;
    field_float: 12.34;
  }
  field_bool: True;
  field_string: "test";
};

field_repeated: [
  0: {
    field_int: 123;
    field_bool: True;
  },
  1: {
    field_int: 454;
    field_bool: False;
  }
];

field_repeated: [
  1: 2, 
  2: 3, 
  3: 4
];

field_map: (
  "key1": "value1",
  "key2": "value2"
);

field_map: (
  "object1": {
    field_int: 123;
    field_bool: True;
  },
  "object2": {
    field_int: 454;
    field_bool: False;
  }
);

field_bytes: <1, 2, 4, 5>;
field_empty_message: {};
```
#### Example
```gdscript
# Debug print, where `message` is any Protobuf class (message)
print(message.to_string())
```

## Related links
Google Protobuf: https://developers.google.com/protocol-buffers/docs/overview <br/>
Godot Engine: http://godotengine.org <br/>
Godot docs: https://docs.godotengine.org/en/stable/ <br/>
Godobuf test suites: https://github.com/kittenseater/godobuf-test <br/>
https://github.com/kittenseater/godobuf-gen-v2 <br/>
https://github.com/kittenseater/godobuf-gen-v3
