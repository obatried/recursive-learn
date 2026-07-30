#!/usr/bin/env bash
# recursive-learn installer.
# Copies the skill + hooks into ~/.claude, seeds the verify-first checklist + the
# (empty) guard/inform spec files, and registers the SOFT + guard hooks in
# ~/.claude/settings.json. Idempotent. Backs up settings.json before editing and
# validates the JSON after. Never deletes data.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="${HOME}/.claude"
COMMANDS="${CLAUDE}/commands"
HOOKS="${CLAUDE}/hooks"
SCRIPTS="${CLAUDE}/scripts"
STATE_RL="${CLAUDE}/state/recursive-learning"
STATE_LEARN="${CLAUDE}/state/learn"
GUARDS="${CLAUDE}/state/guards"
SETTINGS="${CLAUDE}/settings.json"

command -v python3 >/dev/null 2>&1 || { echo "python3 required"; exit 1; }

# jq isn't required to INSTALL, but without it the hooks no-op, inform-specs-lint.sh
# hard-fails, and the /learn spec-append snippets don't work — i.e. a "successful"
# install would be a nonfunctional one. Warn loudly rather than report a false green.
command -v jq >/dev/null 2>&1 || cat <<'WARN'
⚠️  jq not found. Installation will proceed, but until you install jq:
      - the hooks silently no-op (they never break your session, but they do nothing)
      - inform-specs-lint.sh exits 2
      - the /learn snippets that append guard/inform specs will not run
    Install it (brew install jq / apt install jq) and no re-install is needed.
WARN

mkdir -p "$COMMANDS" "$HOOKS" "$SCRIPTS" "$STATE_RL" "$STATE_LEARN" "$GUARDS"

cp "$SRC/commands/learn.md"             "$COMMANDS/learn.md"
cp "$SRC/hooks/learn-trigger.sh"        "$HOOKS/learn-trigger.sh"
cp "$SRC/hooks/learn-preflight.sh"      "$HOOKS/learn-preflight.sh"
cp "$SRC/hooks/learn-guard.sh"          "$HOOKS/learn-guard.sh"
cp "$SRC/hooks/mem-surface.sh"          "$HOOKS/mem-surface.sh"
cp "$SRC/hooks/commit-on-red-guard.sh"  "$HOOKS/commit-on-red-guard.sh"
chmod +x "$HOOKS/learn-trigger.sh" "$HOOKS/learn-preflight.sh" "$HOOKS/learn-guard.sh" \
         "$HOOKS/mem-surface.sh" "$HOOKS/commit-on-red-guard.sh"

# Helper scripts the skill invokes by fixed path (so they're allowlistable as
# Bash(~/.claude/scripts/<name>:*) instead of prompting on every run).
cp "$SRC/scripts/learn-finalize.sh"     "$SCRIPTS/learn-finalize.sh"
cp "$SRC/scripts/inform-specs-lint.sh"  "$SCRIPTS/inform-specs-lint.sh"
chmod +x "$SCRIPTS/learn-finalize.sh" "$SCRIPTS/inform-specs-lint.sh"

# Seed the spec files only if absent (empty array => the hook is a total no-op).
[ -f "$GUARDS/guard-specs.json" ]  || cp "$SRC/state/guard-specs.seed.json"  "$GUARDS/guard-specs.json"
[ -f "$GUARDS/inform-specs.json" ] || cp "$SRC/state/inform-specs.seed.json" "$GUARDS/inform-specs.json"

# Seed the checklist only if absent — never clobber a user's accumulated one.
if [ ! -f "$STATE_RL/verify-preflight.md" ]; then
  cp "$SRC/state/verify-preflight.seed.md" "$STATE_RL/verify-preflight.md"
  echo "seeded $STATE_RL/verify-preflight.md"
else
  echo "kept existing $STATE_RL/verify-preflight.md"
fi

# Register hooks in settings.json (create a minimal file if none exists).
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "${SETTINGS}.bak-$(date +%Y%m%d-%H%M%S)"

python3 - "$SETTINGS" <<'PY'
import json, sys, os, tempfile
p = sys.argv[1]
with open(p) as f:
    d = json.load(f)

# Type guards: bail loudly rather than corrupt an unexpected shape.
if not isinstance(d, dict):
    sys.exit("settings.json root is not a JSON object; refusing to edit. Fix it by hand.")
hooks = d.setdefault("hooks", {})
if not isinstance(hooks, dict):
    sys.exit("settings.json 'hooks' is not an object; refusing to edit. Fix it by hand.")

def _has(event, command, matcher=None):
    arr = hooks.get(event, [])
    if not isinstance(arr, list):
        sys.exit(f"settings.json hooks.{event} is not a list; refusing to edit. Fix it by hand.")
    for e in arr:
        if isinstance(e, dict) and (matcher is None or e.get("matcher") == matcher):
            for hc in e.get("hooks", []) or []:
                if isinstance(hc, dict) and hc.get("command") == command:
                    return True
    return False

def ensure(event, command, matcher=None):
    """Add {matcher?, hooks:[{command}]} to an event if that command isn't already present."""
    if _has(event, command, matcher):
        return False
    arr = hooks.setdefault(event, [])
    entry = {"hooks": [{"type": "command", "command": command}]}
    if matcher is not None:
        entry = {"matcher": matcher, **entry}
    arr.append(entry)
    return True

def drop(event, command, keep_matcher):
    """Remove `command` from any matcher group on `event` other than keep_matcher.
    Used to migrate a hook to a wider matcher without leaving a duplicate behind
    (a double registration would fire the hook twice per tool call)."""
    arr = hooks.get(event, [])
    if not isinstance(arr, list):
        return False
    changed = False
    for e in list(arr):
        if not isinstance(e, dict) or e.get("matcher") == keep_matcher:
            continue
        hcs = e.get("hooks") or []
        kept = [hc for hc in hcs if not (isinstance(hc, dict) and hc.get("command") == command)]
        if len(kept) != len(hcs):
            changed = True
            e["hooks"] = kept
            if not kept:
                arr.remove(e)
    return changed

H = "$HOME/.claude/hooks"
PRE = "Write|Edit|MultiEdit|Bash"

# mem-surface is registered on ALL tools ("*") so an inform_on_tool spec can bind to any
# tool, not just the write/Bash set. Safe since the v3 single-jq-pass rewrite: a non-Bash,
# non-Write call skips every regex entry and costs one jq. Migrate an older narrow
# registration instead of adding a second one.
migrated = drop("PreToolUse", f"{H}/mem-surface.sh", "*")

results = {
  "UserPromptSubmit/learn-trigger":  ensure("UserPromptSubmit", f"{H}/learn-trigger.sh"),
  "SessionStart/learn-preflight":    ensure("SessionStart",     f"{H}/learn-preflight.sh"),
  "PreToolUse/learn-guard":          ensure("PreToolUse",       f"{H}/learn-guard.sh",         PRE),
  "PreToolUse/mem-surface":          ensure("PreToolUse",       f"{H}/mem-surface.sh",         "*"),
  "PreToolUse/commit-on-red-guard":  ensure("PreToolUse",       f"{H}/commit-on-red-guard.sh", "Bash"),
}
if migrated:
    print("PreToolUse/mem-surface: migrated to matcher '*' (was narrow)")

# Atomic write: temp file in the same dir, validate, then rename over the target.
dirn = os.path.dirname(os.path.abspath(p)) or "."
fd, tmp = tempfile.mkstemp(dir=dirn, prefix=".settings.", suffix=".tmp")
try:
    with os.fdopen(fd, "w") as f:
        json.dump(d, f, indent=2)
    json.load(open(tmp))  # validate the temp before replacing
    os.replace(tmp, p)
except BaseException:
    try: os.unlink(tmp)
    except OSError: pass
    raise
for k, added in results.items():
    print(f"{k}: {'added' if added else 'already present'}")
print("settings.json valid")
PY

echo
echo "Installed. The verify-first checklist injects on your NEXT session start."
echo "Run /learn at the end of a substantive session (or when you say 'wrapping up')."
echo "Point mem-surface at your playbook dir with CLAUDE_MEMORY_DIR if it isn't ~/.claude/memory."
echo
echo "Optional, to stop /learn's closeout from prompting every run, allowlist in settings.json:"
echo '  Bash(~/.claude/scripts/learn-finalize.sh:*)'
echo '  Bash(~/.claude/scripts/inform-specs-lint.sh:*)'
