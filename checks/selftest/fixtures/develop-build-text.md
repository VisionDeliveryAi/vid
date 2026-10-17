When design/ exists: **transcribe, never reinterpret** (CLAUDE.md
transcription law). Every CSS rule derives property-for-property from a
cited canvas section, hex→token the only substitution; no visual value that
exists in neither the canvases nor design/tokens.css. Citations are
sub-screen, marker unit: rule blocks under
`/* Section (P02/populated — REQ-030) */` comments, templates/components
carrying `Design: design/screens/<file> (P02/populated …)`.
checks/design-cite.sh rejects uncited rule blocks at commit;
checks/coverage.sh joins every marker to a citation. The markup for a
state wears every element identifier its canvas section carries
(`data-element="<role>"`, inside the marker's section) — **the surface
instrument is the fidelity evidence** (v0.9.2 3.4, R7, R20): one ledger
test for every screen, the surface test-author pass's product, mapping
each identified element and comparing every property the canvas
declares on it, then the row's pins hook; **a builder never writes a
per-screen test or a pins hook** — a screen's case is red until the
markup carries the marker, the identifiers and the declared values, and
that red is the slice's work, never a deferral. Small judgment deltas
(an added `gap`, `height`→`min-height`) are yours to make and grade's to
judge. A screen the product needs but the design lacks is a product
question, not a license to invent one.

0. Narrate position in one line before starting it ("REQ-004/005 next:
   ingestion") — visibility for debugging, not a checkpoint. Never wait for a
   reply to a narration line. **A process claim carries its evidence class
   (§8.2):** "still running" resolves to an observation — a last test id, a
   last commit sha, an active-query age, a container state — or declares
   itself unverified. Elapsed time is not evidence of progress; a narrative
   built from it is the measured 48-minute-hang class.
1. **Law first, then code.** Anything the slice needs that changes law — a
   seam row, an inventory row for a new route, a rule/exception/difference
   row — lands BEFORE the code, each in its own standalone commit
   (hook-enforced, §4.1). The rhythm for a new route: (1) the test file,
   written by a test-author pass
   (`skills/vid-test-inventory/passes/test-author.md` — spawned with the
   row, the harness contract, the route table and the boundary rule, and
   nothing of this session), committed UNCHANGED as a free ledger
   addition and observed red by a `prove-red` request — record what you observed,
   `sh checks/event.sh 'red-observed row=<id> report=<receipt> case=<case id> assertion="<the failing assertion, quoted>"'`
   (v0.9.6 3.11): the case must be `failed` on the row's real check, never
   `error` (that is its setup or collection) and never absent, and under a
   0.9.6 plan the commit hook refuses a new `proved-red:` stamp without
   it; whether the quoted assertion is the row's promise is your judgment,
   recorded there for a grader to read; (2) the row citing it (law
   commit, stamped `proved-red: <parent-sha>` — the parent is where it was
   observed red); (3) the code that turns it green (v0.9.2 3.1, R1).
   Additions are permitted, never silent; mixing law with work is
   mechanically impossible.
   **A slice that builds a Tier-0 protection also pays its hostility probe
   (§4).** The protection now exists, so the probe can finally be
   materialised and put through the fail-first ritual — attempt the
   forbidden thing through the real public surface, disable the guard by
   the row's own `disable:` toggle, watch the probe fail on its assertion
   about the forbidden effect, restore, watch it pass, stamp
   `proved-red: <sha>` in the row's own law commit. Reading the guard and
   finding it correct is not the ritual: the measured defeats were all of
   guards that were correct and were bypassed by a path nobody read. The
   probe's file is the author pass's to WRITE; the ritual is yours to RUN.
   Each of its runs is a `prove-red` request.
2. Implement inside the seams (ARCHITECTURE.md) and the placement map. Every
   REQ implementation carries a code comment citing its REQ ID; screens cite
   their markers. The import court enforces the seam table at commit: enter
   a module only through its declared public surface, only as a declared
   dependent — a violation means the code or the seam table is wrong; fixing
   the table is a seam change, its own law commit, Seams: line.
3. **Green** the row's ledger test — the builder never creates, edits or
   deletes a file under tests/invariants/ (v0.9.2 3.1, R1): materialised
   tests are made green, never edited into passing, and a test that seems
   wrong is a product question. A surface row's case is red until the
   markup carries the marker, the identifiers and the declared values;
   a journey row's steps are green one transition at a time, operated
   through the real control (3.5).
4. Request an `iterate` run for the rows under work (their built
   neighbours and, after a harness change, the alarm set) and see it
   green — then commit
   with the template message — including the
   `Model:` trailer and, on any commit that adds a file under
   tests/invariants/, the `Tests-by: test-author <date> <batch>` trailer
   the pass's return carries (checks/hooks/commit-msg refuses the addition
   without it; `init` and `builder` are never values — v0.9.2 3.1c). **While any agent runs concurrently, stage by explicit
   pathspec only** (`git add <paths>` — never `git add -A`, `-u`, or `.`):
   a v0.7 ref-lock race swept a concurrent PRD append into a builder's
   commit, an unevidenced-completeness claim on the commit itself (§8) (§9: the model id doing the work; a later model must see
   what it inherits). Ledger-touching commits set `VID_ROLE=fix` —
   legitimate here ONLY because the staged ledger changes are additions
   derived from PRD Fail-ifs, inventory rows, or owner answers (CLAUDE.md
   ledger law). Deleting or weakening an existing ledger assertion is a law
   change and needs an owner answer behind it; if a test seems wrong, ask.

   Every run is a request to the test manager (`vid-test-manager`).
   **Engines:** a breach observed in one engine only is logged
   `sh checks/event.sh 'engine-only breach row=ID engine=<name>'` and reverts the rule for the
   project — the row is BREACHED, not "flaky" (R18).
5. **The census runs in the commit gate** (checks/census.sh, seconds): it
   and the inventory court judge what the commit stages, never the rest of
   the working tree (v0.9.6 3.12) — uncommitted work elsewhere cannot fail
   an unrelated commit, so never stash or park work to get one through. Its
   orphan list is your to-do — a dead path, an unguarded site, an
   unratified divergence, an unreachable surface blocks the commit. An
   orphan whose partner row is still `owed` reports `pending` and does not
   block (debt-aware, §3.4). Never silence an orphan with an exception or
   suppression row you invented for the purpose — those are ratified law
   (standalone commits) and the graders read them. The seam court runs
   beside it (checks/seams.sh): client code touching a seam still owed,
   or an outbound destination no seam row covers, blocks the commit —
   probe first (§3.3), row before code, two legal exits (probed, or
   unreachable-risk with its reason). The inventory court judges the
   hostility rows in the same gate (checks/inventory.sh): a probe cited
   without `proved-red`, a missing or `none` `disable:` toggle, or a probe
   that is the sibling of nothing blocks the commit; a Tier-0 rule with no
   hostility sibling is reported as debt and blocks completion, not this
   commit.
6. Log decisions as you make them (trigger in CLAUDE.md); every commit
   message carries its Decisions: line. A choice about what a stored value
   MEANS — "stored lowercase", "minor units", "never moves backward" —
   lands as a constraint or a test, never prose only (the data-semantics
   landing law, §6.3): these under-fire the decision trigger because they
   do not feel like choices, which is why the law names them. **Never touch checks/ in a slice
   commit** (law-change rule, CLAUDE.md): a court or extractor change is an
   owner-sanctioned act tracing to owner law, standalone, self-test re-run —
   or it is a grade finding.
