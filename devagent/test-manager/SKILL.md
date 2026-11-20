# DevAgent's test manager (TM)

The test manager of DevAgent (v0.26.10.24.1 R4), ViD's own dev side for GitHub auto: it works ViD's tickets on your
product, through GitHub, and sends back real results. You start it; ViD never starts it. As in develop
(skills/vid-test-manager/SKILL.md § "Internal — invoked by vid-develop and vid-fix"), the test manager is rules and a script, not an agent, with one agent pass,
the setup. Whoever runs the dev side, the dev manager (`../agents/dev-manager.md`), follows these rules and runs `run.sh`, beside this file. Each section names the heading or
bullet it is lifted from, in that file (TM below), by its first words (0.26.10.28.4, M8); learnings of develop's runner come over as rules, not as its code.

## The one rule (TM § "The one rule")

Nobody runs the test runner for a report but the test manager, through `run.sh`. Only its runs are reported; anyone
else's runs count for nothing. It never edits a test or product code, and stops only processes it started, by their pids.

## The order of a ticket's test work

1. **The setup** (`setup.md`), a fresh agent, before anything else. Firm: the record exists before the first reported run.
2. **The test author** (`../agents/test-author.md`), which commits its tests alone.
3. **The run** at the pull request's head, below; for the skeleton, the draft pull request's head with no product yet.
4. **Measure, pick and prove** (the setup's step 3), once there are tests to measure with.
5. **The product's entry** (the setup's step 8), then the builder and the check, as below, then step 3 again at the product's first
   start, and the head run.

On a step ticket (v0.26.10.24.2 R3, R4, R6), each after the one before:

1. **Tests first:** the test author's one commit on the ticket's branch, tests and helpers only.
2. **The red run** at that commit, below.
3. **The builder** (`../agents/builder.md`), on top of it. Its hand-back goes to whoever runs the dev side.
4. **The check,** before any head run: `sh untouched.sh <a clone> <the head>`. Exit 1 names each test or helper changed: no head
   run; a fresh builder on the same branch, its job note naming what to put right. It is for honest slips, nothing more. A helper
   two tickets' test authors both changed, merged clean, is named too: a test author's commit of it settles that.
5. **The head run,** below. A ticket or regression row that fails sends the builder back once, the same way, and the next head
   gets a new report. What still fails is reported as it stands, for the fixer.

A close run (v0.26.10.25.3 R8), an issue labelled `<prefix>run`: `vid: started` when its first chunk starts; each chunk by `run.sh`, phase 1's first, then phase 2's; `vid: reported <chunk>-<k>` for each
report; a chunk again only on ViD's `vid: again <chunk>` (`../agents/dev-manager.md`).

A fix round (v0.26.10.24.3 R3), after that order. A "not yet" naming a row that failed at T3
sends a fresh fixer (`../agents/fixer.md`) to the head. Once ViD has said it, a failing row is the fixer's, not the builder's.

1. **The job note,** from the "not yet": each row with its reason as ViD gave it, the report it comes from, and any earlier reason
   on that row with the commit that answered it. No file and no cause. This history goes to the fixer alone, never into a report.
2. **The fixer,** on top of the head, in the same pull request. Its hand-back goes to whoever runs the dev side.
3. **The check,** before any head run, as for a builder. Exit 1 sends a fresh fixer back with the file's name.
4. **The head run** at the new head, its report under that head's id; earlier heads' reports stay as they are. One head run per
   "not yet": a row still failing there is reported as it stands, for ViD to decide. A hand-back with no commit has no new head, so
   no run: its question goes to whoever runs the dev side. A run nobody will read: `run.sh stop`.

After the head run of a step ticket or the skeleton (v0.26.10.24.4 R3, R7), each after the one before, at the ticket's first head: the head its first `vid: decide` names, whatever that head's report shows. At a later head, from a fix round or a correction: T3 whole and the reached rows' breaks (`../agents/dev-manager.md`). No grade and no sort: a ticket is read once (v0.26.10.25.2). A ticket whose asks hold no T5, a follow-up (its header's `follows:` line) or a reached ticket, takes steps 1 to 3 and the ask alone: no grade and no sort, as its step was graded at its first ticket (0.26.10.28.10). A merge from main, or a `test it` commit that only adds cases, reaches no row: its ask needs the head report alone. A change to an existing case makes that row `retested:` in the next head report, and it takes its break.

1. **The needed faults:** the ticket's faulted rows, the rows of `no-red-<ticket>.txt`, the retested rows and, at a later head, every reached row, whatever its red, less the deploy-owed ones. A row
   that failed at this T3 waits for a head where it passes. Pick each a control: another row that passed at this T3. A control in the test
   author's `cases:` line may be the row's own case: then it runs as part of that row's test. The skeleton's fault has no control.
2. **A fresh grader for the breaks** (`../agents/grader.md`), in `sh run.sh blind --setup <record> --commit <the head>`, a fresh copy for each
   job, which prints its folder. Its job note: that folder, the head's full id, the plain ticket (its body and parts, no other comment; each decision's `why:` dropped, as step 4 says) and export, the rows to break, with the fail-if
   of any the ticket does not hold, and where its patches go, `faults/<ticket>/<row>.patch` in the work folder. Nothing of any earlier decision, reason, report or head, but for a weak-test line's break, step 5. At a later head a row's patch goes again, when it applies to the new head. A fresh grader writes one only for a row with none, or one that no longer applies, on step 5's job note for a list row and this one for any other: the break job alone, no verdict and no line to add to.
3. **The fault run:** a list, one fault a line, `<row> TAB <patch> TAB <control row, or none> TAB <runner words>`. The words take in the row's test,
   its control's, and any earlier case the test needs, such as a journey's earlier transitions. `sh run.sh start --setup <record>
   --ask pr-<n>-<head12> --commit <the head> --faults <list>`, then `wait`. Its report is the next attempt at this head, with T3's files
   unchanged and any fault folders that stand. You judge nothing: a test that stays green is reported green.
4. **Two fresh graders for the grade,** at the first head alone, started at the same moment, each in its own fresh blind copy, and waited for together. Their job note, the same but for the blind copy and the grade file's path: that folder, the head's full id, the plain ticket and export, this head's
   report folder alone, less `retested:`, the record's `stand-in:` lines, the rows it grades, and this pull request's Decisions section, rewritten for this head before the job note is written, each line up to ` | why:` (`../agents/dev-manager.md`; 0.26.10.29.5, DP-1 R1, R3). It carries no earlier decision, reason, report or head. Every grader's plain ticket, at every head and of every kind, drops the `why:` of each decision, each decision line kept up to ` | why:` (0.26.10.29.5, DP-1 R3); a fix ticket's also drops its `failed:` lines and its history (v0.26.10.25.4 R5). A reader that dies or is refused is replaced once by a fresh one. Each reader's own file stays in the work folder, `grades/<ticket>/`.
5. **The head grade:** the graders push nothing, so `sh run.sh grade --setup <record> --ask grade-pr-<n>-<head12> --file <first grade.txt> --second <second grade.txt>`, which joins them, one line a row, the ticket's one grade report. **A weak-test line,** `breached test` on a row that is not deploy-owed, skips the sort: all such lines take one fresh grader's job for their breaks, then one fault run, before the ask. Its job note gives each row and, as what must come true, the line's first reason alone, up to any ` — also: `, word for word, with no verdict word. Its patch goes at `faults/<ticket>/<row>.patch`, replacing any patch there, as the fault run replaces the row's folder. Caught, the line is closed. Missed, the row reads `failing, a weak test`. Inconclusive: a comment on the ticket, begun `TM:`, no label, and any fault folder of that row at this head stands.
6. **The sort,** at the first head, once the head grade holds a line left to sort, before the ask, once a ticket (0.26.11.1.4, R7): a line of the one grade that reads `breached` or `unclear`, less the rows of `known-limits.txt` and the weak-test lines step 5 took. `to-sort.txt`: `by: DM`, `commit:` the head, then each such line, word for word. A fresh second reviewer (`../agents/second-reviewer.md`) in a fresh blind copy, its job note the grader's, with `to-sort.txt` for the rows. Its `sorted.txt` goes by `sh run.sh sort --setup <record> --ask sort-pr-<n>-<head12> --lines <to-sort.txt> --file <its sorted.txt>`, the ticket's one sort report. Its `test it` lines wait for the decision's one test author's pass (`../agents/dev-manager.md`: a "not yet"'s, or the merge's), never before it: a test author's commit before the first decision would be a new head whose report lacks this head's fault proofs. `note it` and `drop it` take nothing of yours, and no grade follows.
7. **The ask.** A failed run comes back as its row's line, and goes by it.

**A door or a number a test author or builder wants (v0.26.10.24.4):** what they invent is a question, never a decision.

| Kind | What it is | Who authorises it | What happens to it |
|---|---|---|---|
| Measuring tool | Reads what no page can show, such as a scan of the store | A decision in the spec, cited by the test argument | Stays, in the tests |
| Set-up door | Puts in place, or reads back, under the test switch alone, what no public path can yet | You, on the test author's request; a `stand-in:` line in the record, which alone names the row or step that replaces it | Never on in production; removed when that step lands |
| Proposed production interface | Anything reachable in production that no row or decision holds; a door of doubtful kind | The product's owner, by a question on the ticket, labelled blocked when a row waits on it | Not built until answered |

## Starting an agent

`sh ../dev-manager/dm.sh start <role> <job note> <clone>` (v0.26.10.24.7 R3): a fresh agent on the job note's model, its first message checked. Its prompt names its role
file and its job note and nothing else, and it works in its own clone under the dev side's work folder. A job note is
short: its clone, its job, the commits it works at, and for the test author, the builder, the fixer and the analyst the dev setup record, read only.

## A reported run

```
sh run.sh start --setup <work folder>/dev-setup.txt --ask pr-<n>-<head12> --commit <the head's full id> \
  [--select "<runner words>"] [--engines "<engine> …"] [--no-product] [--line "stand-in: … — … — …"]…
sh run.sh wait <run folder>     # again and again, until it stops printing `running`
```

`run.sh` makes a clean checkout of the named commit from origin, so a commit not on origin is not run, and the run tests a
frozen copy (TM § "Every test run tests a frozen copy"): an edit made meanwhile never reaches it. For each engine it starts the environment, runs the
selection, stops the environment and checks for leftovers. Then it pushes the report, alone on `vid-results/<id>`, with
the next attempt number: the head report, `pr-<pull request>-<head12>-<k>`, the red report, `red-<ticket>-<k>`, or a close chunk's, `req-<issue>-<chunk>-<k>`, which carries no `--line`. The run folder
holds `log`, the tests' output, and `start.log`, the output of `start:` and of the product it leaves running.

- **Engines (TM § "Engines:"):** every engine the ticket asks; for the skeleton, every engine the setup declares (the default); for a close chunk, its own.
- **The selection (TM § "Scoped runs, the floor, the engines, the fixtures"):** yours, in the runner's own syntax, built from the ticket's row ids. Where the record has `select-form:`, give the names alone: `run.sh` puts them in that form, in a fault line too. ViD names ids only.
  A head run selects the ticket's rows, its regression rows and any retested row, less the deploy-owed ones and the rows of
  `known-limits.txt` in the work folder: a row ViD's comment reads `known limit` leaves every later selection and needed fault, this ticket's and
  later tickets'. Rows' kinds and marks are read from the ticket.
- **Before the product exists:** `--no-product`, the skeleton's case only (the setup's step 7). A `setup:` error in every
  case that reaches for the product is what that run should show.
- **The report's own lines:** `--line`, once each. `stand-in:` for each line of the record no earlier head report of this project carries, on a
  head report's first attempt alone, with its test and production values; `retested: <row id> …`, ids alone, for a row whose test now checks something different; `rows:` in a red run.
  `covers:` is not yours: `run.sh` copies the `covers:` lines into `results.txt`, one per row, the lowest, from the log of the
  pass that wrote the report.
- **The red run (R4):** `--ask red-<ticket> --commit <the tests-first commit> --select "<…>" --line "rows: <row id> …"`, the
  ticket's rows less the deploy-owed ones, with the product as it stands on the base running, so no `--no-product`. `run.sh` holds
  it to the primary engine and its `rows:` line. Read the cases, and keep in the work folder, as `no-red-<ticket>.txt`, the rows
  with no red and why, for the faults: a case that failed on a missing door, a set-up or an earlier step is no red. Judge no more
  than that: reading a red is ViD's. A correction before the builder's
  first commit is a new tests-only commit and a new red report, and for each row the newest report that lists it counts. After
  that first commit it takes no red report: its next head report carries `retested:` for each row the test author names.
- **The builder's own runs** (`--here`, R2) are one run on an environment like any other; they are reported to nobody.
- **One run per environment.** With every environment busy, wait for one (TM § "Every test run tests a frozen copy"); never refuse, never run a second
  on top of it. In containers a run takes its environment only when memory leaves its measured size plus 2 GB, else it
  waits; the first is never held back (TM § "The test environments").

**Waiting (TM § "Requests and waits").** A run longer than one call is started with `start` and waited on with `wait`, in calls of at most
200 seconds; it outlives whoever asked. `sh run.sh stop <run folder>` stops your own run, by its pid.

## What comes back

`wait` prints the run's `result`, and exits with its code:

| Exit | The result | What you do |
|---|---|---|
| 0 | `pushed vid-results/<id>`, the leftovers, the case counts, `broken:` lines, any `analyst due:` line | Read it; a failing case is an ordinary result |
| 2 | `no results report`, with the last lines. It ran twice and pushed nothing. A report with no case or no closing tag is a runner killed mid-write: it counts as none | Stop; tell whoever runs the dev side, with those lines. Do not run it a third time |
| 3 | `stopped: …` and pushed nothing | Read the log; see below |
| 1 | The run did not happen, and why: no record, a commit not on origin, a folder of ViD's records | Put it right |

Every result has a `leftovers:` line. Anything but `leftovers: none` is a defect of the setup's `stop:`: `run.sh` stopped
what it started, and names it. Mend the setup before the next run.

## What stops a run (TM § "When it is due", § "A service that dies stops the run")

- **Its watcher:** silent for 20 minutes (a likely hang; what the product logs is not the tests' output and does not
  count), a start-up past 60 minutes (a stack that won't come up), or the run limit, 24 hours. The result says `analyst due: cap stop=<why> last-output=<UTC>`.
- **A dying service:** the record's `services:` command, every 15 seconds while the tests run. A service that ended with
  code 0, or an unhealthy one, is not a death. Read the timeline, then run again or start the analyst.
- **A case at the limit** does not stop the run: the runner stops the case, reports it failed by its name and goes on.

## The test analyst (TM § "When it is due", § "No trigger is silenced by an earlier one", § "The test analyst")

You start it, on `../agents/test-analyst.md`, when a result says `analyst due:`, for any of these, in no order; no trigger
silences another:

- **cap:** the run stopped by its watcher;
- **setup:** 5 or more red cases, each over 60 seconds; or 5 `setup:` errors over a pull request's head runs, whatever their time, said once a pull request (v0.26.10.25.3 R12);
- **slow:** a case over 240 seconds.

Its job note: its clone, the run folder, the trigger, the dev setup record, the published ticket. Name each `timeline-<engine>.log` to it. Keep
working meanwhile. It proposes; nothing it returns changes a test, a setting or a limit by itself. On its return:

- **setup:** a test-author pass with the named cases, one pass per cause;
- **hang:** repair the environment, or tell whoever runs the dev side;
- **limit with `prod: n/a`:** a setting only the test has: a test-author pass changes the test;
- **limit:** ask whoever runs the dev side the return's question. A yes that changes a test value is a test difference,
  named in the next report's `stand-in:` line;
- **none:** nothing.

## Broken tests, sorted (TM § "Broken tests, sorted")

The `broken:` lines group the red cases by first message, largest first. Hand a group that points at the tests to a
test-author pass in bulk: one test defect behind many cases is one group, repaired once. A `setup:` group before the product
exists is expected.

## Your environment (TM § "The test environments")

It is yours: the test author asks you for a change, and writes shared test setup itself. Run the setup again when the
environment or the machine changes, after a run killed for memory or lost to the host's process limit, and when the product first starts: before any
further run `environments: 1`, then the setup's step 3, and only that pass raises it. A head report with more cases than the record's `measured:` line is no
trigger (v0.26.10.28.2, R5): runs go on at the last proved `environments:`, run.sh's memory admission and the machine's `max-environments:` guarding them. A test difference you introduce is named in the
next report. Nothing here waits on ViD: what only a person can settle goes to whoever runs the dev side.

## Roles and boundaries (v0.26.10.24.1 R6, R7)

- Every commit carries `Role: <label>`, and every report's first line is `by: <label>`.
- A comment on GitHub in one of the format's forms (`vid: claimed`, `vid: decide <commit>`, `vid: started`, `vid: reported <chunk>-<k>`) keeps that
  first line and names its role on the second, `by: <label>`. A question's first line begins `Question:`. Any other comment begins with its label.
- DevAgent reads and writes nothing in a folder of ViD's records, and calls none of ViD's scripts.
- On GitHub it writes only: the ticket's branch, its draft pull request, `vid-results/*` branches, labelled comments, and
  the blocked label, with its question, on the issue or pull request it works on. It never pushes to main, closes
  or edits a ticket, and merges one thing alone (v0.26.10.24.7 R10): the merger's merge of a pull request ViD's comment reads `ticket: accepted` for this exact head, a merge
  commit ending `Role: MR`.
- A technical question is yours to decide and log. A product question is a comment on the issue, pull request or close run, its first line
  beginning `Question:` and naming the rows or step, labelled blocked only when the work cannot go on without the answer.
