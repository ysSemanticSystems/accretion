#!/usr/bin/env sh
# Build libgodot_ext into ./target/ (res://target/...) so Godot loads the fresh dylib.
# Cursor/sandbox sets CARGO_TARGET_DIR elsewhere; this script pins the output path.
set -eu
cd "$(dirname "$0")/.."
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/target}"
exec cargo build -p godot-ext "$@"
