#!/bin/sh
# Wiki structure checks (W1–W8). Exits non-zero on first failure.
set -e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT"

python3 <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(".")
WIKI = ROOT / "wiki"
MANIFEST = WIKI / "manifest.yaml"
RULES = ROOT / ".cursor" / "rules"

EXEMPT = {
    WIKI / "README.md",
    WIKI / "features" / "_template.md",
}

REQUIRED_FIELDS = ("id", "title", "status", "layer", "depends_on", "last_reviewed")
FEATURE_EXTRA = ("acceptance", "implements", "blocks")
MAX_MDC_LINES = 25


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def warn(msg: str) -> None:
    print(f"WARN: {msg}")


def parse_frontmatter(text: str) -> dict | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end == -1:
        return None
    block = text[4:end]
    data: dict = {}
    current_key = None
    current_list: list | None = None
    for line in block.splitlines():
        if re.match(r"^\s+-\s+", line) and current_list is not None:
            current_list.append(re.sub(r"^\s+-\s+", "", line).strip().strip('"'))
            continue
        m = re.match(r"^(\w+):\s*(.*)$", line)
        if not m:
            continue
        key, val = m.group(1), m.group(2).strip()
        if val == "" or val == "[]":
            data[key] = []
            current_key = key
            current_list = data[key]
        elif val.startswith("[") and val.endswith("]"):
            inner = val[1:-1].strip()
            if not inner:
                data[key] = []
            else:
                data[key] = [x.strip().strip('"') for x in inner.split(",")]
            current_key = key
            current_list = None
        else:
            data[key] = val.strip('"')
            current_key = key
            current_list = None
    return data


def load_manifest() -> dict[str, str]:
    if not MANIFEST.is_file():
        fail("wiki/manifest.yaml missing")
    pages: dict[str, str] = {}
    current_id = None
    for line in MANIFEST.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\s+-\s+id:\s+(\S+)\s*$", line)
        if m:
            current_id = m.group(1)
            continue
        m = re.match(r"^\s+path:\s+(\S+)\s*$", line)
        if m and current_id:
            pages[current_id] = m.group(1)
            current_id = None
    if not pages:
        fail("manifest.yaml has no pages")
    return pages


print("W1: required frontmatter on wiki pages")
wiki_pages: dict[Path, dict] = {}
for path in sorted(WIKI.rglob("*.md")):
    if path in EXEMPT:
        continue
    text = path.read_text(encoding="utf-8")
    fm = parse_frontmatter(text)
    if fm is None:
        fail(f"missing frontmatter: {path.relative_to(ROOT)}")
    for field in REQUIRED_FIELDS:
        if field not in fm:
            fail(f"{path.relative_to(ROOT)} missing frontmatter field '{field}'")
    if fm.get("layer") == "features" or path.parent.name == "features":
        if path.name == "_template.md":
            continue
        for field in FEATURE_EXTRA:
            if field not in fm:
                fail(f"{path.relative_to(ROOT)} missing feature field '{field}'")
    if fm.get("id") != path.stem and not path.name.startswith("F"):
        # allow overview.md etc — id comes from frontmatter, not filename
        pass
    wiki_pages[path] = fm

print("W2: manifest.yaml matches wiki pages")
manifest = load_manifest()
manifest_paths = {WIKI / p for p in manifest.values()}
wiki_paths = set(wiki_pages.keys())
if len(manifest) != len(set(manifest.values())):
    fail("duplicate paths in manifest.yaml")
if len(manifest) != len(manifest.values()):
    fail("duplicate ids in manifest.yaml")
for path in wiki_paths:
    rel = path.relative_to(WIKI).as_posix()
    if rel not in manifest.values():
        fail(f"orphan wiki page not in manifest: {rel}")
for mid, rel in manifest.items():
    p = WIKI / rel
    if p not in wiki_paths:
        fail(f"manifest entry missing file: {rel}")
    if wiki_pages[p].get("id") != mid:
        fail(f"manifest id '{mid}' != frontmatter id '{wiki_pages[p].get('id')}' in {rel}")

print("W3: internal wiki links resolve")
link_re = re.compile(r"\]\(([^)#]+)\)")
for path, fm in wiki_pages.items():
    text = path.read_text(encoding="utf-8")
    for target in link_re.findall(text):
        if target.startswith("http") or target.startswith("#"):
            continue
        if target.startswith("wiki/"):
            resolved = ROOT / target
        else:
            resolved = (path.parent / target).resolve()
        if not resolved.is_file():
            fail(f"broken link in {path.relative_to(ROOT)}: {target}")

print("W4: depends_on and blocks reference valid ids")
valid_ids = {fm["id"] for fm in wiki_pages.values()}
for path, fm in wiki_pages.items():
    for key in ("depends_on", "blocks"):
        for dep in fm.get(key, []) or []:
            if dep and dep not in valid_ids:
                fail(f"{path.relative_to(ROOT)}: {key} references unknown id '{dep}'")

print("W5: status implemented requires non-empty implements")
for path, fm in wiki_pages.items():
    if fm.get("status") == "implemented":
        impl = fm.get("implements", [])
        if not impl:
            fail(f"{path.relative_to(ROOT)}: status implemented but implements is empty")

print("W6: locked-decisions active with last_reviewed")
locked = WIKI / "game-design" / "locked-decisions.md"
if locked not in wiki_pages:
    fail("locked-decisions.md missing")
ld = wiki_pages[locked]
if ld.get("status") != "active":
    fail("locked-decisions.md must have status: active")
if not ld.get("last_reviewed"):
    fail("locked-decisions.md missing last_reviewed")

print("W7: .cursor/rules are thin pointers")
if RULES.is_dir():
    for mdc in sorted(RULES.glob("*.mdc")):
        lines = mdc.read_text(encoding="utf-8").splitlines()
        if len(lines) > MAX_MDC_LINES:
            fail(f"{mdc.relative_to(ROOT)} has {len(lines)} lines (max {MAX_MDC_LINES})")

print("W8: root docs link to wiki/README.md")
for doc in (ROOT / "AGENTS.md", ROOT / "CONTRIBUTING.md"):
    if not doc.is_file():
        fail(f"{doc.name} missing")
    if "wiki/README.md" not in doc.read_text(encoding="utf-8"):
        fail(f"{doc.name} must link to wiki/README.md")

print("All wiki checks passed.")
PY
