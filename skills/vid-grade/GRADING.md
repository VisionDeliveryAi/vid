# The ViD grading engine

Run by vid-grade (the discovery verb — standalone, scheduled, or invoked by
the owner anytime), by vid-develop automatically at completion, and by
vid-fix for the mandatory internal re-grade — scoped to the changed modules
plus their declared dependents (the seam table's blast radius), never the
whole product. Fresh context is the entire value: author ≠ reviewer,
mechanically.

Words matter: a TEST is the ledger running (`sh checks/test.sh` —
deterministic, author-written). A GRADE is this engine — stochastic,
probe-based, hunting what the ledger's authors could not see. Never use one
word for the other.

## Dispatch rules

- Graders receive NO build-session context. Not a summary, not "what I
  built", not your opinions — only the repo path and the PRD. If a grader's
  prompt contains anything the build session believes, the grade is void.
- Read PRD.md (base + Appends; later appends win) and collect every live
  `pilot` REQ — the effective set, `phase: pilot` (the default when absent).
  A `later` REQ is listed in the report as deferred: never batched, never
  ABSENT (v0.9.1 3.6).
- Batch REQs by domain, ~25–30 per grader, so each grader holds a whole
  domain's coherence. Spawn one fresh `vid:grader` subagent per batch
  (Agent tool), in parallel.
- **Every brief is a file (v0.9.3 3.1).** The session writes each brief
  this engine composes — slice verdict, end grade, fix re-grade — as a file
  in vid-develop's "Spawned roles" format (`.vid/briefs/<slice>/grader-<n>.md`:
  the header, the independence paragraph, the numbered items, quotation
  never summary), runs `sh checks/brief.sh` on it, and spawns the grader
  with the repository path and that file. The contents below are what the
  file carries.
- Each grader prompt contains: the repo path; the batch's REQ blocks verbatim
  (ID, tier, phase, behavior, Fail-if) and, for each inventory row in the
  batch's scope, its executor — ledger, browser, census, or deploy-owed
  (`owed: paid by /vid deploy gate N`): the repo grade checks a deploy-owed
  row's in-repo half as a full obligation and its deploy-only half is graded
  at staging, nothing advisory (v0.9.1 3.6); the full fences list; and the
  doctrine below.
- **Three required inputs in every brief** (v0.7 §8): the census tables
  (`sh checks/census.sh --report`); GRADING-CHECKLIST.md verbatim; the
  law-change log since the last grade. Where these exist and are missing
  from a brief, the grade is void. **A fourth, beside them (v0.9.2 3.8,
  R11):** the owed rows for the batch's REQs, verbatim — id, obligation,
  the deferral class and its detail (`owed: <class> — <detail>`), since
  which commit, Tier-0 first — and, in the same block, the flagged tests
  for those REQs: the strength and vacuity reports on their paid rows
  (3.9c, `sh checks/census.sh --report`'s `STR` and `VAC` lines). A grader
  may cite an owed row as the reason a REQ is not PASS, and a flagged test
  as the reason a row's green is not evidence. The brief opens with the
  rows headline (`sh checks/metrics.sh`'s first line: `rows: kept K ·
  unverdicted U · breached B · red R · owed O · deploy-owed D`), never a
  proportion.
- **What every brief withholds (v0.9.3 3.1, R1) — one rule for every
  brief this engine composes: the slice verdict, the end grade, the fix
  re-grade.** On the rows the grader verdicts, the brief carries no prior
  verdict, attempt record, counterexample or fix fact, from any verb; a
  legacy `owed: reverted — "<reason>"` row travels as
  `owed: reverted — (detail withheld from graders)`; and the brief states,
  verbatim:
  *"Do not read under `.vid/` beyond the receipt named above."* The receipt's
  per-case status is information, never a class. The fix re-grade's
  adjacent-path line (element 8) and the law-change log above are inputs
  as they always were; this rule governs the rows the grader verdicts.
- **A journey row is verdicted per transition (v0.9.2 3.5, R8).** Where a
  brief carries a journey row, it lists the row's `transitions:` and the
  grader returns one KEPT / BREACHED per transition, each with its
  file:line evidence; the row-count completeness check applies per
  transition (four transitions → four verdicts, or the pass re-runs); the
  row is KEPT only when every transition is.
- **A fix's re-grade verdicts the fix's rows (v0.9.2 3.11).** When vid-fix
  briefs this engine with the rows the fix materialised or re-paid,
  verbatim with their Fail-ifs, the same fresh grader answers, beside its
  per-REQ verdicts, one KEPT / BREACHED per such row (per transition for a
  journey) — the closed question develop's verdict pass asks — and the
  caller records them as `sh checks/event.sh 'verdict slice=fix-<date> row=<id> result=…
  class=… [transition=k/n] brief=<path> quoted-at=<sha>'` events. One more
  question, no new pass.
- **A BREACHED names its class (v0.9.3 3.6, R8).** Every per-row or
  per-transition BREACHED carries one of three, chosen with its
  counterexample: `product` — the product violates the Fail-if, the
  counterexample in code; `test` — the product may hold, but the test
  cannot observe the promise (it asserts what was already true, stops
  before the effect, binds the wrong boundary): not KEPT on this test;
  `harness` — the instrument failed (fixture order, load sensitivity, an
  errored or absent service). KEPT means the promise holds in the product
  AND the test observes it. An errored case is classed from its
  demonstrated cause: a broken fixture is `harness`; a product defect that
  aborts fixture setup through a public path (a sign-in the fixture
  performs) is `product`, with that counterexample.
- **Every grader return is checked for row-count completeness (§8):**
  verdicts returned must equal REQs briefed — one verdict per REQ, no
  silence. Fewer → re-run that batch with the same brief; a v0.7 grader
  silently skipped 1 of 47, and an unverdicted REQ is an unevidenced
  completeness claim (F11).
- The end grade's scope is what only it can do: cross-slice joins (the
  dead-path halves that span slices), journeys and the browser class, the
  checklist, denominator attacks, decision mining, the law-change review,
  and the queued ROW-AMBIGUOUS rows from develop's verdict passes.

## The grader prompt — five elements, verbatim in spirit

1. **Adversarial stance.** "Your job is to find the counterexample, not to
   assess quality. Assume the build is wrong and try to prove it." And the
   two sentences every verdict brief carries (v0.9.2 3.8, R12; the first
   reworded in v0.9.3 3.6): *"Name the plausible wrong behaviour at this
   test's boundary that the test would not catch; if you can, return
   BREACHED class=test."* and
   *"An assertion that was already true before the action is not evidence
   the action worked."*
2. **Falsifiable criteria only.** "Grade each REQ against its own Fail-if
   text and nothing else. Never grade impressions, effort, or code quality."
3. **Institutional distrust.** "Claims in dispositions, comments, commit
   messages, and docstrings are not evidence. The code is the truth. Verify
   every claimed fix against the code."
4. **The six probes** — apply each, per area:
   - (i) *Who calls this function?* Dead code hides here: a rule whose only
     caller is a test does not exist in the product.
   - (ii) *What happens on the DEFAULT/seeded config?* Walk the seeded/pilot
     configuration end-to-end exactly as shipped — defect classes live
     entirely in defaults.
   - (iii) *What do the test fixtures assume?* Flag ledger tests whose
     fixtures are constructed via model/ORM shortcuts with states production
     paths never produce (register through the view, not
     Model.objects.create with flags pre-set). Fixtures must go through
     public paths; also flag tests that read source files as text.
   - (iv) *Walk one concrete user end-to-end* through each critical journey,
     as that user, step by step — including the unhappy branches (declines,
     expiries, invalid input, permission denials).
   - (v) *What is written but never read* (config fields, columns) — *and
     read but never written?*
   - (vi) *Check second-occurrence branches:* the second tenant, second run,
     second send, the ON CONFLICT/upsert branch. n=1 works, n=2 breaks.
     Include time seams: timezone and day boundaries checked against a
     non-UTC zone.
5. **Verify before reporting.** "Spot-check every finding against the code
   before including it. Rank by consequence to the product, not by count."
6. **Attack the denominators** (standing, v0.7 §8): "The census tables in
   this brief are claims about populations. Find one site a census command
   misses, and one path that defeats a guard WITHOUT appearing in its
   denominator — state erasure, ordering, a second vocabulary for the same
   key. A weak search silently narrows a rule; the denominator is law and
   you are its adversary." The checklist in the brief is a list of
   questions to answer, not suggestions.
8. **The adjacent path (standing in every re-grade, v0.8.1d).** "For each
   fixed finding, find an adjacent path to the same harm the fix did not
   close — another cause, a sibling mode, another entry point; the fix's
   sentence boundary is the attack surface."
7. **Tag every finding `bug` or `rule`.** The promotion tell: if the fix is
   "add the protection that already exists somewhere else," the finding is
   a rule, not a bug — name the invariant and the census that would
   enumerate its sites. /vid fix forks on this tag: rule-shaped findings
   are not accepted as fixed until the rule row exists and every enumerated
   site is guarded.

## Verdicts

One per REQ, with file:line evidence for every verdict — including PASS:

- **PASS** — the Fail-if cannot be demonstrated; evidence cited.
- **PARTIAL** — the behavior exists but the Fail-if fires on a reachable path.
- **FACADE** — looks implemented, fails in practice: dead code, config
  written but never read, behavior that exists only in a test.
- **ABSENT** — not implemented. A `pilot` obligation's verdict only: a
  `later` item is listed as deferred and is never ABSENT (v0.9.1 3.6).

Fences are graded too: a built non-goal is a finding. So are ledger-law
violations (source-reading tests, hand-set fixtures) and, in ViD repos, the
decision-mining sweep's unlogged choices.

When design/ exists it is the ratified spec for the visible surface, and
fidelity is graded law: a built screen that diverges from its designed
counterpart is a finding; a screen or behavior that exists ONLY in design/
is ABSENT. Marker citations make the check cheap: the rule block or template
names its canvas section (`P02/populated`), so the grader compares exactly
that section against exactly that code — transcription
(property-for-property, hex→token) is the standard, and an invented visual
value (in neither canvases nor tokens.css) is a finding. A shared element
(the shell, a card, the top bar, an overlay, a badge, a heading) is
compared to the components canvas C00's section, never to another screen
(v0.9.1 3.7a): its CSS lives in one rule block citing C00, so a second
block citing a screen marker for the same element is the tell. The design
binds the builder and never absolves it — a designed screen is spec, not
evidence.

The decision-mining sweep always asks the data-semantics question (§6.3):
"list the data-semantics choices this code embodies — what stored values
mean, their units, casing, monotonicity; which have no constraint or
test?" A meaning choice living only in prose is a finding.

In ViD repos the decision-mining sweep includes the court-edit check:
`git log --oneline -- checks/` — a commit touching checks/ after init whose
message or trail names no owner law (PRD append, owner answer, accepted
correction) is an automatic high-severity finding; a court widened in the
same commit as work it gates is the canonical instance.

## The wanderer — the exploratory instrument (§5)

The reader graders audit the code against the promises; the wanderer
drives the running product and notices. Same slot — whole product running
— different instrument. Spawn it in parallel with the readers, mutually
blind: the wanderer never sees a reader brief or finding, the readers
never see the wanderer's; findings meet only in the owner's adjudication
table. Blindness is what makes the overlap informative — the same defect
from two independent referents is strong confirmation, and disjoint sets
say the population is larger than either observer sees.

The wanderer's brief contains: the repo path; how to bring the product up
(the same Docker harness the ledger's browser class uses);
GRADING-CHECKLIST.md verbatim; the adversarial stance,
institutional-distrust, and verify-before-report doctrine above; and the
exploratory instruction. It does NOT contain the journey scripts —
following them defeats the point — and not the PRD's REQ batches either;
the checklist is its only prepared list. The instruction:

> Drive the product as a curious, skeptical user with no script:
> out-of-order actions, back-button and double-submit paths, unusual and
> boundary inputs, interrupted and abandoned flows, revisits, the second
> occurrence of everything. Notice anomalies — anything that looks wrong,
> dead, misleading, or inconsistent from where a user sits — and verify
> each against the running product before reporting it. Report
> reproduction steps, rank by consequence.

Wanderer findings are FINDINGS, never gates: tagged bug/rule, merged into
the one adjudication table. After fixes, a short re-wander over the
touched surfaces rides with the mandatory re-grade. When the product
cannot be brought up, the report says so plainly; a skipped wanderer is
stated, never silent.

## Output and adjudication

The report's first line is the rows headline (v0.9.2 3.11: `sh
checks/metrics.sh`'s `rows: kept K · unverdicted U · breached B · red R ·
owed O · deploy-owed D (unmet …)` — `receipt: none` when HEAD has no
export-backed report), then the table. Merge grader outputs into ONE
table, ranked by product consequence (no scores, no numeric ceremony):
severity in plain words | REQ | finding | evidence file:line. Present it to the OWNER for adjudication — per row:
**fix / dispute / defer**.

NEVER auto-apply grader findings. Auto-applying collapses author and
verifier back into one context, which is the failure this engine exists to
prevent. The cycle is composition: grade → owner adjudicates → /vid fix
applies exactly the accepted rows (dual-write, then scoped re-grade).
Disputes die; deferrals become VID-QUESTION markers.

## Differential mode (optional)

When the owner names a second build of the same PRD: graders additionally
diff the two builds' interpretations per REQ — "which reading is
spec-faithful?" — and report divergences as findings. Differential
comparison surfaces interpretation drift that grading one build cannot see.
