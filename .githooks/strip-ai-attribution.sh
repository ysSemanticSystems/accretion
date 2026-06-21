#!/bin/sh
# Strip AI-tool attribution from a commit-message file.
# Usage: strip-ai-attribution.sh <path-to-commit-msg-file>
#   - removes `Co-authored-by:` trailers naming Cursor (case-insensitive)
#   - removes standalone "Generated with ... Cursor" attribution lines
#   - collapses any resulting trailing blank lines
# Always exits 0. Idempotent. No `sed -i` (BSD/macOS portability).

msg="$1"
[ -n "$msg" ] && [ -f "$msg" ] || exit 0

tmp=$(mktemp) || exit 0

sed -e '/^[Cc]o-authored-by:.*[Cc]ursor/d' \
    -e '/[Gg]enerated with.*[Cc]ursor/d' \
    "$msg" > "$tmp" 2>/dev/null || { rm -f "$tmp"; exit 0; }

# Remove trailing blank lines left behind by deletions.
awk '
  { lines[NR] = $0 }
  END {
    last = NR
    while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
    for (i = 1; i <= last; i++) print lines[i]
  }
' "$tmp" > "$msg" 2>/dev/null

rm -f "$tmp"
exit 0
