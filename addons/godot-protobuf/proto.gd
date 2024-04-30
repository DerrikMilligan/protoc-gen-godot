
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
	# For map field default typing to ensure that there's always a valid
	# type provided. This will throw exceptions if the type is not provided
	INVALID_TYPE = -1,

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
	var name          : String
	var position      : int
	var data_type     : DATA_TYPE
	var map_key_type  : DATA_TYPE
	var map_value_type: DATA_TYPE
	var repeated      : bool
	var packed        : bool
	var message_class
	var value

	func _init(
		_name: String,
		_position: int,
		_data_type: DATA_TYPE,
		_message_class = null,
		_repeated: bool = false,
		_packed: bool = true,
		_map_key_type: DATA_TYPE = DATA_TYPE.INVALID_TYPE,
		_map_value_type: DATA_TYPE = DATA_TYPE.INVALID_TYPE
	):
		name           = _name
		position       = _position
		data_type      = _data_type
		repeated       = _repeated
		packed         = _packed
		message_class  = _message_class
		map_key_type   = _map_key_type
		map_value_type = _map_value_type

	func encode() -> PackedByteArray:
		return ProtobufEncoder.encode_field(self)

class ProtobufMessage:
	var fields: Dictionary = {}

	func _init(initial_data: Dictionary = {}):
		_init_fields()
		_load_initial_data(initial_data)

	func _load_initial_data(initial_data: Dictionary):
		for key in initial_data.keys():
			if not fields.has(key):
				continue

			match fields[key].data_type:
				DATA_TYPE.MESSAGE:
					## We can only instantiate the message if we were given a class
					if fields[key].message_class == null:
						fields[key].value = initial_data[key]
						continue

					fields[key].value = fields[key].message_class.new(initial_data[key])
				
				DATA_TYPE.MAP:
					# If we're given a dictionary for a map construct the array of key/value pairs
					if typeof(initial_data[key]) != TYPE_DICTIONARY:
						fields[key].value = initial_data[key]
						continue
					
					fields[key].value = []

					for map_key in initial_data[key].keys():
						fields[key].value.append([ map_key, initial_data[key][map_key] ])
					
				_:
					fields[key].value = initial_data[key]

	## To be overriden by each message to prep it's fields
	func _init_fields():
		pass

	func add_field(
		name: String,
		position: int,
		data_type: DATA_TYPE,
		message_class = null,
		repeated: bool = false,
		packed: bool = true,
		map_key_type: DATA_TYPE = DATA_TYPE.INVALID_TYPE,
		map_value_type: DATA_TYPE = DATA_TYPE.INVALID_TYPE
	):
		var field = ProtobufField.new(name, position, data_type, message_class, repeated, packed, map_key_type, map_value_type)
		fields[name] = field

	func encode() -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()

		for field in fields.values():
			if field.value != null:
				bytes.append_array(field.encode())

		return bytes

class ProtobufEncoder:

	## Helper class to encode map fields
	class MapMessage extends ProtobufMessage:
		func _init(key_type: DATA_TYPE, value_type: DATA_TYPE, initial_data: Dictionary = {}):
			add_field("key", 1, key_type)
			add_field("value", 2, value_type)

			_load_initial_data(initial_data)

		# func set_key(key):
		# 	fields["key"].value = key

		# func set_value(value):
		# 	fields["value"].value = value

	static func encode_varint(_value, data_type: DATA_TYPE) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()
		var value = _value

		if typeof(_value) == TYPE_BOOL:
			value = 1 if value else 0

		# If the value is negative, convert it to a positive number
		if data_type == DATA_TYPE.SINT32 || data_type == DATA_TYPE.SINT64:
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

	static func encode_varint_field(field: ProtobufField) -> PackedByteArray:
		return encode_varint(field.value, field.data_type)

	static func decode_varint(bytes: PackedByteArray) -> int:
		var value = 0
		var shift = 0

		for byte in bytes:
			value |= (byte & 0x7F) << shift
			if byte & 0x80 == 0:
				break
			shift += 7

		return value

	static func encode_fixed_field(field: ProtobufField, byte_count: int) -> PackedByteArray:
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

	static func encode_length_delimited_field(field: ProtobufField) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()
		var value: PackedByteArray

		match field.data_type:
			DATA_TYPE.STRING:
				value = field.value.to_utf8_buffer()

			DATA_TYPE.BYTES:
				value = field.value;

			DATA_TYPE.MESSAGE:
				value = field.value.encode()

			DATA_TYPE.MAP:
				var map_message = MapMessage.new(field.map_key_type, field.map_value_type, { "key": field.value[0], "value": field.value[1] })
				value = map_message.encode()

			_:
				assert(false, "Not a length delimited type")

		# Encode the varint representing the length of the data
		bytes.append_array(encode_varint(value.size(), DATA_TYPE.INT32))
		bytes.append_array(value)

		return bytes

	static func encode_field_for_wire_type(wire_type: WIRE_TYPE, field: ProtobufField) -> PackedByteArray:
		match wire_type:
			WIRE_TYPE.VARINT:
				return encode_varint_field(field)
			WIRE_TYPE.FIX32:
				return encode_fixed_field(field, 4)
			WIRE_TYPE.FIX64:
				return encode_fixed_field(field, 8)
			WIRE_TYPE.LENGTHDEL:
				return encode_length_delimited_field(field)
			_:
				assert(false, "Unsupported wire type")
				return PackedByteArray()

	static func encode_field(field: ProtobufField) -> PackedByteArray:
		var wire_type = WIRE_TYPE_LOOKUP[field.data_type]
		var field_descriptor = (field.position << 3) | wire_type
		var bytes: PackedByteArray = PackedByteArray(encode_varint(field_descriptor, DATA_TYPE.INT32))

		var field_values = field.value.duplicate() if field.repeated else [ field.value ]

		for index in len(field_values):
			field.value = field_values[index]

			bytes.append_array(encode_field_for_wire_type(wire_type, field))

			# Append the next field descriptor if we're not at the last element
			if index < len(field_values) - 1:
				bytes.append_array(encode_varint(field_descriptor, DATA_TYPE.INT32))

		# Restore the original field values if we were repeating
		if field.repeated:
			field.value = field_values

		return bytes

