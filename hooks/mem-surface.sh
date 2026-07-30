#!/bin/bash
# mem-surface.sh
# PreToolUse INFORM hook (SOFT — never blocks, never changes the permission flow).
# The "inform-at-tool-time" carrier of the /learn loop: when the agent is about to
# take an action (a file write to a matching path, a Bash command matching a pattern,
# or a specific tool), surface the playbook YOU already wrote for that action — at the
# workflow point where it's needed, NOT only at prompt time.
#
# This is the complement to learn-guard.sh: that hook DENIES a detectable mistake;
# this one INFORMS for a detectable runbook. Specs live in a SEPARATE file so a bug
# here can never touch the trusted deny path.
#
# Specs file (JSON array): ~/.claude/state/guards/inform-specs.json
#   {"type":"inform_on_path_regex","path_regex":"ERE","memory":"file.md","note":"..."}  -> Write/Edit/MultiEdit target matches
#   {"type":"inform_on_bash_regex","pattern":"ERE","memory":"file.md","note":"..."}     -> Bash command matches
#   {"type":"inform_on_tool","tool":"<exact tool_name>","memory":"file.md","note":"..."} -> tool name matches exactly
# `memory` is a path RELATIVE to your memory/playbook dir; `note` is an optional one-line why/what.
# Patterns/notes must be single-line: a raw newline inside a pattern makes grep treat
# it as TWO patterns (silent over-match), so extraction flattens newlines to spaces.
#
# CONFIG: point MEMORY_DIR at wherever your playbook/memory markdown files live.
#   Override with the CLAUDE_MEMORY_DIR env var; default below is ~/.claude/memory.
#   (If you use a companion memory system like total-recall, set this to its memory dir.)
#
# SAFETY MODEL (identical contract to learn-guard.sh):
# - Empty/absent specs file => total no-op.
# - NEVER emits permissionDecision => the user's normal permission prompt/settings
#   are left completely intact. This hook only ever ADDS context.
# - On any internal error => exit 0 with no output (fail-open), so a hook bug can
#   never brick a tool call.
# Three controls bound the noise: exact/explicit matching, once-per-memory-per-session
# throttle, and a max of 2 surfaced per call.
#
# PERF: the spec scan is ONE jq pass emitting \x1f-joined records (raw fields, never
# @tsv, so regex backslashes survive) plus a pure-bash loop; grep only spawns for regex
# entries when there is actually a CMD/TARGET to match. The earlier per-index loop
# spawned 4 jq processes per entry (~3s/call at 120 specs; now ~0.1s). That headroom is
# what makes registering this hook with matcher "*" viable — see install.sh — so an
# inform_on_tool spec can fire for ANY tool; non-Bash/Write tools skip every regex
# entry and cost only the single jq pass.

set -uo pipefail
exec 2>/dev/null
trap 'exit 0' ERR

[ -n "${HOME:-}" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

SPECS="$HOME/.claude/state/guards/inform-specs.json"
MEMORY_DIR="${CLAUDE_MEMORY_DIR:-$HOME/.claude/memory}"
[ -f "$SPECS" ] || exit 0
# specs must be a non-empty JSON array, else no-op
jq -e 'type=="array" and length>0' "$SPECS" >/dev/null 2>&1 || exit 0

INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"')
[ -z "$TOOL" ] && exit 0

# Derive the action string(s) to match against, by tool.
TARGET=""; CMD=""
case "$TOOL" in
  Write|Edit|MultiEdit) TARGET=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""') ;;
  Bash)                 CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""') ;;
esac

# ONE jq pass over the specs: emit "type \x1f pattern \x1f tool \x1f memory \x1f note"
# per entry. Fields are raw (jq -r join, never @tsv) so regex backslashes (\b, \d, \.)
# survive; newlines/tabs inside fields are flattened so they can't split records or the
# downstream tab-separated MATCHES format.
RECORDS=$(jq -r '.[] | [
    (.type // ""),
    ((.pattern // .path_regex // "") | gsub("[\n\t]"; " ")),
    (.tool // ""),
    (.memory // ""),
    ((.note // "") | gsub("[\n\t]"; " "))
  ] | join("\u001f")' "$SPECS")
[ -z "$RECORDS" ] && exit 0

# Collect matching "memory<TAB>note" pairs (pure bash; grep only on regex entries).
MATCHES=""
while IFS=$'\x1f' read -r TYPE pat want mem note; do
  [ -n "$mem" ] || continue
  hit=0
  case "$TYPE" in
    inform_on_tool)
      [ -n "$want" ] && [ "$want" = "$TOOL" ] && hit=1 ;;
    inform_on_path_regex)
      [ -n "$pat" ] && [ -n "$TARGET" ] && grep -qE "$pat" <<<"$TARGET" && hit=1 ;;
    inform_on_bash_regex)
      [ -n "$pat" ] && [ -n "$CMD" ] && grep -qE "$pat" <<<"$CMD" && hit=1 ;;
  esac
  if [ "$hit" -eq 1 ]; then
    MATCHES="${MATCHES}${mem}	${note}"$'\n'
  fi
done <<< "$RECORDS"

[ -z "$MATCHES" ] && exit 0

# Throttle: once per memory per session.
SAFE_SID=$(printf '%s' "$SESSION_ID" | tr -cs 'A-Za-z0-9._-' '_'); [ -z "$SAFE_SID" ] && SAFE_SID="unknown"
SEEN_FILE="$HOME/.claude/state/mem-surface-$SAFE_SID.seen"
mkdir -p "$HOME/.claude/state" 2>/dev/null || true
# Self-hygiene: a seen-file is only meaningful within its own session. On the FIRST
# match of a fresh session (file doesn't exist yet) opportunistically prune stale
# mem-surface seen-files (>7d) so they can't accumulate. Runs at most once/session.
[ -e "$SEEN_FILE" ] || find "$HOME/.claude/state" -maxdepth 1 -name 'mem-surface-*.seen' -mtime +7 -delete 2>/dev/null || true
touch "$SEEN_FILE" 2>/dev/null || true

desc_of() {  # $1 = absolute file path -> description (or humanized filename)
  local d
  d=$(awk 'BEGIN{c=0} /^---$/{c++; if(c==2)exit; next} c==1 && /^description:/{sub(/^description: */,""); gsub(/"/,""); print; exit}' "$1" 2>/dev/null)
  [ -z "$d" ] && d=$(basename "$1" .md | tr '_-' '  ')
  printf '%.180s' "$d"
}

LINES=""
EMITTED=0
while IFS=$'\t' read -r mem note; do
  [ -z "$mem" ] && continue
  [ "$EMITTED" -ge 2 ] && break
  grep -qxF "$mem" "$SEEN_FILE" 2>/dev/null && continue   # already surfaced this session
  abs="$MEMORY_DIR/$mem"
  [ -f "$abs" ] || continue
  d=$(desc_of "$abs")
  if [ -n "$note" ]; then
    LINES="${LINES}• ${mem} — ${d} (${note})"$'\n'
  else
    LINES="${LINES}• ${mem} — ${d}"$'\n'
  fi
  printf '%s\n' "$mem" >> "$SEEN_FILE"
  EMITTED=$((EMITTED+1))
done <<< "$MATCHES"

[ "$EMITTED" -eq 0 ] && exit 0

# analytics
LOG="$HOME/.claude/state/learn/mem-surface.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg s "$SESSION_ID" --arg tool "$TOOL" \
   --arg n "$EMITTED" --arg files "$LINES" \
   '{ts:$ts,session:$s,tool:$tool,emitted:($n|tonumber),files:$files}' >> "$LOG" 2>/dev/null || true

MSG="[MEMORY SURFACE — soft] You're about to use ${TOOL}. A playbook you wrote applies here — read it before proceeding:
${LINES}Surfaced once per session per playbook. Soft pointer, not a block — skip if it doesn't fit."

# Inject context ONLY. No permissionDecision => the normal permission flow is untouched.
jq -nc --arg m "$MSG" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$m}}'
exit 0
