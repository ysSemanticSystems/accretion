.PHONY: check gen build test clippy fmt hooks

GODOT_BIN ?= godot

hooks:
	./scripts/setup-hooks.sh

gen:
	python3 scripts/gen_constants.py
	python3 scripts/gen_golden.py

build:
	cargo build

test:
	cargo test --workspace

clippy:
	cargo clippy --workspace --all-targets -- -D warnings

fmt:
	cargo fmt --check

check: gen hooks
	git diff --exit-code crates/accretion-core/src/constants.rs
	git diff --exit-code crates/accretion-core/tests/fixtures/golden.json
	sh scripts/check_invariants.sh
	cargo test --workspace
	cargo clippy --workspace --all-targets -- -D warnings
	cargo build
	@if command -v $(GODOT_BIN) >/dev/null 2>&1; then \
		$(GODOT_BIN) --headless --quit --path . ; \
	else \
		echo "WARN: $(GODOT_BIN) not on PATH; skipping Godot headless load test"; \
	fi
