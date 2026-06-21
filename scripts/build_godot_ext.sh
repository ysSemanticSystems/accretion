#!/usr/bin/env sh
# Build libgodot_ext and copy into bin/ (res://bin/...) for Godot to load.
# Cursor/sandbox may set CARGO_TARGET_DIR elsewhere; pin output to ./target.
set -eu
cd "$(dirname "$0")/.."
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"
cargo build -p godot-ext "$@"
mkdir -p bin
case "$(uname -s)" in
  Darwin)
    install -m 755 target/debug/libgodot_ext.dylib bin/libgodot_ext.dylib
    ;;
  Linux)
    install -m 755 target/debug/libgodot_ext.so bin/libgodot_ext.so
    ;;
  MINGW* | MSYS* | CYGWIN*)
    install -m 755 target/debug/godot_ext.dll bin/godot_ext.dll
    ;;
  *)
    echo "Unsupported OS for godot-ext install: $(uname -s)" >&2
    exit 1
    ;;
esac
echo "Installed godot-ext → bin/ ($(uname -s))"
