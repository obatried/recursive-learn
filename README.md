# recursive-learn

A self-correcting learning loop for [Claude Code](https://claude.com/claude-code). At the end of a session, `/learn` audits the assistant's own claims for the one failure that quietly erodes trust — **asserting a conclusion before verifying it** — generalizes each miss to the *root reason* it happened, and feeds that into a checklist injected at the *start* of every future session. So "verify before you assert" stops being a buried rule and becomes an active prompt every time.

It is deliberately tiny. It does one thing.

## The flywheel

```
/learn  →  writes the recurring "I asserted before checking" misses
              to  state/recursive-learning/verify-preflight.md
   ↑                                                    ↓
   │              learn-preflight.sh (SessionStart hook) injects that
   │              checklist into context at the START of every session
   └────── next session has verify-first top-of-mind ──┘
```

The insight: a rule sitting in a memory file is **passive** — it only helps when something happens to read it. The failure (asserting from inference) happens mid-turn, not when you read docs. So the fix isn't another memory; it's resurfacing the lesson at session start *and* — crucially — noticing when even that isn't enough.

## What's in the box

| File | Role |
|---|---|
| `commands/learn.md` | The skill. Core = **Assertion Audit**: re-scan your own claims, tag each `verified` / `asserted-from-inference` / `wrong`, and write down the *root reason* behind each miss (generalized, not the one-off incident) so it transfers to the next mistake. |
| `hooks/learn-trigger.sh` | `UserPromptSubmit` hook (**soft**). Fires once/session when you signal you're wrapping up → nudges "consider `/learn`." Never blocks. |
| `hooks/learn-preflight.sh` | `SessionStart` hook (**soft**). Injects the verify checklist at session start. |
| `hooks/learn-guard.sh` | `PreToolUse` hook (**hard, fail-open on error**). Reads `guard-specs.json` and **denies** a tool call that matches a guard `/learn` installed for a previously-corrected, *detectable* mistake. No-op until a spec exists. |
| `state/verify-preflight.seed.md` | Starter checklist — the flywheel's memory. |
| `state/guard-specs.seed.json` | Starter (empty) guard list — the enforcement layer's memory. |

## Detectable vs fuzzy: the honest split

Not all mistakes are equal, and the system refuses to pretend otherwise:

- **Detectable** (a file path you must never write, a command you must never run) → `/learn` appends a line to `guard-specs.json` and the `PreToolUse` guard **mechanically blocks it** every time. This is the only thing that genuinely makes a mistake *"never again."* It's data-only — `/learn` appends a spec; no new code runs.
- **Fuzzy** (a judgment call, "asserted before verifying") → no shell hook can reliably detect it, so it **cannot be guaranteed** — only made *less likely* via the soft layers below. The system labels every lesson `hard-blocked` or `salience-only` so you always know which you've actually got.

## The escalation ladder (why it self-corrects)

Most "learning" systems just launder mistakes into nicer-looking notes. This one tracks whether its own mechanism is *working*, and for the fuzzy class:

- **L0** one-off → a memory file.
- **L1** recurred despite the memory → promote to the preflight, tagged `(seen 1x)`.
- **L2** recurred *again while already on the preflight* → the soft mechanism has **provably failed**. `/learn` proposes the nearest in-the-moment proxy guard, not another note. And it's forbidden from claiming "fixed" — the only proof is the recurrence count trending to zero in the run log.

## Install

Requires `python3` (for the installer's settings.json edit) and `jq` (the hooks no-op gracefully without it, so they never break your session — but they only *do* anything with `jq` present).

```bash
git clone https://github.com/obatried/recursive-learn
cd recursive-learn
./install.sh        # copies the skill + hooks into ~/.claude and registers the hooks
```

The installer backs up `settings.json` first and validates the JSON after. To uninstall, remove the two hook entries from `~/.claude/settings.json` and delete the three files.

## Philosophy: start soft, earn the block

Every hook here is **soft** — it nudges, never blocks. If you keep skipping `/learn` when nudged, the trigger log tells you, and *that's* the signal to harden — not a guess up front. A blocking hook that misfires is the fastest way to make you hate your own tooling. Earn the block.

## License

MIT.
