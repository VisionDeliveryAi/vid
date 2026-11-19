---
name: vid-stage
description: Cut a ViD project into stages the owner ratifies in one sitting — through five lenses (outcome, technical order, constraints, risk, complexity) it builds the finest cut whose every stage is usable, safe to release, buildable, protected and whole, then coarser rungs by merging neighbours, shown as one ladder with counts, the recommended rung's plain-language cards and the open product choices; the ratified cut is STAGES.md, a law file, or no file at all when the owner keeps a single stage; at init's cut it also offers a technical stage 0 (the walking skeleton, deployed to staging, never released) and asks once for the standing staging authorization. vid-init runs it at its end, after the inventory is ratified and the spec committed; it also runs on request for a re-cut. Use when the owner says "vid stage", wants the product delivered in stages, or wants the cut changed.
---

# /vid stage

A product large enough is delivered in stages: each built stage is
closed, tagged and can go to staging, and at each close the owner decides
whether to go live or carry on (vid-develop, vid-deploy). This skill
proposes the cut and records what the owner ratifies. It changes no
requirement and no row except through their doors (0.26.10.29.4 phase 4
R5; "The doors the cut uses", below), and no line of the PRD's grammar:
`phase: pilot | later` keeps its meaning, and stages 1 to N together are
the pilot (stage 0, when there is one, holds rows only: it is technical
and never released).

**Stage events (RECORDS.md).** Outside ticket mode, record `sh checks/event.sh "stage
name=stage state=start session=$CLAUDE_CODE_SESSION_ID records=28"` when
this skill starts and `sh checks/event.sh "stage name=stage state=end
session=$CLAUDE_CODE_SESSION_ID"` when it hands back.

**Ticket mode (0.26.10.29.2, R2).** While `.vid/RUN-STATE.md` says `mode:
tickets`, a re-cut is a draft through the door, as /vid add's ticket-mode
branch drafts (the vid-add skill): it records no stage event, so the run's
stage stays the newest and `plan.sh`'s gate stays on, and it commits
nothing. The steps, the ladder and the sitting are as below, each rung
tried in its scratch copy. Then, in the working tree, uncommitted: the
owner's answer as its row in PRD.md's appended `vid-prd-answers` block
(What it writes, 1), with DECISIONS.md's lines; any PRD append and any
INVENTORY.md row the cut's doors write (below; a split of a ratified row
is additive here: the original row and its test stay, the stage-local
rows are added, since the landing carries spec files only); STAGES.md as
ratified, or STAGES.md deleted for one stage; and, in a file, the plan
block as it will stand: each row whose stage changed moved out of its step into a step of
its new stage (a new step with its name, modules, lane, builds-on and
`needs` line when none fits), so `sh checks/planner.sh check` passes. The
writer amends each open ticket that held a moved row at the next round.
A stage already closed (a `stage-closed <N>` line in `.vid/tw/handed`) or
deployed (any of its candidates' D1 passed, or a `production` line that
covers it; the `staged` line is no test) is shown as it stands and never
changed: the draft is refused if it changes one. A stage with a candidate
not deployed may be re-cut: when its rows change, the landing withdraws
the candidate and the asks made at it (its C3, its S1, its D1 okay), and a
new candidate is named once one is due. Keep the count: the whole-set
review in delta mode by a fresh agent over the rows whose stage changed,
its output (`none`, or `finding <row id> | <why>` lines) in a file, and
the record of the answer's append in the append, as "What it writes" says
(0.26.10.29.3 R3: the landing commits through the hooks); then
`sh checks/land.sh draft --review <that file> --why "/vid stage: <the
re-cut, in a line>" --plan <the block file>` (the why's `/vid stage: `
marks a re-cut; refused, it names the check and keeps the tree), and `sh
checks/queue.sh ask draft <n>` asks the owner once. No staging question
here: staging stays the dev team's. The owner's yes lands it in `/vid
run`: the law commit cites the answer, the plan change is a
`scope-change`, the landing re-ratifies in the owner's words and records
the `stage-cut` event. The hand-back names `/vid run` on both its lines:
"the re-cut is draft <n>, asked as Q<k>", and "say yes in /vid:vid-run to
land it", then back to /vid run's loop at 2.

## When

- **At the end of init** — vid-init calls it after the inventory is
  ratified (v0.26.10.9 R6: init makes the spec only; the spec commit comes
  first), before its hand-back, so it sees the whole baseline. With two
  or more stages, this run alone ends with the final review (below).
- **On request** (`/vid stage`) — a re-cut. Stages already closed (a
  `stage-closed … ready` event, or in ticket mode `stage-closed … source=ci`)
  are shown as they stand; the re-cut is of
  the stages not yet closed.

## What it reads

- `PRD.md`: goals, actors, journeys, features, requirements, the owner's
  answers, every `phase: later`;
- `ARCHITECTURE.md`: modules, owned data, outside services;
- `INVENTORY.md`: rows, journeys, rule rows, hostility rows, seams;
- `BASELINE.md` and `DECISIONS.md`: stack limits, settled choices;
- the design brief and the route extractor, when present;
- `DEPLOYMENT.md`, when present;
- `.vid/RUN-STATE.md`, on a re-cut (`stage:` is the stage being built).

The stage court is 0.26.10.5's (`checks/records-version` 25), and stage 0
is 0.26.10.8's (28): a project whose checks/ is older is refreshed first,
as develop's version check says. `sh checks/prd.sh --effective` gives the effective items; `sh
checks/stages.sh scope --upto N --reqs` and `sh checks/stages.sh stage-of
<id>` read a cut back exactly as every court will.

## The five lenses

| Lens | The question | Whose |
|---|---|---|
| **Outcome** | Who can do what at the end of this stage, and what will being live teach? | The owner's |
| **Technical** | Which modules, data and services does it need? Is the order buildable? | ViD's |
| **Constraints** | Deadlines, budget, providers, what must not be live early | Stated by the owner; applied by ViD |
| **Risk** | Which assumptions hurt most if wrong? The smallest probe for each, and the stage it goes in | ViD proposes; the owner sees it |
| **Complexity** | Which journeys are simplest to build first: the fewest modules, services and rows they need? | ViD's, its reasons shown on the cards |

The complexity lens (0.26.10.29.4 phase 4 R3) orders the cut: the finest
cut puts the simplest usable journey in stage 1, and each later stage
adds the next simplest journey the earlier ones make possible.

## The steps

1. **Sort what is decided:** the owner's commitments, ViD's technical
   decisions, open assumptions. Keep every `later` the owner deferred —
   a later item has no stage.
2. **Outcome candidates:** for each plausible first outcome, the smallest
   usable journey, with its failure handling and its protections.
3. **Feasibility:** map each candidate to modules, data, services and
   contracts. Record each prerequisite with its source (a requirement, a
   module, a seam) and mark it product or technical. Not every link is a
   prerequisite: architecture's "may be used by" is a permission, and an
   invariant's `spans:` is an interaction — neither is an ordering edge
   on its own.
4. **Compare feasible orders** by outcome, constraints, the cost of
   waiting, integration risk and reversibility. Place the risk probes.
5. **Challenge each boundary:** does the stage work with every later
   capability absent? Was a shared protection — a must-never-break rule —
   postponed by accident? (Rules hold for the whole code from the first
   stage: a rule row is stage 1 unless a `row:` line places it later.
   Under the block's line `rules: by-origin`, 0.26.10.29.4 phase 4 R2, a
   census row whose `origin:` names PRD items takes the earliest stage of
   those items instead, since a rule derived from a requirement is only
   exercised once that requirement's code exists; it stays stage 1 when its
   origin names no PRD item, when every origin item is `phase: later`, and
   when it is a Tier-0 rule, which covers all the code from the first
   stage. A `row:` line overrides any of these.)
   What would make this cut wrong?
6. **Present the ladder (amendment 1, R1a):** the finest cut, the
   coarser rungs made from it, the recommended rung, and the product
   choices left open (below).

Whole features by default; a feature is split only when an outcome needs
it, or when its journeys differ in complexity and splitting along them
makes a finer usable stage (the complexity lens), and the card then shows
the exact requirements that go where; its requirements move with
`split:` lines, as always. Two usable stages may sit inside one feature:
the feature's first stage lists it, `split:` lines move the later
requirements, and a stage whose content comes only from `split:` lines
lists no feature (`features: -`). Each feature is still placed once.

## The ladder (amendment 1, R1a)

The owner favours smaller releases. Offer the finest cut that makes
sense, then coarser versions of it, and let the owner pick.

**The finest cut** is the most stages you can find in which every stage
meets all five constraints:
1. **Usable:** it gives someone a result they can use, not a technical
   layer.
2. **Safe to release:** it holds nothing that must not go live without a
   later stage — a public listing without takedowns, accounts without
   deletion, paid placement without the partner's reporting.
3. **Buildable:** it needs only earlier stages (the court's `needs:` rule).
4. **Protected:** it carries the must-never-break rules from the first
   stage they touch.
5. **Whole:** what can't be separated stays together.

On the card where a constraint stopped a finer split, name it, so the
owner sees why the cut is not finer.

**Coarser rungs** are made only by merging neighbouring stages of the
finest cut, which keeps the five constraints and the court's rules. At
most four rungs: the finest; one or two in between, merging at the cut
lines whose separation buys the least; and a single stage. A merge
renumbers the stages in `row:`, `split:` and `screen:` lines and drops the `row:`
lines and `split:` entries it makes redundant. On a re-cut a merge never takes in a stage already
closed or deployed.

**The wait's parts (0.26.10.29.6, S11).** Where `.vid/` exists, before
the first rung is tried, name the wait: `sh
"${CLAUDE_PLUGIN_ROOT}/checks/face.sh" wait parts "Trying the cuts"
"Counting each" "Writing the stages"`. Then `sh
"${CLAUDE_PLUGIN_ROOT}/checks/face.sh" wait at <n>` as each step starts:
1 when the rungs are written into their scratch copies and `check` runs,
2 when `counts` runs on each, 3 when the recommended rung's cards are
written. The `stages` sitting's write clears them. When a sitting's
write has cleared the parts and a step of the same list remains (a
rung's journey row written through the inventory's door, or a rung made
up during the sitting and tried before it is shown), name the list again
(`face.sh wait parts`, the same three parts) and then call `wait at <n>`
for the step you start.

**Each rung is tried before it is shown.** Write it into a scratch copy
outside the repository — PRD.md, INVENTORY.md, `checks/` and the
candidate STAGES.md — and there run `sh checks/stages.sh check` (it must
pass) and `sh checks/stages.sh counts`: per stage its requirements (REQ
ids: `scope --upto k --reqs` minus the same at k-1), rows (`scope
--upto k` minus `--upto k-1`) and journeys (the journey rows among
them), and the rung's `row-lines` — the rows placed by hand, judgement
included. The project's own STAGES.md is never overwritten by a
candidate. Counts come from there, never estimated.

**Nothing untried reaches the owner** (0.26.10.29.4 phase 4 R6). Any
rung, outline or variation offered at the sitting, one made up during it
included, is written into the scratch copy and counted with `check` and
`counts` before it is shown. The owner is never asked to confirm a list
or an outline that has no counts, or items they have not seen. **The
owner's pick stands:** once the owner picks or adjusts a rung, ViD makes
no further split or merge on its own; a change ViD thinks better is shown
as one more rung, tried and counted the same way, for the owner to pick.

**One table, one decision.** The sitting's main question is the ladder,
shown as one table: each rung, its stages, the counts per stage, its
placed-row count, and what actually differs from the finest — fewer
stage closes and deploys, a later or bigger first release, a risk tested
later — or "unchanged" where nothing differs; claim no difference it
doesn't have. Cards are drawn for the recommended rung only, and again
for the rung the owner picks.

**Too small, too large** (0.26.10.29.4 phase 4 R3). A stage is too small
when it is not worth its own close and deploy. It is too large when its
requirements, from `counts`, are above 60: what ViD grades comfortably,
two grading batches of 30, the figure the size sentence states
(vid-create-prd, §8, item 2). The recommendation:
- the finest rung with no stage too small and none too large;
- when no rung has neither, the finest rung with no stage too large, and
  its card names the small stage;
- when every rung has a stage too large, the finest rung, and that
  stage's card says which of the five constraints holds it together.

Too large is a count from `counts`, never a score.

**Every stage holds a journey** (0.26.10.29.4 phase 4 R3): `counts`
gives each stage's `journeys=`. A journey row usually spans several
stages' requirements and sits in one, so a candidate stage can hold
none. Then ViD writes that stage's own journey row, its usable outcome as
a journey, through the inventory's door ("The doors the cut uses",
below) into the rung's scratch copy, and tries the rung again. A rung is
dropped only when one of its stages still holds no journey. Exempt: on a
re-cut, a closed or deployed stage, shown as it stands; and the technical
stage 0.

## Stage 0 — the technical stage (v0.26.10.8 R1, R2)

**At init's cut only,** below the ladder's table, one more line offers a
**technical stage 0** for the rung the owner picks, with its card; the
owner says yes or no to it right after the pick, on its own (The sitting,
`stages-own`, below). A re-cut never adds or
removes it: the court refuses a STAGE-0 line added or removed by any
commit but the one creating `STAGES.md`.
- **Recommended** when the product will be deployed and uses an outside
  service (email, payments, sign-in, storage, a partner feed); the card
  says why in one line — so the questions a first deploy raises come at
  the start, not at the end.
- **Its rows** are yours to choose: the fewest existing ROW rows that make
  one thin journey through the main modules (ARCHITECTURE.md), including
  at least one that stores data and reads it back. Each is a row whose
  whole Fail-if the skeleton can meet. A health page alone is never the
  skeleton. The rows' requirements keep their own stages; stage 0 holds
  rows only.
- **Tried before it is shown,** as every rung is: written into the rung's
  scratch copy and passed through `sh checks/stages.sh check` and `counts`
  (`stage 0 requirements=0 rows=<n> journeys=<n>`; stage 0 is exempt
  from the journey rule).
- **With the single-stage rung,** a yes writes `STAGES.md` with STAGE-0
  and a STAGE-1 holding every feature.
- **Stage 0's card** says, in plain language: "technical: never released;
  an exception to 'usable'"; the thin journey it holds, and the rows
  proving it (counted); what setting staging up will still need from the
  owner's own hands, from the `vid-hosting` block init recorded
  (`owner-only:`): the log-in, and the accounts only the owner can create
  (counted, by name); what proves it done: its rows pass and are graded,
  then staging runs it; the effort, S/M/L, labelled an estimate. It has
  no outcome, audience, "what to watch once live" or requirements: it
  holds none.
- **With stage 0,** stage 1's card names no walking skeleton; stage 0 is
  it.

**The standing staging authorization (R6).** Right after the pick and
stage 0's answer, on its own, once the cut has two or more stages (stage
0 counts), ask once: "May ViD set up
the test site and put each finished stage on it on its own? Going live
always waits for you." Record the answer after `STAGES.md` is committed:
`sh checks/stages.sh staging-auth on|off --words "<the owner's words,
verbatim>"`. The owner may give or withdraw it at any time afterwards;
any verb records "stop deploying to staging on your own" as `off`. It
covers only develop's staging deploy at a ready stage close, and at
"continue" while staging is being set up — not a fix, a schedule, a re-cut
or production.

## The sitting — one, at the end

The owner sees the ladder and the recommended rung's cards and, in one
sitting, picks a rung, adjusts one, or keeps a single stage (the top
rung). The picked rung's cards are drawn and shown.

**Size, counted** (0.26.10.29.4 phase 4 R4). The sitting shows the size
sentence (vid-create-prd, §8, item 2) with the counts of that moment,
from the `size:` line of `sh checks/prd.sh --pause PRD.md`: its pilot
count, and the fewest stages the cut needs so that none holds more than
60 requirements, that count divided by 60, rounded up (when that is 1,
the sentence says they fit in one stage). The ladder is held to it (too
large, above).

**The `stages` sitting (0.26.10.29.6, S1, S2).** Where `.vid/` exists,
before you ask:
1. make the page of the cuts to choose from, one folder a rung, each the
   rung's scratch copy: `sh "${CLAUDE_PLUGIN_ROOT}/checks/pages.sh" cuts
   <folder> [<folder> …]`;
2. write the sitting: `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write stages <file>`,
   the file in `face.sh`'s line form (its head); a refused line is
   rewritten and the call made again, and a line the script names as
   holding an id or one of ViD's own words is rewritten in plain words and
   written again before you ask;
3. give the owner what the scripts printed about pages first: the link,
   or the file's path;
4. present the same sections in the chat, in the same order, whether or
   not a panel is there.

Its sections:
- `section cuts`, figures: one `item` a rung, its `value` line its
  stages' requirements and tests as `counts` printed them (the rows
  `counts` gives a stage are every test of that stage, of every kind,
  called "tests"), then the size sentence as an `item` of its own, its
  `value` the count of stages it gives;
- `section which`, which cut: one item, a `choice` line a rung, and your
  recommended rung as its `recommend` line;
- `section stages`, the text of the recommended rung's stages: one item a
  stage, its card in `detail` lines;
- `section open`, the product choices left open, each a question with its
  `choice` and `recommend` lines (`recommend | none` where you have none);
- `section findings`, the findings of the review of the changes the cut
  needs (The doors the cut uses, below), each with your recommendation,
  Fix it or Leave it, in the button's own words, or `recommend | none`, a
  finding that proposes a looser bound followed by `alone`. No
  `tests-review` sitting is written for them.

An empty section is `empty <section> | <why>`. An answer typed in the
chat answers the items it names, one by one. A yes to the
recommendations covers only the items shown with one, and no item asked
on its own: say what it covered, as counts by section, and ask what it
did not; never offer one yes for items of different kinds. One question
settles one thing. Once the pick and the rulings are written: `sh
"${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end stages`.

**The `stages-own` sitting, right after the pick.** Before anything is
committed, each question that applies is asked on its own, in this
order: stage 0, where it is offered; then the standing staging
authorization, where the cut has two or more stages once stage 0 is
answered. For each in turn: write it, `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh"
write stages-own <file>`, the file holding `section alone` with that one
item and no `choice` line (its answers are Yes and No, fixed; a
`recommend` line, where you give one, is Yes or No), give the page lines
first, ask it in the chat in a
message of its own, and once its answer is recorded, `sh
"${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end stages-own`. When neither
applies, `stages-own` is not written.

**The page of the cut picked.** Once the owner's pick is recorded (What
it writes, below: after STAGES.md's law commit, or for one stage after
the answer's commit and its `stage-cut` event; in ticket mode once the
draft is in the working tree), run `sh "${CLAUDE_PLUGIN_ROOT}/checks/pages.sh"
stages`, whichever cut the owner picked, the one they already have and a
cut back to one stage included: called by name, it takes the cuts' page
off the index.

Where the map has passed this stop (a re-cut after init), the script
writes no sitting and says so in one line: ask in the chat all the same,
item by item, with the pages; the two calls to `pages.sh` are made as
above.


Each card has:

- the outcome and who it is for;
- what is in and what is out;
- the features — whole by default; a split feature shows its exact
  requirements;
- the prerequisites, with their sources;
- the constraints;
- the risks and their probes;
- why this order;
- what proves it done;
- what to watch once live;
- the effort, S/M/L, labelled an estimate;
- counts: requirements, rows, journeys, new outside services.

Stage 1's card names its **walking skeleton**: one thin journey through
the main modules and services, built first in stage 1 — unless the owner
took stage 0, which is the skeleton (above).

**Plain language.** No ids in what the owner reads unless the owner asks
— a feature by its name, a requirement by what it lets someone do.
Counts only; no scores, no percentages.

## What it writes

1. **The owner's answer** as one human row in an appended
   ```vid-prd-answers block — `A-NNN | human | <date> | Q: how should the
   product be delivered — in which stages? | A: <the cut as ratified, in
   the owner's words — the rung picked, or "one stage"> | settles:
   contract` — committed on
   its own with ViD's decisions behind the cut in DECISIONS.md (each
   labelled, as every decision is), the message quoting the owner's words
   in an `Owner:` trailer (0.26.10.29.3 R2; vid-create-prd, "The owner's
   words"; in ticket mode the landing quotes the owner's yes). Before that
   commit the answer gets the append doors' review step (0.26.10.29.3 R3):
   spawn `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/whole-set-review.md`
   in `mode: delta` on the answer's append against the effective set, rule
   its findings in the sitting, and write its record in the append —
   its findings, ruled, as rows of the section's own ```vid-prd-findings block (pass `review`), and the line `review: delta, round <r>, <n> findings` — `<r>` the round the review ended on, `<n>` the rows of the section's findings block, every round's rows (vid-create-prd, "The findings record", gives the line's rules); pre-commit refuses a new append section holding rows without it.
   Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.
2. **A single stage:** no `STAGES.md`; record `sh checks/event.sh
   'stage-cut n=1 answer=A-NNN'`, run `sh "${CLAUDE_PLUGIN_ROOT}/checks/pages.sh"
   stages` (The sitting, "The page of the cut picked") and hand back.
3. **Two or more stages:** `STAGES.md` at the root from
   `${CLAUDE_PLUGIN_ROOT}/templates/STAGES.md` — the cards, and the
   ```vid-stages block (one `STAGE-N | <name> | features: FEAT-…` line per
   stage; with stage 0, `STAGE-0 | <name> | technical` and a `row: ROW-x ->
   STAGE-0` line for each of its rows; `split:` lines for a split feature's requirements; `row:` lines
   placing a row whose requirements span stages, or a rule row placed
   later; `screen:` lines, below; `needs:` lines, each with its source; the line `rules: by-origin`,
   once at most, below). No placeholder survives.
   **The `screen:` lines** (0.26.11.1.2, R8): one `screen: <screen id> -> STAGE-<n>` line for each screen whose states' requirements fall in different stages, naming the stage that first builds the screen; a row testing that screen (its subject, or its marker before `/`) then waits for that stage, and a `row:` line may place it later, or in stage 0, never earlier. When the move leaves a requirement whose every row sits in a later stage, the cut moves that requirement to the screen's stage too, with a `split:` line.
   **The `rules: by-origin` line** (0.26.10.29.4 phase 4 R2): write it,
   creating STAGES.md or re-cutting, only when no stage is closed or
   deployed. Once any stage is, a re-cut keeps the line exactly as the
   base STAGES.md holds it, neither adding nor removing it; a cut back to
   one stage deletes STAGES.md, and a later cut after stage 1 has closed
   creates it again without the line. Adding or removing the line is a
   membership change: its commit cites the owner's answer.
   Run `sh checks/stages.sh` and resolve every refusal before committing:
   a row spanning stages is placed explicitly, never pushed to the latest
   stage automatically (often the later stage is right — say why), and no
   requirement's only rows may sit in a later stage than the requirement:
   split the row, bring its prerequisite forward, or move the requirement
   itself with a `split:` line. Membership moves only by these lines: a
   requirement between stages by a `split:` line, a row by a `row:` line,
   a screen's rows by a `screen:` line.
   Commit STAGES.md as a law commit, alone or with INVENTORY.md when the
   cut's doors wrote rows (below), with the
   answer cited in the message (`Stages: A-NNN`): commit-msg refuses a
   membership change without one. Then record `sh checks/event.sh
   'stage-cut n=<stages> answer=A-NNN blob=<git rev-parse HEAD:STAGES.md>'`
   and run `sh "${CLAUDE_PLUGIN_ROOT}/checks/pages.sh" stages`.

A re-cut writes the same way: a new answer, the STAGES.md change (with
INVENTORY.md when rows changed) as one law commit citing it, a new
`stage-cut`. Deleting STAGES.md (back to one stage) is a membership
change too.

## The doors the cut uses (0.26.10.29.4 phase 4 R5)

A cut may need requirements reworded or added and rows added or split.
Each goes through its document's own door, one writer each, never an
improvised agent or writer:
- **A PRD append** may reword an item or add one, with the append doors'
  review step (What it writes, 1) and its rounds (vid-create-prd,
  "Reviews converge"). It never changes an existing item's `feature:` or
  `phase:`: the stage court reads those on the PRD's own commit, before
  the law commit can follow. Moving a requirement between stages is a
  `split:` line, never an append.
- **Deferring a feature to later** is the owner's change, made before the
  cut is tried, in two commits in this order:
  1. the owner's answer and the PRD amendment marking the feature
     `phase: later`, together: on that commit only, the stage court
     accepts `split:` and `row:` lines naming items the same commit makes
     later;
  2. next, the STAGES.md law commit citing the answer, removing those
     lines. Every other commit is refused until it lands.

  Never remove the lines first: the requirement would fall back to its
  feature's stage, and its rows could then span stages, which the court
  refuses.
- **A new row**, such as a stage's own journey row (Every stage holds a
  journey, above), is written in the inventory's append mode, its
  strength pass included (vid-test-inventory, the modes list). A stage's
  own journey row has no journey in the PRD's `## Actors and journeys`
  to derive from, so it is written in the genus-proposal form, `origin:
  domain`: its derived-from names that stage's own requirements, and its
  transitions come from their fail-ifs. That row is the delta append mode
  receives, and its `origin: domain` is why a later re-derivation keeps
  it. It is drafted, and its strength pass run, before the sitting, in the
  rung's scratch copy; the sitting ratifies it with the rung, and only the
  picked rung's rows are written.
- **Before the code skeleton** (`sh checks/plan.sh skeleton` says `not
  started provenance=spec-only`), there is no code: append mode stops
  after the ratification, as it does under tickets, and the new rows are
  written `owed: spec-only — first stage`. That holds at init's cut and
  at any re-cut before the skeleton.
- **A split of a ratified row** goes by the row-set diff's path: the new
  rows plus the old row's retirement, a law change citing the cut's
  answer (vid-test-inventory §5). In ticket mode a split is additive
  (Ticket mode, above).

**The order.** PRD appends land first, each by its door. Then
INVENTORY.md and STAGES.md land together in one law commit citing the
answer: a new row that spans stages needs its `row:` line in the same
commit, and a law commit may hold several law files. In ticket mode the
cut commits nothing: every changed file goes in its one draft through
`land.sh` (Ticket mode, above).

## After init's cut, the final review (0.26.10.29.3 phase 2 R4)

Once, in vid-init's run only, with two or more stages, after STAGES.md is
committed (so `sh checks/stages.sh check` reads the real file): spawn
`${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/final-review.md` in
`mode: whole`, with the inputs its `receives:` line lists for after the
cut — init's documents as committed, STAGES.md, and the output of `sh
checks/stages.sh check` and `sh checks/stages.sh counts`, each run on its
own, never piped. Its rounds, its second reader and its record follow
vid-create-prd, "Reviews converge", "The second reader" and "The findings
record", as at init (vid-init, "6b. The final review").
Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.

ViD repairs by the same rule as at init, but everything is committed by
now, so each repair goes through its document's own door:
- the PRD by an append, carrying `review: final, round <r>, 0 findings,
  see <heading>`;
- INVENTORY.md and STAGES.md together in one law commit, after the PRD's
  repair append when there is one, by the cut's order (0.26.10.29.4 phase
  4 R5; The doors the cut uses, above); a STAGES.md change cites the
  stage answer, as above;
- the law regions of ARCHITECTURE.md and BASELINE.md each by a law
  commit of its own;
- the rest by an ordinary commit.

The owner gets the same three kinds as at init — a repair that would
weaken or remove a test row, a product decision the record does not
hold, a finding against the design — and a change to the cut itself,
which is the owner's re-cut, asked at this sitting. The findings heading,
`### <date> — final review after the cut` with its line `review: final,
round <r>, <n> findings, read: <files>` (STAGES.md among the files) and
its one ```vid-prd-findings block, lands in PRD.md in a commit of its
own, after the loop ends, so it holds every round's rows; the PRD's
repair append, when there is one, rides in that commit, so its `see`
names a heading that exists. No hook asks for this record: pre-commit
asks for a final review only on the commit that adds INVENTORY.md (the
spec commit), and by the cut INVENTORY.md already exists, so this text
holds it.

With one stage there is no STAGES.md and no second run. A later re-cut
(`/vid stage` on request, or ticket mode's draft) keeps its delta review
and never runs the final review.

**The questions a cut raises (0.26.10.29.3 R4).** A product question the
cut raises — yours, or a lens's or an agent's — that ViD cannot settle
from the record (a ruling, the seed, or an owner answer it can cite)
becomes an open carrier in the PRD at once, `VID-QUESTION: (OQ-n) <the
question>` in a dated append, and is asked at this sitting or the next;
one ViD settles from the record is answered in the message to the owner
with the record line that settles it (vid-create-prd, "The owner's words,
and the questions raised"). Never call a question settled, or defer it to
a later stage, without one or the other.

## Hand back

One line per stage — its name, its outcome, its requirements, rows and
journeys, from `sh checks/stages.sh counts` run on the committed cut
(0.26.10.29.4 phase 4 R7) — and, for each stage whose counts differ from
what the sitting showed, one line with both numbers and why (a row added
through the inventory's door after the sitting, say); whether the
standing staging authorization is on, the open questions as the court's
count (the `open-OQs=` field of `sh checks/prd.sh --report PRD.md`, never a
number or "none" of your own; 0.26.10.29.3 R4), and that `/vid develop` builds the
first stage first, stage 0 when there is one (or, on a re-cut, carries on
with the current stage).
