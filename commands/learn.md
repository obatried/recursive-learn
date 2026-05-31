Recursive learning pass. The single job of this skill is to turn what just happened into durable behavior change for next time. It is token-heavy and run selectively — at the end of a substantive session, or when something surprising happened (a failure, a recovery, a new task type, repeated pushback).

**Scope discipline (read this first, it is the whole point):** session-close rituals tend to fail by sprawling — they grow status-file, bookkeeping, and handoff steps until they "do random stuff" and nobody runs them. `/learn` must NOT do that. It does ONE thing: extract learning and feed the verify flywheel. If you feel the urge to update a project status file, close a tracker, or write a handoff here — STOP, that belongs in a separate close command. Keep this skill small forever.

Location note: if running outside the slash-command loader, read this file from `~/.claude/commands/learn.md` and execute it.

Paths used by this skill (portable defaults):
- Memory directory: `~/.claude/memory/` — where durable `feedback_*.md` lessons live. Adjust if yours differs.
- Flywheel checklist: `~/.claude/state/recursive-learning/verify-preflight.md` — injected at session start by `learn-preflight.sh`.
- Run log: `~/.claude/state/learn/learn-runs.jsonl`.

---

## Step 0 — Gate (don't run on nothing)

Run only if the session was substantive: roughly ≥8 tool calls, OR ≥2 files changed, OR ≥1 real pushback from the user, OR a notable failure/recovery happened. If none apply, output `/learn: skipped (non-substantive session)` and stop. Don't perform the rest.

## Step 1 — Assertion Audit (THE CORE — do this most carefully)

Re-read your OWN messages this session and find every place you stated something as fact: "X exists / doesn't exist", "it's done", "that's sent", "the file has Y", "the data is empty", "this is a false positive", "tests pass", etc.

For each such claim, tag it:
- **Verified** — you had run the check (Read/Bash/grep/tool/screenshot) BEFORE asserting. Cite the check.
- **Asserted-from-inference** — you reasoned it was true and stated it before checking. (Tell: the user asked "did you actually check?" or you only verified after they pushed.)
- **Wrong** — it turned out false.

Output a short table: `| claim | tag | the check I should have run first |`.

The `Asserted-from-inference` and `Wrong` rows are the gold — but what you write down is **the reason, not the incident**. Writing "when about to claim a data store is empty → query it directly" is a patch for one situation that will never transfer to the next, differently-shaped mistake. Write down the **root reason you made the mistake**, generalized to a rule that fires everywhere that reason applies — yet still concrete enough to act on. Calibrate the altitude:
- too abstract (useless): "be more careful", "verify more".
- too specific (a patch, won't transfer): "when claiming a data store is empty, open it first".
- right (the reason, still actionable): "when you reach a conclusion by inference instead of direct observation — especially when you feel confident — treat it as a hypothesis and run the one direct check before stating it as fact".

The incident is just the example that taught you the reason. **Persist the reason; cite the incident as its example.** And when a new miss shares a root reason with a lesson you already have, do NOT add a new line — **deepen the existing one** (sharpen its wording, bump its recurrence count). That consolidation is the "build on top of it" recursion; a growing list of narrow incidents is the failure mode.

## Step 2 — Correction mining

Re-read every USER message. Flag pushback signals (direct "no/don't/stop/why", soft "actually/instead/I would have", repeated re-statements, frustration, and especially "did you check / are you sure"). For each: generalize to the underlying pattern, not the surface complaint. Search your memory directory (`~/.claude/memory/feedback_*.md`) for an existing rule — if one exists, this is a refinement (Step 4), not a new file.

## Step 3 — Persist so it changes behavior (not just a log)

Two destinations:

1. **New/refined memory** for genuinely new lessons → a `feedback_*.md` file in your memory directory. Use whatever frontmatter/indexing convention your setup expects (this skill is agnostic to it).

2. **The verify flywheel** → append/refresh the rolling checklist at `~/.claude/state/recursive-learning/verify-preflight.md`. Keep it to the **top 3–5 recurring verification misses, one line each.** This file is injected into context at the start of every session by `learn-preflight.sh`, which is what makes verify-first *active* instead of buried. Demote stale entries; promote whatever bit this session.

**First, classify the trigger's DETECTABILITY — this decides whether you can actually guarantee non-recurrence.**

**Detectable** — the trigger is an exact thing a shell hook can see: a file path you must never write, or a Bash command pattern you must never run. → **Install a hard guard NOW, on the FIRST identification — do not wait for a 2nd occurrence.** Append a spec to `~/.claude/state/guards/guard-specs.json`; the pre-installed `learn-guard.sh` PreToolUse hook reads it and DENIES the matching call (the tool is blocked before it runs). This is the **only** level that genuinely makes a mistake "never again." Recipe (atomic):
```bash
jq '. += [{"type":"deny_write_path","path":"/ABS/PATH","reason":"why + what to do instead"}]' \
   ~/.claude/state/guards/guard-specs.json > ~/.claude/state/guards/.gs.$$ \
   && mv ~/.claude/state/guards/.gs.$$ ~/.claude/state/guards/guard-specs.json
# command form:  {"type":"deny_bash_regex","pattern":"<portable, ANCHORED ERE>","reason":"..."}
```
Rules: store the **absolute** path (match is exact). Keep regexes **portable** (BSD + GNU grep — avoid `\b` and fancy classes if unsure) and **anchored**/specific so they can't over-block a legit command. Label the lesson **`hard-blocked`**. The guard is data-only — you append a line; no new code runs.

**Fuzzy** — a judgment with no clean signature (e.g. "asserted from inference before checking"). A hook cannot reliably detect it, so it **cannot be hard-guaranteed** — be honest, label it **`salience-only`** (less likely, not impossible). Use the soft ladder, moving UP a level on each recurrence (re-noting at the same level is the failure mode — it feels like progress and changes nothing):
- **L0 one-off** → a `feedback_*.md` memory.
- **L1 recurred despite the memory** → promote to `verify-preflight.md` (injected at session start), tag `(seen Nx)`.
- **L2 recurred AGAIN while on the preflight** → the soft layer is provably failing. Best remaining move is the nearest *proxy* guard (e.g. a claim-evidence Stop-check that flags a confident state-claim with no verifying tool-call that turn). **Describe it and ASK before building** (Step 4 rules).

**Honest-effectiveness check (required output, no overclaiming):** for each recurring lesson, state its label (`hard-blocked` = genuinely prevented; `salience-only` = less likely) and level. Never call a `salience-only` lesson "fixed" — the only proof is its recurrence count trending to zero in the run log. A lesson reaching L2 IS evidence the soft layer is failing — surface it loudly.

## Step 4 — Rule refinement (ask before changing load-bearing rules)

Any stored rule that *misfired* this session (got cited, then the user said "doesn't apply / too broad / stop citing that")? Propose tighten / exception / split / soften / delete — one-line context + proposed diff. **Apply only on explicit approval.** Stored rules are load-bearing; a bad refinement is worse than none.

## Step 5 — Skill fix (only if one misfired this session)

If a skill/command invoked this session needed manual steering or produced a bad result, read its file and fix the specific gap. Skip silently if none.

## Output

```
/learn
- Assertion audit: N claims | verified A | inference B | wrong C
- New/refined memories: N  (slug — one line each)
- Preflight: now N lines (promoted: ..., recurrence counts updated)
- Recurring → level: <lesson> L0→L1 (to preflight) | <lesson> L1→L2 (soft FAILED, hardening proposed below) | "none"
- Hardening proposed (awaiting approval): <proposed hook + trigger> | "none"
- Rule changes proposed (awaiting approval): ... | "none"
- Skill fixes: ... | "none"
- Effectiveness (honest): which lessons are at which level; proof is the recurrence count trending to 0 — NOT "fixed"
- Still open: one line, or "nothing"
```

Then append one JSON line to `~/.claude/state/learn/learn-runs.jsonl`: `{ts, session, claims, inference_misses, wrong, new_memories, recurring_items: [{lesson, level}]}`. The per-lesson `level` is what makes the trend real: if the same `lesson` keeps reappearing and climbing to L2, the soft flywheel is provably failing for that lesson and the next `/learn` must propose a hook, not another note.
