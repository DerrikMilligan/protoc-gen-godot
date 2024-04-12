#!/usr/bin/env -S godot -s

# godot --headless -s test.gd

extends SceneTree

class TypeTest:
  var integer = null
  var string = null

func _init():
  var t = TypeTest.new()
  print(t.integer)
  print(t.string)
  print("Hello!")
  quit()
