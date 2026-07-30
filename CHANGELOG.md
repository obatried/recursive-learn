# Changelog

## v3 — gated capture, escalated contradictions, drained reports

Five months of dogfooding, folded back. v2 made capture the core but left it **ungated** — anything true about the workflow qualified, so the playbook set only ever grew and the always-read stage files grew with it. v3 is mostly about the brakes.

**What changed:**

- **The capture bar is now three gates (Step A).** *Cost-of-not-knowing* (explained / cost real time / **fails silently** / "save this") and the *second-use gate* (name a concrete, different future task in one sentence containing no proper noun or ID unique to this session) decide **whether** to write. The new *fire-condition gate* decides **where**: every-run lines go in the stage/playbook file, symptom-only lines go on an on-demand `recovery/` shelf. That third gate is the one that gets skipped by default — one dogfooded skill grew +26% in 12 days, with 199 new lines landing in always-read stages and 2 on the shelf.
- **Contradictions are escalated, never resolved (new Step 0.5).** When two live docs prescribe opposite actions for the same step, `/learn` blocks the write to *both*, finishes the rest of the pass, and surfaces the tie with both rules quoted plus its own read and the evidence — no newest-wins, no "the file already open." Unresolved ties re-surface next run.
- **Supersede = propagate (Step A).** When a session proves an existing rule wrong, `grep -ril` the old rule's distinctive strings and fix **every** site in the same act. Updating one file leaves a stale copy that wins whenever a different file is read first.
- **The preflight is frozen (Step B).** Its ~5 lines are saturated, so the default is now **no edit** — this was the one ungated branch in Step B and it collected all the churn. The single admissible edit: the old wording, read literally, would have *permitted* the mistake that just happened, and you can name the move it let through. A line that already covered the case and still didn't stop you is a mechanism failure, not a wording failure.
- **Write every capture tight.** Explicit compression rules: lead with the rule in one sentence, state each point once, **state the positive rule** rather than negation-plus-rule, and keep dates in frontmatter/git rather than inline. Only `description:` re-surfaces at decision time, so every extra word there is signal-diluting debt.
- **Step C drains three reports, and applies reversible fixes without asking.** Alongside the merge digest it now consumes a **demotion valve** (re-injected entries that have never once fired) and a **recall-miss review** (a relevant memory existed but prompt-time recall stayed silent). Routing rule: add-or-sharpen fixes are applied in the run that finds them; only destructive moves stay propose-only. Recall fixes must be applied to **every carrier** — the `description:`, the index pointer, and any `inform_*` note that restates the rule — since the tool-bound one is what actually fires mid-task.
- **`scripts/learn-finalize.sh` (new).** Fixed-path closeout for the run log + digest archiving. The old inline `mkdir`/`printf`/redirect blob could never match a Bash prefix-allow rule, so it re-prompted for approval every single run. `--digest-date` is validated to `YYYY-MM-DD` and the path is built internally; arbitrary paths are never moved.
- **`scripts/inform-specs-lint.sh` (new).** `inform-specs.json` is append-only, so duplicate triggers pointing at the same playbook accumulate and their `note` text drifts apart — one stale, one current. The lint is now a required step after every append. Same trigger → *different* playbook is intentional fan-out and stays allowed.
- **`mem-surface.sh` is ~30× faster and registered on all tools.** The spec scan became one `jq` pass emitting `\x1f`-joined raw records plus a pure-bash loop; the old per-entry loop spawned four `jq` processes per spec (~3s per tool call at 120 specs, now ~0.1s). With that headroom the installer registers the hook with the `"*"` matcher, so `inform_on_tool` fires for any tool — including MCP tools — with no settings edit. The installer *migrates* an existing narrow registration instead of leaving a duplicate that would fire twice.
- **Feedback-as-debt, rule 4.** A `feedback_*` note is current-truth, not a changelog: when a recurrence revises it, rewrite it to the live rule instead of bolting on a dated "CORRECTED on `<date>`" paragraph. Git history holds the timeline.
- **Wait boundaries are learn boundaries.** The moment the only remaining move is waiting on an external run, that's a trigger — run the pass during the wait.

## v2.1 — harm-class gate

Sharpening from continued dogfooding. The v2 routing made *detectability* the gate for a hard deny — but a regex that *can* match a mistake doesn't mean it *should* be blocked forever.

**What changed:**
- **Harm-class gate in `/learn` (Step B).** A hard deny is now admissible only when you can name the harm class it prevents — `data_loss`, `security`, `environment_breakage`, or `tool_semantics`. A merely-detectable *preference / style / pacing* correction gets a soft, overridable `inform` surface instead, never a permanent deny. (Learned the hard way: a one-session "stop pacing yourself" instruction was regex-able, ossified into a forever-global deny, and later had to be torn out by hand.)
- **Structured-review fold-back (Step A2).** When an external grader/CI/PR review returns *named* defects, walk the full list and fold each into the relevant pre-submit checklist — preventing "we noted the headline lesson but never acted on the individual defects."
- **Feedback-as-debt.** Default to editing a canonical owner (a rulebook section, a playbook, project memory) over spawning a standalone `feedback_*` note; a note with no detectable trigger can never auto-surface, so it's write-only debt.
- **`learn-preflight.sh` fails loud.** Replaced the silent char-cut with per-line (240-char) + bullet-count (8) enforcement that injects a visible ⚠️ warning when the checklist violates its shape, instead of quietly dropping the back half.
- **`learn-trigger.sh` self-hygiene.** Prunes stale per-session throttle files (>7 days) so they don't accumulate on a long-lived install.

## v2 — forward-only reshape

A significant simplification, learned from dogfooding the v1 design.

**What changed:** v1 was a *mistake-auditing journal* — at session end it re-scanned the assistant's own claims, sorted misses into families, ran an L0/L1/L2 escalation ladder, and grew a lesson registry. In practice that produced **documentation, not behavior change**: a note in a file doesn't alter the next session unless something re-injects it or a hook enforces it, and the registry/ladder mostly measured *activity* (lessons written) rather than *outcome* (mistakes avoided).

**What it is now:** a forward-only loop that does two things well —
1. **Capture reusable playbooks** indexed by task shape, so a solved problem is never re-solved or re-explained. *(promoted to the core)*
2. **Hard-stop a detectable mistake** with a deny guard, or — for a fuzzy mistake — sharpen one line in a deliberately tiny verify-first preflight.

**Removed:** the assertion-audit step, the family taxonomy, the lesson registry, and the L0/L1/L2 escalation ladder. **Removed the backward audit-sample** that re-read old transcripts to self-score — it manufactured busywork and measured the wrong axis.

**Added:**
- `mem-surface.sh` — the **tool-time inform** carrier. Binds a playbook to a detectable trigger (command / path / tool) and re-surfaces it the instant you reach for that action, closing the gap prompt-time recall can't reach. Inform-only; never blocks.
- `commit-on-red-guard.sh` — an example narrow hard-deny (a `git commit` that runs regardless of a failing check in the same command). Ships in log mode.
- `inform-specs.seed.json` — the (empty) spec file `mem-surface` reads.

**Reframed preflight:** the verify-first checklist is now ~5 universal one-line principles. The lesson: pouring fuzzy mistakes into it dilutes salience — sharpen the matching line, never add a bullet.

## v1 — initial release

Self-correcting learning loop: `/learn` assertion-audit + verify-first preflight (SessionStart) + a detectable-mistake deny guard (PreToolUse). The honest detectable-vs-fuzzy split and "start soft, earn the block" philosophy date from here and carry forward.
