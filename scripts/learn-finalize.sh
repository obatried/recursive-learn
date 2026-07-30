#!/bin/bash
# learn-finalize.sh
# Deterministic closeout for the /learn skill. Replaces the inline multi-line Bash
# blob (mkdir + mv + printf '<json>' >> file + echoes) that /learn used to compose
# freshly each run — that blob could never match a Bash prefix-allow rule (multi-line,
# comments, redirects), so it prompted for approval on every single run. A single
# fixed-path invocation IS allowlistable:
#
#   Bash(~/.claude/scripts/learn-finalize.sh:*)
#
# The model supplies DATA only (date, counts, flags) — never shell structure.
#
# Usage (pass either action, or both in one call):
#   learn-finalize.sh --digest-date YYYY-MM-DD                 # archive a handled consolidation digest
#   learn-finalize.sh --log --session S [--playbooks N] [--guard true|false] [--salience true|false]
#
# SAFETY: --digest-date is validated to YYYY-MM-DD and the source path is built
# INTERNALLY from it; arbitrary paths are never accepted or moved.
set -uo pipefail

REMINDERS="${CLAUDE_REMINDERS_DIR:-$HOME/.claude/state/reminders}"
ACTIONED="$REMINDERS/actioned"
LOG="$HOME/.claude/state/learn/learn-runs.jsonl"

DIGEST_DATE=""
DO_LOG=0
SESSION="unknown"
PLAYBOOKS="0"
GUARD="false"
SALIENCE="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --digest-date) DIGEST_DATE="${2:-}"; shift 2;;
    --log)         DO_LOG=1; shift;;
    --session)     SESSION="${2:-unknown}"; shift 2;;
    --playbooks)   PLAYBOOKS="${2:-0}"; shift 2;;
    --guard)       GUARD="${2:-false}"; shift 2;;
    --salience)    SALIENCE="${2:-false}"; shift 2;;
    *) echo "learn-finalize: ignoring unknown arg: $1" >&2; shift;;
  esac
done

norm_bool() { case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in true|t|yes|y|1) echo true;; *) echo false;; esac; }

# --- archive a handled digest (validated, path built internally) ---
if [ -n "$DIGEST_DATE" ]; then
  if ! printf '%s' "$DIGEST_DATE" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    echo "learn-finalize: refusing --digest-date '$DIGEST_DATE' (must be YYYY-MM-DD)" >&2
    exit 2
  fi
  SRC="$REMINDERS/memory-consolidate-$DIGEST_DATE.md"
  if [ -f "$SRC" ]; then
    # Fail LOUD: a silent archive failure makes the digest look handled while it
    # is still live, so it re-surfaces forever and the "it's done" report is a lie.
    if ! mkdir -p "$ACTIONED" || ! mv "$SRC" "$ACTIONED/"; then
      echo "learn-finalize: FAILED to archive $SRC -> $ACTIONED/ (digest is still live)" >&2
      exit 1
    fi
    echo "archived digest -> $ACTIONED/memory-consolidate-$DIGEST_DATE.md"
  else
    echo "learn-finalize: no live digest for $DIGEST_DATE (nothing to archive)"
  fi
fi

# --- append one run-log line ---
if [ "$DO_LOG" -eq 1 ]; then
  PLAYBOOKS="$(printf '%s' "$PLAYBOOKS" | tr -cd '0-9')"; [ -z "$PLAYBOOKS" ] && PLAYBOOKS=0
  GUARD="$(norm_bool "$GUARD")"
  SALIENCE="$(norm_bool "$SALIENCE")"
  # Fail LOUD on a write failure. Reporting "logged" after the append silently
  # failed is a false green — the exact class of bug commit-on-red-guard exists
  # to catch — so every step here is checked before the success line prints.
  if ! mkdir -p "$(dirname "$LOG")"; then
    echo "learn-finalize: FAILED to create $(dirname "$LOG") — run NOT logged" >&2
    exit 1
  fi
  TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if command -v jq >/dev/null 2>&1; then
    ok=0
    jq -nc \
      --arg ts "$TS" --arg s "$SESSION" \
      --argjson p "$PLAYBOOKS" --argjson g "$GUARD" --argjson sal "$SALIENCE" \
      '{ts:$ts, session:$s, playbooks_captured:$p, guard_installed:$g, salience_sharpened:$sal, recurring_items:[]}' \
      >> "$LOG" || ok=1
  else
    ok=0
    printf '{"ts":"%s","session":"%s","playbooks_captured":%s,"guard_installed":%s,"salience_sharpened":%s,"recurring_items":[]}\n' \
      "$TS" "$SESSION" "$PLAYBOOKS" "$GUARD" "$SALIENCE" >> "$LOG" || ok=1
  fi
  if [ "$ok" -ne 0 ]; then
    echo "learn-finalize: FAILED to append to $LOG — run NOT logged" >&2
    exit 1
  fi
  echo "logged learn run -> $LOG (session=$SESSION playbooks=$PLAYBOOKS guard=$GUARD salience=$SALIENCE)"
fi
