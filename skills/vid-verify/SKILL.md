---
name: vid-verify
description: Internal — invoked by vid-develop and vid-fix; not a verb, never run by the owner. The row-verdict contract — the grader's pass (one verdict per row, per transition for a journey, against its Fail-if), the completeness check, recording each verdict and the attempt record, routing by class, blind re-grades, the computed bound and hold, the owner's "how far?" question and the hold's release.
user-invocable: false
---

# The verifier (internal)

Internal — invoked by vid-develop and vid-fix. Not a verb: `vid help`
does not list it, and the owner never runs it. It holds the row-verdict
contract, one copy for both callers (v0.9.7.0.5). Each caller keeps its
own parts: vid-develop the claim, the slice close, its backstop on
scope, the loop's stop and the first close's adjudication of report-only
checks; vid-fix its population, its per-REQ verdicts, its adjacent-path
line, its counts and its convergence stop.

## The grader

One fresh grader per pass, spawned with the repo path and its brief file
and nothing else of the session. Its own text is `passes/grader.md` —
the closed question, the verdict classes, the three sentences, the
return format — and every grader brief quotes it whole: vid-develop's,
written with `sh checks/brief.sh write --role grader`, and vid-fix's
re-grade, in GRADING.md's format. **What the brief withholds** is
GRADING.md's shared rule ("What every brief withholds",
`${CLAUDE_PLUGIN_ROOT}/skills/vid-grade/GRADING.md`); this skill cites it
and does not restate it.

## The return

**Check the return for row-count completeness before acting on it (§8):**
verdicts returned must equal rows claimed — one verdict per row, one per
transition for a journey, no silence. Fewer → the pass re-runs with the
same brief; a v0.7 grader silently skipped 1 of 47, and an unverdicted
row is an unevidenced completeness claim (F11). Record each verdict as
its own event (v0.9.2 3.6; v0.9.3 3.6): `sh checks/event.sh 'verdict slice=N row=ID
result=KEPT|BREACHED class=product|test|harness [transition=k/n]
[scope="<the grader's scope: question, double quotes made single>"]
brief=<the brief file the grader was spawned with> quoted-at=<the
commit that brief quotes>'` — `slice=fix-<date>` in vid-fix — a BREACHED
the grader returned with `scope:` carries it as `scope="…"` (v0.9.7.0.4
3.1) — the rows headline reads the LATEST ELIGIBLE per-row verdict (one
quoted before the row's latest amendment is recorded and ignored), a
newer BREACHED outranks an older KEPT, a passing row without a verdict
is `unverdicted`, never kept, and a row whose latest breach is `test` or
`harness` is `unverdicted` too. Append each verdict to the row's attempt
record, `.vid/verdicts/<ROW-id>.md` (v0.9.3 3.11): one block per verdict
— slice, result, class, counterexample or reason — and, after a fix, the
repair and its commit. A builder or fixer brief quotes that file; a
grader brief never does.

## Routing by class

BREACHED → routed by its class — information, not a fixed route
(v0.9.3 3.6). `product` → fix, then re-verdict with a FRESH grader
that is never told the previous verdict nor that a fix was made
(bandwagon effects run >70%). `test` → a test-author pass briefed with
the row and the grader's reason, never the verdict's wording as a
target; it adds or strengthens cases (free ledger additions) —
weakening or removing an assertion stays a law change with an owner
answer behind it. `harness` → `sh checks/event.sh 'incident slice=N harness row=ID
<what>'`; tests/invariants/harness.* is repaired by a test-author pass,
docker-compose.test.yml by a standalone law commit. After a `test` or
`harness` breach the row stays `unverdicted` until a fresh verdict.

**Fresh grading data (v0.9.8 3.5, R9).** A grader's case used to fix
the product — its counterexample turned into a fixture — becomes a
regression case: its fixture's header says `Provenance: regression — <whose
case, and the fix that used it>`. The next grader brief for those rows
lists it under `### Regression cases` and asks for fresh cases instead.

**Sweeps and lessons (v0.9.8 3.5, R8; amendment 3).** A confirmed weak
test — a grader's `class=test` BREACHED, or a conclusive proof that
failed (its verdict carries `proof=`) — is repaired with its siblings:
the test-author brief written for it (`sh checks/brief.sh write --role
test-author --rows <ROW-id>`) lists them in `## 18 siblings` (the rows
sharing an item it derives from — never a row only because it shares the
test file), and the pass checks each the same way, and any other test
with the same data pattern, in that one pass. When the weak test's cause
is new, write one lesson in `.vid/test-lessons.md`, no blank line inside
it:

```
## L-<n> · <UTC date> · from ROW-<id>
helpers: <the helper files it concerns, comma-separated, or none>
rules: <the REQ, RULE or ROW ids it concerns, comma-separated>
bad: <the weak test, one line>
why: <the wrong product it let pass>
good: <the strong form, one line>
```

Test-author briefs carry the entries whose rules or helpers match their
rows — their ids, or their test files (`## 17 lessons`), never the whole
file.

**Under breadth first (v0.9.7.2 3.6, R10)** — RUN-STATE's `strategy:
breadth-first` — a test-class BREACHED on a feature-step row goes to a
test-author pass at once and is never deferred (`metrics.sh defer` refuses
it): a core row's weak test is repaired before it can be KEPT. On a row in
a hardening step it may wait for that step, recorded with `sh
checks/metrics.sh defer --kind test …` (vid-develop, Breadth first).

## The fault proof (v0.9.8 3.4, R4) — measured, never a gate

A grader brief's `### Fault proof` names the rows in scope: protected
rows and journeys, rows repaired after a weak test, and one other graded
row in ten. The grader returns a
`fault:` line and a patch for each (`passes/grader.md`); it runs nothing.
The run manager proves each, one at a time:
1. a proof worktree at the brief's quoted-at: `git worktree add --detach
   .vid/proofs/<ROW-id> <quoted-at>`;
2. from it, the clean baseline: `sh checks/test.sh request --type
   prove-red --role orchestrator --purpose proof --rows <ROW-id> --why
   "<…>" -- <the target and control, in the runner's syntax>` — for a row
   whose evidence is deployed-shape (a journey or actor `(process)` row,
   when the harness declares `deployed-selector:`), `--type deployed`
   instead — and its `wait`;
3. `git -C .vid/proofs/<ROW-id> apply <the patch>`, then the faulted run,
   the same request, and its `wait`; a patch that does not apply needs no
   run;
4. the verdict: `sh checks/metrics.sh proof --row <ROW-id> --brief <the
   grader brief> --fault <the patch> --target <case> --control <case>
   --clean <receipt|none> --red <receipt|none>`, then `git worktree remove
   --force .vid/proofs/<ROW-id>`.

It is conclusive when the baseline passes both cases on the quoted
commit's tree and the faulted run, on that tree with exactly the patch,
fails the target and passes the control: `test-proven … result=proven`.
A target that still passes on the fault is a weak test: the command
records `verdict … result=BREACHED class=test proof=<receipt>`, routed as
any test breach (below). Anything else — a patch that does not apply, a
missing case, a failed baseline, a run that published nothing, the wrong
shape — is `inconclusive`, recorded and never a verdict. A proof request
is refused while another is open (`checks/test.sh`); its receipts are no
ordinary receipts (`checks/evidence.sh ordinary`): nothing credits,
claims, briefs or estimates from them. The probes keep their `disable:`
toggle as their fault. Proof gates nothing in this release — not done, not
completion; the pilot reads it (`sh checks/metrics.sh test-state`).

## The bound and the hold

**The bound is computed, never written (v0.9.3 3.6, R8, R9).**
`sh checks/metrics.sh` derives every row's rounds from the verdict
events — a round is one brief — and holds a row after two `product`
rounds since its latest KEPT, reissue or amendment (`reason=bound`),
two `test` rounds (`reason=test`), or two `harness` rounds with no
commit touching the harness between them (`reason=harness`); its
attempt count — `product` rounds since its latest KEPT or amendment —
never falls on a reissue. Two more holds (v0.9.7.0.4 3.2): a BREACHED
carrying `scope=` holds the row at once (`reason=scope`, before the
class bounds) until a reissue or an amendment; and after `reissued …
rounds=<N>` the row is held `reason=rounds` once N distinct briefs
have breached it, of any class, with no KEPT brief (the class bounds
still apply inside the N). A held row STAYS materialised: its test
field unchanged, no law commit, the headline counting it `breached`;
the claim skips it and prints `held row=ID reason=…`; queue it for the
owner with its attempt record — a `Q<n>` line gating that row (the
two-channel rule of the calling verb). The question's form (v0.9.7.0.4
3.3):

> `Q<n> · ROW-<id> held (<reason>) · <one-line summary of the breaches>
> · how far? (a) <the drafted clarification or narrowing> · (b) N more
> grading rounds (say N) · (c) record it as a known limit: <the part
> excluded, owed, with its reason>`

For `reason=scope` it quotes the grader's `scope:` text, and (a)
answers it. The answer releases the row:
- **(a)** a law commit amending the row as drafted (`amended`);
- **(b)** `sh checks/event.sh 'reissued row=ID why=<the ratified answer
  id> rounds=<N>'`;
- **(c)** ONE law commit that amends the row's obligation — its Fail-if
  — to the part that holds now (`amended`) and appends a new row for
  the excluded part, its test `owed: owner-decision — OQ-<n> <the
  limit, one line>`. That row is debt: counted owed, never KEPT, and
  completion stays unmet until it is paid or the owner strikes it.

It is released by an owner ruling —
write `sh checks/event.sh 'reissued row=ID why=<the ratified answer id> [rounds=<N>]'`, the one event
here the session writes — by an amendment (`amended`, written by
checks/hooks/post-commit), or by a KEPT from a fix's blind re-grade.
Code alone never releases a hold. The loop ends because failure has a
legal resting place: the owner's queue. No `owed: reverted` flip and no
`reverted` event (a 0.9.2 project's legacy rows and events stay and
are read as they were).
