
enum WIRE_TYPE {
	VARINT     = 0,
	FIX64      = 1,
	LENGTHDEL  = 2,
	STARTGROUP = 3, # Deprecated
	ENDGROUP   = 4, # Deprecated
	FIX32      = 5,
	UNDEFINED  = 8,
}

enum DATA_TYPE {
	# VARINT Types
	BOOL   = 0,
	ENUM   = 1,
	INT32  = 2,
	INT64  = 3,
	UINT32 = 4,
	UINT64 = 5,
	SINT32 = 6,
	SINT64 = 7,

	# FIX32 Types
	FIXED32  = 8,
	SFIXED32 = 9,
	FLOAT    = 10,

	# FIX64 Types
	FIXED64  = 11,
	SFIXED64 = 12,
	DOUBLE   = 13,

	# LENGTHDEL Types
	STRING  = 14,
	BYTES   = 15,
	MESSAGE = 16,
	MAP     = 17,
}

const WIRE_TYPE_LOOKUP = {
	DATA_TYPE.BOOL:     WIRE_TYPE.VARINT,
	DATA_TYPE.ENUM:     WIRE_TYPE.VARINT,
	DATA_TYPE.INT32:    WIRE_TYPE.VARINT,
	DATA_TYPE.INT64:    WIRE_TYPE.VARINT,
	DATA_TYPE.UINT32:   WIRE_TYPE.VARINT,
	DATA_TYPE.UINT64:   WIRE_TYPE.VARINT,
	DATA_TYPE.SINT32:   WIRE_TYPE.VARINT,
	DATA_TYPE.SINT64:   WIRE_TYPE.VARINT,
	DATA_TYPE.FIXED32:  WIRE_TYPE.FIX32,
	DATA_TYPE.SFIXED32: WIRE_TYPE.FIX32,
	DATA_TYPE.FLOAT:    WIRE_TYPE.FIX32,
	DATA_TYPE.FIXED64:  WIRE_TYPE.FIX64,
	DATA_TYPE.SFIXED64: WIRE_TYPE.FIX64,
	DATA_TYPE.DOUBLE:   WIRE_TYPE.FIX64,
	DATA_TYPE.STRING:   WIRE_TYPE.LENGTHDEL,
	DATA_TYPE.BYTES:    WIRE_TYPE.LENGTHDEL,
	DATA_TYPE.MESSAGE:  WIRE_TYPE.LENGTHDEL,
	DATA_TYPE.MAP:      WIRE_TYPE.LENGTHDEL,
}

class ProtobufField:
	var name     : String
	var position : int
	var data_type: DATA_TYPE
	var value

	func _init(_name: String, _position: int, _data_type: DATA_TYPE):
		name      = _name
		position  = _position
		data_type = _data_type

	func encode() -> PackedByteArray:
		return ProtobufEncoder.encode_field(self)

class ProtobufMessage:
	var fields: Dictionary = {}

	func _init(initial_data: Dictionary = {}):
		_init_fields()

		for key in initial_data.keys():
			if fields.has(key):
				fields[key].value = initial_data[key]

	## To be overriden by each message to prep it's fields
	func _init_fields():
		pass

	func add_field(name: String, position: int, data_type: DATA_TYPE):
		var field = ProtobufField.new(name, position, data_type)
		fields[name] = field

	func encode() -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()

		for field in fields.values():
			if field.value != null:
				bytes.append_array(field.encode())

		return bytes

	# func decode(bytes: PackedByteArray):
	# 	var position = 0
	# 	while position < bytes.size():
	# 		var byte = bytes[position]
	# 		var wire_type = byte & 0x07
	# 		var field_number = byte >> 3

	# 		var field = fields.values().find(lambda f: f.position == field_number)
	# 		if field == null:
	# 			position += 1
	# 			continue

	# 		match wire_type:
	# 			WIRE_TYPE.VARINT:
	# 				var varint = ProtobufEncoder.decode_varint(bytes[position+1:])
	# 				field.value = varint
	# 				position += 1 + varint.size()
	# 			WIRE_TYPE.FIX32:
	# 				var fix32 = bytes[position+1:position+5]
	# 				var spb = StreamPeerBuffer.new()
	# 				spb.put_data_array(fix32)
	# 				field.value = spb.get_float()
	# 				position += 5
	# 			WIRE_TYPE.FIX64:
	# 				var fix64 = bytes[position+1:position+9]
	# 				var spb = StreamPeerBuffer.new()
	# 				spb.put_data_array(fix64)
	# 				field.value = spb.get_double()
	# 				position += 9
	# 			WIRE_TYPE.LENGTHDEL:
	# 				var length = ProtobufEncoder.decode_varint(bytes[position+1:])
	# 				var data = bytes[position+1+length:position+1+length+length]
	# 				var spb = StreamPeerBuffer.new()
	# 				spb.put_data_array(data)
	# 				field.value = spb.get_data_array()
	# 				position += 1 + length + length
	# 			_:
	# 				assert(false, "Unsupported wire type")


class ProtobufEncoder:

	static func encode_varint(field: ProtobufField) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()
		var value = field.value

		if typeof(field.value) == TYPE_BOOL:
			value = 1 if value else 0

		# If the value is negative, convert it to a positive number
		if field.data_type == DATA_TYPE.SINT32 || field.data_type == DATA_TYPE.SINT64:
			if value < -2147483648:
				value = (value << 1) ^ (value >> 63)
			else:
				value = (value << 1) ^ (value >> 31)

		for i in range(9):
			var byte = value & 0x7F
			value >>= 7
			if value:
				bytes.append(byte | 0x80)
			else:
				bytes.append(byte)
				break

		# Additional bit to indcate that it's a negative value
		if bytes.size() == 9 && bytes[8] == 0xFF:
			bytes.append(0x01)

		return bytes

	static func decode_varint(bytes: PackedByteArray) -> int:
		var value = 0
		var shift = 0

		for byte in bytes:
			value |= (byte & 0x7F) << shift
			if byte & 0x80 == 0:
				break
			shift += 7

		return value

	static func encode_bytes(field: ProtobufField, byte_count: int) -> PackedByteArray:
		if field.data_type == DATA_TYPE.FLOAT:
			var spb = StreamPeerBuffer.new()
			spb.put_float(field.value)
			return spb.get_data_array()
		
		if field.data_type == DATA_TYPE.DOUBLE:
			var spb = StreamPeerBuffer.new()
			spb.put_double(field.value)
			return spb.get_data_array()

		if field.data_type == DATA_TYPE.FIXED32 or field.data_type == DATA_TYPE.FIXED64:
			assert(field.value >= 0, "Fixed types can't be negative, use SFIXED instead")
		
		var bytes : PackedByteArray = PackedByteArray()

		var value = field.value
		for i in range(byte_count):
			bytes.append(value & 0xFF)
			value >>= 8

		return bytes

	static func encode_field(field: ProtobufField) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()
		var wire_type = WIRE_TYPE_LOOKUP[field.data_type]

		bytes.append((field.position << 3) | wire_type)

		match wire_type:
			WIRE_TYPE.VARINT:
				bytes.append_array(encode_varint(field))
			WIRE_TYPE.FIX32:
				bytes.append_array(encode_bytes(field, 4))
			WIRE_TYPE.FIX64:
				bytes.append_array(encode_bytes(field, 8))
			_:
				assert(false, "Unsupported wire type")

		return bytes

