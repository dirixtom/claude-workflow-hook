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
REPO_OWNER="${REPO%%/*}"
REPO_NAME="${REPO##*/}"

# Note: CONTEXT is interpolated into JSON by the printf below, so it must not
# contain double quotes, backslashes, backticks or newlines.
CONTEXT="BOOTSTRAP REQUIRED: This project has no CLAUDE.md or .claude/settings.json. Before starting the user's task, scaffold them from the template repo. Step 1: fetch templates/CLAUDE.md from $REPO using whichever transport works in this environment, in order: (a) gh CLI - gh api -H 'Accept: application/vnd.github.raw' repos/$REPO/contents/templates/CLAUDE.md; (b) GitHub MCP server, for cloud, mobile and web sessions that have no gh CLI - call mcp__github__get_file_contents with owner: $REPO_OWNER, repo: $REPO_NAME, path: templates/CLAUDE.md, loading its schema first via ToolSearch select:mcp__github__get_file_contents if needed, and if the repo is reported out of scope add it via mcp__claude-code-remote__add_repo with owner: $REPO_OWNER, repo: $REPO_NAME and retry; (c) a local clone of $REPO if one exists on this machine, read from its templates directory. Step 2: inspect this codebase (stack, package manager, build/test/lint commands, folder structure) and write ./CLAUDE.md based on the template - remove sections irrelevant to this repo and add a project-specific section with the info you discovered. Step 3: fetch templates/settings.json from $REPO the same way and write .claude/settings.json - strip machine-specific entries (absolute paths, the SessionStart bootstrap hook itself) and keep only project-relevant permissions and hooks. Step 4: show the user both files for review and offer to commit them so other machines and cloud sessions pick them up. Only skip bootstrapping if every transport in Step 1 fails - then tell the user which ones you tried and why each failed."

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$CONTEXT"
exit 0
