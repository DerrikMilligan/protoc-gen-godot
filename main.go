package main

import (
	"fmt"
	"slices"

	"google.golang.org/protobuf/compiler/protogen"
	"google.golang.org/protobuf/reflect/protoreflect"
)

func main() {
	protogen.Options{}.Run(func(gen *protogen.Plugin) error {
		for _, f := range gen.Files {
			if !f.Generate {
				continue
			}
			generateFile(gen, f)
		}
		return nil
	})
}

func getEnumTypeFromKind(kind protoreflect.Kind) (string, bool) {
	switch kind {
	case protoreflect.BoolKind:
		return "BOOL", true
	case protoreflect.Int32Kind:
		return "INT32", true
	case protoreflect.Sint32Kind:
		return "SINT32", true
	case protoreflect.Sfixed32Kind:
		return "SFIXED32", true
	case protoreflect.Int64Kind:
		return "INT64", true
	case protoreflect.Sint64Kind:
		return "SINT64", true
	case protoreflect.Sfixed64Kind:
		return "SFIXED64", true
	case protoreflect.Uint32Kind:
		return "UINT32", true
	case protoreflect.Fixed32Kind:
		return "FIXED32", true
	case protoreflect.Uint64Kind:
		return "UINT64", true
	case protoreflect.Fixed64Kind:
		return "FIXED64", true
	case protoreflect.FloatKind:
		return "FLOAT", true
	case protoreflect.DoubleKind:
		return "DOUBLE", true
	case protoreflect.StringKind:
		return "STRING", true
	case protoreflect.BytesKind:
		return "BYTES", true
	case protoreflect.MessageKind:
		return "MESSAGE", true
	case protoreflect.EnumKind:
		return "ENUM", true
	}

	return "UNKNOWN KIND " + kind.String(), false
}

func getEnumTypeFromField(field *protogen.Field) (string, bool) {
	if field.Desc.IsMap() {
		return "MAP", true
	}

	typeName, ok := getEnumTypeFromKind(field.Desc.Kind())

	if ok {
		return typeName, true
	}

	return "Unknown " + field.Desc.Kind().String(), false
}

func getGodotFieldType(field *protogen.Field) string {
	switch field.Desc.Kind() {
	case protoreflect.BoolKind:
		return "bool"
	case protoreflect.Int32Kind, protoreflect.Sint32Kind, protoreflect.Sfixed32Kind,
		protoreflect.Int64Kind, protoreflect.Sint64Kind, protoreflect.Sfixed64Kind,
		protoreflect.Uint32Kind, protoreflect.Fixed32Kind,
		protoreflect.Uint64Kind, protoreflect.Fixed64Kind:
		return "int"
	case protoreflect.FloatKind, protoreflect.DoubleKind:
		return "float"
	case protoreflect.StringKind:
		return "String"
	case protoreflect.BytesKind:
		return "PackedByteArray"
	case protoreflect.MessageKind:
		// If it's a real message
		if !field.Desc.IsMap() {
			return string(field.Desc.Message().FullName().Name())
		}
		// If it's a map
		return "Dictionary"
	case protoreflect.EnumKind:
		return string(field.Desc.Enum().FullName().Name())
	}
	return "Unknown " + field.Desc.Kind().String()
}

// func getGodotDefaultValue(field *protogen.Field) string {
// 	switch field.Desc.Kind() {
// 	case protoreflect.BoolKind:
// 		return "false"
// 	case protoreflect.Int32Kind, protoreflect.Sint32Kind, protoreflect.Sfixed32Kind:
// 	case protoreflect.Int64Kind, protoreflect.Sint64Kind, protoreflect.Sfixed64Kind:
// 	case protoreflect.Uint32Kind, protoreflect.Fixed32Kind:
// 	case protoreflect.Uint64Kind, protoreflect.Fixed64Kind:
// 		return "0"
// 	case protoreflect.FloatKind:
// 	case protoreflect.DoubleKind:
// 		return "0.0"
// 	case protoreflect.StringKind:
// 		return "\"\""
// 	case protoreflect.BytesKind:
// 		return "PackedByteArray()"
// 	case protoreflect.MessageKind:
// 		return "null"
// 	// Maybe this would be handled differently?
// 	case protoreflect.EnumKind:
// 		return "0"
// 	}
// 	return "null"
// }

func generateFile(gen *protogen.Plugin, file *protogen.File) {
	filename := file.GeneratedFilenamePrefix + "_pb.gd"
	g := gen.NewGeneratedFile(filename, file.GoImportPath)
	g.P("## @generated by protoc-gen-godot")
	g.P("## @generated from ", file.Desc.Path())
	g.P("##")
	g.P("## Proto syntax: ", file.Desc.Syntax())
	if file.Proto.Edition != nil {
		g.P("## Edition: ", file.Proto.Edition)
	}
	g.P()
	g.P("const proto = preload(\"res://addons/godot-protobuf/proto.gd\")")
	g.P()

	// Generate the enum definitions
	for _, enum := range file.Enums {
		g.P("## @generated from enum ", enum.Desc.Name())
		g.P("enum ", enum.GoIdent.GoName, " {")
		for _, value := range enum.Values {
			g.P("\t", value.Desc.Name(), " = ", value.Desc.Number(), ", ## @generated from enum value: ", value.Desc.Name(), " = ", value.Desc.Number())
		}
		g.P("}")
		g.P()
		g.P()
	}

	// Generate Message definitions
	for _, msg := range file.Messages {
		g.P("## @generated from message ", msg.Desc.Name())
		g.P("class ", msg.GoIdent.GoName, " extends proto.ProtobufMessage:")
		g.P("\tstatic func from_bytes(bytes: PackedByteArray) -> ", msg.GoIdent.GoName, ":")
		g.P("\t\treturn proto.ProtobufDecoder.decode_message(", msg.GoIdent.GoName, ".new(), bytes)")
		g.P()

		if len(msg.Fields) <= 0 {
			continue
		}

		g.P("\tfunc _init_fields():")

		for _, field := range msg.Fields {
			fieldType, ok := getEnumTypeFromField(field)

			if !ok {
				println("Invalid field type: ", field.Desc.Kind())
				return
			}
			fieldMethod := "\t\tadd_field(\"" + string(field.Desc.Name()) + "\", " + fmt.Sprintf("%d", field.Desc.Number()) + ", proto.DATA_TYPE." + fieldType

			switch field.Desc.Kind() {
			case protoreflect.MessageKind:
				// Regular messages that aren't maps
				if !field.Desc.IsMap() {
					fieldMethod = fieldMethod + ", " + string(field.Desc.Message().FullName().Name())
					if field.Oneof != nil {
						fieldMethod = fieldMethod + ", false, true, -1, -1, \"" + string(field.Oneof.Desc.Name()) + "\""
					}
					break
				}

				// Map key and value types
				keyType, ok := getEnumTypeFromKind(field.Desc.MapKey().Kind())
				if !ok {
					println("Invalid map key type: ", field.Desc.MapKey().Kind())
					return
				}
				valueType, ok := getEnumTypeFromKind(field.Desc.MapValue().Kind())
				if !ok {
					println("Invalid map value type: ", field.Desc.MapValue().Kind())
					return
				}
				if keyType == "MESSAGE" {
					keyType = string(field.Desc.MapKey().Message().FullName().Name())
				} else {
					keyType = "proto.DATA_TYPE." + keyType
				}
				if valueType == "MESSAGE" {
					valueType = string(field.Desc.MapValue().Message().FullName().Name())
				} else {
					valueType = "proto.DATA_TYPE." + valueType
				}
				fieldMethod = fieldMethod + ", null, true, false, " + keyType + ", " + valueType

				if field.Oneof != nil {
					fieldMethod = fieldMethod + ", \"" + string(field.Oneof.Desc.Name()) + "\""
				}

			case protoreflect.EnumKind:
				fieldMethod = fieldMethod + ", " + string(field.Desc.Enum().FullName().Name())
				if field.Oneof != nil {
					fieldMethod = fieldMethod + ", false, true, -1, -1, \"" + string(field.Oneof.Desc.Name()) + "\""
				}

			default:
				if field.Desc.IsList() {
					fieldMethod = fieldMethod + ", null, true"

					if field.Oneof != nil && !field.Desc.IsPacked() {
						fieldMethod = fieldMethod + ", true, -1, -1, \"" + string(field.Oneof.Desc.Name()) + "\""
					}
				}

				if field.Desc.IsPacked() {
					fieldMethod = fieldMethod + ", true"

					if field.Oneof != nil {
						fieldMethod = fieldMethod + ", -1, -1, \"" + string(field.Oneof.Desc.Name()) + "\""
					}
				}

				if !field.Desc.IsList() && !field.Desc.IsPacked() && field.Oneof != nil {
					fieldMethod = fieldMethod + ", null , false, true, -1, -1, \"" + string(field.Oneof.Desc.Name()) + "\""
				}
			}

			g.P(fieldMethod, ")", " ## @generated from field: ", field.Desc.Kind().String(), " ", field.Desc.Name(), " = ", field.Desc.Number())
		}

		g.P()

		for _, field := range msg.Fields {
			g.P("\tfunc get_", field.Desc.Name(), "() -> ", getGodotFieldType(field), ":")
			g.P("\t\treturn get_field(\"", field.Desc.Name(), "\") as ", getGodotFieldType(field))
			g.P()
			g.P("\tfunc set_", field.Desc.Name(), "(value: ", getGodotFieldType(field), "):")
			g.P("\t\tset_field(\"", field.Desc.Name(), "\", value)")
			g.P()

			// Potentially in the future we could add a set method for maps to set the key and value
			// if field.Desc.IsMap() {
			// 	g.P("\tfunc set_", field.Desc.Name(), "(value: ", getGodotFieldType(field), "):")
			// 	g.P("\t\treturn fields[\"", field.Desc.Name(), "\"].set_value(value)")
			// 	g.P()
			// }
		}

		var oneofs []string

		for _, field := range msg.Fields {
			if field.Oneof == nil {
				continue
			}

			oneofName := string(field.Oneof.Desc.Name())

			if slices.Contains(oneofs, oneofName) {
				continue
			}

			oneofs = append(oneofs, oneofName)

			g.P("\tfunc get_", oneofName, "():")
			g.P("\t\treturn get_field(\"", oneofName, "\")")
			g.P()
			g.P("\tfunc set_", oneofName, "(value):")
			g.P("\t\tset_field(\"", oneofName, "\", value)")
			g.P()
		}

		g.P()
	}

}
