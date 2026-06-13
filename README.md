# recursive-learn

A small, forward-only learning loop for [Claude Code](https://claude.com/claude-code). At the end of a session, `/learn` is built around two jobs — and deliberately resists growing past them:

1. **Captures reusable playbooks** — so a problem you solved once is never re-solved or re-explained. This is the core.
2. **Hard-stops a detectable mistake** from recurring — by installing a deny guard the moment you identify one.

It is deliberately tiny, and it only ever reflects on **the session that just happened** — it never mines or audits old transcripts to grade itself. (That's a trap: it manufactures busywork and measures the wrong thing.)

> **Why this shape?** An LLM's weights are frozen between sessions. Only two things actually carry over: **context that gets re-injected**, and **what a hook enforces**. A lesson written into a memory file is *documentation, not learning* — it changes nothing next session unless something re-surfaces it or a hook acts on it. So this tool is built on exactly those two carriers, and it refuses to pretend a note is a fix.

## The carriers

```
                 /learn  (end of a substantive session)
                    │
        ┌───────────┼───────────────────────────┐
        ▼           ▼                             ▼
   CAPTURE      MISTAKE → detectable?        MISTAKE → fuzzy?
 task-shaped    install a DENY guard         sharpen ONE line in the
 playbook       (guard-specs.json)           verify-first preflight
        │           │                             │
        │  next time you reach for that action…   │  injected at the
        ▼           ▼                             ▼  start of every session
  surfaced by    blocked by                  re-surfaced by
  mem-surface    learn-guard                 learn-preflight
  (tool-time)    (PreToolUse deny)           (SessionStart)
```

- **Capture (the skill).** When you crack something — a non-obvious auth path, a tool sequence, a procedure the user explained — `/learn` writes a `reference_*` playbook **indexed by task shape**, not by the incident ("pull the meeting notes for a call", not "that thing on Tuesday"). Record the working path *and* the dead-ends.
- **Surface at point-of-need (`mem-surface.sh`).** A playbook in a file is inert until it's re-injected at the moment it's needed. Prompt-time recall only fires when your *prompt* keyword-matches. But the need often lands mid-task — you're about to run a command, write a path, call a tool — with no prompt to match. So `/learn` binds a playbook to its **detectable trigger** (a command pattern, a path pattern, a tool name), and this PreToolUse hook surfaces it the instant you reach for that action. It only ever *adds context* — it never blocks and never touches the permission flow.
- **Hard-deny (`learn-guard.sh`).** For a mistake with a clean signature — a path you must never write, a command you must never run — `/learn` appends a spec and this PreToolUse hook **denies the matching call** every time. Data-only: `/learn` appends JSON; no new code runs at match time. This is the one carrier that genuinely makes a mistake *"never again."*
- **Preflight salience (`learn-preflight.sh`).** For a *fuzzy* lesson with no clean signature (how you reason about a claim or a state), there's nothing to enforce — so `/learn` sharpens a single line in a ~5-line verify-first checklist that gets injected at the start of every session. Honest framing: this makes a miss *less likely, not impossible*.

## Detectable vs fuzzy: the honest split

Not all mistakes are equal, and the tool refuses to pretend otherwise:

- **Detectable** → `guard-specs.json` + the deny hook. Mechanically blocked. This is real "never again."
- **Fuzzy** (a judgment call, "asserted before verifying") → no shell hook can reliably detect it, so it **cannot be guaranteed** — only made *less likely* via salience. The tool never calls a fuzzy lesson "fixed."

The corollary the redesign learned the hard way: **don't pour fuzzy lessons into the preflight.** Each one that gets pasted in dilutes the salience of the rest. Keep it to ~5 short lines forever; sharpen the matching line, don't add a bullet.

## What's in the box

| File | Role |
|---|---|
| `commands/learn.md` | The skill. Three steps: **A** capture playbooks (the core), **B** mistake → guard-or-salience, **C** close the dedup loop. Forward-only; no audit journal, no taxonomy, no registry. |
| `hooks/mem-surface.sh` | `PreToolUse` (**soft, inform-only**). Surfaces the playbook bound to a command/path/tool you're about to use. Reads `inform-specs.json`. Never blocks; never changes permissions. |
| `hooks/learn-guard.sh` | `PreToolUse` (**hard, fail-open on error**). Reads `guard-specs.json` and **denies** a tool call matching a guard `/learn` installed for a previously-corrected, *detectable* mistake. No-op until a spec exists. |
| `hooks/commit-on-red-guard.sh` | `PreToolUse(Bash)` example guard. Catches a `git commit` joined to a test/check by an unconditional operator (`;`, `\|\|`, `&`) so the commit fires even on red. Ships in **log mode** — flip to enforce once the log shows the false-alarm rate is low. |
| `hooks/learn-preflight.sh` | `SessionStart` (**soft**). Injects the verify-first checklist at session start. |
| `hooks/learn-trigger.sh` | `UserPromptSubmit` (**soft**). Fires once/session when you signal you're wrapping up → nudges "consider `/learn`." Never blocks. |
| `state/verify-preflight.seed.md` | Starter checklist — ~5 universal verification principles, one line each. |
| `state/guard-specs.seed.json` | Starter (empty) deny list. Empty = the guard is a total no-op. |
| `state/inform-specs.seed.json` | Starter (empty) inform list for `mem-surface`. Empty = no-op. |

## Install

Requires `python3` (for the installer's settings.json edit) and `jq` (the hooks no-op gracefully without it, so they never break your session — but they only *do* anything with `jq` present).

```bash
git clone https://github.com/obatried/recursive-learn
cd recursive-learn
./install.sh        # copies the skill + hooks into ~/.claude and registers the hooks
```

The installer backs up `settings.json` first and validates the JSON after. To uninstall, remove the hook entries from `~/.claude/settings.json` and delete the copied files.

**Memory dir.** The capture + surface carriers read and write playbook files in a memory dir. Point `mem-surface.sh` at yours via the `CLAUDE_MEMORY_DIR` env var (default `~/.claude/memory`). If you want a richer capture/recall/search layer underneath this loop, see the companion project **[total-recall](https://github.com/obatried/total-recall)** — recursive-learn is the *learning loop*; total-recall is the *memory system* it writes into.

**Surfacing on other tools.** The installer registers `mem-surface` for `Write`, `Edit`, `MultiEdit`, and `Bash`, so `inform_on_bash_regex` / `inform_on_path_regex` specs work out of the box. An `inform_on_tool` spec only fires for a tool `mem-surface` is actually registered on — to surface a playbook when you call some *other* tool (e.g. a specific MCP tool), add that exact tool name to the `mem-surface` matcher in `~/.claude/settings.json` (its own matcher group is fine).

## Philosophy

- **Forward-only.** Reflect on the session in front of you. Never audit history to score yourself.
- **Earn the block.** The soft layers (capture, inform, preflight, trigger) never block. The one always-on hard-deny — `learn-guard` — fires only on an **exact spec you installed *after* a real mistake already happened**, so the block is earned by the incident, not guessed up front (and an empty spec file is a total no-op). *Broad or heuristic* guards like `commit-on-red` ship in **log mode**: you read the log first and flip to enforce only once its false-alarm rate is low. A blocking hook that misfires is the fastest way to make you hate your own tooling.
- **Keep it small.** Capture + surface + deny. The moment it grows a registry, a taxonomy, or a self-grading audit, it has drifted back into documentation theater. Resist it.

## Works well with: total-recall

recursive-learn handles *self-correction*. [total-recall](https://github.com/obatried/total-recall)
handles *memory* — the `CLAUDE.md` / `MEMORY.md` capture, structure, and search that let a fresh session
pick up where the last one left off. They compose: run total-recall's `meta-install.sh` to set up both
at once ("give your AI a memory" + a `/learn` loop in one command).

## License

MIT.
