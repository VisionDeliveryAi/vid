# {{PROJECT_NAME}} — PRD
grammar: 0.9.8.1

> **Precedence rule:** the base of this file (everything above `## Appends`)
> is immutable after final ratification. All change is appended under
> `## Appends`. Later appends win over the base and over earlier appends.
> Authority order within the record: Seed and human answers > ratified
> thesis > sources > model proposals.

## Seed

<!-- The owner's brief, verbatim, never edited by the machine. Highest
     authority in the run. Import-door documents in the seed role land
     here, verbatim, under a dated sub-heading. After consolidation
     (checks/prd-consolidate.sh) this section is replaced by one header
     line, `Seed: SEED.md (sha256 <hash>)`, and the text lives verbatim
     in SEED.md; the court reads the seed there and refuses a hash that
     does not match. -->

{{OWNER_BRIEF_VERBATIM}}

## Sources

<!-- Optional. Import-door documents in the source role, verbatim, each
     under a named, dated sub-heading. Supporting authority: below the
     seed and human answers, above model proposals. Delete this section
     when no source documents exist. -->

### {{SOURCE_NAME}} ({{DATE}})

{{SOURCE_DOCUMENT_VERBATIM}}

## Thesis

<!-- Seven prose sub-sections, all mandatory, plus the optional
     `Future or secondary` eighth — all ratified at pause 1. -->

### Product summary

{{WHAT_THIS_PRODUCT_IS}}

### Primary users

{{WHO_THIS_PRODUCT_SERVES}}

### MVP focus

<!-- A bulleted list of goals with stable labels: `- G1: <goal>`. The
     labels are load-bearing — the mechanisms block joins on them. -->

- G1: {{GOAL}}
- G2: {{GOAL}}

### Explicitly not MVP

{{WHAT_IS_DEFERRED_AND_WHY}}

### Future or secondary

<!-- Optional eighth sub-section. Coming-later context that CONSTRAINS
     today's foundations — distinct from Explicitly not MVP (not now /
     never): what lives here is planned, and Phase-1 decisions must not
     paint it out. Grounds `constraint` items where a future phase binds
     a present foundation; delete the section when nothing does. -->

{{COMING_LATER_CONTEXT_THAT_BINDS_TODAY}}

### Required core flows

<!-- Derived: one line per journey (its value), never authored separately. -->

- {{JOURNEY_VALUE_ONE_LINE}}

### Value logic

{{WHY_ANYONE_PAYS_OR_RETURNS}}

### Evidence basis

<!-- Where sources conflicted and which way the resolution went. -->

{{CONFLICTS_AND_RESOLUTIONS}}

## Actors and journeys

<!-- One sub-heading per actor (a role, never a demographic). Per actor,
     one or more journeys: an ordered walk of 3–6 phases across time,
     including phases where the product is not present, each such phase
     marked `(off_screen)`. Phases are illustrative — one plausible arc —
     never a procedure a downstream stage reproduces or grades against. -->

### {{ACTOR_ROLE}}

1. {{PHASE}} (off_screen)
2. {{PHASE}}
3. {{PHASE}}

## Mechanisms

<!-- One row per mechanism, joined to the thesis's goal labels.
     Columns: MECH-NN | G-label | one-sentence mechanism | grounding.
     Grounding is typed and join-checked: `stated: seed "<excerpt>"` (the
     excerpt must appear word-for-word in the Seed section), `stated:
     answer A-NNN` (the ledger row must exist), or `open: OQ-n` (the
     carrier must exist under Open decisions). A goal with no mechanism
     and no open question is a wish and will be refused. Lines beginning
     `#` inside any machine block are annotations the court ignores. -->

```vid-prd-mechanisms
MECH-01 | G1 | {{MECHANISM_ONE_SENTENCE}} | stated: seed "{{VERBATIM_SEED_EXCERPT}}"
MECH-02 | G2 | {{MECHANISM_ONE_SENTENCE}} | open: OQ-1
```

## Content contract

<!-- The ratified dimension list this product's requirements must
     terminate on: the catalog floor plus the panel's extensions, ratified
     by the owner at pause 1. Hard cap: 24 dimensions.
     Columns: DIM-id | title | category | demand | labeled fields.
     category: mechanism | nfr | proof. demand: required | case-by-case.
     covered_by: the closed list of item types that may cover this
     dimension. facets: optional comma list; when present, covers:
     citations are facet-qualified (DIM-x/facet) and closure is per facet.
     prompt: one line — what a builder would invent without this
     dimension; mandatory on panel-added dimensions. status: derived
     truth the court recomputes (`covered`, or `na owner <date> <ref>` —
     an NA is legal only with an owner attribution). -->

```vid-prd-contract
DIM-{{ID}} | {{TITLE}} | {{CATEGORY}} | {{DEMAND}} | covered_by: {{TYPES}} | status: covered
```

## Criticality tiers

- **T0** — must never break or leak.
- **T1** — core behavior; getting it wrong is a defect.
- **T2** — desirable; getting it wrong is a fix-round item.

## Items

<!-- The features: the parts of the product the owner would name —
     narrower than a goal, one goal each where the goal exists — declared
     with the thesis and mechanisms and ratified at pause 1, before any
     item exists. Columns: FEAT-NN | goal label | name. The goal is a
     `G*` label from MVP focus, or `-` for an appended feature serving an
     outcome outside the frozen thesis (legal; the court notes it). Every
     demand item and invariant belongs to exactly one feature (`feature:`
     below). Appends add rows in their own ```vid-prd-features block; a
     rename or retirement is a `FEAT-NN AMENDED` row, latest wins. A
     feature left with no demand item is listed at the pause, never
     convicted. No count is mandated. -->

```vid-prd-features
FEAT-01 | G1 | {{FEATURE_THE_OWNER_WOULD_NAME}}
```

<!-- One row per typed item. Four positional fields, then labeled fields
     in any order (the header's grammar line, 0.9.5 or later, is what puts the
     file under this grammar — a pre-0.9.1 file keeps its five, with the
     priority column the court no longer reads). `|` is the separator
     and may not appear inside a field — the court refuses a row whose
     field count under-parses.
     Columns: ID | type | tier | statement | labeled fields.
     ID: demand items REQ-NNN; frame items INV- NG- RISK- HYP- OUT- MET-
     CON-. Numbering continues per prefix; appends continue the sequence.
     type (closed, 11): functional nfr ux_flow data_entity (demand) ·
     invariant non_goal risk hypothesis outcome metric constraint (frame).
     A heading is NOT a requirement type.
          tier: T0 T1 T2, or `-` where criticality is meaningless (non_goal,
     hypothesis, outcome, metric). Demand items and invariants always
     carry a tier. There is no priority column: release membership is
     `phase:` (below), never a ranking.
     fail-if: mandatory on every demand item, forbidden on every frame
     item. The failing case named — never "works as expected".
     serves: mandatory on demand items — what the item is FOR.
     feature: mandatory on every demand item and invariant — exactly one
     FEAT-NN from the features block, never a list; a frame item may
     carry one.
     plain: mandatory on every demand item and invariant under
     `grammar: 0.9.5` — the rule in one plain sentence the owner reads:
     one sentence, at most 30 words, no ids, and every number in it
     taken from the item's own statement or fail-if. The owner approves
     it beside its rule at every pause; an AMENDED row restates it.
     authority: authoritative | provisional | pending. An authoritative
     item cites no ViD decision (a model_proposed answer); a provisional
     item waiting on an owner decision cites the ViD decision or the
     SRC- document it rests on.
     confirms_via: mandatory on every non-authoritative item —
     <kind>/<blocks>, kind ∈ owner-decision | measurement |
     external-dependency, blocks ∈ yes | no, optionally a ref
     (owner-decision OQ-3/yes).
     The T0 rule: a T0 item of any type whose source: cites ViD
     decisions is `provisional`, its confirms_via `owner-decision`
     naming each decision's open question, blocks `yes`
     (owner-decision OQ-3 OQ-7/yes) — never pending. It stays
     provisional while any decision it cites is still ViD's, and is
     amended authoritative once the owner has answered them all.
     source: grounding refs, matched by prefix — seed (seed §n), A-NNN
     (A-012 (AM-15)), SRC-<name>, thesis (thesis G2, thesis MECH-15).
     `proposal` is retired: a ViD decision is a model_proposed ledger
     row, and the item cites it by its A-NNN.
     The values rule: every number in the statement of an authoritative
     item, or of a provisional item waiting on an owner decision,
     appears in a text its source: cites — the seed, a cited answer's
     A:, the thesis, the sources; the court refuses one it cannot find
     (a fail-if's numbers are its falsifier, not claims; 0, 1 and ids
     such as REQ-120 or G4 are not values). A value the owner deferred
     is provisional, confirms_via: measurement, citing the answer that
     deferred it; a value taken from an external standard enters through
     a decision that states it. A door's sitting reference (fix …,
     grade …, design …) is counted, not traced.
     covers: zero or more DIM- ids this item genuinely satisfies,
     facet-qualified where the dimension declares facets, legal only
     where the item's type appears in the dimension's covered_by list.
     A pending item claims no covers.
     derives: optional, closed: golden-set | trigger-row.
     spans: optional, on invariant rows guarding an interaction — the
     item ids whose joint behavior the falsifier tests; each must exist
     in the effective set.
          cross-cutting: optional — the surfaces or sides a demand lands on
     when it belongs to no single one; non-empty when present.
     phase: pilot | later — release membership, not ranking; default
     pilot; mandatory on every demand item and invariant under
     `grammar: 0.9.1`. `later` is what the owner has deferred, never
     inferred from what the harness can observe; a phase change is an
     AMENDED row under the append law.
     arms: on every AMENDED row whose predecessor carries a fail-if —
     one entry per arm of the row it supersedes (an arm is one fail-if
     clause split at top-level " or " / ", or " / "; or "), by ordinal,
     from retained · strengthened · moved <id> · withdrawn <A-NNN>. The
     court joins a move against the target's revision before the move
     and a withdrawal against an effective answer settling the item;
     required under `grammar: 0.9.1`, reported (never convicted) before.
     No rewording or amendment anywhere loses an acceptance arm without
     an accounted disposition. -->

```vid-prd
REQ-001 | {{TYPE}} | {{TIER}} | {{STATEMENT}} | fail-if: {{FAILING_CASE}} | serves: {{PURPOSE}} | authority: authoritative | source: seed | covers: DIM-{{ID}} | phase: pilot | feature: FEAT-01 | plain: {{THE_RULE_IN_ONE_PLAIN_SENTENCE}}
```

## Answer ledger

<!-- Every decision, tiered by whose it is.
     Columns: A-NNN | tier | date | Q: … | A: … | settles: … | unchanged:
     … | importance: … | shown: …
     tier: human (an owner decision — grounds `authoritative`) |
     model_proposed (a ViD decision — grounds at most `provisional`). An
     answer to a question ViD asked is human: the interview, the audit's
     gaps, a must-never-break question, a mini-interview, a blanket "all
     recommended" — one row per question. A decision ViD takes is
     model_proposed. A ViD decision the owner changes is restated human
     (in place before final ratification, A-NNN AMENDED after); one the
     owner lets stand stays ViD's.
     A: restates the value decided, even under a blanket acceptance
     ("accepted as recommended: 30 days") — values are traced against A:
     texts only, and consolidation drops Q:.
     importance: optional on human rows, one value, `priority` — the
     owner's big decisions; absent means normal. ViD sets it where a
     must-never-break rule rests on the answer (it settles a T0 item, a
     T0 item cites it, or it resolves a question a T0 item routes to —
     `checks/prd.sh --pause` refuses such an answer without it); the
     owner may raise or lower any.
     shown: on model_proposed rows — `shown: pause-N <sum>`, written when
     the decision is presented at pause N; <sum> is the checksum
     `checks/prd.sh --pause` prints beside it, of the A: text as shown,
     so a decision revised after it was shown counts as unshown again.
     settles: names item, MECH-, or DIM- ids, OQ carriers, `thesis`, or
     `contract` (a contract-sitting ruling — strikes and case-by-case
     in/out); the court fails a live answer that traces to nothing.
     unchanged: optional — a comma list of bare item ids the ruling
     examined and deliberately left as they stand; the reason lives in
     the `A:` text. Every id must exist in the effective item set (the
     court refuses an unknown one). The delta coherence review reads it:
     an answer that names or affects an item leaves that item AMENDED in
     the same append or named here — an affected item in neither is a
     finding.
     Supersession is the items' law applied to answers: a changed ruling
     restates the FULL row as `A-NNN AMENDED` in an append — latest
     wins, an amendment needs an ancestor, and every ref resolves
     against the effective ledger. Two live answers never disagree in
     prose. -->

```vid-prd-answers
A-001 | human | {{DATE}} | Q: {{QUESTION}} | A: {{ANSWER}} | settles: REQ-001
```

## Open decisions

<!-- Blocking product questions carried as markers, each with a stable
     carrier id: `VID-QUESTION: (OQ-1) …`. The literal token
     `VID-QUESTION:` — colon included — is what checks/coverage.sh
     counts; the carrier id follows it. A must-never-break question asks
     exactly one ViD decision a T0 item rests on and names it after its
     id: `VID-QUESTION: (OQ-2) A-NNN — <the question>` — one decision,
     one carrier. Resolve by owner answer: the
     answer lands as an A-NNN ledger row and the item's amendment in an
     append, and IN THE SAME COMMIT this carrier line is rewritten
     `RESOLVED: (OQ-1) A-NNN — <the question>` — the one line class of
     the base that may change after ratification. References to a
     resolved carrier still resolve; only open carriers count; a
     pending item may not point at a resolved one (the court refuses
     it); a RESOLVED line must name an answer that exists. -->

VID-QUESTION: (OQ-1) {{BLOCKING_PRODUCT_QUESTION}}

## Findings

<!-- The sitting record: what each grading pass found and how each
     finding was dispositioned — written by the skill at every pause,
     one dated sub-heading per sitting, so the ratification sha covers
     what the owner was SHOWN, not only what they decided. A clean
     sitting is recorded as a prose line under its heading — a finding
     is never manufactured to fill the block.
     Columns: F-NN | pass | severity | target | disposition, plus an
     optional labeled evidence: field.
     pass: red-team | audit | review | lens. severity: blocking | advisory.
     lens: one row per wording-lens rewording — `F-NN | lens | advisory
     | REQ-x | repaired | evidence: arms: … — now: <new fail-if>`; the
     old text stays in the diff; a declined rewording is `noted`.
     A near-duplicate pair `checks/prd.sh --pause` prints and ViD keeps
     apart is recorded `F-NN | review | advisory | REQ-a, REQ-b | noted
     | evidence: near-duplicate kept — <why>`; the row is the record,
     and the pair is not shown again.
     target: item, MECH-, or DIM- ids (comma-separated), thesis, or
     seed — a finding with no target cannot be repaired or verified.
     disposition: repaired | overruled A-NNN | accepted A-NNN |
     routed OQ-n | noted (advisory only — a blocking finding must carry
     a resolving disposition before its pause may commit).
     Repair traceability lives here: a repaired finding names its
     target, so every repair edit traces to the finding it resolves. -->

### {{DATE}} — pause 1 sitting

```vid-prd-findings
F-01 | red-team | {{SEVERITY}} | {{TARGET}} | {{DISPOSITION}} | evidence: {{WHY_IT_MATTERS}}
```

## Ratifications

<!-- One line per ratification pause, written by the skill: date, scope
     (thesis+contract | gap answers | final), and the commit sha. The
     sha is the digest — the ratified artifact names exact bytes. -->

- {{DATE}} — thesis+contract — {{SHA}}

## Appends

<!-- Append-only below this line. Each append is dated and names its
     source: (owner answer), (/vid fix correction), (/vid add), (gap
     augment). New items ride in ```vid-prd blocks with fresh IDs
          continuing their prefix sequence. Behavior changes restate the full
     row with the marker AMENDED appended to the ID field: a later
     AMENDED row supersedes every earlier row with its ID, and carries
     `arms:` for every arm of the row it supersedes. -->
