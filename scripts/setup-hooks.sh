#!/bin/sh
# Wire the tracked hooks for this clone. Re-run after every fresh clone.
# core.hooksPath lives in .git/config, which is NOT cloned, so this is the
# single command that makes the AI-attribution hook reproducible.
set -e
repo_root=$(git rev-parse --show-toplevel)
chmod +x "$repo_root/.githooks/"* "$repo_root/scripts/setup-hooks.sh"
git config core.hooksPath .githooks
echo "Hooks wired: core.hooksPath -> .githooks"
