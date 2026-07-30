#!/bin/bash
# inform-specs-lint.sh
# Lint the mem-surface inform-specs file for COLLIDING entries.
#
# Why: inform-specs.json is append-only (grown by the /learn loop + by hand).
# Nothing checks for collisions at write time, so duplicate triggers pointing at
# the SAME memory file accumulate silently — and their `note` text drifts apart
# (one stale, one current). That drift is the failure mode this catches.
#
# Identity key = (type, trigger, memory):
#   inform_on_bash_regex -> pattern
#   inform_on_path_regex -> path_regex
#   inform_on_tool       -> tool
# Same trigger -> DIFFERENT memory is INTENTIONAL fan-out (both reminders fire) and is allowed.
#
# Severity:
#   ERROR  same key, >1 distinct note   -> drift; must reconcile
#   ERROR  malformed entry / unknown type / empty trigger or memory
#   WARN   same key, identical note      -> pure dup; safe to delete one
#   WARN   memory file missing on disk   -> stale pointer
#
# Exit 0 = clean (warnings allowed). Exit 1 = at least one ERROR. Exit 2 = bad input.
# Usage: inform-specs-lint.sh [path]   (default: ~/.claude/state/guards/inform-specs.json)
#
# CONFIG: the missing-file check resolves `memory` against your playbook dir —
# set CLAUDE_MEMORY_DIR if it isn't ~/.claude/memory (same var mem-surface.sh reads).

set -uo pipefail

SPECS="${1:-$HOME/.claude/state/guards/inform-specs.json}"
MEMORY_DIR="${CLAUDE_MEMORY_DIR:-$HOME/.claude/memory}"

command -v jq >/dev/null 2>&1 || { echo "lint: jq not found" >&2; exit 2; }
[ -f "$SPECS" ] || { echo "lint: no specs file at $SPECS" >&2; exit 2; }
jq -e 'type=="array"' "$SPECS" >/dev/null 2>&1 || { echo "lint: $SPECS is not a JSON array" >&2; exit 2; }

# --- structural + collision report (one prefixed line per finding) ---
report=$(jq -r '
  def trig:
    if   .type=="inform_on_bash_regex" then .pattern
    elif .type=="inform_on_path_regex" then .path_regex
    elif .type=="inform_on_tool"       then .tool
    else null end;

  ( to_entries
    | map(.value + {_idx: .key, _trig: (.value|trig)}) ) as $rows

  # malformed / unknown-type / empty key fields
  | ( $rows[]
      | if (.type|IN("inform_on_bash_regex","inform_on_path_regex","inform_on_tool")|not)
          then "ERROR\t[\(._idx)] unknown type: \(.type)"
        elif ((._trig // "") == "")
          then "ERROR\t[\(._idx)] \(.type): empty/missing trigger field"
        elif ((.memory // "") == "")
          then "ERROR\t[\(._idx)] \(.type) \(._trig): empty/missing memory"
        else empty end )
  ,
  # collisions on (type, trigger, memory)
  ( $rows
    | map(select((._trig // "") != "" and (.memory // "") != ""))
    | group_by([.type, ._trig, .memory])
    | map(select(length>1))[]
    | ( (map(.note // "") | unique | length) as $distinct
        | (map(._idx|tostring) | join(",")) as $idxs
        | if $distinct > 1
            then "ERROR\tdrift: \(.[0].type) /\(.[0]._trig)/ -> \(.[0].memory)  [rows \($idxs); \($distinct) different notes]"
            else "WARN\tdup: \(.[0].type) /\(.[0]._trig)/ -> \(.[0].memory)  [rows \($idxs); identical note]"
          end ) )
' "$SPECS")

# --- missing-memory-file check (filesystem, so done in bash) ---
missing=""
while IFS=$'\t' read -r mem idx; do
  [ -z "$mem" ] && continue
  [ -f "$MEMORY_DIR/$mem" ] || missing="${missing}WARN	missing memory file: $mem  [row $idx]"$'\n'
done < <(jq -r 'to_entries[] | select((.value.memory // "")!="") | "\(.value.memory)\t\(.key)"' "$SPECS")

ALL="$report"$'\n'"$missing"
ALL=$(printf '%s\n' "$ALL" | grep -E '^(ERROR|WARN)' || true)

if [ -z "$ALL" ]; then
  echo "inform-specs-lint: clean ($(jq 'length' "$SPECS") entries, no collisions)"
  exit 0
fi

errs=$(printf '%s\n' "$ALL" | grep -c '^ERROR' || true)
warns=$(printf '%s\n' "$ALL" | grep -c '^WARN' || true)
printf '%s\n' "$ALL" | sort | sed 's/^ERROR\t/ERROR  /; s/^WARN\t/WARN   /'
echo "inform-specs-lint: $errs error(s), $warns warning(s)"
[ "$errs" -gt 0 ] && exit 1 || exit 0
