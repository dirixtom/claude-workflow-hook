#!/bin/bash
# One-shot installer for claude-workflow-hook. Run this on your Mac:
#   cd ~/Development/git-personal/claude-workflow-hook && bash install.sh
#
# It will:
#   1. Import your ~/.claude/CLAUDE.md and ~/.claude/settings.json as repo templates (first run only)
#   2. Fill in your GitHub username in the hook and slash command
#   3. Install the SessionStart hook script to ~/.claude/hooks/
#   4. Register the hook in ~/.claude/settings.json (safe merge, no overwrite)
#   5. Install the /sync-claude-config slash command to ~/.claude/commands/
#   6. Create a private GitHub repo and push
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
REPO_NAME="claude-workflow-hook"

echo "==> claude-workflow-hook installer"

# --- Preflight -------------------------------------------------------------
command -v gh >/dev/null 2>&1 || { echo "ERROR: GitHub CLI (gh) is required. Install: brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: gh is not authenticated. Run: gh auth login"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required."; exit 1; }

OWNER="$(gh api user -q .login)"
SLUG="$OWNER/$REPO_NAME"
echo "GitHub user: $OWNER"

# --- 1. Import templates (first run only) ----------------------------------
mkdir -p "$REPO_DIR/templates"

if [ ! -f "$REPO_DIR/templates/CLAUDE.md" ]; then
  if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$CLAUDE_DIR/CLAUDE.md" "$REPO_DIR/templates/CLAUDE.md"
    echo "Imported ~/.claude/CLAUDE.md -> templates/CLAUDE.md"
  else
    cat > "$REPO_DIR/templates/CLAUDE.md" <<'TPL'
# CLAUDE.md

## About me
<!-- Who you are, how you like Claude to work -->

## General preferences
- Be concise and direct.
- Prefer small, reviewable changes; explain non-obvious decisions.

## Git conventions
- Conventional commit messages; never force-push main.

## Project-specific
<!-- Filled in per repo at bootstrap time -->
TPL
    echo "No ~/.claude/CLAUDE.md found - wrote a starter template instead. Edit templates/CLAUDE.md."
  fi
else
  echo "templates/CLAUDE.md already exists - keeping it."
fi

if [ ! -f "$REPO_DIR/templates/settings.json" ]; then
  if [ -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$REPO_DIR/templates/settings.json"
    echo "Imported ~/.claude/settings.json -> templates/settings.json"
    echo "NOTE: review templates/settings.json before pushing - remove anything secret or machine-specific."
  else
    printf '{\n  "permissions": {\n    "allow": [],\n    "deny": []\n  }\n}\n' > "$REPO_DIR/templates/settings.json"
    echo "No ~/.claude/settings.json found - wrote a minimal starter."
  fi
else
  echo "templates/settings.json already exists - keeping it."
fi

# --- 2. Fill in repo slug placeholders -------------------------------------
replace_slug() {
  local f="$1"
  if grep -q "__REPO_SLUG__" "$f" 2>/dev/null; then
    if sed --version >/dev/null 2>&1; then
      sed -i "s|__REPO_SLUG__|$SLUG|g" "$f"        # GNU sed (Linux)
    else
      sed -i '' "s|__REPO_SLUG__|$SLUG|g" "$f"     # BSD sed (macOS)
    fi
    echo "Set repo slug in $(basename "$f")"
  fi
}
replace_slug "$REPO_DIR/hooks/bootstrap-project.sh"
replace_slug "$REPO_DIR/commands/sync-claude-config.md"
replace_slug "$REPO_DIR/README.md"

# --- 3. Install hook script ------------------------------------------------
mkdir -p "$CLAUDE_DIR/hooks"
cp "$REPO_DIR/hooks/bootstrap-project.sh" "$CLAUDE_DIR/hooks/bootstrap-project.sh"
chmod +x "$CLAUDE_DIR/hooks/bootstrap-project.sh"
echo "Installed ~/.claude/hooks/bootstrap-project.sh"

# --- 4. Register SessionStart hook in ~/.claude/settings.json --------------
python3 - "$CLAUDE_DIR/settings.json" <<'PY'
import json, os, sys

path = sys.argv[1]
cfg = {}
if os.path.exists(path):
    with open(path) as f:
        cfg = json.load(f)

cmd = "bash " + os.path.expanduser("~/.claude/hooks/bootstrap-project.sh")
ss = cfg.setdefault("hooks", {}).setdefault("SessionStart", [])

already = any(
    h.get("command", "").endswith("bootstrap-project.sh")
    for m in ss for h in m.get("hooks", [])
)
if already:
    print("SessionStart hook already registered - skipping.")
else:
    ss.append({"hooks": [{"type": "command", "command": cmd}]})
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("Registered SessionStart hook in ~/.claude/settings.json")
PY

# --- 5. Install slash command ----------------------------------------------
mkdir -p "$CLAUDE_DIR/commands"
cp "$REPO_DIR/commands/sync-claude-config.md" "$CLAUDE_DIR/commands/sync-claude-config.md"
echo "Installed /sync-claude-config slash command"

# --- 6. Git init, create private repo, push --------------------------------
cd "$REPO_DIR"
if [ ! -d .git ]; then
  git init -b main >/dev/null
  echo "Initialized git repo"
fi
chmod +x install.sh hooks/bootstrap-project.sh scripts/batch-bootstrap.sh 2>/dev/null || true
git add -A
git commit -m "claude-workflow-hook: templates, SessionStart hook, sync command" >/dev/null 2>&1 \
  && echo "Committed changes" || echo "Nothing new to commit"

if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin main
  echo "Pushed to existing remote"
else
  gh repo create "$REPO_NAME" --private --source . --remote origin --push
  echo "Created private repo https://github.com/$SLUG and pushed"
fi

echo ""
echo "==> Done. Next steps:"
echo "  - New/unconfigured projects: just open them in Claude Code; the hook bootstraps them."
echo "  - Existing projects in bulk:  bash scripts/batch-bootstrap.sh <projects-root>"
echo "  - Manual (cloud/mobile/any):  run /sync-claude-config inside the project."
echo "  - Commit the generated CLAUDE.md + .claude/settings.json in each repo for handoff."
