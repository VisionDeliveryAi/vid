# VID records — the contract a reader relies on

records: 21

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
replaces `<git dir>/vid-memo/selftest`). New events: `decision-labels`
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

## The viewer's own files *(19)*

`/vid view` (the plugin's `viewer/view.sh`) reads the project's documents
in git and the records above, and writes only into its own folder, outside
the project (`--out <dir>`, else `~/ViD Viewer/<project folder name>/`):
`index.html`, one `<UTC>-<milestone>.html` per snapshot, `now.html`, and
`.cache/`. They are the viewer's, not project records: nothing in VID
reads them, and their shape is the viewer's data contract,
`viewer/DATA.md` (`viewer-data 1`), not this file's version.

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
| `PRD.md` | vid-create-prd (creation, three ratification commits); the append doors — vid-add, vid-fix, vid-design's dual-write, vid-develop's two-channel appends; `checks/prd-consolidate.sh` | at those commits | the product's items, features and decisions (below) |
| `INVENTORY.md` | vid-test-inventory; row changes are standalone commits | at init and at every re-derivation | the rows that will be verified, with their `kind` |
| `DESIGN-BRIEF.md` | vid-design | at the brief and at import | the manifest: marker → REQ map |
| `.vid/SLICE-REPORTS.md` | vid-develop at every slice close; vid-fix and vid-deploy at their final report | appended | VID's computed progress at each report; *(19)* the project viewer does not read it — it computes each moment's row states with the plugin's own evidence reader |
| `.vid/metrics-events` | the courts, hooks and helpers of `checks/`, and the skills through `checks/event.sh`; *(4)* the plugin's `hooks/record.sh` | appended, one line per event; *(4)* `checks/event.sh` appends at the run's home | the run's history (Events, below) |
| `.vid/briefs/<N>/<role>-<n>.return.md` *(10)* | vid-develop's or vid-fix's session (the run manager), from a builder's or fixer's report; *(16)* the agent itself, at the path its brief's `return:` gives (written `.tmp`, then renamed) | when the agent returns, before the run manager acts on it | the hand-back block: `brief:`, `agent:` (added by the run manager — *(16)* by `sh checks/brief.sh return <file> --agent <id\|codex:<try>>`), `branch:`, `commit:`, then one line per row of the brief, `ROW-… \| pass \| <receipt>` or `ROW-… \| not \| <receipt or none> \| <reason and evidence>`; checked by `sh checks/brief.sh return`, which writes `build-cost` |
| `.vid/briefs/<N>/<role>-<n>.report.md` *(16)* | the agent | beside its return, when it has more to say than the return's lines | free text: the detail a `not` reason may point at ("see the report"); `return` refuses such a reason when this file is missing; *(18)* one written in the worktree of the return's branch, at the same path, is copied here by `return` |
| `.vid/briefs/labels-<n>.md` *(18)* | `sh checks/decisions.sh propose [--all]` | once per labelling pass (at init, step 7; once for an existing project) | the labeller's brief: the unlabelled decisions (`--all`: every one; else those citing no ROW, REQ or RULE id), each `D-NNN <text hash> \| <the line>`, the items a label may name and the return form |
| `.vid/decision-labels.proposed` *(18)* | the run manager, from the labeller's return, unchanged | after the labeller returns | one line per decision, `D-NNN <hash> \| applies-to: <items> \| sure\|unsure` or `… \| scope: project \| …`; read by `decisions.sh apply` — a label is written only where the decision's text hash still matches |
| `.vid/decision-labels.applied` *(18)* | `checks/decisions.sh apply` | appended at each labelling pass | one line per label written, `D-NNN<TAB><label><TAB>sure` or `…<TAB>widened: <why>` — a label the labeller was unsure of, a malformed proposal, or one naming an item no brief joins on, written `scope: project` instead |
| `.vid/refusals/<attempt>/` *(18)* | `checks/hooks/pre-commit`, at the run's home (a builder's worktree's refusal too) | one folder per refused commit attempt, before the hook's cleanup; kept | `meta` (`tree=` the index's tree, `head=`, then a `court=<name> rule=<rule\|-> subject=<subject\|->` line per refusing court — rule and subject from census's `FAIL  <rule>  <subject>` and inventory's `GAP  <subject>` lines, else `-`), and each refusing court's `<court>.out` and `.err`; a refusal before the courts keeps only its meta |
| `<git common dir>/vid-selftest/<key>` *(18)* | `checks/hooks/pre-commit` | after a law commit's complete self-test pass, while the key's inputs and every file under `checks/` still equal what was judged; written privately, then renamed | `pass <key>` — the self-test certificate, shared by every checkout of the repository; the key is 0.9.5's memo key; anything else in the file is a miss |
| `.vid/continuations/<step>/<try>/` *(16)* | `sh checks/brief.sh save` (the builder, the run manager, or `checks/job.sh`) | when a builder or fixer stops with unfinished work; published atomically; kept until a later return's commit contains it or `continuation-superseded` | `manifest` (`schema=`, `run=`, `step=`, `try=`, `role=`, `brief=`, `brief-hash=`, `quoted-at=`, `head=`, `landed=<commits past quoted-at>`, `report=`, then `file<TAB><path><TAB><mode><TAB><hash>` per payload), `tracked.patch` (`git diff --binary HEAD`, may be empty), `new/<path>` (each untracked file); read by `sh checks/brief.sh restore` |
| `.vid/jobs/<try>` *(16)* | `checks/job.sh` | at `start`; `run` appends the launch and the exit; `stop` the intent | `key=value` lines: `run=`, `step=`, `try=`, `brief=`, `brief-hash=`, `quoted-at=`, `worktree=`, `plugin=`, `version=`, `model=`, `effort=`, `return=`, `started=`; then `pgid=`, `pid-start=`, `supervisor=`, `supervisor-start=`, `[task=]`; `stop=<UTC>`; `exit=<n\|recovered\|not-launched>`, `[stopped=yes]`, `ended=`. Beside it `<try>.events` (Codex's `--json` stream), `<try>.final` (its last message), `<try>.err`, `<try>.save`, and the worktree `<try>.wt/` |
| `design/screens/index.json` *(21)* | the design pack (vid-design rule 6), new packs only | at import, with the pack | `{"layout": "per-screen", "files": [every file], "components": {"<screen>": [its component group files]}}` — under `layout: per-screen` design-join judges one canvas per screen and every listed file present, and briefs name a screen's own file and its components; absent, or another layout, nothing changes; `sh checks/design-join.sh --index` reads it |
| `.vid/reentry-shown.<session_id>` *(21)* | the plugin's `hooks/reentry.sh` (SessionStart `resume`) | when a resume prints the re-entry page | its UTC time: a resume within 30 minutes of it prints nothing; a resume writes no re-read debt — only a compaction does |
| `.vid/agents/<agent id>.brief` *(21)* | the plugin's `hooks/net.sh` (PostToolUse) | made exclusively at an agent's first tool call | an empty marker: that agent's `agent-brief` is recorded, so it is recorded once |
| `.vid/hook-times` | `checks/hooks/pre-commit` | one line per commit attempt, refused ones included | where the commit gate's time goes |
| `.vid/RUN-STATE.md` | vid-develop's session; `metrics.sh completion --record` writes `run: complete` | created at develop's start; rewritten at every slice open and close, handoff, state change and completion report | where the run stands now, and the open questions |
| `.vid/HEARTBEAT.md` | `checks/watchdog.sh` (the session's lines) and `checks/observe.sh` (the observer's) | appended, newest last | what is running, since when, on what evidence; *(12)* the owner's notices, `observe: notice — <text>` |
| `.vid/observer.state` *(12)* | `checks/observe.sh` (each tick, under its lock) | rewritten whole at each tick | the observer's memory, `<key> <value>` lines: `tick <epoch> <home>` (the newest tick and the home it ran for — `alive` reads both), `loop <token> <home>` (the watcher loop's acknowledgement, written as each of its ticks begins, and as a tick held back by the interval ends), `notified.<key> <epoch>` (a notice recorded, until its condition clears), `quiet.standing`, `idle`, `fail.<op>`, `epstart.<episode>`; no `notifier` line |
| `.vid/observer.pid` *(12)* | `checks/observe.sh start` | at each start of the loop | three lines: the loop's pid, the run's home (`pwd -P`) and the loop's random token; a loop whose token is not here ends |
| `.vid/observer.log` *(12)* | the watcher loop | its output, appended; cut to its last 200 lines at each start | the loop's ticks and its end, `observe loop <token> ended at <UTC>` |
| `.vid/observer.lock` *(12)* | `checks/observe.sh` (a tick) | while a tick runs, per worktree; removed at its end | `pid` — the tick's; a live holder's lock makes another tick skip, a dead holder's is reclaimed |
| `.vid/observer.start` *(12)* | `checks/observe.sh start` | while a start runs; removed at its end | `pid` — the start's; serialises two starts |
| `.vid/SUMMARY.md` | vid-develop | a section appended at every slice close | the slice in the owner's words |
| `.vid/verdicts/<ROW-id>.md` | vid-develop, vid-fix | one block per verdict | a row's attempt record, prose |
| `.vid/ledger-results/` | `checks/test.sh` | one file per ledger run that ran to its end; *(2)* inside a 0.9.6 develop run, at the run's home, with `<receipt>.tree` and `<receipt>.cases` beside each kept receipt | the receipts (below) |
| `.vid/runs/<run-id>/` *(2)* | `checks/test.sh`, inside a 0.9.6 develop run | one folder per test run while it runs, at the run's home; deleted after publish; kept only when its teardown failed | a live run (its `holder`: `pid=`, `start=`, `kind=`, `worktree=`, `slot=`, `project=`, `tree=`, and `teardown-failed <UTC>` when that happened); temporary |
| `.vid/requests/<ticket>/` *(6)* | `checks/test.sh request` (and the run it starts) | one folder per test request, at the run's home (in the checkout outside a develop run); `<ticket>` is the UTC time and 4 hex; kept | `request` (`key=value` lines: `type=`, `role=`, `runrole=`, `why=`, `rows=`, `estimate=`, `cap=`, `startup=`, *(13)* `teardown=` (the teardown between two passes the estimate counts; 0 for one pass), `cases=`, `expect=`, `no-history=`, `cwd=`, `sel=`, `dsel=`, `steps=`, `gated=`, `prove=`, `created=`; *(15)* a close batch's `batch=yes`; a chunk's `id=<ticket>/<n>`, `batch=<ticket>`, `chunk=<n>`, `phase=1\|2`, `export=`, `tree=`, `base=`), `rows` (the requested rows, one per line), `state` (`queued`, `running`, `done`, `capped`, `failed-to-start` or `stopped`), `running-at`, `result` (at most: `status=<n> ran-to-end=<yes\|no> capped=<yes\|no> report=<receipt\|none>`, `cases <status>=<n> …`, the red groups, `outside n=<n> rows=…`, `why: …`, `no-history rows=…`, *(7)* one `analyst due: <reason> request=<ticket> [rows=…] [cases=…] [group="…"]` line per test-analyst trigger that fired; *(18)* `retry: --expect <s>` on a capped result, s twice `cases=`; `build failed: no test ran — <the build's last error line>`, the result's first line, when the image build failed — no later pass, no receipt; the ticket keeps it as `build-failed`), `exit`, `cap-hit` when the cap stopped it, `outside` (the rows it reached outside the request; *(14)* the report is kept all the same and credits none of them — before 14, the kept-out candidate report beside it); *(14)* `stopped` — the cause line when a service died while the tests ran (`stopped: service <name> exited code <c>\|killed for memory at <UTC> — see services.<pass>.txt`), also the result's first line; `services.<pass>.txt` (`inline`, `deployed`) — inside a develop run, each pass's containers' end states before its teardown, a header line then one line each, `<name> state= exit= memory-kill=yes\|no health= restarts= started-at= ready-at= finished-at=` (`ready-at` the first passing readiness check Docker kept, else `-`; *(20)* renamed `kept-healthy-at=` — the first passing check Docker still kept in its rolling health log when VID read it, not when the service became ready); `timeline.<pass>.log` — each pass's test-environment log lines with their times (the last 20,000, at most 20 MB), after its result and before its teardown; *(21)* a pass that is red or ran short of its end keeps `timeline.<pass>.log.gz` instead — its whole log, compressed, at most 100 MB keeping the end (when cut, its first line says so); *(21)* a pass stopped short (a cap, a cancel, any stop) keeps it too, and `last-lines.<pass>.log` — each service's last 200 lines — both taken before its down; *(21)* `tests-at` — when the tests container was first seen running (the cap counts from it); *(21)* `slept` — the seconds of host sleep the cap watcher saw (a tick gap over 40 s), not counted against the cap, recorded as `slept=<n>` in `request` and said in `result` as `host slept <n> s during this run`; *(21)* `result`'s `deployed pass: ended outside completed (exit <n>), no receipt — the inline pass's receipt is kept` when only the deployed pass of an iterate ended outside completed; *(11)* `holders` — while the run waits for a test environment, one line per held slot on the host as of its latest try (`stack.<k>: held by pid <pid> — repository <path>, compose project <name>, for <s> s`, or `stack.<k>: STALE — pid <pid> is gone (repository <path>, compose project <name>), <s> s old. …`; *(15)* a chunk's `giving way: request <ticket> waits and this batch holds <n> of <k> slot(s)`), left as last written; *(13)* `timeline.log` — inside a develop run, when its inline pass's `overhead=` is over 120 s, the test environment's own log lines with their times (Compose `logs --timestamps`), saved before its teardown (*(14)* replaced by `timeline.<pass>.log`); *(13)* `run` — inside a develop run, the run folder's path: the result, `exit` and the final `state` are written when the last pass is published, before the final teardown, so a request can be `done` while its run folder and slot are still held (*(21)* written once the folder and its holder exist, and removed with the folder); `log`, `passes`, `pid`, `supervisor`, `watcher` are its working state; *(15)* a close batch's ticket also holds `groups` (its groups as asked, one per line: `G <phase> <phase.line> <rows,…> <inline words> <deployed words> <the line>`, tab-separated), `batch` (`id=`, `tree=`, `base=`, `steps=`, `chunk-seconds=`, `stacks=`, `export=`, `frozen-at=`, `frozen=computed\|reused from <ticket>`), `frozen/` (close-rows' required rows with sets, phases and shapes, the expected cases' inputs and the population reference, as frozen at its start; `key` — the tree, steps, slice, rows file and plan it was frozen for and the events line count then: a later batch reuses it while nothing else close-rows reads has changed), `layout` (`<n> <phase> run\|adopted <seconds\|source chunk>` a chunk a line), `receipts` (`<chunk> <receipt path> inline\|deployed`, the newest sub-ticket's each), `export` while it runs, and `chunks/<n>/` — a sub-ticket with the files above plus `groups`, `phase`, `outcome` (`green`, `red`, `incomplete`, `retry`, `stopped`), `why`, `judged`, `receipts`, and `adopted` (`<ticket>/<n>` of the chunk it took); `<n>-retry` is its one retry; a chunk never launched ends `stopped`. The parent's `result` is `green`, `red phase <p>[, rows <ids>][, chunks <ns>]`, `incomplete phase <p>, chunks <ns>` or `stopped: …`, then `chunks <n> retried= adopted= stacks-max= wall= chunk-seconds-sum=`, `incomplete chunk=<n> why=…` and `red row=<id> case=<case>` lines, a `chunk <n> phase=<p> <outcome> [adopted=…] [report=…]` line each, and the chunks' `analyst due:` lines; *(16)* `try=` in `request` for a builder's or fixer's ticket; `pid-start` beside `pid`; a `cancel` mark (`by=`, `at=`); the state `cancelled` (exit 77, the result's first line `cancelled by <who>`) |
| `.vid/budget` | vid-init (`stacks=`, `memory-headroom-mb=`); the owner; *(2)* `checks/testenv.sh record` | at init; *(2)* at develop's test-environment step | `key=<number>` lines: `stacks`, `memory-headroom-mb`, `claims-per-slice`, `wall-hours-per-slice`, `court-seconds`; *(10)* `builder-context-tokens` (400000); *(15)* `chunk-seconds` (a close batch's chunk size in recorded case seconds, default 1200); *(2)* `unverified-rows` (60 per environment), `env-mb` (one environment's measured peak), `testenv=proved\|one` (two or more environments proved side by side, or one); *(13)* `testenv=proved harness=<cksum of docker-compose.test.yml>` — the harness it was proved on: admission and the checkpoint use `stacks=` only when it matches the requesting checkout's harness, else one environment; a bare `testenv=proved` reads as proved on no known harness; *(12)* `progress-notify` is gone — nothing is sent; *(17)* `builders-target=<n>`, the owner's: how many builders at once, shown by the progress table, never enforced |
| `.vid/close/<slice>.rows` *(3)* | vid-develop (the orchestrator or builder that made the change) | before each selected close, from the closing steps' diff | the rows the builder names as affected, one line each — `ROW-<id> \| <one-line reason>` — and `note \| <what was checked>` for a change to shared paths or uncited code; read by `checks/metrics.sh close-rows` as set 5 |
| `.vid/plans/<hash>.plan` *(2)* | `checks/plan.sh change` | every accepted plan, copied whole when its change is recorded; never edited or removed | the plan a `step-start` was admitted under — with the events, what every started step held, rebuilt without RUN-STATE |
| `.vid/PROGRESS.md` *(2)* | `checks/progress.sh --record` (the observer hourly and after a plan change; the session) | a table appended per update, newest last | the progress update — the fixed table below; the newest section is current |
| `.vid/home` *(2)* | `checks/plan.sh home --brief <f>` | a builder worktree's first act | one line: the absolute path of its run's home, where its receipts, events and amendments land |
| `.vid/grades/YYYY-MM-DD-grade.md` | vid-grade | one per grade (`-2` for a second the same day) | the ranked findings table, with an `adjudication:` cell per row; *(4)* the header's `graded: <commit, 12 hex>` and `dirty: yes\|no` (the worktree had uncommitted changes) name what was graded |
| `.vid/run` *(4)* | `checks/event.sh` (through `checks/run.sh id`) on every `stage … state=start`; `checks/run.sh new` and `label` | created at the first stage start at the run's home; renewed when the project was copied (its `path=` is not the home's) or by `run.sh new`; `team=` and `series=` set by `run.sh label` | `key=value` lines: `id=` (the UTC time plus 6 hex), `path=` (the home when the id was made), `start=` (HEAD then, or `none`), `parent=` (the id it was renewed from, or `-`), `parent-start=` (the parent's `start=`), `copied-at=` (HEAD when a copy was detected, or `-`), `created=`, `team=`, `series=` (`unknown` until set). One id per trial, kept through handoffs, restarts and refreshes of `checks/` |
| `.vid/run.parent` *(4)* | `checks/run.sh` | when `.vid/run` is renewed | the file it replaced, whole |
| `.vid/plans/decisions/<id>.why` *(4)* | `checks/plan.sh change`, inside a develop run under the gate | one per plan change, accepted or refused; written once, never edited | `key=value` lines: `id=` (the UTC time plus the candidate hash), `at=`, `result=accepted\|refused`, `what=`, `prev=` (the last accepted plan's hash, or `none`), `candidate=` (the hash of the raw block, taken before validation), `commit=` (HEAD), `trigger=`, `evidence=`, `expect=`, `alternatives=` (`-` when not given; the trigger, expectation and alternatives are the model's declaration), `refusal=<first line>` when refused; *(17)* `not-needed-by=<step ids>` and `not-needed-why=<one line>` when given. What moved between two plans is not stored: it is computed from the two kept blocks. *(17)* A strategy decision, `<UTC>-strategy.why` (written by `checks/plan.sh strategy`): `id=`, `at=`, `result=accepted`, `what=strategy`, `set=`, `by=owner`, `commit=`, then a line `words:` and the owner's words verbatim to the end of the file |
| `.vid/plans/decisions/<id>.plan` *(4)* | `checks/plan.sh change` | beside each `.why` | the candidate block whole, accepted or refused, a block that does not parse included |
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
    pause-N <sum>`. The tier `human` is the owner's decision,
    `model_proposed` a decision VID took; `importance: priority` marks the
    owner's big decisions.
  - ```` ```vid-prd-mechanisms ````, ```` ```vid-prd-contract ````,
    ```` ```vid-prd-findings ```` — the thesis mechanisms, the coverage
    contract, the review findings.
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
  deploy gate N — …` is paid at deploy).
- `rule`, `seam` and the governance rows sit in the same block; their
  first field is the word `rule` or `seam`.

### DESIGN-BRIEF.md

The ```` ```vid-design-manifest ```` block, one row per surface × state:
`<screen> | <state> | REQ-NNN,REQ-NNN | pins: …`. The marker is
`<screen>/<state>`.

### .vid/SLICE-REPORTS.md

Sections, newest last; **the newest section is current**:
- `## slice <N> <UTC>` — vid-develop at each slice close;
- `## fix <UTC>` — vid-fix at its final report;
- `## deploy <UTC>` — vid-deploy at its report.

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

    run: active|waiting|stopped <reason>|complete
    session: <the id of the session running the build>
    questions: <k> open · next Q<m>        (or: - · next Q<m>)
    slice: <N> open|closed    since: <UTC>    commit: <sha>     (slice: - before the first)
    modules: <paths>
    claims: <ROW-id> …
    receipt: <report name>|none    briefs: <files>|-
    held: <ROW-id> …|-
    plan: required                          (2) written by 0.9.6 develop at its start
    now: <one line>|-                       (2) the build's own words, `checks/progress.sh --now`
    strategy: depth-first|breadth-first     (17) absent: depth first; written only by `checks/plan.sh strategy … --by owner`

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
  side, so the fields add up to more than `seconds=`.

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

A grader brief's patches,
one per row in proof scope, in `grader-<n>.faults/<ROW-id>.patch`, and its
return's `fault: ROW-<id> | target=<case> | control=<case> | patch=<path>`
lines.

### Receipts — .vid/ledger-results/

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
  materialised probes).

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
fails when code or a skill writes one that is not.

| type | fields | writer | when |
|---|---|---|---|
| `adjudicated` | `class=<name> promoted\|advisory\|deleted tp=<n> fp=<n>` | vid-develop | a report-only class decided at the first slice close |
| `agent-returned` | *(16)* `role=<role> n=<n> try=<try\|->` *(21)* `agent=<the return's agent id>` | `checks/brief.sh return` | a builder's or fixer's return passes the check, once per brief |
| `brief-written` | *(16)* `path=<brief> role=<role> try=<try\|-> bytes=<n>` | `checks/brief.sh write` | each brief written |
| `builder-tool` | *(16)* `set=<claude\|codex> by=owner`, or `paused reason=codex-limit reset=<time\|unknown>` | `checks/job.sh` | the owner switches the builders' tool; Codex runs out |
| `decision-labels` | *(18)* `applied=<n> widened=<n> changed=<n> skipped=<n>` | `checks/decisions.sh apply` | the labelling pass applied: labels written, of them written `scope: project` because the labeller was unsure (or the proposal could not be used), decisions changed since their proposal (left unlabelled), proposals skipped |
| `delegated` | *(19)* `answer=<A-id>` | `checks/metrics.sh delegated` | vid-develop marks an answer it wrote under the owner's delegation, in the step that commits it, and once at the first session after the 0.9.7.4 refresh for the answers taken before; refused for an id not in the PRD's effective answer ledger, an answer of tier `model_proposed`, and an id already marked; the mark says how an answer was made, never when |
| `deferred` | *(17)* `row=<ROW-id> kind=product\|test why="<one line>" from=brief:<path>#<row>\|receipt:<name> by=<who>` | `checks/metrics.sh defer` | under breadth first, an edge finding — a row in a hardening step with an eligible BREACHED verdict — waits for its step; never a core or protected row |
| `deferred-resolved` | *(17)* `row=<ROW-id> by=commit:<12 hex>\|verdict:<brief>` | `checks/metrics.sh defer-resolved` | an open deferral's disposition — never a verdict |
| `context-high` | *(16)* `n=<tokens>` | `checks/brief.sh write`, `return` | the run manager's context is above 350000, once per crossing (none since its session's latest `session` event) |
| `context-window` | *(16)* `requested=<n>\|declined` | vid-develop, vid-init | the owner answers the compaction-setting question |
| `continuation-restored` | *(16)* `try=<the successor's> from=<the package's>` | `checks/brief.sh restore` | a package restored |
| `continuation-saved` | *(16)* `try=<try> files=<n> bytes=<n>` | `checks/brief.sh save` | a package published |
| `continuation-superseded` | *(16)* `try=<try> [why=<…>]` | vid-develop | the run manager drops a package it will not restore |
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
| `analyst-due` | *(7)* `request=<ticket> reason=cap\|setup\|slow [rows=<ROW-id,…>] [cases=<case id,…>] [group="<first message>"]` — `rows=`/`cases=` the slow cases, by row when the evidence join credits one, else by case id; *(15)* a close batch's chunk as `request=<ticket>/<n>`; *(21)* `group="<message> (<n> case[s]); …"` — the groups of the red cases over 60 s that tripped the setup trigger, each with its count | `checks/test.sh` | a request's completion, after `result` and before the final `state`, once per trigger that fired: capped (*(21)* not when the host slept during the run); 5 or more red cases each over 60 s; a case over 240 s |
| `agent-start` | *(4)* `session=<session id> agent=<agent id> type=<agent type>`; *(9)* `transcript=<the parent session's transcript, as the hook receives it>` before `at=` — the agent's own is `<it without .jsonl>/subagents/agent-<agent id>.jsonl` | the plugin's `hooks/record.sh` (Claude Code's SubagentStart) | an agent starts; a resumed agent starts again under the same id; its brief, role and step are joined at export, never here |
| `agent-stop` | *(4)* `session=<session id> agent=<agent id> type=<agent type> transcript=<the agent's transcript path>` | the plugin's `hooks/record.sh` (SubagentStop) | an agent stops; no "accepted" status is recorded |
| `build-cost` | *(10)* `role=<builder\|fixer> slice=<N> step=<id\|-> brief=<path> rows=<n> rows-passed=<k> peak=<t> total=<t> before-change=<t\|unknown>[ shell]` — tokens of the agent's own transcript: per API call input + cache read + cache creation, the largest and the sum; before-change the call that made the first product mutation under the step's modules, ` shell` when only a shell call could have (possible, not proven); `unknown` when the transcript is not found *(16)* then `tool=claude\|codex model=<m\|unknown> effort=<e\|unknown> brief-bytes=<n>` — the effective model and effort from the agent's transcript (Codex: its job record); for a Codex builder the tokens are read from its events file by their own reader (`turn.completed` usage, summed per turn), `peak=unknown` (an exec is one turn, so no call's context is readable), `before-change=unknown`; for a grader, test-author or analyst (`sh checks/brief.sh cost <brief> --agent <id>`) `step=-`, `rows-passed=-`; *(21)* `brief=` relative to the home (an older record's absolute path is still read, up to the next ` key=`, its home prefix removed); *(21)* for a cost with no transcript found, `cost … --tokens <n> --source agent-tool` records `total=<n>` and `source=agent-tool` after `before-change=` — the caller's own total, reported, never `unknown`; *(21)* `agent=<the agent's id>` last before `at=` — an agent whose `build-cost` or `agent-returned` carries its id after its latest `agent-start` is finished (resume and the watcher never call it quiet); older records without it stay as they are | `checks/brief.sh return` | a hand-back passes the check, once per brief |
| `amended` | `row=<ROW-id> sha=<commit>` *(20)* `by=obligation\|fail-if` — the row's own obligation changed, or an item it derives from changed its fail-if; only `obligation` clears its authority flag | `checks/hooks/post-commit` | after a commit that changed the row's obligation or its item's effective fail-if; wipes the row's verdicts; *(2)* inside a 0.9.6 develop run, written at the run's home |
| `attempts` | `row=<ROW-id> n=<k>` | (legacy, 0.9.2) | no longer written; read as 0.9.2 read it |
| `brief-check` | `path=<brief> result=ok\|fail` | `checks/brief.sh` | every brief check — including the observer's, so never session activity |
| `checkpoint` | *(3)* `n=1\|2 report=<the kept checkpoint receipt> built=<b> regressions=<k> base=<the commit it tested>` | `checks/metrics.sh checkpoint --n <n> --to <report>` | a checkpoint recorded once its receipt holds every expected case of every built row (*(15)* of the population its `.rows` carries); `regressions=` counts built rows that passed before it and do not in it — checkpoint 2 runs only when checkpoint 1's is above zero (*(15)*: due at two thirds whatever checkpoint 1 found) |
| `close-batch` | *(15)* `id=<ticket> chunks=<n> retried=<n> adopted=<n> stacks-max=<k> wall=<s> chunk-seconds-sum=<s> load-start=<1-min load> load-end=<1-min load>` | `checks/test.sh` (the batch's supervisor) | a close batch ended, green or not: `wall` from its first chunk's start to its end, `chunk-seconds-sum` each chunk run's seconds from its slot to its result, `stacks-max` the most at once |
| `completion` | `unmet=<U> strict-gaps=<G>` | `checks/metrics.sh completion --record` | at the completion report |
| `court` | `name=inventory\|census\|coverage seconds=<s>` | those courts' report modes | court runtime |
| `court-refused` | *(18)* `court=<name> rule=<rule\|-> subject=<subject\|-> tree=<the index tree> attempt=<the refused event's attempt>` | `checks/hooks/pre-commit` | one per refusing court of a refused commit, beside `refused`; its record is `.vid/refusals/<attempt>/`; progress counts them by court and rule |
| `deploy-confirm` | *(4)* `state=ask\|answer what="<the question>" [result=yes\|no]` | `checks/deploy-gate.sh confirm`, called by vid-deploy | an owner confirmation asked, and answered |
| `deploy-gate` | *(4)* `gate=1\|2\|3 state=start candidate=<commit> env=<name>`; `state=end result=pass\|fail [rollback-target=<ref>]`; `gate=1 state=skipped reason=first-deploy` | `checks/deploy-gate.sh`, called by vid-deploy | a gate opens, closes, or is skipped; never refused — a gate 3 start with no gate 2 record is written like any other. A missing record means "not recorded", not "not done" |
| `deploy-rollback` | *(4)* `gate=1\|2\|3 why="<one line>"` | `checks/deploy-gate.sh rollback`, called by vid-deploy | a rollback starts |
| `died` | `reason=<the API error type, or usage-limit-waiting> session=<id> [details="<text, 200 characters at most>"]` | the plugin's `hooks/stop-failure.sh` (StopFailure, and the Notification types `quota_auto_resume_stale` and `quota_auto_resume_disabled`) | the run's own session stopped on an API error, or a usage-limit pause is left waiting; never for a subagent or another session; stands until a newer `run` event |
| `engine-only` | `breach row=<ROW-id> engine=<name>` | vid-develop | a breach seen in one test engine only |
| `failif-amendment` | `n=<k>` | `checks/hooks/pre-commit` | a PRD change counting amended items or removed fail-ifs (written before the message check, so a refused commit can still record it) |
| `harness-upgrade` | *(13)* `state=due\|dispatched\|asked\|applied\|declined harness=<cksum of docker-compose.test.yml as it was, the original harness>`; *(14)* `target=<the rules version the step brings the harness to>` — none reads as 1; states are keyed by hash and target, so a target-1 decline leaves target 2 due | vid-develop (`sh checks/event.sh`) | the upgrade step for a harness with no `rules:` line (`sh checks/harness.sh rules`, at develop's start): `due` once, `dispatched` with the first admitted step's upgrade pass, `asked` with the owner's law question, then `applied` (after the law commit) or `declined`; the latest state for the hash is where a resumed run goes on; events only — a declined hash is due again once the harness file changes |
| `incident` | `slice=<N> <what>` (free text; `harness row=<ROW-id> …` for a harness breach) *(16)* `slice=- coordination-fault try=<try> ticket=<id> ledger=<path>` (`checks/job.sh status`: a job's ticket outside the run's home) | vid-develop | an incident |
| `invalidated` | `slice=<N> <why>`; *(2)* `slice=<N> report=<receipt> <why>` names the void receipt | vid-develop | the close run invalidated; *(2)* any run found void — its receipt is then no current result |
| `ledger-run` | `seconds=<s> kind=full\|deployed\|scoped report=<name>\|none status=<n> [role=builder\|fixer\|close\|grader]`; *(5)* `role=` always present — also `test-author` and `testenv` (a scoped run, like a builder's), and `-` for a run outside a develop run that names no role; *(6)* `role=orchestrator` (the orchestrator's own `prove-red`); a request's run adds `request=<ticket> type=prove-red\|iterate\|close\|checkpoint\|full\|deployed rows=<n> estimate=<s> cap=<s> [expect=<s>] [no-history=<n>]` (*(15)* a close batch's chunk: `request=<ticket>/<n>` and, after those, `batch=<ticket>`), then `[outside=<n>]` on a pass kept out of the evidence (`report=none`; *(14)* on a kept pass whose cases reached `<n>` rows outside its frozen rows, none credited) and `capped=yes` on a run stopped at its cap (`report=none status=130`) — *(14)* or `stopped=service:<name>` in its place on a run stopped by a service's death, and `why="<line>"` last before `at=`; a plain run outside a develop run adds `form=legacy` after `role=`; *(2)* inside a 0.9.6 develop run also `tree=<sha> run=<run-id> [waited=<s>] [teardown=failed]`, and `report=` names the kept receipt; *(13)* inside a develop run a pass is published before its teardown, so `seconds=` holds no teardown and `teardown=failed` rides only a capped run's event — a failed teardown is its own `teardown-failed` event; *(13)* each pass published inside a develop run adds `overhead=<s>` after the request's fields (before `why=`): its seconds minus the sum of its cases' seconds in its `.cases`, never below 0 — the image build, the services, installs and the runner's start; a run outside a develop run keeps no `.cases` and writes none; *(3)* `kind=close` for a selected close's inline pass and `kind=checkpoint` for a checkpoint's (their deployed passes are `kind=deployed`), with `role=checkpoint` *(16)* `try=<try>` after the request's fields when its ticket carries one; a cancelled run `report=none status=130 … cancelled=yes` | `checks/test.sh` | every ledger run; *(2)* written at the run's home *(20)* `purpose=proof` on a proof request's run, its receipt named `.proof.`: cost and export read it; nothing that credits, claims, briefs, estimates or triggers does. |
| `owed-close` | `slice=<N> n=<k>` | vid-develop | owed rows at slice close |
| `paid` | `row=<ROW-id> via=ledger\|browser\|census\|deploy` | vid-develop | a row paid, and by which channel |
| `plan-change` | *(2)* `what=create\|add\|drop\|split\|merge\|reorder\|lanes\|rows\|other hash=<12 hex> why="<one line>"`; *(4)* `decision=<id>` before `why=`; *(17)* `what=edge` (rows moved into a hardening step), `not-needed-by=<step ids>` before `why=` when given | `checks/plan.sh change` | every accepted change to the plan block, with its reason; the block is kept in `.vid/plans/<hash>.plan`; *(4)* its decision record in `.vid/plans/decisions/<id>.why`. A refused change writes no event, only its record |
| `progress` | *(2)* `trigger=hourly\|plan-change\|session by=observer\|session rows-passing=<n> rows-left=<n> estimate=<lo>-<hi>\|none` | `checks/progress.sh --record` | a progress update; `by=observer` lines are never session activity |
| `question` | `n=<n> state=asked gates=<ROW-ids and paths, comma-separated, or all>`; `n=<n> state=answered` | vid-develop | a develop question asked (after its `Q<n>` line is written), and answered (after the PRD append) |
| `red-observed` | *(2)* `row=<ROW-id> report=<receipt> case=<case id> assertion="<the failing assertion>"` | vid-develop | a new row's test observed failing on its real check, before its `proved-red:` stamp |
| `re-verdict` | `slice=<N> round=<r> breached=<k>` | vid-develop | a re-verdict round |
| `regressions` | `slice=<N> n=<k>` | vid-develop | at slice close |
| `refused` | *(4)* `phase=pre-commit\|commit-msg\|admission by=<court or rule> attempt=<the UTC time plus 4 hex> [step=<id>]` | `checks/hooks/pre-commit` (`by=` the courts that refused, comma-separated, or `protected-paths`, `law-dirty`, `law-standalone`, `purpose-header`, `decisions-enforced`, `decisions-promissory`, *(18)* `decisions-label`, `index-copy`, `red-stamp`, `prd-grammar`, `selftest`); `checks/hooks/commit-msg` (`decisions`, `tests-by`); `checks/plan.sh` (`rule-A`, `rule-B`, `dirty-currency`, `unrecorded-plan`, `no-step`, `rows-not-of-step`, *(17)* `graded`, with `step=`) | every refusal of a commit or an admission, at the run's home |
| `reissued` | `row=<ROW-id> why=<answer id>` *(8)* `[rounds=<N>]` — the owner's allowance: the row is held `reason=rounds` once N distinct briefs breach it with no KEPT | vid-develop | an owner ruling releases a held row |
| `reverted` | `row=<ROW-id>` | (legacy, 0.9.2) | no longer written; wipes as 0.9.2 read it |
| `rows-paid` | `slice=<N> n=<k>` | vid-develop | at slice close |
| `run` | `state=<the run: value>` — `state=active`, `state=waiting`, `state=stopped <reason>`, `state=complete`; the reason is free text | vid-develop | every write of RUN-STATE's `run:`; the newest one's time starts the run's current episode |
| `session` | *(4)* `id=<session id> source=<as Claude Code gives it> [model=<when given>] transcript=<path> vid=<plugin version>` | the plugin's `hooks/record.sh` (SessionStart), wherever the project already has `.vid/` | a session starts; the session that creates a project has none (it starts before `.vid/` exists) — the export recovers it from the stage events' `session=`; nothing is backdated |
| `slice-close` | `slice=<N> sha=<commit>` | vid-develop | a slice closes |
| `slice-modules` | `slice=<N> <path> …` | vid-develop | a slice opens: the modules it touches |
| `slice-open` | `slice=<N> sha=<commit>` | vid-develop | a slice opens |
| `slot-reclaimed` | *(11)* `slot=<k> project=<the holder's compose project> holder-pid=<pid> age=<s>` | `checks/test.sh` | a run that found no free test environment freed a host slot left by a run that died: its holder pid gone, Docker answering, no container, running or stopped, of that compose project left; written at the run's home, once per slot freed |
| `stage` | `name=<verb> state=start\|end\|pause-1\|pause-2\|pause-3 session=<id> [records=<n>]`; *(4)* `run=<the run id>` on every `state=start`, before `at=` | every verb but vid-grade, in a VID project | a verb starts or ends; vid-create-prd also at each pause commit; `records=` is the version the verb writes (vid-develop 8, vid-fix 8, vid-deploy 4, the others 1) *(20)* vid-develop and vid-fix write `records=20`. |
| `stall` | `op=<op> elapsed=<s> envelope=<s>` | `checks/watchdog.sh` | a session's check of an operation past its envelope |
| `step-closed` | *(3)* `step=<id> report=<the kept receipt the claim read>`; *(15)* `batch=<ticket>` from a claim by batch, `report=` its newest constituent | `checks/metrics.sh claim --steps` | a claim on a selected close, or on the final full run, succeeded; the step's rows are then eligible at every later close |
| `step-done` | *(17)* `step=<id>` | `checks/metrics.sh step-state` | the first time a step is computed done; a stamp for measurement, never read back as done |
| `step-rows-passing` | *(17)* `step=<id> tree=<12 hex> receipts=<names, comma-separated>` | `checks/metrics.sh step-state` (read at `brief.sh return` and by `progress.sh`) | once per feature step, the first time every row of it passes (or is owed, held or later) on receipts of one tree: the time it was seen |
| `step-start` | *(2)* `step=<id> plan=<hash>`; *(3)* `base=<commit>`, HEAD at admission (absent on a step started before 0.9.6.1) | `checks/plan.sh` (a builder or fixer brief checked ok, or `plan.sh start <id>`) | a plan step's first admission |
| `strategy` | *(17)* `set=depth-first\|breadth-first by=owner decision=<id>` | `checks/plan.sh strategy` | the owner sets the run's strategy; the words are in `.vid/plans/decisions/<id>.why` |
| `teardown` | *(13)* `seconds=<s> report=<the pass's kept receipt\|none>` | `checks/test.sh` | inside a develop run, each pass's teardown that succeeded, after the pass is published (so its `ledger-run` seconds hold no teardown); written at the run's home |
| `teardown-failed` | *(13)* `request=<ticket\|->` `project=<compose project>` | `checks/test.sh` | inside a develop run, a teardown failed — between two passes (the later pass did not start) or after the result (the result stands); the slot and the run folder are kept, both holders marked `teardown-failed <UTC>`; written at the run's home |
| `testenv` | *(2)* `stacks=<k> env-mb=<n> docker-mb=<n> other-mb=<n> case-seconds=<s> compose=<version> resets=yes\|no` | `checks/testenv.sh record` | develop's test-environment step: the environments recorded, with the figures they were picked from |
| `tokens` | `slice=<N> phase=build\|verdict\|fix\|re-verdict\|review n=<k>` | vid-develop; the append doors and reviews (`phase=review`, `slice=0` before the first slice) | tokens spent |
| `verdict` | per row: `slice=<N\|fix-<date>> row=<ROW-id> result=KEPT\|BREACHED class=product\|test\|harness [transition=k/n]` *(8)* `[scope="<the grader's question>"]` `brief=<path> quoted-at=<sha>` — `scope=` on a BREACHED holds the row `reason=scope`; per slice: `slice=<N> claimed=<k> breached=<k>` | vid-develop; vid-fix's re-grade | a grader's verdict; the slice's tally *(20)* A failed fault proof writes `verdict … result=BREACHED class=test proof=<the faulted receipt> brief=<the grader brief> quoted-at=<sha>` (`checks/metrics.sh proof`). |
| `wall-clock` | `slice=<N> seconds=<s>` | vid-develop | at slice close |
| `test-proven` | *(20)* `row=<ROW-id> result=proven\|inconclusive why=<-\|unappliable\|no-baseline\|no-fault-run\|shape\|baseline-tree\|fault-tree\|missing-case\|baseline-failed\|control-<status>\|target-<status>> fault=<patch> clean=<receipt\|none> red=<receipt\|none> target=<case> control=<case> commit=<12 hex> file=<test path> blob=<blob> helpers=- obligation=<cksum> authority=<digest> brief=<grader brief>` | `checks/metrics.sh proof` | a fault proof judged; a conclusive failure is a `verdict … class=test proof=<receipt>` instead |
| `authority-kept` | *(20)* `row=<ROW-id> sha=<HEAD>` | `checks/brief.sh authority --kept` | a test-author pass kept the row as it is under its changed authority; its flag clears until the bundle changes again |
| `selftest-retried` | *(21)* `case=<path from checks/selftest/> result=convicts\|failed` | `checks/selftest/run.sh` | a case listed in `checks/selftest/flaky` failed in the suite and ran once more, alone, where a `.vid/` is present; a run a retry rescued publishes no self-test certificate and is never evidence |
| `agent-brief` | *(21)* `agent=<agent id> brief=<path relative to the home>\|unavailable` | the plugin's `hooks/net.sh` (PostToolUse) | at an agent's first tool call in a VID project, every role, once (`.vid/agents/<id>.brief`); the brief read from the agent's first user entry as the context net reads it, without its builder-and-fixer gate; `unavailable` when none is found |

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

## The question numberings

- `Q<n>` is a develop-time question, a line in RUN-STATE; numbers are
  never reused (`questions: … next Q<m>`).
- `OQ-n` is a PRD open-decision carrier (`VID-QUESTION: (OQ-n) …`).
- `VID-QUESTION` at a code site is a non-blocking marker.
- A `Q<n>` answer lands in the PRD as usual. When a `Q<n>` concerns an
  `OQ-n`, its line names it.
