Recursive learning pass. Its job: turn what just happened into durable behavior change for next time — **primarily by capturing reusable playbooks so a problem solved once is never re-solved or re-explained**, and secondarily by hard-stopping a *harmful*, detectable mistake from recurring (a detectable mistake that's merely a preference gets a soft, overridable reminder, not a permanent guard — see Step B). Run at the end of a substantive session, when something notable happened (you explained a procedure, the agent burned real time finding a working path, a failure/recovery, repeated pushback), or the moment the only remaining move is WAITING on an external run/job — a wait boundary is a learn boundary; run it during the wait, unprompted.

**Scope discipline (read this first — it is the whole point).** This skill used to be a mistake-auditing journal: it re-read every claim, sorted misses into families, ran an escalation ladder, and grew a lesson registry. That produced *documentation, not behavior change* — a note in a file never changed the next session, because the only things that carry over are (1) what gets re-injected into context and (2) what a hook enforces. So this skill now does just two things well: **capture playbooks** and, when a real mistake recurs, **install a guard or sharpen the one salience line.** If you feel the urge to classify a family, update a registry, or write a per-claim audit table — STOP. That was the old shape. Keep this skill small forever.

**Write every capture TIGHT.** Verbosity is the recurring bug: a one-screen lesson gets written as a wall — rule stated, then re-defended with parentheticals, inline dated citations, and restatements. A capture is *minimum words that change next time*. Shape: lead with the rule in ONE sentence; bullets over paragraphs; state each point ONCE; **state the POSITIVE rule ("do X"), not negation+rule ("not Y — do X") — a negation earns words only when the ban IS the rule**; **dates live in frontmatter/git, NEVER inline**; no parenthetical re-arguing a clause already made. Only the `description:` re-surfaces at decision time, so every extra word there is signal-diluting debt. The test before saving: *could a senior engineer cut this 50% without losing a rule?* If yes, it isn't done.

**Forward-only (read this too).** This skill reflects on the session that *just happened* — what you learned, fixed, or got corrected on, while it's in front of you. It does **NOT** mine, re-read, or audit past transcripts to score yourself. A backward audit-sample is a trap: it manufactures activity, costs a sweep every run, and measures the wrong axis. Learning happens going forward, not by grading history.

---

## Step 0 — Gate (don't run on nothing)

Run only if the session was substantive — judge qualitatively, don't tally tool calls: you explained how to do something, the agent spent real effort finding a working path, a notable failure/recovery happened, or there was real pushback. If none apply, output `/learn: skipped (non-substantive session)` and stop.

## Step 0.5 — Contradiction → STOP, the user breaks the tie

If two live docs prescribe **opposite actions** for the same step — honoring one violates the other — you do **not** resolve it. Not by newest-wins, not by "the file already open", not by "the more detailed one". Multi-file playbook sets are where this bites: two files, same stage, different instruction, and whichever one the agent happened to read silently becomes policy.

- **Contradiction** (can't honor both) → **block the write to BOTH files.** Finish the rest of the pass so it isn't wasted, then surface the tie: both rules quoted verbatim with paths, the step where they collide, what each one would have made you do differently, and **your read of which is right plus the evidence for it** (which one the last working run actually followed, which one a live artifact contradicts, which was written after the other). The user's call still lands it — but bring the analysis, don't make them redo it.
- **Overlap** (both fire, both honorable) → not a tie. Write the `Precedence:` line yourself.
- An unresolved tie stays unresolved and re-surfaces next `/learn`. A later session must never quietly resolve it.
- **On the user's pick:** the winner propagates (SUPERSEDE rule in Step A); the loser is corrected in place at **every** site — or, if it was right in a narrower context, kept with a `Precedence:` line naming that scope. If the project has a drift detector, add the losing string to it as a tripwire.

## Step A — Capture playbooks (THE CORE)

Ask: **did I work out HOW to do something this session that I'd otherwise have to re-figure-out next time — or did the user explain a procedure they should never have to explain again?** Tells — I spent more than a call or two discovering a method, hit a "that path was blocked, this one worked" moment, found a non-obvious auth/tool/navigation path, or the user walked me through steps.

**Capture bar — THREE gates, all required. Gates 1-2 decide WHETHER to write; gate 3 decides WHERE. (1-2 stop one-time overfit; 3 stops unbounded playbook growth.)**

1. **Cost-of-not-knowing (necessary, not sufficient):** the user explained it, OR it cost real time / dead-ends, OR **it fails SILENTLY** (no error, wrong output, caught downstream or never — this qualifies even when you spotted it instantly and lost zero time), OR the user said "save this." Everything else: skip. Two skips worth naming: a true-but-tiny nuance that cost nothing and fails LOUDLY is not a capture; and struggle that was situation-specific (a flaky endpoint, a bad handoff) won't recur, so it isn't one either. **"It's true and it's about this workflow" is NOT the bar** — that bar passes everything, which is how a playbook only ever grows.
2. **Second-use gate:** before creating a NEW re-injected entry — a new `reference_*.md` with its own `description:` + index pointer — write ONE sentence naming a concrete, DIFFERENT future task (a different project or workload, NOT a rerun of today's) where that `description` would match, and that sentence may contain **no proper noun, ID, or number that exists only in this session**. Can't write it → the lesson is not general enough for re-injected memory: fold it as a line into the **body** of the existing playbook that owns the workflow (specifics are cheap in a body, expensive in a `description:` — but a body is only free if it's read ON DEMAND, so route it with gate 3), or drop it. An explicit "save this" from the user overrides gate 2. The sentence is reported in the Output block, so it cannot be skipped.
3. **Fire-condition gate — decides WHERE, not whether.** Does the line fire on EVERY run of the workflow, or only on a SYMPTOM (one endpoint's error, a retry, a particular input shape)? **Every run → the stage/playbook file. Symptom-only → the on-demand shelf** (a `recovery/` dir in the skill, or a symptom-keyed section), titled with the symptom a cold operator would search for. A skill's stage files are read IN FULL every run, so an append there is a permanent per-run tax on all future runs; the on-demand shelf costs nothing until the symptom fires. **Most captures are symptom-triggered and get mis-routed to stage files by default** — one dogfooded closeout skill grew +26% in 12 days: 199 new lines went into always-read stages, 2 into `recovery/`.

For each capture that clears gates 1-2 (and is routed by gate 3), write or refresh a `reference_*.md` playbook in your memory/playbook dir:

- **Index by TASK SHAPE, not the incident.** The `description:` and any index pointer must read like the words I'd reach for next time — "pull the meeting notes for a call", "get the value needed to do a billing write op" — NOT "that thing on 6/3". This is what makes retrieval actually fire.
- Record the **working path** (exact commands / clicks / tool sequence) AND the **dead-ends to skip**, so next time's re-discovery cost is zero. (Incident specifics belong HERE, in the body — not in the `description:`.)
- If a playbook already covers it, **deepen that one** — don't spawn a duplicate.
- **⭐ SUPERSEDE = PROPAGATE.** Newest-wins fires ONLY when THIS session produced the evidence that the old rule is wrong; a contradiction you merely *noticed* is Step 0.5, not this. When the lesson CORRECTS or REVOKES an existing rule (a changed threshold, a dead endpoint, a retired mechanic, a reversed doctrine), updating one file is NOT done: `grep -ril` the old rule's distinctive strings across the whole live doc set for that project (memory tree + any co-located playbooks/scripts) and fix EVERY site in the same act — newest-wins, mark the old rule superseded in place. Then add the stale string as a tripwire to the project's drift detector if one exists.
- **Wire it to fire at point-of-need (the retrieval upgrade — do this or the file stays inert).** A playbook only changes behavior if it gets re-injected at the moment it's needed. Prompt-time recall covers the case where my *prompt* keyword-matches. But if the playbook applies at a **mid-task action** — about to run a command, write to a path, or call a tool — there's no prompt to match, so bind it directly: if the playbook has a *detectable trigger* (a Bash command pattern, a file-path pattern, or an exact tool name), append an `inform_*` spec to `~/.claude/state/guards/inform-specs.json`. The `mem-surface.sh` PreToolUse hook then surfaces this playbook the instant I reach for that action next time — no keyword luck required. This is the inform-side twin of Step B's deny guard.
  ```bash
  jq '. += [{"type":"inform_on_bash_regex","pattern":"<anchored ERE>","memory":"reference_xxx.md","note":"one-line why/what"}]' \
     ~/.claude/state/guards/inform-specs.json > ~/.claude/state/guards/.is.$$ \
     && mv ~/.claude/state/guards/.is.$$ ~/.claude/state/guards/inform-specs.json
  # other types: {"type":"inform_on_path_regex","path_regex":"<ERE>",...}  |  {"type":"inform_on_tool","tool":"<exact tool_name>",...}
  ~/.claude/scripts/inform-specs-lint.sh   # MUST pass after appending. A non-zero exit = your new entry
  # COLLIDES with an existing (type+trigger+memory) — do NOT leave a 2nd row. DEEPEN the existing entry's
  # note in place instead (the "deepen, don't duplicate" rule). Same trigger -> DIFFERENT memory is fine (fan-out).
  ```
  `memory` is the file path RELATIVE to your memory dir. Prefer binding to an **early** action in the workflow (a first read/list), so the runbook lands *before* the consequential write — the hook informs, it doesn't block. No detectable trigger? Skip this; prompt-time recall is the only carrier for purely conversational playbooks.

## Step A2 — Structured-review fold-back (ONLY if a graded review returned named defects this session)

Skip entirely unless an external review handed back **named, located** defects this session — an automated grader, a client quality report, a human PR/code review, a CI gate, or a QA report. No such verdict → skip silently. (Judge it — you have the whole session in front of you; don't keyword-guess.)

A structured verdict is **proof a playbook/checklist may be incomplete**, so the job is to ACT, not just note. **The failure this step exists to prevent: summarizing the headline lesson while the individual named defects never make it into the checklist** ("we learned but didn't do it"). So:

- **Walk the FULL defect list, not the headline.** For EACH clearly-defined defect, do one of: (a) fold a compact preventive rule into the relevant pre-submit checklist/playbook (refresh an existing line, don't duplicate); or (b) skip it *explicitly* as one-off / ambiguous / not-preventable-before-submit / already-covered. Mechanizable (regex / path / metadata check) → the checklist's machine-checks; judgment-only → one sharp line; graduate judgment→mechanizable once a pattern recurs ~2–3×.
- **Reconcile before ending:** every defect must be accounted for — added, refreshed, already-covered, or deliberately skipped. Report the count in the Output block (this reconciliation IS the guard against noted-but-not-acted).
- **Fold into the workflow's own pre-submit home** — the playbook or checklist that governs that workflow, not a global note. If that workflow has a scripted pre-submit gate, append the rejection+fix to its ledger, add a check if mechanizable, then **re-run the gate to confirm it now catches it**. (A clean review with no defects → capture the "what good looked like" positive reference instead.)
- **Gate principle (don't over-build):** the external grader is the source of truth — the durable rule is procedural ("run it before submit, fix, re-run until clean, fold back any new defect class"). Build a LOCAL scripted check only for the cheap, recurring, deterministic subset (metadata, banned strings, formatting); never clone the grader wholesale — it drifts from their real criteria and gives false-green confidence.

## Step B — Mistake → minimal (no journal, no taxonomy)

Was there a notably-wrong **action** this session (not just an imperfect phrasing)? If no, skip this step entirely.

**Also — user corrections.** Did the user push back on or correct your behavior this session (incl. soft signals: "actually", "instead", "hmm", or re-stating an ask they already made)? If it's a correction worth not repeating, generalize its ROOT (not the surface complaint) — then find its canonical owner and EDIT that: a CLAUDE.md section, the playbook that runs the workflow, or project/topic memory. Workflow mechanics — steps, SEQUENCE/ORDER, method, timings, pacing — belong in the playbook that RUNS that workflow, NEVER a behavioral note (not even a project-scoped one): a rule that isn't in the playbook doing the work never changes the work. Ask first "which playbook/skill owns this workflow?" and edit THAT; a `feedback_*` note is a rare last resort, written only when no owner exists. Judgment, not an exhaustive per-message audit.

**Feedback-as-debt.** Standalone `feedback_*` notes are the part of a memory corpus most likely to become dead weight — a note with no detectable trigger can never auto-surface, so it's write-only: it costs retrieval precision and never pays it back. So: (1) **default HARD to editing a canonical owner** (CLAUDE.md / playbook / project memory) over spawning a new note; (2) a new `feedback_*.md` is admissible ONLY if it has a **detectable trigger** you can wire to an `inform_*` spec (else it can't fire and is debt on creation); (3) **if the same correction family recurs ~3+ times, STOP writing notes — fix the root mechanism** (a hook, a CLAUDE.md rule, or the workflow itself); (4) a feedback note is CURRENT-TRUTH, not a changelog — when a recurrence revises it, REWRITE it to the live rule; never bolt on a dated "CORRECTED on \<date\>" incident paragraph (git history holds the timeline). A note that can't fire isn't a memory, it's litter.

If yes, classify it — **by invariance and harm FIRST, detectability second.** Detectability (can you write an exact path or command pattern for it?) only decides how *reliably* a mechanism can fire; it does NOT earn the strongest mechanism. A regex match means you *can* hard-block, not that you *should*.

**A hard guard (`deny_*` in `guard-specs.json`) is a global safety rail, not a strong memory** — it is permanent, applies in every project and session, and escaping it means hand-editing JSON. So it is admissible ONLY when you can name the **harm class** it prevents: `data_loss`, `security`, `environment_breakage`, or `tool_semantics` (a tool/shell that silently does the wrong thing). **If the best label you can give the correction is `preference`, `style`, `workflow`, or `pacing` → it gets NO hard guard, even if it's perfectly detectable.** Sanity test: a hard guard's `reason` must read as a timeless rule on its own; if you can't write it without "the user said so this once", it is a contextual call, not an invariant. (A cautionary case: a one-session "stop pacing yourself" instruction was regex-detectable, so it ossified into a forever-global deny that later fought the user's own intent and had to be torn out by hand. Detectable ≠ worth enforcing forever.)

Then route by mechanism:

- **Harm-class invariant + detectable** → **install the hard guard NOW**, on first identification, phrased timelessly (kill-the-browser, `rm -rf /`, a shell idiom that returns a false-green exit code). Append a spec to `~/.claude/state/guards/guard-specs.json`; the `learn-guard.sh` PreToolUse hook reads it and DENIES the matching call.
  ```bash
  jq '. += [{"type":"deny_write_path","path":"/ABS/PATH","reason":"why + what to do instead"}]' \
     ~/.claude/state/guards/guard-specs.json > ~/.claude/state/guards/.gs.$$ \
     && mv ~/.claude/state/guards/.gs.$$ ~/.claude/state/guards/guard-specs.json
  # command form: {"type":"deny_bash_regex","pattern":"<portable, ANCHORED ERE>","reason":"..."}
  ```
  Use the **absolute** path (exact match); keep regexes **portable and anchored** so they can't over-block.
- **Detectable but preference / workflow / pacing / style** → do **NOT** hard-block. Bind an `inform_*` surface (Step A's mechanism) so it *reminds* at the action point and stays **overridable in the moment**, and/or home it in the relevant project's memory. A reversible preference must never require editing JSON to escape.
- **Fuzzy + universal** (about how you reason about any claim or state) → **`verify-preflight.md` is FROZEN — default is NO EDIT.** Its ~5 lines are saturated: they already say everything general there is to say about verifying before asserting, so a new lesson either already fits a line (no edit needed) or doesn't fit (don't cram it in). This branch is the only ungated one in Step B, which is exactly why it collects the churn — rewording a line that was already correct changes nothing and is the failure mode to avoid. Report `already covered — no edit` and move on.
  - **The one admissible edit:** the current line, read literally, would have **PERMITTED** this session's wrong move. Name the move the old wording lets through and the new one forbids — can't name it, no edit. A line that already covered the case and still didn't stop you is a mechanism failure, not a wording failure: better adjectives won't fix it, so bind a detectable `inform_*` trigger, home it in the project playbook, or let the lesson go.
- **Fuzzy + project/tool-scoped** (it names a specific product, tool, file format, or workflow) → it belongs in that project's memory or the relevant `reference_*` playbook, which prompt-time recall already surfaces on mention. That's **Step A's job — deepen the playbook there.** Do **NOT** copy it into the global preflight: that is exactly what bloats it — a lossy duplicate of a lesson already homed, broadcast to every unrelated session.

## Step C — Close the dedup loop + demotion valve + recall-miss review (every run — cheap)

Capture without maintenance just grows an unmaintained pile: the corpus only grows, and retrieval degrades as it bloats. This step is the consumer that drains it. Every lever here has the same failure mode — the report gets *written* and never *acted on*.

**Route by reversibility, not by habit.** A fix that only ADDS or SHARPENS a file you already own — **apply it in the run that found it, then report what you did.** A found-but-unapplied fix is a gap that stays open until the user happens to say yes, which defeats the point of the pass. Only DESTRUCTIVE moves (merging files, archiving a demoted note) are propose-only. This holds for every lever below and any added later.

**1. Merge digest.** If you run a periodic consolidation pass (e.g. a weekly job that clusters near-duplicate memories and writes proposals to `~/.claude/state/reminders/memory-consolidate-*.md`), this is where you consume it. `ls` the live ones (NOT `actioned/`); if none, skip to lever 2. Otherwise read the **newest**, count proposed **merges** (clusters carrying a `SUPERSEDES:` line; ignore `DISTINCT — keep separate`), and surface ONE line: *"M pending memory merges from `<date>` (+K prune candidates) — apply now?"* Don't dump the whole digest unprompted. **Only on a yes**, apply each merge with the standard memory-mutation discipline (non-negotiable):
   - Back up every touched file (`*.bak-<date>`); never delete irreversibly — `mv` superseded files to an `archive/` dir.
   - **Verify each merge preserves all nuance + every cross-link before applying.** A second read-only review pass (a different model is ideal) is cheap here; use it, but spot-verify its concrete file claims — a reviewer can fabricate line facts. Never auto-merge on a digest's say-so alone.
   - Pick the survivor by inbound-reference count; repoint inbound refs; collapse duplicate index lines.

   After a digest is handled (applied, OR the user says skip-for-good), archive it with **exactly** `~/.claude/scripts/learn-finalize.sh --digest-date <YYYY-MM-DD>` so it stops resurfacing. Run it as its own standalone command; do NOT compose a raw `mv`/`mkdir` or bundle it with other shell steps — a multi-line/commented blob defeats the permission allow-rule and re-triggers an approval prompt. If the user says "later", leave it: it resurfaces next `/learn`, and that gentle nag every session IS the forcing function that stops the rot.

**2. Demotion valve (the exit for anything that slipped the capture gate).** If your memory layer can report which re-injected entries have **never once fired** in ~30 days, read it and surface those in ONE line as demotion candidates alongside the merges. Same surface-and-propose discipline; on a yes, back up and `mv` the note to `archive/`. A re-injected note that has never once fired is paying no retrieval rent.

**3. Recall-miss review (the demotion valve's twin — *should-have-fired* instead of *never-fired*).** If your prompt-time recall hook logs near-misses (a relevant memory existed but the gate stayed silent), that signal is captured and usually never acted on. Review it read-only — e.g. for the companion [total-recall](https://github.com/obatried/total-recall) recall hook:
   ```bash
   jq -r '"\(.top_candidate)\t\(.prompt)"' ~/.cache/total-recall/recall-misses.jsonl 2>/dev/null \
     | sort | uniq -c | sort -rn | head -5
   ```
   **Expect this to be near-empty most runs — empirically most of the log is noise**, so subtract it first: drop misses another carrier already handled (e.g. the wrap-up trigger hook), misses older than ~45 days, and files you've already reviewed. For each surviving candidate, judge from its sample prompts — the frequency count is a weak prior, the prompts are the evidence:
   - **On-topic (a real gap)** → fix findability, cheapest lever first: sharpen the file's `description:` toward the wording the missed prompts actually used (task-shape, Step A); or, if the miss lands at a detectable action, add an `inform_*` trigger (Step A). Add a recall **alias** only for a **true single-token synonym** (`invoice, bill`) — **never a workflow/topic bundle** (`wrap, close, document`): the group counts as ONE concept, so bundling co-occurring words *lowers* the match count and makes recall worse.
   - **Off-topic (an attractor)** or **already owned by a dedicated carrier** → do NOT alias; there's nothing to fix.

   **Apply the lever in this run — don't ask** (reversible; see the routing rule above), backing up each touched file, then report it in the Output block. **Fix every carrier, not just the owner file:** `description:` is only the prompt-time path — any index pointer or `inform_*` note that RESTATES the rule carries the same omission, and that tool-bound pointer is the one that actually fires mid-task. `grep -ril` the rule's distinctive strings and correct every site in the same act. **Then mark the file reviewed** (however your report tracks state) so historical rows stop re-surfacing every run — without that, this consumer rots into the same write-only pile it exists to drain.

Keep it conservative: surface similarity ≠ duplication; when a cluster is genuinely two lessons, leave it.

## Output

```
/learn
- Playbooks captured/refreshed: N (slug — 2nd-use: <different-future-task sentence>) | none
- Review fold-back: N folded / M already-covered / K skipped (reason) | n/a (no graded review)
- Contradictions: N surfaced w/ my read (awaiting tie-break) | none
- Mistake → guard installed: <path/pattern> | salience line sharpened (<move the old wording permitted>) | already covered — no edit | none
- Memory maintenance: M merges applied (date) | K pending — surfaced | D never-fired demotion candidates | G recall-gap fixes APPLIED (desc/inform/alias + carriers) | none pending
- Still open: one line | nothing
```

Then log the run by running **exactly** this one standalone command (do NOT hand-compose `mkdir`/`printf`/redirects/`echo` or a multi-line blob — that defeats the permission allow-rule and re-triggers an approval prompt):

```
~/.claude/scripts/learn-finalize.sh --log --session <slug> --playbooks <N> --guard <true|false> --salience <true|false>
```

The script appends one JSON line `{ts, session, playbooks_captured, guard_installed, salience_sharpened, recurring_items: []}` to `~/.claude/state/learn/learn-runs.jsonl` (it generates the UTC `ts` itself). If a digest also got actioned this run, fold both into one call by adding `--digest-date <YYYY-MM-DD>`.
