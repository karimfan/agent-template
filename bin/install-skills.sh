#!/usr/bin/env bash
# install-skills.sh — symlink agent-template's kplan + sprint skills into
# the user-level locations so Codex and Claude Code see them from every
# repo on this machine.
#
# After this runs:
#   ~/.codex/skills/kplan        → <agent-template>/.codex/skills/kplan
#   ~/.codex/skills/sprint       → <agent-template>/.codex/skills/sprint
#   ~/.claude/commands/kplan.md  → <agent-template>/.claude/commands/kplan.md
#   ~/.claude/commands/sprint.md → <agent-template>/.claude/commands/sprint.md
#
# Editing the canonical files in this repo updates the live behavior for
# every repo immediately — symlinks resolve on read.
#
# Idempotent: running this twice is safe. If a target already points at
# the right source, it's left alone; if it points elsewhere (a stale or
# per-repo copy that was supposed to be removed), the script prints a
# warning and skips that target rather than clobbering.
#
# Usage:
#   bin/install-skills.sh           # link both skills (kplan + sprint)
#   bin/install-skills.sh --force   # replace pre-existing files/links
#   bin/install-skills.sh --dry-run # print what would happen, change nothing

set -euo pipefail

FORCE=0
DRYRUN=0
for arg in "$@"; do
  case "$arg" in
    --force)   FORCE=1 ;;
    --dry-run) DRYRUN=1 ;;
    -h|--help)
      sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

# Resolve the agent-template root from this script's own location so it
# works no matter where the user invokes it from.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_ROOT="$(dirname "$SCRIPT_DIR")"

if [ ! -d "$TEMPLATE_ROOT/.codex/skills" ] || [ ! -d "$TEMPLATE_ROOT/.claude/commands" ]; then
  echo "ERROR: $TEMPLATE_ROOT doesn't look like agent-template (missing .codex or .claude)" >&2
  exit 1
fi

link() {
  local src="$1"
  local dst="$2"

  if [ -L "$dst" ]; then
    # Existing symlink. Check whether it already points at us.
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "ok    $dst (already linked)"
      return
    fi
    if [ "$FORCE" -eq 0 ]; then
      echo "skip  $dst → $current (use --force to replace)" >&2
      return
    fi
    [ "$DRYRUN" -eq 1 ] || rm "$dst"
    echo "relink $dst → $src"
  elif [ -e "$dst" ]; then
    # Real file or directory in the way.
    if [ "$FORCE" -eq 0 ]; then
      echo "skip  $dst (real file/dir present; use --force to replace)" >&2
      return
    fi
    [ "$DRYRUN" -eq 1 ] || rm -rf "$dst"
    echo "link  $dst → $src (replaced real file)"
  else
    echo "link  $dst → $src"
  fi
  [ "$DRYRUN" -eq 1 ] || ln -s "$src" "$dst"
}

mkdir -p ~/.codex/skills ~/.claude/commands

link "$TEMPLATE_ROOT/.codex/skills/kplan"        ~/.codex/skills/kplan
link "$TEMPLATE_ROOT/.codex/skills/sprint"       ~/.codex/skills/sprint
link "$TEMPLATE_ROOT/.claude/commands/kplan.md"  ~/.claude/commands/kplan.md
link "$TEMPLATE_ROOT/.claude/commands/sprint.md" ~/.claude/commands/sprint.md

if [ "$DRYRUN" -eq 1 ]; then
  echo "(dry-run; nothing actually changed)"
fi
