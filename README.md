
# Generating Protos

Install the dependencies:

```bash
go get
```

Make sure you have the binary built.

```bash
go build
```

You can either have the built binary on your path or point to it relatively with your [buf.gen.yaml](https://buf.build/docs/configuration/v2/buf-gen-yaml) file.

Example:

```yaml
# Learn more: https://docs.buf.build/configuration/v2/buf-gen-yaml
version: v2

plugins:
  - local: ../protoc-gen-godot/protoc-gen-godot
    out: godot/protos/

inputs:
  - directory: proto/
```

## Usage in Godot
Drag the addons folder into your godot resources as a plugin. This contains the needed code for all the generated files to use.


# Tests
There is a test proto file that can be built against and tests can be ran with godot in headless mode to ensure things are working correctly.

```bash
# Generate file
npx @bufbuild/buf generate proto

# Run test file
godot --headless -s test.gd
```
