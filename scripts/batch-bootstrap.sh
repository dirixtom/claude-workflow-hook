#!/bin/bash
# Bootstrap all existing projects under a root folder that lack a CLAUDE.md.
# Usage: ./scripts/batch-bootstrap.sh ~/Development/git-personal
set -euo pipefail

ROOT="${1:?Usage: batch-bootstrap.sh <projects-root>}"

command -v claude >/dev/null 2>&1 || { echo "ERROR: 'claude' CLI not found on PATH"; exit 1; }

for d in "$ROOT"/*/; do
  [ -d "$d/.git" ] || continue
  if [ -f "$d/CLAUDE.md" ] || [ -f "$d/.claude/CLAUDE.md" ]; then
    echo "-- skip (already configured): $d"
    continue
  fi
  echo "==> Bootstrapping: $d"
  (cd "$d" && claude -p "/sync-claude-config" --permission-mode acceptEdits) || echo "!! failed: $d"
done

echo "Done. Review each repo's CLAUDE.md and .claude/settings.json, then commit and push."
