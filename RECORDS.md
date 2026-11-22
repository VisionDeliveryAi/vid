# VID records — the contract a reader relies on

records: 34

This file lists every record a reader outside VID may rely on — a viewer,
a script, a person — with its path, its writer, when it is written, its
fields and, where it has one, its grammar version. The reader reads files
only; it runs no VID command, so nothing here is command output. What is
not listed is VID's own working state and may change without notice.

**The version.** `records: <n>` covers two sets of writers:
- a project's `checks/` — the courts, the hooks and the helpers. Its
  version is `checks/records-version` (a `Purpose:` line, then
  `records: <n>`), copied at init and at every refresh of `checks/`; a
  project without the file predates this contract;
- the plugin's skills and hooks. A verb's version rides its
  `stage … state=start` event as `records=<n>`; a hook's lines carry the
  plugin's version on the session's `vid=` (version 9, below).

After a plugin update without a `checks/` refresh, a project's files can
mix two versions; those two fields say which lines came from which. **The
version rule:** a change to any documented file, field or event raises
`records:`, and the CHANGELOG names it.

**Version 2 (v0.9.6) only adds to 1.** Every file, field and event of 1
keeps its name, place and meaning, and a reader of 1 keeps working; what 2
adds is marked *(2)* below. `records=` on a stage event names the version
of the records THAT verb writes: vid-develop writes `records=10` (from
v0.9.7.0.7; `records=8` from 0.9.7.0.4, `records=7` under 0.9.7.0.3, `records=6` under 0.9.7.0.2, `records=5` under 0.9.7.0.1, `records=4` under 0.9.6.2, `records=3` under 0.9.6.1,
`records=2` under 0.9.6), and
vid-deploy `records=4` (from v0.9.6.2), and vid-fix `records=10` (from
v0.9.7.0.7; `records=8` from 0.9.7.0.5, `records=7` from v0.9.7.0.3, `records=1` before); the other verbs write exactly what
they wrote under 1 and keep `records=1`, which stays true.

**Version 3 (v0.9.6.1) only adds to 2**, the same way: what it adds —
the selected close and the checkpoint, their receipts and `kind=`,
`step-start base=`, `step-closed`, `checkpoint`, `.vid/close/<slice>.rows`
and the close's lines in a slice section — is marked *(3)* below. Under a
develop run, a row's result stands until its own test changes (a changed
line naming the row, or inside the block of a case it ran), it is
amended, or a newer receipt shows it otherwise; a reader that recomputes
row states from receipts orders them by the commit each tested.

**Version 4 (v0.9.6.2) only adds to 3**, the same way: what it adds — the
run id (`.vid/run`, `run=` on a stage start), the session and agent
events, the plan decisions (`.vid/plans/decisions/`, `decision=` on
`plan-change`), the `refused` event and `by=` in `.vid/hook-times`, the
deploy gate events, the export (`.vid/exports/`) and the grade header's
`graded:` and `dirty:` — is marked *(4)* below. **The one change in
place:** `checks/event.sh` now writes at the run's home — the worktree
holding `.vid/RUN-STATE.md`, named by a builder worktree's `.vid/home` —
not in the current directory; a builder worktree's events, which landed
in its own `.vid/` where a reader of the home did not see them, now land
at the home.

**Version 5 (v0.9.7.0.1) only adds to 4**, the same way: what it adds —
the `ledger-run` role values `test-author` and `testenv`, and `role=-` on
a run outside a develop run that names no role; and `checks/plan.sh
home-of`, the one way the home is found, which adds the live run among the
repository's checkouts to the lookup — is marked *(5)* below. A reader of
4 keeps working: `role=` was already an optional field.

**Version 6 (v0.9.7.0.2) only adds to 5**, the same way: what it adds —
every test run inside a develop run is a request with a ticket; the
`ledger-run` request fields (`request=<ticket> type=<type> rows=<n>
estimate=<s> cap=<s> [expect=<s>] [no-history=<n>] [capped=yes]
[outside=<n>] why="<line>"`), `form=legacy` on a plain run outside a
develop run, the `role=orchestrator` value, and the `.vid/requests/`
folder — is marked *(6)* below. A reader of 5 keeps working: every new
field is a key it may skip, and `why="…"` is the last field before
`at=`.

**Version 7 (v0.9.7.0.3) only adds to 6**, the same way: what it adds —
the test analyst's two events, `analyst-due` (written by `checks/test.sh`
at a request's completion) and `analyst-done` (written by the conductor,
vid-develop or vid-fix, when the analyst returns), and the `analyst due`
lines of a request's `result` — is marked *(7)* below. vid-fix now
stamps `records=7`, since it writes `analyst-done`. A reader of 6 keeps
working: two new event types and new lines at the end of `result`.

**Version 8 (v0.9.7.0.4) only adds to 7**, the same way: what it adds —
`verdict`'s optional `scope="<question>"`, `reissued`'s optional
`rounds=<N>`, and the held reasons `scope` and `rounds` — is marked *(8)*
below. vid-fix wrote neither field and stayed at 7 under 0.9.7.0.4;
from v0.9.7.0.5 it writes `records=8` — its graders get the `scope:`
sentence and it follows the shared recording and hold release
(`vid-verify`), so it can write both. A reader of 7 keeps working: both
are optional keys it may skip, and a held reason is a value.

**Version 9 (v0.9.7.0.6) only adds to 8**, the same way: what it adds —
`agent-start`'s `transcript=<the parent session's transcript>` — is marked
*(9)* below. **Hook lines and verb lines are told apart.** A stage
event's `records=` names what that verb's own text writes; lines written
by the plugin's hooks (`session`, `agent-start`, `agent-stop`, `died`)
carry the plugin's version on the session's `vid=`, and a reader takes an
optional field by its presence, as every version only adds. So no verb's
stamp changes: vid-develop and vid-fix both stay at `records=8`, since
neither writes the field itself; a project's `checks/` is 9, the version
develop's start requires, since it needs the observer that reads it. A
reader of 8 keeps working: one more field, taken by key.

**Version 10 (v0.9.7.0.7) only adds to 9**, the same way: what it adds —
the `build-cost` event, the hand-back file `.vid/briefs/<N>/<role>-<n>.return.md`
and `.vid/budget`'s `builder-context-tokens` — is marked *(10)* below.
vid-develop and vid-fix both write `records=10` and stop on a `checks/`
below 10: their builders and fixers hand back through `sh checks/brief.sh
return`, which writes the event. The context net's once-only marker,
`.vid/net.<agent id>`, is the plugin's hook's file, as version 9's debt
is. A reader of 9
keeps working: one more event type and one more file, both optional.

**Version 11 (v0.9.7.0.8) only adds to 10**, the same way: what it adds —
a queued request's `holders` file and the `slot-reclaimed` event — is
marked *(11)* below. Both are `checks/test.sh`'s own, so no verb's stamp changes: vid-develop and vid-fix
both stay at `records=10` and stop on a `checks/` below 10. A reader of 10
keeps working: one more file in a request's folder and one more event
type.

**Version 12 (v0.9.7.0.9)** changes the watcher's records; what it adds or
changes is marked *(12)* below. It adds `.vid/observer.pid`,
`.vid/observer.log`, `.vid/observer.lock` and `.vid/observer.start` (the
watcher loop develop starts, and the tick's lock); `.vid/observer.state`
carries `tick <epoch> <home>` and the loop's `loop <token> <home>`, and no
longer a `notifier` line; the observer's notices are heartbeat lines
`observe: notice — <text>` in place of `notify — …`, since nothing is sent;
and `.vid/budget` loses `progress-notify`. vid-develop writes `records=12`
and stops on a `checks/` below 12: it calls `sh checks/observe.sh start`
and `sh checks/test.sh analyst-due`, which only a 12 `checks/` has.
vid-fix calls neither and stays at `records=10`, stopping below 10 — the
minimum follows each verb's own writers and readers. A reader of 11 keeps
working: a notice line is an `observe:` line, a missing key is a key it
skips, and nothing it read is moved.

**Version 13 (v0.9.7.0.10)** changes when a request's run writes and
what it records; what it adds or changes is marked *(13)* below. Inside a
develop run a pass is published before its teardown, so a `ledger-run`
event's `seconds=` no longer holds the teardown; each teardown is its own
`teardown` event, a failed one `teardown-failed`; a request's `result`,
`exit` and final `state` are written when its last pass is published,
while its run folder and slot are still held (the ticket's `run` names
the folder). Each pass published inside a develop run adds `overhead=`;
the ticket's `request` adds `teardown=`; a request whose inline pass
spent over 120 s outside its cases keeps its test environment's
`timeline.log` in the ticket, and nothing becomes due for it.
`.vid/budget`'s proof becomes `testenv=proved harness=<hash>`: a bare
`testenv=proved` reads as proved on no known harness, so admission uses
one environment until the test-environments pass proves again. The
harness upgrade's states are `harness-upgrade` events. vid-develop writes
`records=13` and stops below 13: it calls `checks/harness.sh rules`,
which an older `harness.sh` ignores, passing silently. vid-fix calls
nothing new and stays at `records=10`, stopping below 10. A reader of 12
keeps working: three more event types, one more field taken by key, a
proof line read by its prefix, and a `ledger-run` without
`teardown=failed` inside a develop run — a reader that summed `seconds=`
as the run's whole time adds the `teardown` events' seconds.

**Version 14 (v0.9.7.0.11)** changes what a request's reports credit and
what a run keeps; what it adds or changes is marked *(14)* below. A
request's report carries `<report>.rows`, the rows the request was
frozen with, and credits only those (`sh checks/evidence.sh credit`); a
report reaching rows outside them is kept, its `ledger-run` carrying
`outside=<n>` and its result `outside n=<n> rows=<…> — not credited`. A
run whose stack loses a service while the tests run is stopped:
`ledger-run … report=none status=130 … stopped=service:<name>`, the
ticket's `stopped` and the result's first line naming the cause. Each
pass keeps the ticket's `services.<pass>.txt` and `timeline.<pass>.log`
(the latter replacing 13's `timeline.log` and its threshold). The harness
gains rule 4: `x-vid-harness`'s `case-limit: <seconds>` and `rules: 2`.
`harness-upgrade` events carry `target=<n>` (none reads as 1);
`analyst-done` may carry `owner=no`; a `.vid/hook-times` line written
from another checkout lands at the run's home with `checkout=<name>`.
vid-develop writes `records=14` and stops below 14: its upgrade step
reads `harness.sh rules`' targets and `rules: 2`. vid-fix stays at
`records=10`. A reader of 13 keeps working: new fields taken by key, new
files beside the old, and an outside report that is now kept — a reader
crediting a report's rows reads its `.rows` first.

**Version 15 (v0.9.7.0.12)** adds the close batch; what it adds or
changes is marked *(15)* below. A close is one request with `batch=yes`:
its ticket keeps the groups it was asked with, the `batch` record, the
`frozen` inputs, the `layout` of its chunks and the `receipts` they
published; each chunk is a sub-ticket `<ticket>/chunks/<n>/` with its own
control files, and its retry `<n>-retry`. A chunk's run writes
`request=<ticket>/<n>` and `batch=<ticket>` in its `ledger-run`, and its
analyst dues are keyed `request=<ticket>/<n>`. The batch ends with a
`close-batch` event; the claim by batch writes `step-closed … batch=`.
`close-rows` prints each row's `sets=` and `phase=`; `.vid/budget` may
carry `chunk-seconds`. A checkpoint's receipt carries its population in
its `.rows`, and checkpoint 2 is due at two thirds whatever checkpoint 1
found. vid-develop writes `records=15` and stops below 15: its close
writes groups and claims by batch. vid-fix stays at `records=10`. A
reader of 14 keeps working: a new event type, new fields taken by key, a
ticket folder holding sub-tickets, and `required` lines whose `set=`
became `sets=`.

**Version 16 (v0.9.7.1)** adds agent cost; what it adds or changes is
marked *(16)* below. A builder's or fixer's brief carries its attempt id
(`try:`), its branch and its return path; `try=` rides its tickets, their
`ledger-run` events and its job. A ticket may end `cancelled` (its
`cancel` mark, `pid-start` beside `pid`; `wait` exits 77). New files: a
continuation package `.vid/continuations/<step>/<try>/`, a Codex builder's
job record `.vid/jobs/<try>` with its `.events`, `.final`, `.err` and
worktree `<try>.wt`, and an agent's detailed report
`.vid/briefs/<N>/<role>-<n>.report.md` beside its return. `.vid/budget`
may carry `builder-tool=`, `codex-model=` and `codex-effort=`. New events
are below; `build-cost` gains `tool=`, `model=`, `effort=` and
`brief-bytes=` and is written for every role, and `brief-written` records
each brief's size. vid-develop and vid-fix write `records=16` and stop
below 16: they spawn by agent type, pass the selection, and hand back
through `return --agent`. A reader of 15 keeps working: new event types,
new fields taken by key, new files beside the old, one more terminal
ticket state.

**Version 17 (v0.9.7.2)** adds breadth first, the owner's strategy; what
it adds or changes is marked *(17)* below. RUN-STATE may carry
`strategy:`; a plan step line may end `| kind: hardening`, and the plan
block may carry one `protected:` line. A plan change may be `what=edge`
and carry `not-needed-by=`; a strategy decision is kept beside the plan
decisions. `.vid/budget` may carry `builders-target=`. New events:
`strategy`, `step-done` (a stamp), `step-rows-passing`, `deferred` and
`deferred-resolved`; `refused` gains `by=graded`. The progress table's
"Done" row is named "Passing" and gains the Debt and Builders-at-once rows
(and three shown only when they apply). vid-develop and vid-fix write
`records=17` and stop below 17. A reader of 16 keeps working: new event
types, new fields taken by key, a new last column in the plan's parsed step
lines; RUN-STATE without `strategy:` is depth first, as before.

**Version 18 (v0.9.7.3)** adds agent cost, part 2; what it adds or changes
is marked *(18)* below. A DECISIONS.md line may carry a label after its
`enforced:` field — `| applies-to: <ids and codes>` or `| scope: project`
— and the commit hook refuses a new or changed line with neither (a line
changed only in its label is judged by that rule alone). New files: the
labelling pass's `.vid/briefs/labels-<n>.md` and
`.vid/decision-labels.proposed`; a refused commit's
`.vid/refusals/<attempt>/`; the self-test certificate,
`<git common dir>/vid-selftest/<key>`, shared by every checkout (it
replaces `<git dir>/vid-memo/selftest`; not written from 0.26.10.12.1). New events: `decision-labels`
and `court-refused`; `refused` gains `by=decisions-label`. New lines in a
request's `result`: `retry: --expect <s>` and `build failed: no test ran —
…`. The progress table gains a Refused commits row and
`builders <n>` per tool. vid-develop and vid-fix write `records=18` and
stop below 18. A reader of 17 keeps working: new event types, new fields
taken by key, new files beside the old.

**Version 19 (v0.9.7.4)** adds the delegated mark; what it adds is marked
*(19)* below. New event: `delegated`, written by `sh checks/metrics.sh
delegated --answer <A-id>` for an answer VID wrote under the owner's
delegation. The project viewer (`/vid view`) writes only its own files,
outside the project (below, "The viewer's own files"); they are not
project records. vid-develop and vid-fix write `records=19` and stop below
19. A reader of 18 keeps working: one new event type.

**Version 20 (v0.9.8)** adds test writing as a job; what it adds or
changes is marked *(20)* below. New events: `test-proven` (the proof's
attestation, or `result=inconclusive`) and `authority-kept`;
`amended` gains `by=obligation|fail-if`, `ledger-run` gains
`purpose=proof`, a `verdict` from a failed proof gains `proof=<receipt>`.
A receipt of a proof request is named `.proof.` where an
ordinary scoped one is `.live.`, its `.tree` carrying `purpose=proof`: it is
no ordinary receipt and nothing credits it. New files: `.vid/test-lessons.md`;
a grader's patches, `.vid/briefs/<N>/grader-<n>.faults/`.
In a ticket's `services.<pass>.txt`, `ready-at=` is renamed
`kept-healthy-at=` (R17). The host's admission lock, `vid-host/admit.lock`,
is a symbolic link whose target text is `<pid> <start time>`; an older VID's
was a directory (R16). The progress table
gains a Test state row. vid-develop and vid-fix write `records=20` and stop
below 20. A reader of 19 keeps working: new event types, new fields taken by
key, new files beside the old — and a `.proof.` receipt, read by name as a
scoped one, is the only record a reader of 19 could mistake: it names no
ordinary result.

Version 21 (VID 0.9.8.1, small fixes) only adds to 20. New events:
`selftest-retried` (a listed flaky case's one retry) and `agent-brief` (each
agent's brief at its first tool call, once: `.vid/agents/<id>.brief`).
`build-cost` and `agent-returned` gain `agent=`; `build-cost`'s `brief=` is
written relative to the home (an older absolute value is still read, up to
the next field); a cost with no transcript may carry the caller's total,
`source=agent-tool`. A red pass keeps `timeline.<pass>.log.gz`, its whole
log. A design pack may carry `design/screens/index.json` declaring `layout:
per-screen`. A ticket cancelled by its id (`cancel --ticket`) may carry an
empty `try=` on `ticket-cancelled`. A resume's re-entry page writes
`.vid/reentry-shown.<session>` and no re-read debt; only a compaction writes
the debt. vid-develop and vid-fix write `records=21` and stop below 21.
A reader of 20 keeps working: new event types, new fields taken by key, new
files beside the old; a relative `brief=` reads as the path it is.

Version 22 (VID 0.26.10.2, the viewer's architecture view) only adds to 21.
A decision's `applies-to:` label may name module ids of ARCHITECTURE.md's
module table (its Module column, a dotted label read as a path), beside its
row, requirement or screen items; the commit hook accepts them. An
INVENTORY.md `seam` row may carry `module: <module id>`, read by label.
Both are optional to write. A checks/ of 21 refuses a module item, so
vid-develop and vid-fix write `records=22` and stop below 22, and a
project's checks/ is refreshed before its builders write one. A reader of
21 keeps working: a label item and a seam field are taken by name.

Version 23 (ViD 0.26.10.3, amendments that don't wipe) only adds to 22.
A new event, `law-changed row= sha= item=`: post-commit writes it, in place
of `amended … by=fail-if`, for a row present at both commits whose own
obligation did not change but an item it derives from changed its
effective fail-if; such a row is **to confirm** (Readings, below) and keeps
its verdicts, attempts, holds, allowances and evidence. Post-commit's row
sets are `sh checks/inventory.sh impact`'s (`--detail`), the calculation
the owner's questions quote. From 23 post-commit writes `amended` only
`by=obligation`; an `amended … by=fail-if` already written keeps its
meaning: every reader still wipes on any `amended`. A new event,
`vid-finding`, beside a new file, `.vid/VID-FINDINGS.md` (ViD's own defect
log, from `templates/VID-FINDINGS.md`). The observer keeps
`.vid/observer.passing` and `.vid/observer.drop` and writes the drop
notice (`.vid/HEARTBEAT.md`). The progress table's Estimate leaves out the
rows to re-run and says so. A checks/ of 22 wipes where 23 puts a row to
confirm, and lacks `metrics.sh to-confirm` and `inventory.sh impact`, so
vid-develop and vid-fix write `records=23` and stop below 23. A reader of
22 keeps working: new event types and new files beside the old; a row a
reader of 22 counts as unchanged may be to confirm, which only completion
reads.

Version 24 (ViD 0.26.10.4, a test run stopped on silence) only adds to 23,
apart from what a run stopped by its watcher writes. A request's watcher
stops it on silence (no new output for `silence-minutes`, 20), a pass's
start-up past `startup-minutes` (60), or `run-limit-minutes` (1440) awake
— three new `.vid/budget` keys; the estimate stops nothing. The names stay:
`state` `capped`, `cap-hit`, `capped=yes`. `cap-hit` holds `reason=`,
`pass=`, `last-output=` and `at=` lines (before 24 a UTC time alone); the
result's first line says why; the capped `ledger-run` adds
`stop=silent|startup|limit`; `analyst-due … reason=cap` adds `stop=` and
`last-output=`; a request and its events carry `silence=`, `startup=` and
`limit=` in place of `cap=`, and the request's estimate start-up term moves
from `startup=` to `estimate-startup=`. New ticket files: `watch` (the
watcher's counts), `pass`, `compose.inline.err`, `svcout.<pass>`, and
`tests-at.<pass>` in place of `tests-at`. No longer written: `slept`,
`slept=`, `host slept …`, `retry: --expect …`; older tickets keep them and
are read as written. A new file, `.vid/decision-ids`, holds D-number
reservations (`checks/decisions.sh next`). vid-develop and vid-fix write
`records=24` and stop below 24: their agents reserve D-numbers through a
`next` a checks/ of 23 lacks, and a checks/ of 23 still stops runs at twice
their estimate. A reader of 23 keeps working: `capped` reads as before,
new keys are taken by name, new files sit beside the old; a reader of a
request's `startup=` reads the start-up limit from 24 on.

Version 25 (ViD 0.26.10.5, staged delivery) only adds to 24. A new law
file, `STAGES.md` at the project root (from `templates/STAGES.md`), the
stage cut: the cards, and its ```` ```vid-stages ```` block — the region
`checks/lawfiles` names (`STAGES.md vid-stages`). New events `stage-cut`,
`stage-closed`, `pull-forward` and `stage-deploy`; RUN-STATE's `stage:`;
a `## stage N <UTC>` section of `.vid/SLICE-REPORTS.md`; a request's
`stage=` (`--stage N`); the annotated tags `vid/stage-N`; `refused … by=`
gains `stages` (commit-msg), `stages` among the pre-commit courts, and
`stage` (admission). A project without STAGES.md writes none of them.
vid-develop and vid-fix write `records=25` and still stop below 24 — a
project without STAGES.md is unchanged by 25 — and a project holding
STAGES.md whose checks/ is below 25 stops: its stage court, `stages.sh`
and `metrics.sh stage-close` are 25's. A reader of 24 keeps working: new
event types, a new key and a new file beside the old.

Version 26 (ViD 0.26.10.6, the viewer's execution and economics) only
adds to 25. One new event, `usage`: each agent's, each Codex job's and
each run-manager window's tokens in four kinds that never overlap (fresh
input, cache read, cache write, output) with its model, so totals are
comparable and priceable. It is written by the plugin's
`hooks/record.sh` at SubagentStop (after `agent-stop`), by
`checks/job.sh run` (beside `job-exit`) and by `checks/brief.sh return`
(beside `manager-cost`). Nothing reads it but the viewer. vid-develop and
vid-fix write `records=26` and still stop below 24: no floor rises, and a
project without it reads "not recorded in kinds". A reader of 25 keeps
working: a new event type beside the old.

Version 27 (ViD 0.26.10.7, deploy to staging and deploy to production)
only adds to 26. New events `deploy-check` (`checks/metrics.sh
deploy-check --record`, one per target) and `stage-hold` (the owner's hold
after a stage: `checks/stages.sh hold`, and the stage close turning it
on); `stage-deploy` is now written by each target. A request's `--type
staging` (its `ledger-run` carries `type=staging`), and a request's home
outside develop's gate: whenever `checks/plan.sh home-of` resolves, a
request's ticket, its receipts (frozen, with `.tree` and `.cases`, named by
run id) and its events are at the home. The annotated tags
`vid/stage-N.k`; RUN-STATE's `run: stopped owner asked to hold after
stage N`; the `## deploy` section's first line. vid-develop and vid-fix
write `records=27` and still stop below 24 (25 with STAGES.md); vid-deploy
writes `records=27` and stops below 27 — its checks are 27's. A reader of
26 keeps working: new event types, a new value and new tags beside the old.

Version 28 (ViD 0.26.10.8, release B: stage 0, the standing staging
authorization, staging at each close, the viewer's stages) only adds to 27.
STAGES.md's `STAGE-0 | <name> | technical` line (stage 0, fed by `row:`
lines only; added or removed only by the commit creating STAGES.md);
ARCHITECTURE.md's ```` ```vid-hosting ```` block (where the product runs,
access recorded by shape only — `cli-login <platform>`, `env <NAME>` or
`none` — refused otherwise by pre-commit, `by=hosting-access`); RUN-STATE's
`stage: 0`; the event `staging-auth` (`checks/stages.sh staging-auth
on|off`); `stage-deploy`'s `staging=failed`, `by=` and `why=`; `stage-closed`
written for the final stage too, tagged `vid/stage-k`, with no next stage;
`stages.sh deploy --by develop`, `candidate --by develop` and `metrics.sh
deploy-check --by develop`; the setup hold — `stage-hold … words="staging
setup"`, RUN-STATE's `run: stopped staging setup after stage N` and its
release `stages.sh hold --off --setup`; a request's `--stage 0`. vid-develop
and vid-fix write `records=28`; their floors are unchanged (24; 25 with
STAGES.md) but for a project whose STAGES.md holds STAGE-0, which stops
develop below 28; vid-deploy and vid-stage write `records=28`, and vid-deploy
stops below 28. A reader of 27 keeps working: a new event type, new values
and keys, a new block beside the old. The viewer's contract moves to
`viewer-data 4` (adds `stages`).

Version 29 (ViD 0.26.10.9, the ticket planner with spec-only init) only adds
to 28. Init makes the spec only: its end event carries `made=spec`;
INVENTORY.md's owed class `spec-only` (details `first stage` and `ticket`);
the code skeleton's `skeleton` events, `checks/plan.sh skeleton` and
RUN-STATE's `plan: skeleton` (the gate off). Ticket mode: RUN-STATE's `mode:
tickets`; the stage names `plan` and `replan` (`replan`: old ticket mode, removed in 0.26.10.28.1; the gate on under them, and
admission reading ticket grades); ARCHITECTURE.md's ```` ```vid-code ````
block; ANSWERERS.md; `.vid/code/` (the read-only copy, not a record),
`.vid/tickets/` (`map`, `state`, `PLAN.md`, `pr-<n>/`, `commit-<sha>/`),
`.vid/replans/<round>.md` (these two: old ticket mode, removed in 0.26.10.28.1), `.vid/pages/`; CI receipts `<code
sha>.ci-<run>-<attempt>.xml` with `.cases` and `.rows` (no `.tree`) and
`ledger-run … type=ci`; the events `ticket`, `milestone`,
`publish-approved`, `copy-check`, `skeleton`, `red-observed`'s ticket-mode
form, `question … to=`, `stage-closed … source=ci`; a brief's `ticket:`,
`base:` and `return: pull request` and its `## 16 ticket`; the `vid-ticket`
part header and the `vid-return 1` block; the skeleton contract's artifact
name `vid-junit-<run attempt>`; `metrics.sh stage-close --ci`; outside ViD's
records, in the stand-in's clone, `.git/vid/` and the `Stand-in:` commit
trailer. vid-init, vid-develop, vid-plan and vid-replan (old ticket mode, removed in 0.26.10.28.1) write `records=29`;
develop stops below 29 only for a `made=spec` or adopted project (R5); the
other verbs keep what they write. A reader of 28 keeps working: new event
types, values, keys, blocks and files beside the old. The viewer's contract
stays `viewer-data 4` (a spec-only init's milestone reads "Spec ratified",
its kind `setup-done`).

Version 30 (ViD 0.26.10.11, the /vid add refresh) only adds to 29. vid-add's
start event carries `base=<HEAD, 12 hex>` and `records=30`; vid-develop's
completion grade reads it: while one or more `stage name=add state=start`
events come after the newest `completion unmet=0 strict-gaps=0`, it grades
the requirements those adds' appends add or amend and those of the modules
changed since the earliest such add's `base=`, with their declared
dependents. vid-add writes RUN-STATE's `stage:` when it opens a new final
stage after the final close. The other verbs keep what they write. A
reader of 29 keeps working: a new key on an existing event.

Version 31 (ViD 0.26.10.12, ticket-mode CI scope) only adds to 30.
ARCHITECTURE.md's vid-code block gains `run-full: <how the full run is
started>`, written by vid-replan from the skeleton's block (old ticket mode, removed in 0.26.10.28.1); the skeleton
ticket's return block gains `skeleton: run-full:`, required only of a
skeleton ticket that asks for it. A feature or fix ticket's section 16
gains `### CI scope` and its return block `ci-scope:`. The event
`run-full started` (`checks/github.sh run-full` (old ticket mode, removed in 0.26.10.28.1)); with `run-full:`, `ticket.sh
import --main` and `metrics.sh stage-close --ci` read only a run such an
event names. Without `run-full:` a project keeps
0.26.10.11's behaviour. The verbs keep what they write. A reader of 30
keeps working: a new key in a block, a new line in another.

Version 32 (ViD 0.26.10.24, the add guards) only adds to 31. The events
`step-resumed` and `overrun`; `refused phase=pre-commit by=no-plan-step`,
from `checks/plan.sh guard --paths -` (pre-commit rule 4e); `checks/plan.sh
run-start`, the place of the run's start; `checks/observe.sh notices`; two
`observe: notice — <text>` lines, the hand-back's (key `handback.<cksum>`)
and the overrun's (key `overrun.<ticket>`); a `| Notices |` first row in the
progress table. vid-add stops below 32. A reader of 31 keeps working: new
event types, a new `by=` value, new notice lines, a new table row.

Version 33 (ViD 0.26.10.27.4, the ticket flow's files and fields) only adds
to 32: no file or field of 32 changes meaning. The Files section gains "The
ticket flow's files" — `.vid/tw/`, `.vid/decide/`, `.vid/results/`,
`.vid/round/` (local scratch, never saved), `.vid/plan/`, `.vid/code`,
`.vid/pages/`, `.vid/state-at` and `.vid/lock-session`, which the rebuilt
ticket flow writes and no version listed; the first mode's section keeps only
what is that mode's alone. The Events table lists the fields every writer
writes: the `ticket` event's asks (`kind=deploy|grade|close
state=asked`, `stage=`), `run … by=owner`, `progress … mode=tickets`, and
the ticket-flow events' fields their rows left out; a field no writer writes
is marked *(not written from <version>)*. `checks/selftest/cases/records-drift.sh`
now checks both ways, names and fields. The readers' gates stay below 32.
A reader of 32 keeps working: what 33 adds is documentation of lines
already written.

## The pages: work in progress, not records *(usability)*

`checks/pages.sh` makes a readable page of each document the owner is
asked to read, and writes only `.vid/pages/` and `.vid/pagelinks`, only
where `.vid/` exists. Nothing in ViD reads them back to decide anything:
the documents stay the only truth, and a page lost is made again by one
call.

- `.vid/pages/<NAME>.md` and `.vid/pages/<NAME>.html` — a page's
  markdown and its rendering by `checks/page.sh`: `PRD`, `FOUNDATION`,
  `FINDINGS`, `TESTS`, `CUTS` (the cuts to choose from, read from the
  rungs' scratch folders), `STAGES` (the committed cut), `BOOK` (the
  product book: the pages as its chapters, made again by every `all` and
  `for <stop>`, its waiting note and marks read from `face.sh waiting`
  when it is made, never kept), and the plan's `PLAN-PAGE.html` (made by `planner.sh page`,
  only indexed here). Never saved to the state repository, as the rest
  of `.vid/pages/`.
- `.vid/pages/index` — one line a page that exists, five fields
  separated by tabs: the page's id (`prd`, `foundation`, `findings`,
  `tests`, `cuts`, `stages`, `plan`, `book`), its title (no tab), the
  html file's full path, its link or `-`, and the stops it is due at as
  numbers separated by commas, or `-`. Written whole, by rename, at every
  call; a page whose file is gone is left out. The cuts' line leaves only
  when `pages.sh stages` is called by name (the pick; with no STAGES.md,
  the project keeps one stage) or when `pages.sh cuts` writes a new one;
  `for <stop>` and `all` never take it out. The panel reads it.
- `.vid/pagelinks` — outside the pages folder, so emptying it loses
  neither: `publish<TAB>yes|no<TAB><the owner's own words><TAB><UTC time>`,
  the owner's one answer on publishing (the latest replaces the earlier),
  and `link<TAB><page id><TAB><address>`, each page's private claude.ai
  link (an address starting `https://claude.ai/`). This checkout's own:
  not saved to the state repository, so after a restore ViD asks again.

## The viewer's own files *(19)*

`/vid view` (the plugin's `viewer/view.sh`) reads the project's documents
in git and the records above, and writes only into its own folder, outside
the project (`--out <dir>`, else `~/ViD Viewer/<project folder name>/`):
`index.html`, one `<UTC>-<milestone>.html` per snapshot, `now.html`, and
`.cache/`. They are the viewer's, not project records: nothing in VID
reads them, and their shape is the viewer's data contract,
`viewer/DATA.md` (`viewer-data 1`), not this file's version.

## ViD's face: work in progress, not records *(0.26.10.29)*

`checks/face.sh` writes two files for the panel in the Claude desktop app,
`.vid/face/sitting.json` and `.vid/face/standing.json`, and only where
`.vid/` exists. They are work in progress, not records: the PRD and its
answer ledger stay the only truth, nothing in ViD reads them back, and a
file lost is rewritten at the next sitting. The sitting is what ViD
presents at one of the four PRD sittings (`format`, `sitting`, `stop`,
`session`, `written`, `state` waiting or ended, `ended`, and `sections`,
each `id`, `kind`, `title`, `source`, `empty`, `why`, `acts`, `items`);
the standing is the nine stops (`format`, `written`, `current`, `turn`
person or vid, `sitting`, `session`, `next`, `stops`). Both are written
whole, by rename. Their shape is face.sh's head, not this file's version.

*(usability, release A)* Both now say `format` 2. Each item of a sitting
also carries `preset` (the answer it starts at: `choose:<choice>`,
`<act>` or `<act>:<words>`, or empty), `presetBy` (`vid` for ViD's
recommendation for that item, `standing` for its section's standing act,
or empty), `alone` (asked on its own, never part of a bulk answer) and
`norecommend` (ViD said it has none). A section may be of a seventh kind,
`alone`; each pause ends with one, the checks ViD's draft would remove,
filled from what `prd.sh --pause` prints under "owner questions". A
sitting may stand at any stop from 2 to 9; a stop's `sitting` in the
standing is true where face.sh's table holds one for it, and only the four
PRD sittings close their stop when they end. The standing also carries
`wait`: the parts of the wait now running (`parts`, each `name` and
`state` done, now or to come) and `now`, what ViD is doing, from
`.vid/face/wait` (`part`, `at` and `now` lines, tab-separated), which
`sh checks/face.sh wait …` writes and a sitting written or ended clears.
`.vid/face/run.<session id>` is one line, `<running|stopped> <since,
UTC> <last step, UTC|->`: the plugin's `hooks/face-standing.sh` writes it
at a prompt, after a step, at Stop and at StopFailure (by rename), and
the panel module's recorder writes it stopped at the end of every turn,
an interrupted one too. Every run of the standing removes `.standing.*`
files older than a minute and `run.*` files older than seven days. These
too are work in progress, not records.

*(usability, release C)* A sitting also carries `ready`, its short phrase
for when it waits, and its `state` may be `drafting` (written by
`sh checks/face.sh draft`: only the session's sections given, never the
person's turn, no marks kept); an item also carries `about`, the
`<section>/<item>` a finding is about, or empty. When a sitting ends,
face.sh appends `<stop><TAB><title>: <n> items, agreed <day> <month>` to
`.vid/face/agreed`; each stop of the standing carries `agreed`, its latest
line while the stop is done (`Done` with none), empty while it is not.

*(usability, release B)* The standing also carries `pages`, one entry a
line of `.vid/pages/index` (the pages section), in order: `id`, `title`,
`file`, `link` (empty for none) and `stops` (numbers). Where
`checks/pages.sh` is beside face.sh, writing or ending a sitting runs
`pages.sh for <its stop>` once the sitting is in place, then recomputes
the standing; a failure of that script leaves the sitting as written.
`sh checks/face.sh waiting` prints the sitting that waits, for the book:
`<name><TAB><stop><TAB><title>`, then `<item id><TAB><its words>` a line.

*(0.26.10.29.6, the pauses)* face.sh's table also holds the eleven
sittings of stops 6 to 9 (`technical`, `design-who`, `design-gaps`,
`design-lines`, `design-approval`, `tests`, `tests-review`,
`consolidation`, `settings`, `stages`, `stages-own`), none closing its
stop. An item may also carry `look`, why ViD points to it (`An open
finding`, `Shapes a rule that must never break` or `No recommendation`),
or empty; the pointed items come first in their section. Pauses 2 and 3
carry a section `changed`, of kind decided: each line of the PRD's thesis
and mechanisms that differs from the commit named by the last line under
`## Ratifications`, the line as it is now with the line as it was as its
detail. Stop 7 of the standing is done, after the latest `stage
name=design … state=start` event, only at that verb's `state=end` (with no
design event, when `design/` exists, as before). Where the map, as the standing
shows it, stands past a sitting's stop, `face.sh write` and `draft` write
nothing and exit 0; `face.sh end` of a sitting not on disk, or at a stop
the map has left, says so and exits 0; both leave the files as they are. Still no format change: both files say `format` 2.

## Reading rules

- **Time.** Every line appended to `.vid/metrics-events` ends
  ` at=<UTC>`, in the form `YYYY-MM-DDTHH:MM:SSZ`. Take a line's **last**
  `at=` token, and only in that exact form: free text inside an event may
  contain the string. A line without one is untimed (written before
  0.9.5, or by a writer that skipped the helper) and stays readable.
- **Order.** Order lines by that time, file order breaking a tie; never by
  position alone.
- **Fields.** An event line is `<type> <field>=<value> …`; pick fields by
  key, never by position — a later version may add fields.
- **Latest wins.** In `PRD.md` and `INVENTORY.md` a later row with the same
  id supersedes an earlier one (`<id> AMENDED` restates the whole row).
- **Commits.** Commit shas are 12 hex characters in events and receipt
  names.

## Files

| path | writer | when | what a reader takes from it |
|---|---|---|---|
| `PRD.md` | vid-create-prd (creation, three ratification commits); the append doors — vid-add, vid-fix, vid-design's dual-write, vid-develop's two-channel appends; every sitting's rulings, creation's and the doors', written through `checks/prd-apply.sh` (FB-1 A2); `checks/prd-consolidate.sh` | at those commits | the product's items, features and decisions (below) |
| `INVENTORY.md` | vid-test-inventory; row changes are standalone commits | at init and at every re-derivation | the rows that will be verified, with their `kind` |
| `DESIGN-BRIEF.md` | vid-design | at the brief and at import | the manifest: marker → REQ map |
| `STAGES.md` *(25)* | vid-stage (the ratification), vid-add and vid-fix (a new feature's placement); every change to its ```` ```vid-stages ```` block a standalone law commit citing the owner's answer | at the stage sitting, a re-cut, a new feature's placement | the stage cut: which stage each feature, requirement and row is in (`sh checks/stages.sh scope`, `stage-of`) |
| `.vid/SLICE-REPORTS.md` | vid-develop at every slice close; vid-fix and vid-deploy at their final report | appended | VID's computed progress at each report; *(19)* the project viewer does not read it — it computes each moment's row states with the plugin's own evidence reader |
| `.vid/metrics-events` | the courts, hooks and helpers of `checks/`, and the skills through `checks/event.sh`; *(4)* the plugin's `hooks/record.sh` | appended, one line per event; *(4)* `checks/event.sh` appends at the run's home | the run's history (Events, below) |
| `.vid/briefs/<N>/<role>-<n>.return.md` *(10)* | vid-develop's or vid-fix's session (the run manager), from a builder's or fixer's report; *(16)* the agent itself, at the path its brief's `return:` gives (written `.tmp`, then renamed) | when the agent returns, before the run manager acts on it | the hand-back block: `brief:`, `agent:` (added by the run manager — *(16)* by `sh checks/brief.sh return <file> --agent <id\|codex:<try>>`), `branch:`, `commit:`, then one line per row of the brief, `ROW-… \| pass \| <receipt>` or `ROW-… \| not \| <receipt or none> \| <reason and evidence>`; checked by `sh checks/brief.sh return`, which writes `build-cost` |
| `.vid/briefs/<N>/<role>-<n>.report.md` *(16)* | the agent | beside its return, when it has more to say than the return's lines | free text: the detail a `not` reason may point at ("see the report"); `return` refuses such a reason when this file is missing; *(18)* one written in the worktree of the return's branch, at the same path, is copied here by `return` |
| `.vid/briefs/labels-<n>.md` *(18)* | `sh checks/decisions.sh propose [--all]` | once per labelling pass (at init, step 7; once for an existing project) | the labeller's brief: the unlabelled decisions (`--all`: every one; else those citing no ROW, REQ or RULE id), each `D-NNN <text hash> \| <the line>`, the items a label may name and the return form |
| `.vid/decision-labels.proposed` *(18)* | the run manager, from the labeller's return, unchanged | after the labeller returns | one line per decision, `D-NNN <hash> \| applies-to: <items> \| sure\|unsure` or `… \| scope: project \| …`; read by `decisions.sh apply` — a label is written only where the decision's text hash still matches |
| `.vid/decision-labels.applied` *(18)* | `checks/decisions.sh apply` | appended at each labelling pass | one line per label written, `D-NNN<TAB><label><TAB>sure` or `…<TAB>widened: <why>` — a label the labeller was unsure of, a malformed proposal, or one naming an item no brief joins on, written `scope: project` instead |
| `.vid/decision-ids` *(24)* | `checks/decisions.sh next` (an agent with `--try <try>`, a run manager without) | appended at each reservation, under the home's lock `.vid/decision-ids.lock`; at the run's home | one line per D-number reserved, `D-NNN<TAB><try\|manager><TAB><UTC>` — above every D-number in the caller's HEAD, the home's checked-out HEAD and every earlier reservation; a reserved number never used is a gap |
| `.vid/refusals/<attempt>/` *(18)* | `checks/hooks/pre-commit`, at the run's home (a builder's worktree's refusal too) | one folder per refused commit attempt, before the hook's cleanup; kept | `meta` (`tree=` the index's tree, `head=`, then a `court=<name> rule=<rule\|-> subject=<subject\|->` line per refusing court — rule and subject from census's `FAIL  <rule>  <subject>` and inventory's `GAP  <subject>` lines, else `-`), and each refusing court's `<court>.out` and `.err`; a refusal before the courts keeps only its meta |
| `<git common dir>/vid-selftest/<key>` *(18; not written from 0.26.10.12.1: a project's law commit runs only its own cases, F-108; older ones are left as data and nothing reads them)* | `checks/hooks/pre-commit` | after a law commit's complete self-test pass, while the key's inputs and every file under `checks/` still equal what was judged; written privately, then renamed | `pass <key>` — the self-test certificate, shared by every checkout of the repository; the key is 0.9.5's memo key; anything else in the file is a miss |
| `.vid/continuations/<step>/<try>/` *(16)* | `sh checks/brief.sh save` (the builder, the run manager, or `checks/job.sh`) | when a builder or fixer stops with unfinished work; published atomically; kept until a later return's commit contains it or `continuation-superseded` | `manifest` (`schema=`, `run=`, `step=`, `try=`, `role=`, `brief=`, `brief-hash=`, `quoted-at=`, `head=`, `landed=<commits past quoted-at>`, `report=`, then `file<TAB><path><TAB><mode><TAB><hash>` per payload), `tracked.patch` (`git diff --binary HEAD`, may be empty), `new/<path>` (each untracked file); read by `sh checks/brief.sh restore` |
| `.vid/jobs/<try>` *(16)* | `checks/job.sh` | at `start`; `run` appends the launch and the exit; `stop` the intent | `key=value` lines: `run=`, `step=`, `try=`, `brief=`, `brief-hash=`, `quoted-at=`, `worktree=`, `plugin=`, `version=`, `model=`, `effort=`, `return=`, `started=`; then `pgid=`, `pid-start=`, `supervisor=`, `supervisor-start=`, `[task=]`; `stop=<UTC>`; `exit=<n\|recovered\|not-launched>`, `[stopped=yes]`, `ended=`. Beside it `<try>.events` (Codex's `--json` stream), `<try>.final` (its last message), `<try>.err`, `<try>.save`, and the worktree `<try>.wt/` |
| `design/screens/index.json` *(21)* | the design pack (vid-design rule 6), new packs only | at import, with the pack | `{"layout": "per-screen", "files": [every file], "components": {"<screen>": [its component group files]}}` — under `layout: per-screen` design-join judges one canvas per screen and every listed file present, and briefs name a screen's own file and its components; absent, or another layout, nothing changes; `sh checks/design-join.sh --index` reads it |
| `.vid/reread-owed.<session_id>` *(9)* | the plugin's `hooks/reentry.sh` (SessionStart `compact`) writes it; `hooks/reread.sh` (PostToolUse Read) appends `cover` lines and removes it when paid | at a compaction in a live run; a cover at each main-session read of a listed path | the session's re-read debt: `since <UTC>`, one `file <path>` per skill file to re-read, one `cover <path> <first> <last> <total>` per read (from v0.26.10.10 a truncated read too, its last line withheld); while it stands every main-session tool but Read is refused. The owner may delete it from another terminal to lift the block; no agent-facing text says so |
| `.vid/reentry-shown.<session_id>` *(21)* | the plugin's `hooks/reentry.sh` (SessionStart `resume`) | when a resume prints the re-entry page | its UTC time: a resume within 30 minutes of it prints nothing; a resume writes no re-read debt — only a compaction does |
| `.vid/VID-FINDINGS.md` *(23)* | the run managers of vid-init, vid-develop, vid-fix and vid-add | an entry appended when a ViD check, hook, skill or agent role misbehaves (refuses legitimate work, crashes, contradicts itself or its documentation, gives a wrong count) or is worked around; created from `templates/VID-FINDINGS.md` at the first | ViD's own defect log, one entry each, numbered in the file: `## F-<n> · <title>`, then `- **Seen:** <UTC date> · ViD <version> · records <n> · <verb>, <step>`, `- **Where:** <ViD file>[:<line>]`, `- **What happened:**`, `- **Evidence:** <project paths, never pasted product content>`, `- **Cost:** <counted minutes, re-runs or tokens lost> \| not counted`, `- **Local workaround:** <…>[ (owner answer A-<n>)] \| none`, `- **Ask:**`; each with its `vid-finding` event; the export carries it with the home's `.vid/` |
| `.vid/agents/<agent id>.brief` *(21)* | the plugin's `hooks/net.sh` (PostToolUse) | made exclusively at an agent's first tool call | an empty marker: that agent's `agent-brief` is recorded, so it is recorded once |
| `.vid/hook-times` | `checks/hooks/pre-commit` | one line per commit attempt, refused ones included | where the commit gate's time goes |
| `.vid/RUN-STATE.md` | vid-develop's session; `metrics.sh completion --record` writes `run: complete` | created at develop's start; rewritten at every slice open and close, handoff, state change and completion report | where the run stands now, and the open questions |
| `.vid/HEARTBEAT.md` | `checks/watchdog.sh` (the session's lines) and `checks/observe.sh` (the observer's) | appended, newest last | what is running, since when, on what evidence; *(12)* the owner's notices, `observe: notice — <text>`; *(23)* the drop notice, `ViD: passing rows fell from <A> to <B> since <HH:MM> UTC: <x> reset by an amendment (commits <shas>), <y> now red, <z> not re-run since a test change, <h> held, <o> other. Open the session and ask what changed.` (only the non-zero parts; they add up to A − B) — when passing falls 20 or more against the last 60 minutes' high |
| `.vid/observer.state` *(12)* | `checks/observe.sh` (each tick, under its lock) | rewritten whole at each tick | the observer's memory, `<key> <value>` lines: `tick <epoch> <home>` (the newest tick and the home it ran for — `alive` reads both), `loop <token> <home>` (the watcher loop's acknowledgement, written as each of its ticks begins, and as a tick held back by the interval ends), `notified.<key> <epoch>` (a notice recorded, until its condition clears), `quiet.standing`, `idle`, `fail.<op>`, `epstart.<episode>`; no `notifier` line; *(23)* `notified.drop.<epoch>` — a drop notice, keyed on the tick its drop is counted from |
| `.vid/observer.passing` *(23)* | `checks/observe.sh` (each tick of a run with `plan: required`) | rewritten at each tick | the passing rows of the last 60 minutes' ticks, one line a tick: `<epoch> <HH:MM UTC> <passing count> <ROW-id,…\|->` (checks/evidence.sh's `pass` rows) — the drop alarm's window |
| `.vid/observer.drop` *(23)* | `checks/observe.sh` | at a drop notice; emptied when passing recovers to within 20 of the drop's high | the drop standing: `<epoch> <HH:MM UTC> <the high A> <B at the last notice> <ROW-id,…>` (the rows passing then) — a further notice needs 20 below B |
| `.vid/observer.pid` *(12)* | `checks/observe.sh start` | at each start of the loop | three lines: the loop's pid, the run's home (`pwd -P`) and the loop's random token; a loop whose token is not here ends |
| `.vid/observer.log` *(12)* | the watcher loop | its output, appended; cut to its last 200 lines at each start | the loop's ticks and its end, `observe loop <token> ended at <UTC>` |
| `.vid/observer.lock` *(12)* | `checks/observe.sh` (a tick) | while a tick runs, per worktree; removed at its end | `pid` — the tick's; a live holder's lock makes another tick skip, a dead holder's is reclaimed |
| `.vid/observer.start` *(12)* | `checks/observe.sh start` | while a start runs; removed at its end | `pid` — the start's; serialises two starts |
| `.vid/SUMMARY.md` | vid-develop | a section appended at every slice close | the slice in the owner's words |
| `.vid/verdicts/<ROW-id>.md` | vid-develop, vid-fix | one block per verdict | a row's attempt record, prose |
| `.vid/ledger-results/` | `checks/test.sh` | one file per ledger run that ran to its end; *(2)* inside a 0.9.6 develop run, at the run's home, with `<receipt>.tree` and `<receipt>.cases` beside each kept receipt | the receipts (below) |
| `.vid/runs/<run-id>/` *(2)* | `checks/test.sh`, inside a 0.9.6 develop run | one folder per test run while it runs, at the run's home; deleted after publish; kept only when its teardown failed | a live run (its `holder`: `pid=`, `start=`, `kind=`, `worktree=`, `slot=`, `project=`, `tree=`, and `teardown-failed <UTC>` when that happened); temporary |
| `.vid/requests/<ticket>/` *(6)* | `checks/test.sh request` (and the run it starts) | one folder per test request, at the run's home (in the checkout outside a develop run; *(27)* at the home `checks/plan.sh home-of` resolves, when it does; a `staging` request's `type=staging`); `<ticket>` is the UTC time and 4 hex; kept | `request` (`key=value` lines: `type=`, `role=`, `runrole=`, `why=`, `rows=`, `estimate=`, `cap=` (*(24)* gone: `silence=`, `startup=`, `limit=` in its place — the watcher's silence, start-up and run limits in seconds; an older ticket's `cap=` is still read as written), `startup=` (before 24 the estimate's start-up term; *(24)* the start-up limit, the estimate's start-up term then `estimate-startup=`), *(13)* `teardown=` (the teardown between two passes the estimate counts; 0 for one pass), `cases=`, `expect=`, `no-history=`, `cwd=`, `sel=`, `dsel=`, `steps=`, `gated=`, `prove=`, `created=`; *(15)* a close batch's `batch=yes`; *(25)* a full run's `stage=<N>` (`--stage N`: the analyst's setup and slow triggers count only the cases of stages 1 to N; *(28)* `stage=0` when STAGES.md holds STAGE-0, stages 0 to N); a chunk's `id=<ticket>/<n>`, `batch=<ticket>`, `chunk=<n>`, `phase=1\|2`, `export=`, `tree=`, `base=`), `rows` (the requested rows, one per line), `state` (`queued`, `running`, `done`, `capped`, `failed-to-start` or `stopped`), `running-at`, `result` (at most: `status=<n> ran-to-end=<yes\|no> capped=<yes\|no> report=<receipt\|none>`, `cases <status>=<n> …`, the red groups, `outside n=<n> rows=…`, `why: …`, `no-history rows=…`, *(7)* one `analyst due: <reason> request=<ticket> [rows=…] [cases=…] [group="…"]` line per test-analyst trigger that fired; *(18)* `retry: --expect <s>` on a capped result, s twice `cases=` (*(24)* gone); *(24)* a capped result's first line says why — `stopped: no new output for <n> min (last at HH:MM UTC)`, `stopped: the <inline\|deployed> pass's start-up passed <n> min`, or `stopped at the run limit (<n> h awake)`; `build failed: no test ran — <the build's last error line>`, the result's first line, when the image build failed — no later pass, no receipt; the ticket keeps it as `build-failed`), `exit`, `cap-hit` when the cap stopped it (*(24)* when its watcher stopped it: `reason=silent\|startup\|limit`, `pass=inline\|deployed`, `last-output=<UTC>` (the last new output it saw), `at=<UTC>`, one a line — before 24 a UTC time alone); *(24)* `watch` — the watcher's counts, rewritten each 5 s tick while the run runs: `awake=<s> silent=<s> pass=<inline\|deployed> phase=<startup\|tests> at=<UTC>` (ticks × 5 s, so a host sleep never counts; `wait` reads it); *(24)* `pass` — the pass in progress, `inline` or `deployed`; *(24)* `compose.inline.err` — the inline pass's Compose output as `up` writes it, removed when the pass is read; *(24)* `svcout.<pass>` — inside a develop run, each service's last log line, `<service><TAB><line>`, rewritten each poll of the services watcher from the pass's bring-up; `outside` (the rows it reached outside the request; *(14)* the report is kept all the same and credits none of them — before 14, the kept-out candidate report beside it); *(14)* `stopped` — the cause line when a service died while the tests ran (`stopped: service <name> exited code <c>\|killed for memory at <UTC> — see services.<pass>.txt`), also the result's first line; `services.<pass>.txt` (`inline`, `deployed`) — inside a develop run, each pass's containers' end states before its teardown, a header line then one line each, `<name> state= exit= memory-kill=yes\|no health= restarts= started-at= ready-at= finished-at=` (`ready-at` the first passing readiness check Docker kept, else `-`; *(20)* renamed `kept-healthy-at=` — the first passing check Docker still kept in its rolling health log when VID read it, not when the service became ready); `timeline.<pass>.log` — each pass's test-environment log lines with their times (the last 20,000, at most 20 MB), after its result and before its teardown; *(21)* a pass that is red or ran short of its end keeps `timeline.<pass>.log.gz` instead — its whole log, compressed, at most 100 MB keeping the end (when cut, its first line says so); *(21)* a pass stopped short (a cap, a cancel, any stop) keeps it too, and `last-lines.<pass>.log` — each service's last 200 lines — both taken before its down; *(21)* `tests-at` — when the tests container was first seen running (the cap counts from it; *(24)* one per pass, `tests-at.<pass>`: that pass's start-up ends there); *(21)* `slept` — the seconds of host sleep the cap watcher saw (a tick gap over 40 s), not counted against the cap, recorded as `slept=<n>` in `request` and said in `result` as `host slept <n> s during this run` (*(24)* no longer written: ticks never count a sleep; an older ticket's `slept`, `slept=` and line are still read as written); *(21)* `result`'s `deployed pass: ended outside completed (exit <n>), no receipt — the inline pass's receipt is kept` when only the deployed pass of an iterate ended outside completed; *(11)* `holders` — while the run waits for a test environment, one line per held slot on the host as of its latest try (`stack.<k>: held by pid <pid> — repository <path>, compose project <name>, for <s> s`, or `stack.<k>: STALE — pid <pid> is gone (repository <path>, compose project <name>), <s> s old. …`; *(15)* a chunk's `giving way: request <ticket> waits and this batch holds <n> of <k> slot(s)`), left as last written; *(13)* `timeline.log` — inside a develop run, when its inline pass's `overhead=` is over 120 s, the test environment's own log lines with their times (Compose `logs --timestamps`), saved before its teardown (*(14)* replaced by `timeline.<pass>.log`); *(13)* `run` — inside a develop run, the run folder's path: the result, `exit` and the final `state` are written when the last pass is published, before the final teardown, so a request can be `done` while its run folder and slot are still held (*(21)* written once the folder and its holder exist, and removed with the folder); `log`, `passes`, `pid`, `supervisor`, `watcher` are its working state; *(15)* a close batch's ticket also holds `groups` (its groups as asked, one per line: `G <phase> <phase.line> <rows,…> <inline words> <deployed words> <the line>`, tab-separated), `batch` (`id=`, `tree=`, `base=`, `steps=`, `chunk-seconds=`, `stacks=`, `export=`, `frozen-at=`, `frozen=computed\|reused from <ticket>`), `frozen/` (close-rows' required rows with sets, phases and shapes, the expected cases' inputs and the population reference, as frozen at its start; `key` — the tree, steps, slice, rows file and plan it was frozen for and the events line count then: a later batch reuses it while nothing else close-rows reads has changed), `layout` (`<n> <phase> run\|adopted <seconds\|source chunk>` a chunk a line), `receipts` (`<chunk> <receipt path> inline\|deployed`, the newest sub-ticket's each), `export` while it runs, and `chunks/<n>/` — a sub-ticket with the files above plus `groups`, `phase`, `outcome` (`green`, `red`, `incomplete`, `retry`, `stopped`), `why`, `judged`, `receipts`, and `adopted` (`<ticket>/<n>` of the chunk it took); `<n>-retry` is its one retry; a chunk never launched ends `stopped`. The parent's `result` is `green`, `red phase <p>[, rows <ids>][, chunks <ns>]`, `incomplete phase <p>, chunks <ns>` or `stopped: …`, then `chunks <n> retried= adopted= stacks-max= wall= chunk-seconds-sum=`, `incomplete chunk=<n> why=…` and `red row=<id> case=<case>` lines, a `chunk <n> phase=<p> <outcome> [adopted=…] [report=…]` line each, and the chunks' `analyst due:` lines; *(16)* `try=` in `request` for a builder's or fixer's ticket; `pid-start` beside `pid`; a `cancel` mark (`by=`, `at=`); the state `cancelled` (exit 77, the result's first line `cancelled by <who>`) |
| `.vid/budget` | vid-init (`stacks=`, `memory-headroom-mb=`); the owner; *(2)* `checks/testenv.sh record` | at init; *(2)* at develop's test-environment step | `key=<number>` lines: `stacks`, `memory-headroom-mb`, `claims-per-slice`, `wall-hours-per-slice`, `court-seconds`; *(10)* `builder-context-tokens` (400000); *(15)* `chunk-seconds` (a close batch's chunk size in recorded case seconds, default 1200); *(2)* `unverified-rows` (60 per environment), `env-mb` (one environment's measured peak), `testenv=proved\|one` (two or more environments proved side by side, or one); *(13)* `testenv=proved harness=<cksum of docker-compose.test.yml>` — the harness it was proved on: admission and the checkpoint use `stacks=` only when it matches the requesting checkout's harness, else one environment; a bare `testenv=proved` reads as proved on no known harness; *(12)* `progress-notify` is gone — nothing is sent; *(17)* `builders-target=<n>`, the owner's: how many builders at once, shown by the progress table, never enforced; *(24)* `silence-minutes` (20), `startup-minutes` (60), `run-limit-minutes` (1440) — a test run's silence, start-up and run limits, read when it is requested |
| `.vid/windows` *(0.26.10.29.3; 0.26.11.1.3)* | `sh checks/lib/wsl.sh notice` (init's first step, create-prd's when standalone, and the starts of /vid run, /vid plan and /vid develop), which checks once that WSL starts and records the answer, with no question (*(0.26.11.1.3)* the question, `ask` and `record`, is cut); the owner, by editing it | once per machine, only on a native Windows shell; at the main checkout (the parent of `git rev-parse --git-common-dir`; outside a repository, the working directory); untracked | `wsl: yes` (WSL started) or `wsl: no` with a `# WSL did not start <UTC>` line: with `yes`, the courts run directly (prd, inventory, design-join, imports, seams, stages) re-run under WSL, never under a git hook; with no file they run natively; while the file exists nothing is checked or said again, and deleting it checks again; builder worktrees and other sessions read the main checkout's |
| `.vid/reviewers` *(0.26.10.29.3, phase 2)* | `sh checks/lib/wsl.sh reviewers record yes\|no`, on the owner's answer to the one second-reviewer question (asked at the first whole-mode review, only when `codex` is on the PATH); the owner, by editing it | once per machine; at the main checkout, beside `.vid/windows`; untracked | one line, `codex: yes` or `codex: no`: with `yes` (and `codex` still on the PATH; `sh checks/lib/wsl.sh reviewers` prints the answer), every round of the whole-mode reviews (create-prd's §10, 7b, the final passes) has a second reader, Codex, beside the fresh agent; while the file exists the question is not asked again |
| `.vid/briefs/<pass>-<n>.md` *(0.26.10.29.3, phase 2)* | the session that starts a review pass (vid-create-prd, "The second reader") | once per pass run that Codex reads, before it starts; `<n>` counts that pass's briefs | the pass's brief: its pass file and its inputs, as paths only, never their contents; Codex is started with one short sentence naming this file |
| `.vid/reviews/<pass>-<date>-<n>-r<round>-<reader>.md` *(0.26.10.29.3, phase 2)* | the session that started the pass, from the reader's return, verbatim | once per reader per round, before the return is read; `<n>` counts that pass's runs that day, `<reader>` is `agent` or `codex` | the whole report, unedited; the PRD's findings rows for that review are written from these files, every finding one row, and the `review:` line's count is of those rows |
| `.vid/close/<slice>.rows` *(3)* | vid-develop (the orchestrator or builder that made the change) | before each selected close, from the closing steps' diff | the rows the builder names as affected, one line each — `ROW-<id> \| <one-line reason>` — and `note \| <what was checked>` for a change to shared paths or uncited code; read by `checks/metrics.sh close-rows` as set 5 |
| `.vid/plans/<hash>.plan` *(2)* | `checks/plan.sh change` | every accepted plan, copied whole when its change is recorded; never edited or removed | the plan a `step-start` was admitted under — with the events, what every started step held, rebuilt without RUN-STATE |
| `.vid/PROGRESS.md` *(2)* | `checks/progress.sh --record` (the observer hourly and after a plan change; the session) | a table appended per update, newest last | the progress update — the fixed table below; the newest section is current |
| `.vid/home` *(2)* | `checks/plan.sh home --brief <f>` | a builder worktree's first act | one line: the absolute path of its run's home, where its receipts, events and amendments land |
| `.vid/grades/YYYY-MM-DD-grade.md` | vid-grade | one per grade (`-2` for a second the same day) | the ranked findings table, with an `adjudication:` cell per row; *(4)* the header's `graded: <commit, 12 hex>` and `dirty: yes\|no` (the worktree had uncommitted changes) name what was graded |
| `.vid/run` *(4)* | `checks/event.sh` (through `checks/run.sh id`) on every `stage … state=start`; `checks/run.sh new` and `label` | created at the first stage start at the run's home; renewed when the project was copied (its `path=` is not the home's) or by `run.sh new`; `team=` and `series=` set by `run.sh label` | `key=value` lines: `id=` (the UTC time plus 6 hex), `path=` (the home when the id was made), `start=` (HEAD then, or `none`), `parent=` (the id it was renewed from, or `-`), `parent-start=` (the parent's `start=`), `copied-at=` (HEAD when a copy was detected, or `-`), `created=`, `team=`, `series=` (`unknown` until set). One id per trial, kept through handoffs, restarts and refreshes of `checks/` |
| `.vid/run.parent` *(4)* | `checks/run.sh` | when `.vid/run` is renewed | the file it replaced, whole |
| `.vid/plans/decisions/<id>.why` *(4)* | `checks/plan.sh change`, inside a develop run under the gate | one per plan change, accepted or refused; written once, never edited | `key=value` lines: `id=` (the UTC time plus the candidate hash), `at=`, `result=accepted\|refused`, `what=`, `prev=` (the last accepted plan's hash, or `none`), `candidate=` (the hash of the raw block, taken before validation), `commit=` (HEAD), `trigger=`, `evidence=`, `expect=`, `alternatives=` (`-` when not given; the trigger, expectation and alternatives are the model's declaration), `refusal=<first line>` when refused; *(17)* `not-needed-by=<step ids>` and `not-needed-why=<one line>` when given. What moved between two plans is not stored: it is computed from the two kept blocks. *(17)* A strategy decision, `<UTC>-strategy.why` (written by `checks/plan.sh strategy`): `id=`, `at=`, `result=accepted`, `what=strategy`, `set=`, `by=owner`, `commit=`, then a line `words:` and the owner's words verbatim to the end of the file |
| `.vid/plans/decisions/<id>.plan` *(4)* | `checks/plan.sh change` | beside each `.why` | the candidate block whole, accepted or refused, a block that does not parse included |
| `.vid/shares/<run>/` *(0.26.10.28.7)* | `sh checks/share.sh build` (through `/vid:vid-share`, the user) | one folder per share, its summary beside it; rebuilt when the user leaves a part out; nothing else of the project changes | the bundle in the share form: RUN.md, FINDINGS.md, `findings/`, MANIFEST.json and MANIFEST.md, `records/`, `logs/`, `conversations/`, redacted and scanned; never part of a later share's `records/` |
| `.vid/exports/<run id>-<UTC>/` *(4)* | `sh checks/export.sh [--out <dir>]` (the owner) | one folder per export; the export changes nothing else | `manifest.tsv` (`<kind> <path> <bytes> <sha256> <source> <captured>`, tab-separated; kind `file`, `part` — a file over 95 MiB cut into `<path>.part-000` … —, `split` — that whole file's bytes and sha256 — and `missing`), `export.tsv`, `vid/home/` (the home's `.vid/`, `exports/` left out), `vid/worktrees/<name>/`, `repo.bundle` (every ref, plus `refs/vid-export/tree/<receipt>` per receipt tree), `transcripts/<folder>/`, `plugin/<version>/` |

### PRD.md

- **Grammar.** The header line `grammar: <x.y.z>` before the first `## `.
  `0.9.4` and later (compared component by component) carry the features
  block and the decision labels; `0.9.5` and later also carry `plain:`; a
  file without the line is legacy. A grammar line is never lowered.
- **Machine blocks**, each a fenced block named below; `#` lines inside
  are annotations:
  - ```` ```vid-prd ```` — the items, `ID | type | tier | statement |
    <label>: <value> | …`. Demand items are `REQ-NNN` (types
    `functional`, `nfr`, `ux_flow`, `data_entity`); frame items `INV-`,
    `NG-`, `RISK-`, `HYP-`, `OUT-`, `MET-`, `CON-`. Labels a reader may
    use: `fail-if:`, `serves:`, `feature:` (one `FEAT-NN`, on every demand
    item and invariant under 0.9.4), `plain:` (the rule in one plain
    sentence, at most 30 words, no ids, on every demand item and invariant
    under 0.9.5 — what a viewer shows the owner), `authority:` (`authoritative` |
    `provisional` | `pending`), `confirms_via:`, `source:`, `phase:`
    (`pilot` | `later`).
  - ```` ```vid-prd-features ```` — `FEAT-NN | goal label or - | name`,
    the parts of the product the owner would name.
  - ```` ```vid-prd-answers ```` — the decisions: `A-NNN | <tier> |
    <date> | Q: … | A: … | settles: … | importance: priority | shown:
    pause-N <sum> | delegated: yes`. The tier `human` is the owner's decision,
    `model_proposed` a decision VID took; `importance: priority` marks the
    owner's big decisions; `delegated: yes` (0.26.10.29.3 R2) a human answer
    VID wrote under the owner's delegation, until the owner confirms it
    (restated without the field).
  - ```` ```vid-prd-mechanisms ````, ```` ```vid-prd-contract ````,
    ```` ```vid-prd-findings ```` — the thesis mechanisms, the coverage
    contract, the review findings. A findings row is `F-NN | pass |
    severity | target | disposition | evidence: …`; pass `red-team |
    audit | review | lens | final | strength` (`strength`, the test
    list's strength pass; 0.26.10.29.4 phase 3 R1); a target names items, mechanisms,
    dimensions or answers, the thesis or the seed, or another document by
    form only (`INVENTORY.md:ROW-12`, `DESIGN-BRIEF.md:D-149`, a bare
    name; 0.26.10.29.3 phase 2 R6).
- **Review lines.** *(0.26.10.29.3 phase 2 R2)* A review's record is a line
  `review: <delta|whole|final>, round <r>, <n> findings` (a final review
  adds `, read: <files>`; a whole or final review's repair append says
  `, 0 findings, see <its heading under ## Findings>`), in the append
  section of a delta review or the dated `### ` heading under
  `## Findings` of a whole or final one; `<n>` is the rows of the
  findings block(s) under the same heading, checked by `checks/prd.sh`.
  Phase 1's `review: delta, <n> findings` reads as round 1, its count not
  judged.
- **Open decisions.** `VID-QUESTION: (OQ-n) A-NNN — <question>` lines ask
  the owner to confirm a VID decision; `RESOLVED: (OQ-n) A-NNN` closes one.
- **Appends.** Everything under `## Appends` supersedes by the latest-wins
  rule.

### INVENTORY.md

The ```` ```vid-inventory ```` block; its first line `grammar: 0.9.3` for
a 0.9.3-or-later project. Rows:

    ROW-NNN | kind | subject | actor/state | marker | obligation | derived-from | test

- `kind`: `surface` · `journey` · `shell` · `behavior` · `reachability`.
- `derived-from`: `REQ-NNN` ids and/or design markers (`P03/expired`).
- `test`: a ledger test path, or `owed: <reason>` (`owed: paid by /vid
  deploy gate N — …` is paid at deploy). *(29)* `owed: spec-only — first
  stage` on a row ratified at a spec-only init whose test is not written yet
  (the code skeleton writes it), `owed: spec-only — ticket` on a row appended
  under ticket mode (its ticket carries it); legitimate on the par line, its
  count `spec-only=<n>` in the class split after `prerequisite=`. In ticket
  mode a row's `test` field is a path under `tests/` in ViD's copy — the
  file at the path it has in the code repository — and never carries a
  `proved-red:` stamp.
- `rule`, `seam` and the governance rows sit in the same block; their
  first field is the word `rule` or `seam`. A `seam` row may carry
  `module: <module id>` *(22)*.

### ARCHITECTURE.md's vid-code block *(29)*

Ticket mode only (vid-plan; vid-replan wrote the test facts and `run-full:`, old ticket mode, removed in 0.26.10.28.1): the code repository on GitHub, by
name only, one `key: value` line each in a ```` ```vid-code ```` block —
`repo: <owner>/<name>`, `labels-prefix: <empty, or a prefix>`; once the code
skeleton is merged and checked, `test-framework:`, `test-dir: tests/<dir>`,
`run-one: <the command that runs named tests>`, `ci-workflow: <the
workflow's name>`, `report: vid-junit-<run attempt>`; *(31)* `run-full: <how
the full run is started>` — the skeleton's CI runs every test only on a
manual start of main. Committed alone.

### ANSWERERS.md *(29)*

Ticket mode: one line per area in a ```` ```vid-answerers ```` block — `<area:
feature ids, or all> | <name> | <how reached>`. A question card names the
answerer of its area (vid-replan's question cards: old ticket mode, removed in 0.26.10.28.1).

### Ticket mode's files — .vid/tickets/, .vid/replans/ *(29)*

The first ticket mode's alone (vid-plan's publish, vid-replan): old ticket mode, removed in 0.26.10.28.1. *(33)* Its `.vid/code/` and `.vid/pages/` entries,
which the rebuilt flow writes and reads too, are under "The ticket flow's files" below.

- `.vid/tickets/map` — one line per thing created on GitHub, written by
  `checks/github.sh publish`: `label name=<label>`, `milestone stage=<n>
  number=<n> hash=<12>`, `step step=<id> number=<n> hash=<12>`, `ticket
  number=<n> step=<id|-> kind=feature|fix|skeleton brief=<file> parts=<n>
  hash=<the written: hash>`.
- `.vid/tickets/state` — `github.sh pull`'s reading: `ticket number=
  state=OPEN|CLOSED labels=<names|-> taken=yes|no` and `pr number= ticket=
  state=open|merged|closed draft=true|false head= merge=<sha|->`.
- `.vid/tickets/pr-<n>/` — a pull request naming a ticket: `meta` (the same
  fields), `body.md`, `comments/<k>.md`, `runs` (`run id= attempt= sha=
  workflow=<spaces as %20> event= status= conclusion= repo=`, each run of its
  commits) and `artifacts/<run>-<attempt>/` (the report downloaded as
  `vid-junit-<attempt>`; `<run>-<attempt>.none` when that download failed: no
  report). `.vid/tickets/commit-<sha>/` holds main's runs at a stage's last
  merge the same way.
- `.vid/tickets/PLAN.md` (`checks/ticket.sh plan-md`) — the plan page's
  source; `.vid/tickets/skeleton.md` (`ticket.sh skeleton-body`) — the
  skeleton ticket, a `kind: skeleton` header, `quoted-at:`, `base:`, a
  `written: ticket.sh skeleton-body <hash>` stamp.
- `.vid/replans/<round>.md` — a replan's report (its page rendered under
  `.vid/pages/`).
- **A ticket on GitHub:** parts of at most 60,000 characters, each opening
  with a ```` ```vid-ticket ```` header — `issue= step= stage=
  kind=feature|fix|skeleton part=<k>/<n> hash=<the written: hash> base=<code
  commit> branch=vid/<issue>`, part 1 adding `rows:` and `run:` — and ending
  `<!-- vid-ticket end part=<k>/<n> -->`; part 1 the issue's body, the rest
  its comments. **The return block, `vid-return 1`:** one ```` ```vid-return
  ```` block at the end of a pull request's description: `ticket: #<n>`;
  `rows:` then one line per ticket row, `<REQ-id>/<ROW-id>
  pass|fail|not-run ci: <run id> [reason: <one line>]`; `decisions:`,
  `discovered:` (`early-technical|user-visible|new-work: <line>` or
  `blocked-by: #<n>`), `law-needed:` (`<ROW-id>: <why>`) and `questions:`,
  each a list or `- none`; the skeleton ticket's block `rows: none` and one
  `skeleton: <key>: <value>` line each for test-framework, test-dir,
  run-one, ci-workflow and report, *(31)* and run-full when its ticket asks
  for it; *(31)* one `ci-scope: <selector>` line, equal to the ticket's CI
  scope's selector when it has one. **The skeleton contract's artifact:**
  every CI run publishes its JUnit XML report as `vid-junit-<run attempt>`,
  each case `<test path>::<test name>`, the name carrying the ROW id.
- **Outside ViD's records, in the stand-in's clone:** `.git/vid/` (its
  fetched tickets, reviews and claims), `.git/vid/sessions` (`verb=
  session= transcript= at=`, one line per stand-in verb start), and the
  `Stand-in: worker-<k>` / `Stand-in: approver` commit trailer on the root
  commit, every claim commit and every approver's merge.

### The ticket flow's files *(33)*

The rebuilt ticket mode's records, at the top of ViD's repository (the run's home): its plan, its tickets, what the
dev side sent back and what ViD decided. Each script writes only under `.vid/`, reads no code but the bare copy and
runs nothing of the code repository. `checks/github.sh state-save` saves `.vid/decide/`, `.vid/tw/`, `.vid/plan/`,
`.vid/plans/`, `.vid/results/*.txt`, RUN-STATE, the budget, the events and the findings log to the state repository's
`vid-state/records`, and `state-restore` brings them back; `.vid/round/`, `.vid/code`, `.vid/pages/`,
`.vid/state-at`, `.vid/lock-session` and `.vid/decide/tmp.*` are never saved. A row's *(v0.26.10.x)* names the
release that began the file; *(33)* is when this contract first lists it.

| path | writer | when | what a reader takes from it |
|---|---|---|---|
| `.vid/tw/settings` | `checks/planner.sh setup` (the owner's setup answers, *(v0.26.10.26.7)*; `labels-prefix:` added empty when missing); the owner, by hand, for the rest | at the setup sitting and each later setup answer; an owner's edit | `key: value` lines: `layout: separate\|one`, `team: <name> \| <area> \| strict\|core \| <people>` (one a team), `split:`, `github-mode: auto\|team` (who works the tickets, ViD's own DevAgent or an outside team's, asked with no default, *(v0.26.10.28.8)*), `repo: <owner>/<name>`, `spec-repo:`, `labels-prefix:`, `open-tickets:`, `state-repo:`; the round's `ticket-hours:` (8), `quiet-hours:` (2) and `stand-in: on` (off by default, never written by ViD); the close's `close-chunk-minutes:` (20) and `close-wait-minutes:` (180). A default ViD wrote is no answer: `planner.sh setup "not yet"` writes no key |
| `.vid/tw/log` | `checks/github.sh` (each act on GitHub: tw-post, tw-close, tw-sync, code-setup, spec-setup, state-setup, spec-export, spec-publish, tw-reopen, the asks) | appended, one line an act | the writer's and the asks' history: `published\|amended <n> <the meta's fields> parts= at=`, then `sent <row> ticket=<n> hash=<h>` a row; `withdrawn <n> decision=`; `sync main=<sha>|none|absent open=<n,…>` (*v0.26.10.28.2*: `none` an empty code repository, `absent` heads but no main; a failed read writes no line); `export <c> from=<ViD commit> state=pushed\|unchanged`; `repo\|spec-repo\|state-repo <name> created\|exists at=` (*FB-2 A1*: each repository the setup names, made at the connect when missing, private and empty); `spec-failed export=<12 hex\|-> at= why="<the line, GitHub's words in it>"` (*FB-2 B2*: each folder publish not finished, exit 5, no reader keys on it); `reopened <n> at= open=left[ words="<w>"]` (*FB-2 A3*: an open ticket its dev side left, reopened with one comment); `asked <n> close\|deploy\|grade step=\|stage= commit= at=` — what admission, the writer's `due`, the results reader and the round read for which ticket holds a row |
| `.vid/tw/handed` | `checks/decide.sh` (merged, held and failing rows), `checks/results.sh declare` (the engines), `checks/close.sh` (`closed <step>`, fix lines, a stage's candidate), `checks/round.sh` (the interim `closed <step>`), `checks/land.sh` (`reached` lines, a landing's drops), `checks/queue.sh lesson` | appended, and rewritten when a landing drops a row's lines | what later roles hand in, each line ending `\| stand-in: <who>` until their stages: `engines <primary> <other>…`, `engine-split <row>`, `closed <step>`, `row <id> <state> [fault-proven]`, `fix <row> [<row> …] \| <reason> \| <links>`, `lesson <ids> \| <words>`, `reached <row> <REQ\|INV id> [<the landing>]`, `candidate <stage>` — what `plan.sh start` admits by and the writer reads |
| `.vid/tw/out/` | `checks/writer.sh write` (`<kind>-<arg>.md` and its `.meta`: the log line's fields, then `sent <row> <hash>` a row; `parts` into a folder it is given); `checks/github.sh tw-post` (`issue-<n>.md`, the ticket as published) | at each write; at each publish or amendment | the tickets ViD wrote, before and as published; the results reader, the close and the writer's amend read `issue-<n>.md`. The skill reads only the file the write just printed, never one left from before |
| `.vid/tw/named` *(0.26.10.29.5, DP-1 R5)* | `checks/writer.sh name <step> <D-id,…>` (RM, an unknown step or id refused before anything is written) | appended, one line a name | `<step> <D-id>,<D-id>…`: the decisions RM named for every ticket of that step, its fix tickets included; the writer joins them to each such ticket's Decisions section whatever their label and always keeps them, a decision about ViD's own settings apart; the section is in the ticket's hash, so a name for a step with an open ticket makes `writer.sh due` owe its amendment |
| `.vid/tw/known-findings` | `checks/queue.sh answer` (a finding ruled `known`) | appended, a line once | one finding's words a line: what the owner keeps as a known limit, so it is not asked again |
| `.vid/tw/stood-in-answers.txt` | `checks/round.sh` | appended, only under `stand-in: on` | `<UTC> TAB <row or ticket> TAB <the answer> TAB <why>`: each answer the round gave in the owner's place (a held row with only its evidence missing accepted, a held weak test ruled a known limit, each `--by stand-in`) |
| `.vid/plan/setup` *(v0.26.10.26.7)* | `checks/planner.sh setup` | appended, one line a setup answer; the planner writes no event | `setup-answered key=<layout\|team\|split\|repo\|spec-repo\|github-mode> value="<the answer>" words="<the owner's words>" at=<t>`; until the first ratify, `planner.sh check` flags each setup key no line covers; `checks/devagent-start.sh` reads the newest `github-mode` line, the GitHub mode, for the start it prints and for vid-run's read-access line *(v0.26.10.28.8)* |
| `.vid/plan/review` | `checks/planner.sh review --in <file>`, `answer <n> keep` | at each review pass recorded; at the owner's keep | `review <r> hash=<h> findings=<k> at=<t>`, then `finding <n> review=<r> hash=<h> \| <row id> \| <why>` each; `answer <n> keep hash=<h> at=<t> words=<…>` |
| `.vid/plan/<the review's output>` | the session (vid-plan: the fresh agent's review, saved under `.vid/plan/`) | at each review pass | the reviewer's `finding <row id> \| <why>` lines or `none`, as it returned them; read once by `planner.sh review --in` |
| `.vid/plan/PLAN-PAGE.md` | `checks/planner.sh page` | at each page | the plan page's markdown, the record; rendered to `.vid/pages/PLAN-PAGE.html` |
| `.vid/plan/paged` | `checks/planner.sh page` | appended at each page | `paged spec= plan=` — the spec and plan hashes the owner was shown; ratify refuses a plan no page showed |
| `.vid/plan/ratified` | `checks/planner.sh ratify`; `reratify` (a landing's, from `checks/land.sh`) | appended at each ratification | `ratified hash=<h> plan=<plan hash> at=<t> words=<verbatim>` — `planner.sh ratified` and the writer's gate read the newest |
| `.vid/decide/pr-<p>-<head12>.txt` | `checks/decide.sh decide` | at each decision, overwritten | the decision on that head, as its comment says it: each row's state and the ticket's (`ticket: accepted` and the like); it names reports, never their words |
| `.vid/decide/pr-<p>-<head12>.rows` | `checks/decide.sh decide` | at each decision | tab-separated, a row a line: row, journey, state, what stands under a hold, fault, line, undone, t3, what it has failed as on this pull request, w or p, 1 when a later head must shrink past it, the same before this head |
| `.vid/decide/posted-pr-<p>-<head12>`, `.vid/decide/last-pr-<p>` | `checks/decide.sh decide --post`; `decide` | at a post; at each decision | the comment as last posted at that head (posted again only if it changed); the pull request's newest head decided |
| `.vid/decide/state`, `.vid/decide/log` | `checks/decide.sh` (`state` rewritten by `checks/land.sh` and `rule`) | at each decision | `state`: each row's newest decision, tab-separated (`accepted`, `accepted by ruling`, `held`, `failing`, …); `log`: date, pull request, head12, row, state — a line a row decided |
| `.vid/decide/counts`, `.vid/decide/limits`, `.vid/decide/halted`, `.vid/decide/record`, `.vid/decide/analyst`, `.vid/decide/accepted-at` | `checks/decide.sh`; `checks/land.sh` drops a landed id's lines | at each decision | the hold: `counts` (`<row> <head12 or report id>`, once each), `limits` (`<row> <n>`), `halted` (pull request, row, `i` for an inconclusive fault: held until a ruling, or a later head that proves the row), `record` (the rows truly on the handed record), `analyst` (ticket, head12: analyst due once a ticket), `accepted-at` (*(v0.26.10.26.3)* pull request, ticket, head12, `at=<UTC>`: the first decision reading `ticket: accepted`, the only time kept) |
| `.vid/decide/rulings`, `.vid/decide/rows/<row>.txt` | `checks/decide.sh rule` (the owner's answer for a held row, given through `checks/queue.sh answer`; `checks/land.sh` writes a landing's `reset`); `decide` | at each ruling; at each decision | `rulings`: date, row, word (`accept`, `limit`, `amend`, `more`, a landing's `reset`), words, who — tab-separated; `rows/<row>.txt`: the row's record, as the queue page shows it |
| `.vid/decide/queue.md`, `.vid/decide/queue.html` | `checks/decide.sh queue` (rendered by `checks/page.sh --out`) | at each queue | the owner's queue page: the headline, each held row with its record and the four answers, the findings ranked; the markdown is the record |
| `.vid/decide/merged-prs`, `.vid/decide/merges`, `.vid/decide/refused`, `.vid/decide/flags`, `.vid/decide/accepted-log`, `.vid/decide/ruled` | `checks/round.sh` | at each step of the round | `merged-prs`: a merged pull request a line, once its merge is recorded; `merges`: pull request, ticket, head, merge commit (tab), read by the grade asks and the status; `refused`: `<the work> <plan change>`, a refusal said once until the plan or the handed record changes; `flags`: `<word> <on>`, each alarm standing (cleared when it clears); *(FB-2 A3)* `ticket-left <n>`, a ticket DevAgent left (its newest `DM: left: <why>` comment with no `vid: reopened at the owner's word` after it), GitHub auto alone, cleared by the reopen; `accepted-log`: `<epoch> <accepted rows>` a step; `ruled`: the count of rulings and answers last acted on |
| `.vid/decide/landed`, `.vid/decide/drafts/<n>/` *(v0.26.10.25.5)* | `checks/land.sh` (draft, and the landing on the owner's yes) | at a draft; at a landing | `landed`: `<id> <the landing, 12> <time>`, each reset or added line, a journey's transitions with it — the ids no earlier evidence decides; a draft's `base`, `files/`, `plan` (the whole new vid-plan block when the change places rows), `why`, `count`, `sets`; *(v0.26.10.26.7)* `review` (the fresh-agent review's output the draft was made with, `none` or `finding <row id> \| <why>` lines) and `replaced` (the number of the draft that replaced it); *(0.26.10.29.2, R2)* `deleted` (a spec file the draft deletes, one a line: STAGES.md, a re-cut back to one stage) |
| `.vid/decide/queue/` *(v0.26.10.25.3)* | `checks/queue.sh` (`update-at` by `checks/round.sh`; `status.txt` by `queue.sh status`, which `checks/observe.sh` runs on its ticket-mode ticks) | at each sync, ask, answer and status | `ids` (`<item key> TAB Q<n> TAB <UTC>`: a Q line's number, never reused), `answers` (`<UTC> TAB <item key> TAB <word> TAB <words> TAB <who> TAB <outcome>`, `<who>` owner, RM, delegate or stand-in *(v0.26.10.28.8)*; *(v0.26.10.26.7)* the keys `hold:<N>`, the setup hold answered `continue`, and `context:window`), `questions` (the dev side's questions and their state), *(FB-1 B2)* `own` (`<id> TAB <UTC> TAB <what it gates> TAB <question>`: ViD's own questions, `ask own`, each the item `own:<id>` until answered), `recommend` (`<item key> TAB <letter> TAB <why>`, the session's own), `seen` (what was announced once), `waited` (the questions told they wait on the lead), `doors` (the items sent to /vid fix's door), `started` (`run-start <epoch>`), `updated`, `update-at`, `status.txt` (the status block), *(v0.26.10.27.4)* `offer` (the owner's answer to the grade before the first go-live: `grade <ask>` or `yes`); every other file in it is working state |
| `.vid/decide/stage/<N>/s1` *(v0.26.10.26.1)* | `checks/close.sh` (S1's read) | at each S1 report read whole | `<REQ id> TAB <pass\|partial\|facade\|absent> TAB <candidate>`: the newest grade of each requirement of stage N, by the candidate it was graded at; the end grade's (v0.26.10.27.4) holds every live requirement; `end.sh` reads the newest over every stage |
| `.vid/decide/completion.md` *(v0.26.10.27.4)* | `checks/end.sh complete` | each completion run, met or unmet (never `--check`) | the completion report, nine parts in develop's order, each line naming its evidence; complete only when its part 2 says so, and only then is RUN-STATE's `run: complete`; it is no production okay |
| `.vid/decide/close/<step>/<k>/` *(v0.26.10.25.3)* | `checks/close.sh` (`read` by `checks/results.sh close`; `withdrawn` and `reached` by `checks/land.sh`) | at the step's k-th ask and each decide | the step close's k-th ask: `ask` (its issue, commit, chunks), `again`, `items`, `read` (the results reader's chunk, row, split and engine lines), `chunks`, `rows`, `failed`, `acted`, `lined`, `fixes`, `result`, `numbers` (the three numbers after the first ask), `done`; *(v0.26.10.25.5)* `withdrawn` — a landing reopened the step; *(v0.26.10.26.7)* `reached` — the reached rows that withdrew it, one a line, gathered over the landings while it stays withdrawn; the close waits for the tickets holding them and is asked at their merge; *(v0.26.10.28.2)* a chunk DevAgent says lost on the issue, `vid: lost <chunk> <k>` at the current count of `vid: again <chunk>`, is `again` at once the first time and an `items` line `lost …` the second, with no quiet time; *(0.26.10.28.10)* `lostsig` — each lost attempt's unrun rows, `<chunk> <attempt> <signature>` (by engine and state, messages apart); `same` — the chunks lost as at the attempt before, one a line, for which a bare again is refused; `againwhy` — an owner's again's words, `<chunk> TAB <words>`, posted under its `vid: again` as `why:` and then dropped, as is its `same` line. The newest k is the step's newest ask |
| `.vid/decide/stage/<N>/<c>/` *(v0.26.10.26.1)* | `checks/close.sh` (the candidate, C3, S1, the okays and the staging run); `checks/walk.sh` (`w1/`); `checks/results.sh` (each `read`) | at each stage step | candidate c of stage N: `named`, `commit`; *(0.26.10.29.2, R2)* `withdrawn` (`<the landing, 12> <time>`, `checks/land.sh`: a re-cut changed the stage; its C3 is read no more, its S1 gets `s1withdrawn`, its D1 okay a `d1/closed` of `withdrawn by the landing <12> <time>`, and close.sh names a new candidate once one is due; *(FB-1 C3)* then an `issue <n>` line for each of those asks told and closed on GitHub, by land.sh in GitHub auto or by close.sh's reclose at a later owed, in GitHub manual once the apply holds the landing); C3's `ask`, `body`, `rows`, `chunks`, `packed`, `read`, `again`, `items`, `result`, `passed`, `done`; S1's `s1ask`, `s1body`, `s1read`, `s1done`, `s1again`, `s1withdrawn`, `findings`; `d1/` (*(v0.26.10.26.2)* staging's okay: `ask`, `read`, `passed`, `again`, `items`, `closed`, `door`; *(0.26.11.1.3, R3)* `ask` holds `real TAB <n> TAB <line>`, one for each real check the okay lists (stage 0's skeleton line, each `finding: real` line of its tickets), and `read` holds `real TAB <n> TAB done\|not done\|missing TAB <words>`, one for each), `cs/` (the staging run, as a close), *(v0.26.10.27.1)* `rh/` and `cr/` (the rehearsal and its run), `d2/` (the production deploy), *(FB-2 A4)* `dn-staging/` and `dn-production/` (a take-down okay: `ask` with `target`, `address` and the owner's `words`, for either target; `body`, `read` (`checks/results.sh deploy --kind dn`: `dn down <k>` and `down TAB <target> TAB <address>`, `dn failed <k> <why>` or `dn refused <k> <why>`), `again`, `done`, then `down` or `failed`, or `lost` (asked again once, after no report or a refused one posted back, and never reported after it: nothing taken down, the target free); an earlier one at that candidate moved to `dn-<target>-<j>`), *(v0.26.10.26.4)* `w1/` (the walk: `<s>/` a start with its `brief.md`, `pid` and `walk.txt`; `done`, `withdrawn`, `findings`, `items`, `again`), *(v0.26.10.26.5)* `summary.md` (the stage's summary, before its close) |
| `.vid/decide/grade/<n>/` *(v0.26.10.27.2)* | `checks/grade.sh` (`read` by `checks/results.sh grade`) | at an owner's grade ask and each step | `ask` (issue, commit, asked, reqs, deferred, vs, robustify, focus; tab), `body`, `read`, `grades` (REQ, word, reason, vs word, vs reason; tab), `findings`, `done`, `refused`, `again`, `allow`, `lost`, `withdrawn` |
| `.vid/decide/production` *(v0.26.10.27.1)* | `checks/close.sh` | appended at each passed D2 | `<commit> TAB <the D2 issue> TAB <UTC>`: production's commit, the newest line now |
| `.vid/decide/duties-known` *(0.26.11.1.1, R3)* | `checks/queue.sh answer` (the owner's `known` on a D1 duty not done); read by `checks/results.sh deploy` | appended, a line an answer | `<duty> TAB <the owner's words> TAB owner TAB <UTC>`: a staging duty the owner ruled a known limit of the project, whose `not done` a passed D1 may then say |
| `.vid/decide/real-known` *(0.26.11.1.3, R3)* | `checks/queue.sh answer` (the owner's `known` or `row` on a real check not done or missing, its D1 refused twice); read by `checks/results.sh deploy` | appended, a line an answer | `<issue>-<n> TAB <the owner's words> TAB <who> TAB <UTC> TAB known\|row`: a real check of a staging okay the owner ruled a known limit of the project, or a new row for /vid fix; a passed D1 may then say it `not done` or leave it out |
| `.vid/decide/tmp.*` | `checks/decide.sh` | while it runs; removed at its exit | working state, never saved |
| `.vid/results/pr-<p>-<head12>.txt`, `.html` *(v0.26.10.24.5)* | `checks/results.sh read`; `page` (the `.html`, by `checks/page.sh --out`) | at each head read | the evidence for that head: report lines, then a tab-separated line per row or transition (row, kind, red, t3, fault, reason), the grades' findings, `open grade line:` lines, `finding: note` lines, a fault folder for no row, and the head report's engines, environments and retested — what decide.sh decides from |
| `.vid/results/stand-in-pr-<p>.txt`, `.vid/results/stand-in.txt` | `checks/results.sh read` | rebuilt at each read | `<head12> TAB <the line>`: every head report's stand-in lines, by pull request and all of them, each once |
| `.vid/results/tmp.*` | `checks/results.sh` | while it runs | working state |
| `.vid/run-state.lock` *(0.26.10.28.4)* | `checks/lib.sh` (`rs_edit`, the run record's one writer on the ticket side) | while a writer rewrites RUN-STATE.md | **a lock, never a record:** a folder naming its holder in one file, `h`: `<pid> <start>`; a dead holder's is taken over. `.vid/decision-ids.lock` is the same lock (`checks/decisions.sh`, 0.26.10.28.4) |
| `.vid/round/` *(v0.26.10.25.1)* | `checks/round.sh` (`read`, round-read's lines), `checks/close.sh`, `checks/grade.sh`, `checks/queue.sh`, `checks/walk.sh` (their working files and `stg.*`, `walk.*` folders) | each step | **local scratch, never saved:** `read` holds the newest read of GitHub (`open <p> <ticket> <head> …`, `merged <p> <ticket> <head> <merge>`, `issue <n> …`, *(v0.26.10.28.2)* `main <commit>|none|absent`, tab-separated); *(v0.26.10.28.2)* `code-main`, `checks/github.sh` round-read's last good read of main, given again when a read fails, and `code-url`, the address it reads, dropped when a read fails; every other file is a working file. Nothing outside the round reads it as a record |
| `.vid/round-errors` | `checks/round.sh` | at each failed step | the count of the round's errors running, beside each `round-error` event |
| `.vid/code` *(v0.26.10.24.5; the first mode's since 29)* | `checks/github.sh results-fetch` (and `state-restore`, through it); the first mode cloned it too | at each fetch | the copy `checks/results.sh` reads: the `vid-results/*` reports, and every other head's commits (0.26.10.28.4: no file of the code, below); not a record. The first mode's vid-replan read code commits there (`git -C .vid/code …`; old ticket mode, removed in 0.26.10.28.1). *(0.26.10.28.1, S5)* A working clone found there, the first mode's, is moved aside to `.vid/code.old-<UTC>` and the bare copy cloned; a ticket-mode export leaves both out. *(0.26.10.28.4, M5)* It holds no file of the code: a partial copy (`extensions.partialClone=vid-commits`, no stored address, HEAD on the unborn `refs/vid/none`), the `vid-results/*` branches each its newest commit and its folder (`--depth=1`), every other branch and pull-request head with no tree (`--filter=tree:0`); proved at each fetch, else removed and refused; a copy in the earlier full form is replaced |
| `.vid/pages/<name>.html` *(29)* | `checks/page.sh` (`planner.sh page`'s `PLAN-PAGE.html`; the first mode's pages) | at each render | a page rendered from its markdown, which stays the record; one file, offline. A page rendered with `--out` lands where it says |
| `.vid/state-at` *(v0.26.10.25.1)* | `checks/github.sh state-save`, `state-restore` | at each save or restore | the commit of the state repository's `vid-state/records` this home's records equal; a restore is skipped while it matches |
| `.vid/lock-session` *(v0.26.10.25.1)* | `checks/github.sh lock-take`; removed by `lock-free` | at the lock's take | the session id holding the run's lock (`vid-state/lock` of the state repository) from this checkout |

### The pre-publish releases' records *(34)*

Added by 0.26.10.28.1 to 0.26.10.28.8, after the ticket flow's files above; each item names its release.

- **`.vid/round/wait`** *(0.26.10.28.6)*, `checks/round.sh wait`: while a wait runs, `start=<epoch>` and `max=<seconds>`; removed at its
  end. The watcher counts a wait that has started and not ended, within its limit and a margin, as activity.
- **`.vid/round/code-results`** *(0.26.10.28.6)*, `checks/github.sh round-read`: `<id> TAB <commit>`, one line each `vid-results/*`
  branch, from the same read of the code repository as its main; round-read prints them as `result <id> <commit>`.
- **The dev side's stopped report** *(0.26.10.28.6)*: a `vid-results/stopped-<k>` branch on the code repository holding
  `stopped-<k>/results.txt` (`by: DM`, `stopped: <why>`, `at:`), in docs/RESULTS-FORMAT.md. ViD's flag for it is the alarm word
  `devagent-stopped` (a `flag` and later a `flag-cleared` event, `on=stopped-<k>`, and a line of `.vid/decide/flags`).
- **`.vid/decide/stage/<N>/<c>/w1/none` and `w1/limit`** *(0.26.10.28.6)*, `checks/walk.sh` and `checks/queue.sh`: no walk owed (the
  product has no screens), or the owner's close without the walk (`limit`: its words, then who answered and when), which the end
  report lists as a known limit; the events `walk-none` and `walk-limit`.
- **`.vid/tw/log`'s `withdrawn <n> decision=known-limit rows=<rows>`** *(0.26.10.28.6)*, `checks/github.sh tw-close`: a fix ticket whose
  rows were all ruled known limits, withdrawn.
- **`.vid/tw/log`'s `handover <n> pr=<p>[,<p>…]|- rows=<rows> at=`** *(0.26.10.29.2, R3)*, `checks/github.sh tw-handovers` (before the round or a hand-call writes any ticket), else `tw-close` and `tw-post --amend`:
  the rows a plan change took out of ticket n, withdrawn (every row of its newest writing, `pr=` its open pull requests or `-`), or
  amended while a pull request naming it is open (the rows it lost). The ticket the writer next writes holding any of them names n in its
  header, `- earlier work: ticket #<n>[, pull request #<p>]`, until a later published or amended ticket has carried that row. A
  withdrawn ticket's pull request is never decided again (checks/round.sh), and its withdrawal comment, on the issue and on each open
  pull request, names the change's why and where each row went (`checks/writer.sh where <n>`).
- **`.vid/tw/log`'s `withdrawn <n> decision=<D> kept=<step>` and `told <n> limits=<rows> at=`** *(0.26.10.29.2, R11)*, `checks/github.sh
  tw-close` and `tw-tell`: a step or skeleton ticket withdrawn because more than half of the rows it held at its last writing are gone or
  replaced, its step kept, which the writer counts as never sent (as a closed-outside one), so the step's kept rows go out in a new
  ticket naming it; and a fix ticket whose every row was ruled a known limit while a pull request names it, told so once and left to
  merge as it is. A ticket's `.meta` gains `tell <line>` lines at an amendment, its cause and each row added, removed or changed by id
  and promise, which `tw-post --amend` posts on the issue and each open pull request.
- **`.vid/shares/<run>.summary` and `.vid/shares/<run>.known`** *(0.26.10.28.7)*, `checks/share.sh build`, beside the bundle
  (`.vid/shares/<run>/`, in the table above): the summary, one item a line (`folder` relative to the project, `size`, `part`,
  `redacted`, `left-out`, `missing`, `split`, `scan`, `limit`), what `/vid:vid-share` shows; the known personal values the scan
  needs, mode 600, never in the bundle and never sent.
- **DECISIONS.md's `| origin: dev-side`** *(0.26.10.29.5, DP-1 R2)*: a decision the dev side made, recorded by `checks/decisions.sh
  record` from a merged pull request's Decisions section (`| enforced: ticket <n> |` and its label) or a passed deploy report's
  `decision:` lines (`| enforced: deploy <id> | scope: project`), in the dev side's words; in ticket mode the pre-commit hook's
  ledger-path test does not read such a line, which its ticket or deploy ref enforces.
- **DECISIONS.md's `| about: vid-settings` mark** *(0.26.10.28.5)*: beside a decision's label, a decision about ViD's own settings,
  which no ticket quotes (vid-init records its budget with it).
- **The recorded GitHub mode** *(0.26.10.28.8)*, `checks/planner.sh setup github-mode`: `.vid/tw/settings`' `github-mode:` key and its
  `setup-answered key=github-mode` line in `.vid/plan/setup` (their rows above), the owner's answer, GitHub auto or GitHub manual (FB-1 C1: an old `team` answer, retired, is refused at the connect); and
  `queue-answered`'s `by=delegate` and `by=stand-in` (its row in the Events table).
- **`.vid/run-state.lock`** *(0.26.10.28.4)* and the event **`round-main-changed`** *(0.26.10.28.2)*: listed with their own rows.

### DESIGN-BRIEF.md

The ```` ```vid-design-manifest ```` block, one row per surface × state:
`<screen> | <state> | REQ-NNN,REQ-NNN | pins: …`. The marker is
`<screen>/<state>`.

### STAGES.md *(25)*

Present only for a project delivered in stages (none: one stage). The
```` ```vid-stages ```` block, law (`checks/lawfiles`), one line each:

    STAGE-<n> | <name> | features: FEAT-a FEAT-b …     one per stage, numbered 1..k; `features: -` for a stage fed only by split: lines
    STAGE-0 | <name> | technical                      (28) the technical stage 0, the walking skeleton: rows only, each placed by a row: line; stages then run 0..k; added or removed only by the commit creating STAGES.md
    split: REQ-x REQ-y -> STAGE-<n>                  a split feature's requirements placed in another stage
    row: <ROW|RULE|DIF|EXC|SUP>-x -> STAGE-<n>        a row placed: a ROW whose requirements span stages, or a census row later
    needs: FEAT-a needs FEAT-b — <source>            an ordering edge, with its source
    rules: by-origin                                 (0.26.10.29.4) at most once: census rows placed by their origin (below); written by vid-stage only while no stage is closed or deployed, kept as it stands by a later re-cut

What gets which stage: a requirement or invariant its feature's (a
`split:` line overrides), none when `phase: later`; a ROW its items'
when they agree, a `row:` line when they don't, stage 1 with no item
(*(28)* stage 0 only by a `row:` line; its rows' requirements keep their
own stages); a
census row (RULE, DIF, EXC, SUP) stage 1 unless placed (*(0.26.10.29.4)*
with `rules: by-origin`, the earliest stage of the PRD items its `origin:`
names; stage 1 still when it names none, when they are all `phase: later`,
and for a Tier-0 rule row; a `row:` line first); a HOS row the
stage of what its `protects:` names. Around the block, one card per stage
in plain language (no reader parses them). A stage's close is tagged
`vid/stage-N` (annotated, at the commit `stage-closed` names; a tag never
moves). *(27)* While the owner holds the next stage, each production
deploy of a correction to stage N is tagged `vid/stage-N.k` (k = 1, 2, …;
annotated, at the commit its `deploy-check target=production` record
names): a supersession of stage N's candidate. `vid/stage-N` never moves;
the newest of `vid/stage-N` and `vid/stage-N.k` is stage N's candidate.
*(28)* The final stage (the highest number) is closed and tagged
`vid/stage-k` too; `vid/stage-0` is stage 0's, which goes to staging and
never to production.

### ARCHITECTURE.md's vid-hosting block *(28)*

Where the product runs, recorded at init by `vid-staging-setup` Part 1
(and by vid-deploy, for a project made by an older init), one `key: value`
line each inside a ```` ```vid-hosting ```` fence — not a table, so the
seam table's readers never see it: `platform`, `region`, `staging`,
`production`, `sending`, `spend-cap`, `access`, `dns-access`, `owner-only`
(the steps left to the owner's hands, each named), `providers` (each
outside service: `live-restricted` or `fake` on staging). `access:` and
`dns-access:` take only `cli-login <platform>` (the word equal to
`platform:`), `env <NAME>` (NAME `[A-Z_][A-Z0-9_]*`) or `none`; never a
credential. A later answer updates its key in place. Read by
`vid-staging-setup` Part 2, the build-out of staging and production.

### .vid/SLICE-REPORTS.md

Sections, newest last; **the newest section is current**:
- `## slice <N> <UTC>` — vid-develop at each slice close;
- `## fix <UTC>` — vid-fix at its final report;
- `## deploy <UTC>` — vid-deploy at its report; *(27)* a staging deploy's
  opens with one line, `staging runs <commit>, <k> commits past the last
  full pass <sha>`;
- *(25)* `## stage <N> <UTC>` — `checks/metrics.sh stage-close --record` at
  a ready stage close: counts only — what stage N holds (requirements,
  rows, hostility probes, rule rows), the full run's cases for stages 1 to
  N and the rows kept, the deploy debt with what each owed row needs, the
  pull-forwards, open questions, and what stage N+1 holds. It holds no
  ```` ```vid-metrics ```` block.

Each section holds `sh checks/metrics.sh`'s ```` ```vid-metrics ```` block,
whose first line is the rows headline —
`rows: kept K · unverdicted U · breached B · red R · owed O · deploy-owed D (unmet …)`,
or `rows: receipt: none — materialised rows unverified · …` when no
current full report exists — and the five closure lines, each unmet row
exactly once:

    closure contract-ambiguity n=<k> <ROW-id> …
    closure invalid-test-evidence n=<k> <ROW-id> …
    closure unfinished-implementation n=<k> <ROW-id> …
    closure deploy-owed n=<k> <ROW-id> …
    closure later n=<k>

A row named in none of the first four is met. A section written before
this contract may carry the block without a heading.

*(2)* Under a 0.9.6 develop run a slice section also carries `sh
checks/testenv.sh leftovers`' lines — `leftover <what> (<age>)`, one per
container, dead run folder, merged worktree or undone operation the
project still has, then `leftovers n=<k>` — and `metrics.sh completion`
counts each leftover as a strict gap, listing it `leftover …` after the
closure.

*(3)* Under a 0.9.6 develop run a slice section closed on a selected close
also carries the close's lines, as `checks/metrics.sh` prints them:
- from `close-rows --steps <ids>`: `base step=<id> commit=<sha>
  from=step-start|brief|step-start-time` (the commit each closing step's
  diff starts from), one `required row=<id> set=<1–5> step=<id>` per row
  the close had to run (a hostility probe as `step=-`; *(15)* `sets=<n,…>`
  every set the row is in, then `phase=1|2` — 1 when a set is 1, 4 or 5),
  `note <text>` for
  each note of the rows file, and `close-rows steps=<ids> required=<n>`;
- from the claim: `claim row=<id> why=unverdicted|breached|re-paid`,
  `held row=<id> reason=<r>` (*(8)* `scope` and `rounds` join `bound`,
  `test` and `harness`), `provisional row=<id>` after the claim line
  of a row whose cases no checkpoint or full run has yet run whole, and
  `claim rows=<n> held=<h> provisional=<p> from=<report> to=<report>
  steps=<ids>` (*(15)* by batch: `claim rows=<n> held=<h> provisional=<p>
  from=<batch ticket|receipt|none> batch=<ticket> steps=<ids>`, refused
  also with `not-run chunk=<n> — …` and `mixed tree chunk=<n> report=<r>
  — …`); a refused claim prints instead `not-run row=<id>
  case=<case id>` (`case=-` when a provisional row has none) and
  `failed row=<id> case=<case id>`, and no `claim` line.

*(3)* Under a 0.9.6 develop run with two or more proved test environments,
the ```` ```vid-metrics ```` block carries `checkpoint due n=<1|2>
built=<b> plan=<p>` while a checkpoint is due and not yet recorded (the
built rows — of closed steps, not owed, held or `later` — have reached a
third of the plan's rows for checkpoint 1, two thirds for checkpoint 2
after a checkpoint 1 that found a regression — *(15)* whatever checkpoint
1 found); the progress update's
Tests cell shows the same line.

### .vid/RUN-STATE.md

Keys first, one line each, then the session's own prose:

    run: active|waiting|stopped <reason>|complete    (27) `stopped owner asked to hold after stage N`, written by `metrics.sh stage-close --record` under a hold
    session: <the id of the session running the build>
    questions: <k> open · next Q<m>        (or: - · next Q<m>)
    slice: <N> open|closed    since: <UTC>    commit: <sha>     (slice: - before the first)
    modules: <paths>
    claims: <ROW-id> …
    receipt: <report name>|none    briefs: <files>|-
    held: <ROW-id> …|-
    plan: required                          (2) written by 0.9.6 develop at its start
    plan: skeleton                          (29) while develop builds the code skeleton (vid-skeleton): the gate off
    mode: tickets                           (29) written by /vid plan: the planner's run; develop refuses it
    now: <one line>|-                       (2) the build's own words, `checks/progress.sh --now`
    strategy: depth-first|breadth-first     (17) absent: depth first; written only by `checks/plan.sh strategy … --by owner`
    stage: <N>                              (25) only with STAGES.md: the stage being built; 1 at develop's start, N+1 written by `metrics.sh stage-close --record`; (28) 0 at develop's start with STAGE-0; the final stage's close sets none; (30) k+1 written by vid-add right after the placement commit that opens STAGE-k+1 after the final close

- `run:` — `active`; `waiting`: everything left depends on an open
  question; `stopped <reason>`: genuinely blocked, or `stopped owner asked
  to pause`; `complete`: written only by `metrics.sh completion --record`,
  when the computed claim is complete. A file written before 0.9.5 has no
  `session:` or `questions:` and only `active` or `complete`.
- `plan: required` *(2)* — a develop run under a 0.9.6 plan. With it, `run:`
  active or waiting, and a develop stage the newest started, the run's
  gate is on (`sh checks/plan.sh gate`): its test runs are frozen and kept
  by run, below. A file without the key is a 0.9.5 run, read as before.
- **The plan** *(2)* — the section `## The plan` holds one fenced
  ```` ```vid-plan ```` block, a line per step and one `shared:` line:

      step <id> | name: <plain words> | modules: <path prefixes> | builds-on: <ids or -> | rows: <ROW ids, ROW-a..ROW-b ranges> | lane: orchestrator|builder [| kind: hardening]
      shared: <paths every step depends on>
      protected: <ROW ids, ROW-a..ROW-b ranges>      (17) optional, one line, only grows

  *(17)* `kind: hardening` marks a step that holds edge rows under breadth
  first (nothing builds on it); absent, a feature step. `protected:` names
  rows designated protected beside those `checks/inventory.sh protected`
  derives; a change may add an id, never remove one. Under depth first both
  are read and kept, and inert.

  Its hash (12 hex) is the sha256 of the block, trailing space trimmed;
  the newest `plan-change` event names the hash in force. A row belongs
  to one step; `name:` is what the progress update shows.
- **The run's home** *(2)* is the worktree whose `.vid/RUN-STATE.md` holds
  the run — Git's main checkout or a linked worktree. A builder worktree
  names it in `.vid/home`. *(5)* `sh checks/plan.sh home-of` prints it:
  this worktree when it holds `.vid/RUN-STATE.md`, else the path its
  `.vid/home` names, else the one checkout of the repository (`git worktree
  list`) whose run is live — a develop run in progress. With two or more
  live runs and no `.vid/home` there is no home (exit 3) and a test run is
  refused; outside a live run a worktree's records stay its own.
- **The open questions**, in the section `## Open product questions`, one
  line each and nothing else:

      - Q<n> · asked <UTC> · gates <rows | modules | all remaining work> · <the question, one plain sentence>

  A line is deleted when its answer lands in the PRD; `questions:`'s count
  equals the lines.

### .vid/PROGRESS.md *(2)*

A header line, then one section per update, newest last:

    ## <UTC to the minute> — progress (hourly|plan-change|session)

    | | |
    |---|---|
    | Passing | <k> of <n> steps passing: <names>. <P> rows passing |      (17) was "Done"
    | Debt | <n> rows owed — in hardening, not done <a> · passing, not KEPT <b> (never graded <b1> · product breach <b2> · test or harness breach <b3> · journey part-graded <b4> · re-grade after amendment <b5>) · held <h> (with their questions: <Q ids>) · deferred open <d> |   (17); under depth first: <b> rows owed — passing, not KEPT <b> (…)
    | Closed, not graded | <step> (<k> rows), … — … |      (17) breadth first, when any
    | Hardening | <n> rows in <k> steps |      (17) breadth first, once every feature step is done
    | Now | <step name> (<lane>): <x> of <y> rows passing · … |
    | Left | <steps not started>. <rows> rows not yet passing (<r> red, <v> never run[, <u> not in the plan]); blocked: <b> (…). Apart: <d> checked at deploy, <l> later |
    | Tests | <busy> of <stacks> environments busy · red by where it stops: setup <s>, failed <f> |
    | Builders | … |
    | Builders at once | <now> open · target <t|none> · last 6 h average <x> |      (17)
    | Rows passing | closed: <step> <h> h, … (includes regression checks) · open: <step> waiting <h> h, … |      (17) when a step has step-rows-passing
    | Refused commits | <n> — <court> <k> (<rule> <j>, …) · … |      (18) when any, from court-refused
    | Your questions | <k> open — Q<n>: <question> (holds <what>) |
    | Estimate | <lo>–<hi> h to the last row passing, at <a>–<b> rows/hour (<how>). Not included: … — or "no estimate yet", or "no estimate: no rows turned green in the last 3 h" |
    | Plan changes since the last update | <what> — "<why>"; … |
    | Now (the build's own words) | <RUN-STATE now:> |

Steps show by their `name:`, questions by their sentence; no row ids,
paths or court names. The format is VID's (`checks/progress.sh`).

### .vid/HEARTBEAT.md

A `# Heartbeat` header, then lines `- <UTC> | <text>`, newest last. A line
whose text starts `observe: ` is the observer's; every other line is the
session's, written through `checks/watchdog.sh` (declare, re-declare,
check, claim, done, note). *(12)* A notice for the owner is the observer's
line `observe: notice — <text>`, once per condition until it clears;
nothing is sent. The tick's activity line reads `observe: run activity
<s>s ago (<source>) · last commit <g>s ago · run: …` (the source: events,
commit hooks, heartbeat, git or `agent <id>`), or `observe: run activity:
none recorded · …`.

### .vid/hook-times

One line per commit attempt, newest last:

    hook result=pass|refused|killed seconds=<total> placement=<s> conformance=<s> imports=<s> seams=<s> inventory+census=<s> design-cite=<s> prd=<s|memo|-> harness=<s> selftest=<s|memo|-> redstamp=<s|-> [by=<names>] [checkout=<name>] at=<UTC>

- `result=pass` is the pre-commit hook's verdict; the message check that
  follows can still refuse the commit. `killed`: the hook was interrupted.
- *(2)* `redstamp=` — the red-stamp check's seconds (a commit staging
  INVENTORY.md inside a 0.9.6 develop run), `-` otherwise.
- *(4)* `by=` — on a refused line only: what refused, the same names as
  the `refused` event's `by=`.
- *(14)* `checkout=` — a commit attempt in another checkout than the run's
  home (a builder's worktree) writes its line at the home, naming that
  checkout's folder; a line without it is the checkout's own (the home's,
  or any with no live run).
- A court field is `-` when the court did not run (absent, or the hook
  stopped earlier), `memo` when its memo skipped it; the courts run side by
  side, so the fields add up to more than `seconds=`. From 0.26.10.12.1
  `selftest=` times the project's own cases only and is never `memo`.

### .vid/SUMMARY.md

A header comment and `# Slice summaries`, then one section per closed
slice, newest last, in the owner's words (no row ids; decision ids only):

    ## <UTC> — slice <N>

    - **Working now:** <features and journeys that now pass>
    - **Went back:** <what stopped working, or "nothing">
    - **Decided for you:** <each decision VID took for the owner, with its id>

### .vid/test-lessons.md *(20)*

Written by the run manager after a confirmed weak test with a new cause;
one entry each, no blank line inside it: `## L-<n> · <UTC date> · from
ROW-<id>`, then `helpers: <paths, comma-separated, or none>`, `rules: <REQ,
RULE or ROW ids>`, `bad:`, `why:` and `good:` lines. Test-author briefs
quote the entries matching their rows (`## 17 lessons`), whole.

### Briefs — .vid/briefs/<N>/ *(20, the new ones)*

*(29)* A ticket — a builder or fixer brief written with `brief.sh write
--ticket` — carries `ticket: pending` (the issue's number is kept in
`.vid/tickets/map`), `base: <the code repository's commit>` and `return:
pull request`, no `first act:`, the plan's `shared:` line in section 10, and
a `## 16 ticket` section: `stage: <n>    step: <id> — <name>`, `modules:`,
`shared:`, `base:`, then `### Acceptance tests` (each file whole under
`#### <path>`, fenced), `### Design screens`, `### Instructions` and `### The
return block (vid-return 1)`. *(31)* Once the vid-code block names
`run-full:`, a `### CI scope` before the instructions: `selector: <the
--selection>`, then one `<ROW-id> <test path> ticket|alarm` line per row —
the ticket's rows citing a test, and the journeys, shell and reachability
rows of merged tickets — and the return block's `ci-scope: <the selector>`. A ticket's hand-back is
`<role>-<n>.return.md`, written by `ticket.sh import` from the block (old ticket mode, removed in 0.26.10.28.1).

A grader brief's patches,
one per row in proof scope, in `grader-<n>.faults/<ROW-id>.patch`, and its
return's `fault: ROW-<id> | target=<case> | control=<case> | patch=<path>`
lines.

### Receipts — .vid/ledger-results/

*(29)* A CI receipt, ticket mode: `<code sha, 12>.ci-<run>-<attempt>.xml` —
the dev team's JUnit XML report, imported by `checks/ticket.sh import` (old ticket mode, removed in 0.26.10.28.1) —
with `.cases` (`case <test path>::<name> <status> <seconds>`) and `.rows`
(the rows it was imported for) and no `.tree`; its `ledger-run … type=ci`
event names the run. Readers take its cases from `.cases`; a grader brief
credits its `.rows`; no reader resolves its commit in ViD's repository.

The runner's own per-case results report, renamed by `checks/test.sh` only
when the run ran to its end: `<sha>.full.xml` (the whole ledger on an
export of commit `<sha>` — certifiable), `<sha>.deployed.xml` (its
deployed-shape pass), `<sha>.live.sel-<hash>.xml` and
`<sha>.live.deployed.sel-<hash>.xml` (scoped runs, never certifiable). The
content is the runner's format; the progress a reader needs is already in
SLICE-REPORTS.

*(2)* Inside a 0.9.6 develop run every run tests a frozen copy of a git
tree and is kept under a name no later run reuses, at the run's home:
`<sha>.run-<id>.full.xml`, `<sha>.run-<id>.deployed.xml`,
`<sha>.live.sel-<hash>.run-<id>.xml` and
`<sha>.live.deployed.sel-<hash>.run-<id>.xml` (`<sha>` is HEAD when the
run froze; `<id>` the run's start time and pid). `<sha>.full.xml` and
`<sha>.deployed.xml` are then copies of the newest kept one, so a reader of
1 reads them as before; an event names the kept receipt, never the copy.
Beside each kept receipt:
- `<receipt>.tree` — `tree=<the git tree tested>`, `base=<the commit it
  was frozen on>`, `frozen-at=<UTC>`, `shape=inline|deployed`;
- `<receipt>.cases` — the results reader's `case <id> <status> <seconds>`
  lines;
- *(14)* `<receipt>.rows` — a request's receipt only (a full run has
  none): the rows the request was frozen with, one per line, written
  before the receipt and copied with it to its commit-named copy. The
  receipt credits only these rows; a row its cases reach outside them is
  not credited. *(15)* A chunk's receipt carries its chunk's rows; a
  checkpoint's, its population (the rows of closed steps and the
  materialised probes). *(27)* A `staging` request's carries its change
  set whole (ROW, census and HOS ids).

*(27)* **A request's home outside the gate.** Whenever `checks/plan.sh
home-of` resolves — a checkout holding `.vid/RUN-STATE.md`, or one whose
`.vid/home` names one — a request's ticket is at that home, and its run is
frozen and kept as inside a run: the names above with `.run-<id>`, the
`.tree`, `.cases` and `.rows` beside them, its `ledger-run` event at the
home. A direct `sh checks/test.sh` run outside the gate is unchanged.

*(3)* Inside a 0.9.6 develop run, a **selected close** (`sh checks/test.sh
--role close -- <selection>`, v0.9.6.1) is export-backed like the full
run and kept as `<sha>.run-<id>.close.xml`, with its deployed-shape pass
`<sha>.run-<id>.close.deployed.xml` when the harness declares one;
`<sha>.close.xml` and `<sha>.close.deployed.xml` are copies of the newest.
It holds only the rows the caller selected: a row absent from it keeps
its earlier result. A **checkpoint** (`sh checks/test.sh --role checkpoint
-- <selection>`) takes the same path, kept as
`<sha>.run-<id>.checkpoint.xml` and `<sha>.run-<id>.checkpoint.deployed.xml`,
with the copies `<sha>.checkpoint.xml` and `<sha>.checkpoint.deployed.xml`;
it runs every built row once, and tests the commit `<sha>` it was frozen on
— work committed while it ran is not in it. Under a develop run, a result
is ordered by the commit its receipt tested (its `.tree`'s `base=`): a
descendant's beats an ancestor's, whenever each was published.

*(20)* A **proof's** runs (`--purpose proof`, the run manager's
`prove-red` or `deployed` from a proof worktree) are kept as
`<sha>.proof.sel-<hash>.run-<id>.xml` and
`<sha>.proof.deployed.sel-<hash>.run-<id>.xml` (`<sha>.proof.sel-<hash>.xml`
outside a develop run), their `.tree` adding `purpose=proof`. They are no
ordinary receipts: no reader that credits, claims, briefs, estimates or
triggers reads them (`sh checks/evidence.sh ordinary <receipt>` exits 1),
no copy or alias is ever written for them, and their `ledger-run` events
stand for cost and export.

`.vid/ledger.lock` is written only outside a 0.9.6 develop run; a reader
of who is running looks at it and at the live run folders
(`.vid/runs/*/holder`).

## Events

`.vid/metrics-events`, one line per event: `<type> <fields> at=<UTC>`.
Every type written is listed here; `checks/selftest/cases/records-drift.sh`
fails when code or a skill writes one that is not. *(33)* It also fails on a
listed type no writer writes, a field written but missing from its row's
fields cell (the keys of its code spans), and a field listed that no writer
writes — the last two unless marked *(not written from <version>)*, on the
row's writer or when cell for a type, right after the key's code span for a
field. A writer that builds keys or a type at run time names them in a
`# fields: <key>= …` comment on its line.

| type | fields | writer | when |
|---|---|---|---|
| `adjudicated` | `class=<name> promoted\|advisory\|deleted tp=<n> fp=<n>` | vid-develop | a report-only class decided at the first slice close |
| `agent-returned` | *(16)* `role=<role> n=<n> try=<try\|->` *(21)* `agent=<the return's agent id>` | `checks/brief.sh return` | a builder's or fixer's return passes the check, once per brief |
| `brief-written` | *(16)* `path=<brief> role=<role> try=<try\|-> bytes=<n>` | `checks/brief.sh write` | each brief written |
| `builder-tool` | *(16)* `set=<claude\|codex> by=owner`, or `paused reason=codex-limit reset=<time\|unknown>` | `checks/job.sh` | the owner switches the builders' tool; Codex runs out |
| `decision-labels` | *(18)* `applied=<n> widened=<n> changed=<n> skipped=<n>` | `checks/decisions.sh apply` | the labelling pass applied: labels written, of them written `scope: project` because the labeller was unsure (or the proposal could not be used), decisions changed since their proposal (left unlabelled), proposals skipped |
| `delegated` | *(19)* `answer=<A-id>` | `checks/metrics.sh delegated` | vid-develop marks an answer it wrote under the owner's delegation, before its commit (0.26.10.29.3 R2; before it, in the step that commits it), and once at the first session after the 0.9.7.4 refresh for the answers taken before; refused for an id not in the PRD's effective answer ledger, an answer of tier `model_proposed`, an id already marked, and (0.26.10.29.3 R2) an answer that a withdrawn arm of any item row, superseded or not, cites (`arms:` … `withdrawn <A-id>`), and an answer whose effective row lacks `delegated: yes`; the mark says how an answer was made, never when |
| `deferred` | *(17)* `row=<ROW-id> kind=product\|test why="<one line>" from=brief:<path>#<row>\|receipt:<name> by=<who>` | `checks/metrics.sh defer` | under breadth first, an edge finding — a row in a hardening step with an eligible BREACHED verdict — waits for its step; never a core or protected row |
| `deferred-resolved` | *(17)* `row=<ROW-id> by=commit:<12 hex>\|verdict:<brief>` | `checks/metrics.sh defer-resolved` | an open deferral's disposition — never a verdict |
| `context-high` | *(16)* `n=<tokens>` | `checks/brief.sh write`, `return` | the run manager's context is above 350000, once per crossing (none since its session's latest `session` event) |
| `context-window` | *(16)* `requested=<n>\|declined` | vid-develop, vid-init; *(v0.26.10.26.7)* `checks/queue.sh` (ticket mode's `context:window` question) | the owner answers the compaction-setting question |
| `continuation-restored` | *(16)* `try=<the successor's> from=<the package's>` | `checks/brief.sh restore` | a package restored |
| `continuation-saved` | *(16)* `try=<try> files=<n> bytes=<n>` | `checks/brief.sh save` | a package published |
| `continuation-superseded` | *(16)* `try=<try>` `[why=<…>]` *(not written from 0.9.7.1)* | vid-develop | the run manager drops a package it will not restore |
| `job-cleaned` | *(16)* `try=<try>` | `checks/job.sh clean` | every cancelled ticket of the job is terminal |
| `job-exit` | *(16)* `try=<try> exit=<n> reason=exit\|stopped\|codex-limit` | `checks/job.sh run` | the supervisor reaps its Codex process |
| `job-recovery-required` | *(16)* `try=<try> reason=no-identity\|group-remains` | `checks/job.sh stop` | a dead supervisor's job can't be confirmed gone; nothing saved, the worktree kept |
| `job-start` | *(16)* `try=<try> step=<id\|->` | `checks/job.sh start` | a Codex builder's job is recorded |
| `job-stop` | *(16)* `try=<try> saved=yes\|no [reason=not-launched]` | `checks/job.sh stop` | a job stopped, its work saved and its tickets cancelled |
| `manager-cost` | *(16)* `calls=<n> input=<tokens> since=<the previous manager-cost's at\|-> return=<file>` | `checks/brief.sh return` | once per return file, from the run manager's own session's transcript |
| `takeover` | *(16)* `started reason=<cause> scope=tests\|commits\|both`, or `ended fix=<what was fixed>` | vid-develop | the run manager takes a builder's tests or commits, and gives them back (at the latest when the next step starts) |
| `ticket-cancelled` | *(16)* `ticket=<id> try=<try> by=<who>` — *(21)* `try=` empty for a ticket with none, cancelled by `cancel --ticket <id>` | `checks/test.sh cancel` | a ticket of the try marked cancelled, once |
| `agent-death` | `slice=<N> <which>` | vid-develop | a spawned agent lost |
| `analyst-done` | *(7)* `request=<ticket> reason=cap\|setup\|slow outcome=setup\|hang\|limit\|none [rows=<ROW-id,…>] [cases=<case id,…>]` — `rows=` and `cases=` from the return's `limit:` lines; *(14)* `[owner=no]` when every limit line says `prod: n/a` (a setting only the test has: the test author's, no owner question) | the conductor: vid-develop, vid-fix (`vid-test-manager`) | the test analyst returned; an `outcome=limit` naming a slow case's row or case id stops that case from triggering again |
| `analyst-due` | *(7)* `request=<ticket> reason=cap\|setup\|slow [rows=<ROW-id,…>] [cases=<case id,…>] [group="<first message>"]` — `rows=`/`cases=` the slow cases, by row when the evidence join credits one, else by case id; *(15)* a close batch's chunk as `request=<ticket>/<n>`; *(21)* `group="<message> (<n> case[s]); …"` — the groups of the red cases over 60 s that tripped the setup trigger, each with its count; *(24)* a capped run's `stop=silent\|startup\|limit last-output=<UTC>` after `reason=cap` | `checks/test.sh` | a request's completion, after `result` and before the final `state`, once per trigger that fired: capped (*(21)* not when the host slept during the run; *(24)* on any of the watcher's three reasons); 5 or more red cases each over 60 s; a case over 240 s |
| `agent-start` | *(4)* `session=<session id> agent=<agent id> type=<agent type>`; *(9)* `transcript=<the parent session's transcript, as the hook receives it>` last, before the time — the agent's own is `<it without .jsonl>/subagents/agent-<agent id>.jsonl` | the plugin's `hooks/record.sh` (Claude Code's SubagentStart) | an agent starts; a resumed agent starts again under the same id; its brief, role and step are joined at export, never here |
| `agent-stop` | *(4)* `session=<session id> agent=<agent id> type=<agent type> transcript=<the agent's transcript path>` | the plugin's `hooks/record.sh` (SubagentStop) | an agent stops; no "accepted" status is recorded |
| `build-cost` | *(10)* `role=<builder\|fixer> slice=<N> step=<id\|-> brief=<path> rows=<n> rows-passed=<k> peak=<t> total=<t> before-change=<t\|unknown>[ shell]` — tokens of the agent's own transcript: per API call input + cache read + cache creation, the largest and the sum; before-change the call that made the first product mutation under the step's modules, ` shell` when only a shell call could have (possible, not proven); `unknown` when the transcript is not found *(16)* then `tool=claude\|codex model=<m\|unknown> effort=<e\|unknown> brief-bytes=<n>` — the effective model and effort from the agent's transcript (Codex: its job record); for a Codex builder the tokens are read from its events file by their own reader (`turn.completed` usage, summed per turn), `peak=unknown` (an exec is one turn, so no call's context is readable), `before-change=unknown`; for a grader, test-author or analyst (`sh checks/brief.sh cost <brief> --agent <id>`) `step=-`, `rows-passed=-`; *(21)* `brief=` relative to the home (an older record's absolute path is still read, up to the next field, its home prefix removed); *(21)* for a cost with no transcript found, `cost … --tokens <n> --source agent-tool` records `total=<n>` and `source=agent-tool` after `before-change=` — the caller's own total, reported, never `unknown`; *(21)* `agent=<the agent's id>` last, before the time — an agent whose `build-cost` or `agent-returned` carries its id after its latest `agent-start` is finished (resume and the watcher never call it quiet); older records without it stay as they are | `checks/brief.sh return` | a hand-back passes the check, once per brief *(29)* a ticket's hand-back (`brief.sh return … --agent pr:<n>`): `tool=ticket model=unknown effort=unknown`, the token fields `unknown`, `agent=pr:<n>` |
| `amended` | `row=<ROW-id> sha=<commit>` *(20)* `by=obligation\|fail-if` — the row's own obligation changed, or an item it derives from changed its fail-if; only `obligation` clears its authority flag | `checks/hooks/post-commit` | after a commit that changed the row's obligation or its item's effective fail-if; wipes the row's verdicts; *(2)* inside a 0.9.6 develop run, written at the run's home; *(23)* written only `by=obligation` (a changed fail-if writes `law-changed`); one written `by=fail-if` before 23 still wipes |
| `law-changed` | *(23)* `row=<ROW-id> sha=<12 hex> item=<REQ-id,…>` — the items it derives from whose effective fail-if changed | `checks/hooks/post-commit` (the row sets of `sh checks/inventory.sh impact --detail`) | after a commit that changed an effective fail-if, for each row present at both commits whose own obligation did not change and that derives from such an item (a row new at the commit gets none); no wipe — the row is to confirm (Readings); inside a develop run, written at the run's home |
| `attempts` | `row=<ROW-id> n=<k>` | (legacy, 0.9.2) | no longer written; read as 0.9.2 read it |
| `brief-check` | `path=<brief> result=ok\|fail` | `checks/brief.sh` | every brief check — including the observer's, so never session activity |
| `checkpoint` | *(3)* `n=1\|2 report=<the kept checkpoint receipt> built=<b> regressions=<k> base=<the commit it tested>` | `checks/metrics.sh checkpoint --n <n> --to <report>` | a checkpoint recorded once its receipt holds every expected case of every built row (*(15)* of the population its `.rows` carries); `regressions=` counts built rows that passed before it and do not in it — checkpoint 2 runs only when checkpoint 1's is above zero (*(15)*: due at two thirds whatever checkpoint 1 found) |
| `close-batch` | *(15)* `id=<ticket> chunks=<n> retried=<n> adopted=<n> stacks-max=<k> wall=<s> chunk-seconds-sum=<s> load-start=<1-min load> load-end=<1-min load>` | `checks/test.sh` (the batch's supervisor) | a close batch ended, green or not: `wall` from its first chunk's start to its end, `chunk-seconds-sum` each chunk run's seconds from its slot to its result, `stacks-max` the most at once |
| `completion` | `unmet=<U> strict-gaps=<G>` | `checks/metrics.sh completion --record` | at the completion report |
| `court` | `name=inventory\|census\|coverage seconds=<s>` | those courts' report modes | court runtime |
| `court-refused` | *(18)* `court=<name> rule=<rule\|-> subject=<subject\|-> tree=<the index tree> attempt=<the refused event's attempt>` | `checks/hooks/pre-commit` | one per refusing court of a refused commit, beside `refused`; its record is `.vid/refusals/<attempt>/`; progress counts them by court and rule |
| `deploy-check` | *(27)* `target=staging sha=<12 hex> tests=scoped\|full base=<12 hex\|-> ahead=<n> rows=<n> receipt=<name\|-> result=ready`; `target=production sha=<12 hex> tests=full base=<12 hex\|-> regraded=<n> result=ready` | `checks/metrics.sh deploy-check --record` | a target's check ready on its candidate; a production record, and a staging one with `tests=full`, is a last full pass |
| `deploy-confirm` | *(4)* `state=ask\|answer what="<the question>" [result=yes\|no]` | `checks/deploy-gate.sh confirm`, called by vid-deploy | an owner confirmation asked, and answered; gate 3's question begins `cutover <the commit, 12>:`, and only its answers are read by a gate 3 start |
| `deploy-down` | *(FB-2 A4)* `target=staging at=<commit> words="<the owner's words>"` (develop: the test site taken down, its address no longer answering); in the GitHub modes `target=staging\|production at=<commit> stage=<N> issue=<n> result=down\|failed words="<the owner's words>"`, a take-down's report read; `words=` last, the owner's own words from the command, a double quote in them made a single one | vid-deploy (develop); `checks/close.sh` (the GitHub modes) | a site taken down at the owner's word, or a take-down that failed |
| `deploy-gate` | *(4)* `gate=1\|2\|3 state=start candidate=<commit> env=<name>`; `state=end result=pass\|fail [rollback-target=<ref>]`; `gate=1 state=skipped reason=first-deploy` | `checks/deploy-gate.sh`, called by vid-deploy | a gate opens, closes, or is skipped. A gate 3 start is written only when the newest gate-2 pass, a ready production `deploy-check`, gate 1 after it (or a first-deploy skip), the owner's `cutover <c>:` yes after that and `stages.sh debt` all hold for the commit; else it is refused, nothing written (0.26.11.1.2, R2). Every other call only records. A missing record means "not recorded", not "not done" |
| `deploy-rollback` | *(4)* `gate=1\|2\|3 why="<one line>"` | `checks/deploy-gate.sh rollback`, called by vid-deploy | a rollback starts |
| `died` | `reason=<the API error type, or usage-limit-waiting> session=<id> [details="<text, 200 characters at most>"]` | the plugin's `hooks/stop-failure.sh` (StopFailure, and the Notification types `quota_auto_resume_stale` and `quota_auto_resume_disabled`) | the run's own session stopped on an API error, or a usage-limit pause is left waiting; never for a subagent or another session; stands until a newer `run` event |
| `engine-only` | `breach row=<ROW-id> engine=<name>` | vid-develop | a breach seen in one test engine only |
| `failif-amendment` | `n=<k>` | `checks/hooks/pre-commit` | a PRD change counting amended items or removed fail-ifs (written before the message check, so a refused commit can still record it) |
| `harness-upgrade` | *(13)* `state=due\|dispatched\|asked\|applied\|declined harness=<cksum of docker-compose.test.yml as it was, the original harness>`; *(14)* `target=<the rules version the step brings the harness to>` — none reads as 1; states are keyed by hash and target, so a target-1 decline leaves target 2 due | vid-develop (`sh checks/event.sh`) | the upgrade step for a harness with no `rules:` line (`sh checks/harness.sh rules`, at develop's start): `due` once, `dispatched` with the first admitted step's upgrade pass, `asked` with the owner's law question, then `applied` (after the law commit) or `declined`; the latest state for the hash is where a resumed run goes on; events only — a declined hash is due again once the harness file changes |
| `incident` | `slice=<N> <what>` (free text; `harness row=<ROW-id> …` for a harness breach) *(16)* `slice=- coordination-fault try=<try> ticket=<id> ledger=<path>` (`checks/job.sh status`: a job's ticket outside the run's home) | vid-develop | an incident |
| `invalidated` | `slice=<N> <why>`; *(2)* `slice=<N> report=<receipt> <why>` names the void receipt | vid-develop | the close run invalidated; *(2)* any run found void — its receipt is then no current result |
| `ledger-run` | `seconds=<s> kind=full\|deployed\|scoped report=<name>\|none status=<n> [role=builder\|fixer\|close\|grader]`; *(5)* `role=` always present — also `test-author` and `testenv` (a scoped run, like a builder's), and `-` for a run outside a develop run that names no role; *(6)* `role=orchestrator` (the orchestrator's own `prove-red`); a request's run adds `request=<ticket> type=prove-red\|iterate\|close\|checkpoint\|full\|deployed rows=<n> estimate=<s>` `cap=<s>` *(not written from 0.26.10.4)* (*(24)* `silence=<s> startup=<s> limit=<s>` in its place; an older event's `cap=` is still read) `[expect=<s>] [no-history=<n>]` (*(15)* a close batch's chunk: `request=<ticket>/<n>` and, after those, `batch=<ticket>`), then `[outside=<n>]` on a pass kept out of the evidence (`report=none`; *(14)* on a kept pass whose cases reached `<n>` rows outside its frozen rows, none credited) and `capped=yes` on a run stopped at its cap (`report=none status=130`; *(24)* `capped=yes stop=silent\|startup\|limit` — its watcher's reason) — *(14)* or `stopped=service:<name>` in its place on a run stopped by a service's death, and `why="<line>"` last, before the time; a plain run outside a develop run adds `form=legacy` after `role=`; *(2)* inside a 0.9.6 develop run also `tree=<sha> run=<run-id> [waited=<s>] [teardown=failed]`, and `report=` names the kept receipt; *(13)* inside a develop run a pass is published before its teardown, so `seconds=` holds no teardown and `teardown=failed` rides only a capped run's event — a failed teardown is its own `teardown-failed` event; *(13)* each pass published inside a develop run adds `overhead=<s>` after the request's fields (before `why=`): its seconds minus the sum of its cases' seconds in its `.cases`, never below 0 — the image build, the services, installs and the runner's start; a run outside a develop run keeps no `.cases` and writes none; *(3)* `kind=close` for a selected close's inline pass and `kind=checkpoint` for a checkpoint's (their deployed passes are `kind=deployed`), with `role=checkpoint` *(16)* `try=<try>` after the request's fields when its ticket carries one; a cancelled run `report=none status=130 … cancelled=yes`; *(0.26.10.28.3)* a run whose publish lock stayed held, or whose reclaim folder stood, past 20 s `report=none … pid=<p> why=publish-lock-held\|publish-reclaim-stands`, its report kept beside as `<report>.unpublished`; *(20)* `purpose=proof` on a proof request's run, its receipt named `.proof.`: cost and export read it; nothing that credits, claims, briefs, estimates or triggers does; *(27)* `type=staging` on a staging request's run (`kind=scoped`, its receipt today's scoped one); *(29)* a CI receipt's: `type=ci report=<code sha>.ci-<run>-<attempt>.xml repo=<owner/name> workflow=<name, spaces as %20> run=<id> attempt=<n> commit=<code sha, 12> pr=<n\|-> [stage=<n>] status=0` *(not written from 0.26.10.28.1)* (`checks/ticket.sh import` (old ticket mode, removed in 0.26.10.28.1)) | `checks/test.sh`; *(29)* `checks/ticket.sh import` (old ticket mode, removed in 0.26.10.28.1) | every ledger run; *(2)* written at the run's home; *(27)* a request's run is written at its home whenever `checks/plan.sh home-of` resolves, the gate on or off, with `tree=` and `run=` |
| `owed-close` | `slice=<N> n=<k>` | vid-develop | owed rows at slice close |
| `overrun` | *(32)* `ticket=<ticket> estimate=<s> awake=<s>` | `checks/test.sh` (the request's watcher) | once per request, the first tick its awake seconds pass twice its estimate; it stops nothing |
| `paid` | `row=<ROW-id> via=ledger\|browser\|census\|deploy` | vid-develop | a row paid, and by which channel |
| `plan-change` | *(2)* `what=create\|add\|drop\|split\|merge\|reorder\|lanes\|rows\|other hash=<12 hex> why="<one line>"`; *(4)* `decision=<id>` before `why=`; *(17)* `what=edge` (rows moved into a hardening step), `not-needed-by=<step ids>` before `why=` when given | `checks/plan.sh change` | every accepted change to the plan block, with its reason; the block is kept in `.vid/plans/<hash>.plan`; *(4)* its decision record in `.vid/plans/decisions/<id>.why`. A refused change writes no event, only its record |
| `progress` | *(2)* `trigger=hourly\|plan-change\|session by=observer\|session rows-passing=<n> rows-left=<n> estimate=<lo>-<hi>\|none`; *(33)* in ticket mode `trigger=<…> by=observer mode=tickets` — the watcher's tick that rewrites `.vid/decide/queue/status.txt` | `checks/progress.sh --record`; *(33)* `checks/observe.sh` (ticket mode) | a progress update; `by=observer` lines are never session activity |
| `pull-forward` | *(25)* `step=<id> decision=<D-id>` | vid-develop | a minimum technical piece of a later stage brought forward into the current one (its plan change and decision recorded with it) |
| `question` | `n=<n> state=asked gates=<ROW-ids and paths, comma-separated, or all>`; `n=<n> state=answered` | vid-develop | a develop question asked (after its `Q<n>` line is written), and answered (after the PRD append) *(29)* in ticket mode `to=<answerer>` on `state=asked` (ANSWERERS.md), written by vid-replan (old ticket mode, removed in 0.26.10.28.1) |
| `red-observed` | *(2)* `row=<ROW-id> report=<receipt> case=<case id> assertion="<the failing assertion>"`; *(29)* ticket mode: `row=<ROW-id>` `pr=<n> commit=<code sha, 12>` *(not written from 0.26.10.28.1)* — the row's cases failing in the dev team's CI report for the tests-first commit; no receipt, no stamp | vid-develop; *(29)* `checks/ticket.sh import` (old ticket mode, removed in 0.26.10.28.1) | a new row's test observed failing on its real check, before its `proved-red:` stamp; *(29)* in ticket mode, at the import of the tests-first commit's CI report |
| `re-verdict` | `slice=<N> round=<r> breached=<k>` | vid-develop | a re-verdict round |
| `regressions` | `slice=<N> n=<k>` | vid-develop | at slice close |
| `refused` | *(4)* `phase=pre-commit\|commit-msg\|admission by=<court or rule> attempt=<the UTC time plus 4 hex> [step=<id>]` | `checks/hooks/pre-commit` (`by=` the courts that refused, comma-separated, or `protected-paths`, `law-dirty`, `law-standalone`, `purpose-header`, `decisions-enforced`, `decisions-promissory`, *(18)* `decisions-label`, `index-copy`, `red-stamp`, `prd-grammar`, `selftest`; *(25)* `stages` among the courts; `append-review`, a new append section holding rows with no record of its delta review, 0.26.10.29.3 R3); `checks/hooks/commit-msg` (`decisions`, `tests-by`, *(25)* `stages`; `owner`, a human answer added with no `Owner:` trailer, 0.26.10.29.3 R2); `checks/plan.sh` (`rule-A`, `rule-B`, `dirty-currency`, `unrecorded-plan`, `no-step`, `rows-not-of-step`, *(17)* `graded`, *(25)* `stage`, with `step=`) | every refusal of a commit or an admission, at the run's home |
| `reissued` | `row=<ROW-id> why=<answer id>` *(8)* `[rounds=<N>]` — the owner's allowance: the row is held, reason rounds, once N distinct briefs breach it with no KEPT | vid-develop | an owner ruling releases a held row |
| `reverted` | `row=<ROW-id>` | (legacy, 0.9.2) | no longer written; wipes as 0.9.2 read it |
| `rows-paid` | `slice=<N> n=<k>` | vid-develop | at slice close |
| `run` | `state=<the run: value>` — `state=active`, `state=waiting`, `state=stopped <reason>`, `state=complete`; the reason is free text; *(33)* `state=stopped by=owner` or `state=active by=owner` — the owner's pause or continue in ticket mode | vid-develop; *(33)* `checks/queue.sh` (the owner's pause and continue) | every write of RUN-STATE's `run:`; the newest one's time starts the run's current episode |
| `session` | *(4)* `id=<session id> source=<as Claude Code gives it> [model=<when given>] transcript=<path> vid=<plugin version>` | the plugin's `hooks/record.sh` (SessionStart), wherever the project already has `.vid/` | a session starts; the session that creates a project has none (it starts before `.vid/` exists) — the export recovers it from the stage events' `session=`; nothing is backdated |
| `slice-close` | `slice=<N> sha=<commit>` | vid-develop | a slice closes |
| `slice-modules` | `slice=<N> <path> …` | vid-develop | a slice opens: the modules it touches |
| `slice-open` | `slice=<N> sha=<commit>` | vid-develop | a slice opens |
| `slot-reclaimed` | *(11)* `slot=<k> project=<the holder's compose project> holder-pid=<pid> age=<s>` | `checks/test.sh` | a run that found no free test environment freed a host slot left by a run that died: its holder pid gone, Docker answering, no container, running or stopped, of that compose project left; written at the run's home, once per slot freed |
| `stage` | `name=<verb> state=start\|end\|pause-1\|pause-2\|pause-3 session=<id> [records=<n>]`; *(4)* `run=<the run id>` on every `state=start`, last, before the time (`checks/event.sh` adds it); *(29)* `made=spec` on vid-init's end for a spec-only init; *(30)* `base=<HEAD when it starts, 12 hex>` on vid-add's start; *(IR I5)* the stage name `incorporate`, with `base=` on its start as vid-add's | every verb but vid-grade, in a VID project | a verb starts or ends; vid-create-prd also at each pause commit; `records=` is the version the verb writes (vid-develop 8, vid-fix 8, vid-deploy 4, the others 1) *(20)* vid-develop and vid-fix write `records=20`. *(29)* the stage names `plan` and `replan` (vid-plan, vid-replan, `records=29`; `replan`: old ticket mode, removed in 0.26.10.28.1); vid-init's end carries `made=spec` for a spec-only init (an older init wrote no `made=`); vid-init and vid-develop write `records=29` *(30)* vid-add writes `records=30` and `base=<HEAD when it starts, 12 hex>` on its `state=start`, read by vid-develop's completion grade (the adds since the newest `completion unmet=0 strict-gaps=0`, from the earliest one's `base=`) *(IR I5)* vid-incorporate writes `stage name=incorporate` at its start and end outside ticket mode (none under tickets, GitHub auto and manual alike, as vid-add records none there), its start carrying `base=` as vid-add's; vid-develop's completion grade reads it as an add's, and `checks/plan.sh guard` refuses product code while it is open, as during an add |
| `stage-closed` | *(25)* `n=<N> sha=<12 hex> ready rows=<n> debt=<n> stages-blob=<HEAD:STAGES.md blob\|none>`; *(29)* ticket mode: `n=<N> sha=<the code commit, 12> source=ci run=<id> rows=<n> debt=<n>` (`metrics.sh stage-close --ci --record`) — no `ready` token, so no reader of a close's ViD sha reads it; no tag | `checks/metrics.sh stage-close --record`; *(v0.26.10.26.5)* `checks/close.sh close-stage` in ticket mode, no tag | a ready stage close, with the tag vid/stage-N at sha (in develop); what vid-deploy reads, never recomputing a past commit |
| `stage-cut` | *(25)* `n=<stages> answer=<A-id> [blob=<HEAD:STAGES.md blob>]` | vid-stage; *(0.26.10.29.2, R2)* `checks/land.sh`, at a re-cut's landing in ticket mode | the owner ratified a cut (n=1: one stage, no STAGES.md), at init or a re-cut |
| `stage-deploy` | *(25)* `n=<N> staging=yes production=yes\|no`; *(28)* `staging=failed`, `[by=develop]`, `[why="<one line>"]` | vid-deploy | a stage deployed to staging and the owner's gate-3 answer; *(27)* written by each target — `production=no` by a staging deploy, `production=yes` by a production cutover; *(28)* `by=develop` for develop's own staging deploy under the standing authorization, `staging=failed` with its reason when that deploy ended without gate 2's pass |
| `stage-hold` | *(27)* `n=<N> state=asked words="<the owner's words>"`; `n=<N> state=on`; `n=<N> state=off` | `checks/stages.sh hold --after N` (asked), `checks/metrics.sh stage-close --record` (on), `checks/stages.sh hold --off` (off); *(v0.26.10.26.5)* in ticket mode `checks/queue.sh control hold` (asked), `checks/close.sh close-stage` (on), `control continue` (off); *(30)* vid-add (off, for an asked hold the owner's yes to an add withdraws before the build) | the owner's "hold after this stage"; stage N's ready close under it; the owner's "continue"; *(28)* `words="staging setup"` is the setup hold, asked by vid-develop while no staging deploy has passed gate 2 (its close writes `run: stopped staging setup after stage N`), released by `checks/stages.sh hold --off --setup` once staging works — which, when the owner also asked to hold, records nothing and rewrites the run line to the owner's hold |
| `staging-auth` | *(28)* `state=on\|off words="<the owner's words>"` | `checks/stages.sh staging-auth on\|off --words` (vid-stage's sitting; any verb, at the owner's word) | the standing staging authorization: develop may set staging up and deploy each closed stage to it on its own; the newest stands |
| `stall` | `op=<op> elapsed=<s> envelope=<s>` | `checks/watchdog.sh` | a session's check of an operation past its envelope |
| `step-closed` | *(3)* `step=<id> report=<the kept receipt the claim read>`; *(15)* `batch=<ticket>` from a claim by batch, `report=` its newest constituent | `checks/metrics.sh claim --steps` | a claim on a selected close, or on the final full run, succeeded; the step's rows are then eligible at every later close |
| `step-done` | *(17)* `step=<id>` | `checks/metrics.sh step-state` | the first time a step is computed done; a stamp for measurement, never read back as done |
| `step-resumed` | *(32)* `step=<id> plan=<hash>` | `checks/plan.sh start <id>` | outside ticket mode, on a step already started; with `step-start`, it lets product code past the commit guard after a develop start |
| `step-rows-passing` | *(17)* `step=<id> tree=<12 hex> receipts=<names, comma-separated>` | `checks/metrics.sh step-state` (read at `brief.sh return` and by `progress.sh`) | once per feature step, the first time every row of it passes (or is owed, held or later) on receipts of one tree: the time it was seen |
| `step-start` | *(2)* `step=<id> plan=<hash>`; *(3)* `base=<commit>`, HEAD at admission (absent on a step started before 0.9.6.1) | `checks/plan.sh` (a builder or fixer brief checked ok, or `plan.sh start <id>`) | a plan step's first admission |
| `strategy` | *(17)* `set=depth-first\|breadth-first by=owner decision=<id>` | `checks/plan.sh strategy` | the owner sets the run's strategy; the words are in `.vid/plans/decisions/<id>.why` |
| `teardown` | *(13)* `seconds=<s> report=<the pass's kept receipt\|none>` | `checks/test.sh` | inside a develop run, each pass's teardown that succeeded, after the pass is published (so its `ledger-run` seconds hold no teardown); written at the run's home |
| `teardown-failed` | *(13)* `request=<ticket\|->` `project=<compose project>` | `checks/test.sh` | inside a develop run, a teardown failed — between two passes (the later pass did not start) or after the result (the result stands); the slot and the run folder are kept, both holders marked `teardown-failed <UTC>`; written at the run's home |
| `testenv` | *(2)* `stacks=<k> env-mb=<n> docker-mb=<n> other-mb=<n> case-seconds=<s> compose=<version> resets=yes\|no` | `checks/testenv.sh record` | develop's test-environment step: the environments recorded, with the figures they were picked from |
| `tokens` | `slice=<N> phase=build\|verdict\|fix\|re-verdict\|review n=<k>` | vid-develop; the append doors and reviews (`phase=review`, `slice=0` before the first slice) | tokens spent |
| `verdict` | per row: `slice=<N\|fix-<date>> row=<ROW-id> result=KEPT\|BREACHED class=product\|test\|harness [transition=k/n]` *(8)* `[scope="<the grader's question>"]` `brief=<path> quoted-at=<sha>` — `scope=` on a BREACHED holds the row, reason scope; per slice: `slice=<N> claimed=<k> breached=<k>`; *(20)* a failed fault proof's `result=BREACHED class=test proof=<the faulted receipt> brief=<the grader brief> quoted-at=<sha>` (`checks/metrics.sh proof`) | vid-develop; vid-fix's re-grade; *(20)* `checks/metrics.sh proof` | a grader's verdict; the slice's tally; a fault proof that failed |
| `wall-clock` | `slice=<N> seconds=<s>` | vid-develop | at slice close |
| `ticket` | *(29)* `issue=<n> step=<id\|-> kind=feature\|fix\|skeleton state=published\|rewritten\|commented\|taken\|returned\|merged\|graded\|fix\|done\|blocked\|unblocked` `[pr=<n>]` *(not written from 0.26.10.28.1)* `[resolved-by=<issues>]` *(not written from 0.26.10.28.1)* `[why=<word>]` *(not written from 0.26.10.28.1)* (the first ticket mode's); *(33)* the ticket flow's asks: `issue=<n> stage=<N> kind=deploy\|grade state=asked` (a staging or production okay, `github.sh deploy-ask`; a stage's grade, `github.sh grade-ask`) and `issue=<n> step=<step> kind=close state=asked` (a close's run, `github.sh run-ask`; `step=stage-<N>` and the like for a stage's runs) | `checks/github.sh` (published, rewritten, commented; taken, returned, merged as `pull` first sees them; *(33)* the asks); vid-replan (old ticket mode, removed in 0.26.10.28.1: graded, fix, done, blocked, unblocked) | a ticket's state changes; `state=done` is what admission under tickets reads (the original completed by its fix carries `resolved-by=`); *(33)* an ask's issue made on GitHub |
| `milestone` | *(29)* `stage=<n> number=<n> state=created\|edited\|closed [commit=<code sha>]` | `checks/github.sh publish` (old ticket mode, removed in 0.26.10.28.1), `close --milestone` | a stage's milestone made, its title or card changed, or closed naming the commit that passed the stage |
| `publish-approved` | *(29)* `words="<the owner's words>"` | vid-plan | the owner's yes to the plan page; nothing goes to GitHub before it |
| `run-full` | *(31)* `started run=<id> attempt=<n> sha=<the run's head commit, 12>` | `checks/github.sh run-full` (old ticket mode, removed in 0.26.10.28.1) *(not written from 0.26.10.28.1)* | ViD started the skeleton's manual run of every test on main (ticket mode, the vid-code block naming `run-full:`); the run's commit descends from every merge of the stage's tickets. `ticket.sh import --main` and `metrics.sh stage-close --ci` read only a run one of these names |
| `copy-check` | *(29)* `pr=<n> files=<n> changed=<n> missing=<n>` | `checks/ticket.sh import` (old ticket mode, removed in 0.26.10.28.1) *(not written from 0.26.10.28.1)* | ViD's copy check of a merged pull request: its ticket's test files at the merge commit against ViD's copy; `brief.sh return` reads the newest for the pull request |
| `skeleton` | *(29)* `state=start provenance=spec-only\|adopted`; `state=part-done part=<1\|2\|3>`; `state=end sha=<HEAD> materialised=<n> red=<n> spec-only=<n> prerequisite=<n>` | vid-skeleton (develop's first step) | the code skeleton's parts; `checks/plan.sh skeleton` reads them |
| `test-proven` | *(20)* `row=<ROW-id> result=proven\|inconclusive why=<-\|unappliable\|no-baseline\|no-fault-run\|shape\|baseline-tree\|fault-tree\|missing-case\|baseline-failed\|control-<status>\|target-<status>> fault=<patch> clean=<receipt\|none> red=<receipt\|none> target=<case> control=<case> commit=<12 hex> file=<test path> blob=<blob> helpers=- obligation=<cksum> authority=<digest> brief=<grader brief>` | `checks/metrics.sh proof` | a fault proof judged; a conclusive failure is a `verdict … class=test proof=<receipt>` instead |
| `authority-kept` | *(20)* `row=<ROW-id> sha=<HEAD>` | `checks/brief.sh authority --kept` | a test-author pass kept the row as it is under its changed authority; its flag clears until the bundle changes again |
| `selftest-retried` | *(21)* `case=<path from checks/selftest/> result=convicts\|failed` | `checks/selftest/run.sh` | a case listed in `checks/selftest/flaky` failed in the suite and ran once more, alone, where a `.vid/` is present; a run a retry rescued publishes no self-test certificate and is never evidence |
| `vid-finding` | *(23)* `n=<n> area=check\|hook\|skill\|agent file=<ViD path>` | the run managers of vid-init, vid-develop, vid-fix and vid-add, through `checks/event.sh` | with each entry appended to `.vid/VID-FINDINGS.md` (its `F-<n>`) |
| `agent-brief` | *(21)* `agent=<agent id> brief=<path relative to the home>\|unavailable` | the plugin's `hooks/net.sh` (PostToolUse) | at an agent's first tool call in a VID project, every role, once (`.vid/agents/<id>.brief`); the brief read from the agent's first user entry as the context net reads it, without its builder-and-fixer gate; `unavailable` when none is found |
| `usage` | *(26)* `agent=<agent id\|codex:<try>\|manager> session=<id\|-> tool=claude\|codex model=<m\|mixed\|unknown> effort=<e\|unknown> calls=<n\|unknown> input=<n> cache-read=<n> cache-write=<n> cache-write-1h=<n> output=<n> scope=agent\|since:<UTC\|->` — tokens in four kinds that never overlap; `cache-write-1h` is the part of `cache-write` written for one hour. A Claude agent's (`scope=agent`): every API call of its whole transcript once, by message id, its last entry's usage (`input_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`, of which `cache_creation.ephemeral_1h_input_tokens`, `output_tokens`); entries whose model is `<synthetic>` skipped; `model` the calls' model, or `mixed` when they name more than one (never priced); cumulative — a resumed agent's later record covers its earlier runs, and a reader takes the newest per agent, never a sum. A Codex job's (`scope=agent`, `session=-`, `calls=unknown`): its events file's `turn.completed` usage summed, `input` = `input_tokens` less `cached_input_tokens`, `cache-read` = `cached_input_tokens`, `cache-write` = `cache_write_input_tokens` (0 when absent), `cache-write-1h` 0, `output` = `output_tokens` (reasoning tokens within it); model and effort the job record's. The run manager's (`agent=manager`, `scope=since:<the window's start, the previous manager-cost's at, or ->`): its transcript's entries after the window's start, each message id's last entry, split the same way | the plugin's `hooks/record.sh` (SubagentStop, after `agent-stop`, from the agent's own transcript); `checks/job.sh run` (beside `job-exit`); `checks/brief.sh return` (beside `manager-cost`, over the same window) | once per writing; a transcript or events file not found, or a hook stopped by its timeout (SubagentStop's 10 s), writes none, and the reader falls back to the older totals |
| `close-again` | *(v0.26.10.25.3)* `step=<step> chunk=<chunk>` | `checks/close.sh` | a close's chunk lost or not wholly run, asked again once |
| `close-asked` | *(v0.26.10.25.3)* `step=<step> issue=<n> commit=<sha> chunks=<n> ask=<k>` | `checks/close.sh` | a step's close run asked, as ask k of the step |
| `close-closed` | *(v0.26.10.25.3)* `step=<step> issue=<n> commit=<sha>`, or `step=<step> rows=0` | `checks/close.sh` | the step closed on a green close, or with no row to run |
| `close-done` | *(v0.26.10.25.4)* `step=<step> issue=<n>` | `checks/close.sh` | a red close's ask finished: its rows acted on and its issue closed |
| `close-failing` | *(v0.26.10.25.4)* `step=<step> row=<id> issue=<n>` | `checks/close.sh` | a red row of a close read failing, with its one count |
| `close-fix` | *(v0.26.10.25.4)* `step=<step> issue=<n> rows=<ids>` | `checks/close.sh` | a close's red rows written as one fix line |
| `close-item` | *(v0.26.10.25.3)* `step=<step> what=<kind-chunk>` | `checks/close.sh` | a close's item for the owner: red, lost twice, or red again after its fix |
| `close-numbers` | *(v0.26.10.25.4)* `step=<step> ask=<k> regressions=<n> open=<n> fixed=<n>` | `checks/close.sh` | the three numbers of a close after the first |
| `close-ticket-closed` | *(GM-4 K3)* `step=<step> issue=<n>` | `checks/close.sh` | in GitHub manual, a closed step's open ticket closed on GitHub, its one comment posted once (`commented <n>`, then `closed <n>` in `.vid/decide/close/<step>/tickets`) |
| `draft` | *(v0.26.10.25.5)* `n=<k> files=<the spec files>` | `checks/land.sh` | a counted change to the spec drafted, committing nothing |
| `engine-split` | *(v0.26.10.25.3)* `row=<id> from=<close or a decision> [step=<step>]` | `checks/decide.sh`, `checks/close.sh` | a row passing in one engine and failing in another: every engine is asked from then on |
| `flag` | *(v0.26.10.25.1)* `word=<alarm> on=<what>` | `checks/round.sh` | a round alarm raised, once until it clears |
| `flag-cleared` | *(v0.26.10.25.1)* `word=<alarm> on=<what>` | `checks/round.sh` | the alarm cleared |
| `land-landed` | *(v0.26.10.25.5)* `draft=<k> at=<the landing, 12>` | `checks/land.sh` | a draft landed on the owner's yes and re-ratified |
| `landed` | *(v0.26.10.25.5)* `draft=<k> at=<the landing, 12> ids=<n> reopened=<steps or ->` | `checks/land.sh` | a landing's records written, before its commits |
| `lesson` | *(v0.26.10.25.3)* `rows=<ids>` | `checks/queue.sh` | a lesson line for the next ticket of those rows |
| `lock-taken` | *(v0.26.10.25.1)* `session=<id> from=<the earlier holder or none>` | `checks/github.sh` | the run's lock taken |
| `queue-answered` | *(v0.26.10.25.3)* `what=<kind> by=<owner, RM, delegate or stand-in>` (delegate: RM in the owner's place, under their delegation; stand-in: the round's, for an absent answerer; *(v0.26.10.28.8)*) | `checks/queue.sh` | an answer to a Q line recorded |
| `queue-asked` | *(v0.26.10.25.3)* `Q<n> what=<kind>` | `checks/queue.sh` | a Q line given its number |
| `queue-draft` | *(v0.26.10.25.5)* `n=<k>` | `checks/queue.sh` | a draft asked of the owner |
| `queue-refused` | *(v0.26.10.25.5)* `what=draft n=<k>` | `checks/queue.sh` | the owner's yes, and the landing refused: nothing landed |
| `queue-stale` | *(v0.26.10.25.5)* `what=draft n=<k>` | `checks/queue.sh` | the owner's yes to a stale draft: SP redrafts it |
| `queue-waits` | *(v0.26.10.25.5)* `what=draft n=<k>` | `checks/queue.sh` | the owner's yes while paused or stopped: it waits for continue |
| `round-error` | *(v0.26.10.25.1)* `step=<what failed> count=<n>` | `checks/round.sh` | a round's step failed |
| `decisions-recorded` | *(0.26.10.29.5, DP-1 R2)* `pr=<p> n=<k\|none\|missing\|refused>` or `deploy=<report id> n=<k\|none>` (k=0: every line held already) | `checks/decisions.sh record`; `checks/round.sh` (`n=missing` for a merge with no decision of ViD's) | the dev side's decisions of a merged pull request or a deploy report the reader did not refuse: k lines recorded in DECISIONS.md in one commit; `none`, its `Decisions: none` (or `decisions: none`); `missing`, no Decisions section; `refused`, the hooks refused the commit and nothing was written. Once a pull request or report, never tried again |
| `round-merged` | *(v0.26.10.25.1)* `pr=<p> decision=none` | `checks/round.sh` | a pull request merged with no decision of ViD's |
| `round-main-changed` | *(v0.26.10.28.2)* `main=<commit>\|none\|absent` | `checks/round.sh` | the step saw the code repository's main change, and printed `main-changed` for `next` |
| `round-refused` | *(v0.26.10.25.1)* `what=<the work refused>` | `checks/round.sh` | ticket work or an admission the round was refused, recorded once |
| `round-stop` | *(v0.26.10.25.1)* `stray=<n>` | `checks/round.sh` | the round stopped for a stray, its count |
| `vid-defect` | *(v0.26.10.25.3)* `step=<where>` | `checks/queue.sh` | ViD's own defect, an entry in .vid/VID-FINDINGS.md |
| `stage-candidate` | *(v0.26.10.26.1)* `stage=<N> commit=<sha> candidate=<c>` | `checks/close.sh` | a stage's candidate named, its C3 and S1 asked |
| `stage-candidate-withdrawn` | *(0.26.10.29.2, R2)* `stage=<N> candidate=<c> by=<the landing, 12>` | `checks/land.sh` | a re-cut that changed stage N withdrew its newest candidate, with its C3, S1 and D1 okay still out; a new one is named once due |
| `stage-c3` | *(v0.26.10.26.1)* `stage=<N> ask=<c> result=passed` | `checks/close.sh` | a stage's full run green: its steps closed |
| `stage-s1` | *(v0.26.10.26.1)* `stage=<N> candidate=<c> graded=<n>` | `checks/close.sh` | a stage's grade read whole |
| `grade-ask` | *(v0.26.10.27.2)* `issue=<n> commit=<c> reqs=<n>` [`vs=<c>`] [`robustify=yes`] | `checks/grade.sh` | the owner's grade ask posted |
| `grade-read` | *(v0.26.10.27.2)* `issue=<n> graded=<n> findings=<n>` | `checks/grade.sh` | a grade ask's report read |
| `grade-lost` | *(v0.26.10.27.2)* `issue=<n>` | `checks/grade.sh` | a grade ask lost twice: the owner's again or no |
| `grade-withdrawn` | *(v0.26.10.27.2)* `issue=<n>` | `checks/grade.sh` | a grade ask withdrawn on the owner's no |
| `draft-replaced` | *(v0.26.10.26.7)* `n=<k> by=<m>` | `checks/land.sh` | draft k replaced by draft m (`draft --replaces`): k's question closes, m is asked afresh |
| `queue-waiting` | *(v0.26.10.26.7)* `n=<issue or pull request> q=Q<m>` | `checks/queue.sh` | the dev side told, once, that its question waits on the lead |
| `stage-okay` | *(v0.26.10.26.2)* `stage=<N> candidate=<c> issue=<n> commit=<sha>`; *(v0.26.10.27.1)* `kind=rh\|d2` on the rehearsal's and the production deploy's okay (none on staging's); *(FB-2 A4)* `kind=dn words="<the owner's words>"` on a take-down okay, `words=` last | `checks/close.sh` | the staging okay posted, for DevAgent's D1 |
| `stage-okay-withdrawn` | *(v0.26.10.26.2)* `issue=<n> by=<the newer okay>` | `checks/close.sh` | an earlier okay with no D1 passed withdrawn by a newer one |
| `stage-okay-again` | *(v0.26.10.26.2)* `stage=<N> candidate=<c> kind=d1\|rh` — the okay asked again; *(0.26.11.1.1, R4)* `kind=stand-in`, D1 and CS asked afresh on the owner's again to a stand-in row | `checks/close.sh` | a failed okay asked again at the same commit, on the owner's again |
| `staging-seed` | *(0.26.11.1.1, R6)* `seed=production\|synthetic by=owner` | `checks/queue.sh` | the owner's word for staging's data (`control seed`), which each later staging okay's `seed:` follows |
| `stage-d1` | *(v0.26.10.26.2)* `stage=<N> issue=<n> result=passed attempt=<k>`; `result=failed step=<step> change=yes\|no` | `checks/close.sh` | a D1 report read |
| `stage-staged` | *(v0.26.10.26.2)* `stage=<N> issue=<n>` | `checks/close.sh` | the run's first passed D1: the setup hold ends |
| `stage-differs` | *(v0.26.10.26.2)* `stage=<N> issue=<n>` | `checks/close.sh` | a passed D1 named a new difference from production, for the door |
| `stage-cs` | *(v0.26.10.26.2)* `stage=<N> result=passed issue=<n>` (`rows=0` when none ran) | `checks/close.sh` | a staging run green |
| `stage-cs-withdrawn` | *(v0.26.10.26.2)* `stage=<N> issue=<n>` | `checks/close.sh` | an older candidate's staging run withdrawn by a newer candidate |
| `stage-paid` | *(v0.26.10.26.2)* `stage=<N> row=<id> issue=<n>`; *(0.26.11.1.1, R4)* `by=limit` when the owner's `limit` pays a stand-in row against its stand-in (`checks/queue.sh`) | `checks/close.sh` | a seam or staging-owed row passed at CS: `paid` |
| `duty-known` | *(0.26.11.1.1, R3)* `duty=<duty> by=owner` | `checks/queue.sh` | the owner ruled a staging duty not done a known limit of the project: `.vid/decide/duties-known` |
| `mode` | *(GM-1 S2)* `name=manual from=<auto\|team\|none> words="<the owner's words>"` | `checks/mode.sh` | `/vid mode manual` switched the project to GitHub manual, its plan ratified; the newest one's time is where Slack's first read starts |
| `mode-devagent` | *(GM-1 S2)* `words="<the owner's words>"` | `checks/mode.sh` | a switch from GitHub auto: the owner's words that DevAgent is stopped |
| `mode-retake` | *(GM-1 S2)* `words="<the owner's words>"` | `checks/mode.sh` | `/vid mode manual` run again in GitHub manual: the stock of published tickets re-taken, the plan ratified again |
| `mode-take-over` | *(GM-3 S2)* `commit=<the take-over commit> on=<the commit the tickets were written from> ref=refs/vid/applied/<k> rows=<id,…> words="<the owner's words>"` | `checks/mode.sh` | the switch took the project over as its tickets were published: the rows they quote, missing from INVENTORY.md, written on the commit they were written from; that commit, kept under `refs/vid/applied/`, is the applied version |
| `stage-rh` | *(v0.26.10.27.1)* `stage=<N> issue=<n> result=passed attempt=<k>`; `result=no-backup`; `result=failed step=<step> change=yes\|no` | `checks/close.sh` | the rehearsal's report read |
| `stage-cr` | *(v0.26.10.27.1)* `stage=<N> result=passed issue=<n>` (`rows=0` when none ran) | `checks/close.sh` | the rehearsal run green |
| `stage-d2` | *(v0.26.10.27.1)* `stage=<N> issue=<n> result=passed`; `result=failed` `step=<step>` *(not written from 0.26.10.27.3)* | `checks/close.sh` | the production deploy's report read |
| `stage-cp` | *(v0.26.10.27.1)* `stage=<N> result=passed issue=<n>` (`rows=0` when none ran) | `checks/close.sh` | the production run green |
| `production` | *(v0.26.10.27.1)* `stage=<N> commit=<sha>` | `checks/close.sh` | stages up to N in production |
| `production-asked` | *(v0.26.10.27.1)* `stage=<N> candidate=<c>` | `checks/close.sh` | the owner's production yes asked |
| `production-yes` | *(v0.26.10.27.1)* `stage=<N> candidate=<c>` | `checks/queue.sh` | the owner's yes to production |
| `production-commit` | *(v0.26.10.27.1)* `commit=<sha\|none>` | `checks/close.sh` | production's commit recorded: a passed D2 |
| `production-recovery-asked` | *(v0.26.10.27.1)* `stage=<N> issue=<n>` | `checks/close.sh` | a failed D2 or a red CP: recovery asked |
| `production-recovered` | *(v0.26.10.27.1)* `stage=<N> issue=<n> commit=<sha\|none>` | `checks/close.sh` | DevAgent's `vid: recovered` read |
| `production-lost` | *(v0.26.10.27.1)* `stage=<N> issue=<n>` | `checks/close.sh` | a production deploy with no report after the run wait |
| `production-grade` | *(v0.26.10.27.4)* `ask=<n>` | `checks/queue.sh` | the owner's `grade` to the offer before the first go-live: the grade ask posted, which holds every production yes until read and ruled, or withdrawn |
| `stage-summary-refused` | *(v0.26.10.26.5)* `n=<N>` | `checks/close.sh` | a stage close refused: its summary misses a fact |
| `walk-brief` | *(v0.26.10.26.4)* `stage=<N> candidate=<c> start=<s>` | `checks/walk.sh` | a walk's brief written, outside the project |
| `walk-start` | *(v0.26.10.26.4)* `stage=<N> candidate=<c> start=<s>` | `checks/walk.sh` | the walker started, a session of its own |
| `walk-read` | *(v0.26.10.26.4)* `stage=<N> start=<s> result=done\|not-done\|refused` | `checks/walk.sh` | the walker's return read |
| `walk-withdrawn` | *(v0.26.10.26.4)* `stage=<N> candidate=<c>` | `checks/walk.sh` | an older candidate's walk withdrawn by a newer candidate |
| `walk-none` | *(34; 0.26.10.28.6)* `stage=<N> candidate=<c>` | `checks/walk.sh` | no walk owed: the product has no screens; the walk's step closes |
| `walk-limit` | *(34; 0.26.10.28.6)* `stage=<N> candidate=<c> by=owner` | `checks/queue.sh` | the owner closed without the walk (screens, no browser), a known limit in the end report |
| `stage-move` | *(GM-4 K4)* `kind=walk-stage\|read-walk\|write-summary stage=<N> words="<the owner's words>"` | `checks/next-move.sh` | in GitHub manual, the owner's move on a stage's walk or summary done, its line taken out of `.vid/next/stage-moves` |
| `ticket` … `state=closed-outside` | *(v0.26.10.27.3, 8.1b R1)* `issue=<n> state=closed-outside` | `checks/github.sh` (`tw-outside`) | a published ticket closed on GitHub with no merged pull request naming it, read as withdrawn: `.vid/tw/log` gains `withdrawn <n> decision=closed-outside at=<UTC>` |
| `close-reopened` | *(v0.26.10.27.3, 8.1b R3)* `step=<s> ticket=<n>` | `checks/round.sh` | a closed step whose ticket was closed outside ViD opens again: its `closed <s>` line dropped, its newest close ask withdrawn |
| `setup-hold` | *(v0.26.10.26.2)* `state=off by=owner` | `checks/queue.sh` | the owner's continue ended the setup hold |

**Stages.** An `end` closes the latest open `start` of the same name; a
`pause-N` belongs to it; a `start` with no `end` is open. Nesting (init
containing create-prd and test-inventory) and repeats (develop after a
takeover) pair by that rule. A standalone create-prd outside a VID project
writes none; vid-grade never writes them.

## Readings

- **Progress by feature.** An inventory row joins to a REQ directly
  (`derived-from`), or through the manifest (its marker's row in
  DESIGN-BRIEF.md). The REQ names its feature (`feature:`). The row's
  latest state is read from the newest SLICE-REPORTS section's closure.
- **"Needs me".** It combines:
  - the open `Q<n>` lines in RUN-STATE;
  - rows held for the owner (RUN-STATE `held:`);
  - the owner-decision rows in the newest closure's `contract-ambiguity`
    line;
  - `run: waiting` or `run: stopped <reason>`;
  - a `died` event with no newer `run` event (the observer's rule);
  - the newest `observe:` line in the heartbeat when the session cannot
    write (the observer's view of a stopped or quiet run).
- **An episode** of the run is the time of the newest `run` event; a
  resumption followed by the same stop is a new episode.
- **Durations.** A stage's span from its `start` and `end`; a slice's wall
  between its `slice-open` and `slice-close`, by `at=`; the rows paid in
  the slice by INVENTORY `kind`; the product rounds by kind (one distinct
  brief among a row's product-class BREACHED verdicts, counted in the slice
  its first verdict falls in — a history, never reduced by a later KEPT);
  a question's window from `question … state=asked` to `state=answered`;
  the hook's share of a slice from the `.vid/hook-times` lines inside it.
  A negative span (a clock step) is uncounted. `sh checks/metrics.sh
  timing` computes the same from the same lines; before any timed run,
  what to estimate is the reader's choice.
- **To confirm** *(23)*. A row is to confirm when it has a `law-changed`
  at commit L that no resolution covers. A resolution — `authority-kept
  row= sha=<S>` or `amended row= sha=<S>` — covers L only when L is an
  ancestor of S (or S itself) and S is an ancestor of the HEAD read; a
  change at an L that HEAD does not hold puts nothing to confirm. Its
  verdicts, attempts, holds and evidence stand; completion counts it unmet
  (`to confirm: N (ids)`). `sh checks/metrics.sh to-confirm` computes the
  same from the same lines.

## The question numberings

- `Q<n>` is a develop-time question, a line in RUN-STATE; numbers are
  never reused (`questions: … next Q<m>`).
- `OQ-n` is a PRD open-decision carrier (`VID-QUESTION: (OQ-n) …`).
- `VID-QUESTION` at a code site is a non-blocking marker.
- A `Q<n>` answer lands in the PRD as usual. When a `Q<n>` concerns an
  `OQ-n`, its line names it.
