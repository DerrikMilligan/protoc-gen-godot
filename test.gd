#!/usr/bin/env -S godot -s

# godot --headless -s test.gd

extends SceneTree

const proto = preload("res://addons/godot-protobuf/proto.gd")

class TestProtobufEncoder:
  static func run_tests():
    TestProtobufEncoder.test_encode_field()

  # static func test_encode_varint():
  #   var encoded = proto.ProtobufEncoder.encode_varint(1000)
  #   assert(encoded == PackedByteArray([0xE8, 0x07]))

  #   encoded = proto.ProtobufEncoder.encode_varint(150)
  #   assert(encoded == PackedByteArray([0x96, 0x01]))

  #   encoded = proto.ProtobufEncoder.encode_varint(123456789)
  #   assert(encoded == PackedByteArray([0x95, 0x9A, 0xEF, 0x3A]))

  # static func test_decode_varint():
  #   var decoded = proto.ProtobufEncoder.decode_varint(PackedByteArray([0xE8, 0x07]))
  #   assert(decoded == 1000)

  #   decoded = proto.ProtobufEncoder.decode_varint(PackedByteArray([0x96, 0x01]))
  #   assert(decoded == 150)

  #   decoded = proto.ProtobufEncoder.decode_varint(PackedByteArray([0x95, 0x9A, 0xEF, 0x3A]))
  #   assert(decoded == 123456789)

  static func test_encode_field():
    var encoded = proto.ProtobufEncoder.encode_field(123.456, proto.DATA_TYPE.FLOAT)
    assert(encoded == PackedByteArray([0x79, 0xE9, 0xF6, 0x42]))

    encoded = proto.ProtobufEncoder.encode_field(123.456, proto.DATA_TYPE.DOUBLE)
    assert(encoded == PackedByteArray([0x77, 0xBE, 0x9F, 0x1A, 0x2F, 0xDD, 0x5E, 0x40]))

    encoded = proto.ProtobufEncoder.encode_field(123, proto.DATA_TYPE.INT32)
    assert(encoded == PackedByteArray([0x7B]))

    encoded = proto.ProtobufEncoder.encode_field(-123, proto.DATA_TYPE.INT32)
    assert(encoded == PackedByteArray([0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01]))

    encoded = proto.ProtobufEncoder.encode_field(123, proto.DATA_TYPE.UINT32)
    assert(encoded == PackedByteArray([0x7B]))

    encoded = proto.ProtobufEncoder.encode_field(123, proto.DATA_TYPE.FIXED32)
    assert(encoded == PackedByteArray([0x7B, 0x00, 0x00, 0x00]))

    encoded = proto.ProtobufEncoder.encode_field(-123, proto.DATA_TYPE.SFIXED32)
    assert(encoded == PackedByteArray([0x85, 0xFF, 0xFF, 0xFF]))

    encoded = proto.ProtobufEncoder.encode_field(123, proto.DATA_TYPE.INT64)
    assert(encoded == PackedByteArray([0x7B]))

    encoded = proto.ProtobufEncoder.encode_field(-123, proto.DATA_TYPE.INT64)
    assert(encoded == PackedByteArray([0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01]))

    encoded = proto.ProtobufEncoder.encode_field(123, proto.DATA_TYPE.UINT64)
    assert(encoded == PackedByteArray([0x7B]))

    encoded = proto.ProtobufEncoder.encode_field(123, proto.DATA_TYPE.FIXED64)
    assert(encoded == PackedByteArray([0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))

    encoded = proto.ProtobufEncoder.encode_field(-123, proto.DATA_TYPE.SFIXED64)
    assert(encoded == PackedByteArray([0x85, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))

    encoded = proto.ProtobufEncoder.encode_field(true, proto.DATA_TYPE.BOOL)
    assert(encoded == PackedByteArray([1]))

    encoded = proto.ProtobufEncoder.encode_field(false, proto.DATA_TYPE.BOOL)
    assert(encoded == PackedByteArray([0]))



func _init():
  TestProtobufEncoder.run_tests()
  quit()
