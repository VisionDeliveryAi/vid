# The viewer's data contract — `viewer-data 1`

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
**Figures:** counts only, never a percentage or a score.

## The parts

Types: `s` string, `n` number, `b` boolean, `a` array, `o` object; `|null`
where a value may be absent. A field marked *now* is filled in the latest
snapshot only (a past snapshot carries it empty).

### `viewer-data` (n) — `1`

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
  (s\|null) — DECISIONS.md at C, latest line per id.

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
- `agentsOpen` (a of o): `name`, `handBack` — agents started and not
  stopped, and Codex builder jobs started and not ended (a job needing
  recovery counts open; 0.9.7.2's rule); an agent's hand-back is the oldest
  brief of its role written before it started and not yet handed back.
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

A promise's capabilities come through its requirements; a decision's
through what it settles or applies to; a plan change's through the ids its
reason names. The delegated mark is never a change.

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
