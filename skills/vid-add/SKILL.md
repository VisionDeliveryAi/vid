---
name: vid-add
description: Add a feature to an existing ViD project — mini-interview, PRD appends with new REQs and Fail-ifs, the inventory delta, then a hand-over to develop, which builds it and grades it once, scoped to the add. Use when the owner says "vid add", "add a feature", or describes new behavior for an already-built project.
---

# /vid add

The same loop, smaller. Requires an existing ViD project (CLAUDE.md law file
with a ```vid-placement block) — otherwise point the owner at /vid init.

**The start (v0.26.10.24 R1).** Outside ticket mode, read `checks/records-version` first: absent or below 32, tell the owner the project's checks/ needs the refresh and stop before any work; the refresh is vid-develop's ("Version skew"), run before the add is asked again. **Stage events (v0.9.5 3.11, R11; v0.26.10.11 R6; RECORDS.md).** Outside ticket mode, in the project, record `sh checks/event.sh "stage name=add state=start session=$CLAUDE_CODE_SESSION_ID records=30 base=$(git rev-parse --short=12 HEAD)"` when this verb starts — `base=` is HEAD before the add's first commit, which develop's completion grade reads; outside ticket mode, whenever a session takes the add over, record it again with its first `base=` — and `sh checks/event.sh "stage name=add state=end session=$CLAUDE_CODE_SESSION_ID"` when it hands back or hands over (§3); develop writes its own. Every event this skill names is written the same way, `sh checks/event.sh '<event>'`, which appends it to `.vid/metrics-events` with its time.

**GitHub manual (GM-3 U2).** When
`sh "${CLAUDE_PLUGIN_ROOT}/checks/devagent-start.sh" mode` prints `manual`,
the add drafts through the door as the ticket-mode branch below does, with
GitHub manual's one difference as the door says it (no plan block).
The hand-back names /vid next in place of /vid run.

**Ticket mode (v0.26.10.25.5, R1).** While `.vid/RUN-STATE.md` says `mode:
tickets`, the add is a draft through the door, the vid-fix skill's
ticket-mode branch: it records no stage event, so the run's stage stays
the newest and `plan.sh` stays on, and it commits nothing. Run §1, §2 (the
placement in STAGES.md included) and §2b's derivation and ratification in
the working tree, uncommitted, the new rows written `owed: spec-only —
ticket`, with any checklist line in GRADING-CHECKLIST.md, and the plan
block as it will stand in a file: the step each new row goes in, or a new
step with its name, modules, lane, builds-on and `needs` line. Keep §4's
count: first the whole-set review in delta mode by a fresh agent, its
output (`none`, or `finding <row id> | <why>` lines) in a file; then `sh
checks/land.sh draft --review <that file> --why "/vid add: <the add, in a line>"
--plan <the block file>` prints it (refused, it names the check and keeps
the tree: v0.26.10.26.7, R4, R5); the door's ask and landing take it from
there. No §3: grading stays per ticket, and staging stays the dev
team's. The hand-back (§5) is the door's: "the add is draft <n>, asked as
Q<k>", and that the owner's yes lands it, then back to /vid run's loop at 2,
or the call (v0.26.10.26.7, R3).

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
the `A:` texts they cite. **The owner's words (0.26.10.29.3, R2):** an
answer is `human` only with the owner's yes, given at this
mini-interview; one ViD proposes that the owner has not seen is
`model_proposed`. The append commit quotes the owner's words in an
`Owner:` trailer — `Owner: "<words>"`, or `Owner: A-NNN "<words>"` per
answer — and commit-msg refuses a human answer added without one
(vid-create-prd, "The owner's words"); in ticket mode the landing quotes
the owner's yes. **Raised questions (0.26.10.29.3 R4):** a question an agent's report raises that ViD cannot settle from the record (a ruling, the seed, or an owner answer it can cite) becomes an open carrier at once, `VID-QUESTION: (OQ-n) <the question>` in a dated append, raised with the owner at the next sitting; one ViD settles from the record is answered in the message to the owner with the record line that settles it (vid-create-prd, "The owner's words, and the questions raised").

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
- **A new feature's stage (v0.26.10.5 R5; v0.26.10.11 R1, R3), when
  STAGES.md exists.** The owner puts the add's pilot work in a stage in
  the same sitting as its append: recommend, ask, and record the answer
  as a row of the append's answers block — the answer row the placement
  commit cites.
  - **Every stage closed** (`.vid/metrics-events` holds `stage-closed
    n=<k>`, k the final stage: STAGES.md's highest `STAGE-` number) and
    the add brings pilot items: one answer, a new final stage —
    `STAGE-<k+1> | <name> | features: <the add's new pilot features>`,
    plus a `split: <REQ…> -> STAGE-<k+1>` line for each new pilot
    requirement of an existing feature (`features: -` when the add brings
    no new pilot feature), with its plain-language card. A closed stage's
    tag never moves: the new stage's close is what tags it, re-checks
    stages 1 to k+1 and takes the feature to staging.
  - **Otherwise:** the current stage or a later one. A new requirement in
    an existing feature takes that feature's stage; there is nothing to
    place.
  - `later` items go in no stage. An add that brings no pilot item places
    nothing and builds nothing: no hand-over, and the hand-back
    says there is nothing to build.
  - **A hold, on or asked for (v0.26.10.11 R7).** When a stage is held (a
    `stage-hold n=N state=on` with no `state=off` for N after it), or the
    owner has asked to hold after a stage still open (`stage-hold n=N
    state=asked`, its words not "staging setup", no `state=off` after
    it), the placement question also says that building now ends the
    hold, as "continue" does — and, for a hold that is on, that staging
    goes back to the held stage's build until the feature's stage closes.
    On yes:
    - a hold that is on: develop (§3) starts through its "continue" path
      — `run: active`, `sh checks/stages.sh hold --off`, its `continue:`
      line said first; for the setup hold, develop's rules for "continue"
      while the setup hold is on;
    - an asked hold: withdrawn before the build starts with the record
      "continue" writes, `sh checks/event.sh 'stage-hold n=N state=off'`
      (`hold --off` refuses while no stage is held); when stage N's
      cycle also holds the setup hold's ask, ask it again at once, `sh
      checks/stages.sh hold --after N --words "staging setup"`, so only
      the owner's hold is withdrawn.

    On no, stop after §2b: no hand-over, and the hand-back's last line is
    "say 'continue' to build it with stage <its stage>". Develop's scoped
    grade holds until that build's completion. (Owner decision D2 (a).)

  The placement is its own law commit, right after the append commit
  (which follows the whole-set review, below): the feature joins a `STAGE-` line of
  STAGES.md's ```vid-stages block (or a `split:` line places its
  requirements), the message citing the answer (`Stages: A-NNN`) —
  commit-msg refuses a membership change without one. Until it lands,
  `checks/stages.sh` refuses every other commit (the feature is in no
  stage). An amendment that adds a pilot feature gets its own placement
  commit right after it. **The current stage (v0.26.10.11 R2):** right
  after the placement commit that opens STAGE-<k+1>, write RUN-STATE's
  `stage:` line as `stage: <k+1>` (replace it; with none, add it after
  `plan:`). `sh checks/stages.sh current`, admission, the close of
  STAGE-<k+1> (the final stage: tagged `vid/stage-<k+1>`, no next stage)
  and develop's staging step at that close then read it unchanged.
- Before the append commit (0.26.10.29.3 R3: no append is committed
  without its review), on the prepared append: spawn
  `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/whole-set-review.md`
  in `mode: delta` on the append against the effective set (v0.9.1 3.2),
  once per add (v0.26.10.24 R1). Its findings are ruled now, one line
  each: a `fix_from_record` finding is an amendment in the same append, a
  question goes back to the mini-interview (v0.9.8.1 R29: every finding
  that narrows or withdraws a fail-if arm, one question for the review,
  listing each row, its arm and the answer it follows; the answer settles
  every row it names), and what the repairs and the rulings land is read
  again by the same pass (vid-create-prd, "Reviews converge", in Pass mechanics: every repaired round is read again by the same pass, up to three rounds, and what remains goes to the owner as one list; 0.26.10.29.3 phase 2, R1); the run records `sh checks/event.sh 'tokens slice=0 phase=review n=T'`.
  Write its record in the append — its findings, ruled, as rows of the
  section's own ```vid-prd-findings block (pass `review`), and the line
  `review: delta, round <r>, <n> findings` (`<r>` the round the review ended on, `<n>` the rows of the section's findings block, every round's; one round and no findings: `round 1, 0 findings`; vid-create-prd, "The findings record"); pre-commit
  refuses a new append section holding rows without it. Write the rulings as an edits file and apply it with `sh "${CLAUDE_PLUGIN_ROOT}/checks/prd-apply.sh" PRD.md <file>`; never edit the machine blocks by hand or with a script of your own. Then the append
  commit, its placement (above), and §2b.
  Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.
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

## 3. Hand over to develop (v0.26.10.24 R1)

Once §2b has ratified the rows and written them red, tell the owner in one
line the delta's row-set counts and that develop now runs as it always
does. Record the add's end, `sh checks/event.sh "stage name=add state=end
session=$CLAUDE_CODE_SESSION_ID"`; then **invoke the vid-develop skill (the
Skill tool)** and go on from its "Before any work", whose stage event turns
the gate on. Inside develop the add's rows join the plan through `sh
checks/plan.sh change add "<why>" --trigger scope-change --evidence
commit:<the append commit> --expect "<one line>"`, as develop's plan rule
says, and its completion grade is this add's one grade (the vid-develop
skill, "After an add, the grade is scoped"). An add that brings no pilot
item (§2) hands nothing over: there is nothing to build. When the owner's
yes ends a hold (§2), develop starts through its "continue" path.

Write-scope discipline is the point of this verb: needing to touch files
outside the feature's seams means the seam map is wrong — stop, fix
ARCHITECTURE.md in the same commit, or reconsider the approach. It is never
"just this once".

## 4. Throughout the add

These two hold from §1 to the hand-over, before develop's text is in force.

**A change to the law, counted first (v0.26.10.3 R3, R5).** A question
whose recommended answer would change a fail-if or a row's obligation
quotes `sh checks/inventory.sh impact` on a scratch draft of the change,
and a bulk approval asks once before landing when any row would be reset
(vid-develop's two-channel rule).

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

Only three adds end here: ticket mode, no pilot item, a hold kept (§2).

The first line is the rows headline (v0.9.2 3.11: `sh checks/metrics.sh`'s
`rows: kept K · unverdicted U · breached B · red R · owed O · deploy-owed
D (unmet …)` — over the whole inventory, the delta's rows named), then
the delta's row-set diff counts, the deploy-owed rows and `later` items
as their own two counts, and the open questions as the court's count — the
`open-OQs=` field of `sh checks/prd.sh --report PRD.md`, never a number or
"none" of your own (0.26.10.29.3 R4); counts never scores.

In ticket mode the add ends as a draft asked of the owner, handing to `/vid run`, which lands it on their yes and publishes its tickets.

The last lines: "nothing to build: the add brings no pilot item" (§2),
"say 'continue' to build it with stage <its stage>" (a hold kept, §2), and
ticket mode's (above). A kept hold's hand-back adds: when the owner then
says "continue", invoke the vid-develop skill (the Skill tool) and go on
from its "Before any work", whose stage event turns the gate on, then its
"continue" path.
