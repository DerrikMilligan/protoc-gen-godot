#!/usr/bin/env -S godot -s

# godot --headless -s test.gd

extends SceneTree

const proto = preload("res://addons/godot-protobuf/proto.gd")

class SubMessage extends proto.ProtobufMessage:
  func _init_fields():
    add_field("int32", 1, proto.DATA_TYPE.INT32)

class TestMessage extends proto.ProtobufMessage:
  static func from_bytes(bytes: PackedByteArray) -> TestMessage:
    return proto.ProtobufDecoder.decode_message(TestMessage.new(), bytes)

  func _init_fields():
    add_field("int32", 1, proto.DATA_TYPE.INT32)
    add_field("int64", 2, proto.DATA_TYPE.INT64)
    add_field("float", 3, proto.DATA_TYPE.FLOAT)
    add_field("double", 4, proto.DATA_TYPE.DOUBLE)
    add_field("uint32", 5, proto.DATA_TYPE.UINT32)
    add_field("uint64", 6, proto.DATA_TYPE.UINT64)
    add_field("sint32", 7, proto.DATA_TYPE.SINT32)
    add_field("sint64", 8, proto.DATA_TYPE.SINT64)
    add_field("fixed32", 9, proto.DATA_TYPE.FIXED32)
    add_field("fixed64", 10, proto.DATA_TYPE.FIXED64)
    add_field("sfixed32", 11, proto.DATA_TYPE.SFIXED32)
    add_field("sfixed64", 12, proto.DATA_TYPE.SFIXED64)
    add_field("bool", 13, proto.DATA_TYPE.BOOL)
    add_field("bytes", 14, proto.DATA_TYPE.BYTES)
    add_field("string", 15, proto.DATA_TYPE.STRING)
    add_field("sub_message", 16, proto.DATA_TYPE.MESSAGE, SubMessage)
    add_field("map", 17, proto.DATA_TYPE.MAP, null, true, false, proto.DATA_TYPE.STRING, proto.DATA_TYPE.INT32)
    add_field("sub_map", 18, proto.DATA_TYPE.MAP, null, true, false, proto.DATA_TYPE.STRING, proto.DATA_TYPE.MESSAGE)
    add_field("r_int32", 19, proto.DATA_TYPE.INT32, null, true)
    add_field("big_int32", 12345, proto.DATA_TYPE.INT32)

class TestProtobufEncoder:
  static func run_tests():
    TestProtobufEncoder.test_message_encoding()
    TestProtobufEncoder.test_message_decoding()

  static func test_message_encoding():
    assert(TestMessage.new({ "int32": 123 }).encode() == PackedByteArray([0x08, 0x7B]))
    assert(TestMessage.new({ "big_int32": 67890 }).encode() == PackedByteArray([0xC8, 0x83, 0x06, 0xB2, 0x92, 0x04]))
    assert(TestMessage.new({ "int32": -123 }).encode() == PackedByteArray([0x08, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01]))
    assert(TestMessage.new({ "int64": 123 }).encode() == PackedByteArray([0x10, 0x7B]))
    assert(TestMessage.new({ "int64": -123 }).encode() == PackedByteArray([0x10, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01]))
    assert(TestMessage.new({ "float": 123.456 }).encode() == PackedByteArray([0x1D, 0x79, 0xE9, 0xF6, 0x42]))
    assert(TestMessage.new({ "float": -123.456 }).encode() == PackedByteArray([0x1D, 0x79, 0xE9, 0xF6, 0xC2]))
    assert(TestMessage.new({ "double": 123.456 }).encode() == PackedByteArray([0x21, 0x77, 0xBE, 0x9F, 0x1A, 0x2F, 0xDD, 0x5E, 0x40]))
    assert(TestMessage.new({ "double": -123.456 }).encode() == PackedByteArray([0x21, 0x77, 0xBE, 0x9F, 0x1A, 0x2F, 0xDD, 0x5E, 0xC0]))
    assert(TestMessage.new({ "uint32": 123 }).encode() == PackedByteArray([0x28, 0x7B]))
    assert(TestMessage.new({ "uint64": 123 }).encode() == PackedByteArray([0x30, 0x7B]))
    assert(TestMessage.new({ "sint32": 123 }).encode() == PackedByteArray([0x38, 0xF6, 0x01]))
    assert(TestMessage.new({ "sint32": -123 }).encode() == PackedByteArray([0x38, 0xF5, 0x01]))
    assert(TestMessage.new({ "sint64": 123 }).encode() == PackedByteArray([0x40, 0xF6, 0x01]))
    assert(TestMessage.new({ "sint64": -123 }).encode() == PackedByteArray([0x40, 0xF5, 0x01]))
    assert(TestMessage.new({ "fixed32": 123 }).encode() == PackedByteArray([0x4D, 0x7B, 0x00, 0x00, 0x00]))
    assert(TestMessage.new({ "sfixed32": 123 }).encode() == PackedByteArray([0x5D, 0x7B, 0x00, 0x00, 0x00]))
    assert(TestMessage.new({ "sfixed32": -123 }).encode() == PackedByteArray([0x5D, 0x85, 0xFF, 0xFF, 0xFF]))
    assert(TestMessage.new({ "fixed64": 123 }).encode() == PackedByteArray([0x51, 0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    assert(TestMessage.new({ "sfixed64": 123 }).encode() == PackedByteArray([0x61, 0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    assert(TestMessage.new({ "sfixed64": -123 }).encode() == PackedByteArray([0x61, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
    assert(TestMessage.new({ "bool": false }).encode() == PackedByteArray([0x68, 0x00]))
    assert(TestMessage.new({ "bool": true }).encode() == PackedByteArray([0x68, 0x01]))
    assert(TestMessage.new({ "bytes": PackedByteArray([0x01, 0x02, 0x03]) }).encode() == PackedByteArray([0x72, 0x03, 0x01, 0x02, 0x03]))
    assert(TestMessage.new({ "string": "Test String!" }).encode() == PackedByteArray([0x7A, 0x0C, 0x54, 0x65, 0x73, 0x74, 0x20, 0x53, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x21]))
    assert(TestMessage.new({ "sub_message": { "int32": 123 } }).encode() == PackedByteArray([0x82, 0x01, 0x02, 0x08, 0x7B]))
    assert(TestMessage.new({ "map": { "a": 1, "b": 2, "c": 3 } }).encode() == PackedByteArray([
      0x8A, 0x01, 0x05, 0x0A, 0x01, 0x61, 0x10, 0x01,
      0x8A, 0x01, 0x05, 0x0A, 0x01, 0x62, 0x10, 0x02,
      0x8A, 0x01, 0x05, 0x0A, 0x01, 0x63, 0x10, 0x03
    ]))
    assert(TestMessage.new({ "sub_map": { "a": SubMessage.new({ "int32": 1 }), "b": SubMessage.new({ "int32": 2 }) } }).encode() == PackedByteArray([
      0x92, 0x01, 0x07, 0x0A, 0x01, 0x61, 0x12, 0x02, 0x08, 0x01,
      0x92, 0x01, 0x07, 0x0A, 0x01, 0x62, 0x12, 0x02, 0x08, 0x02
    ]))
    assert(TestMessage.new({ "r_int32": [ 1, 2, 3 ] }).encode() == PackedByteArray([0x9A, 0x01, 0x03, 0x01, 0x02, 0x03]))
    assert(TestMessage.new({ "int32": 123, "int64": 456, "fixed64": 789 }).encode() == PackedByteArray([0x08, 0x7B, 0x10, 0xC8, 0x03, 0x51, 0x15, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))

  static func test_message_decoding():
    assert(TestMessage.from_bytes(PackedByteArray([0x08, 0x7B])).encode() == TestMessage.new({ "int32": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0xC8, 0x83, 0x06, 0xB2, 0x92, 0x04])).encode() == TestMessage.new({ "big_int32": 67890 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x08, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01])).encode() == TestMessage.new({ "int32": -123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x10, 0x7B])).encode() == TestMessage.new({ "int64": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x10, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01])).encode() == TestMessage.new({ "int64": -123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x1D, 0x79, 0xE9, 0xF6, 0x42])).encode() == TestMessage.new({ "float": 123.456 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x1D, 0x79, 0xE9, 0xF6, 0xC2])).encode() == TestMessage.new({ "float": -123.456 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x21, 0x77, 0xBE, 0x9F, 0x1A, 0x2F, 0xDD, 0x5E, 0x40])).encode() == TestMessage.new({ "double": 123.456 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x21, 0x77, 0xBE, 0x9F, 0x1A, 0x2F, 0xDD, 0x5E, 0xC0])).encode() == TestMessage.new({ "double": -123.456 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x28, 0x7B])).encode() == TestMessage.new({ "uint32": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x30, 0x7B])).encode() == TestMessage.new({ "uint64": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x38, 0xF6, 0x01])).encode() == TestMessage.new({ "sint32": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x38, 0xF5, 0x01])).encode() == TestMessage.new({ "sint32": -123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x40, 0xF6, 0x01])).encode() == TestMessage.new({ "sint64": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x40, 0xF5, 0x01])).encode() == TestMessage.new({ "sint64": -123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x4D, 0x7B, 0x00, 0x00, 0x00])).encode() == TestMessage.new({ "fixed32": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x5D, 0x7B, 0x00, 0x00, 0x00])).encode() == TestMessage.new({ "sfixed32": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x5D, 0x85, 0xFF, 0xFF, 0xFF])).encode() == TestMessage.new({ "sfixed32": -123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x51, 0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])).encode() == TestMessage.new({ "fixed64": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x61, 0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])).encode() == TestMessage.new({ "sfixed64": 123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x61, 0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])).encode() == TestMessage.new({ "sfixed64": -123 }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x68, 0x00])).encode() == TestMessage.new({ "bool": false }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x68, 0x01])).encode() == TestMessage.new({ "bool": true }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x72, 0x03, 0x01, 0x02, 0x03])).encode() == TestMessage.new({ "bytes": PackedByteArray([0x01, 0x02, 0x03]) }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x7A, 0x0C, 0x54, 0x65, 0x73, 0x74, 0x20, 0x53, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x21])).encode() == TestMessage.new({ "string": "Test String!" }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x82, 0x01, 0x02, 0x08, 0x7B])).encode() == TestMessage.new({ "sub_message": { "int32": 123 } }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([
      0x8A, 0x01, 0x05, 0x0A, 0x01, 0x61, 0x10, 0x01,
      0x8A, 0x01, 0x05, 0x0A, 0x01, 0x62, 0x10, 0x02,
      0x8A, 0x01, 0x05, 0x0A, 0x01, 0x63, 0x10, 0x03
    ])).encode() == TestMessage.new({ "map": { "a": 1, "b": 2, "c": 3 } }).encode())
    # assert(TestMessage.from_bytes(PackedByteArray([
    #   0x92, 0x01, 0x07, 0x0A, 0x01, 0x61, 0x12, 0x02, 0x08, 0x01,
    #   0x92, 0x01, 0x07, 0x0A, 0x01, 0x62, 0x12, 0x02, 0x08, 0x02
    # ])).encode() == TestMessage.new({ "sub_map": { "a": SubMessage.new({ "int32": 1 }), "b": SubMessage.new({ "int32": 2 }) } }).encode())
    # assert(TestMessage.from_bytes(PackedByteArray([0x9A, 0x01, 0x03, 0x01, 0x02, 0x03])).encode() == TestMessage.new({ "r_int32": [ 1, 2, 3 ] }).encode())
    assert(TestMessage.from_bytes(PackedByteArray([0x08, 0x7B, 0x10, 0xC8, 0x03, 0x51, 0x15, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])).encode() == TestMessage.new({ "int32": 123, "int64": 456, "fixed64": 789 }).encode())

func _init():
  TestProtobufEncoder.run_tests()
  quit()
