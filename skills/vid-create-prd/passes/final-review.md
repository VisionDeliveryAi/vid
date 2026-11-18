Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# final-review — pass brief

<!-- 0.26.10.29.3 (phase 2 R4): one pass over the whole spec, every document beside the PRD, run by vid-init before
its labelling pass and once more after init's stage cut. -->

mode: whole | delta
when: at init — after step 6's budget lines, before step 7's labelling pass; after init's stage cut — once, after STAGES.md is committed
receives: mode whole — the PRD without its `## Findings` section, without its append sections' `vid-prd-findings` blocks and without its `review:` lines; the design when there is one (`DESIGN-BRIEF.md`, `design/screens/` with its `index.json`, `design/tokens.css`); ARCHITECTURE.md, DECISIONS.md, BASELINE.md, INVENTORY.md, GRADING-CHECKLIST.md; after the cut, also STAGES.md and the output of `sh checks/stages.sh check` and `sh checks/stages.sh counts`, run on the committed STAGES.md. mode delta — the same documents, the rows the last repair changed, their affected set, and ViD's recommended answer to every open `needs_owner` finding.
must not receive: the session's reasoning; any earlier verdict — the PRD's findings, the append reviews' records, a previous round's findings.

A fresh pass over the whole spec: every document the project's build
will be held to, read together, as one record. It reads the documents as
they stand, never what any earlier review said of them. The red-team's
finiteness mandate applies verbatim:

> A finding needs a MATERIAL CONSEQUENCE — if nothing downstream changes
> because of it, it is not a finding; wording you would have phrased
> differently is not a finding; style is not a finding. A CLEAN VERDICT IS
> AN ACCEPTABLE OUTCOME. You are not scored on how much you find.

> If a correction would override an answer the owner gave, say so in your
> evidence — the owner's hand outranks a later model guess, so such a
> finding is a QUESTION for the owner, never a correction you may assume.

## The lenses

- **Across documents.** One document permits what another forbids, or
  states a different value, bound or actor for the same thing: the PRD
  and the design, the PRD and ARCHITECTURE.md or DECISIONS.md, BASELINE.md
  and either, a test row and the item it derives from, the grading
  checklist and the PRD. A contradiction names every side: its `target`
  lists every row in conflict.
- **Soundness.** Would building an item exactly as written harm the user
  or defeat its own purpose? For example: a retry that repeats a real
  action already completed; a permission that shows what it should hide;
  a default that loses data.
- **Every bound has a number.** Every limit, timeout, retention, maximum
  or "at most", in any document, has a number, a named setter (who
  decides it, and where it is recorded), or an open question. A bound
  with none of the three is a finding, whatever its dimension.
- **Every test can be measured.** Every test row's words, in INVENTORY.md
  and GRADING-CHECKLIST.md, can be observed by a finite test. "Unlimited",
  "fast", "always" and their kin, without a bound, are findings.
- **After the cut, the stage checks.** Each stage card's counts equal the
  `stages.sh counts` output you were given; no stage needs what only a
  later stage builds (a prerequisite, a row, a service or a screen placed
  in a later stage than the stage that needs it).

## Delta mode (a re-read round)

You read the rows the last repair changed and their affected set: every
row in any document that shares their subject, value, bound or actor.
Report **blocking findings only**, on what changed: a repair that is
itself wrong, a contradiction the repair made or left on another side, a
side of a ruling the repair did not carry. The soundness lens also judges
each recommended answer you were given: would the product, built on that
answer, harm the user or defeat its own purpose? Named ids are the
minimum, never the scope; what did not change is not re-judged.

## Your findings

Every finding is a `vid-prd-findings` row, pass `final`:
`F-NN | final | <severity> | <target> | <triage class> | evidence: <…>`;
the caller replaces your triage class with its ruling (`repaired`,
`accepted A-NNN`, `overruled A-NNN`, `routed OQ-n`, `noted`). Severity is
`blocking` or `advisory`. A target is a PRD id (an item, an answer, a
mechanism, a dimension), or a row of another document by its file —
`INVENTORY.md:ROW-12`, `DESIGN-BRIEF.md:D-149`, `STAGES.md:STAGE-2` — or a
bare file name when no row fits; a comma list when it names several
sides. The triage classes:

| triage_class | meaning |
|---|---|
| `fix_from_record` | the answer already exists in the record — a mislink, a stale side of a ruling, a value one document states and another contradicts where the record settles which stands |
| `fix_model_authority` | repairable with no new decision: a test row's unmeasurable words given the bound the record holds, a missing row the record already requires, a draft ViD wrote |
| `needs_owner` | requires a decision that exists nowhere in the record; a repair that would weaken or remove a test row; any finding against the design. *"Use this whenever answering would mean inventing product intent. Never guess it, and never downgrade it to keep the count low."* |

**A finding names its failure.** The `evidence:` field states the
situation, the affected actor, the plausible wrong outcome, the passages
(file and line, or id) that permit, require or fail to resolve it, and
why the consequence is material to the agreed scope.

**Challenge your own finding first.** Before reporting it, find the
strongest evidence that it is already settled — related items, owner
answers, the Explicitly-not-MVP section, a decision line, later rulings
— and report it only if the material problem survives that check. A
deliberate deferral is never rediscovered as missing scope.

Return your rows and nothing else; when there is nothing, return
`none`. You edit nothing.
