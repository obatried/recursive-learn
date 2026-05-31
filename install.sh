#!/usr/bin/env bash
# recursive-learn installer.
# Copies the skill + hooks into ~/.claude, seeds the verify-first checklist, and
# registers the two SOFT hooks in ~/.claude/settings.json. Idempotent. Backs up
# settings.json before editing and validates the JSON after. Never deletes data.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="${HOME}/.claude"
COMMANDS="${CLAUDE}/commands"
HOOKS="${CLAUDE}/hooks"
STATE_RL="${CLAUDE}/state/recursive-learning"
STATE_LEARN="${CLAUDE}/state/learn"
SETTINGS="${CLAUDE}/settings.json"

command -v python3 >/dev/null 2>&1 || { echo "python3 required"; exit 1; }

mkdir -p "$COMMANDS" "$HOOKS" "$STATE_RL" "$STATE_LEARN"

cp "$SRC/commands/learn.md"          "$COMMANDS/learn.md"
cp "$SRC/hooks/learn-trigger.sh"     "$HOOKS/learn-trigger.sh"
cp "$SRC/hooks/learn-preflight.sh"   "$HOOKS/learn-preflight.sh"
chmod +x "$HOOKS/learn-trigger.sh" "$HOOKS/learn-preflight.sh"

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

def ensure(event, command):
    arr = hooks.setdefault(event, [])
    if not isinstance(arr, list):
        sys.exit(f"settings.json hooks.{event} is not a list; refusing to edit. Fix it by hand.")
    for e in arr:
        if isinstance(e, dict):
            for hc in e.get("hooks", []) or []:
                if isinstance(hc, dict) and hc.get("command") == command:
                    return False
    arr.append({"hooks": [{"type": "command", "command": command}]})
    return True

a = ensure("UserPromptSubmit", "$HOME/.claude/hooks/learn-trigger.sh")
b = ensure("SessionStart",     "$HOME/.claude/hooks/learn-preflight.sh")

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
print(f"UserPromptSubmit hook {'added' if a else 'already present'}")
print(f"SessionStart hook {'added' if b else 'already present'}")
print("settings.json valid")
PY

echo
echo "Installed. The verify-first checklist injects on your NEXT session start."
echo "Run /learn at the end of a substantive session (or when you say 'wrapping up')."
