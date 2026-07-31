---
description: Bootstrap or sync this repo's CLAUDE.md and .claude/settings.json from my claude-workflow-hook template
---

Bootstrap or sync this project's Claude configuration from my template repo (`dirixtom/claude-workflow-hook`).

1. Fetch the templates. Use whichever transport is available in this environment — try them in order and stop at the first that works:

   **a. `gh` CLI** (local machines):
   - `gh api -H 'Accept: application/vnd.github.raw' repos/dirixtom/claude-workflow-hook/contents/templates/CLAUDE.md`
   - `gh api -H 'Accept: application/vnd.github.raw' repos/dirixtom/claude-workflow-hook/contents/templates/settings.json`

   **b. GitHub MCP server** (cloud, mobile, web sessions — no `gh` CLI there): call `mcp__github__get_file_contents` twice with `owner: dirixtom`, `repo: claude-workflow-hook`, and `path: templates/CLAUDE.md` then `path: templates/settings.json`. Load the schema first with `ToolSearch` (`select:mcp__github__get_file_contents`) if the tool isn't already available. If the MCP server reports the repo is out of scope, add it with `mcp__claude-code-remote__add_repo` (`owner: dirixtom`, `repo: claude-workflow-hook`) and retry.

   **c. Local clone** (last resort): if `dirixtom/claude-workflow-hook` happens to be checked out on this machine, read `templates/CLAUDE.md` and `templates/settings.json` directly from it.
2. If this repo has **no** `CLAUDE.md`: inspect the codebase (stack, package manager, build/test/lint commands, folder structure) and write `./CLAUDE.md` based on the template. Remove template sections irrelevant to this repo and add a project-specific section with what you discovered.
3. If this repo **already has** a `CLAUDE.md`: merge instead. Keep all project-specific content, update/add the general sections from the template, and remove anything the template has since dropped. Show a summary of what changed.
4. Write `.claude/settings.json` from the settings template (or merge with the existing one). Strip machine-specific entries: absolute paths and the SessionStart bootstrap hook itself. Keep only project-relevant permissions and hooks.
5. Show me both files for review, then offer to commit them.

Only stop if **every** transport in step 1 fails — then say which ones you tried and why each failed.
