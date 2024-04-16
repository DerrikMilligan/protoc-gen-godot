
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

	static func encode_varint(value) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()
		print("Value: " + ProtobufEncoder.binary_representation(value))

		while value >= 0x80 && bytes.size() < 10:
			print("Byte: " + ProtobufEncoder.binary_representation((value & 0x7F) | 0x80))
			bytes.append((value & 0x7F) | 0x80)
			value >>= 7

		print("Byte: " + ProtobufEncoder.binary_representation(value))
		bytes.append(value)

		return bytes


