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

**Ticket mode (v0.26.10.25.5, R1): one door, which only drafts and asks.** While `.vid/RUN-STATE.md` says `mode: tickets`, in both GitHub modes, this branch is the one door for every change to rows (GM-4 F9), its text here alone: /vid add, /vid stage and /vid incorporate draft through it, each naming it, and /vid run, /vid next and the vid-answer skill send every `door:` line here. In both modes each draft is asked through the queue, `sh checks/queue.sh ask draft <n>` (step 4), and landed by the owner's yes through the vid-answer skill. What comes through it: a held row answered (d) amend, in the owner's words; a finding ruled `fix` or `row` (both end as a new row, whose ticket's T2 red shows the defect: a row never accepted has no fix line); an answer to a question that changes a row; the owner's own correction; an add; a pull-forward's addition to the stage (0.26.10.29.2, R5); the owner's re-cut of the stages by `/vid stage` (0.26.10.29.2, R2: refused for a stage closed or deployed, and for a cut that leaves a stage with no row; its plan change is a `scope-change`, and it records `stage-cut`); an edit of ARCHITECTURE.md's module table that a merge shows, counted as zero rows. It runs inside the caller's session (/vid run's, /vid next's, or the verb's own) and records no stage event of its own, so the run's stage stays the newest and `plan.sh` stays on. The version skew, the internal skills, test runs, fixers, the Tier-0 ritual and the re-grade below are not part of it: it writes no test and touches no code. In order:

**In GitHub manual** (GM-3 U2, GM M3: `sh "${CLAUDE_PLUGIN_ROOT}/checks/devagent-start.sh" mode` prints `manual`) the door is the same, with no plan block: no `--plan`, PLAN.md as HEAD holds it, since placing the rows is `/vid next planning-analysis`'s; and a change landed waits as pending at /vid next, where the apply brings it to the team, nothing posted on landing.

1. **The law read and the question** ("Input", below): CLAUDE.md → PRD.md → BASELINE.md → ARCHITECTURE.md → DECISIONS.md; a load-bearing product question asked at once, through the owner's queue.
2. **The change, in the working tree, uncommitted:** the PRD append in row grammar, a new item or an `AMENDED` restatement that keeps every clause the answer does not change, word for word; its inventory rows, the harm class named first ("Per correction", below); GRADING-CHECKLIST.md and DECISIONS.md lines when the change needs them; for new rows, the plan block as it will stand, in a file: the step each goes in, or a new step with its name, modules, lane and builds-on, and its `needs` line, so `sh checks/planner.sh check` passes; PLAN.md's standing lines when the change needs them, as a first stored entity needs its standing rehearsal. Run the courts on it (`sh checks/prd.sh`, `sh checks/inventory.sh --strict`; in ticket mode the inventory court reads no CLAUDE.md placement, v0.26.10.26.7) and the whole-set review in delta mode over the rows it touches, by a fresh agent (the Agent tool, `claude-opus-5-5`), given the change and the rows alone: its output, `none` or one `finding <row id> | <why>` a line, goes in a file, which the draft records (R5), and its record goes in the PRD append as at (a) below (0.26.10.29.3 R3: the landing commits through the hooks). Correct what it finds before drafting. Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.
3. **The draft:** `sh checks/land.sh draft --review <the review's file> --why "<one line: what changes, and whose words>" [--plan <the block file>] [--for <the item keys it answers>] [--replaces <n>]`; a finding's draft names the keys its `door:` line gives (v0.26.10.26.5), or the stage close waits on it. It runs the landing's dry run first (v0.26.10.26.7, R4): refused, no draft is made, the refusal names the failing check, and the tree stays for you to correct and draft again. A draft that replaces one already asked (a correction, or one gone stale) names it, `--replaces <n>`: its Q line closes, and the new draft is asked afresh; a yes is never carried over. Made, the files become draft `<n>`, the tree goes back to HEAD, and the count prints (`inventory.sh impact --tickets`): the lines reset, added and reached, and the records, which owe nothing.
4. **The ask:** `sh checks/queue.sh ask draft <n>`, one `Q<n>` line: "This changes <n> rows, adds <a> in <steps>, and reaches <m> more: <ids>. Land it?" Tell the owner in one plain message, then back to the caller: /vid run's loop at 2, or the call. One draft a question: a second draft on the same base goes stale once the first lands.

**A stage's finding** (v0.26.10.26.4, R2, R5), ruled `row` or `fix`: its `door:` line names the kind. A *rule* finding is a rule row: its fail-if names the invariant, and its test reports the places it covers, `covers: <id> <n>`, so every later ticket counts it once it is accepted. A *bug* finding is an ordinary row, which joins the regression rows once accepted. An absent guard adds its GRADING-CHECKLIST.md line in the same draft. An unmatched case kept is a row that names that case. Each fail-if is written as the harm, never the mechanism, in plain words. Place a stage's finding's row in a step of that stage; a production- or staging-owed row a difference brings, in a step of the next stage.

The owner's yes lands it: `sh checks/queue.sh answer Q<n> yes "<their words>"` runs `sh checks/land.sh <n>` (the vid-answer skill): a dry run on a scratch copy first, then the records, the commits, the plan change and `planner.sh reratify` in their words, so ticket writing goes on with no new sitting. Refused while paused or stopped (say yes again after continue), or stale when HEAD moved: a draft gone stale is drafted again, `--replaces <n>`, and asked afresh; one the owner has not answered stays. The landing's lines, said to the owner once in /vid run: `landed <n> at <commit>: …`, `reopened <step>`, `withdrawn <step> <k>`, `withdrawn stage-<N> <c>`, `ask-open stage-<N> <i>`, `stage <k>`: the change is in the spec, re-ratified by their yes; `next` exports it and writes the new tickets; a step that gained a row closes only by a fresh close. A re-cut (0.26.10.29.2, R2) that changed a stage with candidates not yet deployed withdraws each of them and the asks made at them, and the round names the stage's candidate again once it is due; `stage <k>` says the run's current stage is now stage <k> of the new cut; `ask-open` names an ask's issue the landing could not close: close it on GitHub. A protection's correction needs no hostility sibling: in ticket mode every protection is its own hostility row, and the new ticket's T4 plants its `disable:` fault, which re-runs the ritual. The hand-back is the draft's number, its count and its `Q<n>` line, then back to the caller: /vid run's loop at 2 (v0.26.10.26.7, R3), or the call.

**Stage events (v0.9.5 3.11, R11; RECORDS.md).** Outside ticket mode, in the project, record `sh checks/event.sh "stage name=fix state=start session=$CLAUDE_CODE_SESSION_ID records=28"` when this verb starts and `sh checks/event.sh "stage name=fix state=end session=$CLAUDE_CODE_SESSION_ID"` when it hands back. Every event this skill names is written the same way, `sh checks/event.sh '<event>'`, which appends it to `.vid/metrics-events` with its time.

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
  A `human` answer a fix adds is the owner's yes, and its commit quotes the
  owner's words in an `Owner:` trailer (0.26.10.29.3 R2; vid-create-prd,
  "The owner's words"); one ViD proposes is `model_proposed` until the
  owner says yes. Raised questions (0.26.10.29.3 R4): a question an agent's report raises that ViD cannot settle from the record (a ruling, the seed, or an owner answer it can cite) becomes an open carrier at once, `VID-QUESTION: (OQ-n) <the question>` in a dated append, raised with the owner at the next sitting; one ViD settles from the record is answered in the message to the owner with the record line that settles it (vid-create-prd, "The owner's words, and the questions raised").

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
convergence lesson).** A fix tends to stop at the boundary of the
sentence that described it: a closure can repair the named harm and
leave an adjacent, equally reachable path to the same harm open
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
4. A row the correction writes that guards or forbids is written with its
   control sibling, by vid-test-inventory §4.4's step: the allowed case
   shown working, so a fix that keeps the promise by doing nothing fails
   (0.26.10.29.3, R5).

The re-grade below carries the same question as a standing line.

### The forked protocol (§5): bug or rule

Findings from a grade report arrive tagged `bug` or `rule`; type-in
corrections you classify yourself by the promotion tell: **if the fix is
"add the protection that already exists somewhere else," the finding is a
rule, not a bug.** The unit of fix progress is the invariant, never the
instance — a late Critical is often an early invariant at a different
site.

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
  in `mode: delta` on the append against the effective set (v0.9.1 3.2),
  its record written in the append before the commit (0.26.10.29.3 R3:
  its findings, ruled, as rows of the section's own ```vid-prd-findings block (pass `review`), and the line `review: delta, round <r>, <n> findings` (`<r>` the round the review ended on, `<n>` the rows of the section's findings block, every round's; one round and no findings: `round 1, 0 findings`; vid-create-prd, "The findings record"); pre-commit refuses a new append section holding rows without it)
  — a `fix_from_record` finding is a further `AMENDED` row in the same
  append, a question goes to the owner before any code moves (v0.9.8.1
  R29: every finding that narrows or withdraws a fail-if arm, as one
  question for the review, listing each row, its arm and the answer it
  follows; the answer settles every row it names); what the repairs and
  the rulings land is read again by the same pass (vid-create-prd, "Reviews converge", in Pass mechanics: every repaired round is read again by the same pass, up to three rounds, and what remains goes to the owner as one list; 0.26.10.29.3 phase 2, R1); the run
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
already has a hostility sibling that attempts this arm through this way
in, the fix re-runs the ritual against it rather than adding a second
row; an arm or a way in the correction shows unprobed gets its own
hostility row, landed by the four steps above. The bound is
vid-test-inventory §4.3's (one probe per Tier-0 rule or invariant; for a
Tier-0 demand item, one per fail-if arm and, per arm, one per way in),
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
lands, append its repair and commit to that file. Run every helper in the foreground (`run_in_background: false`
on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you
started in the background, is running.

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
