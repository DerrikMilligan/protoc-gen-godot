package main

import (
	"fmt"

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
		return "PoolByteArray"
	case protoreflect.MessageKind:
		return string(field.Desc.Message().FullName().Name())
	// Maybe this would be handled differently?
	case protoreflect.EnumKind:
		return string(field.Desc.Enum().FullName().Name())
		// return "int"
	}
	return "Unknown " + field.Desc.Kind().String()
}

func getGodotDefaultValue(field *protogen.Field) string {
	switch field.Desc.Kind() {
	case protoreflect.BoolKind:
		return "false"
	case protoreflect.Int32Kind, protoreflect.Sint32Kind, protoreflect.Sfixed32Kind:
	case protoreflect.Int64Kind, protoreflect.Sint64Kind, protoreflect.Sfixed64Kind:
	case protoreflect.Uint32Kind, protoreflect.Fixed32Kind:
	case protoreflect.Uint64Kind, protoreflect.Fixed64Kind:
		return "0"
	case protoreflect.FloatKind:
	case protoreflect.DoubleKind:
		return "0.0"
	case protoreflect.StringKind:
		return "\"\""
	case protoreflect.BytesKind:
		return "PackedByteArray()"
	case protoreflect.MessageKind:
		return "null"
	// Maybe this would be handled differently?
	case protoreflect.EnumKind:
		return "0"
	}
	return "null"
}

// generateFile generates a _ascii.pb.go file containing gRPC service definitions.
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
				if !field.Desc.IsMap() {
					fieldMethod = fieldMethod + ", " + string(field.Desc.Message().FullName().Name())
					break
				}

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
				fieldMethod = fieldMethod + ", null, true, false, proto.DATA_TYPE." + keyType + ", proto.DATA_TYPE." + valueType

			default:
				if field.Desc.IsList() {
					fieldMethod = fieldMethod + ", null, true"
				}

				if field.Desc.IsPacked() {
					fieldMethod = fieldMethod + ", true"
				}
			}

			g.P(fieldMethod, ")", " ## @generated from field: ", field.Desc.Kind().String(), " ", field.Desc.Name(), " = ", field.Desc.Number())
			// g.P("\tvar ", field.Desc.Name(), " = null  # Type: ", getGodotFieldType(field))
			// g.P()
		}

		g.P()

		for _, field := range msg.Fields {
			g.P("\tfunc get_", field.Desc.Name(), "() -> ", getGodotFieldType(field), ":")
			g.P("\t\treturn fields[\"", field.Desc.Name(), "\"].value")
			g.P()
			g.P("\tfunc set_", field.Desc.Name(), "(_value: ", getGodotFieldType(field), "):")
			g.P("\t\treturn fields[\"", field.Desc.Name(), "\"].set_value(_value)")
			g.P()
		}

		g.P()
		g.P()
	}

	// return g
}
