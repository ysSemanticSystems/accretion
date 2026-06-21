.PHONY: check gen build test clippy fmt hooks godot-smoke

# Godot loads res://target/debug/libgodot_ext.dylib — always build there.
CARGO_TARGET_DIR := $(CURDIR)/target
export CARGO_TARGET_DIR

# macOS default; override with GODOT_BIN=... or put `godot` on PATH.
GODOT_BIN ?= /Applications/Godot.app/Contents/MacOS/Godot
GODOT_FALLBACK := godot

hooks:
	./scripts/setup-hooks.sh

gen:
	python3 scripts/gen_constants.py
	python3 scripts/gen_golden.py

build:
	./scripts/build_godot_ext.sh

test:
	cargo test --workspace

clippy:
	cargo clippy --workspace --all-targets -- -D warnings

fmt:
	cargo fmt --check

godot-smoke: build
	@set -e; \
	GODOT=""; \
	if [ -x "$(GODOT_BIN)" ]; then GODOT="$(GODOT_BIN)"; \
	elif command -v $(GODOT_FALLBACK) >/dev/null 2>&1; then GODOT="$(GODOT_FALLBACK)"; \
	else echo "ERROR: Godot not found. Install to /Applications/Godot.app or set GODOT_BIN."; exit 1; fi; \
	case "$(uname -s)" in \
	  Darwin) test -f bin/libgodot_ext.dylib || { echo "ERROR: bin/libgodot_ext.dylib missing"; exit 1; } ;; \
	  Linux)  test -f bin/libgodot_ext.so || { echo "ERROR: bin/libgodot_ext.so missing"; exit 1; } ;; \
	esac; \
	echo "Godot smoke test ($$GODOT)…"; \
	if [ ! -f .godot/extension_list.cfg ]; then \
	  echo "Bootstrapping .godot/ (fresh clone — verifying GDExtensions)…"; \
	  "$$GODOT" --headless --path . -e --quit-after 1 >/dev/null 2>&1 || true; \
	fi; \
	"$$GODOT" --headless --path . res://scenes/GodotSmoke.tscn

check: gen hooks
	git diff --exit-code crates/accretion-core/src/constants.rs
	git diff --exit-code crates/accretion-core/tests/fixtures/golden.json
	sh scripts/check_invariants.sh
	sh scripts/check_wiki.sh
	cargo test --workspace
	cargo clippy --workspace --all-targets -- -D warnings
	$(MAKE) godot-smoke
