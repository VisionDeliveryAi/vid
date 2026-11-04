---
name: vid-replan
description: Read what the dev team returned and move a ticket-mode plan on — ViD's second gate. Reads the code repository read-only (merged pull requests, their vid-return blocks and CI results; draft pull requests holding blocking questions), checks the return blocks, checks that ViD's tests are present and unchanged, imports the dev team's CI per-test report as evidence, grades the merged rows, answers questions through named people, changes the plan, closes a stage from main's CI run, and publishes the next tickets with their tests. Run when asked (daily, plus on demand for a blocked ticket); it never watches. Use when the owner says "vid replan", or after a ticket merges or is blocked.
---

# /vid replan (v0.26.10.9 R11, R12, R14–R18, R26)

The planner's working session in ticket mode (/vid plan published the
plan). ViD runs nothing on the dev team's infrastructure: its evidence is
the code, read in the read-only copy, and their CI's per-test report, read
from the artifact named for the run's attempt. It writes nothing to the
code repository but issues, labels, comments and milestones, through `sh
checks/github.sh`; never a push, a merge or a deploy.

## 1. Start, and read what came back

1. `sh checks/event.sh "stage name=replan state=start
   session=$CLAUDE_CODE_SESSION_ID records=29"`; invoke `vid-verify`.
   RUN-STATE's `run: active` (the gate is on: `mode: tickets`, a replan
   session).
2. `git -C .vid/code fetch`; `sh checks/github.sh pull`: every ticket's
   state and labels, every pull request naming a ticket (open, draft or
   merged), their comments, their CI runs and the runs' reports, into
   `.vid/tickets/`.
3. **Return blocks, checked here.** `sh checks/ticket.sh return-check
   .vid/tickets/pr-<n>/body.md --ticket <its brief>` on each pull request's
   block. An incomplete or malformed block gets one comment asking for the
   correction, naming each line (`vid: return block incomplete — …`, `sh
   checks/github.sh comment <pr> --body-file <f>`); nothing else waits for
   it.
4. **Draft pull requests and `blocked` tickets:** their `questions:`,
   `law-needed:` and `discovered:` lines are read now (§4); nothing in a
   draft is graded.

## 2. The skeleton, after it merges

`sh checks/ticket.sh import <pr>` on the skeleton's pull request (it
publishes the head's CI receipt when the report is there, and prints the
block's `skeleton:` lines). Read the merged skeleton in the copy
(`git -C .vid/code checkout <the merge commit>`) and check each `skeleton:`
line against it: the test framework and `tests/<dir>` exist, the run-one
command names them, the CI workflow of that name runs on a pull request
(opened, synchronize, reopened, edited) only the tests the `ci-scope:` line
of its return block selects — every test when the line is missing or
unreadable, the description read through an environment variable, never
pasted into a shell step — runs every test on a manual start of main (on
the run's own commit, no commit input) and nothing on a push to main,
checks out the exact commit (the pull request's head, not the merge
preview), and always publishes `vid-junit-<run attempt>`; the `run-full:`
line says how that manual start is made. Then write ARCHITECTURE.md's
```vid-code block's test facts — `test-framework:`, `test-dir:`,
`run-one:`, `ci-workflow:`, `report:` — and `run-full:` beside them,
committed alone.
**A `skeleton:` line the merged code doesn't bear out, or a missing report,
is a fix ticket with `kind=skeleton`**: `sh checks/ticket.sh skeleton-body
--req <the same requirement> --missing "<what is missing>" --out
.vid/tickets/skeleton-fix-<k>.md`, published as a new ticket (the original
is closed; a comment on it would go unread). Only then are the next
tickets' tests written in that framework.

**An older skeleton (v0.26.10.12 R8).** When the vid-code block holds the
test facts but no `run-full:` — a skeleton merged before 0.26.10.12, whose
CI runs every test on every pull request and push to main — say so once,
in the first replan report that finds it, and offer a skeleton fix ticket:
`sh checks/ticket.sh skeleton-body --req <the same requirement> --missing
"the CI runs a ticket's scope on pull requests and every test only on a
manual start (R1)" --out .vid/tickets/skeleton-fix-<k>.md`, published at
the owner's yes (a quick yes or no in chat; a no is not asked again). Its
return block carries `skeleton: run-full:`, checked as above. Until it
merges and `run-full:` is written, ViD behaves as 0.26.10.11: tickets carry
no CI scope, import checks every row of the ticket, and the stage close
reads main's run at the stage's last merge (§7).

## 3. Each merged pull request not yet read

`sh checks/ticket.sh import <pr>`:
- the copy checked out at the merge commit;
- **ViD's copy check:** each of the ticket's test files present at the
  merge commit and byte-identical to ViD's copy (the correction last sent
  is ViD's copy), recorded `copy-check pr= files= changed= missing=`; a
  missing or changed file is a finding: a fix ticket restoring it, and the
  replan report says so;
- **tests first:** the merged history holds a commit adding exactly the
  ticket's test files before any product change; when the dev team's CI
  ran on it and its report shows a row's cases failing, `red-observed row=
  pr= commit=<code sha>`, else the row is counted "red not shown". Events
  only: ticket mode writes no `proved-red:` stamp, and INVENTORY.md is never
  changed by an import;
- **CI results:** the head's run, bound to the vid-code block's repository
  and `ci-workflow:`, testing exactly the head, its report the artifact
  named for the attempt imported (`vid-junit-<attempt>`; an earlier
  attempt's never stands in), every row of the ticket with a case naming it
  under its test path — published as `<code sha>.ci-<run>-<attempt>.xml`
  with `.cases` and `.rows`. No report, a run of something else, or an
  expected test missing: nothing is published, the rows stay unverdicted,
  and the report names what was missing. **A ticket with a CI scope
  (v0.26.10.12 R5):** the expected tests are every row of its `### CI
  scope`, at their stamped paths — its own rows and the alarm set's; the
  receipt credits the ticket's rows only. An alarm row failing in that
  run is red evidence: the import prints `sent back:` naming it and checks
  no hand-back, so the ticket's rows stay unverdicted; write a **fix
  ticket** of the same step with the ticket's rows (§4's fix ticket, its
  selection as §6's CI scope has it): the red alarm rows are built rows,
  so they ride its CI scope's alarm set and its import holds them to
  green. A comment on the original names them; `ticket … state=fix`; the
  fix's grade completes the original (§4). A ticket without a CI scope is
  read as before;
- **the hand-back** `.vid/briefs/<round>/builder-<n>.return.md` from the
  block, and `sh checks/brief.sh return <file> --agent pr:<n>` (the code
  commit read in the copy, descending from the ticket's `base:`; a pass
  credited from the receipt's cases; ViD's copy check in place of the
  protected-path rule). Without a receipt the return isn't checked.

## 4. The grade (D3)

**Every merged ticket with a receipt has its rows graded:** one `git -C
.vid/code worktree add <a folder outside .vid/> <the merge commit>` per
graded merge, named in the grader's brief as the code to read (`--notes`);
`sh checks/brief.sh write --role grader --slice <round> --rows <the
ticket's rows> --receipt <the CI receipt> --notes <that file>`, one fresh
`vid:grader`, then vid-verify: completeness, verdict events, attempt
records, routing by class, blind re-grades. Remove the worktree after its
verdicts are recorded. A ticket without a receipt is not graded: its rows
stay unverdicted and the report says why.

**What this grade can see, against develop's:** the same code, read the
same way; ViD's tests present and unchanged; the dev team's CI results per
test. **What it can't:** a run of its own (no fresh or varied runs, no
fault proof, no checkpoint, no test analyst); a hostility probe's ritual;
ViD's commit courts on the code (placement, seams, imports, census,
harness); a test's red when the dev team's CI didn't run on the tests-first
commit; the running product (the staging check is deferred to the next
release). The replan report counts what each verdict rested on.

**The routes:**
- every row KEPT: label `done` (`github.sh label <n> --add done --remove
  ready`); the sub-issue closed if the merge didn't close it (`github.sh
  close <n>`); `sh checks/event.sh 'ticket issue=<n> step=<id> kind=<k>
  state=done'`;
- a product breach: a **fix ticket** — `sh checks/brief.sh write --role
  fixer --slice <round> --step <id> --rows <the breached rows> --selection
  '<run-one>' --ticket` (the selection as §6's CI scope has it) (the attempt record carrying the grader's
  counterexample), published as a new sub-issue of the same step, with a
  comment on the original naming the breach; `ticket … state=fix`;
- a test breach: the test-author pass corrects ViD's copy (a law commit); a
  fix ticket carries the corrected test;
- a scope dispute: vid-verify's "how far?" question, as a card.

**A fix completes its original.** After a fix ticket's grade, recompute the
original ticket's completion from each row's latest eligible verdict (`sh
checks/metrics.sh row-state --table`, its third column): when every row is
KEPT, `ticket issue=<the original> … state=done resolved-by=<the fix
tickets>`, and the steps that build on it can be admitted.

**Owed rows.** After a merged step is graded, write the tests of the
`prerequisite` rows whose payment point that step supplied into a
follow-up ticket of that step, as any ticket's tests (§6). Hostility probes
(`guard-first`) are not materialised: they stay owed, as ticket-mode debt.

## 5. Discoveries and blocked tickets

Routed as the scope's table has them, each change through the existing
records. `blocked-by:`, `new-work:` and a change too big for the stage are
routed as soon as they're read, from a draft or a merged block;
`early-technical:` and `user-visible:` wait for the merge.

| Came back | ViD does | Recorded as |
|---|---|---|
| `early-technical:` (merged) | records it; the later step shrinks | `plan.sh change rows … --trigger discovered-dependency --evidence step:<id>`, the pull request's number in the why, and the pull-forward decision as develop's rule has it |
| `user-visible:` | a question card to the area's answerer | a `Q<n>` line gating the ticket's rows, `question n=<n> state=asked gates=<rows> to=<answerer>` |
| `new-work:`, or the owner's /vid add (v0.26.10.11 R8) | a question card: add it or not, and in which stage (the add asked its own placement question) | on a yes, an append through vid-add's path in ViD's repository (vid-test-inventory's append mode writes the new rows `owed: spec-only — ticket`), then `plan.sh change add … --trigger owner-answer`; for the owner's /vid add, its append is already made: `plan.sh change add … --trigger scope-change --evidence commit:<the append commit>`. Their tests and tickets follow §6 |
| `blocked-by: #<n>` | the dependency recorded, the order changed | `plan.sh change edge` or `reorder … --trigger discovered-dependency` |
| a change too big for the stage | a revised stage cut proposed | a card; /vid stage re-cuts on the answer |

**Blocking** (a draft pull request, the ticket labelled `blocked`): its
`questions:` become cards to the area's answerer (ANSWERERS.md); its
`law-needed:` lines (a test or requirement that looks wrong) come to you.
The answer is a PRD append, or a corrected test in ViD's copy (a law
commit), in ViD's repository. Then, while the ticket's pull request is
unmerged: a comment on the ticket quoting the answer and any corrected test
file whole (under `#### <its path>`, fenced), `blocked` cleared and `ready`
set (`github.sh label <n> --remove blocked --add ready`), `ticket …
state=unblocked`; the dev team updates its branch from `origin/main` and
resumes. A correction to a test already merged goes out as a fix ticket.

**After the changes,** every published ticket whose brief changed is
re-written and published again with `github.sh publish --ticket <the new
brief> --issue <n> --why "<the plan change's why>"`: not taken, its body and
parts are replaced; taken, a comment quotes the why and what changed. Every
step issue a change names is rewritten by the same publish.

## 6. The next tickets: tests first, then the brief

For each step admission now admits (`sh checks/plan.sh start <step>`):
1. **Its tests first.** For its rows that have no test (`spec-only`, or a
   `prerequisite` the skeleton now supplies), spawn the test-author pass as
   develop briefs one: `sh checks/brief.sh write --role test-author --slice
   <round> --rows <rows>`, its `--notes` adding the vid-code block's test
   facts and the merged skeleton's test set-up, read in the copy. ViD runs
   none of these tests.
2. **Two commits in ViD's repository, in this order:** the returned files,
   unchanged, at their code-repository paths under `tests/` — ViD's copy,
   an ordinary commit (with the pass's `Tests-by:` trailer when a path is
   under `tests/invariants/`); then the rows' `test` fields changed to those
   paths, INVENTORY.md alone, a standalone law commit. A row the pass can't
   write stays or becomes `owed: prerequisite — …` in the second commit.
3. **The ticket:** `sh checks/brief.sh write --role builder --slice <round>
   --step <id> --rows <its rows> --selection '<the run-one selection>'
   --ticket` — `ticket: pending`, `base:` the copy's origin/main, `return:
   pull request`, and section 16: the stage and step, the acceptance tests
   whole, the design screens the rows' markers cite, the instructions and
   the vid-return block. **Its CI scope (v0.26.10.12 R2):** once the
   vid-code block names `run-full:`, the selection covers its rows' tests
   and the alarm set's — the journeys, the shell and the reachability rows
   of the merged tickets, never a hostility probe (ticket-mode debt) — in
   the runner's syntax, written by you (ViD never derives a selector from
   row ids). The brief stamps it in section 16's `### CI scope`: the
   selector, then each row with its test path, `ticket` or `alarm`; the
   return block's `ci-scope:` line carries the selector, and return-check
   holds the dev team's block to it. No neighbours: the stage's full run
   catches the rest. Without `run-full:`, no CI scope (an older skeleton,
   §2).
4. `sh checks/github.sh publish --ticket <the brief>`: a sub-issue of its
   step's issue, labelled ready.

## 7. A stage's end (D7, F8)

When every step of the current stage is merged and graded done, the full
run (v0.26.10.12 R3): `sh checks/github.sh run-full` — it starts the
skeleton's manual run on main and records `run-full started run= attempt=
sha=`, the run's own commit, refusing a commit that does not descend from
the stage's last merge; then, once that run is complete, `sh
checks/github.sh pull --commit <that sha>` (an unfinished run's report is
fetched by a later pull) and `sh checks/ticket.sh import --main <that sha>
--stage <n>` (the expected tests every ViD test of stages up to n; nothing
is asked of the dev team). Then `sh checks/metrics.sh stage-close --stage
<n> --ci <that receipt> --record`: ready when every ROW row of stages up to n passed in
that run, is graded KEPT, has ViD's copy unchanged at that commit, nothing
to confirm and no open question gating it; ticket-mode debt is listed, never
required — the rule rows, the hostility probes and every deploy-gate row,
each with its real executor and environment (production TLS, a backup
restore, an image audit are the dev team's evidence, not ViD's); the census
and coverage's REQ-citation and design-marker joins are reported "not
checked in ticket mode" (a ticket may mention citing REQ ids as a courtesy,
never as a gate). It records `stage-closed n=<n> sha=<the code commit>
source=ci run=<id>`, `stage: <n+1>` and `## stage <n>` in SLICE-REPORTS.md
with the debt. No tag, no staging step, no setup hold.

A fix ticket that merges past that run (before the close, or a breach the
close found): the full run once more, from `run-full`.

**An older skeleton (§2), no `run-full:` yet:** no `run-full`; `sh
checks/github.sh pull --commit <the stage's last merge commit>`, then
`import --main <that commit> --stage <n>` reads main's run there and
`stage-close --ci` its receipt, as 0.26.10.11 did.

Then `sh checks/github.sh close --milestone <n> --commit <that commit>` —
the milestone closed naming the commit, the dev team's deploy input — and
the next stage's ready tickets are published (§6). The deploy is the dev
team's.

## 8. The replan report, and the end

Write `.vid/replans/<round>.md` and render it (`sh checks/page.sh
.vid/replans/<round>.md`; an artifact when the session has the tool, else
the path): what came back; return blocks checked and corrections asked;
ViD's copy checks; CI imports, and every run refused or missing with what
it lacked; grades (KEPT, BREACHED and unverdicted by row, and the evidence
each rested on, counted); fix tickets and the originals they completed; the
planner's own usage (this session's usage records); the stage's debt and
what wasn't checked in ticket mode, when it closes; plan changes with their
why and trigger; questions as ```vid-card blocks, grouped by answerer;
the stage's state; the next tickets; the stage's `ci-minutes forecast`
line (`ticket.sh forecast --stage <n>`: the mean test time of the imported
CI runs, labelled measured, else unknown — a forecast, nothing gates on
it; v0.26.10.12 R7). Refresh the plan page (`ticket.sh plan-md`, which
prints the forecast too; `page.sh`). Quick yes/no questions stay in chat.

RUN-STATE's `run: waiting` (what it waits for, in one line); `sh
checks/event.sh "stage name=replan state=end session=$CLAUDE_CODE_SESSION_ID"`;
the report's link or path to the owner.
