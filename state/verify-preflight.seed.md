# Verify-first preflight (top recurring misses — injected at session start)

This is the live, rolling checklist maintained by `/learn`. Keep it to the 3–5 highest-frequency "asserted before checking" misses. `/learn` promotes/demotes entries each run. Edit by `/learn`, not by hand. Each line carries a `(seen Nx)` recurrence count: if a line is already here and the miss happens AGAIN, `/learn` bumps the count — and at L2 (a second recurrence while on this list) the soft injection has failed and `/learn` must propose an in-the-moment hook, not just bump.

This is a starter seed. `/learn` will reshape it around your actual recurring misses over time.

- Before claiming a thing **exists / doesn't exist / is empty / is done / is sent / passed** — run the check first (Read / Bash / grep / the tool / a screenshot). Cite the check. If you haven't run it, say "I haven't verified" rather than asserting.
- A **tool/linter/automated flag is a pointer, not a verdict.** Before repeating its claim as fact, confirm it against ground truth (open the file, run the thing, read the actual state). These flake; you still verify.
- When the user asks **"did you actually check?"** — that means you asserted from inference. The check they're implying should have come BEFORE the claim, not after the push.
- Prefer the **direct ground-truth source** over the convenient proxy (the rendered UI over the API; the opened file over its config entry; the actual run over the dry inference).
