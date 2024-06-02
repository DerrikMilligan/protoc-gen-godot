
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
	var name     : String
	var position : int
	var data_type: DATA_TYPE
	var repeated : bool
	var packed   : bool
	var map_key_type
	var map_value_type
	var message_class
	var value

	func _init(
		_name: String,
		_position: int,
		_data_type: DATA_TYPE,
		_message_class = null,
		_repeated: bool = false,
		_packed: bool = true,
		# These can also be other messages
		_map_key_type = DATA_TYPE.INVALID_TYPE,
		_map_value_type = DATA_TYPE.INVALID_TYPE
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

	func get_value():
		match data_type:
			DATA_TYPE.MAP:
				var map_dictionary = {}

				for item in value:
					map_dictionary[item[0]] = item[1]

				return map_dictionary

			_:
				return value

	func set_value(_value) -> void:
		value = get_clean_value(_value)

	func get_clean_value(_value):
		match data_type:
			DATA_TYPE.BOOL:
				if _value is bool: return _value
				if _value is int: return _value != 0
				assert(false, "Invalid value type for field: '%s' value given: '%s'. Must be bool or int" % [name, _value])
			DATA_TYPE.ENUM:
				assert(_value is int, "Invalid value type for field: '%s' value given: '%s'. Must be int and one of these values: %s" % [name, _value, message_class])
				assert(_value in message_class.values(), "Invalid value for field: '%s' value given: '%s'. Must be one of: %s" % [name, _value, message_class])
				return _value
			DATA_TYPE.UINT32:
				assert(_value >= 0, "Invalid value type for field: '%s' value given: '%s'. Unsigned integer can't be negative" % [name, _value])
				return _value
			DATA_TYPE.UINT64:
				assert(_value >= 0, "Invalid value type for field: '%s' value given: '%s'. Unsigned integer can't be negative" % [name, _value])
				return _value
			DATA_TYPE.STRING:
				return str(_value)
			DATA_TYPE.BYTES:
				assert(_value is PackedByteArray, "Invalid value type for field: '%s' value given: '%s'. Expected PackedByteArray" % [name, _value])
				return _value
			DATA_TYPE.MESSAGE:
				assert(message_class != null, "Invalid value type for field: '%s' value given: '%s'. Field doesn't support a message type of value" % [name, _value])
				match typeof(_value):
					TYPE_OBJECT:
						return _value
					TYPE_DICTIONARY:
						return message_class.new(_value)
					_:
						assert(false, "Invalid value type for field: '%s' value given: '%s'. Expected '%s'" % [name, _value, message_class])

			DATA_TYPE.MAP:
				# assert(_value is Dictionary, "Invalid value type for field: '%s' value given: '%s'. Expected Dictionary" % (name, _value))
				# @TODO: If we pass an array of key/value pairs handle that? Maybe?
				# @TODO: How do you add a single value?

				match typeof(_value):
					TYPE_ARRAY:
						return _value
					# If we're given an array of values construct the array of key/value pairs
					TYPE_DICTIONARY:
						var mapped_values = []
						for map_key in _value:
							mapped_values.append([ map_key, _value[map_key] ])
						return mapped_values
					_:
						assert(false, "Invalid value type for field: '%s' value given: '%s'. Expected Array or Dictionary" % [name, _value])

			_:
				return _value

class ProtobufMessage:
	var fields: Dictionary = {}

	func _init(initial_data: Dictionary = {}):
		_init_fields()
		_load_initial_data(initial_data)

	func _load_initial_data(initial_data: Dictionary):
		for key in initial_data.keys():
			if fields.has(key):
				fields[key].set_value(initial_data[key])

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
		# These can also refer to other message types uses as keys or values
		map_key_type = DATA_TYPE.INVALID_TYPE,
		map_value_type = DATA_TYPE.INVALID_TYPE
	):
		var field = ProtobufField.new(name, position, data_type, message_class, repeated, packed, map_key_type, map_value_type)
		fields[name] = field

	func encode() -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()

		for field in fields.values():
			if field.value != null:
				bytes.append_array(field.encode())

		return bytes

## Helper class to encode map fields
class MapMessage extends ProtobufMessage:
	func _init(
		key_type: DATA_TYPE,
		value_type: DATA_TYPE,
		initial_data: Dictionary = {},
		key_message_class = null,
		value_message_class = null
	):
		add_field("key", 1, key_type, key_message_class)
		add_field("value", 2, value_type, value_message_class)

		_load_initial_data(initial_data)

class ProtobufEncoder:

	static func encode_varint(_value, data_type: DATA_TYPE) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()
		var value = _value

		if typeof(_value) == TYPE_BOOL:
			value = 1 if value else 0

		# Encode signed integers using ZigZag encoding
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

	static func encode_fixed_field(field: ProtobufField, byte_count: int) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()

		if field.data_type == DATA_TYPE.FLOAT:
			bytes.resize(4)
			bytes.encode_float(0, field.value)
			return bytes
		
		if field.data_type == DATA_TYPE.DOUBLE:
			bytes.resize(8)
			bytes.encode_double(0, field.value)
			return bytes

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
				var key_is_class   = typeof(field.map_key_type)   != TYPE_INT
				var value_is_class = typeof(field.map_value_type) != TYPE_INT

				var map_message = MapMessage.new(
					DATA_TYPE.MESSAGE if key_is_class   else field.map_key_type,
					DATA_TYPE.MESSAGE if value_is_class else field.map_value_type,
					{ "key": field.value[0], "value": field.value[1] },
					field.map_key_type   if key_is_class   else null,
					field.map_value_type if value_is_class else null
				)
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
		var field_descriptor = (field.position << 3) | (WIRE_TYPE.LENGTHDEL if field.repeated and field.packed else wire_type)
		var bytes: PackedByteArray = PackedByteArray(encode_varint(field_descriptor, DATA_TYPE.INT32))

		var field_values = field.value.duplicate() if field.repeated else [ field.value ]

		var packed_data: PackedByteArray = PackedByteArray()

		for index in len(field_values):
			field.value = field_values[index]

			var encoded_field = encode_field_for_wire_type(wire_type, field)

			if field.repeated and field.packed:
				packed_data.append_array(encoded_field)
				continue
				
			bytes.append_array(encoded_field)

			# Append the next field descriptor if we're not at the last element
			if index < len(field_values) - 1:
				bytes.append_array(encode_varint(field_descriptor, DATA_TYPE.INT32))

		if field.repeated:
			# Restore the original field values if we were repeating
			field.value = field_values

			if field.packed:
				bytes.append_array(encode_varint(packed_data.size(), DATA_TYPE.INT32))
				bytes.append_array(packed_data)

		return bytes

class ProtobufDecoder:

	static func decode_varint(bytes: PackedByteArray, data_type: DATA_TYPE):
		var value      = 0
		var shift      = 0
		var byte_count = 1

		for byte in bytes:
			value |= (byte & 0x7F) << shift

			# if we don't have the continuation bit then break the loop
			if (byte & 0x80) == 0:
				break

			byte_count += 1
			shift += 7

		# Decode signed integers using ZigZag decoding
		if data_type == DATA_TYPE.SINT32 or data_type == DATA_TYPE.SINT64:
			if value & 1:
				value = ~(value >> 1)
			else:
				value = value >> 1

		# Convert to boolean if data type is boolean
		if data_type == DATA_TYPE.BOOL:
			value = value != 0

		return [ byte_count, value ]

	static func decode_varint_field(field: ProtobufField, bytes: PackedByteArray):
		return decode_varint(bytes, field.data_type)

	static func decode_fixed_field(field: ProtobufField, bytes: PackedByteArray, byte_count: int):
		if field.data_type == DATA_TYPE.FLOAT:
			return [ byte_count, bytes.decode_float(0) ]
		
		if field.data_type == DATA_TYPE.DOUBLE:
			return [ byte_count, bytes.decode_double(0) ]

		var value = 0
		for i in range(byte_count):
			value |= (bytes[i] << (i * 8))

		# Because in gdscript every integer is actually a 64-bit integer, when we get a negative value
		# for a 32-bit integer, we need to sign-extend it to 64 bits. Praise be ChatGPT... I'm sure I could
		# understand this given enough time... But for now it works.
		# Check if the number is negative
		var most_significant_bit = 1 << ((byte_count * 8) - 1)
		if value & most_significant_bit != 0:
			# Sign-extend to 64 bits
			value |= -most_significant_bit


		return [ byte_count, value ]

	static func decode_length_delimited_field(field: ProtobufField, bytes: PackedByteArray):
		var byte_count = 0

		# Decode the length of the data
		var length_info = decode_varint(bytes, DATA_TYPE.INT32)
		var length = length_info[1]
		byte_count += length_info[0]

		# Extract the length-delimited bytes
		var value_bytes = bytes.slice(byte_count, byte_count + length)
		byte_count += length

		# Decode the extracted bytes based on the data type
		var value
		match field.data_type:
			DATA_TYPE.STRING:
				value = value_bytes.get_string_from_utf8()

			DATA_TYPE.BYTES:
				value = value_bytes

			DATA_TYPE.MESSAGE:
				value = decode_message(field.message_class.new(), value_bytes)

			DATA_TYPE.MAP:
				value = []

				# restart the count because we need to count up each map field and not include the length
				byte_count = length_info[0]

				var key_is_class   = typeof(field.map_key_type)   != TYPE_INT
				var value_is_class = typeof(field.map_value_type) != TYPE_INT

				var map_message = MapMessage.new(
					DATA_TYPE.MESSAGE if key_is_class   else field.map_key_type,
					DATA_TYPE.MESSAGE if value_is_class else field.map_value_type,
					{},
					field.map_key_type   if key_is_class   else null,
					field.map_value_type if value_is_class else null
				)

				while true:
					var key_field   = decode_next_message_field(map_message, bytes.slice(byte_count))
					byte_count     += key_field[0]
					var value_field = decode_next_message_field(map_message, bytes.slice(byte_count))
					byte_count     += value_field[0]

					value.append([ key_field[1], value_field[1] ])

					# map fields are never packed so we always get the mapper field
					# information again as well as the length of the field
					length_info = decode_varint(bytes.slice(byte_count), DATA_TYPE.INT32)

					var field_position = length_info[1] >> 3

					# If the field position doesn't match the map field position then we've reached the end
					if field_position != field.position:
						break

					byte_count += length_info[0]

					# offset by the length descriptor
					length_info = decode_varint(bytes.slice(byte_count), DATA_TYPE.INT32)
					byte_count += length_info[0]

			_:
				assert(false, "Not a length delimited type")

		return [byte_count, value]

	static func decode_field_for_wire_type(wire_type: WIRE_TYPE, field: ProtobufField, bytes: PackedByteArray):
		match wire_type:
			WIRE_TYPE.VARINT:
				return decode_varint_field(field, bytes)
			WIRE_TYPE.FIX32:
				return decode_fixed_field(field, bytes, 4)
			WIRE_TYPE.FIX64:
				return decode_fixed_field(field, bytes, 8)
			WIRE_TYPE.LENGTHDEL:
				return decode_length_delimited_field(field, bytes)
			_:
				assert(false, "Unsupported wire type")
				return PackedByteArray()

	## Only decodes the first field in the bytes it can find
	static func decode_next_message_field(message: ProtobufMessage, bytes: PackedByteArray):
		var decoded_descriptor = decode_varint(bytes, DATA_TYPE.INT32)
		var field_descriptor   = decoded_descriptor[1]
		var field_position     = field_descriptor >> 3
		var wire_type          = field_descriptor & 0x07

		var field = null

		for _field in message.fields.values():
			if _field.position == field_position:
				field = _field
				break

		# Skip the field if we don't have it in our fields
		if field == null:
			# byte_index += field_descriptor
			return [ decoded_descriptor[0], null, null ]

		if field.repeated and field.packed:
			var byte_length = decoded_descriptor[0]
			var repeated_length = decode_varint(bytes.slice(byte_length), DATA_TYPE.INT32)
			var item_wire_type = WIRE_TYPE_LOOKUP[field.data_type]

			byte_length += repeated_length[0]

			var repeated_items = []

			for i in range(repeated_length[1]):
				var repeated_field = decode_field_for_wire_type(item_wire_type, field, bytes.slice(byte_length))
				byte_length += repeated_field[0]
				repeated_items.append(repeated_field[1])

			return [ byte_length, repeated_items, field ]

		var field_info = decode_field_for_wire_type(wire_type, field, bytes.slice(decoded_descriptor[0]))

		return [ decoded_descriptor[0] + field_info[0], field_info[1], field ]

	static func decode_message(message: ProtobufMessage, bytes: PackedByteArray):
		var byte_index = 0

		while byte_index < bytes.size():
			var decoded_field = decode_next_message_field(message, bytes.slice(byte_index))
			var field         = decoded_field[2]
			byte_index       += decoded_field[0]

			if decoded_field[1] == null or field == null:
				continue

			match field.data_type:
				# For messages we'll already have the message object and just need to assign it
				DATA_TYPE.MESSAGE:
					field.value = decoded_field[1]
				_:
					field.set_value(decoded_field[1])

		return message
