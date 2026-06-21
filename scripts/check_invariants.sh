#!/bin/sh
# Mechanical invariant checks (C1–C6). Exits non-zero on first failure.
set -e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

echo "C1: constants.rs is generated and byte-stable"
test -f crates/accretion-core/src/constants.rs
python3 scripts/gen_constants.py
git diff --exit-code crates/accretion-core/src/constants.rs

echo "C2: no scientific-notation literals outside constants.rs"
if grep -rEn '[0-9]+\.?[0-9]*[eE][+-]?[0-9]+' crates/accretion-core/src --include='*.rs' \
  | grep -v 'crates/accretion-core/src/constants.rs'; then
  echo "FAIL: e-notation literal found outside constants.rs"
  exit 1
fi

echo "C3: golden.json is generated and byte-stable"
test -f crates/accretion-core/tests/fixtures/golden.json
python3 scripts/gen_golden.py
git diff --exit-code crates/accretion-core/tests/fixtures/golden.json

echo "C4: no scientific-notation literals in integration tests"
if grep -rEn '[0-9]+\.?[0-9]*[eE][+-]?[0-9]+' crates/accretion-core/tests --include='*.rs'; then
  echo "FAIL: e-notation literal found in tests"
  exit 1
fi

echo "C5: gdext API pin matches compatibility_minimum"
feat=$(grep -oE 'api-4-[0-9]+' crates/godot-ext/Cargo.toml | head -1)
test -n "$feat"
ver=$(printf '%s' "$feat" | sed 's/api-4-/4./')
cm=$(grep -oE 'compatibility_minimum[[:space:]]*=[[:space:]]*[0-9.]+' accretion.gdextension | grep -oE '[0-9.]+$')
test "$ver" = "$cm"

echo "C6: accretion-core has zero godot in dependency tree"
if cargo tree -p accretion-core 2>/dev/null | grep -qi '^.*godot'; then
  echo "FAIL: godot found in accretion-core tree"
  exit 1
fi

echo "C7: no physics formulas in GDScript or shaders (presentation boundary)"
python3 <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(".")
PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("Kerr horizon leak", re.compile(r"sqrt\s*\(\s*max\s*\(\s*1\.0\s*-\s*spin", re.I)),
    ("Shakura-Sunyaev literal", re.compile(r"shakura|sunyaev", re.I)),
    ("Stefan-Boltzmann in presentation", re.compile(r"sigma_sb|sigma_t\b", re.I)),
    ("ISCO closed form in presentation", re.compile(r"3\.0\s*\+\s*z2\s*-\s*\(\(", re.I)),
]
SCAN_DIRS = [ROOT / "scripts", ROOT / "shaders"]
SKIP = {"presentation_tests.gd"}


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


for base in SCAN_DIRS:
    if not base.is_dir():
        continue
    for path in sorted(base.rglob("*")):
        if path.suffix not in {".gd", ".gdshader"}:
            continue
        if path.name in SKIP:
            continue
        text = path.read_text(encoding="utf-8")
        for label, pat in PATTERNS:
            m = pat.search(text)
            if m:
                line = text.count("\n", 0, m.start()) + 1
                fail(f"{path.relative_to(ROOT)}:{line} matches {label!r}")

print("C7 OK")
PY

echo "All invariant checks passed."
