#!/usr/bin/env -S godot -s

# godot --headless -s test.gd

extends SceneTree

const proto = preload("res://addons/godot-protobuf/proto.gd")

# class TypeTest:
#   var integer = null
#   var string = null

func _init():
  # var t = TypeTest.new()
  # print(t.integer)
  # print(t.string)
  # print("Hello!")
  print(proto.ProtobufEncoder.encode_varint(1000))
  quit()
