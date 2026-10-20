# The viewer's data contract — `viewer-data 4`

One JSON object per snapshot, embedded in its page as `window.VID_DATA`
(v0.9.7.4 spec §3.6, R7). It is the shape the page reads (`viewer/page/`,
the owner's design): the shape of the design's sample data, plus the
additions the spec names (§3.10). Where this file and the page's reading
differ, the page's reading is the contract and this file records the
difference. `sh viewer/view.sh --check <snapshot>` checks a snapshot against
it: every required field present and of its type, and every id a part
cites present in its part.

The canvases are not in the object: `window.VID_CANVASES` maps each
canvas name a screen gives to that canvas's HTML, packaged to open offline,
each once. *(v0.9.8.1 R23)* Each canvas is written once, as the local script
asset `canvases/<key>.js` beside the snapshots — `<key>` the cache's canvas
key, from its content, the files it inlines and the library — which sets
`window.VID_CANVAS_FILES["<key>"]`; a snapshot loads the assets it names by
`<script src="canvases/<key>.js">` and maps each name to one. A changed canvas
is a new key, so an older snapshot keeps its own; file:// loads the assets,
so a snapshot, or the folder copied elsewhere, opens offline. `--check`
refuses a snapshot that loads any other script, or whose asset is not beside
it.

**Never included:** transcripts, source code, credentials. Test file paths
and reviewers' prose are included; they name code files and lines.
**Figures:** *(v0.26.10.6 R16, the owner's ruling of 2026-10-20)* counts,
durations, token counts and dollar estimates labelled "API-equivalent, not
your bill" — never a percentage, a ratio or a score; a cache share is two
counts side by side. Times are elapsed, never compute time.

## The parts

Types: `s` string, `n` number, `b` boolean, `a` array, `o` object; `|null`
where a value may be absent. A field marked *now* is filled in the latest
snapshot only (a past snapshot carries it empty).

### `viewer-data` (n) — `4`

*(v0.26.10.8)* `4` adds the `stages` part and loses nothing.
*(v0.26.10.6)* `3` adds the `execution` and `economics` parts and loses
nothing; `activity.agentsOpen` reads agents the same way as `execution`.
*(v0.26.10.2)* `2` adds the `architecture` part, three fields of each
technical decision and the `architecture` change kind. `1` was v0.9.7.4 to
v0.9.8.1.

### `meta` (o) — the run

| field | type | holds |
|---|---|---|
| `project` | s | the PRD's title, else the project folder's name |
| `label` | s | the milestones this snapshot stands for, as the index names them |
| `moment` | o | `commit` (s, 7 hex), `time` (s, UTC) — the commit read and the time the records are read to |
| `milestones` | a of s | the milestone kinds: `prd-ratified`, `setup-done`, `building-started`, `step-closed`, `slice-closed`, `checkpoint`, `run-ended`, `requested`, `now` |
| `madeAt` | s | when this snapshot's data was computed (UTC) |
| `vid` | s | the plugin's version |
| `records` | n\|null | the project's records version (`checks/records-version` at HEAD); null when absent |
| `evidenceRule` | s | the rule the test states were read by |
| `replayed` | b | a past snapshot |
| `requested` | b | made by `--at` |
| `mode` | s | `snapshot`, or `index` for `index.html`; the page reads it first |
| `fingerprint` | s | the data's cache key |
| `previous`, `next` | o\|null | the neighbour: `label`, `time`, `commit`, `file` |
| `snapshots` | a of o | every snapshot, oldest first: `label`, `moment`, `milestones`, `file`, `replayed`, `requested` |
| `nowOnly` | b | true in a past snapshot: agents, recent activity, review prose and question wording are shown in the latest snapshot only |
| `notRecorded` | a of s | panels whose records the project's records version predates: `delegated` (below 19), `built` (below 10); the page says "not recorded" for them |

### `goals` (a of o) — `id`, `name`, `text`
The PRD's goal lines (`- G<n>: <name> — <text>` under its MVP focus).

### `capabilities` (a of o) — `id`, `goal` (s\|null), `name`
The PRD's features (```` ```vid-prd-features ````, latest row per id).

### `users` (a of o) — `name`
The PRD's primary users (bold names), else its actor headings.

### `journeys` (a of o) — `promise`, `text`
Every INVENTORY row of kind `journey`: the row and its text.

### `requirements` (a of o)
`id`, `type`, `tier`, `plain` (the item's `plain:` sentence, else its
statement), `statement`, `failsIf` (s\|null), `capability` (its `feature:`,
s\|null), `phase` (`pilot` or `later`). Every effective item of the PRD that
is not a non-goal.

### `nonGoals` (a of o) — `id`, `plain`

### `screens` (a of o)
`screen`, `state`, `requirements` (a of s), `canvas` (s\|null: the name of
the canvas file at C holding the marker `@screen <screen> state=<state>`).
The design brief's manifest at C.

### `promises` (a of o) — one per INVENTORY row at C

| field | type | holds |
|---|---|---|
| `id`, `kind`, `text` | s | the row |
| `requirements` | a of s | the items it derives from that this snapshot holds |
| `capabilities` | a of s | their capabilities, each once |
| `screenState` | s\|null | its `<screen>/<state>` |
| `test` | s | its test path, or its `owed:` text |
| `step` | s\|null | its step in the plan at T |
| `state` | s | the evidence reader's: `pass`, `red`, `stale`, `never`, `owed`, `deploy-owed`, `held`, `later` |
| `stateDetail` | s | the reader's detail |
| `resultFile` | s\|null | the receipt the detail names, in each form the reader prints (`passed at <commits> (<receipt>)`, `<receipt>`, `… (last current run: <receipt>)`, `… (last run <receipt>)`) |
| `resultCommit` | s\|null | the commits a `passed at` names, else the commit the receipt's name starts with |
| `built` | b | a hand-back listed it `pass`, in a return whose `build-cost` event is at or before T |
| `judgments` | a of o | each grader's verdict on it by T, in order: `at`, `result` (`kept`, `broken`), `class` (`product`, `test`, `harness`, `-`), `prose` (*now*: the section of `.vid/verdicts/<row>.md` the verdict's brief wrote; else null). A journey's transitions in one brief are one judgment, broken if any is |

### `steps` (a of o) — the plan at T
`id`, `name`, `kind` (`feature`, `hardening`), `buildsOn` (a of s),
`promises` (a of s), `started` (the first `step-start`, s\|null), `closed`
(the last `step-closed` by T, s\|null), `done` (always null: 0.9.7.2's done
is not computed by the viewer, §7).

### `decisions` (o)
- `answers` (a of o): `id`, `amended` (b), `tier`, `date`, `q`, `a`,
  `settles` (a of s), `delegated` (b) — the PRD's effective answer ledger at
  C. `delegated` is applied when the page is assembled: true when any
  `delegated` event names the answer, whatever its time.
- `technical` (a of o): `id`, `what`, `why`, `appliesTo` (s\|null), `scope`
  (s\|null) — DECISIONS.md at C, latest line per id. *(v0.26.10.2 R13)*
  `enforced` (s\|null): its `enforced:` field as written. `added` (o\|null):
  `commit` (7 hex), `time` — the first commit on HEAD's first-parent history
  whose DECISIONS.md holds its id. `stage`: `spec` when added at or before the
  first `stage name=develop state=start` event by T, `build` after it. Both
  `added` and `stage` are null when there is no such event by T, and when C
  is not on HEAD's first-parent history.

### `architecture` (o) — *(v0.26.10.2)* how the product is put together, as recorded at C

Read from ARCHITECTURE.md, BASELINE.md and INVENTORY.md's seam rows at C,
and the plan at T. Free prose is not read. A field marked "as written" keeps
the document's text; null where a column or field is absent.

| field | type | holds |
|---|---|---|
| `modules` | a of o | the first table of ARCHITECTURE.md whose header row has a cell `Module`, to the table's end, one per row (a Module cell empty or starting `{{` skipped) — below |
| `planOnly` | a of o | `name` (as written), `steps` (a of s): a plan module name with no row |
| `services` | a of o | INVENTORY.md's `seam` rows: `id`, `service`, `purpose` (s); `chosen`, `credentials`, `probe`, `evidence`, `quirks`, `module` (s\|null), by label, as written |
| `stack` | a of o | the first table under BASELINE.md's `## Stack`: `layer`, `choice`, `ruledOut` (s\|null; the third column when its header starts `FORBIDDEN`) |
| `mustNeverBreak` | a of o | the first table under BASELINE.md's `## Tier-0 rows`: `rule`, `meaning` (s\|null) |
| `missing` | a of o | `part` (`modules`, `services`, `stack`, `mustNeverBreak`), `why` (s): each record that is absent — no ARCHITECTURE.md, no module table, a column missing, no seam rows, no BASELINE.md, no Stack or Tier-0 table. The page says "not recorded" with the reason |

A module:

| field | type | holds |
|---|---|---|
| `id` | s | its Module cell, backticks removed, a dotted label read as a path, as the import court reads it |
| `responsibility`, `ownedData`, `surface`, `dependents` | s\|null | the `Responsibility`, `Owned tables/data`, `Public surface` and `Dependents` cells, as written; null when the column is missing |
| `openToAll` | b | `all` is among its Dependents |
| `mayBeUsedBy` | a of s | its Dependents names that are module ids, compared as written; the names split on commas and spaces, as the court reads them; `none` names none |
| `otherNames` | a of s | its other Dependents names, as written (`tests/invariants`, say) |
| `mayUse` | a of s | the modules whose `mayBeUsedBy` holds it, and every `openToAll` module but itself |
| `steps` | a of s | the plan's steps whose `modules:` names it, joined as `brief.sh archrows` joins them (`/` and `.` equal, a trailing `/` ignored) |
| `placement`, `level` | s, n\|null | `open-to-all`; `level` 0 for a module no other module may use, n+1 for one a level-n module may use (the shortest way down; its own name ignored); `unplaced` for one reached so by none. Computed, not recorded |
| `decisions` | a of o | `id`, `by`, `match` (s\|null): each technical decision at C linked to it, once, by the first way it links — `module-label` (its `applies-to:` names the module), `label` (it names a row, requirement or screen code of the module's steps' promises), `mentions` (its what or why holds a path that starts with the module's id or dotted form at a path boundary and that the court's rule gives to this module; `match`: the words, as written). `scope: project` decisions are in no module |
| `files` | a of s | the paths at C the import court gives it (`/src/` segments collapsed, the longest module path that is a prefix wins); no file is read |
| `surfaceHistory` | a of o\|null | `commit`, `time`, `from` (null where the row first appears), `to`: each commit on HEAD's first-parent history up to C in which its Public surface cell changed; null when C is not on that history |

The table records what may be used, not what the code imports: the page says
"may use", never "uses". A module's promises are its steps' promises, on the
page; one is counted under every module its step names.

### `needsYou` (o)
- `questions` (a of s): *now*, RUN-STATE's open question lines as written
  (`Q<n> · asked <date> · gates <ids> · <wording>`); in a past snapshot, each
  question asked and not answered by T, from its `question` events, its
  wording "not recorded".
- `held` (a of s): the promises in state `held`.
- `delegated` (a of s): the answers marked delegated (applied at assembly).
- `answered` (a of s): *(v0.9.8.1 R22)* every answer of the effective answer
  ledger at C, newest first, by id. The page shows each from
  `decisions.answers` — its id, date, tier or delegated mark, the answer
  (`A:`) and the question (`Q:`) where still present; a field the records
  do not hold (consolidation drops `Q:`) reads "not recorded". Nothing is
  inferred.

### `activity` (o) — *now*
- `agentsOpen` (a of o): `name`, `handBack` — *(v0.26.10.6 R9)* the agents
  whose latest run is open and the Codex jobs open or needing recovery,
  read as `execution.agents` reads them; a hand-back is named only when a
  record links the agent's brief (`execution.agents[].brief`), never paired
  by time.
- `recentCommits` (a of o): `commit`, `time`, `subject` — the latest 12 on
  the first-parent history.
- `planChanges` (a of o): `what`, `why`, `at` — the latest 10.

### `counts` (o)
`promises`, `built`, `tested` (passing), `reviewed` (with a judgment),
`reviewedKept`, `reviewedBroken` (by each one's latest judgment) — each
counted on its own, never one among another; `byState` (o: state → n);
`steps` (o: `closed`, `underway`, `notStarted`).

### `changes` (a of o) — the change log
Between consecutive snapshots' data. A snapshot carries its own window's;
the index carries every window's. Every change has `kind`, `ids` (a of s),
`at` (s\|null), `capabilities` (a of s) and `window` (the file of the
snapshot its window ends at). By kind:

| kind | a change when | its own fields |
|---|---|---|
| `promise state` | the state differs; a row new since the previous snapshot reads from `new`, one gone reads to `removed` | `from`, `to`; `at` null (a window, not a time) |
| `review` | a verdict recorded in the window (one per row and brief) | `result`, `class` |
| `decision` | a PRD answer or technical decision appeared or changed | `text` (the answer, or the decision's what); `at` the answer's date |
| `plan` | a plan change recorded in the window | `what`, `why`; `ids` the step and row ids its reason names |
| `step` | a step started or closed in the window | `what` (`started`, `closed`) |
| `question` | a question asked or answered in the window | `what` (`asked`, `answered`), `text` |
| `commit` | a commit landed on the first-parent history in the window | `text` (its subject) |
| `architecture` | *(v0.26.10.2)* a module, service or stack row added, removed or changed (any recorded field differs) | `what` (`added`, `removed`, `changed`), `part` (`module`, `service`, `stack`), `text` (the module id, service name or layer), `fields` on a change (each `name`, `from`, `to`); `ids` the module id, SEAM id or layer; `at` null; `capabilities` empty. Derived fields (placement, `mayUse`, `steps`) are never a change |

A promise's capabilities come through its requirements; a decision's
through what it settles or applies to; a plan change's through the ids its
reason names. The delegated mark is never a change.

### `execution` (o\|null) — *(v0.26.10.6)* *now*, as observed at its time
Filled in the latest snapshot and the index; null in a past snapshot (the
page shows its one line). Every reading is of the records up to T and of
files at the project's home; a value the records don't hold is null.
- `observedAt` (s): T. `watcher` (o): `lastTick` (s\|null, the watcher's
  state's `tick`, as UTC).
- `sessions` (a of o): `id`, `started` (its first record), `source`
  (s\|null, as written), `model` (s\|null), `manager` (b: named by a
  `stage name=develop|fix state=start`).
- `agents` (a of o), one per agent id in `agent-start` or `agent-stop`, and
  one per Codex job (`codex:<try>`): `id`, `tool` (`claude`, `codex`),
  `session`, `type` (as written; null for a job), `started` (its first
  recorded run start), `role`, `try`, `step`, `slice`, `brief`, `rows`
  (a\|null: its hand-back's row ids), `model`, `effort` (its usage entry's;
  a job's record's), `linked` (b), `runs` (a of o: `started`, `ended`,
  `endedBy` — `stop`, `hand-back`, `cost`, `job-exit`, `job-stop` — each
  s\|null), `seconds` (n\|null: the runs' elapsed time, an open run's to
  `observedAt`; null when a start, or an end before the latest run, is not
  recorded), `state` (`working`, `returned`, `unaccepted` — handed back, no
  acceptance recorded —, `ended`, `died` (a job only), `needs-recovery`),
  `stateDetail` (s\|null), `handBack` (o\|null: `file`, `accepted` (b),
  `refusedAt` (always null: a refusal writes no record), `lines` (a of o:
  `row`, `result`, `receipt`, `reason`, as written), `report` (b)),
  `briefText` (s\|null: for agents working, agents a current attention item
  names and the 10 latest by start).
  - **Runs:** each `agent-start` opens one; it ends at the first, after it
    and before the next start, of `agent-stop` (`stop`), `agent-returned
    agent=` (`hand-back`) or `build-cost agent=` (`cost`). A run followed by
    the next start with none of them has its end not recorded, never open;
    only the latest run can be open. A stop with no start before it is a run
    with `started` null. Events are read in time order.
  - **Links, only from a record naming both,** in order: `agent-brief`
    (`unavailable` links nothing); a return file whose `agent:` line names
    the id (the newest; of equal times, the later accepted, then the higher try number); a Codex job's record. A linked agent's `try`,
    `role`, `slice` and `brief` come from the brief's path
    (`.vid/briefs/<slice>/<role>-<n>.md`, try `<slice>-<role>-<n>`); an
    unlinked agent's role is its `vid:<role>` type's. A try's step: its
    `build-cost`'s `step=`, else its brief's `step:` header, else its job
    record's.
  - **Acceptance** is recorded by `agent-returned try=` or `build-cost
    brief=`; the `agent:` line is not acceptance.
- `attention` (a of o), newest first by `at`, nulls last: `kind`
  (`question`, `run-died`, `agent-died`, `quiet`, `notice`, `stuck`,
  `needs-recovery`, `environment-left`, `no-acceptance`, `run-state`), `at`
  (s\|null), `current` (b), `text` (as written, or ViD's fixed words),
  `ids` (o: `agent`, `try`, `question`, `ticket`, `slot`, `row`, each
  s\|null). A watcher's notice is current while its `notified.<key>` stands
  in `.vid/observer.state`: its tick runs from the key's epoch to the next
  tick (the heartbeat's `observe: run activity` lines mark the ticks), and
  that tick's notice lines of the key's kind are current; a line names its
  agent only when the tick holds one quiet-agent key and one such line.
  Progress notices and question keys are left out.
- `queue` (o): `environments` (n\|null: `.vid/budget` `stacks=`), `taken`
  (a of o: `slot`, `ticket`, `since`, `workingCopy` — the folder's name),
  `running` and `waiting` (a of o: `ticket`, `type`, `role`, `try`, `rows`,
  `since` (running-at, else created), `limits` (o, seconds: `cap` as
  written, or `silence`, `startup`, `limit` when `silence=` or `limit=` is
  present), and for waiting `why` (s\|null: the `holders` file's lines)).
- `bands` (a of o): `kind` (`stage`, `slice`, `step`), `id`, `name`
  (s\|null), `start`, `end` (s\|null) — a stage to the next end of its
  name, a slice from `slice-open` to `slice-close`, a step from its first
  `step-start` to its last `step-closed` (one naming several steps closes
  each), named from the plan.
- `rework` (o): `steps` (a of o: `step`, `briefs`, `returned`, `closed`
  (s\|null), `tries`), `rows` (a of o: `row`, `briefs`, `broken` (the
  distinct grader briefs that broke it), `keptLast` (b), `tries`) — a row
  named by two or more builder or fixer returns or broken at least once —
  and `noAcceptance` (a of o: `try`, `file`, `refusedAt`).

### `economics` (o) — *(v0.26.10.6)* in every snapshot, from what was recorded by T
A past snapshot reads a return file only once its acceptance is recorded by
T, a Codex events file only once its `job-exit` is, and no request's present
state.
- `usage` (a of o), one per agent, never two: `agent`, `try`, `tool`,
  `role`, `step`, `slice`, `stage` (the newest stage started at or before
  `at`), `model`, `effort`, `at`, `kind` (`kinds`, `total`, `reported`),
  `input`, `cacheRead`, `cacheWrite`, `cacheWrite1h` (the part of
  `cacheWrite` written for one hour), `output`, `total` (n\|null each),
  `largestCall`, `beforeChange`, `beforeChangeShell` (b), `briefBytes`,
  `calls`, `survived` (b\|null), `why` (s\|null). In order: the agent's
  newest `usage` record (records 26); else a Codex job's events file once
  it has exited (fresh input is `input_tokens` less `cached_input_tokens`);
  else a `build-cost` (`total`, input and cache together, output not
  recorded; `reported` for `source=agent-tool`), given to its `agent=`,
  else to the single agent linked to its brief, else to none. An agent with
  kinds has no build-cost entry. `survived`: false when superseded, when
  every row its hand-back passed was later broken and none later kept, or
  when a builder or fixer with kinds ended with no hand-back; true when a
  row it passed was later kept or its step closed after its hand-back;
  else null (not yet known).
- `manager` (a of o), the run manager apart, one per window: `at`, `since`,
  `calls`, `total` (its older mixed total), `model`, and the four kinds
  (`input`, `cacheRead`, `cacheWrite`, `cacheWrite1h`, `output`) when a
  `usage agent=manager` covers the window — then no total.
- `tests` (a of o), one per pass (`ledger-run`): `ticket`, `batch`, `type`,
  `role`, `try`, `step`, `rows`, `asked`, `started`, `ended`, `waited` (on a
  run's first pass only), `ran`, `startup` (both from `overhead=`, else
  null), `cleanup` (the one teardown naming the pass's receipt), `outcome`
  (`passed`, `failed`, `limit`, `service-stopped`, `void`, `cancelled`;
  in the latest snapshot also `build-failed`, `failed-to-start`, `running`,
  `waiting` for requests with no pass), `proof` (b), `attempt`.
- `batches` (a of o): `ticket`, `parts`, `elapsed`, `retried`, one per
  `close-batch`; a batch's parts are never added to its own time.
- `outcomes` (o): `steps` (a of o: `step`, `closed`, `tries`,
  `testSeconds`), `rows` (a of o: `row`, `kept`, `tries` (a of o: `try`,
  `rows` — its return's line count)), `shared` (o: `managerRecords`,
  `testsOwnedByNone`, two counts). Nothing is shared out: a try is listed
  whole under every row it names.
- `prices` (o): `asOf`, `source`, `placeholder` (false), `models` (o, by
  model name: `input`, `cacheRead`, `cacheWrite`, `cacheWrite1h`, `output`,
  US dollars per million tokens) — `viewer/prices.tsv`, dated. A model not
  there, `unknown`, `default` or `mixed` is "model not priced"; an older
  total is never priced.

### `stages` (o) — *(v0.26.10.8)* in every snapshot, from the events by T and the files at C

RUN-STATE is not read: a past snapshot's RUN-STATE is generated.
- `list` (a of o), empty without `STAGES.md` at C, in stage order: `n`,
  `name`, `technical` (b, true for STAGE-0, the walking skeleton, never
  released), `state`, `closedAt` (s\|null), `commit` (s\|null, the close's
  sha). `state`: `closed` (a `stage-closed n=<n> … ready` by T); `held`
  (closed, its newest `stage-hold` by T `on`); `building` (the lowest stage
  not closed by T, unless a stage is held or a `run state=complete` is
  recorded by T); `not started` (any other).
- `staging` (o\|null): what staging was last verified at — the newest gate-2
  pass by T (its start's candidate, its end's time); null with none.
  `commit`, `at`; `stage` (n\|null): the closed stage whose close (or tag
  made by T) is that commit; `ahead`, `base` (n\|null, s\|null): from the
  newest `deploy-check target=staging` record for that commit; `by`
  (`owner`, `develop`, or null when not recorded): the `stage-deploy …
  staging=yes` after the pass; `lastFailure` (o\|null): a later gate-2 fail
  or `stage-deploy … staging=failed`, the newer — `at`, `candidate` (the
  attempt's gate-2 candidate, or the failed stage's close sha when no gate-2
  attempt started), `why` (its `why=`, null when not recorded).
- `production` (o\|null): the newest row of DEPLOYMENT.md's deploy log at C,
  the row `checks/stages.sh deploy` reads: `commit`, `at` (its Date as
  written, s\|null), `stage` (n\|null, as for staging).

**The joins `--check` adds (R15):** every agent an attention item names is
in `agents`; every step the two parts name is in `steps`; every row is in
`promises`; every try in `rework` and `outcomes` is a usage entry's, an
agent's or one in `rework.noAcceptance`.

## Differences from the design's sample data

The sample (in the release's design notes, kept in the repository's docs/, not shipped) was written before the data side
was built. Each difference, and why:
- `meta.records` is a number (or null), as the sample's.
- New in `meta`: `label`, `milestones`, `requested`, `mode`, `fingerprint`,
  `snapshots`, `nowOnly`, `notRecorded`, and `file` in `previous` and
  `next` — the spec's every-window, index and replay fields (§3.6, §3.10).
- New in a promise: `resultFile`, `resultCommit` (§3.10).
- New in a technical decision: `appliesTo`, `scope` (its label, 0.9.7.3).
- New in `counts`: `steps`.
- `meta.note` is gone: a real snapshot is not a sample.
- A change's `window`; the `new` and `removed` states in `promise state`
  changes.
- *(v0.26.10.6)* The execution and economics sample (the release's brief)
  carried five fields the page never reads, left out: `watcher.notice`,
  `watcher.noticeAt`, a request's `estimate`, a pass's `stop` and
  `prices.currency`. New beside it: `cacheWrite1h` and the state
  `unaccepted`.
