---
description: Bootstrap or sync this repo's CLAUDE.md and .claude/settings.json from my claude-workflow-hook template
---

Bootstrap or sync this project's Claude configuration from my template repo (`dirixtom/claude-workflow-hook`).

1. Fetch the templates:
   - `gh api -H 'Accept: application/vnd.github.raw' repos/dirixtom/claude-workflow-hook/contents/templates/CLAUDE.md`
   - `gh api -H 'Accept: application/vnd.github.raw' repos/dirixtom/claude-workflow-hook/contents/templates/settings.json`
2. If this repo has **no** `CLAUDE.md`: inspect the codebase (stack, package manager, build/test/lint commands, folder structure) and write `./CLAUDE.md` based on the template. Remove template sections irrelevant to this repo and add a project-specific section with what you discovered.
3. If this repo **already has** a `CLAUDE.md`: merge instead. Keep all project-specific content, update/add the general sections from the template, and remove anything the template has since dropped. Show a summary of what changed.
4. Write `.claude/settings.json` from the settings template (or merge with the existing one). Strip machine-specific entries: absolute paths and the SessionStart bootstrap hook itself. Keep only project-relevant permissions and hooks.
5. Show me both files for review, then offer to commit them.

If `gh` is unavailable or not authenticated, say so and stop.
