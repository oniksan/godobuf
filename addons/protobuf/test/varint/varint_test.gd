extends SceneTree

const Proto: Script = preload("varint.gd") 

func _init():
	var typename = OS.get_cmdline_user_args()[0]
	var number = int(OS.get_cmdline_user_args()[1])
	var filename = OS.get_cmdline_user_args()[2]
	print("encoding %s" % number)
	
	var proto = Proto[typename].new()
	proto.set_n(number)
	var bytes = proto.to_bytes()
	var base64 = Marshalls.raw_to_base64(bytes)
	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(base64)
	file.close()
	quit()
