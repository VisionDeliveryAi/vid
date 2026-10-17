---
name: vid-develop
description: Build the entire PRD end-to-end in one run — "make the ledger green": no approvals, no checkpoints, ledger green at every commit, the ratified Test Inventory burned down mechanically; product questions go to the owner immediately, technical questions are decided and logged. Use when the owner says "vid develop", "build it", or wants the spec implemented.
---

# /vid develop

One command. Build the whole spec end to end. Zero owner approvals — the only
owner interaction is product questions. Since v0.6 the job has a mechanical
name: **make the ledger green.** Init materialised the ratified Test
Inventory as failing tests; progress is the red count falling, measured, not
narrated.

## Before any work

**The stage event (v0.9.5 3.11, R11).** First of all, record
`sh checks/event.sh "stage name=develop state=start session=$CLAUDE_CODE_SESSION_ID records=21"`
— and again whenever a session takes over the run (Resume, below); the
completion report records the `end` (`state=end`, the same form without
`records=`). Every event this skill names is written with
`sh checks/event.sh '<event>'`, which appends it to `.vid/metrics-events`
with its time.

**The internal skills (v0.9.7.0.6 3.5).** Right after the stage event,
invoke the `vid-test-manager`, `vid-verify` and `vid-build` skills (the
Skill tool) — the test manager's rules, the row-verdict contract and the
rules for building a step — and again
whenever a session takes over the run. Claude Code restores after a
compaction only the skills that were invoked, never a file that was only
read.

**The run's state from the first minute (v0.9.5 3.2, R2).** Right after the
stage event, write `.vid/RUN-STATE.md` (from `${CLAUDE_PLUGIN_ROOT}/templates/RUN-STATE.md`, or
rewrite the keys of the one a takeover finds) with `run: active`,
`session: $CLAUDE_CODE_SESSION_ID`, `plan: required` (v0.9.6 — it switches
on this release's run mechanics, below), `questions:` carried over (or
`- · next Q1`) and `slice: -` until the first slice opens, and record
`sh checks/event.sh 'run state=active'` — before any planning, so the
observer and the death record cover it. **Version skew:** Read
`checks/records-version` first. If it is absent or below 21, the
project's checks/ predates this plugin: tell the owner it needs the
refresh and stop before building. The refresh (v0.9.8.1 R5): first run
`sh "${CLAUDE_PLUGIN_ROOT}/checks/local-changes.sh"` from the project's top
level and show the owner its list — the project's commits under `checks/`
since the last refresh, and its uncommitted changes there — since the copy
overwrites them; each is carried over or dropped on purpose. Then copy
`${CLAUDE_PLUGIN_ROOT}/checks/` changes over `./checks/` and commit it alone
with `VID_ROLE=fix`, its subject `Refresh checks/ to VID <version>` (the
next refresh's list counts from it). Record
the stop as `run: stopped checks/ needs the refresh` (the four legal
stops, below).

**Delegated marks, once (v0.9.7.4 3.9, R10).** At the first session after
the refresh (no `delegated` event in `.vid/metrics-events` yet), if the
owner has ever delegated decisions to ViD's recommendation, mark each
existing answer you took under that delegation, by hand, from your own
record of the run (the run's log of delegated rulings, the answers you
wrote): one `sh checks/metrics.sh delegated --answer <A-id>` each. Nothing
is inferred from an answer's wording; an answer you are not sure of stays
unmarked. The mark says how an answer was made, so it reaches every past
snapshot the viewer makes.

**Decision labels, once (v0.9.7.3 3.3, R3).** A decision carries a label
saying where it applies (`| applies-to: <ids and codes>`, or `| scope:
project`), so a brief quotes it only there. At the first session after
the refresh (no `decision-labels` event in `.vid/metrics-events` yet), run
the labelling pass once over the decisions that cite no ROW, REQ or RULE
id: `sh checks/decisions.sh propose` writes `.vid/briefs/labels-<n>.md`
(or says there is nothing to label); spawn one general-purpose agent with
that brief — it reads and returns one line per decision, it edits
nothing — and save its return, unchanged, as
`.vid/decision-labels.proposed`. Then `sh checks/decisions.sh apply`
writes the labels in one commit, with no question to the owner: a label
the agent is unsure of, or one no brief could join, is written `scope:
project`, so that decision still reaches every builder as it does today;
`.vid/decision-labels.applied` records each. A decision changed since its
proposal is left unlabelled and listed.

**The harness upgrade (v0.9.7.0.10 3.6, R13; v0.9.7.0.11 3.2, R2).**
Right after the version check, run `sh checks/harness.sh rules`. On exit
0 there is nothing to do. On exit 1 it prints `harness-upgrade
harness=<hash> target=<n> state=<state>`: the harness file's `rules:` is
below the rules the plugin brings (`rules: 2`, the four harness rules of
`vid-init`) and they are not yet its law. That hash, the original
harness's, and that target name every state of the step, recorded as
events only (`sh checks/event.sh 'harness-upgrade state=<state>
harness=<hash> target=<n>'`). A step for target 1 already dispatched or
asked keeps its scope: finish it, then target 2 comes due on the new
harness; a target-1 decline does not suppress target 2.
With `state=none`, record `state=due`, once. Any other state is a resumed
run's: go on from it, never asking again — `due` is dispatched with the
first admitted step; `dispatched` waits for the upgrade's returns;
`asked` waits for the owner's answer to the question already asked. The
run never waits for the upgrade: every other builder keeps building on
the old harness until the upgrade's law commit lands.
- **Dispatch, with the first admitted step** — a fresh run has no plan or
  admitted step, and a brief and its requests need both. Once the first
  builder brief is admitted, write one more on that step and its rows
  with `--upgrade` (`sh checks/brief.sh write --role builder --slice <N>
  --step <id> --rows <its rows> --upgrade`, which adds the harness, the
  template's rules, the slowest cases of the run's history, the newest
  timeline, the last 20 gated
  passes' `overhead=` and the last 20 passes' container states with each
  service's started-at and kept-healthy-at), start it in its own worktree — the harness
  upgrade pass (`vid-build`) — and record `state=dispatched`. When it
  returns, brief a test-author pass the same way (`--role test-author …
  --upgrade`, its `--notes` naming the services the builder made
  started-only) for rule 2's shared setup step and the tests routed
  through it; integrate both returns in the upgrade's worktree.
- **The question.** Ask the owner one law question, through the
  two-channel rule: may the harness take the rules (target 2: all four;
  from `rules: 1`, rule 4's limit), with this change? Name the limit and
  how it was chosen. Show the `overhead=` before (the brief's last gated passes) and
  after (the builder's re-measured request) and any `difference` row it
  proposes (v0.9.8 R17: no service's ready time — the container states
  hold only the first healthy check Docker still kept). Record `state=asked`.
- **On a yes, two commits** in the upgrade's worktree, then integrate
  them: first the support files — the images, the readiness route, the
  shared setup step and the routed tests — as ordinary commits; then the
  law — the harness with `rules: 2` (or `rules: 1` for a target-1 step),
  and any `difference` rows — as one
  standalone law commit, its `Decisions:` line naming the owner's answer.
  Record `state=applied`. From then the court holds the readiness
  declarations, and admission runs one test environment until you run the
  test-environments pass again, which proves them on the new harness
  (`vid-test-manager`, test environments).
- **On a no,** record `state=declined` — an event only, never a line in
  the harness, so a later change to the harness file makes the step due
  again.

**The watcher (v0.9.7.0.6 3.3, R6; v0.9.7.0.9 3.8, R12).** Right after
the version check, run `sh checks/observe.sh start` — it starts the
watcher as a detached loop tied to this run, or finds it running — then
`sh checks/observe.sh alive`, which exits 0 only when the watcher ticked
here within the last 30 minutes. On exit 1 (rare, since you just started
it), tell the owner what it printed and stop: record `run: stopped the
watcher is not running`. The watcher sends nothing: its notices are
`observe: notice —` lines in the run's heartbeat. A reboot or log-out ends
the loop; the next resume starts it again (Resume, below).

**Your context, the host, the builders' tool (v0.9.7.1 3.8, 3.9, 3.12).**
Right after the watcher:
- run `sh checks/brief.sh context` and say its line (`context: <tokens>`,
  your own session's, or `unknown`);
- unless `.claude/settings.json` already sets `autoCompactWindow`, or a
  `context-window` event records the owner's answer, ask the owner once,
  in plain words: may ViD set this project's compaction point to 300,000
  tokens, so this session compacts before its context grows costly? On a
  yes write `"autoCompactWindow": 300000` into the project's
  `.claude/settings.json` and record `sh checks/event.sh
  'context-window requested=300000'`; on a no, `context-window
  requested=declined`. A launch flag, the environment or a higher setting
  can override it: `brief.sh write` and `return` print `context <n>` above
  350,000 — a notice; nothing stops. Compact when it shows;
- run `sh checks/brief.sh plugins` and give the owner its lines when it
  names any plugin — each one's skills reach every session start; the
  owner turns one off for this project. It never stops the run;
- run `sh checks/job.sh tool` and say its line (`builders: claude`,
  `codex` or `paused`).

**The test environments.** The test manager measures the environments before the first
run (`vid-test-manager`, test environments).

Read, in order: CLAUDE.md → PRD.md (base, then Appends; later appends win) →
BASELINE.md → ARCHITECTURE.md → DECISIONS.md → design/ when it exists (the
second half of the spec) → INVENTORY.md when it exists (the ratified rows
you are turning green). CLAUDE.md is the law; this skill only adds the run
loop. A spawned agent reads its brief — the quotations and the role's
required inputs — and nothing else is mandatory; the linked sources are
further reading it takes at will. The orchestrating session reads in the
order above.

The design transcription law: `vid-build`.

## The run loop

Nobody runs the test runner directly. To get a test result, make a request to the test manager.
Its rules are the `vid-test-manager` skill, invoked at the stage start
(Before any work): `sh checks/test.sh request …`, then `sh
checks/test.sh wait <ticket>` until it ends (v0.9.7.0.2).
Only you, the run manager, start the test analyst (`vid-test-manager`,
the test analyst): when a request's result says `analyst due`, and for
each line `sh checks/test.sh analyst-due` prints. Run it after every
test-author return and at each slice close; `sh checks/brief.sh return`
prints the same lines at every builder's and fixer's hand-back.

Plan, decompose, and sequence the PRD using your own best judgment.
Apply a strong bias toward reality before compounding: before
substantial work depends on a consequential assumption, prefer
confronting that assumption with evidence independent of the assumption
itself and representative of what it claims about, especially where
being wrong would cause broad or costly rework. Treat this as strong
planning advice, not a fixed rule; balance it against the other
considerations that make the overall plan effective, and depart from it
when the trade-offs justify doing so. Prefer completing one journey — actor or
machine — end to end and verifying it at its real boundary early, before
breadth across the modules it crosses; the run's first integrated
observation should not be the end grade. Size each builder step as a
modular unit: rows whose tests exercise the same modules and share their
setup, so one builder can make them pass together without holding the
rest of the product. Not so big that the builder spends its context
finding its way before it changes anything; not so small that the cost
of starting an agent and writing its brief dominates. Within that, choose
the grouping most likely to pass whole at the hand-back. The `build-cost`
lines in the progress table show what your past steps cost and how many
of their rows passed; use them. The decomposition is yours and is
never put to the owner for approval — no epics, checkpoints, or approval
pauses; the owner sees it only through the progress update. The inventory
remains the completeness floor under any decomposition: shell,
reachability, and journey rows have an owner even when no slice claims
them.

**The plan is a record (v0.9.6 3.1–3.5, R1–R6).** Before building, write
the plan into RUN-STATE's `## The plan` as one ```` ```vid-plan ````
block (the template shows the grammar): a line per step — its `name:` in
plain product words, the `modules:` it builds, the steps it `builds-on:`,
its `rows:`, its `lane:` — and one `shared:` line
naming what every step depends on (the harness, the fakes, the compose
file, migrations). Say in the prose below it which steps run side by side
and why they won't collide. Its `lane:` is `builder`: every step is built
by a builder (v0.9.7.0.9 3.6). You build a step yourself only when no
agent can be started, or when its whole change is smaller than its brief
(resolving a merge, one configuration line); its lane then reads
`orchestrator (<why>)`, and `sh checks/plan.sh check` refuses a bare
`orchestrator`. How many steps, their size and order are
yours, and you may change the plan at any time — but every edit is
recorded, `sh checks/plan.sh change <create|add|drop|split|merge|reorder|lanes|rows|other|edge> "<why>"` (`edge`: breadth first, below)
(`sh checks/plan.sh check` validates it first); an edit that is not
recorded refuses every admission until it is. Each change is a decision
(v0.9.6.2 3.3, R3): add `--trigger <t>[,<t>…]` — `initial`,
`test-evidence`, `owner-answer`, `agent-failure`, `cost`,
`discovered-dependency`, `scope-change`, `gate-refusal` or `unknown` —
with `--evidence <ref>[,<ref>…]` for any trigger but `initial` and
`unknown` (`receipt:<name>[#<case>]`, `question:Q<n>`, `agent:<id>`,
`refusal:<attempt>`, `step:<id>`, `commit:<sha>`; each must exist), and
`--expect "<one line>"`: what you expect the change to do;
`--alternatives "<one line>"` is optional. A change without them, or
with a reference that does not resolve, is refused; accepted or refused,
the script keeps the decision and its candidate plan in
`.vid/plans/decisions/`. A slice closes the steps
it claims, with a selected close of the rows they need and its verdict
pass (Slice close, below); the whole ledger runs once, at the end.

Two rules are checked whenever a step STARTS — a builder or fixer brief
naming it (`step: <id>` in the brief's header; `sh checks/brief.sh` asks
`sh checks/plan.sh admit`), or `sh checks/plan.sh start <id>`, which is
your first act on a step you build yourself:
- **Rule B — build only on passing steps.** Every step in its
  `builds-on:` passes on current results: each row's newest result is a
  pass, or the row is owed, held or `later` (v0.9.6.1 3.4). A row's
  newest result stands until its own test file changes, the row is
  amended, or a later receipt shows it otherwise — newest by the commit
  the run tested, not by when it finished. A change under modules or the
  shared paths does not re-open a passed row; such a break is caught when
  a close selects the row, or at the final full run.
- **Rule A — a ceiling on unverified work.** The rows of started steps
  that are not passing, with the new step's rows that are not, each
  counted once, stay within `.vid/budget unverified-rows` (60 per test
  environment). A step bigger than that is split. Raising the number is a
  recorded `plan-change what=other` naming `unverified-rows=<n>`.

A refusal names the gap — "S2 builds on S1, which is not passing: ROW-012
red …". Your moves are to fix the prerequisite, or to record a change (a
red row split into its own step the next one does not build on). A
started step is never refused again: its fixes and ordinary work flow. A
row's charge follows the row: moving or dropping a started step never
clears it, and a change that leaves a started row in no step is refused.
Test-author and grader briefs start no step and meet neither rule, so
bulk test repair and harness repair are never held back. When a refusal
holds up a step, "keep building" means what the rules admit: the started
steps, the red prerequisite, the tests.

**Breadth first, the owner's strategy (v0.9.7.2 3.1–3.11, R1–R15).** Depth
first is the default and nothing below applies to it. Breadth first is
the owner's choice, never yours: on the owner's instruction, quote their
words exactly — `sh checks/plan.sh strategy breadth-first --by owner --words
"<the owner's words, verbatim>"` — and the same for a switch back
(`depth-first`), which is always allowed: every marker below is then inert
and no plan becomes invalid. Under breadth first:
- **Where a row sits says what it is.** Feature steps hold core rows; a
  step line ending `| kind: hardening` holds edge rows, and nothing builds
  on a hardening step (`check` refuses it). A row you can't call stays in
  its feature step: it stays core. Split hardening by area at the normal
  step size.
- **A move into hardening is its own change**, `sh checks/plan.sh change
  edge "<why>" …`; a split, rows or other change that places rows there is
  refused. A protected row never sits in hardening, whatever the reason:
  the rows `sh checks/inventory.sh protected` derives (rows derived from a
  Tier-0 requirement or Tier-0 invariant, and rows a hostility probe names
  by their ROW id) and the plan's one `protected: <ROW ids>` line — add
  there what the tiers can't see,
  such as tenant isolation expressed through a lower-tier requirement; the
  line only grows. A row with an open product breach can't move to
  hardening while a feature step that built on its step is not done,
  unless the change names every such step and why it doesn't need the row:
  `--not-needed-by <id>[,<id>…] "<why>"`.
- **The graded gate (the owner's option b).** A new step is admitted only
  when every step it builds on is closed at its current rows and every
  eligible row graded — any verdict class; breaches don't hold it, they go
  to fixers or to hardening as routed today. So grade every close's rows,
  core first. A step already started is never refused. When a closed step
  is not graded (progress lists them under "Closed, not graded"), write a
  catch-up grader brief from its close's own evidence: `sh checks/brief.sh
  write --role grader --slice <N> --catch-up <step>`; the rows it leaves out
  (stale or amended since) go through a run, a claim and a grade.
- **Done is computed, never recorded by you**: `sh checks/metrics.sh
  step-state <step>` — closed at its current rows, every eligible row KEPT,
  its protected rows' owed hostility probes materialised and proved red,
  no held row. It prints the rows holding each.
- **Deferrals are records.** An edge finding — a row in a hardening step
  with an eligible BREACHED verdict — waits for its hardening step with `sh
  checks/metrics.sh defer --kind product|test --row <id> --why "<one
  line>" --from brief:<path>#<row>|receipt:<name>`. A core row and a
  protected row are never deferred, and a test-class breach on a
  feature-step row goes to a test-author pass at once. A finding with no
  verdict is graded first; a question goes to RUN-STATE's open questions.
  Under breadth first develop never writes `.vid/end-grade-queue.md`. When
  a fix or a fresh verdict settles a deferral, record `sh checks/metrics.sh
  defer-resolved --row <id> --by <commit|the verdict's brief>` — a
  disposition only; the fresh KEPT is what counts.
- **Draining hardening.** Once every feature step is done, the next steps
  admitted are hardening steps, and progress says `hardening: <n> rows in
  <k> steps`. Before that, a hardening step may start only when a test slot
  is idle and no feature step is admissible; its admission counts its
  parked rows as new under rule A (which otherwise leaves them out), so it
  can't push core work aside.
- **The debt and the builders.** Every progress print shows the debt, each
  row owed counted once, and how many builders are open against the
  owner's `builders-target=` in `.vid/budget` (shown, never enforced).
  Completion also needs every hardening step done.
- **At the upgrade** of a run already working breadth first: set the
  strategy in the owner's recorded words; catch up every closed step not
  graded; enter by hand, with `defer`, the open edge items of any free-form
  end-of-run file, and its questions as questions.

**Broken tests, sorted.** After any red, read the sorted groups the request's result
gives; hand setup groups to test-authors in bulk (`vid-test-manager`).

**Checkpoints.** When a checkpoint is due, request one (`--type
checkpoint`); it never blocks admission, close or claim
(`vid-test-manager`).

**Authority changes raise a flag, never a wipe (v0.9.8 3.3, R6).** A
ruling that reaches a row — an owner answer, an amended arm, a changed
decision rule — leaves its test as it was. It counts from the row's last
change: the last commit to a line of its test file that names it, or to
its INVENTORY line, or its kept record, whichever is latest (amendment
3; an edit for another row in a shared file is not this row's). `sh checks/inventory.sh
--report` lists each such row `authority-changed row=<id> since=<commit>
what=<ids>` (`sh checks/brief.sh authority --changed` alone prints the
same lines). Each is revisited once, by the next close's test-author
pass, briefed with the row (`brief.sh write --role
test-author --rows …`, its authority bundle in section 15). The pass
returns the row `kept` — the test stands under the new authority — or
amends it (a law commit; weakening needs an owner answer). Record the kept ones: `sh checks/brief.sh authority --kept
<ROW-id,…>`. Verdicts, attempts and holds are untouched; the `amended`
wipe is unchanged.

**The four legal stops (v0.9.5 3.2, R2).**

> End your turn only with its reason recorded:
> - `run: waiting`, when everything left waits on an open `Q<n>`;
> - `run: stopped <reason>`, for a genuine block or when the owner asked
>   to pause;
> - completion, computed by `sh checks/metrics.sh completion --record`.
>
> A report, the end of a slice or the end of your plan is not a reason to
> stop: keep building. If you stop with no reason recorded, the observer
> tells the owner that the build went quiet.

The owner's controls: "pause" → write `run: stopped owner asked to pause`
(and its event) after the current step, then stop; "continue", an answer,
a takeover or a return after a death → write `run: active` first, before
any other work, even when it already reads `active`. Every write of `run:`
is recorded as `sh checks/event.sh 'run state=<value>'` — the history, and
what clears a death notice. Before any tool call that asks the owner and
blocks, the run is `waiting`; never use the blocking question tool while
work that does not depend on the answer remains or any agent you started
is still running.

**The run's record (v0.9.3 3.8, R7, R12; v0.9.5 3.2).** `.vid/RUN-STATE.md`
exists from develop's start (above); rewrite it at every slice open, every
slice close, every handoff and at the completion report, carrying every
key over: keys first — `run:` (`active`, `waiting`, `stopped <reason>`,
`complete`), `session:`, `questions:` (`<k> open · next Q<m>`, or
`- · next Q<m>` — the next number is never reused), `slice:` (N
open|closed, since, commit), `modules:` (the module paths this slice
touches), `claims:`, `receipt:` and `briefs:`, `held:` — then `## The
plan` (v0.9.6: the recorded plan block, above) — then prose: the
slice plan and why, what was considered and rejected, the dependencies
discovered and what they changed (an unbuilt module a row needs is written
there the moment it is found), the open product questions as one line each
(`- Q<n> · asked <UTC> · gates <rows | modules | all remaining work> ·
<the question, one plain sentence>` — nothing else in that section), the
rows under work by their attempt records. The plan is yours; the record describes it. At slice open record
`sh checks/event.sh 'slice-open slice=N sha=<HEAD>'` and
`sh checks/event.sh 'slice-modules slice=N <paths>'`, at slice close
`sh checks/event.sh 'slice-close slice=N sha=<HEAD>'` — RUN-STATE is rewritten, the
events are the history (`sh checks/metrics.sh` prints each slice's
modules and seam-table changes from them). For each slice:

Building a step — steps 0–6: `vid-build` (`${CLAUDE_PLUGIN_ROOT}/skills/vid-build/SKILL.md`).

## Long-run supervision (§8)

**Spawned agents are watched from the hooks' record (v0.9.7.0.6 3.2),**
with no declaration: the plugin's hooks record each agent's start and
stop, and the observer reads the agent's transcript — finished, working,
or quiet after 20 minutes with no new step — and tells the owner when one
goes quiet. **Dev servers, background loops and corpus builds** still
declare an expected envelope BEFORE they start:
`sh checks/watchdog.sh declare <op> <seconds> '<probe-cmd>'
<operation-id>`, where the probe is a MECHANICAL observation of the
underlying system (active queries and their ages, container state, agent
liveness), decided when the operation starts, not improvised when it
stalls. **The probe is a predicate about the named operation (v0.9.3
3.9):** it exits 0 only when it observes that operation itself alive or
progressed — a process by its id, a query by its age, a container by its
name and state — and non-zero otherwise; a command that merely lists
status and exits 0 whether or not the operation exists is not a probe,
and `declare` refuses a probe that does not name the operation's
identifier, as it refuses a missing probe. Exceeding the envelope (`sh
checks/watchdog.sh check <op>`) runs the probe, bounded (`VID_PROBE_BOUND`,
default 60 s), and reports its output — exit 2 when it answered, exit 3
when it failed or did not return — never a re-estimate, never a longer
wait; act on what the probe observed. An overdue operation closes on an
observation: `done` is refused until a `check` after the expiry, and a
re-declare changes only the envelope, keeps the start, and is refused on
an expired operation that has not been checked. The envelope is whole
seconds (`5400`, never `90m`): `declare` refuses anything else. **The
observer (v0.9.3 3.9, R13; v0.9.5 3.3, 3.5)** runs outside this session as
the loop you start (`sh checks/observe.sh start`; one tick per interval,
every worktree with a run): it reads the records, probes overdue operations,
and nudges — `.vid/NUDGE`, printed by the pre-commit hook — only for a
declared operation that fails its probe. It records a notice for the owner
(an `observe: notice —` heartbeat line; v0.9.7.0.9: nothing is sent) when a
question waits, when the run waits on an answer or stops for a reason,
when it dies, and when it goes quiet with no reason recorded: at the first
tick after one quiet interval, unless a test run holds the ledger lock (or,
under a 0.9.6 plan, a live run folder) or a declared operation is inside
its envelope — either for at most 2 h
after its start. It never makes this session continue. Answer a nudge
with an observation: `sh checks/watchdog.sh claim run --evidence '<what
you observed>'`. Progress claims go through
`sh checks/watchdog.sh claim <op> --evidence '<observation>'` (or
`--unverified`, stated) — the process-claim rule (§8.2), mechanised. In
autonomous mode the heartbeat (.vid/HEARTBEAT.md) is the auditable trail:
what is running, since when, on what evidence, which session defaults
were decided (`note`) — a morning review reconstructs the night from
records, not from the session's memory of itself. Agent liveness is the
observer's, from the hooks' record, never an envelope or a timer of yours.

**The progress update (v0.9.6 3.15, R15).** Under `plan: required` the
observer records `sh checks/progress.sh --record` every hour and after
every plan change, into `.vid/PROGRESS.md`, and sends the owner its
headline; it arrives even while you are busy, and it never makes this
session continue. After a plan change, and whenever you report to the
owner, run `sh checks/progress.sh` and print its table unchanged — what's
done, where the build is, what's left, the owner's open questions, the
estimate and how it was calculated. Add your one line with `sh
checks/progress.sh --now "<one line>"`. Never write a status table or an
estimate of your own: the format and the arithmetic are ViD's, and when
there is not enough data the table says "no estimate yet".

**Clean up what you start (v0.9.6 3.10, R10).** Whatever the run starts,
it stops when it no longer uses it: dev servers, background tasks and
loops, builder worktrees once merged, copies of the tree. Dev servers and
background loops are long-lived operations — declare each with
`sh checks/watchdog.sh declare`, and record `done` when you stop it. At every slice close and before completion, the test
manager's leftovers list must be empty (`vid-test-manager`).

## Spawned roles (v0.9.3 3.1, R1, R2)

Every agent this run spawns — builder, fixer, grader, test-author, test
analyst — is briefed by a FILE, `.vid/briefs/<slice>/<role>-<n>.md`,
written before the spawn and kept (resume reads them). A brief quotes; it
never summarises.

**Spawn by type (v0.9.7.1 3.1).** The Agent tool's subagent type is the
role's ViD agent: `vid:builder`, `vid:fixer`, `vid:test-author`,
`vid:grader`, `vid:test-analyst`. Each has only the tools its role needs;
builders and fixers run in their own worktree with `vid-build` preloaded.
`.vid/budget` may name `model-<role>=` and `effort-<role>=`: pass them as
the Agent tool's model and effort; the effective values are recorded at
the return. The prompt is the repository path and the brief file, nothing
else of this session.

```
role: builder|fixer|grader|test-author    slice: <N>    step: <id>   (builder, fixer)
quoted-at: <commit sha>
receives: <this role's items>    must not receive: <this role's exclusions>
```

For `grader` and `test-author` the independence paragraph
(checks/selftest/cases/passes.sh, verbatim) follows. Then the items, as
numbered sections `## 1` … `## 8`: (1) the rows, each as its INVENTORY
line verbatim, a journey with its `transitions:`; (2) the effective PRD
items they derive from, verbatim; (3) the DECISIONS.md lines that cite a
row or any id of its derived-from — a mechanical join on whole ids, every
field read, `why:` included — and the lines whose label (`applies-to:`)
names a briefed row, one of those ids, a rule row it joins, a screen code
the rows mark or a DIF id their `divergence:` names (v0.9.7.3), plus the
ids you name (`--decisions`): whole
lines, and for a grader each one's rule only, the line up to ` | why:`
(v0.9.7.0.5 3.2: a decision's why can recount an earlier verdict); (4)
the global laws quoted from CLAUDE.md —
ledger, law-change, placement, seam — line for line; (5) the start commit
and the current receipt's name; (6) the test requests: type, rows, and the selection; (7) the row's attempt record, `.vid/verdicts/<ROW-id>.md`, whole;
(8) links to the full sources under `further reading (optional)`; a
grader's and test-author's brief adds (15) the rest of
each row's authority bundle (v0.9.8 3.3, R5): the owner answers the
section 2 items' `source:` cites, each as its latest row, and the design
states the rows' markers cite, with the files under design/ holding them —
`sh checks/brief.sh authority --row <ROW-id>` prints one row's bundle. A
builder's brief has no (4) — CLAUDE.md is loaded into every agent — and
adds (9) each row's test locations, (10) its step from the plan in force
with its modules' ARCHITECTURE.md rows, (11) the rule rows whose
`origin:` cites its items and (12) your notes, when you give them; a
builder's and a fixer's header names `skill: vid-build` (v0.9.7.0.7 3.2).

| role | receives | must not receive |
|---|---|---|
| builder | 1–3, 5–12 | another batch's brief or verdicts |
| fixer | 1–8 (7 carries the counterexample) | another batch's brief |
| grader (slice close) | 1–6; the claimed rows' owed siblings, the flagged tests, GRADING-CHECKLIST.md, the grader's pass (`skills/vid-verify/passes/grader.md`), whole | item 7; `.vid/verdicts/`; a legacy `owed: reverted — "<reason>"` sibling's detail, carried as `owed: reverted — (detail withheld from graders)`; and a stated read exclusion: *"Do not read under `.vid/` beyond the receipt named above"* |
| test-author | what `skills/vid-test-inventory/passes/test-author.md` lists, in this format | what it lists |

**An agent in its own worktree** is linked to the run automatically: `checks/test.sh` and
`checks/event.sh` find the live run among the repository's worktrees. When
more than one run is live, or a run refuses with 'ambiguous', it runs `sh
checks/plan.sh home --brief <its brief file>` as its first act; the brief
names the path.

**Write every grader, fixer and test-author brief with `sh checks/brief.sh
write`, never by hand or by a script of your own** (v0.9.7.0.5 3.3):
`CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/brief.sh write --role
builder|grader|fixer|test-author --slice <N> (--rows <ROW-id,…> | --claim <file>)
[--step <id>] [--selection '<selection>' [--deployed-selection '<selection>']]
[--receipt <name>] [--decisions <D-id,…>] [--notes <file>] [--continue <package> [--law <sha>]]` quotes the
records at HEAD word for word into a new `.vid/briefs/<N>/<role>-<n>.md`,
stamps it and runs the check; no option adds text but `--notes`, your own
words, quoted as section 12. A builder or fixer brief names
its step (`--step`) and its rows' test selection in the runner's syntax
(`--selection`, and `--deployed-selection` when the harness declares
one): section 6 becomes the real request, with the brief's attempt id
(`try:`, beside `branch:` and `return:` in the header) — ViD never derives
a selection from row ids. A grader brief names its receipt (`--receipt`).
A continuation names the package its predecessor saved (`--continue`)
and, when law had to land first, that commit (`--law <sha>`): the brief
gains `## 14 continuation`, and the successor restores it.
Every builder, fixer, grader and test-author brief is written with `sh
checks/brief.sh write`.

Run `sh checks/brief.sh <file>` before every spawn; spawn only on `ok`
(it records `brief-check path=<file> result=ok|fail`). A test-author brief
may quote a row born after `quoted-at` — the rhythm writes the test before
its row — when it matches the working tree's INVENTORY.md, or list it
`pending-birth: ROW-…`; an item a fix appends with the fix is listed
`pending-append: REQ-…`. The spawn prompt names the repository path and the
brief file, nothing else of this session. Every verdict event names its
brief and the commit it quoted (`brief=<path> quoted-at=<sha>`);
`sh checks/metrics.sh` flags a verdict whose brief was never checked
(`honesty FLAG verdicts-without-brief`). The grader's CODE read stays
unbounded — that is where findings come from; the end grade's domain
batches are GRADING.md's, in this same format.

**The hand-back (v0.9.7.0.7 3.3; v0.9.7.1 3.4, 3.7).** Every builder and
fixer writes its return file itself, at the path its brief's header names
(`.vid/briefs/<N>/<role>-<n>.return.md`); its final message begins
`return: <that path>`. Record it before acting on it, in one command: `sh
checks/brief.sh return <file> --agent <the agent id from the Agent tool's
result>` — it writes the `agent:` line in, checks every row of the brief
is there once, each `pass` shown passing by its receipt on the committed
law and tests, and the commit descending from the brief's quoted-at;
records `agent-returned`, the agent's `build-cost` and your own
`manager-cost`; and prints each row's results at the return's commit, the
merge probe (clean, or the conflicting paths), the worktree's uncommitted
files, any continuation package of the attempt, and the `law-needed:`
lines. A refusal names the line; it does not route: what each row needs
is yours to decide. On ok, act on any `analyst due` lines it prints
(`vid-test-manager`). When the agent ended with requests nobody will read,
cancel them: `sh checks/test.sh cancel --try <its try>`. A request of your
own carries no attempt id (a full or close run): cancel it by its ticket,
`sh checks/test.sh cancel --ticket <its ticket>` (v0.9.8.1 R28).

**A grader's, test-author's or analyst's return** has its cost recorded
too: `sh checks/brief.sh cost <its brief> --agent <its id> --tokens <the
Agent tool's total> --source agent-tool`. The transcript's figures are
used when it is found; when it is not (the agent ran outside the
project's own session), your total is recorded as reported, never as
unknown (v0.9.8.1 R15).

**Unfinished work and continuations (v0.9.7.1 3.4).** A builder saves its
own unfinished work before it hands back; for one you stopped, save it:
`sh checks/brief.sh save <its brief> --worktree <its worktree>`. The
successor's brief names the package (`--continue`) and any law commit it
waited for (`--law`); it restores the package onto its own base. A package
you will not restore: `sh checks/event.sh 'continuation-superseded
try=<its try>'`.

**Builders keep their tests and commits (v0.9.7.1 3.9a, R14).** Builders
and fixers own their tests and commits: never run a builder's tests or
commit a builder's work as the normal way of working. A coordination
failure — a collision, a lost ticket, a wrong home — is fixed at its
cause: find which request, which ledger, which slot; record it, `sh
checks/event.sh 'incident slice=<N> <the cause>'`; fix it. Taking control
away is not the fix. A takeover, when unavoidable, is recorded, `sh
checks/event.sh 'takeover started reason=<cause> scope=tests|commits|both'`,
and ends at the latest when the next step starts: `sh checks/event.sh
'takeover ended fix=<what was fixed>'`. The progress table and the
observer show one still open.

**A builder on Codex (v0.9.7.1 3.9).** Builders run on Claude unless the
owner says otherwise. Only on the owner's plain words ("use Codex for
builders", "use Claude for builders") run `sh checks/job.sh tool
codex|claude --by owner`; never on your own. It applies from the next
spawn; fixers stay on Claude. With `builders: codex`, a builder's step is
a supervised job, under the same brief, rules, courts and evidence:
1. write the brief as for any builder, then `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/job.sh
   start --brief <it>` — the job record and its worktree at the brief's
   quoted-at;
2. `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/job.sh run <try>` with the background facility. It
   refuses to launch when the worktree's test requests would miss the
   run's shared ledger. Wait for its one line, `job <try> exit=<n>
   return=<path|missing>`, in bounded calls; nothing streams to you, and no
   message reaches a running job — a correction goes into a successor brief;
3. on its line: `sh checks/brief.sh return <the path> --agent codex:<try>`,
   then `sh checks/job.sh status <try>` (a `coordination fault` line is an
   incident: fix its cause) and `sh checks/job.sh clean <try>`;
4. to stop one: `sh checks/job.sh stop <try>` — the supervisor stops the
   job, its work is saved and its tickets cancelled. A
   `job-recovery-required` line means its process can't be confirmed gone:
   tell the owner and leave its worktree.
After a compaction or a resume, the page lists every job not yet collected
and cleaned: wait, collect, clean or stop each; never launch a try twice.

**When Codex runs out** (`job-exit … reason=codex-limit`): its work is
saved, its tickets cancelled, and builders are paused — no builder on
either tool. Keep the work that is under way (other builders, closes,
grading). Ask the owner, word for word: "Codex has run out of allowance
(resets <time>). Builders are paused. Say 'use Claude for builders' to
continue on Claude, or 'wait for Codex' to resume when it resets." Act only
on the answer: `sh checks/job.sh tool claude --by owner`, and the stopped
step continues on Claude from its saved package; or wait until the owner
says to resume (`tool codex --by owner`). Never switch on your own, never
retry against the limit.

## Slice close — the verdict pass (§6)

**What the close runs (v0.9.6.1 3.2–3.6, R1–R3).** Under `plan: required`,
a slice closes on a short
list of tests, not the whole ledger:
1. Write `.vid/close/<slice>.rows` from the closed steps' diff (`git diff
   <base>..HEAD`; `sh checks/plan.sh base <id>` names each step's base):
   one line per earlier row you know the change affected, `ROW-<id> |
   <one-line reason>`, with the diff's REQ and ROW citations as hints; for
   a change to `shared:` paths or to uncited code, one `note | <what you
   checked>`. An empty file when you name none. Shared test code counts
   the same: an edited test file stales only the rows whose id or own test
   a changed line touches (v0.9.6.1 3.4), so for a change to its imports,
   helpers or data that names no row, name the rows it affects, or write a
   `note`.
2. Request the close as one batch: `--type close --steps <ids> --batch
   --phase1 <file> --phase2 <file>`, its groups built from close-rows'
   list (`vid-test-manager`, v0.9.7.0.12). One `wait`: it ends `green`,
   `red phase <p>, rows …` or `incomplete phase <p>, chunks …`.
3. `sh checks/metrics.sh claim --batch <its ticket> --from <the previous
   close's batch ticket> | tee .vid/briefs/<N>/claim.txt` (no `--from` at
   the first close). A refusal prints `not-run`, `failed` or `mixed tree`
   lines and exits 2: fix the failure and request the batch again — at the
   same tree its green chunks are adopted, not run again. On success it
   writes `step-closed … batch=<ticket>` for each step. A `provisional
   row=<id>` line marks a row no checkpoint or full run has yet run whole.
4. The grader, as today — its brief names the provisional rows.
Append close-rows' output and the claim's to the slice report. An earlier
row not on the list keeps its last result: it is not re-run and not sent
back to the grader. **The last slice close**, or the run before the
completion report, is a `full` request, claimed the same way with `--steps` (its `--from` the receipt the previous close's `step-closed` names): anything the lists missed
shows up there. **A run already under way** that closed a slice under
0.9.6 has no `step-closed` history: it keeps 0.9.6's close after the
refresh — the whole ledger, the claim without `--steps` — and 0.9.6.1's
close starts with its next develop run. A run with no closed slice uses
0.9.6.1's close directly.

A slice today would otherwise end fully counted and never read. At slice
close, after the close run shows the slice's rows green:

1. Compute the claim mechanically from the receipts (v0.9.2 3.6, R9):
   `sh checks/metrics.sh claim --from <slice-start report> --to <close
   report>` — both export-backed reports (`<sha>.full.xml`; under a plan
   the close is a batch, claimed `claim --batch <its ticket> --from <the
   previous close's batch ticket>`, above; a `.live.` report is refused as
   the close) — lists every row whose cases went from
   not-passed or absent to passed, plus the rows materialised inside the
   range (a mid-slice birth is claimed, never assumed) and the rows re-paid
   after a reversion or a regression; the claim is the set of `claim
   row=ID` lines, never a diff of green counts. Save it, `… | tee
   .vid/briefs/<N>/claim.txt` — working state, like the briefs (v0.9.7.0.5
   3.3); the brief takes only its row ids.
2. Write the grader's brief and spawn ONE fresh grader (v0.9.7.0.5 3.1,
   3.3): `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/brief.sh
   write --role grader --slice <N> --claim .vid/briefs/<N>/claim.txt
   --receipt <the close's receipt, or its batch ticket> [--decisions
   <D-id,…>]`, spawn only on
   `ok` (Agent tool, subagent type `vid:grader`, NO build-session context — only the
   repo path and its brief file, `.vid/briefs/<N>/grader-<n>.md`, Spawned
   roles, above). Then follow `vid-verify`
   (`${CLAUDE_PLUGIN_ROOT}/skills/vid-verify/SKILL.md`): the grader's pass
   and what its brief withholds, the return's completeness check,
   recording each verdict and the attempt record, routing by class, blind
   re-grades, the bound, the hold and the owner's "how far?" question.
   Anything the grader notices OUTSIDE its rows files to the end-grade
   queue (.vid/end-grade-queue.md) and cannot block the slice — checklists
   terminate, investigations do not. Under breadth first an edge finding
   is a `defer` record instead (Breadth first, above).
3. **The fault proof (v0.9.8 3.4, R4)** — for the rows the grader's brief
   names under `### Fault proof`, prove each fault, one at a time, as
   `vid-verify` says. Measured, never a gate: done and completion are
   unchanged.
4. **The loop's stop stays with develop.** A re-verdict's brief is written
   the same way, `--rows <the rows>`.
   Re-verdict only rows in the fix's blast radius (changed modules +
   declared dependents, the seam table). The breached set must strictly
   shrink; if it does not, halt the loop and escalate rather than iterate.
   **Your own judgment is the backstop for scope (v0.9.7.0.4 3.1):** if
   you read a breach as a dispute over how far the row's promise extends,
   and the grader did not flag it, ask the owner at once — `vid-verify`'s
   "how far?" question, through the two-channel rule, with the ordinary `Q<n>` line
   and `question n=<n> state=asked gates=<the row>` event. The open
   question gates the row. Never edit the grader's verdict.
5. **At the FIRST slice close only — promote or delete (v0.9.2 3.9b,
   R14):** for each report-only extractor class (vacuity, rendered,
   strength): sample 10 of its reports, count true and false positives,
   then promote it fail-closed, keep it advisory, or delete it — one
   standalone law commit per class, its `Decisions:` line stating the
   counts, and the event `sh checks/event.sh 'adjudicated class=<name> promoted|advisory|deleted
   tp=<n> fp=<n>'`. `evidence FLAG report-only-unadjudicated class=…` flags
   every later slice until the event exists. **Vacuity and strength
   (v0.9.8 3.6, R11)** are measured instead and stay advisory until a later
   release sets a bar: with the labelled fixture in place, `sh
   checks/census.sh --measure checks/selftest/fixtures/detectors`, then the
   event `adjudicated class=<name> advisory tp=<n> fp=<n> fn=<n>` from its
   counts, summed over the class's rules — no promotion, no deletion.

## Resume (v0.9.3 3.12, R16)

A session that takes over a run — after a death, a kill, a wedge, or the
observer's notice — resumes from records, never from a wedged
session's transcript: `sh checks/observe.sh resume` prints the whole
`run:` value (a stopped reason included), `session:`, the open slice, its
modules and claims, the open questions, any standing death or quiet
notice, the receipt and whether it is current at HEAD, the held rows, the
live briefs, the declared operations, the uncommitted paths and any stale
lock or lease with its holder, any re-read still owed, and the open
agents. The page printed after a compaction or a resume is this same
record (v0.9.7.0.6 3.4): the plugin's hook puts it into the session, with
the watcher's line and the ViD skill files to re-read in full — read
each with the Read tool before anything else; until you have, every other
tool is refused. Then, before any other work: write
`run: active` and `session: $CLAUDE_CODE_SESSION_ID` (whether a resume
keeps the id is not documented, so always rewrite it — likewise after a
/clear, which changes it), record `sh checks/event.sh 'run state=active'`
and the stage start (Before any work), and start the watcher, `sh
checks/observe.sh start`, then check it, `sh checks/observe.sh alive` — on
exit 1, tell the owner what it printed and stop as `run: stopped the
watcher is not running` (Before any work). Read
RUN-STATE's prose, then
continue the slice, or report plainly why it cannot continue. Never remove
a stale lock or lease before inspecting what it held.

**Record the dataset as you go (§10 — F19: the develop dataset was
prose).** One line per event, written with `sh checks/event.sh '<event>'`
— it appends the line to `.vid/metrics-events` with ` at=<UTC>`, the
time every reader takes (v0.9.5 3.11; RECORDS.md lists every event) — the
substrate `checks/metrics.sh` aggregates: `stage name=develop
state=start|end session=<id> [records=<n>]` · `run state=<the run: value>`
(every write of `run:`) · `question n=<n> state=asked gates=<ROW-ids and
module paths, comma-separated, or all>` · `question n=<n> state=answered` ·
`verdict slice=N claimed=X
breached=Y` · `re-verdict slice=N round=R breached=Z` · `reissued row=ID
why=<answer id> [rounds=<N>]` (v0.9.3; `rounds=` v0.9.7.0.4; `attempts row=ID n=K` and `reverted row=ID` are
no longer written — the attempts and the holds are computed; legacy
events are read) · `regressions slice=N n=M` · `tokens slice=N
phase=build|verdict|fix|re-verdict|review n=T` · `rows-paid slice=N n=K` ·
`paid row=ID via=ledger|browser|census|deploy` (the proof channel per paid
row; a `via` other than `deploy` against a deploy-owed row trips
checks/metrics.sh — v0.9.1 3.6) ·
`owed-close slice=N n=K` · `wall-clock slice=N seconds=S` · `ledger-run
seconds=S kind=full|close|checkpoint|deployed|scoped report=<name|none> status=<n> [role=…]`
(written by checks/test.sh per run — v0.9.2 3.6, v0.9.3 3.3/3.10; the
per-class seconds split and the full-runs tripwire read it) · `verdict
slice=N row=ID result=KEPT|BREACHED class=product|test|harness
[transition=k/n] brief=<path> quoted-at=<sha>` · `amended row=ID
sha=<commit>` (written by checks/hooks/post-commit) · `invalidated slice=N [report=<receipt>] <why>` ·
`plan-change what=<…> hash=<h> why="<…>"` and `step-start step=<id>
plan=<h> base=<commit>` (written by `checks/plan.sh`) · `step-closed
step=<id> report=<receipt>` (written by the claim) · `checkpoint n=<n>
report=<receipt> built=<b> regressions=<k> base=<commit>` (written by `sh
checks/metrics.sh checkpoint`) · `testenv stacks=<k> …` (written
by `checks/testenv.sh record`) · `red-observed row=ID report=<receipt>
case=<case id> assertion="<…>"` · `progress trigger=<…> by=<…> …`
(written by `checks/progress.sh --record`) ·
`adjudicated class=<name> …` · `engine-only breach row=ID engine=<name>`
· `incident slice=N <what>` (a harness breach: `incident slice=N harness
row=ID <what>`) · `agent-death slice=N <which>` · `slice-open slice=N
sha=S` · `slice-close slice=N sha=S` · `slice-modules slice=N <paths>`
(v0.9.3 3.8) · `completion unmet=U strict-gaps=G` (written by `sh
checks/metrics.sh completion --record`) · `court name=<court>
seconds=<s>` (written by coverage.sh --strict, census.sh --report and
inventory.sh --report — v0.9.3 3.13)
(watchdog.sh appends `stall` lines; the pre-commit hook appends
`failif-amendment`). At slice close append the slice's section to the
slice report — a `## slice <N> <UTC>` heading, then the computed block and
the closure: `printf '\n## slice %s %s\n\n' N "$(date -u
+%Y-%m-%dT%H:%M:%SZ)" >> .vid/SLICE-REPORTS.md; sh checks/metrics.sh
--slice N >> .vid/SLICE-REPORTS.md; sh checks/metrics.sh closure >>
.vid/SLICE-REPORTS.md` — the counts are computed, never hand-written prose,
so run-over-run comparison is arithmetic, not archaeology; the newest
section is what a viewer reads as current (RECORDS.md).

**The slice summary (v0.9.5 3.12, R12).** After `slice-close`, append the
slice's section to `.vid/SUMMARY.md` (created from `${CLAUDE_PLUGIN_ROOT}/templates/SUMMARY.md`),
in the owner's language — no row ids, no court names:

    ## <UTC> — slice <N>

    - **Working now:** <features and journeys that now pass, by name, in product words>
    - **Went back:** <what stopped working, or "nothing">
    - **Decided for you:** <each decision ViD took on the owner's behalf this slice, one line, with its id>

`sh checks/metrics.sh` flags a closed slice with no section, "Went back:
nothing" beside a recorded regression, and a DECISIONS.md `D-NNN` or a
`model_proposed` PRD answer added during the slice and not named there.

**Ending the verb.** The completion report records
`sh checks/event.sh "stage name=develop state=end session=$CLAUDE_CODE_SESSION_ID"`.

Doctrine: rows are ratified law, so BREACHED is "not done," not a finding
needing adjudication. The pass is internal — the owner sees nothing new. A
slice ends either kept or honestly in debt, never silently wrong. Expected
error direction: code-conformance judging biases toward false BREACHED —
safe for correctness, expensive in the attempt bound; a `test` or
`harness` breach costs no attempt, and read held-row counts
accordingly.

## The two-channel question rule (operational)

- Hit a load-bearing PRODUCT unknown — behavior, domain semantics, policy,
  priority? Record it first: a `Q<n>` line in RUN-STATE (v0.9.5 3.2) naming
  what it gates — the rows, the modules, or "all remaining work" — and
  `sh checks/event.sh 'question n=<n> state=asked gates=<…>'`. Then ask the
  owner in your message, in plain language, with a recommendation where the
  evidence supports one — never with the blocking question tool while any
  work that does not depend on the answer remains or any agent you started
  is still running; that tool is for when the run is `waiting`. Never
  guess, and never build what the question gates. Keep building everything
  else. When nothing is left that does not depend on an open question, set
  `run: waiting` and stop. When the answer arrives: write `run: active`
  first, append the answer to the PRD (as today), delete the `Q<n>` line,
  record `sh checks/event.sh 'question n=<n> state=answered'`, and
  continue. **The delegated mark (v0.9.7.4 3.9, R10):** when the owner has
  delegated decisions to ViD's recommendation, each answer ViD writes under
  that delegation is marked in the same step that commits it — `sh
  checks/metrics.sh delegated --answer <A-id>` — so the viewer lists it for
  the owner to confirm; an answer the owner gave in their own words is never
  marked. The answer's append goes to PRD.md
  `## Appends` (under a PRD headed `grammar: 0.9.4` or later, a new or
  amended item carries `feature:`; under one headed `grammar: 0.9.5` or later every new or AMENDED demand item and invariant also carries `plain:` — one sentence of at most 30 words saying the rule in the owner's words, no ids, every number in it taken from its own statement or fail-if (v0.9.5 3.13)); spawn
  `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/whole-set-review.md`
  in `mode: delta` on that append against the effective set (v0.9.1
  3.2) — its findings are the next questions or `fix_from_record`
  amendments in the same sitting (v0.9.8.1 R29: every `needs_owner`
  finding that narrows or withdraws a fail-if arm goes to the owner as one
  question per review, listing each row, its arm and the answer it
  follows; the answer settles every row it names), and the run records `sh checks/event.sh 'tokens slice=N
  phase=review n=T'`; add a ledger test if testable, continue.
- Hit a TECHNICAL unknown? Decide, log to DECISIONS.md with its label
  (`| applies-to: <ids and codes>`, or `| scope: project` only when it bears
  on many areas — the hook refuses a line with neither), keep moving. Never
  ask — unless the choice forces a product tradeoff, which makes it a product
  question ("instant search or cheap infra — pick one").
- **The owner's queue is questions too (v0.9.5 3.1).** Rows held for the
  owner, rows owed on an owner decision, and grade findings awaiting
  adjudication are recorded the same way: one `Q<n>` line each, gating
  those rows. In the event, `gates=` lists the ROW ids and module paths
  comma-separated, or `all`. `sh checks/metrics.sh completion` counts every
  open `Q<n>` line as a strict gap, and `sh checks/metrics.sh` prints
  `question FLAG gated-work q=<n> row=<id>` when a row a question gates is
  paid or kept while the question is open — information, never a refusal.
- Non-blocking product uncertainty? Leave `VID-QUESTION: <question>` at the
  site and keep building.
- Internal issues — doc consistency, seam drift, a stale ARCHITECTURE row, an
  append that needs reconciling — are technical-channel by definition: sort
  them out autonomously in the same commit as the work that exposed them, and
  log the surprising ones. Never surface housekeeping to the owner.
- "Blocked" is reserved for the genuinely impossible: Docker absent, no
  network, a credential only the owner holds. Say plainly what is missing and
  keep building everything that does not depend on it.

## Done — evidence, then the adversarial grade

"Done" is evidence, not a claim:

- the final `full` request (Slice close, "The last slice close")
  — ledger green, inventory rows included. That one run serves both the
  last close and this check: do not run it again here. A fix made after
  it needs another whole-ledger run, because completion accepts only a
  full receipt of the current code.
- `sh checks/coverage.sh --strict` — every REQ cited under app source and
  ledger-tested; every design marker cited; every route inventoried, no owed
  rows, no unproved tests, no orphan surfaces; zero open markers
- `sh checks/census.sh` — zero unratified orphans, zero pending (nothing
  owed remains, so debt-awareness has nothing to excuse); the divergence
  table contains only ratified rows
- every Tier-0 protection attempted, not merely read: `hostility-gaps=0`
  and no Tier-0 rule owing a sibling in the inventory line (§4). The
  hostility count against the Tier-0 count is reported as two numbers,
  never as a proportion of anything
- `sh checks/design-cite.sh --strict` — when a marked design exists

Then completion **automatically triggers a first /vid grade** — report only,
no owner request needed. Follow
`${CLAUDE_PLUGIN_ROOT}/skills/vid-grade/GRADING.md` exactly: fresh-context
graders with NO build-session context, every live `pilot` REQ batched by
domain (~25–30 per grader) and every `later` REQ listed as deferred, never
ABSENT (v0.9.1 3.6), every graded REQ PASS / PARTIAL / FACADE / ABSENT
against its own Fail-if with file:line evidence. Your green tests were written by the same
mind that wrote the bugs; the graders were not.

NEVER auto-apply grader findings — that collapses author and verifier back
into one. Findings go to the owner for adjudication (fix / dispute / defer);
the accepted rows are applied by `/vid fix` — the targeted apply verb. A
completion report delivered while completion is unmet asks "adjudicate the
findings" as a `Q<n>` line and sets `run: waiting` — how the run tells a
natural end from an unasked stop (v0.9.5 3.1).

## Completion report

Present to the owner, in this order:

- **first line, the rows headline** (v0.9.2 3.8, 3.11, R10): `sh
  checks/metrics.sh`'s `rows: kept K · unverdicted U · breached B · red R ·
  owed O · deploy-owed D (unmet …)` — rows, never tests; `receipt: none`
  if HEAD has no export-backed full report, in which case the build is not
  done
- **"Complete" is computed, never asserted (v0.9.3 3.13, R18).** Run `sh
  checks/metrics.sh completion --record` when you compute the report: it
  prints the closure — five lines, every unmet row once: contract
  ambiguity (owner-decision rows and held rows), invalid test evidence (a
  latest `test` or `harness` breach), unfinished implementation (the
  rest), then deploy-owed (named) and `later` (counted) — and `completion
  unmet=U strict-gaps=G`, the strict gaps being coverage --strict's gaps
  and open questions. This is the report's second line — U and G, right after the rows headline:
  any non-zero → **"not complete"**, with the closure's lines; under
  breadth first a hardening step not done is printed `hardening not done:
  <steps>` and is not complete either (v0.9.7.2 3.9); both zero →
  **"complete, N rows at deploy, M later"**, and RUN-STATE says `run:
  complete`. The heartbeat never says complete otherwise — the observer
  flags a completion claim the record contradicts. Every slice report
  carries the closure too (`sh checks/metrics.sh closure`).
- what shipped, by REQ, briefly — with the ledger arc stated in the
  headline's terms ("rows: kept 41 · unverdicted 0 · breached 0 · red 0 ·
  owed 0 · deploy-owed 2; was kept 0 · red 41" — never a proportion), the
  rows the verdict pass holds called out as debt with their reasons (and
  a 0.9.2 project's legacy reverted rows)
- the coverage table and the census table (populations, exceptions,
  suppressions, the divergence table — what the green ledger did not
  validate)
- **N rows checked at deploy** and **M items later** — two lists of their
  own, outside the pilot-ledger count (v0.9.1 3.6): the deploy-owed rows
  (`owed: paid by /vid deploy gate N — …`, present and named, paid only by
  that rung's evidence — never a sandbox test that claims to prove one: no
  test-runner-triggered proof of a schedule's consumption, no
  harness-constant proof of an edge setting; the in-repo half is ordinary
  pilot work) and the `later` items
- the metrics roll-up (`sh checks/metrics.sh`) — surface the run totals
  plus any fired tripwire FLAG lines, not the full table; the full block
  lives in .vid/SLICE-REPORTS.md. No metric is presented as a score.
- the ranked grading findings table, for adjudication
- **Decisions made on your behalf** — every DECISIONS entry carrying
  `origin: proposal`, one plain-product-language line each. The owner never
  saw these choices; completion is where they get the chance.
- ALL open `VID-QUESTION` markers, batched

Every claim in the report states its evidence class (ledger test,
browser-class test, coverage join) or declares itself unverified — a fix is
never "working" on the strength of a status code (CLAUDE.md: report from
where the owner sits). If gaps, open markers, owed rows, or ungraded REQs
remain, the build is not done — say so plainly, no hedging.
