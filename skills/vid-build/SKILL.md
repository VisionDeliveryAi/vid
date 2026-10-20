---
name: vid-build
description: Internal — invoked by vid-develop and vid-fix, and loaded by every builder and fixer; not a verb, never run by the owner. The rules for building a step: the first moves, test requests, law first, the rhythm, green without editing tests, the iterate run, the commit gates, decisions, the hand-back.
user-invocable: false
---

# vid-build

A builder or fixer lands no law — no line in the regions `checks/lawfiles`
names, no PRD change, nothing under checks/, no weakened ledger test, no
protected design/ change, no DEPLOYMENT.md change — and hands it back
instead. Start from your brief: its locations say where your tests are;
read files by range, keep search output short. After a compaction,
re-read your brief and this skill in full before any other work.

## Your first moves (v0.9.7.1 3.1, 3.3)

1. **Check out your base.** Your first command, in your fresh worktree:
   `git checkout -b <the brief's branch:> <the brief's quoted-at:>`. It
   never resets a branch that exists. If it fails — the branch exists, the
   commit is missing — make no edit: hand back every row `not | none |
   wrong base: <the error>`, and the run manager writes a new brief.
2. **Restore a continuation** when your brief carries `## 14
   continuation`: `sh checks/brief.sh restore <your brief>`. It applies the
   saved work all or nothing, or refuses and changes nothing; a refused
   patch is yours to reconcile by reading the package. Restored code
   certifies nothing.
3. **Run your rows first:** your brief's section 6 request, then its wait
   (Requests, below). Section 5's results are history — earlier trees, not
   evidence for this brief.
4. **Sort each row by that result, on your own tree:**
   - **already passing** — every case of the row passed. No test-driven
     work is indicated; but a counterexample, a correction or another
     obligation your brief quotes (section 7's attempt record, section
     12's notes) still stands and is worked as briefed. A passing test
     never discharges a BREACHED verdict;
   - **failing with a clear message** — a real assertion failed: read
     where it points;
   - **implementation absent** — the tests ran and the product behaviour
     is not there: build it.
5. **Leave everything else unresolved and name it in your hand-back:** a
   missing test, a collection or setup error, a capped, refused or
   incomplete run. A missing test goes back to the run manager. You may
   read code to understand a setup error.
6. **Read from the failure outward:** the failing line, then the helpers
   it calls, then the product code it reaches. Look at a file's outline
   (its functions) before its body, and read in windows.

Rows that all pass, with no obligation briefed, are handed back without an
edit: they pass by that receipt.

## Requests (v0.9.7.0.2 3.1–3.3; moved here whole from vid-test-manager, v0.9.7.1 3.2c)

**Ask.** One command, which answers at once:

```
sh checks/test.sh request --type <type> --role <role> [--try <id>] --why "<one line>"
     [--rows <ROW-id,…> | --rows-file <path>] [--steps <id,…>]
     [--expect <seconds>] [-- <selection> [--deployed-selection <selection>]]
```

| Type | Who may ask (`--role`) | Rows | Selection |
|---|---|---|---|
| `prove-red` | test-author, orchestrator, fixer (`--purpose proof`: orchestrator only, v0.9.8) | `--rows` / `--rows-file` | required |
| `iterate` | builder, fixer, test-author, testenv | `--rows` / `--rows-file` | required, plus `--deployed-selection` when the harness declares `deployed-selector:` |
| `deployed` | builder, fixer; orchestrator with `--purpose proof` (v0.9.8) | `--rows` / `--rows-file` | required |
| `close` | orchestrator | `--steps` and `--batch --phase1 <file> --phase2 <file>`: groups of close-rows' required rows (v0.9.7.0.12) | in the groups: each carries its own words |
| `checkpoint` | orchestrator | its population, `sh checks/metrics.sh checkpoint --population` (v0.9.7.0.12) | required, plus `--deployed-selection` when the harness declares `deployed-selector:` |
| `full` | orchestrator (the last close) | every row | none |

Graders request nothing. A builder's and a fixer's request carries its
brief's attempt id, `--try <the brief's try:>` (v0.9.7.1); without it the
request is refused. Your brief's section 6 is the command, filled in: your
rows, your try and the run manager's selection — run it as it stands, a
narrower selection of your own, or the whole one again. The selection is yours, in the runner's own
syntax, in words without spaces or quotes; ViD never builds one. A word
holding a space or a quote is refused at once, naming it: the harness
command can't carry it, so select by test ids. An `iterate` with
`--deployed-selection` (a builder, fixer or test-author asking) is one
ticket and one watcher: the inline pass, then the deployed pass with its own
selection, two receipts; its estimate counts the start-up twice and the
teardown between the passes once. The
`deployed` type stays for a deployed pass alone; with no inline pass
before it, it builds the tests' image from its own checkout first
(v0.9.7.0.10). When the harness declares `deployed-selector:`, a deployed
receipt credits only journey and `(process)` rows, so a `deployed`
request naming any other row is refused at once, naming it: request it
inline (v0.9.7.0.11). The answer, at most 6
lines, gives the ticket, the estimate and the limits, the rows with no
history, the queue position and the next command, `sh checks/test.sh wait <ticket>`. The run
starts detached: it outlives the call and the agent that asked.

**Before it runs** (inside a develop run): an empty row list is refused;
a row the plan places in a step not yet started is refused, naming the
step — except for `full`, and for the test-environment pass's own
measurement. A row the plan does not hold (a new row's first proof) is
accepted. Outside a develop run, `close` and `checkpoint` are refused;
`prove-red`, `iterate`, `full` and `deployed` are accepted, and the plain
forms of `sh checks/test.sh` keep working there, recorded `form=legacy`.
Inside a develop run a direct call is refused, naming this form.
A `close`, `full` or `checkpoint` runs HEAD's committed tree: asked while
the worktree has changes outside `.vid/`, it is refused at once, naming
up to five paths — commit first. One whose worktree turns dirty while it
queues waits, before it takes a test environment, saying `waiting for a
clean worktree`, for up to 10 minutes, then is refused; what runs is
HEAD's tree when it starts (v0.9.7.0.11).

**The estimate.** The estimate is each row's case seconds in
the newest results at the run's home that name it, plus the start-up
time measured on recent runs; a row with no history counts 10 seconds,
and the answer names it. A row whose test file has gained lines naming
it since its history ran adds 10 seconds a line, listed `ROW-x (+k lines
since its history)`. When you know the rows are slow
— a test fixed from a fast red into a slow green, a row with no history
— give `--expect <seconds>`, the case seconds you expect for one pass,
start-up excluded (a deployed selection that repeats an inline word
counts them again, v0.9.8.1). It replaces the history and is recorded
with your reason. The estimate plans and shows; it stops nothing
(v0.26.10.4).

**What stops a run (v0.26.10.4).** The run's watcher stops it when it
goes silent: no new output for 20 minutes. During a pass's start-up the
test environment's own output counts too; once its tests start, only the
tests' output does. It also stops a pass whose start-up passes 60
minutes, and any run at 24 hours awake. A project sets the three in
`.vid/budget`: `silence-minutes=`, `startup-minutes=`,
`run-limit-minutes=`. Time is counted in the watcher's ticks, so a host
sleep never counts. A stopped run has no later pass and no receipt; its
result says `capped=yes`, and its first line says why: `stopped: no new
output for 20 min (last at HH:MM UTC)`, `stopped: the deployed pass's
start-up passed 60 min`, or `stopped at the run limit (24 h awake)`.
`--expect` does not keep a run alive. Never set `VID_WAIT_MAX` — a wait
in your worktree ignores it.

**Reach.** After each pass, before anything is published, the manager
reads which rows the run's cases reach (the evidence join). A report
carries the rows its request was frozen with (`<report>.rows`) and
credits only those (`sh checks/evidence.sh credit`), wherever it is read:
the evidence, the claim, a hand-back. A run that reached a row outside
the request — for a close, outside close-rows' required rows; for
`full`, never — is kept all the same; its result says `outside n=<n>
rows=<…> — not credited`, its later passes run, and its exit comes from
its cases.

**Wait.** `sh checks/test.sh wait <ticket>` returns within 200 seconds (v0.9.7.1):
- `queued`, with the elapsed time and the estimate, or `running`, with
  the watcher's awake time, the estimate and the silence so far against
  its limit (exit 75), or `stopping (<reason>)` while a stopped run
  comes down; while
  `queued`, followed by the holders of the host's test environments as
  the run last saw them — live, or STALE with their age;
- `overdue` (exit 76) when a run is still running while its watcher's
  process is gone — nothing stops it on silence: say so in the record;
- or the result, and the run's own exit status: the status line
  (`status=<n> ran-to-end=<yes|no> capped=<yes|no> report=<receipt|none>`),
  the counts by case status, a red run's failures sorted by first message,
  and the rows outside the request or the reason no receipt was kept.
  Inside a develop run the result comes as soon as the last pass is
  published, before its test environment is torn down: `teardown
  pending` follows it while the environment is still held, and the
  result stands. A teardown that fails between two passes stops the
  later pass, and the result names it;
- or `cancelled` (exit 77), when the run manager cancelled the ticket: the
  result's first line is `cancelled by <who>` (v0.9.7.1).

Call `wait` again until it ends; never sleep or poll yourself. It never
prints the run's log; the log stays in the ticket's folder,
`.vid/requests/<ticket>/` at the run's home. A result ends with one
`analyst due: <reason> request=<ticket> …` line for each test-analyst
trigger that fired (below).


## The design transcription law

When design/ exists: **transcribe, never reinterpret** (CLAUDE.md
transcription law). Every CSS rule derives property-for-property from a
cited canvas section, hex→token the only substitution; no visual value that
exists in neither the canvases nor design/tokens.css. Citations are
sub-screen, marker unit: rule blocks under
`/* Section (P02/populated — REQ-030) */` comments, templates/components
carrying `Design: design/screens/<file> (P02/populated …)`.
checks/design-cite.sh rejects uncited rule blocks at commit;
checks/coverage.sh joins every marker to a citation. The markup for a
state wears every element identifier its canvas section carries
(`data-element="<role>"`, inside the marker's section) — **the surface
instrument is the fidelity evidence** (v0.9.2 3.4, R7, R20): a ledger
test file per screen (v0.9.8.1 R18), the surface test-author pass's product, mapping
each identified element and comparing every property the canvas
declares on it, then the row's pins hook; **a builder never writes a
surface test or a pins hook** — a screen's case is red until the
markup carries the marker, the identifiers and the declared values, and
that red is the slice's work, never a deferral. Small judgment deltas
(an added `gap`, `height`→`min-height`) are yours to make and grade's to
judge. A screen the product needs but the design lacks is a product
question, not a license to invent one.

## Building a step — steps 0–6

0. Narrate position in one line before starting it ("REQ-004/005 next:
   ingestion") — visibility for debugging, not a checkpoint. Never wait for a
   reply to a narration line. **A process claim carries its evidence class
   (§8.2):** "still running" resolves to an observation — a last test id, a
   last commit sha, an active-query age, a container state — or declares
   itself unverified. Elapsed time is not evidence of progress; a narrative
   built from it is the measured 48-minute-hang class.
1. **Law first, then code.** Anything the slice needs that changes law — a
   seam row, an inventory row for a new route, a rule/exception/difference
   row — lands BEFORE the code, each in its own standalone commit
   (hook-enforced, §4.1). The rhythm for a new route: (1) the test file,
   written by a test-author pass
   (`skills/vid-test-inventory/passes/test-author.md` — spawned with the
   row, the harness contract, the route table and the boundary rule, and
   nothing of this session), committed UNCHANGED as a free ledger
   addition and observed red by a `prove-red` request — record what you observed,
   `sh checks/event.sh 'red-observed row=<id> report=<receipt> case=<case id> assertion="<the failing assertion, quoted>"'`
   (v0.9.6 3.11): the case must be `failed` on the row's real check, never
   `error` (that is its setup or collection) and never absent, and under a
   0.9.6 plan the commit hook refuses a new `proved-red:` stamp without
   it; whether the quoted assertion is the row's promise is your judgment,
   recorded there for a grader to read; (2) the row citing it (law
   commit, stamped `proved-red: <parent-sha>` — the parent is where it was
   observed red); (3) the code that turns it green (v0.9.2 3.1, R1).
   The test-author pass, the `prove-red` request and the law commit are
   the run manager's; a builder that needs them hands back `law-needed`
   (B3).
   Additions are permitted, never silent; mixing law with work is
   mechanically impossible.
   **A slice that builds a Tier-0 protection also pays its hostility probe
   (§4).** The protection now exists, so the probe can finally be
   materialised and put through the fail-first ritual — attempt the
   forbidden thing through the real public surface, disable the guard by
   the row's own `disable:` toggle, watch the probe fail on its assertion
   about the forbidden effect, restore, watch it pass, stamp
   `proved-red: <sha>` in the row's own law commit. Reading the guard and
   finding it correct is not the ritual: the measured defeats were all of
   guards that were correct and were bypassed by a path nobody read. The
   probe's file is the author pass's to WRITE; the ritual is the run manager's to RUN.
   Each of its runs is a `prove-red` request.
2. Implement inside the seams (ARCHITECTURE.md) and the placement map. Every
   REQ implementation carries a code comment citing its REQ ID; screens cite
   their markers. The import court enforces the seam table at commit: enter
   a module only through its declared public surface, only as a declared
   dependent — a violation means the code or the seam table is wrong; fixing
   the table is a seam change, its own law commit, Seams: line.
3. **Green** the row's ledger test — the builder never creates, edits or
   deletes a file under tests/invariants/ (v0.9.2 3.1, R1): materialised
   tests are made green, never edited into passing, and a test that seems
   wrong is a product question. A surface row's case is red until the
   markup carries the marker, the identifiers and the declared values;
   a journey row's steps are green one transition at a time, operated
   through the real control (3.5).
4. Request an `iterate` run for the rows under work (their built
   neighbours and, after a harness change, the alarm set) and see it
   green — then commit
   with the template message — including the
   `Model:` trailer and, on any commit that adds a file under
   tests/invariants/, the `Tests-by: test-author <date> <batch>` trailer
   the pass's return carries (checks/hooks/commit-msg refuses the addition
   without it; `init` and `builder` are never values — v0.9.2 3.1c). **While any agent runs concurrently, stage by explicit
   pathspec only** (`git add <paths>` — never `git add -A`, `-u`, or `.`):
   a v0.7 ref-lock race swept a concurrent PRD append into a builder's
   commit, an unevidenced-completeness claim on the commit itself (§8) (§9: the model id doing the work; a later model must see
   what it inherits). Ledger-touching commits set `VID_ROLE=fix` —
   legitimate here ONLY because the staged ledger changes are additions
   derived from PRD Fail-ifs, inventory rows, or owner answers (CLAUDE.md
   ledger law). Deleting or weakening an existing ledger assertion is a law
   change and needs an owner answer behind it; if a test seems wrong, ask.

   Every run is a request to the test manager (`vid-test-manager`).
   **Engines:** a breach observed in one engine only is logged
   `sh checks/event.sh 'engine-only breach row=ID engine=<name>'` and reverts the rule for the
   project — the row is BREACHED, not "flaky" (R18).
5. **The census runs in the commit gate** (checks/census.sh, seconds): it
   and the inventory court judge what the commit stages, never the rest of
   the working tree (v0.9.6 3.12) — uncommitted product work elsewhere
   cannot fail an unrelated commit. One exception (v0.9.8.1 R3): law files
   (`checks/`, `design/`, the files `checks/lawfiles` names) edited but not
   staged refuse every commit, because the courts run from the working
   tree. The refusal names them; commit them first as their own law
   commit, or set them aside with a WIP commit (on a side branch, never a
   stash) and bring them back after. Its
   orphan list is your to-do — a dead path, an unguarded site, an
   unratified divergence, an unreachable surface blocks the commit. An
   orphan whose partner row is still `owed` reports `pending` and does not
   block (debt-aware, §3.4). Never silence an orphan with an exception or
   suppression row you invented for the purpose — those are ratified law
   (standalone commits) and the graders read them. The seam court runs
   beside it (checks/seams.sh): client code touching a seam still owed,
   or an outbound destination no seam row covers, blocks the commit —
   probe first (§3.3), row before code, two legal exits (probed, or
   unreachable-risk with its reason). The inventory court judges the
   hostility rows in the same gate (checks/inventory.sh): a probe cited
   without `proved-red`, a missing or `none` `disable:` toggle, or a probe
   that is the sibling of nothing blocks the commit; a Tier-0 rule with no
   hostility sibling is reported as debt and blocks completion, not this
   commit.
6. Log decisions as you make them (trigger in CLAUDE.md); every commit
   message carries its Decisions: line. A choice about what a stored value
   MEANS — "stored lowercase", "minor units", "never moves backward" —
   lands as a constraint or a test, never prose only (the data-semantics
   landing law, §6.3): these under-fire the decision trigger because they
   do not feel like choices, which is why the law names them. **Never touch checks/ in a slice
   commit** (law-change rule, CLAUDE.md): a court or extractor change is an
   owner-sanctioned act tracing to owner law, standalone, self-test re-run —
   or it is a grade finding.
   A decision that bears on one module, or a few, names their module ids
   in its `applies-to:` label, beside its row, requirement or screen
   items, never instead of them (v0.26.10.2 R17).

## The hand-back (v0.9.7.1 3.4)

**Write your return file** at the path your brief's header gives
(`return:`), with a shell command: a here-document into `<that
path>.tmp`, then `mv` it into place. The path is outside your worktree,
where your Write and Edit tools may not reach (rehearsal R-1). Every
row of your brief once: `brief:`, `branch:`, `commit:`, then `ROW-… |
pass | <the receipt that shows it passing>` or `ROW-… | not | <receipt
or none> | <reason and evidence>`. One receipt per line: a pass names
the one receipt where every case and shape the row needs passed; a row
that needs two passes and passed in only one is `not`. When one request
publishes an inline and a deployed receipt, name the one that credits
the row, as `brief.sh return` and the close read it: the deployed one
for a row only a deployed run credits (a journey or a `(process)` row),
else the inline one — check yours against both (v0.9.8.1 R33). The
field holds one receipt file name; notes go in the report. Law you needed
and did not land is a `not` line whose reason begins `law-needed:`.
Write no `agent:` line: the run manager adds your agent id. Detail
beyond a line goes to `<role>-<n>.report.md` beside the return, written
the same way; a reason may point at it ("see the report") only when it
exists.

**Unfinished work:** before you hand it back, save it: `sh checks/brief.sh
save <your brief>`, from your worktree. It publishes a continuation
package — never a commit, a stash or an index — or refuses, naming the
paths, and leaves your work as it was.

**Your final message** is at most 2,500 characters: its first line is
`return: <the path>`, then only what the run manager must act on.

An `analyst due` line in a request's result is not yours to act on: you
can't start an agent, and the run manager gets the line at the hand-back.

## Your branch (v0.26.10.4)

- **Main's changes:** take them with `git merge main` in your worktree.
  The commit hook judges a merge by what the merge itself adds — a
  conflict resolution, an edit — so main's protected paths and its law
  commits pass. Never
  rebase: a rebase's replayed commits skip the commit hook.
- **A commit message in a file:** write it to
  `"$(git rev-parse --git-dir)/vid-commit-msg"` — your worktree's own git
  directory — and commit with `git commit -F` that path. Never a shared
  scratchpad or a `/tmp` name: agents working at once would cross their
  messages.
- **A new D-number:** take it with `sh checks/decisions.sh next --try
  <your try>`. It is reserved at the run's home, above every number in
  your branch, the home's and every reservation, so agents working at once
  never pick the same one. A number you then don't use is a gap, which is
  fine.

## The harness upgrade (v0.9.7.0.10 3.6, R13)

A brief carrying `## 13 harness upgrade` is this pass, once per project:
bring the harness to the rules its section quotes (`vid-init`, the
harness; v0.9.7.0.11: four, `rules: 2`), in your own worktree, on the
step and rows the brief names. A harness already at `rules: 1` keeps its
readiness declarations and gains rule 4 only.
- **Write** the image files that build each service's dependencies in
  once (a tests service or a fake may carry its own `build:`; the product
  is still built once); the product's readiness route, if it has none; the
  harness change — `rules: 2` under `x-vid-harness`; rule 4's
  `case-limit:` and the tests service's `VID_CASE_LIMIT` with the runner's
  own per-case time limit taking it — set the limit from the slowest
  cases section 13 lists (above the slowest, with room) and say in your
  return how you chose it; a healthcheck on the
  product and on each service it needs in order to start, the product
  waiting for those and the tests for the product with `condition:
  service_healthy`; each service the product calls only while serving a
  request, or that only some tests use, under the tests' `depends_on`
  with `condition: service_started` (revision 5: started, waited for by
  nobody at start — in no `depends_on` it would not start); and a
  `difference` row for any test-sized data set (rule 3, a slow-starting
  dependency too: the setting, the test value, the production value, why
  the tests' purpose survives it). Which services are which is yours to
  decide from the code, and to name in your return.
  `sh checks/harness.sh` passes the change before you return.
- **Never edit tests:** the shared setup step for each started-only
  service, and the routing through it of the tests that exercise it, are a
  test-author's pass the run manager starts on your return. Name each such
  service and the tests that exercise it.
- **Commit nothing that is law.** Leave the harness change and the
  `difference` rows uncommitted in your worktree; the images and the
  readiness route are ordinary commits. The law commit is the run
  manager's, on the owner's yes.
- **Measure:** one `iterate` request for the brief's rows, in your
  worktree on the changed harness (it runs at one test environment, since
  the proof names the old harness). Return its ticket and its `overhead=`
  beside the before figures of the brief's section 13:
  `overhead: before=<the newest gated pass's> after=<yours> request=<ticket>`.

## Claude host (v0.9.7.1 3.5; a builder on another host skips this section)

- **Waits:** a test request with `sh checks/test.sh wait <ticket>`, called
  again until it ends (each call returns within 200 s); a command you
  started in the background with one `sleep` of at most 200 s, then Read
  of its output file. Never a loop: a hook refuses `while` and `until`
  loops that sleep or repeat a status probe, and sleeps over 200 s.
  It reads shell syntax only (v0.26.10.4): quoted text and a
  here-document's lines are prose, so a `--why` saying "while" passes.
- **Commits:** run the whole `git commit` with the host's background
  facility; its hooks run inside it and still block. While it runs, wait
  as above, and touch neither the index nor the files you staged. Never a
  hook that returns early, never a court that times out into success.
- **Commands:** plain, separate commands from your worktree; no `cd … &&`;
  no variables in git or `test.sh` commands; edits with Edit, not
  here-documents. The host's worktree guard refuses the rest.
