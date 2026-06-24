# Changelog

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
