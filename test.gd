#!/usr/bin/env -S godot -s

# godot --headless -s test.gd

extends SceneTree

const proto = preload("res://addons/godot-protobuf/proto.gd")

class TestMessage extends proto.ProtobufMessage:
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
    add_field("bytes", 14, proto.DATA_TYPE.BYTES)
    add_field("bool", 15, proto.DATA_TYPE.BOOL)

  func set_int32(value):
    fields["int32"].value = value;

  func set_int64(value):
    fields["int64"].value = value;

  func set_uint32(value):
    fields["uint32"].value = value;

  func set_uint64(value):
    fields["uint64"].value = value;

  func set_sint32(value):
    fields["sint32"].value = value;

  func set_sint64(value):
    fields["sint64"].value = value;

  func set_fixed32(value):
    fields["fixed32"].value = value;
  
  func set_fixed64(value):
    fields["fixed64"].value = value;
  
  func set_sfixed32(value):
    fields["sfixed32"].value = value;
  
  func set_sfixed64(value):
    fields["sfixed64"].value = value;
  
  func set_bool(value):
    fields["bool"].value = value;

  func get_int32(value):
    return fields["int32"].value;

  func get_int64(value):
    return fields["int64"].value;

  func get_uint32(value):
    return fields["uint32"].value;

  func get_uint64(value):
    return fields["uint64"].value;

  func get_sint32(value):
    return fields["sint32"].value;

  func get_sint64(value):
    return fields["sint64"].value;

  func get_fixed32(value):
    return fields["fixed32"].value;
  
  func get_fixed64(value):
    return fields["fixed64"].value;
  
  func get_sfixed32(value):
    return fields["sfixed32"].value;
  
  func get_sfixed64(value):
    return fields["sfixed64"].value;
  
  func get_bool(value):
    return fields["bool"].value;

class TestProtobufEncoder:
  static func run_tests():
    TestProtobufEncoder.test_test_message()

  static func test_test_message():
    assert(TestMessage.new({ "int32": 123 }).encode() == PackedByteArray([0x08, 0x7B]))
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
    # assert(TestMessage.new({ "bytes": PackedByteArray([0x01, 0x02, 0x03]) }).encode() == PackedByteArray([0x4D, 0x7B, 0x00, 0x00, 0x00]))

    assert(TestMessage.new({ "int32": 123, "int64": 456, "fixed64": 789 }).encode() == PackedByteArray([0x08, 0x7B, 0x10, 0xC8, 0x03, 0x51, 0x15, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))


func _init():
  TestProtobufEncoder.run_tests()
  quit()
