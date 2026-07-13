# claude-workflow-hook

Automatic Claude Code project bootstrapping that survives handoff to cloud, mobile, or other machines.

**Template repo:** `dirixtom/claude-workflow-hook` (private) — the single source of truth for `templates/CLAUDE.md` and `templates/settings.json`.

## How it works

1. **SessionStart hook** (`~/.claude/hooks/bootstrap-project.sh`, installed on each of your computers): when you open a git repo that has no `CLAUDE.md`, it injects instructions telling Claude to fetch the templates from this repo via `gh api`, tailor `CLAUDE.md` to the project (strip irrelevant sections, add stack/build/test info discovered from the codebase), write a project-appropriate `.claude/settings.json`, and offer to commit both.
2. **Committed config as handoff vehicle**: once `CLAUDE.md` and `.claude/settings.json` are committed, every environment that clones the repo — cloud, mobile, another laptop — picks them up automatically. Nothing machine-local is required after that.
3. **`/sync-claude-config` slash command**: manual trigger for environments without the hook (cloud/mobile) and for merging template updates into repos that already have a `CLAUDE.md`.

## Install (once per computer)

```bash
git clone https://github.com/dirixtom/claude-workflow-hook.git
cd claude-workflow-hook
bash install.sh
```

Requires `gh` (authenticated) and `python3`. The installer is idempotent — safe to re-run.

On first run it also imports your existing `~/.claude/CLAUDE.md` and `~/.claude/settings.json` into `templates/`. **Review `templates/settings.json` before pushing** — remove secrets or machine-specific paths.

## Usage

| Scenario | What to do |
|---|---|
| New or unconfigured project (local) | Nothing — open it in Claude Code, the hook bootstraps it |
| Existing projects in bulk | `bash scripts/batch-bootstrap.sh ~/Development/git-personal` |
| Cloud / mobile / no hook installed | Run `/sync-claude-config` in the project (needs the command installed, or just paste its instructions) |
| Project already has CLAUDE.md, template changed | `/sync-claude-config` merges template updates, keeping project-specific content |
| Update the template | Edit `templates/*`, commit, push — all future bootstraps/syncs use it |

## Repo layout

```
hooks/bootstrap-project.sh    SessionStart hook (installed to ~/.claude/hooks/)
commands/sync-claude-config.md  Slash command (installed to ~/.claude/commands/)
templates/CLAUDE.md           Master CLAUDE.md template (created by install.sh)
templates/settings.json       Master settings template (created by install.sh)
scripts/batch-bootstrap.sh    One-time bootstrap of all existing repos
install.sh                    Idempotent installer
```

## Notes

- Settings precedence: `~/.claude/settings.json` (user) < `.claude/settings.json` (project, committed) < `.claude/settings.local.json` (machine-local, gitignored). Arrays like `permissions.allow` are merged, so project settings only need project-specific rules.
- The bootstrap instructions explicitly tell Claude to strip the SessionStart hook itself from project settings, so the hook never duplicates into repos.
- The hook only fires in git repos without a `CLAUDE.md`; configured projects are untouched.
