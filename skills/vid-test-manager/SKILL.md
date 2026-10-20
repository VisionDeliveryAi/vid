---
name: vid-test-manager
description: Internal — invoked by vid-develop and vid-fix; not a verb, never run by the owner. The test manager's rules — every test run is a request to checks/test.sh, waited on in calls of at most 200 seconds (the request rules themselves are vid-build's "Requests"); cancel by attempt; estimates, what stops a run, and reach; the test environments, broken-test sorting, checkpoints, frozen and scoped runs, the close's runs and leftovers; the test analyst, started when a result says analyst due.
user-invocable: false
---

# The test manager (internal)

Internal — invoked by vid-develop and vid-fix. Not a verb: `vid help`
does not list it, and the owner never runs it. The test manager is
`checks/test.sh` and these rules, not an agent (v0.9.7.0.2).

## The one rule

Nobody runs the test runner directly. To get a test result, make a request to the test manager.

## Requests and waits (v0.9.7.0.2 3.1–3.3)

**The request rules are `vid-build`'s "Requests" section** (moved there
whole, v0.9.7.1): asking, the types and who may ask, the estimate and
what stops a run, reach, and `wait` — calls of at most 200 seconds, called again until
the result. Builders and fixers preload that one copy; you read it too.
Here is the run manager's side.

**Cancel by attempt (v0.9.7.1 3.6).** A builder's or fixer's requests
carry its brief's attempt id. When an agent ended with requests nobody
will read, or you stopped it, cancel them: `sh checks/test.sh cancel --try
<its try>`. Only that attempt's tickets are touched: a finished one is
left alone, a queued one never starts, a running one is stopped through
the stop path; each ends `cancelled` after its teardown. Confirm each with
`sh checks/test.sh wait <ticket>` (exit 77). Your own close, checkpoint and
full requests carry no attempt id; they keep the close batch's stop.

## The test analyst (v0.9.7.0.3 3.1–3.3)

**When it is due.** At the end of every request — never a plain run
outside one — the manager checks three triggers, in order, and each that
fires writes an `analyst-due` event and an `analyst due` line in the
result:
- **cap** — the request's watcher stopped it (v0.26.10.4): silent for the
  silence limit (20 minutes; a likely hang), a pass's start-up past the
  start-up limit (60 minutes; a stack that won't come up), or the run
  limit (24 hours awake; unusual). The event and the line carry
  `stop=silent|startup|limit` and `last-output=<UTC>`; brief both to the
  analyst. `.vid/budget`'s `silence-minutes=`, `startup-minutes=` and
  `run-limit-minutes=` set the three;
- **setup** — 5 or more of the run's cases are red, each taking over
  60 seconds, whatever their messages: red cases that waited on
  something;
- **slow** — a case took over 240 seconds, named by its row (`rows=`), or
  by its case id (`cases=`) when the evidence join credits it to no row.

A slow start is not a trigger (v0.9.7.0.10), and nothing becomes due for
it. Inside a develop run every pass keeps, in the ticket, its test
environment's own log lines with their times (`timeline.<pass>.log`, the
last 20,000 lines, at most 20 MB, taken after the pass's result and
before its teardown; a red pass, or one short of its end — a capped,
cancelled or stopped one too — keeps its whole timeline compressed,
`timeline.<pass>.log.gz`, and a stopped one each service's last 200
lines, `last-lines.<pass>.log`) and its containers' end states (`services.<pass>.txt`:
state, exit code, memory kill, health, restarts, started-at, kept-healthy-at (v0.9.8: was ready-at),
finished-at, written before each teardown, a stopped run's too). Name
both to the analyst.

**A service that dies stops the run.** While the tests run, the run
checks the other containers of its test environment every 15 seconds. One
that exited with a non-zero code, or was killed for memory, stops the run
at once: the result's first line is `stopped: service <name> exited code
<c>|killed for memory at <UTC> — see services.<pass>.txt`, the state
`stopped`, no receipt. A service that ended with code 0 (a one-shot), or
that stopped before the tests began or after they ended, is not a death;
an unhealthy one is not judged. Read the services file and the timeline,
then request again or take it to the analyst.

No trigger is silenced by an earlier one, with one exception: a slow
case already named by an `analyst-done … outcome=limit` (its row in
`rows=`, or its case id in `cases=`) — that proposal is with the owner,
and the owner's answer governs.

**The test analyst.** Only the run manager starts it. When its own
request's result says `analyst due`, or a line of `sh checks/test.sh
analyst-due` does (each `analyst-due` with no `analyst-done` for its
ticket; `sh checks/brief.sh return` prints the same lines at every
builder's and fixer's hand-back, and the run manager runs it after every
test-author return and at each slice close), the run manager spawns
`passes/test-analyst.md` (the `vid:test-analyst` agent type, v0.9.7.1) with its `receives:`
list for that ticket. A builder, fixer or test-author that sees an
`analyst due` line leaves it: it can't start an agent, and the run
manager gets the line at the hand-back. The analyst's brief says
`role: test-analyst` and carries no test request (`sh checks/brief.sh`).
Keep building; it holds no test slot. When it returns, record `sh checks/event.sh 'analyst-done
request=<ticket> reason=<reason> outcome=<setup|hang|limit|none>
[rows=<the ROW-ids of its limit lines>] [cases=<the case ids of its limit
lines>] [owner=no]'`, lists comma-separated — `owner=no` when every limit
line says `prod: n/a` — and act on the return:
- **setup:** brief test-author passes with the named cases, one pass per
  cause;
- **hang:** record `sh checks/event.sh 'incident slice=<N> <the cause>'`,
  and fix the harness or ask the owner as the return says;
- **limit with `prod: n/a`:** a limit that exists only in the test is the test author's: no owner question, no `difference` row. Brief a test-author pass with the return; it changes the test.
- **limit:** ask the owner the return's question, through the two-channel
  rule, word for word. On a yes, the row's `difference` line
  (`DIF-NNN`: the setting, the test and production values, why it holds,
  the paying step) is appended with the owner's answer as a law commit.
  The test or harness change it allows is a test-author pass, and a
  product setting a builder or fixer task;
- **none:** nothing.

The analyst proposes; nothing it returns changes a test, a setting or a
limit by itself.

## Proof requests (v0.9.8 3.4, R4, R15)

A fault proof's two runs — its clean baseline and its faulted run — are
the run manager's requests with `--purpose proof`: a `prove-red`, or for a
deployed-shape row a `deployed` pass, made from the proof worktree
(`vid-verify`, the fault proof). One is open at a time: a second is
refused, naming the first. Their receipts are named `.proof.` and are no
ordinary receipts: nothing credits, claims, briefs, estimates or triggers
from them — no analyst becomes due for a proof's red, which the fault
caused — and they never overwrite an ordinary copy; their `ledger-run`
events stand for cost and export.

## Moved from vid-develop (v0.9.7.0.2 3.5)

Each paragraph as vid-develop carried it, its test-run commands in their
request form.

**The test environments (v0.9.6 3.9, R9).** Under `plan: required`,
after RUN-STATE is written and the plan recorded (below), before the first
test run, spawn
`passes/test-environments.md` once (its brief: the repository path, a
short selection that runs to its end, and the rows it runs). It measures one test environment,
picks two or three, proves two side by side and records them in
`.vid/budget`; until it has, every run gets one environment. Each
environment held on the host reserves the measured `env-mb`, started or
not: with another one held, a run takes its environment only when
Docker's memory, less other projects' containers and the reservations,
leaves `env-mb` plus `memory-headroom-mb` — else it waits, saying
`waiting for memory`. The first is never held back. The proof counts
only when its two runs overlapped (v0.9.7.0.11). Spawn it
again when `docker-compose.test.yml` changes, after a run killed for
memory (`incident … memory`), or when the machine changed. When its
return carries a `testenv short:` line, ask the owner the one question
the pass file words — it gates nothing; keep building.

**Broken tests, sorted (v0.9.6 3.11; v0.9.6.1 3.6).** Never run the
whole ledger early to find them — it runs rows of steps not yet built,
which fail whether or not they are broken. Sort the red of any selected
close, checkpoint or full run by where it stops: `sh checks/evidence.sh
red <receipt>` groups the `setup` cases (errors) and the failures by
their first message line. Hand the setup groups, and any large failed
group that points at the tests, to test-author passes in bulk — one test
defect behind many cases is one group, repaired once. The order is yours;
the progress update shows the sort's counts.

**Checkpoints (v0.9.6.1 3.8, R8).** With two or more proved test
environments, `sh checks/metrics.sh checkpoint` — and the progress
update — shows `checkpoint due n=<n> built=<b> plan=<p>` once the rows of
closed steps reach a third of the plan's rows, and a second time at two
thirds. Its population is `sh checks/metrics.sh checkpoint --population`
— the rows of closed steps and the materialised hostility probes; the
request asks for exactly those, and the recording judges them. Then start
`sh checks/test.sh request --type checkpoint --role orchestrator --why
"checkpoint <n>" -- <every row and probe of the population, every
variant>` (and
`--deployed-selection <…>` when the harness declares one) in the
background and keep building: it holds one environment, and no
admission, close or claim waits for it. When it ends, record it: `sh
checks/metrics.sh checkpoint --n <n> --to <its receipt>` (a `not-run`
line means the selection left a row or probe of the population out — run
it again with it).
It tests the commit it started on. Its red rows are ordinary red: each
is required at the next close, and rule B holds the steps that build on
it until it is fixed. Never more than two.

**Every test run tests a frozen copy (v0.9.6 3.7, 3.8).** Under
`plan: required`, `sh checks/test.sh request …` freezes what it tests — a full
run HEAD's tree, a scoped run the working tree as it is at the start —
runs it in its own folder and compose project, and keeps its receipt
under a name no later run reuses, at the run's home; an edit made while
it runs never reaches it. When every test environment is busy, `sh
checks/test.sh request …` waits for a free one instead of
being refused — never write a queue script, poll a process list or
parse a refusal. An interrupted run takes its environment down itself.

**Scoped runs, the floor, the engines, the fixtures (v0.9.2 3.7, R16–R18).**
Inside a builder or fix pass the ledger runs SCOPED — `sh checks/test.sh
request --type iterate --role <role> --rows <ROW-id,…> --why "<one line>"
-- <selector>` (v0.9.3 3.10: every run names its role — `--role
builder|fixer|test-author|orchestrator|testenv`; the close run is `--type close --role orchestrator`, a checkpoint `--type checkpoint --role orchestrator`; graders
run no tests: a disputed result goes back to the orchestrator, who re-runs it scoped): the rows under work, their built neighbours (built rows in the same test file,
and the shell), and, when the pass touched the shared
harness, fixtures, schema or authorisation, the alarm set of built rows (the built journeys, shell, reachability rows and materialised hostility probes — §3.2 set 3's definition) — never a row of a step not yet built; what else was checked goes into the close's rows file as a `note` line or as rows with reasons; the close
run (export-backed: HEAD exported, the worktree clean — under a 0.9.6
plan the selected close of Slice close, below; otherwise the whole
ledger, `sh checks/test.sh request --type full --role orchestrator`) is paid ONCE at slice close and again only when the close run was
invalidated (`sh checks/event.sh 'invalidated slice=N report=<its receipt> <why>'` — v0.9.6: a void run is named by its receipt, which then counts for nothing) or a fix landed after it — two
full runs inside one pass without an `incident` or `invalidated` event
trip `cost FLAG full-runs-per-pass` (a close batch's chunks count once). The heartbeat records each run's
selector and report name (`.vid/ledger-results/<sha>.live.sel-<hash>.xml`
for a scoped run, `<sha>.full.xml` for the whole-ledger close, `<sha>.close.xml` for a selected one). **The deployed
shape (v0.9.3 3.3, R4):** when the harness contract declares a
`deployed-selector:`, the close run pays the ledger twice on one export,
each on a fresh stack — inline, then the journey and `(process)` rows in
the deployed profile, the product's declared processes running on the
same image and nothing inline — and `<sha>.deployed.xml` is those rows'
receipt (`ledger-run … kind=deployed`). A builder or fixer chasing a
wiring failure runs `sh checks/test.sh request --type deployed --role
<builder|fixer> --rows <ROW-id,…> --why "<one line>" -- <selector>`: the
live tree in the profile, never certifiable. **Planning prose:** a
surface pass below 20 rows folds into the next slice (R17). **Engines:**
scoped runs use the harness contract's primary engine; the close run
uses the declared matrix. **Fixtures:** the
harness contract states which fixtures are immutable (session-scoped)
and which are mutable (per case, or restored) — the recorded order- and
load-sensitive failures are the cost of not saying; a test that mutates
an immutable fixture is a product question for the harness, not a retry.

**The close's runs (v0.9.6.1 3.2–3.6, R1–R3; steps 2–3 of vid-develop's
"What the close runs").**
2. `sh checks/metrics.sh close-rows --steps <ids>` prints the required
   rows: the steps' own rows, the rows of the steps they build on, the
   alarm set (the journeys, the page frame and navigation, the
   materialised hostility probes), every earlier row not passing on its
   own evidence, and yours — each line with its sets and its `phase=`:
   phase 1 is a row of the closing steps (set 1), a red or stale row (set
   4, never run included) or one of yours (set 5); phase 2 the rest
   (v0.9.7.0.12). Write two
   phase files, one group a line: `<rows> | <inline words> | <deployed
   words>` — the rows whose cases share a selection, in the runner's
   syntax, every variant; a group is never split. Every required row is in
   exactly one group, in its phase's file. When the harness declares
   `deployed-selector:`, a journey or actor `(process)` row's group
   carries deployed words only (it runs once, in the deployed profile),
   and every other group inline words; without it every group is inline.
   ViD never builds or combines the words.
3. `sh checks/test.sh request --type close --role orchestrator --steps
   <ids> --batch --phase1 <file> --phase2 <file> --why "<one line>"` —
   the close batch. At its start it freezes HEAD's tree (one export, so a
   commit meanwhile changes nothing), close-rows and the population run;
   it packs each phase's groups, in order, into chunks of about
   `.vid/budget chunk-seconds` (default 1200) of recorded seconds and runs
   each chunk as a sub-ticket `<ticket>/chunks/<n>` on its own environment
   — while another request waits, it leaves one environment free. Phase 2
   starts only when every phase-1 chunk covers its rows' expected cases
   with no red case. A chunk stopped by its watcher, a signal or a service
   other than the product's processes dying is run once more, alone. One
   `wait` on the ticket: `green`; `red phase <p>, rows …` (fix, request
   again); or `incomplete phase <p>, chunks …` (each chunk's why is under
   the result: a case missing from a group's words, a run that did not
   end). Asked again at the same tree, the chunks that were green with the
   same groups are adopted, not run again. The batch ends with its
   `close-batch` record.

**The last slice close**, or the run before the
completion report, is the whole-ledger run, `sh checks/test.sh request
--type full --role orchestrator --why "<one line>"`, claimed the same way with `--steps` (its `--from` the receipt the previous close's `step-closed` names): anything the lists missed
shows up there.

**Leftovers (v0.9.6 3.10, R10).** An
interrupted test run takes its own environment down. At every slice close
append `sh checks/testenv.sh leftovers` to the slice report (after the
closure), and run it again before the completion report: under a 0.9.6
plan every line it prints is a strict gap, and completion lists each as
`leftover …` — the build is not complete while anything it started still
runs.
