# agent-template

Canonical home for the kplan + sprint skills (Codex + Claude Code) and
the docs/principles/standards that every repo I work in inherits.

## Skills

Two skills live here as the version-controlled source of truth:

- `.codex/skills/kplan/SKILL.md` — multi-agent sprint planning (orient,
  intent, draft, interview, critique, merge). Phase 6 (Merge) requires
  every final sprint document include a `## Documentation Manifest`
  section enumerating every NEW ADR + amended ADR + cross-cutting doc.
- `.codex/skills/sprint/SKILL.md` — sprint implementation gate. Step 4
  re-reads the Documentation Manifest before staging the completion
  commit and refuses to proceed if any listed file didn't change.

Claude Code mirrors of both live at `.claude/commands/{kplan,sprint}.md`
with the agent roles swapped (Claude drafts → Codex critiques in the
Claude version; Codex drafts → Claude Code critiques in the Codex
version). The Documentation Manifest contract is identical on both
sides.

## Install (one machine, all repos)

These skills run at user level (`~/.codex/skills/` and
`~/.claude/commands/`) so editing them here propagates to every repo
on this machine without a per-repo commit:

```bash
bin/install-skills.sh
```

The script symlinks the four files from this repo into the user-level
locations. Idempotent — running twice is a no-op. Use `--force` to
replace existing real files or stale symlinks, or `--dry-run` to print
what would happen.

## Editing a skill

1. Edit `.codex/skills/<skill>/SKILL.md` or `.claude/commands/<name>.md`
   in this repo.
2. Commit + push (this repo is the audit trail).
3. The change is live for every repo on this machine immediately — the
   symlinks resolve to the edited file on next read.

## Why user-level over per-repo

Earlier the kplan + sprint files were copied into each consuming repo.
They drifted: I'd update one repo, forget the others, and a future
session in a stale repo would silently use an older skill. User-level
+ symlink-to-this-repo means there is exactly one source of truth +
zero propagation step.

## Bootstrap on a new machine

```bash
git clone git@github.com:karimfan/agent-template.git ~/src/agent-template
cd ~/src/agent-template
bin/install-skills.sh
```

After that, every new repo I `cd` into automatically has `/kplan` and
`/sprint` available.

## Repo layout

```
.claude/
  commands/
    kplan.md       — Claude Code slash command (Claude drafts, Codex critiques)
    sprint.md
.codex/
  skills/
    kplan/SKILL.md  — Codex skill (Codex drafts, Claude Code critiques)
    sprint/SKILL.md
bin/
  install-skills.sh — user-level symlink installer
docs/
  ...               — principles, standards, conventions inherited by consuming repos
```
