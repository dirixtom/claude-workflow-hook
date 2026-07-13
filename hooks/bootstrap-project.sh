#!/bin/bash
# SessionStart hook: detect projects without Claude config and instruct Claude
# to scaffold CLAUDE.md + .claude/settings.json from the remote template repo.
# Installed to ~/.claude/hooks/ by install.sh from https://github.com/dirixtom/claude-workflow-hook

DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# Already bootstrapped? Stay silent.
if [ -f "$DIR/CLAUDE.md" ] || [ -f "$DIR/.claude/CLAUDE.md" ]; then
  exit 0
fi

# Only bootstrap real git repos, not scratch folders.
if [ ! -d "$DIR/.git" ]; then
  exit 0
fi

REPO="dirixtom/claude-workflow-hook"

CONTEXT="BOOTSTRAP REQUIRED: This project has no CLAUDE.md or .claude/settings.json. Before starting the user's task, scaffold them from the template repo. Step 1: fetch the CLAUDE.md template by running: gh api -H 'Accept: application/vnd.github.raw' repos/$REPO/contents/templates/CLAUDE.md. Step 2: inspect this codebase (stack, package manager, build/test/lint commands, folder structure) and write ./CLAUDE.md based on the template - remove sections irrelevant to this repo and add a project-specific section with the info you discovered. Step 3: fetch repos/$REPO/contents/templates/settings.json the same way and write .claude/settings.json - strip machine-specific entries (absolute paths, the SessionStart bootstrap hook itself) and keep only project-relevant permissions and hooks. Step 4: show the user both files for review and offer to commit them so other machines and cloud sessions pick them up. If gh is unavailable or not authenticated, tell the user and skip bootstrapping."

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$CONTEXT"
exit 0
