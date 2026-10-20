---
name: vid-fix
description: Apply specific corrections to a ViD project, targeted only — each becomes a PRD append + ledger test + fix commit, then a scoped internal re-grade of the touched areas. Input is plain-language corrections from the owner, or the accepted rows of a /vid grade findings file. Never sweeps, never full-grades — discovery belongs to /vid grade. Use when the owner states something to change or hands over adjudicated grade findings.
---

# /vid fix

TARGETED APPLY ONLY. fix never sweeps and never grades the whole project —
discovery is /vid grade's job. The full review cycle is composition, not a
verb: `/vid grade` → the owner adjudicates the findings table (fix / dispute
/ defer) → `/vid fix <accepted>`. The adjudication sitting is the seam
between the two commands; that is where the human belongs.

Narrate position between corrections ("2 of 5 applied; next: alert digest") —
visibility, not approval-seeking.

**Stage events (v0.9.5 3.11, R11; RECORDS.md).** In the project, record `sh checks/event.sh "stage name=fix state=start session=$CLAUDE_CODE_SESSION_ID records=28"` when this verb starts and `sh checks/event.sh "stage name=fix state=end session=$CLAUDE_CODE_SESSION_ID"` when it hands back. Every event this skill names is written the same way, `sh checks/event.sh '<event>'`, which appends it to `.vid/metrics-events` with its time.

**Version skew (v0.9.7.0.7 3.8).** Read `checks/records-version` first. If it is absent or below 24, the project's checks/ predates this plugin: tell the owner it needs the refresh and stop before fixing; so too a project holding STAGES.md whose checks/ is below 25 (v0.26.10.5). The refresh (v0.9.8.1 R5): first run `sh "${CLAUDE_PLUGIN_ROOT}/checks/local-changes.sh"` from the project's top level and show the owner its list — the project's commits under `checks/` since the last refresh, and its uncommitted changes there — since the copy overwrites them; each is carried over or dropped on purpose. Then copy `${CLAUDE_PLUGIN_ROOT}/checks/` changes over `./checks/` and commit it alone with `VID_ROLE=fix`, its subject `Refresh checks/ to VID <version>` (the next refresh's list counts from it) — its fixers are briefed with their test selection and hand back through `sh checks/brief.sh return --agent` (v0.9.7.1), which an older checks/ lacks.

**The internal skills (v0.9.7.0.6 3.5).** Right after the stage start, invoke the `vid-test-manager`, `vid-verify` and `vid-build` skills (the Skill tool) — the test manager's rules, the row-verdict contract and the rules for building a step. Claude Code restores after a compaction only the skills that were invoked, never a file that was only read.

**Test runs (v0.9.7.0.2).** Nobody runs the test runner directly. To get a test result, make a request to the test manager.
Its rules are the `vid-test-manager` skill, invoked at the stage start:
`sh checks/test.sh request --type prove-red --role orchestrator --rows <ROW-id,…>
--why "<one line>" -- <selection>` — your own requests carry no brief, so
no attempt id (v0.9.7.1; a fixer's own requests carry its brief's `--try`)
— then `sh checks/test.sh wait <ticket>` until it ends.
When a request's result says `analyst due`, start the test analyst (`vid-test-manager`, the test analyst).

## Input — two sources, same handling

- The owner typing one or more specific corrections in plain language
  ("save button gives no feedback on the listing page").
- A correction already in the code, named by the owner with its commit
  (v0.26.10.7 R16; Recording a correction already made, below).
- A findings file produced by /vid grade that the owner has adjudicated:
  `/vid fix .vid/grades/2026-08-11-grade.md` — apply exactly the rows marked
  accepted. Disputed rows die. Deferred rows become `VID-QUESTION` markers if
  they aren't already — in an enriched PRD, a carrier `VID-QUESTION: (OQ-n)
  …` in a dated append, its number continuing the sequence. Resolving a
  carrier is the reverse, in one commit: the owner's answer as an
  `A-NNN` ledger row, the item's `AMENDED` row, and the carrier line
  rewritten `RESOLVED: (OQ-n) A-NNN — …` (the one line of the base that
  may change; the court refuses a pending item left pointing at it).

Read the law first: CLAUDE.md → PRD.md (base + Appends) → BASELINE.md →
ARCHITECTURE.md → DECISIONS.md. A correction that raises a load-bearing
product question follows the two-channel rule: ask immediately, plain
language, recommendation attached.
A new DECISIONS line takes its number from `sh checks/decisions.sh next` (v0.26.10.4), reserved at the home, so you and your fixers never share one.

**Stages (v0.26.10.5 R5, R10), when STAGES.md exists.** A correction that
appends a new feature puts it in a stage as vid-add does: the owner's
answer in the same sitting as the append, the placement its own law commit
citing it (`Stages: A-NNN`); a new requirement in an existing feature takes
that feature's stage. A correction to a stage already closed (a
`stage-closed` event, its `vid/stage-N` tag) never moves the tag: it ships
with the next stage's close, which re-checks stages 1 to N; until then
`sh checks/stages.sh deploy` names it among the commits the live candidate
lacks, and `sh checks/metrics.sh` lists it under "since stage N's close".
**While the owner holds the next stage** (`stage-hold n=N state=on`;
v0.26.10.7 R13), every commit after the tag is a correction or a deploy
record, since develop isn't running: work on the develop line as always.
The staging candidate is then HEAD, so `/vid deploy staging` takes the
correction to staging on its own; a production deploy of it tags
`vid/stage-N.k`, and `vid/stage-N` never moves.

**Recording a correction already made (v0.26.10.7 R16).** The owner may
name a correction already in the code, with its commit (for one made
during a deploy). Each becomes a PRD append and a ledger test, as any
correction does, with no fixer: commit them first (`VID_ROLE=fix`). Its
red is seen with the change undone in the working tree, as a hostility
probe's red is seen with its protection disabled: `git revert --no-commit
<commit>`; a `prove-red` request for the new test and its wait; then `git
revert --abort`, which puts the tree back as HEAD holds it (commit before
the revert: the abort drops anything staged). The `proved-red:` stamp names
HEAD, where the red was observed. The re-grade runs as below, with `sh
checks/metrics.sh fix-population --base <the parent of the earliest named
commit>`, so the correction's own source changes are in its scope.

**A change to the law, counted first (v0.26.10.3 R3, R5).** A question
whose recommended answer would change a fail-if or a row's obligation
quotes `sh checks/inventory.sh impact` on a scratch draft of the change,
and approvals of several answers at once follow vid-develop's two-channel
rule: one `impact` on the combined drafts, and one confirmation from the
owner before landing when any row would be reset. Land the narrowest
change: an AMENDED restatement keeps every clause the answer does not
change word for word. After the fix's law commits and before the re-grade,
run the test-author pass on every row its amendments flag — `sh
checks/brief.sh authority --changed`, rows to confirm included — and
record each `kept` with `authority --kept`; a row the pass amends is
reset. The re-grade then runs as below.

**ViD's own defects (v0.26.10.3 R12, R13).** When a ViD check, hook,
skill or agent role misbehaves — it refuses legitimate work, crashes,
contradicts itself or its documentation, or gives a wrong count — or when
you use a workaround around one, append an entry to `.vid/VID-FINDINGS.md`
in the form of `${CLAUDE_PLUGIN_ROOT}/templates/VID-FINDINGS.md` (the file
is created from it at the first entry; entries are numbered in the file),
record `sh checks/event.sh 'vid-finding n=<n> area=check|hook|skill|agent file=<ViD
path>'`, and tell the owner in one line. A defect in the product being
built is not a ViD finding.

## Per correction — first the harm class, then the forked protocol

**Scope to the harm class, never the named instance (v0.8.1d — the
convergence lesson).** The fixes of a field run stopped at the boundary
of the sentence that described them: five closures repaired the named
harm and left an adjacent, equally reachable path to the same harm open
— the expiry consequence fixed while the parse causing it stayed; a
pre-tick removed while the no-statement mode kept sending; a queue built
while the send failure was discarded under a screen asserting success; a
proxy key fixed while registration stayed an open oracle with no
per-account bound; a name path fixed while the postcode path stayed
circular. The finding's sentence had become the fix's spec, and the fix
inherited its narrowness. So, per accepted finding, BEFORE scoping:

1. Name the forbidden effect the finding is an instance of — the harm,
   not the mechanism that was missing.
2. Enumerate the adjacent reachable paths to that same effect — other
   causes, sibling modes, other entry points, the second occurrence — and
   scope the fix to the class they share. The rule-shaped fork below
   handles the same guard missing at sibling SITES; this step handles the
   same harm reachable through an adjacent CAUSE.
3. Write the dual-written row's Fail-if as the HARM ("no feed shape that
   parses to zero records expires inventory"), never as the instance or
   the mechanism ("the expiry guard exists") — a mechanism-worded clause
   is satisfied by code that keeps the mechanism and still does the harm.

The re-grade below carries the same question as a standing line.

### The forked protocol (§5): bug or rule

Findings from a grade report arrive tagged `bug` or `rule`; type-in
corrections you classify yourself by the promotion tell: **if the fix is
"add the protection that already exists somewhere else," the finding is a
rule, not a bug.** The unit of fix progress is the invariant, never the
instance — three of the v0.6 run's round-3 Criticals were round-1
invariants at a different site.

**Bug-shaped** — apply it in ONE commit with `VID_ROLE=fix` set (unchanged
dual-write):

- (a) PRD append — wherever the correction clarifies product behavior — in
  the PRD's row grammar: a dated append heading naming the source
  (`(/vid fix correction)`), then a ```vid-prd block carrying either a
  new `REQ-NNN` row (a demand type, tier, statement, `fail-if:`,
  `serves:`, `phase:` inherited from the amended item unless the ruling
  moves it — v0.9.1 3.6; id continuing the sequence) or a full `REQ-NNN AMENDED`
  restatement of the row it corrects, every field restated, plus `arms:` —
  one entry per arm of the row it supersedes (`retained · strengthened ·
  moved <id> · withdrawn <A-NNN>`; v0.9.1 3.5b, joined by checks/prd.sh
  under `grammar: 0.9.1`). Both carry
  `authority: authoritative` — an owner correction is the owner's hand —
  and `source:` naming the fix sitting or the adjudicated finding
  (`fix 2026-09-09`, `grade 2026-09-09 finding 3`); under a PRD headed
  `grammar: 0.9.4` or later, `feature:` too — an AMENDED row keeps its
  item's, a new row takes the feature of the item the correction
  concerns; under a PRD headed `grammar: 0.9.5` or later every new or AMENDED demand item and invariant also carries `plain:` — one sentence of at most 30 words saying the rule in the owner's words, no ids, every number in it taken from its own statement or fail-if (v0.9.5 3.13) — an AMENDED row restates it with every
  other field. The sitting reference puts the row in the court's
  `values-unchecked=` count instead of the values join: the owner's words
  are not in the PRD. checks/prd.sh judges
  the EFFECTIVE set at the fix commit, so an amendment has teeth it never
  had: an AMENDED row that drops its Fail-if, its serves, or breaks an
  enum fails the commit, and a fresh row without a falsifier never lands.
  A pre-enrichment PRD (no ```vid-prd block) keeps its `### REQ-NNN`
  block form — the court is presence-gated and leaves it alone. Before
  (b) and (c): spawn
  `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/whole-set-review.md`
  in `mode: delta` on the append against the effective set (v0.9.1 3.2)
  — a `fix_from_record` finding is a further `AMENDED` row in the same
  append, a question goes to the owner before any code moves (v0.9.8.1
  R29: every finding that narrows or withdraws a fail-if arm, as one
  question for the review, listing each row, its arm and the answer it
  follows; the answer settles every row it names); the run
  records `sh checks/event.sh 'tokens slice=N phase=review n=T'`.
- (b) ledger test in tests/invariants/ keyed to that REQ, through the public
  surface only, fixture law respected — WRITTEN BY A TEST-AUTHOR PASS
  (`${CLAUDE_PLUGIN_ROOT}/skills/vid-test-inventory/passes/test-author.md`,
  spawned with the row, the harness contract and the boundary rule, and
  nothing of this session; v0.9.2 3.1, R1; v0.9.8 R1, R5: it writes by
  the test-writing skill, with its test argument; its brief carries the
  row's authority bundle), committed unchanged with its
  `Tests-by:` trailer; the fixer commits and requests it — `prove-red`, against the
  pre-fix tree first — and stamps the row `proved-red: <parent-sha>` (a test never seen
  failing is not evidence; the court joins the stamp — the file must exist
  at that sha and name the row or its REQ — and resolves the cited path
  against the commit under construction, never the working tree: the
  numbered rhythm is test, then row, then code)
- (c) the fix itself

Commit message: template; the REQs line names the REQ; Decisions line as
always.

**Rule-shaped** — the deliverable is a denominator, not a patch. A fix for
a rule-shaped finding is NOT accepted while the rule row does not exist:

1. Write the RULE row with its census command (and its extractor, if the
   enumeration needs one) — its own standalone law commit (§4.1). Ratify it
   with `test = owed: census-armed — sites being guarded, fix <finding id>`
   (v0.9.2 3.2's class for exactly this repair) so its orphans report
   `pending` (debt-aware) while you work.
2. Run `sh checks/census.sh`; fix EVERY site it enumerates, not the one the
   finding named.
3. The fix commit states the count in its message: `census: 14 sites,
   14 guarded`.
4. The row's ledger test asserts over the enumerated set — it grows with
   the codebase instead of pinning remembered spots. Authored by the pass,
   like (b); red-first and proved-red as above. Materialising the test (the owed→path flip, its own
   law commit) ARMS the census: from then on a new unguarded site fails the
   commit that introduces it.

**Tier-0 fixes carry the fail-first ritual (§4.2).** When an accepted
correction touches a Tier-0 protection — the fix restores, adds, or repairs
a must-never-happen — the dual-write above is not enough on its own. A
regression test driving the intended path proves the path still works; it
does not prove the protection holds, and the defect being fixed is the
proof of that: the guard was there and something got past it. So the fix
also lands the protection's **hostility sibling** — one row, one probe,
attempting the forbidden thing through the real public surface, keyed to
the defect just fixed so it cannot silently return. Whether the finding
was bug-shaped or rule-shaped, the row and its probe go through the same
four steps, in one sitting:

1. Prove the runner can go red — a `prove-red` request whose selection
   names a test that does not exist; its result shows `ran-to-end=no` and
   the runner's status, which is the observation. A runner that exits 0 on an empty selection makes
   the probe a green that can never go red, which is worse than no probe.
2. Disable the protection by the row's own `disable:` toggle, request the
   probe (`prove-red`), and watch it fail **on its assertion about the forbidden
   effect** — not on a connection error, a 404, or a fixture fault.
3. Restore the protection; the probe passes (a `prove-red` request).
4. Stamp `proved-red: <sha>` (the commit where step 2 was observed) in the
   row's own standalone law commit.

A probe with no verified failing state is rejected at materialisation:
checks/inventory.sh fails the commit that cites it unstamped, and a row
with no usable `disable:` toggle is rejected outright — without the toggle
the ritual cannot be re-run by anyone who comes later. If the protection
already has a hostility sibling, the fix re-runs the ritual against it
rather than adding a second row: the bound is ~one probe per protection,
and probes beyond the ratified protections are ceremony.

**Robustify-proposed rows (§7).** A `/vid grade --robustify` report
proposes ROWS, not findings: invariant rule rows with denominators,
state-machine transition tables, additional executable checks, gates.
The owner adjudicates them like any findings table; accepted proposals
enter through the NORMAL dual-write above — each row its own standalone
law commit (census command and, where the enumeration needs one, its
extractor + selftest case), test red-first and stamped proved-red, every
enumerated site guarded before the row counts paid. A proposed row
asserting on an implementation symbol is rejected at adjudication:
behavior-keyed through a public surface is the contract, and no proposal
ever arrives as a coverage score.

**Checklist growth (§7.2):** when an accepted finding is absent-guard class
— nothing in the repo represented the missing thing — add one line to
GRADING-CHECKLIST.md in the fix commit. This run's blind spot becomes next
run's standard question.

**Or dispute** it with evidence: if the code already does what the correction
asks, or the correction contradicts a live PRD append, show the owner the
file:line and the conflicting spec line. That is a product conversation, not
a silent skip — the owner decides which way the spec goes.

**A deferred row (v0.9.7.2 3.7, R11).** When a correction fixes a row an
open `deferred` event names (a breadth-first develop's edge finding),
record its disposition once the fix lands: `sh checks/metrics.sh
defer-resolved --row <id> --by <the fix's commit>` — never a verdict; the
re-grade below is what makes the row KEPT.

## After applying — the blast-radius re-grade

Re-grade scope is COMPUTED, not guessed: the changed modules **plus their
declared dependents**, read from ARCHITECTURE.md's seam table (the same
table the import court executes, so the dependency graph is real). Never
the whole project — fix-injection was unbounded exactly when nothing could
compute which modules a fix endangered. Fresh-context grader(s) per
`${CLAUDE_PLUGIN_ROOT}/skills/vid-grade/GRADING.md`, scoped to the REQs of
those modules, the brief carrying that engine's standing adjacent-path
line: for each fixed finding, find an adjacent path to the same harm the
fix did not close — the fix's sentence boundary is the attack surface.
Mandatory and internal, never owner-facing: fixes inject
defects at a measured rate. **The re-grade verdicts the fix's rows
(v0.9.2 3.11; the population v0.9.3 3.13):** the brief carries, verbatim
with their Fail-ifs, every row in the re-grade population and, for the
row verdicts, quotes `${CLAUDE_PLUGIN_ROOT}/skills/vid-verify/passes/grader.md`
whole — one KEPT / BREACHED with its class per such row, per transition
for a journey — beside GRADING.md's doctrine for its per-REQ verdicts. Under an
inventory block opening `grammar: 0.9.3` the population is computed, never
chosen: `sh checks/metrics.sh fix-population --base <the commit before the
fix began>` lists every row the fix materialised or re-paid (a legacy
`owed: reverted — …` row whose test is green again — the clause stays for
upgraded projects), every materialised row whose derived-from REQ or
marker is cited in a changed module or one of its declared dependents
(the citation join over application source, which excludes tests) and
whose latest verdict is not KEPT, every materialised row whose cited
ledger test the fix's commits changed (a `test`-held row repaired by a
test-author pass strengthening its green test touches no module), and,
when the fix touched `tests/invariants/harness.*` or
`docker-compose.test.yml`, every row held `reason=harness` — held and
reissued rows included; a KEPT returned there on a held row releases the
hold. Under a 0.9.2 block the population is the fix's materialised and
re-paid rows, as before. **The row verdicts follow `vid-verify`**
(`${CLAUDE_PLUGIN_ROOT}/skills/vid-verify/SKILL.md`, v0.9.7.0.5): what
the brief withholds, the return's completeness check, recording each
verdict with `slice=fix-<date>`, the attempt record, routing by class,
blind re-grades, the bound and the hold; its fixer and `test`-class
test-author briefs are written with `sh checks/brief.sh write --role
fixer|test-author --slice fix-<date>`. A BREACHED row is not fixed,
whatever the REQ verdict says. Without this the rows would stay
`unverdicted` in the headline with no develop slice to close them. The
adjacent-path line and the law-change log stay the brief's inputs.

**The fixer carries the history the grader never sees (v0.9.3 3.11).** A
correction whose work goes to a spawned fixer writes its brief with
`CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/brief.sh write --role
fixer --slice fix-<date> --rows <ROW-id,…> --selection '<the rows' test
selection, in the runner's syntax>'`, which quotes each row's
attempt record, `.vid/verdicts/<ROW-id>.md`, whole (`vid-verify`). The
fixer builds by `vid-build`
(`${CLAUDE_PLUGIN_ROOT}/skills/vid-build/SKILL.md`). Spawn it by its type,
`vid:fixer` (the Agent tool's subagent type; v0.9.7.1), with the
repository path and the brief file, and nothing else of this session. Its
brief's header names its first act, `sh checks/plan.sh home --brief <its
brief file>`: the fixer records the project as its home before anything
else, so its requests publish their receipts and events here and its
hand-back is read here (v0.26.10.7 R6, F-58); a test author this verb
spawns does the same. The
attempt count is computed
(`sh checks/metrics.sh row-state --table`), never restated. After the fix
lands, append its repair and commit to that file.

**The hand-back (v0.9.7.0.7 3.3; v0.9.7.1 3.4, 3.7).** The fixer writes
its return file itself, at the path its brief's header names
(`.vid/briefs/fix-<date>/fixer-<n>.return.md`), and its final message
begins `return: <that path>`. Record it with `sh checks/brief.sh return
<file> --agent <the agent id from the Agent tool's result>` before acting
on it — it writes the `agent:` line in, checks every row of the brief is
there once and each `pass` is shown passing by its receipt, and records
the fixer's `build-cost`; it prints each row's results, the merge probe,
the fixer's uncommitted files and its `law-needed:` lines. When the fixer
ended with requests nobody will read, cancel them: `sh checks/test.sh
cancel --try <its try>`; a request of your own, with no attempt id, by its
ticket: `sh checks/test.sh cancel --ticket <its ticket>` (v0.9.8.1 R28). A refusal names the line; it does not route:
what each row needs is yours to decide. A continuation (when actionable
work remains) gets a new brief whose `--notes` names the earlier branch,
commit and return file.

The re-grade reports two separate numbers — regressions the fixes
INTRODUCED vs pre-existing defects they newly EXPOSED (different problems,
different responses; conflating them hides whether the codebase is coupled
or merely under-explored). Repeat apply → re-grade until the radius grades
clean; if findings stay flat round over round, stop — non-convergence means
a class the loop cannot see (grade's convergence rule) — and escalate to
the owner naming the suspected class.

**Then consolidation.** After the last batch of a grade adjudication and
before the final report, run the scheduled event of vid-create-prd's
"Consolidation": 7a `sh checks/prd-consolidate.sh`, 7b's review, one
row-set-diff sitting, two commits. Never mid-adjudication; a type-in
correction alone does not trigger it, and an add never does.

## Reporting — from where the owner sits

The first line is the rows headline (v0.9.2 3.11: `sh checks/metrics.sh`'s
`rows: kept K · unverdicted U · breached B · red R · owed O · deploy-owed
D (unmet …)`, `receipt: none` when HEAD has no export-backed report).
Then report the final state in a few sentences. A correction is never
reported as working on the basis of a status code, a passing test, or a
check in a browser the owner does not use (CLAUDE.md law): every claim
states its evidence class — ledger test, browser-class WebKit/Chromium
test, coverage join — or says plainly that it is unverified. For anything
the browser class covers, the browser result IS the claim. Fix commits
carry the `Model:` trailer, like develop's. When the project has
deployed (DEPLOYMENT.md exists), the report's last line is "`/vid deploy
staging` takes these to staging" (v0.26.10.7 R17).

**The progress record (v0.9.5 3.10).** A fix changes row states with no
develop slice to close them, so the final report also appends a
`## fix <UTC>` section to `.vid/SLICE-REPORTS.md` — the computed block and
the closure: `printf '\n## fix %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
>> .vid/SLICE-REPORTS.md; sh checks/metrics.sh >> .vid/SLICE-REPORTS.md;
sh checks/metrics.sh closure >> .vid/SLICE-REPORTS.md`. The newest section
is what a viewer reads as current (RECORDS.md).
