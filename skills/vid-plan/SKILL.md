---
name: vid-plan
description: Plan a ViD project for ticket mode — PL, ViD's planner. It asks the setup once (where the code and specs live, the teams and their lanes, the step size) and checks, read only, what it can reach; it takes every test of the ratified test inventory (INVENTORY.md) as a planned row, word for word, appends to the inventory only what it lacks (the protection row of a must-never-happen item no attack row protects, and the standing rows), writes the plan in develop's form — RUN-STATE's plan block, recorded as develop records it, every stage planned, the skeleton first, steps of ARCHITECTURE.md's modules within rule A's ceiling — has a fresh agent review the rows it added, and shows the owner one plan page to ratify. Product text only — it writes, reads and runs no code — and nothing is written to GitHub: the ticket writer publishes from the ratified plan. Use when the owner says "vid plan", "plan the tickets", or wants the plan an outside team builds from.
---

# /vid plan — PL, the planner (v0.26.10.12.2.2; the setup, lanes and needs v0.26.10.12.3.1)

Ticket mode's planner, in ViD's repository alone (the project's spec repository, on the owner's machine). It never
writes to GitHub; its one call there is the setup's read-only access check. ViD never writes, reads or runs DevAgent's code (vid-run, 'DevAgent's code'), and names no file path, test or runner command in what it
writes: a row is a promise and a fail-if in plain words. It writes PLAN.md
(`${CLAUDE_PLUGIN_ROOT}/templates/PLAN.md`), its own rows appended to INVENTORY.md (`origin: plan`), the plan in
RUN-STATE (through `plan.sh change`), and the review, page and ratification under `.vid/plan/`; never another
inventory row, PRD.md, STAGES.md, GRADING-CHECKLIST.md or ARCHITECTURE.md (its module table is read: ViD's own
spec). `sh checks/planner.sh` judges it all (its header names each subcommand).

## Before any work

0. **The refresh** (v0.26.10.26.7, R1). `sh "${CLAUDE_PLUGIN_ROOT}/checks/refresh.sh"`, the plugin's copy, before
   anything reads `checks/`. It prints `refresh: current`, or copies the plugin's `checks/` and commits it alone. A
   project with no `checks/` at all is refreshed the same way. On exit 3 it has listed local edits it would
   overwrite: show the owner that list in plain words and ask once; on a yes run it again with `--yes`, on a no
   refuse in one line, "checks/ needs the refresh", and plan nothing. Then the WSL notice (0.26.11.1.3, R2): `sh
   "${CLAUDE_PLUGIN_ROOT}/checks/lib/wsl.sh" notice`. It prints nothing except once on a native Windows shell with no
   answer recorded for this PC: there it checks that WSL starts, records the answer and prints one line. Show the
   owner that line as written, and go on; it asks nothing.
1. **The stage event.** `sh checks/event.sh "stage name=plan state=start
   session=$CLAUDE_CODE_SESSION_ID records=29"`.
2. **One planner per project.** Refuse in one line while a develop run has
   recorded a plan and is not complete (`.vid/RUN-STATE.md` with a `## The
   plan` block and `run:` not `complete`, no `mode: tickets`).
3. **Prerequisites, each failure one line naming it:**
   `checks/records-version` 32 or later and `checks/planner.sh` present
   (step 0 has refreshed them); the PRD in the enriched form — `sh
   checks/planner.sh prd-form` refuses a legacy block-form PRD in one line,
   naming /vid create-prd's import door (0.26.10.28.1, CK-R-006); the PRD ratified —
   `sh checks/prd.sh PRD.md --report` gives `gaps=0`, else name the gaps
   and send the owner to /vid create-prd; INVENTORY.md committed with no
   change since outside its `origin: plan` rows (`planner.sh check` flags
   one; `git log -1 -- INVENTORY.md` names a commit), else send the owner to
   /vid test-inventory; STAGES.md, when present, the same, and `sh
   checks/stages.sh check` passing (no STAGES.md is one stage). Then `sh checks/planner.sh prereq` (no such subcommand: the
   refresh): each line is a gap in what the skeleton ticket quotes, naming where it belongs. Tell the owner in one line
   and go on; PL does not fill it in, and the page repeats it.
4. **RUN-STATE** (`.vid/RUN-STATE.md`): `run: active`, `session: $CLAUDE_CODE_SESSION_ID`, `mode: tickets`, `plan:
   required`, and `stage:` as `sh checks/stages.sh current` gives it before any `stage:` line (0 with a STAGE-0).
   With step 1's start, the plan gate is on (`sh checks/plan.sh gate` prints `on`).
5. **The setup** (v0.26.10.12.3.1), before any planning, asked once and kept in `.vid/tw/settings` (`key: value`
   lines; the keys the ticket writer reads too). Ask, in plain words, only the questions no `setup-answered` line of `.vid/plan/setup`
   covers, and record each answer only through `sh checks/planner.sh setup <key> <the answer> --words "<the owner's
   words>"` (v0.26.10.26.7, R11), never by writing the key yourself: a default you write is no answer, and `planner.sh
   check` flags each unanswered key until the first ratify. **A session that cannot ask** (headless, or no owner to
   answer) puts the questions in its answer, in plain words, and plans nothing:
   - **Where the code lives and the specs go.** `layout: separate` (the default: the code repository and ViD's private
     spec repository) or `layout: one` (one repository: the team reads the specs in a folder of the code repository).
     With one repository, ViD's own publish into the folder comes with `vid-spec-publish`: each export mirrored into the
     folder by a pull request the team merges. The code repository as `repo: <owner>/<name>`; `spec-repo:` in both
     layouts (default `<repo>-spec`), ViD's own export; with `one`, `spec-path: <folder>` (default `docs/specs`) and
     `spec-stamp: <a file in the folder>` (the file the publish sets to the export it holds, or `none`); an empty
     `labels-prefix:` when none is there. "Not yet" is offered for the repositories alone: their keys stay out, and a later `/vid:vid-plan` asks again.
   - **The teams.** One line each, `team: <name> | <area in words> | strict|core | <people>`: a name of lower-case
     letters and digits, starting with a letter; *strict* when the team does only its area, *core* when the area is
     its main one but it may help elsewhere. The default is offered, `devagent | the whole product | core | 1`, and
     recorded like any answer once the owner takes it. A team of one person has one lane, its name; a team of *n* has the lanes `<name>-1` … `<name>-<n>`.
   - **Who works the tickets** (v0.26.10.28.8, R3; FB-1 C1). `github-mode: auto` (ViD's own DevAgent, which the owner
     starts on their machine: GitHub auto) is the one answer this question records. For a team of people, who work the
     tickets by hand (GitHub manual), leave the key unanswered and write the plan and its page as always: GitHub manual is
     entered only through `/vid mode manual`, whose call is the ratification ("The owner's words", below). No default is
     offered: only the owner's answer counts.
   - **The step size.** `split: journey` (the default: steps by journey, as now) or `split: fine` (finer steps,
     technical ones allowed, by passes/split.md).
   - **The open-ticket limit.** No question: when `open-tickets:` is absent, write `open-tickets: <the number of
     lanes>`, one open ticket per lane (one team of one person gives 1, two teams of three give 6), and say so to the
     owner, who may change the line. A value already there is never overwritten.

   Then the access check, read only: `sh checks/github.sh access`. Tell the owner in plain words what is not ready,
   and write its last line's words after `access: ` as `access: <today's date> <those words>` in the settings, in
   place of any `access:` line there. `planner.sh check` flags a `team:` line out of form (`setup`).

## The rows

Every test is the inventory's. `sh checks/planner.sh rows --short` prints every line of INVENTORY.md as a planned
row, word for word: its id, its requirements, stage, class and marks, its promise and fail-if, its carried fields, a
journey's transitions after it. PL never re-derives, re-words or drops a row; a line it cannot read is flagged
`unread`, for the owner to fix in the inventory. It writes only these, each appended to INVENTORY.md's rows block
(the ```vid-inventory block holding the ROW rows) in the schema's form for its kind, the next free number of its
class, `| origin: plan <item id>` last (templates/PLAN.md's comment has each form):

- **Protection rows.** For each effective pilot T0 requirement or
  invariant no hostility row protects (`check` flags `protection <item>`),
  one hostility row: its attempt is the forbidden act and what must not
  follow, observed, derived from the item, never invented; `disable: the
  guard that protects <item>`; `owed: spec-only — ticket`.
- **The standing rows.** PLAN.md's four standing lines, one of each kind,
  name the rows that make its promise, or say `none:` and why; where no row
  does, PL appends one:
  - `standing rehearsal` — when the PRD keeps data (a pilot `data_entity`
    item), a ROW paid at deploy gate 1: the kept data survives the move to
    a new version, on the restored copy of production's data;
  - `standing sign-in` — when the product signs users in, in the stage of
    the first role that signs in, a ROW paid at gate 2, each role's test
    sign-in works on staging with no password, and one at gate 3, none
    works on production;
  - `standing fields` — when it collects fields from users, a rule row:
    every collected field is acted on beyond validation and display;
  - `standing work` — when it routes work to queues or schedules, a rule
    row: every routed task and every schedule has a consumer (a rule's
    census in words, tier 1, `owed: spec-only — ticket`).
- **Each row PL appends** names one effective pilot REQ- or INV-; a ROW's
  promise and "Fails if" sentence say, in plain words, what someone who
  can't read code would observe if it broke, and where — never "does not
  work". PL changes only its own `origin: plan` rows, never another.
- **Classes are read, never written.** A class line, `<id> | limit: A-NNN`
  (a known limit) or `<id> | moved: STAGE-<k> A-NNN` (a later stage), only
  by the owner's answer.

## The stages

They are init's cut, as the owner ratified it: STAGES.md, read as it is, or one stage when there is none. PL never
cuts, re-cuts or edits it; a change of stage is the owner's, through /vid stage. A row's stage is stages.sh's, the
appended rows' too.

## The plan

Write the plan as develop does, in RUN-STATE. Develop's planning, word for word (skills/vid-develop/SKILL.md § "Plan, decompose, and sequence the PRD";
the substitutions: "builder step" → "step", "one builder" → "DevAgent", "the builder spends its context" → "DevAgent
spends its time", "the cost of starting an agent and writing its brief" → "the cost of starting a ticket", the
`build-cost` sentence → "Once tickets come back, their cost shows what your past steps cost (`sh checks/queue.sh cost`); use it", and "is never
put to the owner for approval — no epics, checkpoints, or approval pauses; the owner sees it only through the progress
update" → "is put to the owner once, as the first plan; after that, no epics, checkpoints, or approval pauses: the
owner sees each change on the plan page"):

> Plan, decompose, and sequence the PRD using your own best judgment. Apply a strong bias toward reality before
> compounding: before substantial work depends on a consequential assumption, prefer confronting that assumption with
> evidence independent of the assumption itself and representative of what it claims about, especially where being
> wrong would cause broad or costly rework. Treat this as strong planning advice, not a fixed rule; balance it against
> the other considerations that make the overall plan effective, and depart from it when the trade-offs justify doing
> so. Prefer completing one journey — actor or machine — end to end and verifying it at its real boundary early, before
> breadth across the modules it crosses; the run's first integrated observation should not be the end grade. Size each
> step as a modular unit: rows whose tests exercise the same modules and share their setup, so DevAgent can make them
> pass together without holding the rest of the product. Not so big that DevAgent spends its time finding its way
> before it changes anything; not so small that the cost of starting a ticket dominates. Within that, choose the
> grouping most likely to pass whole at the hand-back. Once tickets come back, their cost shows what your past steps
> cost (`sh checks/queue.sh cost`); use it. The decomposition is yours and is put to the owner once, as the first plan; after that, no epics,
> checkpoints, or approval pauses: the owner sees each change on the plan page. The inventory remains the
> completeness floor under any decomposition: shell, reachability, and journey rows have an owner even when no slice
> claims them.

Then skills/vid-develop/SKILL.md § "The plan is a record", with "(the harness, the fakes, the compose file, migrations)" → "(the modules of
ARCHITECTURE.md's table every step needs, which the skeleton supplies)":

> **The plan is a record (v0.9.6 3.1–3.5, R1–R6).** Before building, write the plan into RUN-STATE's `## The plan` as
> one ```` ```vid-plan ```` block (the template shows the grammar): a line per step — its `name:`, the step as a
> sentence in plain product words, its punctuation kept (no `|`; v0.26.10.26.7, R15), the `modules:` it builds, the steps it `builds-on:`, its `rows:`, its `lane:` — and one `shared:` line naming
> what every step depends on (the modules of ARCHITECTURE.md's table every step needs, which the skeleton supplies).
> Say in the prose below it which steps run side by side and why they won't collide.

In ticket mode (`sh checks/planner.sh check` holds the block to it): every step in one lane of the setup (`devagent`
by default), DevAgent building each, `fakes:` naming its dashed links when there is more than one lane; one step of `kind: skeleton`, building on nothing — with a STAGE-0 exactly stage 0's rows but known limits and
moved rows, with none one stage-1 row, the golden path, never a seam or deploy-owed row; `modules:` and `shared:` (`-`
when none) naming the Module column of ARCHITECTURE.md's seam table as it names them, its Dependents column a guide to
real `builds-on:`; `builds-on:` only for a real need, on steps of its own or an earlier stage, a step that needs
nothing building on nothing (`-`), and the prose giving each `builds-on:` its need and saying which steps run side by
side and why they won't collide; every planned row (`planner.sh rows`, every kind) in exactly one step but a known
limit, a later-phase row or a record, a step's rows of one stage, a journey listed by its id, ranges such as
`RULE-001..RULE-003` allowed; no step over rule A's ceiling, 60 rows with a journey counted once (or what
`.vid/budget` records), a bigger one split; and every stage planned at the first go, later stages a draft planned again
at each stage's close, as the prose says.

**Planning to the setup** (v0.26.10.12.3.1, R6; guidance to weigh, not a rule). Plan to the setup's teams: each step
in one lane, a team's lanes side by side; a strict team's lanes hold only steps of its area, a core team's mostly its
own, taking another area's step when its lane would otherwise wait. For each seam that crosses teams (a module, record
or contract both teams' steps build against), the prose names the step that owns its contract and the step that
proves it, which builds on the steps of both sides. For each `builds-on:`, ask whether this step's tests need that
step's code; where they need only an earlier hub (a step many build on), build on the hub, not the step before. With
more than one lane, a step whose rows can all pass against a fake of another step's agreed interface names that step
in `fakes:`, and only then; with one lane a step builds on what it needs and has no `fakes:`. A journey or
cross-module row goes to the step that builds on every step owning what it exercises, the latest point of its chain,
with no separate integration step (its needs line, below, holds it there). Each test difference and outside service
goes to the step that first builds against it, in the stage its row has, never the skeleton (which holds no seam or
deploy-owed row); each rule with the steps whose modules it covers; a row with the step building the module that
implements it, the requirement deciding only when the module is unclear. A step always holds rows: a technical step
holds the rules, outside services and test differences of its modules, or its work goes into the first step whose
rows use it. With `split: fine`, split the drafted steps by passes/split.md: a fresh agent (the Agent tool,
general-purpose, no model override) receives what it lists and returns the split block, which you check and own. Read
the page's notes and, for each, change the plan or say in the prose why it stands.
Aim at about 30 rows a step, a journey counted once (rule A's ceiling stays 60; the page notes a step over 40). A
protected row, a protection (hostility) row and a row of a must-never-happen (T0) item sit in the earliest step their
needs allow, never held back to group a topic; the note on rows held late shows where one is not.
The note that a step's needs lines only repeat its `builds-on:`: read its rows one by one. The note on rows held 10 or
more steps late: move them, or say in the prose why they stand. The split's agent is a helper. Run every helper in the
foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.

**Every row's needs, written down** (v0.26.10.12.3.1, R10), once the steps are drafted. The block's order is the
build order: fix it first. Then, for every row of every step (every kind but a transition; a journey by its id), decide
the step that builds what it tests and every other step whose real code its test needs to pass; put the row in the
latest of them, and write its line in the block, `needs <row ids and ranges> | <those other steps, or ->` (rows with
the same needs may share a line), so no step holds a row it cannot pass. Check every row, never a sample: the reading
may be handed to fresh agents in parallel (the Agent tool, no model override), each given a slice of the rows with
PRD.md, ARCHITECTURE.md, those rows' inventory lines and the drafted block, each returning needs lines; you check and
own the result. A link a row needs is `builds-on:`, never `fakes:`. A needs line names steps of the row's own stage or
an earlier one only: a row whose test needs a later stage's step is one of "Provable only at a later stage" (below),
listed there, not in its needs line. A step left with no rows merges into the step that took most of them (the
earliest on a tie), or, when that would put a step before one it builds on, stays and holds the rows its modules own.
`planner.sh check` flags (`needs`) a row in no needs line or in two, a needed step that is no step, the row's own or a
later stage's, and a row whose step does not build on a step it needs ("only a dashed link" when it fakes it); what a
row needs stays your judgement. Whoever records a plan change writes the needs lines with the steps.
Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a
wake-up, while one, or a command you started in the background, is running. In a headless run the turn's end ends the run, and an unfinished helper's work is lost.

**Rows provable only at a later stage** (v0.26.10.12.3.1, R9), after the needs pass and before the page; skipped with
no STAGES.md (one stage), the heading then saying so. The stage cut places a row at its requirement's stage and never
looks at the surface it runs on. For each stage, read its card in STAGES.md (In, Out, Features) and the later stages'
cards, and go through every row of the stage whose subject, marker or promise names a page, surface or capability:
each one that requires something to happen on a surface the card puts under "Out", or a later card builds, goes in
the prose under the heading "Provable only at a later stage", one line each, "<row> — provable only at stage <n>: <its
surface, and the card's words that put it there>", then a count per stage ("none" when none). A row that only requires
something never to happen there stays, unlisted: it passes honestly now. A row whose surface no stage of the cut builds
is listed as "provable in no stage of the cut", counted on its own line. The rows stay where the cut puts them, in a
step as now. Each is a question to the owner on the page: move it, by a re-cut through `/vid stage` (which decides the
form; STAGES.md is ratified, so the plan is ratified again after it), or keep it where it is, its stage unable to
close until that surface exists (the pull-forward rule). A protection row whose attack runs on a later surface than
what its `protects:` names carries one more question: is its `protects:` aimed at the wrong thing (a re-point is the
owner's, by `/vid test-inventory`)? Write no `moved:` line for these.

The pull-forward rule, skills/vid-develop/SKILL.md § "The pull-forward rule", as written; before the ratification its change is part of the
first plan, `--trigger initial` in place of `discovered-dependency`:

> **The pull-forward rule (R7).** You may bring forward the minimum technical work needed to deliver the current
> stage, if it keeps the product scope, the acceptance obligations and the owner's constraints:
> - record it as today's plan change with its trigger, `sh checks/plan.sh change add|split|rows "<why>" --trigger
>   discovered-dependency --evidence <ref> --expect "<effect>"`, a decision naming who uses the piece, its contract,
>   its module and its tests, and `sh checks/event.sh 'pull-forward step=<id> decision=<D-id>'`;
> - the later feature's rows stay in their stage: the piece is proven by the current stage's rows that use it. A stub
>   behind a seam is allowed while building; at the stage close the promised behaviour must be real;
> - ask the owner instead, while the build continues elsewhere, when the piece is something the owner would see;
>   changes data retention, permissions, a provider commitment, the spend limit or a delivery constraint; or can't be
>   separated without changing the outcome or its quality. The answer is a re-cut (`/vid stage`) or a ratified
>   addition to the stage.

**Record the plan:** `sh checks/plan.sh check` until `ViD plan: ok`, then `sh checks/plan.sh change create "<why>"
--trigger initial --expect "<one line>"`, then `sh checks/planner.sh check` until `planner: clean`.

## Changing the plan

Every change goes through `sh checks/plan.sh change <what> "<why>" --trigger <t> [--evidence <ref>] --expect "<one
line>"`: `--trigger initial` before the ratification; after it, its real trigger and evidence that resolves now
(`step:<id>`, `commit:<sha>`). Then `planner.sh check` until clean and `planner.sh page` again, which shows each
change. An edit not recorded so ends the ratification; a recorded one keeps it, and no new ratification is asked. A
change to PRD.md, INVENTORY.md, STAGES.md, GRADING-CHECKLIST.md, ARCHITECTURE.md or PLAN.md needs a new one.

## The review

Invoke the `vid-row-review` skill (GM-4 F12) with the rows `sh checks/planner.sh rows --added` prints; its output saved
under `.vid/plan/`, record it: `sh checks/planner.sh review --in <file>`. Fix each finding's row (the hash changes: check and review
again), or, when the row is right as written, leave the finding on the page for the owner to keep (`sh
checks/planner.sh answer <n> keep --words "<the owner's words>"`) or have fixed.
**At most 3 rounds of review a sitting, fewer when the count does not fall:** the rounds close after the 3rd review, or
after a review that finds no fewer than the one before, and `planner.sh review` then records nothing and says why. Once
they close, PL fixes nothing more on its own: each open finding is the owner's, to keep or to have fixed (`answer <n>
fixed --words "<the owner's words>"` once it is), and ratify needs no new review.

## The page

`sh checks/planner.sh page` writes `.vid/plan/PLAN-PAGE.md` and renders it with page.sh to
`.vid/pages/PLAN-PAGE.html`. Then run `sh "${CLAUDE_PLUGIN_ROOT}/checks/pages.sh" plan` and do what its lines say: it
puts the page in the index and gives the words on publishing, so the owner's answer on that holds here too. Tell the
owner in plain words what the plan holds — the steps, their waves, the largest and smallest, the setup and its lanes —
and what the flags and the notes say: counts only, never a score. Run it after every change, so the owner sees each.

## The owner's words

Nothing is ratified, and nothing leaves, before the owner's words. When the
owner says yes to a page whose flags say none:

1. `sh checks/planner.sh ratify --words "<the owner's words>"`, verbatim;
   it refuses while a flag stands, the plan is not recorded, or the page
   did not show this plan.
2. `sh checks/event.sh 'publish-approved words="<the owner's words>"'`:
   the go the ticket writer reads before it publishes.
3. Commit the change to INVENTORY.md's `origin: plan` rows alone, its
   message citing the ratification and the owner's words; then PLAN.md alone.

For a team of people (FB-1 C1: `github-mode` left unanswered, so `check` flags it and `ratify` refuses), steps 1 and 2 are
the switch's: make step 3's commits, then on the owner's yes run `/vid mode manual --applied <the plan's commit> --words
"<the owner's yes>"`. It reads the plan block and PLAN.md it finds, takes that commit as the applied version, asks GitHub
manual's setup (`state-repo` among it), ratifies in the owner's words and records the mode.

A "no" or a change: change the rows or the plan (through `plan.sh change`, `--trigger initial`), then check, review
and page again. After the ratification, `planner.sh ratified` holds through recorded plan changes.

## Hand back

`sh checks/event.sh "stage name=plan state=end
session=$CLAUDE_CODE_SESSION_ID"`; one line to the owner: the stages, steps
and rows counted, the waves, the ratification or what is open, and that
`/vid run` publishes from the ratified plan: it makes the spec repository at
its start and exports the spec at its first round (v0.26.10.26.7, R12). The
plan publishes nothing.
