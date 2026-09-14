# claude-workflow-hook

Distribution mechanism for my Claude Code config. A SessionStart hook notices a git repo with no
`CLAUDE.md`, tells Claude to fetch `templates/` from this repo, tailor them to that project, and
offer to commit the result — so the config survives handoff to cloud, mobile and other machines.

There is no build, no package manager, no dependency tree. The deliverables are **bash scripts and
markdown**, plus a short embedded `python3` program in each of `hooks/bootstrap-project.sh` and
`install.sh`. Nothing here is compiled, bundled or published.

## Layout

| Path | What it is | Reaches a machine via |
|---|---|---|
| `hooks/bootstrap-project.sh` | SessionStart hook; emits the bootstrap instructions | `install.sh` copies it to `~/.claude/hooks/` |
| `commands/sync-claude-config.md` | `/sync-claude-config` slash command | `install.sh` copies it to `~/.claude/commands/` |
| `templates/CLAUDE.md` | Master CLAUDE.md template | Fetched from GitHub at bootstrap time |
| `templates/settings.json` | Master settings template | Fetched from GitHub at bootstrap time |
| `scripts/batch-bootstrap.sh` | One-shot bootstrap of every repo under a root | Run from a clone |
| `install.sh` | Idempotent per-machine installer | Run from a clone |

**Propagation is not uniform, and it decides how a change ships.** Edits under `templates/` are live
the moment they land on `main` — they are fetched over the network, so nothing needs reinstalling.
Edits to the hook or the slash command are inert until `bash install.sh` runs again on each computer,
because those are *copies* in `~/.claude/`. When you change the hook, say so in the summary: the user
has to re-run the installer, and until then their machine keeps running the old copy.

## Target bash is 3.2, not your shell

macOS ships **bash 3.2.57 (2007)** as `/bin/bash`, and every script here has a `#!/bin/bash` shebang,
so that is the interpreter — not whatever modern bash is on `PATH`. Assume 3.2 for anything in
`hooks/`, `scripts/` or `install.sh`.

This is not theoretical. `CONTEXT="$(cat <<'EOF' ... )"` looks fine and works on bash 4+, but 3.2
scans `$( )` for the closing paren while tracking quote state and does not know a quoted heredoc body
is literal — so the apostrophe in *"the user's task"* left it mid-string, it ran past the closing
paren, and the hook died with a syntax error before emitting anything. It was broken on every macOS
session until `ec47230`. Read heredocs into a variable with `IFS= read -r -d '' VAR <<'EOF' || true`
instead; no command substitution, so the body can hold any character.

Also unavailable in 3.2: `declare -A`, `mapfile` / `readarray`, `${var^^}` / `${var,,}`,
`${arr[-1]}`, `&>>`, `|&`, `;;&`, and `globstar` / `**`.

Verify with the real interpreter, never a brew bash:

```bash
for f in install.sh hooks/bootstrap-project.sh scripts/batch-bootstrap.sh; do /bin/bash -n "$f" || echo "FAIL $f"; done
```

## The hook's output contract

Claude Code parses the hook's **stdout as JSON**. Anything else printed — a stray `echo`, a warning,
a debug line — either corrupts the payload or lands verbatim in the session context. So every path
that is not "emit the bootstrap instructions" prints nothing at all and exits 0: an already-configured
project, a non-git directory, a missing `python3`.

The instruction text lives in a quoted heredoc and `json.dumps` builds the payload, so the text needs
no escaping. Two rules when editing it:

- Reference the repo through the `{{REPO}}` / `{{REPO_OWNER}}` / `{{REPO_NAME}}` placeholders, which
  are substituted at emit time — not shell variables, which a quoted heredoc will not expand.
- Keep the heredoc quoted (`<<'EOF'`). Unquoting it reintroduces shell interpolation over prose that
  contains `$`, backticks and `$(...)`.

## Checking a change

There is no test runner. Run these three by hand before opening a PR; they are the whole suite.

```bash
for f in install.sh hooks/bootstrap-project.sh scripts/batch-bootstrap.sh; do /bin/bash -n "$f" || echo "FAIL $f"; done
```

```bash
d="$(mktemp -d)/repo"; mkdir -p "$d/.git"; CLAUDE_PROJECT_DIR="$d" /bin/bash hooks/bootstrap-project.sh | python3 -m json.tool
```

```bash
d="$(mktemp -d)/repo"; mkdir -p "$d/.git"; touch "$d/CLAUDE.md"; CLAUDE_PROJECT_DIR="$d" /bin/bash hooks/bootstrap-project.sh | wc -c
```

The second must print valid JSON with every `{{...}}` placeholder substituted; the third must print
`0`. When changing the hook's prose, diff the emitted `additionalContext` against the previous one
rather than eyeballing the script — that is the artifact that actually ships.

`install.sh` is idempotent by design and re-run constantly; keep it that way. It requires `gh`
(authenticated) and `python3`. The hook itself needs only `python3`, and the slash command needs
neither — that asymmetry is deliberate, since cloud and mobile sessions have no `gh`.

## Secrets

`install.sh` seeds `templates/settings.json` by copying `~/.claude/settings.json` wholesale on first
run. That file routinely holds machine-specific paths, `env` blocks and API keys. **Review
`templates/settings.json` before every push** — it is a public repo, and the import step is the one
place where a personal secret can walk into it. Absolute paths, `env`, `statusLine` and the
SessionStart hook registration itself do not belong in the template.

## Git Workflow

Never commit directly to `main`/`master`. Always branch first, pull latest `main` beforehand.
Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `tree/` + short description, always name a branch after the feature being implemented.
Never force-push to `main`. Never `--no-verify` without explicit instruction.

## Session naming

Session titles are short, descriptive and **start with a verb-led phrase** that names the
work being done — not a noun-pile echo of the prompt's keywords.

Shape: `<Verb phrase> <what it is about>`. Typical openers: `Spec ...`,
`Implementation of ...`, `Report on ...`, `Analyze ...`, `Review ...`, `Grill ...`,
`Wayfinder ...`, `Bugfix ...`, `Deploy ...`, `Triage ...`.

Name the session after the **subject of the work**, not the mechanics of the request. When
the prompt points at an issue or a ticket, resolve what that issue actually is and name the
feature — an issue number on its own says nothing.

| Prompt | Not this | This |
| --- | --- | --- |
| "Give me an overview of all issues and their dependencies" | `Repository issues dependency overview` | `Report on issue overview & dependencies` |
| "Work the #185 map tickets" | `Map tickets #185` | `Implementation of <the feature #185 is about>` |
| "#207" | `Issue #207` | `Bugfix of <what #207 is about>` |

## Compact Instructions

When compacting: preserve the full list of modified files, errors, and pending decisions.
