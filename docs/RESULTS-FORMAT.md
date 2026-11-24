# ViD results format 1

The agreement between ViD and the team that works its tickets. ViD runs nothing: all it knows of a ticket's work is
what the team sends in this form. A ticket says what to run; this document says how the answer comes back.

Roles are the team's, named as the ticket names them: DM (manager), TA (test author), TM (test manager), AN (test
analyst), BU (builder), FX (fixer), GR (grader), SR (second reviewer), MR (merger), DP (deployer). Every report names the role that made it.

A project in **GitHub manual** has rules of its own for a ticket's results, its review and its closes: the section "GitHub manual"
below. Where it says otherwise than the rest of this document, it stands there.

## Words

| Word | Meaning |
|---|---|
| Row | One checkable promise, with an id (`ROW-12`, or another prefix) and a fail-if |
| Journey, transition | A journey row is made of transitions, each with its own id (`ROW-12-T1`, `ROW-12-T2`, …) and fail-if |
| Ticket | ViD's request to build some rows, published as an issue |
| Head | The newest commit of the ticket's pull request |
| Ask | One thing ViD asks for: T1 to T5 in a ticket; C1, C3, CS, CP, CR (a run), S1 or a grade ask, on an issue of its own; D1, RH, D2 (a deploy), on an okay's issue |
| Attempt | A report sent again for the same ask, numbered from 1 |
| Engine | One place a test case runs, a browser for instance. The first one declared is the primary |
| Fault | A deliberate break of a row: make this row's fail-if true, and nothing else |
| Protection row | A row the ticket marks `protection`: it names something that must never happen. A row not so marked is not one, however it is worded, and carries no `vid-forbidden-effect:` line |
| Control | A row, or another case of the faulted row, whose test must keep passing while a fault is planted |

## The transport

Each report is one folder, `<id>/`, pushed to the code repository as the branch `vid-results/<id>`. ViD reads that folder
alone: whatever else the branch holds is neither read nor downloaded. A branch without a folder of its own name is left out, and said:
put the report's files in a folder named `<id>` on it and push it again. `<id>` names the ask the report answers; `<k>` is the attempt, from 1.

| Report | Id | Made by |
|---|---|---|
| T2, the red run | `red-<ticket>-<k>` | TM |
| Head report: T3, and T4's faults | `pr-<pull request>-<head12>-<k>` | TM |
| Head grade: T5 | `grade-pr-<pull request>-<head12>-<k>` | GR |
| The sort: T5 | `sort-pr-<pull request>-<head12>-<k>` | SR |
| C1, the step close: one chunk | `req-<ask issue>-<chunk>-<k>` | TM |
| C3, the stage's full run: one chunk, its rest chunk `p1cx` too | `req-<ask issue>-<chunk>-<k>` | TM |
| CS, the staging run: one chunk | `req-<ask issue>-<chunk>-<k>` | TM |
| CP, CR: one chunk | `req-<ask issue>-<chunk>-<k>` | TM |
| S1, the stage grade, and a grade ask | `grade-<ask issue>-<k>`, then the comment `vid: reported s1-<k>` | GR |
| D1, RH, D2 | `deploy-<okay issue>-<k>`, then the comment `vid: reported d1-<k>` for D1 | DP |
| The dev side stopped | `stopped-<k>`, answering no ask | DM |
| GitHub manual alone: the team's own results | any id but those beginning `red-`, `req-`, `grade-`, `sort-`, `deploy-` or `stopped-`; `step-<ticket>-<commit12>-<k>` for one | anyone |

`<ticket>`, `<pull request>`, `<ask issue>` and `<okay issue>` are GitHub numbers; `<head12>` is the first 12
characters of the head's commit id, `<commit12>` the same of a commit of the code repository's main; `<chunk>` is a close chunk's name, `p<phase>c<n>`. Only the newest attempt of a report counts, except for T2: each T2 report lists
the rows it covers, and for each row the newest T2 report that lists it counts; and a close chunk's row that could not run in its
newest attempt and passed in an earlier one at the same commit reads passed. A new attempt may carry the earlier
attempt's unchanged files.

## Test reports (T2, the head report, C1, C3, CS, CR, CP)

The folder holds `results.txt` and one `cases-<engine>.xml` for each engine named. `results.txt`, one item a line:

```
by: TM
commit: <the full commit id the tests ran on>
engines: <engine> [<engine> …]
environments: <n>
covers: <rule row id> <number of places>
retested: <row id> [<row id> …]
stand-in: <what> — <test value> — <production value>
rows: <row id> [<row id> …]
```

- `by:` is the first line. `commit:` is the commit the tests ran on, in a clean checkout of it.
- `engines:`, the declaration, primary first, and `environments:`, how many test environments the team runs: every
  head report of the skeleton ticket has both. Later reports need them only for a change.
- `covers:`, one line per rule row run: the number of places its test covered. Zero means the row fails.
- `retested:`, in a head report, when any: a row whose test or helper changed after T2 so that it now checks something
  different. Such a row joins this head's T3 and needs its fault proven. A retested deploy-owed row takes no T3 and no
  fault: it is owed again until TM proves it again on the deployed product.
- `stand-in:`, in a head report, one line per test difference first used at this head.
- `rows:`, in a T2 report: the rows it covers.

`cases-<engine>.xml` is an XML test report, the layout most test runners write: one `testsuite` of `testcase`
elements, each with a `name`, and a `time` in seconds where the runner gives one. A `testsuites` wrapper is allowed. A failure's
`message` begins with the assertion's own line, what was promised and what was seen; the traceback goes in the element's text.
A runner's own class name before that line, one word ending `Error:`, `Exception:`, `Failed:` or `Failure:`, is allowed and read past.

### What a case result means

| In the file | The case |
|---|---|
| A `testcase` with no `failure`, `error` or `skipped` child | passed; `system-out`, `system-err` and `properties` may appear and mean nothing |
| `<failure>` | failed on its assertion |
| `<failure>` whose message begins `setup:` | errored: the runner's message must begin with that word |
| `<error>` | errored |
| `<skipped>` | was skipped |

A case that needs something the test environment does not have errors with a message beginning `setup:`, and so does one that
stops at a missing door, a set-up or an earlier step before its row's own promise. It is not a
failure of its row's promise, and it never counts as a red. A case that runs past the team's case limit is stopped and
reported failed by its name, and the run goes on.

### Matching a case to a row

A case's name matches a row id when it contains the id, with `-`, `_` and `.` counted as the same character, and with
neither a letter nor a digit directly before or after it.

- `ROW-12` matches `test_ROW_12_adds_item` and `ROW-12 adds an item`.
- `ROW-12` does not match `ROW-120`.
- `ROW-12-T1` matches `test_ROW_12_T1_opens_cart`.
- A journey's id also matches its transitions' cases. A journey listed by its id means all its transitions.

**A row's result, when several cases match it.** The row passes when every matching case passed. It fails when any
case failed, errored or was skipped, or when none matches. Where every case that did not pass, in every engine and transition, errored with a message beginning
`setup:`, the row has not failed: its test could not run, and it reads `evidence missing — its test could not run`, never a product failure, and waits for its fault as a failing row does.

**Every engine is read.** A head report's every `cases-<engine>.xml` is read, not only the engines the ticket asks. In an engine
the ticket did not ask, a case that failed, or errored but for `setup:`, fails its row; a `setup:` error, a skipped case or no case
there stops nothing, and the reader's evidence counts them in one line an engine, `engine <e>: <n> could not run`, `<n>` the rows
and transitions so read. A row that failed in one engine and passed in every case of another reads `split <row> <engines it passed in>
<engines it failed in>`, tab-separated. Once the handed record holds an `engine-split` line, every engine the skeleton declared is
asked of every ticket, those already open too: a head report then needs a cases file for each. The evidence also counts, for
each engine, the `setup:` errors of the pull request's head reports, each head's newest attempt, as `setup errors <e>: <n> cases over <k> runs`.

### The red rule (T2)

TA commits the tests alone, before any product code; that is the tests-first commit, and TM names it as the `commit:`
of its T2 report. A row's red is at least one case matching the row that failed on its assertion, with no matching case
errored. An error, a failure whose message begins `setup:`, a skipped case, a passing case and a row with no case are
none of them a red. A row with no red needs its fault proven at the head instead, deploy-owed rows apart.

### Faults (T4)

The head report adds `faults/<row id>/cases-<engine>.xml`, in the primary engine: the faulted run of that row's test
and of its control's, with `control.txt` naming the control. A fault TM could not plant has
`faults/<row id>/inconclusive.txt` instead, with one line saying why. A fault folder is read wherever it is: one for a row the
ticket does not list is read as a regression row, its fault beside it, so a break its test misses makes it fail; a folder whose
name is no row id is said as `fault folder for no row`.

A fault is proven when, under the fault, the faulted row's test fails on its assertion, the control's test passes, and
both passed at this head's T3. A control may name the faulted row or its journey: then the row's cases fail on their assertion, none errors, and at least one other case of the row passes under the fault, or the fault is inconclusive, `no case of its own passed under the fault`. The skeleton's fault has no control. A protection row's failure carries the line
`vid-forbidden-effect: <row id>`, on a line of its own, white space around it ignored; it marks evidence of the forbidden effect itself, never a mismatched error word. A faulted row's test that still passes cannot see its row, and the row fails. A fault
that cannot be planted, a test that errors or is skipped, a control that fails and a missing forbidden-effect line
leave the fault inconclusive, which is no verdict and no count: a row with a red, or a proven fault, is accepted without it, and a row with neither is held. A proven fault stands until a later fault on that row reads proven or not proven, or the row is retested: an inconclusive fault, a failing head and a head where the row needs no fault take nothing away. A journey's fault proves the transitions it failed, and says nothing of the others.

## GitHub manual: the team's own results

A ticket of a team of people is decided at a commit of the code repository's main, from the team's own results there and ViD's own
review of the ticket, once. Nothing here is asked in GitHub auto.

**A result report** is any branch `vid-results/<id>` whose id does not begin `red-`, `req-`, `grade-`, `sort-`, `deploy-` or `stopped-`. Its
folder holds `results.txt`, whose first line is `by: ` and whoever made it, with a `commit:` line naming a commit the code repository holds;
and at least one whole results file with a test case, any `.xml` at the folder's top, of any name. Nothing else keeps it from being read.
Every other line of `results.txt` is read when given: `covers:`, `retested:`, `stand-in:`, and on the skeleton ticket's results `engines:` and
`environments:`.

**It counts at a commit** when its `commit:` is that one, or one that holds the very same files; whose ticket or pull request it was made
for does not matter. An id that ends with the first 7 or more characters of its own commit and a number is an attempt, its newest
alone read; any other id is a report of its own. A test that passed at other files alone reads `passed at <commit12>, not at this
commit`. A test an amendment of the ticket adds or restates is read only from reports made after it, each report by itself.

**A row** (or a journey's transition) is read from all the reports at the commit as one: it passes when at least one file has a case of
it, every case of it in that file passed, and no file has a failed or errored case of it. A skipped case, or one that errored with
`setup:`, in another file stops nothing. A file that is not whole can fail a row and never pass one. No engine is asked by name, and a
regression row is read the same way. A rule row's `covers:` line of 0 fails it; with no line nothing is missing.

**Read when the team gives it, never asked:** a red run, `red-<ticket or a sub-issue of it>-<k>`; a deliberate break, the report's
`faults/<row id>/` folder, read as a fault is (a test that still passes under it fails its row as a weak test).

**The review, the stage's grade and any other grade** are ViD's own: no `grade-` or `sort-` report is asked of the team or read. A
`request <row> — …` line of a decision asks one added test, and holds that decision alone.

**A close's run, a stage's, a staging, a rehearsal and a production run:** `req-` reports, their ids and the commit asked as below, `by:`
anyone, with any results files; a row passed in a chunk's files passes for each engine of its chunk. A file named `cases-<engine>.xml` is read as
that engine's names for the run's `not run` reading. **Deploys:** `deploy-` reports as below, `by:` anyone.

## The step close (C1)

When every ticket of a step has merged, ViD asks for the close run on an issue of its own, labelled `run`, naming the commit (the
step's last merge), the engines (every one declared) and the chunks. Phase 1, `p1c1`, `p1c2`, …, runs the primary engine alone;
phase 2, `p2c1`, …, every other engine together, the same rows chunk by chunk. A journey is named by its own id, all its
transitions in one chunk. Each chunk's report is `req-<ask issue>-<chunk>-<k>`, `by: TM`, its `commit:` the asked one, one
`cases-<engine>.xml` for each engine of its chunk; a report without them is not read, and its chunk reads absent.

A chunk whose run TM lost, with no report, is said on the issue once, as the comment `vid: lost <chunk> <k>`, `by: DM` on its second line, `<k>` the
number of `vid: again <chunk>` comments on the issue then. ViD reads it at once, with no wait for the issue to go quiet: the first loss is asked again,
`vid: again <chunk>`, and a loss said after that again is asked no more: the chunk waits on a person's answer. A loss whose `<k>` is older than the issue's count of agains, or that is older
than the chunk's newest report, changes nothing.

ViD reads each chunk's newest report. In each engine of its chunk a row reads:

| Reading | When |
|---|---|
| passed | every matching case passed |
| failed | a case failed, errored but for `setup:`, or was skipped; or, in phase 1, no case matches the row, or one of a journey's transitions |
| could not run | every case that did not pass errored with `setup:`; it reads passed when an earlier attempt of the chunk, at the same commit, passed |
| not run | a case that the row's newest accepted head report named, in that engine, is not in the close; that head report is the newest whose head is an ancestor of the close's commit |

In phase 2 a row with no case at all stops nothing: it is counted in the tab-separated line `engine <e> <n> could not run`. A chunk reads green when
every row passed, red when one failed, incomplete when one could not run or was not run, and absent with no report, or with its
newest not read. A row failing in one engine and passing in another reads a `split` line.

## The stage's full run (C3)

At a stage's candidate ViD asks C3 as it asks a step close, on an issue labelled `run`, its body beginning `close: stage-<N>`:
every row of the stages so far that a merged ticket holds, every declared engine, phase 1 then phase 2, chunk by chunk, each
chunk reported as `req-<ask issue>-<chunk>-<k>` with `vid: reported <chunk>-<k>`. One more chunk, `p1cx`, asks every other
test case of the suite, in the primary engine, but the cases of the deploy-owed rows its line names (CS runs those): the
cases outside the rows, never the whole suite. When no case is left outside the rows, its report's cases file holds no test
case, its outer tag closed, and its results.txt the line `none left`; a report with no test case and no such line is not
read as green. Its report is read as any chunk's; its cases credit no row, and each whose name holds no id of the inventory is listed. A red C3 gives fix tickets as a red step close does; a green one closes the stage's steps.

## The staging deploy (D1)

Once a candidate's C3 has passed, ViD gives the okay on an issue labelled `deploy`, its body beginning `okay: staging`,
`commit:` the candidate's, `seed: synthetic` (or `seed: production`, once production exists and the product's sponsor asks for
production's data on staging: load a copy of production's newest backup into staging before the migration, in place of the
made-up data, and keep every outside service on staging limited), and `outside-service rows:` the outside-service rows the
staging run will ask, or `none`. Further down the body quotes the hosting, a paragraph `The hosting:` of `> <key>: <value>`
lines, and names the duties, a paragraph `Duties:` of `- <duty>: <what is asked>` lines: `log-in`, `environments`,
`outside-services`, `sending-domain`, `deploy-notes` and `captures`. ViD deploys nothing: DP deploys that commit to staging, within the downtime
tolerance the skeleton ticket's hosting states, comments `vid: started` when it starts, and asks a step only the product's sponsor can take as a question on that issue, labelled blocked. Staging holds one candidate at a time: an okay comes only
once every earlier deploy that passed has had its staging run read. A newer okay withdraws an earlier one that has not passed.
The folder `deploy-<okay issue>-<k>/` holds:

- `report.txt`: `by: DP`, `commit:` the okay's, `outcome: passed` or `outcome: failed <step>`, and for a failed step
  `product change: yes` or `product change: no`;
- `deploy.xml`, one case per deploy step;
- for a passed deploy, `staging.txt`: `staging: <address>`; one `signin: <role> <address>` line for each role DP can sign in
  as; and one `differs: <what> — <on staging> — <on production>` line for each way staging differs from production beyond
  the head reports' `stand-in:` lines, or the one line `differs: none`; `seed: synthetic` or `seed: production`, as the okay's;
  for each outside-service row the okay names, one `seam: <row> real` when its outside service is the real one on this staging,
  or `seam: <row> stand-in — <why>`; and `stays: up` when staging stays up between deploys;
- for a passed deploy, `duties.txt`: for each duty the okay names, one line `<duty>: done — <what and where>`,
  `<duty>: not needed — <why>` or `<duty>: not done — <why>`.

Then `vid: reported d1-<k>` on the issue. A report is not read when its role is not DP, its commit is not the okay's or is not
in the code repository, a passed deploy has no `staging.txt`, no `staging:` line, no `differs:` line, no `seed:` line or one other than
the okay's, or no `seam:` line for a row the okay names, has no `duties.txt`, or leaves a duty the okay names without a line or
`not done`, or a failed one has no `product change:` line; ViD's comment says why, naming the duty and your words, and DP sends
it again as attempt k+1. A second such report on the same okay waits on ViD; for a duty not done, the product's sponsor may rule
it a known limit of the project, and from then on that duty's `not done` is read. A `not needed` duty is read, its words passed
on. An outside-service row is paid only when the passed deploy marks it `real`; any other the staging run passes waits on ViD,
which may ask the deploy and the staging run again at the same commit once the real service is on. A failed step that needs no product change is DP's to fix: ViD's comment `vid: failed at <step>:
deploy again and report as attempt <k+1>` asks it again at the same commit, and a second failure at the same step waits
on ViD. A fix that needs a commit to the code repository is a product change: ViD closes the okay, and the change
comes back as a row in a ticket. With no report for a long while ViD comments `vid: again d1` once.

## The staging run (CS)

Once D1 has passed, ViD asks CS as it asks C3, on an issue labelled `run`, its body beginning `close: staging-<N>`, then
`commit:` the candidate's, `against:` staging's address, the `signin:` lines of the passed deploy, and `engines:`. Its rows:
the golden path (the skeleton step's rows, but production- and rehearsal-owed ones), and every seam and staging-owed row of
the stages so far, each of a ticket merged at or before the candidate. TM runs them against that address, signed in through
those lines, not in a clean checkout of its own, chunk by chunk, each chunk reported as `req-<ask issue>-<chunk>-<k>` with
`vid: reported <chunk>-<k>`, and read as a C3 chunk is. A rule row needs its `covers:` line: zero fails the row, and a chunk
with a rule row and no `covers:` line for it is asked again. A seam or staging-owed row that passes in every engine is paid;
one that fails, and any red row, gives a fix ticket as C3's do. Keep the staging up until the CS issue closes: ViD's walk of the staging, W1, comes after
this run, and the issue closes only when the walk is done, or withdrawn by a newer candidate.


## The rehearsal (RH) and its run (CR)

After a stage's close, ViD gives the rehearsal okay, an issue labelled `deploy`, its body beginning `okay: rehearsal` and
`commit:`. DP restores the newest production backup somewhere that is not production, sealed: no connection from it to anything
outside it, reachable only from where TM runs; migrates it, boots it, and reports `deploy-<okay issue>-<k>/`. Before the migration DP notes every row of each table the product
only ever adds to; after it, it checks each of those rows is still there, word for word:
- `report.txt`: `by: DP`, `commit:`, `outcome: passed`, `outcome: failed <step>` (with `product change: yes` or `no`), or
  `outcome: no backup yet` (a first deploy, before any production exists); for a passed one, `sealed: yes`, `copy: <address>`,
  one `signin: <role> <address>` line a role, and one `kept: <table> — <n> rows` line a table, or the one line
  `kept: none — <why>`; a lost or changed row is `outcome: failed kept`;
- `deploy.xml`, the steps restore, migrate, kept and boot, kept after migrate and before boot;
- `change.txt`, for every outcome: `migrates: yes` or `no`; one `drops: <data>` and one `rewrites: <data>` line for each piece of
  data the migration drops or rewrites; one `services: <outside service>` line for each that changes; or `drops: none` and
  `services: none`.

Then `vid: reported rh-<k>`. A report without these lines, or a passed one not `sealed: yes`, with no `kept:` line or no kept
step, is not read; a failed `kept` is a failed step like any other, and ViD's comment says
why. `no backup yet` is not read once production exists. CR, the rehearsal run, is asked as CS is, on an issue whose body begins
`close: rehearsal-<N>`, against the copy's address: the golden path's rows that are not deploy-owed, and the rehearsal-owed
rows. DP destroys the copy once its run is read.

## The production deploy (D2) and its run (CP)

Once the product's sponsor has said yes to the rehearsal, ViD gives the production okay, its body beginning `okay: production` and `commit:`.
DP backs production up first, deploys, and reports `deploy-<okay issue>-<k>/`:
- `report.txt`: `by: DP`, `commit:`, `outcome: passed` or `outcome: failed <step>`, `production: <address>`, and on the first
  production deploy ever, `logs: <where production's logs are read>`;
- `deploy.xml`, its first step `backup` (before any production exists, it passes with nothing to back up);
- for a passed deploy, `duties.txt`: for each duty the okay names (`service-switch-on`, `backups`, `point-in-time-recovery`,
  `storage-versioning`, `dns`, `https`, `monitoring`), one line in the staging deploy's form. Production is live once it reports,
  so a duty without a line or `not done` never sends the report back: each waits on ViD, until the product's sponsor rules it
  known or a later production report says it done. The production okay quotes the hosting and names these duties as the
  staging okay does.

Then `vid: reported d2-<k>`. Before any restore, DP asks on the issue first, naming the recovery point (the backup's time) and the writes at risk (every
write since). When a deploy fails, or its run
is red, ViD asks for a recovery: DP recovers as it judges and comments `vid: recovered <the commit production runs now, or none>
— <what it did>`; the okay is then closed, never deployed again. A recovery to the okay's own commit counts as its deploy: the okay
stays open, CP is asked again, and a later `vid: recovered` comment on it is read the same way. The production okay closes once
CP is green. A production okay with no report a day after it was given (25
hours after its start comment) is asked what production runs now, and never asked again. CP, the production run, is asked as CS is, on
an issue whose body begins `close: production-<N>`, against production's address, TM signing in through its own production test
accounts: the golden path's rows that are not deploy-owed, and the production-owed rows.

## Grades (T5, S1, a grade ask)

The folder holds `grade.txt`:

```
by: GR
commit: <the commit graded>
ROW-12 kept — <reason>
ROW-13 breached product — <reason>
ROW-14 unclear — <the question>
REQ-3 facade — <reason>
finding: bug high — <what> — <where it shows> — <how to reproduce>
finding: rule — <one line>
```

A ticket has one grade, at its first head, the head its first `vid: decide` names: one line per row or transition, every row, from two fresh readers joined. A row both keep reads the first's line; a row one breaches reads that line, word for word; a row both breach in other words reads the stronger line, then ` — also: ` and the other's line less its row id. No later head has a grade, and one pushed is not read. A line is `kept`; `breached product` (the product is wrong) or `breached test` (the test
cannot see the promise); or `unclear`, the row cannot be judged as written, with the question it raises. S1 and a grade
ask have one line per requirement. S1's issue, labelled `grade`, names the stage, the commit and the requirements asked;
`grade.txt` holds one line for each, `REQ-<n> pass|partial|facade|absent — <reason>` (facade: it looks built, and isn't),
and no other requirement. Then `vid: reported s1-<k>` on the issue; a `vid: again s1`, or ViD's comment saying why the report is not read, asks a
new attempt. The findings follow: anything seen outside the rows, tagged `bug` (one case) or
`rule` (holds everywhere). After the tag a finding may give `high`, `medium` or `low`, then what, where it shows and how to reproduce it, each after
a dash; a plain line still reads, and sorts last. A breach that disputes how far a row reaches begins its reason `scope:`, and is read as `unclear`.

**A grade ask** is an issue labelled `grade` whose body begins `grade: ask-<n>`, n its own number, then `commit:`, the commit
to grade, and `requirements:`, the ones asked (`none` for a robustify ask). Its report's `commit:` is the ask's commit; any other is not
read. It may also name, each on a line of its own after those three:
- `vs: <commit>`: each requirement graded at both, its line running on, `REQ-<n> <word> — <reason> — vs: <word> — <reason>`, the second at
  the `vs:` commit. A line with no second word, or a second word outside the four, is not read;
- `robustify: <area>; <area>; …`: three to five areas, graded as built, with no requirement line; each protection an area lacks is
  `finding: rule — <the invariant, in plain words>`, naming every place it must hold, and never a command.

A focus-areas line, when the ask has one, says what to grade first and deepest. A grade ask asks each finding's severity after its tag.

## The sort (T5)

Only a failed run stops a ticket: a test failing, or a planted break the tests miss. A grade's verdicts decide no row. At the ticket's first head, once its grade holds a `breached` or `unclear` line, SR, a fresh agent, sorts each such line of the one grade, once a ticket, before the ask; `kept` lines and findings do not reach it. The folder holds `sorted.txt`, the ticket's one sort report:

```
by: SR
commit: <the head read>
ROW-13 test it — <one-line reason> — <the grade line, word for word>
ROW-14 note it — <one-line reason> — <the grade line, word for word>
ROW-15 drop it — <one-line reason> — <the grade line, word for word>
ROW-16 prove it real — <one-line reason> — <the grade line, word for word>
```

The sort leaves out known-limit rows, and a `breached test` line on a row that is not deploy-owed, which skips it: TM plants a break aimed at what the line says, at that head, before the ask, and it reads as any fault. An inconclusive one stands apart, and replaces no fault folder. With no fault folder for that row, at the grade's own head, the line goes to the sort; at any later head it is closed. A joined line's break is aimed at its first reason. `test it` goes to TA, for a tests-only commit on the head that adds a case under the row's id, and then the head report alone, or with a decision's failing rows beside it, in the one pass of all that head's test lines: a failing test makes its row failing, a product failure, and a passing test closes it. A change to an existing case makes that row `retested:` in the next head report, and it takes its break. `note it` reaches the queue as a `finding: note` line. `prove it real` is for a line that belongs and could happen in normal use but that no test here can show, because the test environment is not where it happens (another operating system, the person's own machine, a real sign-in, a real outside service): it reads as a `finding: real` line, decides nothing of the ticket, and goes to the stage's staging okay, settled by its `real:` answer there, never by a finding's ruling. `drop it` stays on the report. A line on a deploy-owed row is never `test it`.

## The decision

In GitHub manual a ticket is decided, never a pull request: the comment goes on the ticket's issue, for the commit of main its ask
names, in the same form, the ticket's reports named by their `step-` ids; a pull request of a unit merged under the ticket at or
before that commit with no Decisions section makes it `not yet` with one line `no Decisions section — #<pull request>` each. A
commit not on main's own line (its first parent line; a pull request's head a merge brought in is not on it) is answered `ticket:
not yet` with the one line `not on main — <commit>`.

ViD posts one comment on the pull request for a head, again only if it changes, naming reports, not their words:
```
vid: decision <the head's full commit>
ticket: accepted | not yet
ROW-13 failing, a product failure — its test failed, pr-<pull request>-<head12>-1
ROW-14 failing, a weak test — its fault not proven, pr-<pull request>-<head12>-2 — siblings: ROW-15, and any other test with the same data pattern
ROW-17 evidence missing — no fault folder, pr-<pull request>-<head12>-2
```
A row also reads `accepted`, `accepted by ruling`, `known limit`, `owed`, `passing`, `question open`, `its state stands` or `held`; `held — it did not shrink`, when a new head's failing rows, held ones too, are not fewer than the head before's, leaving out a row at its first product failure that was failing as a weak test at the head before, or has a `list:` line. A row's state comes from runs alone. With no grade report, or a line of the one grade breached or unclear and open with no sort report, a decision reads `not yet` with one line, `sort evidence missing — <what>`, against no row, whatever else it reads. A pull request whose description has no Decisions section (neither the line `Decisions: none` nor a line `Decisions:` with at least one `- ` line under it) reads `not yet` with one line, beside every other line of the decision, against no row, and moves no row's state, count or hold: `decisions missing — the pull request's description has no Decisions section, nor Decisions: none`; once the section is there, the next `vid: decide` at that same head is answered without it. The reader's evidence holds a line `list: <row>` for each row with a line other than `kept` in the one grade, closed or not. A decision holding a product failure ends by asking for the whole harm to be fixed.
After the rows, three ticket-level lines stop nothing: `engine <e>: <n> could not run`, for an engine the ticket did not ask;
`split — every engine is now asked: <engines>`, when a row failed in one engine and passed in another, or once one has and the
ticket asked fewer engines than are declared; and once a ticket, at the head where the pull request's head reports reach 5 cases
that could not run in one engine, `analyst due — <engine>, <n> cases could not run over <k> runs`.

## Deploy reports (D1, RH, D2)

- `report.txt`: `by: DP`, the commit, and the outcome (passed, or failed with the failing step and whether it needs a
  product change); the okay's issue says which target the report is for;
- `deploy.xml`: one case per deploy step, named by the step (for RH: restore, migrate, boot);
- for RH, also `change.txt`: whether data migrates, each piece of data the migration drops or rewrites, and which
  outside services change; and in its `report.txt` the `kept:` lines, a table each, and in its `deploy.xml` the kept step;
- for a passed D1 or D2, also `duties.txt`: one line a duty its okay names, done, not needed or not done, each with its words;
- in every `report.txt`, of every target and outcome, the deploy's own decisions: one line `decision: <what> | why: <why>`
  for each choice it made, or the one line `decisions: none`. A report with neither is sent back, as an RH report with no
  `drops:` line is. ViD records each line of a report it accepts, whatever its outcome, in its DECISIONS.md, `enforced: deploy
  <the report's id>`, `scope: project`, `origin: dev-side`, once: a line whose words it holds already is not recorded again;
- for a passed D1, also `staging.txt`: a `staging: <address>` line, and one `signin: <role> <address>` line for each
  role the sign-in rows name; its `seed:` line, a `seam:` line for each outside-service row its okay names, and `stays: up`
  when staging stays up; and for each real check its okay lists (stage 0's okay always lists the skeleton's journey, run end
  to end where the product's people run it), `real: #<the okay's issue>-<n> done — <what was run, where>` or
  `real: #<the okay's issue>-<n> not done — <why>`, the key never another okay's. A check with no line, or not done, sends the
  report back; sent back twice, it waits on ViD's ruling: fixed, a row or a known limit. Each sign-in is test-only: it signs in as that role on staging, with no password, and
  never works on production.

**Test differences.** Each `stand-in:` line names a setting that differs between the team's tests and production. ViD
proves the real thing on staging. **Sign-ins.** A role's missing `signin:` line makes its sign-in row fail.

## The dev side stopped

When the team's own loop stops, for whatever reason, it says so where ViD reads, whether or not any work is open:

- **The stopped report:** the folder `stopped-<k>/`, on the branch `vid-results/stopped-<k>`, `<k>` one more than the newest
  before it. It holds `results.txt` alone, by DM:

  ```
  by: DM
  stopped: <why, in the words the team's own record gives>
  at: <UTC>
  ```

- **The comment:** `vid: stopped <why>`, then `by: DM`, on each open issue of ViD's that the team holds work for: a ticket it
  has claimed, a run or grade it has started, an okay it is working.

ViD reads a stopped report that is newer than every other report as the team stopped, and says so once. A later report
of any kind clears it. Starting the team again is the team's own act; ViD starts nothing.

## What makes a report complete

ViD reads the form only (in GitHub manual, of a ticket's results and a run's, the form its own section gives):

- the branch holds the report's folder;
- the commit is the one asked for (for T2, the one TM names), and the code repository holds it;
- `results.txt`, `sorted.txt`, `grade.txt` and `report.txt` each name the role this document gives them;
- each line of `sorted.txt` holds one of the four words;
- an S1 report's `commit:` is the candidate's, and it grades every asked requirement once, with one of the four words, and no other;
- a test report has a cases file for every asked engine (T2 and faults need only the primary; a close chunk's report, every engine of its chunk);
- a `retested:` line holds row ids alone;
- a passed D1 report has its `staging.txt`, with staging's address, and a `real:` line for each real check its okay lists.

A report that lacks one of these is not read: ViD says why on the issue or pull request it answers, and the role that
made it sends a new attempt. Nothing about a single row stops a report being read: a missing case makes its row fail, a
zero `covers:` makes its rule row fail unless its test could not run, and a retested row's missing fault folder leaves its evidence missing.

## Claims, pull requests and asks

- **A claim** is a comment on the ticket whose first line is `vid: claimed`.
- **A pull request** names its ticket: its body begins `ticket: #<n>`.
- **Its Decisions section:** the body holds a line `Decisions:` and under it one line a technical decision of the branch,
  `- <what was chosen> | why: <the reason>`, a line that bears on many areas of the product ending `| scope: project`; or the one
  line `Decisions: none`. ViD records each line in its DECISIONS.md when the pull request merges, marked `origin: dev-side`, in the
  dev side's words (a `|` in them written `/`), and a pull request with no section is not accepted.
- **An empty code repository:** a skeleton ticket whose header says `base: none` was written while the code repository had no
  branch at all. Its body says so; the dev side pushes main's first commit, then branches from it. No other ticket goes out
  until main exists.
- **Asking for ViD's decision** is a comment on the pull request whose first line is `vid: decide <the head's full
  commit>`, and nothing more. ViD finds the reports by their ids.
- **In GitHub manual alone, asking for ViD's decision** is a comment on the published ticket's issue, of any kind, whose first line
  is `vid: decide <a full commit of the code repository's main>`, and nothing more, once results that count at that commit are
  pushed ("GitHub manual" above); no grade and no sort is. It is
  unanswered while no `vid: decision <that commit>` comment follows it. A unit's pull request asking `vid: decide` is never
  answered there: the ask belongs on the ticket. A test the newest amendment of the ticket adds or restates counts the ticket's
  evidence only from reports made after that amendment.
- **A started run or grade:** on a run or grade ask's issue, the role the ask names comments `vid: started` when it starts.
