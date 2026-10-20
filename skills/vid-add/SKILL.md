---
name: vid-add
description: Add a feature to an existing ViD project — mini-interview, PRD appends with new REQs and Fail-ifs, develop scoped to the delta, then fix scoped to the delta. Use when the owner says "vid add", "add a feature", or describes new behavior for an already-built project.
---

# /vid add

The same loop, smaller. Requires an existing ViD project (CLAUDE.md law file
with a ```vid-placement block) — otherwise point the owner at /vid init.

**Stage events (v0.9.5 3.11, R11; RECORDS.md).** In the project, record `sh checks/event.sh "stage name=add state=start session=$CLAUDE_CODE_SESSION_ID records=1"` when this verb starts and `sh checks/event.sh "stage name=add state=end session=$CLAUDE_CODE_SESSION_ID"` when it hands back; develop, which this verb runs scoped to the delta, writes its own. Every event this skill names is written the same way, `sh checks/event.sh '<event>'`, which appends it to `.vid/metrics-events` with its time.

## 1. Mini-interview

Read CLAUDE.md → PRD.md (base + appends) → BASELINE.md → ARCHITECTURE.md →
DECISIONS.md first. Then interview exactly as init does, scoped to the new
feature: load-bearing product questions only, one small batch, a
recommendation wherever the evidence supports one. Re-ask the design hint
question only if the feature has surface the recorded hints don't cover.
Every answer lands in the PRD's answer ledger (below); a skipped product
answer is a `model_proposed` ledger row and the item it grounds is born
`provisional | confirms_via: owner-decision/no` — routed, never narrated;
a skipped technical choice is a DECISIONS entry with `| origin: proposal`.
A new DECISIONS line takes its number from `sh checks/decisions.sh next` (v0.26.10.4), reserved at the home.
Under a PRD headed `grammar: 0.9.4` or later, a skipped answer that a T0
item would rest on is not skipped: the owner is present, so the
mini-interview asks it (checks/prd.sh join 18 refuses a T0 item resting on
a ViD decision unless it waits on that decision's own open question), and
the answer lands `human` with `importance: priority`. Every answer's `A:`
restates the value decided — values in the new items are traced against
the `A:` texts they cite.

## 2. Append the spec

- Under PRD.md `## Appends`, a dated heading naming the source
  (`(/vid add)`), in the PRD's row grammar: a ```vid-prd-answers block
  with the mini-interview's answers (`A-NNN` continuing the sequence,
  `human` or `model_proposed`, `settles:` naming the new items), then a
  ```vid-prd block with the new items — `REQ-NNN` rows continuing the
  sequence, each a demand type with tier, statement, `fail-if:`
  (the failing case named), `serves:`, `phase:` (`pilot | later` — the
  mini-interview asks it where the thesis sections cannot decide it;
  v0.9.1 3.6), `authority:` (`authoritative` when
  a human answer or the owner's brief grounds it), `source:` citing the
  answers, `covers:` only where the item genuinely satisfies a ratified
  contract dimension; new fences as `NG-NNN` non_goal rows. Under a PRD
  headed `grammar: 0.9.4` or later every new demand item and invariant
  carries `feature:` — an existing `FEAT-NN`, or a new feature appended as
  its own ```vid-prd-features row in the same append, its goal `-` when no
  ratified goal fits; under a PRD headed `grammar: 0.9.5` or later every new or AMENDED demand item and invariant also carries `plain:` — one sentence of at most 30 words saying the rule in the owner's words, no ids, every number in it taken from its own statement or fail-if (v0.9.5 3.13). checks/prd.sh judges the effective set at the
  commit — an item without a falsifier never lands. A pre-enrichment PRD
  (no ```vid-prd block) keeps its
  `### REQ-NNN` block form, one Fail-if each, a tier each. The
  mini-interview's fail-ifs pass
  `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/wording-lens.md`
  before the append is ratified, under the same `arms:` accounting
  (v0.9.1 3.5c): one line per rewording, ruled at recognition speed.
- After the append commit and before §2b: spawn
  `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/whole-set-review.md`
  in `mode: delta` on the append against the effective set (v0.9.1 3.2).
  Its findings are ruled now, one line each: a `fix_from_record` finding
  is an amendment in a further dated append, a question goes back to the
  mini-interview (v0.9.8.1 R29: every finding that narrows or withdraws a
  fail-if arm, one question for the review, listing each row, its arm and
  the answer it follows; the answer settles every row it names); the run records `sh checks/event.sh 'tokens slice=0 phase=review n=T'`.
- BASELINE/ARCHITECTURE changes only if the feature genuinely adds a seam,
  stack element, or Tier-0 row — rare; prefer existing seams.

## 2b. The inventory delta — delegated to /vid test-inventory (append mode)

After the append commit and before any code: run the vid-test-inventory
skill (`${CLAUDE_PLUGIN_ROOT}/skills/vid-test-inventory/SKILL.md`) in
**append mode**, naming the delta — the new and amended REQs of the
append. It derives the delta's rows with every axis (one row per
independently breakable promise; the trigger row for a time-worded
Fail-if; the seam × Tier-0 probe; the control sibling of a guard row; a
machine journey, actor `(process)`, for a new external input boundary
the feature adds, or a new consequence it promises for an existing one
(v0.9.3 3.2);
surface rows if the feature has a face and the design round has run),
runs its genus lenses scoped to the delta, presents the row-set diff —
NEW rows to ratify, CHANGED rows where an amendment moved an obligation,
ORPHANED rows an amendment left without a source, UNCHANGED as a count —
and the owner ratifies at recognition speed. The new rows are materialised
as failing ledger tests — by test-author passes
(`${CLAUDE_PLUGIN_ROOT}/skills/vid-test-inventory/passes/test-author.md`,
batched as that skill's §6 says, in small files — one row, or up to 5
related rows, a file (v0.9.8.1 R18); a new surface row regenerates its
screen's surface file; never by this session — v0.9.2 3.1, R1; v0.9.8 R1,
R5: written by the test-writing skill, each brief carrying its rows'
authority bundle, each test with its test argument), each file
committed unchanged with its `Tests-by:` trailer — and stamped
`proved-red` at the parent sha where each was observed red, in the
numbered rhythm (test, then row, then code); a row the passes cannot
write is deferred only by the closed vocabulary (`owed: <class> —
<detail>`), and the par line over the delta must hold. Develop then burns them down like any other rows. Rows the feature
needs that this sitting did not derive are develop's per-route additions,
as always — never silent, never a substitute for the sitting.

## 3. Develop, scoped to the delta

Run the /vid develop loop (see the vid-develop skill — same laws: two-channel
questions, ledger green at every commit, commit template, narrated position)
restricted to the delta: only the new REQs, only the seams they live in.

Write-scope discipline is the point of this verb: needing to touch files
outside the feature's seams means the seam map is wrong — stop, fix
ARCHITECTURE.md in the same commit, or reconsider the approach. It is never
"just this once".

## 4. Grade, adjudicate, fix — scoped to the delta

Run /vid grade (see the vid-grade skill) with focus restricted to the
new/amended REQs plus every seam the delta touched. Present the findings
table; the owner adjudicates; apply the accepted rows via the /vid fix
protocol — same dual-write, same scoped internal re-grade.

**A change to the law, counted first (v0.26.10.3 R3, R5).** A question
whose recommended answer would change a fail-if or a row's obligation
quotes `sh checks/inventory.sh impact` on a scratch draft of the change,
and a bulk approval asks once before landing when any row would be reset
(vid-develop's two-channel rule). Before the re-grade, the test-author
pass judges every row the sitting's amendments flag (`sh checks/brief.sh
authority --changed`, rows to confirm included): kept with `authority
--kept`, or its obligation amended.

**ViD's own defects (v0.26.10.3 R12, R13).** When a ViD check, hook,
skill or agent role misbehaves — it refuses legitimate work, crashes,
contradicts itself or its documentation, or gives a wrong count — or when
you use a workaround around one, append an entry to `.vid/VID-FINDINGS.md`
in the form of `${CLAUDE_PLUGIN_ROOT}/templates/VID-FINDINGS.md` (the file
is created from it at the first entry; entries are numbered in the file),
record `sh checks/event.sh 'vid-finding n=<n> area=check|hook|skill|agent file=<ViD
path>'`, and tell the owner in one line. A defect in the product being
built is not a ViD finding.

## 5. Hand back

The first line is the rows headline (v0.9.2 3.11: `sh checks/metrics.sh`'s
`rows: kept K · unverdicted U · breached B · red R · owed O · deploy-owed
D (unmet …)` — over the whole inventory, the delta's rows named), then
the delta's row-set diff counts, the deploy-owed rows and `later` items
as their own two counts, and the open questions; counts never scores.
