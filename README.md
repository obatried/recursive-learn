# recursive-learn

A small, forward-only learning loop for [Claude Code](https://claude.com/claude-code). At the end of a session, `/learn` is built around two jobs — and deliberately resists growing past them:

1. **Captures reusable playbooks** — so a problem you solved once is never re-solved or re-explained. This is the core.
2. **Hard-stops a harmful, detectable mistake** from recurring — by installing a deny guard the moment you identify one (a deny is reserved for real harm; a mere detectable *preference* gets a soft, overridable reminder instead).

It is deliberately tiny, and it only ever reflects on **the session that just happened** — it never mines or audits old transcripts to grade itself. (That's a trap: it manufactures busywork and measures the wrong thing.)

> **Why this shape?** An LLM's weights are frozen between sessions. Only two things actually carry over: **context that gets re-injected**, and **what a hook enforces**. A lesson written into a memory file is *documentation, not learning* — it changes nothing next session unless something re-surfaces it or a hook acts on it. So this tool is built on exactly those two carriers, and it refuses to pretend a note is a fix.

## The carriers

```
                 /learn  (end of a substantive session)
                    │
        ┌───────────┼───────────────────────────┐
        ▼           ▼                             ▼
   CAPTURE      MISTAKE → real harm           MISTAKE → preference
 task-shaped    + detectable?                 or fuzzy?
 playbook       install a DENY guard          inform-surface OR sharpen
        │       (guard-specs.json)            ONE line in the preflight
        │           │                             │
        │  next time you reach for that action…   │  reminded at tool-time /
        ▼           ▼                             ▼  start of every session
  surfaced by    blocked by                  reminded / re-surfaced by
  mem-surface    learn-guard                 mem-surface / learn-preflight
  (tool-time)    (PreToolUse deny)           (tool-time / SessionStart)
```

> **The gate that matters:** a hard deny is permanent and global — escaping it means hand-editing JSON — so it's earned *only* by a nameable **harm class** (`data_loss`, `security`, `environment_breakage`, `tool_semantics`). A merely-detectable *preference* ("stop pacing yourself") does **not** get a deny, even though a regex could match it — it gets a soft, overridable inform. Detectable ≠ worth enforcing forever.

- **Capture (the skill).** When you crack something — a non-obvious auth path, a tool sequence, a procedure the user explained — `/learn` writes a `reference_*` playbook **indexed by task shape**, not by the incident ("pull the meeting notes for a call", not "that thing on Tuesday"). Record the working path *and* the dead-ends.
- **Surface at point-of-need (`mem-surface.sh`).** A playbook in a file is inert until it's re-injected at the moment it's needed. Prompt-time recall only fires when your *prompt* keyword-matches. But the need often lands mid-task — you're about to run a command, write a path, call a tool — with no prompt to match. So `/learn` binds a playbook to its **detectable trigger** (a command pattern, a path pattern, a tool name), and this PreToolUse hook surfaces it the instant you reach for that action. It only ever *adds context* — it never blocks and never touches the permission flow.
- **Hard-deny (`learn-guard.sh`).** For a mistake that causes **real, nameable harm** *and* has a clean signature — a path you must never write, a command you must never run — `/learn` appends a spec and this PreToolUse hook **denies the matching call** every time. Data-only: `/learn` appends JSON; no new code runs at match time. This is the one carrier that genuinely makes a mistake *"never again"* — and precisely because it's permanent, the bar to install one is high.
- **Preflight salience (`learn-preflight.sh`).** For a *fuzzy* lesson with no clean signature (how you reason about a claim or a state), there's nothing to enforce — so `/learn` sharpens a single line in a ~5-line verify-first checklist that gets injected at the start of every session. Honest framing: this makes a miss *less likely, not impossible*.

## Harm class first, detectability second

Not all mistakes are equal, and the tool refuses to pretend otherwise. The classification is **harm first** — detectability only decides how *reliably* a mechanism can fire, never *which* mechanism it earns:

- **Real harm + detectable** (`data_loss` / `security` / `environment_breakage` / `tool_semantics`) → `guard-specs.json` + the deny hook. Mechanically blocked. This is real "never again."
- **Detectable but only a preference / style / pacing** → a regex *could* block it, but it **shouldn't** — a reversible preference must never require editing JSON to escape. It gets a soft, overridable `inform` surface instead.
- **Fuzzy** (a judgment call, "asserted before verifying") → no shell hook can reliably detect it, so it **cannot be guaranteed** — only made *less likely* via salience. The tool never calls a fuzzy lesson "fixed."

The corollary the redesign learned the hard way: **don't pour fuzzy lessons into the preflight**, and **don't ossify a one-time preference into a forever-global deny**. Both bloat the system with rules that fight you later. As of v3 the preflight is **frozen by default** — its ~5 lines are saturated, and the only admissible edit is one where the old wording, read literally, would have *permitted* the mistake that just happened.

## The capture bar: three gates

The failure mode of any capture loop is that it only ever grows. "It's true and it's about this workflow" passes everything, so the playbook set bloats until retrieval degrades and every stage file is a tax. v3 puts three gates in front of a capture — the first two decide **whether** to write, the third decides **where**:

1. **Cost-of-not-knowing.** Save only if the user explained it, it cost real time / dead-ends, **it fails silently** (no error, wrong output — this counts even when you caught it instantly and lost zero time), or the user said "save this." A true-but-tiny nuance that costs nothing and fails *loudly* is not a capture. Neither is a struggle that was situation-specific and won't recur.
2. **Second-use.** Before creating a new *re-injected* entry (one with its own `description:` competing for retrieval), write one sentence naming a concrete, **different** future task where that description would match — and that sentence may contain **no proper noun, ID, or number that exists only in this session.** Can't write it? The lesson isn't general enough to be re-injected: fold it into the body of the playbook that already owns the workflow, or drop it.
3. **Fire-condition.** Does the line fire on *every* run of the workflow, or only on a *symptom* (one endpoint's error, a retry, a weird input)? Every run → the stage file. Symptom-only → an on-demand `recovery/` shelf, titled with the symptom a cold operator would search for. **This is the one that gets skipped**: stage files are read in full on every run, so an append there is a permanent per-run tax, while the shelf costs nothing until the symptom fires. One dogfooded skill grew **+26% in 12 days** — 199 new lines into always-read stages, 2 into `recovery/`.

## Contradictions are escalated, never resolved

Once you have more than a couple of playbook files on one pipeline, two of them eventually prescribe **opposite actions for the same step** — and whichever one the agent happened to read silently becomes policy. `/learn` refuses to break that tie: no newest-wins, no "the file already open", no "the more detailed one." It **blocks the write to both files**, finishes the rest of the pass, and surfaces the conflict with both rules quoted, the step where they collide, and its own read plus the evidence for it. You decide; it brings the analysis so you don't have to reconstruct it. An unresolved tie stays unresolved and re-surfaces next run.

The flip side is **supersede = propagate**: when a session produces evidence that an existing rule is *wrong*, updating one file is not done. `grep -ril` the old rule's distinctive strings across the whole live doc set and fix every site in the same act — otherwise the stale copy wins the next time a different file gets read first.

## What's in the box

| File | Role |
|---|---|
| `commands/learn.md` | The skill. **0.5** escalate doc contradictions, **A** capture playbooks behind the three gates (the core), **A2** fold a graded review's named defects into the right checklist, **B** mistake → harm-class-gated guard / inform / salience, **C** drain the maintenance reports. Forward-only; no audit journal, no taxonomy, no registry. |
| `hooks/mem-surface.sh` | `PreToolUse` (**soft, inform-only**). Surfaces the playbook bound to a command/path/tool you're about to use. Reads `inform-specs.json`. Never blocks; never changes permissions. Registered on **all** tools. |
| `hooks/learn-guard.sh` | `PreToolUse` (**hard, fail-open on error**). Reads `guard-specs.json` and **denies** a tool call matching a guard `/learn` installed for a previously-corrected, *detectable* mistake. No-op until a spec exists. |
| `hooks/commit-on-red-guard.sh` | `PreToolUse(Bash)` example guard. Catches a `git commit` joined to a test/check by an unconditional operator (`;`, `\|\|`, `&`) so the commit fires even on red. Ships in **log mode** — flip to enforce once the log shows the false-alarm rate is low. |
| `hooks/learn-preflight.sh` | `SessionStart` (**soft**). Injects the verify-first checklist at session start. |
| `hooks/learn-trigger.sh` | `UserPromptSubmit` (**soft**). Fires once/session when you signal you're wrapping up → nudges "consider `/learn`." Never blocks. |
| `scripts/inform-specs-lint.sh` | Collision linter for `inform-specs.json`. The spec file is append-only, so duplicate triggers pointing at the same playbook accumulate and their `note` text silently **drifts apart** (one stale, one current). Run after every append; a same-trigger→*different* playbook fan-out is allowed. |
| `scripts/learn-finalize.sh` | Fixed-path closeout: appends the run log and archives a handled consolidation digest. Exists so `/learn` never hand-composes a multi-line shell blob — that blob can't match a Bash prefix-allow rule, so it re-prompts for approval on every single run. |
| `state/verify-preflight.seed.md` | Starter checklist — ~5 universal verification principles, one line each. **Frozen by default** (see Step B). |
| `state/guard-specs.seed.json` | Starter (empty) deny list. Empty = the guard is a total no-op. |
| `state/inform-specs.seed.json` | Starter (empty) inform list for `mem-surface`. Empty = no-op. |

## Install

Requires `python3` (for the installer's settings.json edit) and `jq` (the hooks no-op gracefully without it, so they never break your session — but they only *do* anything with `jq` present).

```bash
git clone https://github.com/obatried/recursive-learn
cd recursive-learn
./install.sh        # copies the skill + hooks into ~/.claude and registers the hooks
```

The installer backs up `settings.json` first and validates the JSON after. It's idempotent, and it *migrates* an older narrow `mem-surface` registration to the `"*"` matcher rather than leaving a duplicate behind. To uninstall, remove the hook entries from `~/.claude/settings.json` and delete the copied files.

**Allowlist the two helper scripts** so `/learn`'s closeout doesn't prompt on every run — in `~/.claude/settings.json` under `permissions.allow`:

```
Bash(~/.claude/scripts/learn-finalize.sh:*)
Bash(~/.claude/scripts/inform-specs-lint.sh:*)
```

**Memory dir.** The capture + surface carriers read and write playbook files in a memory dir. Point `mem-surface.sh` at yours via the `CLAUDE_MEMORY_DIR` env var (default `~/.claude/memory`). If you want a richer capture/recall/search layer underneath this loop, see the companion project **[total-recall](https://github.com/obatried/total-recall)** — recursive-learn is the *learning loop*; total-recall is the *memory system* it writes into.

**Surfacing on other tools.** As of v3 the installer registers `mem-surface` with the `"*"` matcher, so an `inform_on_tool` spec fires for **any** tool — including a specific MCP tool — with no settings edit. That's affordable because the spec scan is now a single `jq` pass plus a pure-bash loop; the old per-entry loop spawned four `jq` processes per spec (~3s per tool call at 120 specs, now ~0.1s), and a non-`Bash`/non-write call skips every regex entry entirely.

## Philosophy

- **Forward-only.** Reflect on the session in front of you. Never audit history to score yourself.
- **Earn the block.** The soft layers (capture, inform, preflight, trigger) never block. The one always-on hard-deny — `learn-guard` — fires only on an **exact spec you installed *after* a real mistake already happened**, so the block is earned by the incident, not guessed up front (and an empty spec file is a total no-op). *Broad or heuristic* guards like `commit-on-red` ship in **log mode**: you read the log first and flip to enforce only once its false-alarm rate is low. A blocking hook that misfires is the fastest way to make you hate your own tooling.
- **Drain the reports, don't just write them.** Every maintenance signal a memory system produces — merge digests, never-fired entries, recall near-misses — has the same failure mode: it gets *generated* and never *acted on*, so it rots in a directory while the corpus keeps growing. Step C is the consumer, and it routes by **reversibility, not by habit**: a fix that only adds or sharpens a file you already own gets **applied in the run that found it**, and only destructive moves (merging, archiving) are propose-only. A found-but-unapplied fix is a gap that stays open until you happen to say yes.
- **Keep it small.** Capture + surface + deny. The moment it grows a registry, a taxonomy, or a self-grading audit, it has drifted back into documentation theater. Resist it.

## Works well with: total-recall

recursive-learn handles *self-correction*. [total-recall](https://github.com/obatried/total-recall)
handles *memory* — the `CLAUDE.md` / `MEMORY.md` capture, structure, and search that let a fresh session
pick up where the last one left off. They compose: run total-recall's `meta-install.sh` to set up both
at once ("give your AI a memory" + a `/learn` loop in one command).

## License

MIT.
