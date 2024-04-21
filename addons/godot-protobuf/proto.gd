
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

class ProtobufEncoder:
	static func binary_representation(number: int) -> String:
		var binary_str = ""
		var num = number

		# Use a loop to divide the number by 2 and collect remainders
		while num > 0:
			# Collect the remainder (0 or 1) and prepend it to binary_str
			binary_str = str(num % 2) + binary_str
			# Update the number by dividing it by 2
			num /= 2

		# Return the binary string
		return binary_str

	static func encode_varint(value, data_type: DATA_TYPE) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()

		if typeof(value) == TYPE_BOOL:
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

	static func decode_varint(bytes: PackedByteArray) -> int:
		var value = 0
		var shift = 0

		for byte in bytes:
			value |= (byte & 0x7F) << shift
			if byte & 0x80 == 0:
				break
			shift += 7

		return value

	static func encode_bytes(value, data_type: DATA_TYPE, byte_count: int) -> PackedByteArray:
		if data_type == DATA_TYPE.FLOAT:
			var spb = StreamPeerBuffer.new()
			spb.put_float(value)
			return spb.get_data_array()
		
		if data_type == DATA_TYPE.DOUBLE:
			var spb = StreamPeerBuffer.new()
			spb.put_double(value)
			return spb.get_data_array()
		
		var bytes : PackedByteArray = PackedByteArray()

		for i in range(byte_count):
			bytes.append(value & 0xFF)
			value >>= 8

		return bytes

	static func encode_field(value, data_type: DATA_TYPE):
		var wire_type = WIRE_TYPE_LOOKUP[data_type]

		if wire_type == WIRE_TYPE.VARINT:
			return encode_varint(value, data_type)

		if wire_type == WIRE_TYPE.FIX32:
			return encode_bytes(value, data_type, 4)

		if wire_type == WIRE_TYPE.FIX64:
			return encode_bytes(value, data_type, 8)



