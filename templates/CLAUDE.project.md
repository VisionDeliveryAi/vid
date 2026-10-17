# {{PROJECT_NAME}} — CLAUDE.md (the ViD law file)

{{THREE_LINE_SUMMARY}}

This project runs under ViD (VisionDelivery.ai): the spec (PRD.md) binds what
gets built; the ledger (tests/invariants/) binds what stays built. Everything
in this file is law, not advice.

## Reading order (every session, before any work)

1. **PRD.md** — base first, then `## Appends`. Later appends win over the base
   and over earlier appends.
2. **BASELINE.md** — stack, named FORBIDDEN alternatives, Tier-0 rows, test environment.
3. **ARCHITECTURE.md** — the seam table: who owns what. Executed, not
   descriptive — it is the import court's rule source.
4. **DECISIONS.md** — choices already made. Do not re-litigate them.
5. **design/** (when present) — the second half of the spec: tokens and
   components are visual law; screens/ are the surface to transcribe,
   not inspiration.
6. **INVENTORY.md** (when present) — the ratified Test Inventory: every row
   is an obligation the ledger verifies; the inventory court reads it at
   every commit.

A spawned agent reads its brief — the quotations and the role's required
inputs — and nothing else is mandatory; the linked sources are further
reading it takes at will. The orchestrating session reads in the order
above. (v0.9.3 3.1, R2: the brief is a file under `.vid/briefs/` that
quotes and never summarises; `sh checks/brief.sh` checks it before the
spawn.)

## Placement rules

{{PLACEMENT_PROSE}}

New files must land under one of these prefixes (machine-read by
checks/placement.sh; a line may be an exact filename). Root doc/config files,
checks/, and tests/ are always allowed:

```vid-placement
{{PLACEMENT_PREFIXES}}
```

## Two-channel question rule (the core asymmetry of ViD)

The owner is a world-class product expert who knows little or nothing about the code.

- **Product questions** — behavior, domain semantics, policy, priorities,
  anything load-bearing about what the product should DO — ask the owner
  **immediately and freely, at any point**: during init, mid-develop, during
  fix. Never guess load-bearing product meaning; never defer a product
  question that blocks correct work. Ask in plain language, with a
  recommendation when the evidence supports one. Every answer dual-writes:
  append to PRD.md `## Appends` in the PRD's row grammar — a dated append,
  the answer as an `A-NNN` ledger row, the behavior as a `REQ-NNN` row
  with its `fail-if:` and `serves:` or a full `REQ-NNN AMENDED`
  restatement (checks/prd.sh judges the effective set at every commit) —
  plus a ledger test when testable.
- **Technical questions** — architecture, libraries, data structures,
  implementation strategy — decide and log to DECISIONS.md. Do NOT ask.
  Escalate only when a technical choice forces a product tradeoff ("instant
  search vs cheap infra — pick one"); at that point it has become a product
  question.
- **Non-blocking product uncertainties**: leave a `VID-QUESTION: <question>`
  marker at the site and batch them at session end. Anything load-bearing is
  asked when hit, never batched. Open markers block "done"
  (checks/coverage.sh counts them).

## Decision trigger

Append to DECISIONS.md whenever a choice (a) picked between plausible
alternatives, (b) constrains future code, or (c) would surprise a competent
newcomer. Always mandatory, regardless of trigger: any hand-rolled
implementation of a security-relevant mechanism (crypto, TOTP/MFA, session
tokens, signing) gets a D-entry naming the standard it implements. Format
(the `| enforced:` ref and the label are hook-enforced):

    - **D-NNN** <what> | why: <why> | enforced: <test/hook ref, or "convention"> | applies-to: <ids and codes>

Label a decision when you write it: `| applies-to:` names the ROW, RULE or
REQ ids, the screen codes (the part before `/` of an INVENTORY marker) or
the DIF ids it bears on — a brief quotes it where its label applies. Use
`| scope: project` instead only when it bears on many areas.

The `enforced:` ref must exist today — a named ledger test must be a real
file, and "future/planned/TBD" is rejected at commit. Write the test first.
Add `| origin: proposal` when the choice is a model default the owner never saw.

**State-machine landing law (§6.1).** A lifecycle field (publication
status, alert lifecycle, consent) lands as a declared transition table in
a state-machine rule row — `rule | RULE-NNN | state-machine <field>: …` —
whose census command enumerates every site that mutates or guard-reads the
field. Introducing or extending a lifecycle is a law commit (the row),
then the code; a mutation outside the declared table fails the census
naming the site.

**Data-semantics landing law (§6.3).** A choice about what a stored value
MEANS — "stored lowercase", "minor units", "never moves backward" — lands
as a constraint or a test, never prose only. These under-fire the decision
trigger because the model does not experience them as choices; the landing
spot is mechanical (a constraint in the schema, or a ledger test), with the
D-entry citing it.

## Ledger and docs laws

- tests/invariants/ is the ledger: tests keyed to REQ IDs in their names,
  behavior-keyed through public surfaces only — never implementation-keyed.
  **Two tiers (v0.8.1d):** tests/scaffolding/ is the builder's non-law
  tier — implementation-keyed instruments, never cited by a row, never
  evidence, outside the coverage join, proved-red and the deletion
  tripwire, deletable without a law commit, never run by the gate.
  Behavior-keying is a court: a tests/invariants/test* file may import a
  seam-table module only when that module's Dependents column names
  tests/invariants (the harness entry declares it; internals do not) —
  checks/imports.sh rejects the rest. Dataset and fixture generators live
  under tests/, where the same court sees them.
- Invariant tests exercise behavior, never text: a ledger test must not read
  application source files as strings (no read_text()/grep against source or
  styles). A test that string-matches source is a facade — the grading engine
  flags it as a finding.
- Fixture law: ledger-test fixtures create their state through the same
  public paths production uses (views, services, API calls) — never model/ORM
  shortcuts with hand-set flags. Hand-set fixture state inherits the author's
  blind spots and grades PASS on broken products.
- The ledger runs ONLY via `sh checks/test.sh` (Docker). It must be green at
  every commit — a discipline this skill-set enforces, stated plainly: the
  hook gate runs the courts and the census, NOT the Docker ledger (per-commit
  Docker is the wrong cost); green is verified mechanically at slice close
  and by the --strict joins.
- tests/invariants/ and checks/ are protected paths. Commits touching them
  require `VID_ROLE=fix`, which is legitimate only when the change is an
  ADDITION backed by owner law — a PRD Fail-if, an owner answer, or an
  owner-accepted /vid fix correction. Deleting or weakening an existing
  ledger assertion is a LAW CHANGE (see the law-change rule): hook-enforced
  standalone commit whose Decisions: trailer states what it admits, and it
  must trace to an owner answer — if a test seems wrong, that is a product
  question; ask the owner first. Neutering by ADDITION is the same law
  change: an added skip/xfail marker over a row-bound test routes through
  the standalone rule, and a skipped row-bound test never counts as green.
- A row's test is evidence only after it has been seen to fail: rows carry
  `proved-red: <commit-sha>` (init stamps materialised rows; a later test
  records the parent commit where it was red). A cited test with no
  proved-red has `owed` standing in the coverage join. The stamp is joined
  at every commit — the sha resolves, the cited file exists at it and
  names the row there — and cited paths resolve against the commit under
  construction (index, then HEAD), never the working tree. The rhythm is
  numbered: (1) the test, a free ledger addition, observed red; (2) the
  row citing it, a standalone law commit stamped with the parent; (3) the
  code that turns it green.
- **The builder never writes a ledger test (v0.9.2 3.1, R1).** A file
  under tests/invariants/ is created only by a test-author pass
  (vid-test-inventory `passes/test-author.md`) from the rows, committed
  unchanged by the caller; the builder never creates, edits or deletes one
  — it makes a test green, and a test that seems wrong is a product
  question. Every commit that ADDS a file under tests/invariants/ carries
  `Tests-by: test-author <date> <batch>` (checks/hooks/commit-msg refuses
  it otherwise; `init` and `builder` are never values). The surface
  instrument — a ledger test file per screen, each row with its pins
  hook, all through the one measure module — is that pass's product too;
  a surface test or a hook written by the builder is a defect. A new test
  file holds one row, or up to 5 related rows (v0.9.8.1 R18).
- **What the courts prove, stated so no report overstates it (v0.9.2
  3.12).** A `passed` case in the receipt (`.vid/ledger-results/<sha>.full.xml`,
  read through checks/extractors/results.sh) proves that case ran and
  passed at that tree — nothing more: it does not prove the assertion
  establishes the row; that is the verdict pass's and the grade's
  judgment, asked with two sentences — *name the plausible wrong behaviour
  at this test's boundary that the test would not catch; an assertion
  that was already true before the action is not evidence the action
  worked.* A `Tests-by:` trailer proves a declaration; the separation it
  declares is the pass file's separate-agent spawn. The rows headline
  (`rows: kept K · unverdicted U · breached B · red R · owed O ·
  deploy-owed D`) counts rows, never tests, and is never a proportion;
  `kept` is a verdict, `passed` is a run. And (v0.9.3 3.16): the brief
  court proves a brief was well-formed when checked and that a verdict
  named it, not that the spawn carried nothing else — independence stays
  the pass file's spawn rule; the deployed-shape pass proves the declared
  processes consume what the product routes in the harness, not on the
  platform, whose half is deploy-owed; the topology census proves the
  declarations join, not that a consumer keeps up; the observer proves a
  run was seen, not that it progressed well.
- A fix scopes to the HARM CLASS, never the named instance: before
  scoping, enumerate the adjacent reachable paths to the same forbidden
  effect — other causes, sibling modes, other entry points — and the
  dual-written row's Fail-if names the harm ("no feed shape that parses to
  zero records expires inventory"), never the mechanism ("the expiry guard
  exists"). Fixes stop at the boundary of the sentence that described
  them unless the sentence is the harm.
- Every new source file opens with a comment stating `Purpose:` (one line,
  what the file is for) within its first 15 lines. Hook-enforced.
- A seam change is a law change: ARCHITECTURE.md changes in its own
  standalone commit, BEFORE the code that needs it — the import court
  enforces the order at the code commit.
- Claims stop at evidence: a REQ is "done" only when `sh checks/coverage.sh`
  shows its full trail — citing code comment + ledger test + reachable
  surface. Never report done without it.
- **Report from where the owner sits.** A fix is never reported as working on
  the basis of a status code, a passing test, or a check in a browser the
  owner does not use. Every completion claim states its evidence class —
  ledger test, browser-class test (WebKit/Chromium), coverage join — or
  declares itself unverified. For anything the browser class covers, the
  browser result IS the claim.
- **Process claims are under the same law (§8.2).** A claim about the run
  itself — "still running", "in the corpus module", "nearly done" — resolves
  to an observation (a last test id, a last commit sha, an active-query age,
  a container state) or declares itself unverified. Elapsed time is never
  evidence of progress.

## Inventory law (when INVENTORY.md exists)

INVENTORY.md is the ratified Test Inventory — the owner ratified its rows
before any code existed, and development is "make the ledger green" against
them. checks/inventory.sh runs at every commit:

- A new route with no inventory row fails the commit. Additions are
  permitted, never silent — and the row is a law change (standalone
  commit), so the rhythm is: test (free ledger addition), then row
  (law commit citing it, stamped proved-red with the parent sha), then the
  code that turns it green.
- Rows still `owed`, unproved tests (no `proved-red`), orphan surfaces (a
  built route no app source links to), and promissory test refs block
  completion (`--strict`, part of the coverage join).
- Never delete or weaken a row; a row that seems wrong is a product question.
- The route table is read from the generated, ratified
  `checks/extractors/routes.sh` — the plugin ships no framework parser.
- **A Tier-0 protection is attempted, not read.** Every Tier-0 rule carries
  one hostility sibling row that commits the forbidden thing against the
  running app through its real public surface, and that probe counts as
  evidence only after it has been watched FAILING with the protection
  disabled by the row's own `disable:` toggle and passing with it restored.
  "Refused" is equally green when the attempt never reached the guard. A
  cited probe with no `proved-red`, a missing or `none` toggle, and a probe
  that is the sibling of nothing all fail the commit; a Tier-0 rule owing a
  sibling blocks completion. The toggle is a local, reversible mutation —
  a guard with a runtime kill-switch in shipped code is not a guard.
- Before any red is read as evidence, the runner is proven able to go red:
  invoke it with a selector naming a test that does not exist. Runners
  commonly exit 0 on a selection matching nothing, and a test wired that way
  is a green that can never go red — worse than no test at all.

## Census law (when checks/census.sh is installed)

checks/census.sh runs at every commit: it enumerates populations
(extractors in checks/extractors/ + rule rows in INVENTORY.md), joins two
sides, and fails on any orphan without a ratified exception row. It counts
and joins; it never judges.

- The orphan list is the builder's to-do. An orphan whose partner row is
  still `owed` reports `pending`, never fails (debt-aware).
- An **exception** row says the rule does not apply to this subject — it
  counts toward the complexity law's ceremony threshold. A **suppression**
  row says the rule applies but the extractor cannot yet see the site — it
  never counts toward deletion and stands as a printed to-do against the
  extractor.
- A **difference** row is the only legal way for a knob to differ between
  test and prod; the census prints the divergence table every run — what
  the green ledger did NOT validate.
- A rule row's census command is its denominator and is itself law: a weak
  search silently narrows a rule, and graders carry a standing instruction
  to attack denominators. Zero-denominator guard: an empty population is a
  failure, never a pass.

## The reality-before-compounding bias (§2)

Before substantial work depends on a consequential assumption, prefer
confronting that assumption with evidence **independent of the assumption
itself** and **representative of what it claims about** — especially where
being wrong would cause broad or costly rework. Strong planning advice,
not a fixed rule: balance it against the other considerations that make
the overall plan effective, and depart from it when the trade-offs
justify doing so. The two qualifying clauses are load-bearing:
"independent" forbids validating an assumption with evidence built on it
(the shared-imagination class — tests and code from the same guess);
"representative" forbids tidy stand-ins for messy reality (the
templated-corpus class). The provider-seam rows (§3) are this bias's
enforced special case, where the assumption is about an external service.

## The complexity law

A new mechanism ships as a row class or an extractor, or it receives
law-change scrutiny. Every court earns its place by a counted failure and
keeps it the same way: a check that fires nothing across two runs, or whose
exception list exceeds ~15–20% of its population, is ceremony and is
deleted. Suppressions never count toward that threshold — an exception is
the rule's problem, a suppression the extractor's.

## Import law

The seam table's public-surface and dependents columns are executed by
checks/imports.sh at every commit: a module is entered only through its
declared import specifier, only by its declared dependents; relative imports
across module paths are always violations. The dependents column is the
blast-radius map — a fix in module X re-grades X plus its declared
dependents, not the whole product.

## Law-change rule (law, §4.1 — subsumes court governance)

The courts read their rules from session-writable files; the list lives in
checks/lawfiles. A commit that touches any `vid-*` machine block, any file
in checks/, or that deletes or weakens a ledger assertion, **may touch
nothing else** — hook-enforced, regardless of VID_ROLE. Adding rows, seams,
tests and assertions is free and never silent; changing what the law admits
is a standalone, owner-visible act whose Decisions: trailer states what it
admits and why. The ordering follows: law first (row, seam, rule), then the
code that needs it, in its own commit. Every law-change commit re-runs the
court self-tests (checks/selftest/run.sh) — touch the law, prove the judge
still convicts; a court whose known-bad fixture passes is a build failure.
A change to checks/ additionally requires `VID_ROLE=fix` tracing to owner
law — a PRD append, an owner answer, or an owner-accepted correction, named
in the commit message; the grading engine flags any court edit without one,
and /vid grade reports every law change since the last grade. The examiner
never marks its own paper: a court is never widened in the same commit as
the work it gates — now mechanically impossible, not merely forbidden.

## Verdict-pass doctrine (develop, per slice)

At slice close, after the ledger runs green, one fresh grader verdicts
every row the slice claims paid (the red→green flip set) against its
ratified Fail-if: KEPT / BREACHED / ROW-AMBIGUOUS. Rows are ratified law,
so BREACHED is "not done," not a finding needing adjudication — the pass is
internal; the owner sees nothing new. Three bounds terminate it: (1) the
grader answers only its rows' Fail-ifs — anything else files to the
end-grade queue and cannot block the slice; (2) after a fix, only rows in
the fix's blast radius are re-verdicted, and the breached set must strictly
shrink or the loop halts and escalates; (3) the attempt bound, computed
from the verdict events and never written by the session — vid-develop's
rule (v0.9.3 3.6): a row past it stays materialised, is held out of the
automatic claim and waits for the owner; no reversion commit. A slice ends
kept or honestly in debt — never silently wrong.

## The run's records (v0.9.3 3.8, 3.9, 3.12; R12, R13, R16)

`.vid/RUN-STATE.md` is law as a RECORD, not an obligation: it must exist
from develop's start and carry its keys (`run:` — `active`, `waiting`,
`stopped <reason>` or `complete` — `session:`, `questions:`, `slice:`,
`modules:`, `claims:`, `receipt:`/`briefs:`, `held:`; v0.9.5 3.2),
rewritten at every slice open and close, every handoff and the completion
report; the plan written in it is the agent's own and nobody approves it.
Open product questions are one `Q<n>` line each in its "Open product
questions" section. A session ends its turn only with its reason recorded
— `run: waiting`, `run: stopped <reason>`, or completion computed. An
observer outside the session (`checks/observe.sh`, the loop develop
starts) reads these records, the heartbeat, the events and the declared
operations, probes an overdue operation, and records a notice for the
owner in the heartbeat (nothing is sent) when a question waits, the run waits or stops, dies, or goes quiet without a
recorded reason; it nudges (`.vid/NUDGE`) only for a declared operation
that fails its probe, and never repairs anything or makes the session
continue. A nudge is answered with an observation — `sh
checks/watchdog.sh claim run --evidence '<what you observed>'`. A session
that takes over a run resumes from these records — `sh checks/observe.sh
resume` — never from a wedged session's transcript.

## Promotion (between runs)

At run end the owner marks which of the run's new rule rows, checklist
lines and extractors are general — domain-level or universal. Promoted
items join the plugin's seed library (seed/), pre-loaded for ratification
at the next init. A seeded item that fires nothing across two runs is
dropped — the complexity law, applied symmetrically.

## Design law (when design/ exists)

design/ is the second half of the spec, ratified by the owner in a
/vid design sitting: PRD.md says what the product DOES; design/ says what
it IS — the source of truth for the visible surface.

- **Transcription law.** Every CSS rule in the app derives from a cited
  canvas section, property-for-property; the only permitted substitution is
  hex→token. **No invented visual values**: a color, radius, spacing, or
  type value that exists in neither the canvases nor design/tokens.css does
  not exist in the app. Small judgment deltas (an added `gap`,
  `height`→`min-height`) are develop's to make and grade's to judge — the
  law is traceability, the grader is the fidelity check.
- Citations are **sub-screen, marker unit** — never the filename. Every rule
  block sits under a comment citing its marker
  (`/* Result cards (P02/populated — REQ-030) */`); markup wears the
  transcribed classes AND, for a state, every element identifier its
  canvas section carries (`data-element="<role>"`, v0.9.2 3.4, R20) on
  the element that plays that role, inside the marker's section — the
  identifiers are what the surface instrument measures, every property
  the canvas declares on the element, so an identifier the page lacks is
  a failing case (`missing element`), never a deferral; templates/
  components cite their markers
  (`Design: design/screens/<file> (P02/populated …)`). checks/design-cite.sh
  enforces the rule-block side at every commit; checks/coverage.sh joins
  every pack marker to a citation — an uncited marker is a gap.
- design/tokens.css is extracted VERBATIM at ratification and carries its
  provenance header. Colors enter the product only through it: app source
  references tokens, and conformance rejects new raw hex outside design/.
  design/ itself is imported verbatim from the owner — exempt from the hex
  court and from Purpose: headers; it is spec, not source.
- design/ is a protected path (VID_ROLE=fix) with ledger standing, and the
  standing is mechanical: MODIFYING or DELETING anything under design/ is a
  law change (standalone commit, hook-enforced); additions are free — the
  ratification import stays one law commit. A visual correction lands as
  the design law commit first (its Decisions: trailer naming the owner
  correction), immediately followed by the code commit citing the same
  markers — adjacent, so the two never diverge beyond one commit.
- The design binds the builder and never absolves it: a designed screen is
  spec, not evidence. Built-vs-designed divergence, and screens existing
  only in design/, are grader findings.
- A discovered PRD/design contradiction is a product question — ask
  immediately, never pick a winner silently.

## Deploy law

A row born `owed: paid by /vid deploy gate N — …` is paid only by that
rung's evidence and stamped `paid-at:` by /vid deploy — never a sandbox test
that claims to prove a deploy-owed row: no test-runner-triggered proof of a
schedule's consumption, no harness-constant proof of an edge setting. Its
in-repo half is ordinary pilot work, counted by coverage like any row.
Deploys happen only via /vid deploy — never from a session's own initiative,
a schedule, or another verb. When DEPLOYMENT.md exists it is law, same
standing as this file. The prod cutover belongs to the owner: one-touch
confirmation, every deploy. Secret values never appear in the repo or in a
session — names and locations only.

## Spec-append precedence

The PRD base is immutable after init. All change is append. Later appends win.
Consolidation is a scheduled event, not a rescue — the only maintenance
operation in this method: after the init sitting (before the initial commit)
and after every grade adjudication (after the last fix batch, before the final
report), the PRD is re-ratified as its effective content. 7a is the mechanical
copy, `sh checks/prd-consolidate.sh` — the seed to SEED.md, the effective rows
and rulings, history to PRD-HISTORY-<date>.md, the arm ledger under .vid/ —
refusing to write unless checks/prd.sh passes on its output; 7b is the
whole-set review over the consolidated file, proposing semantic repairs as
its own append; the owner ratifies both as two commits after one row-set-diff
sitting. Never during develop's slices; never at add. PRD-HISTORY-*.md and
SEED.md are the archive: verbatim, and invisible to the live-question census.

## Commit template (hook-enforced: the Decisions line is mandatory)

    <summary>

    REQs: <ids touched, or "none">
    Decisions: <D-NNN entries added, or "none — nothing surprising">
    Seams: <ARCHITECTURE.md rows changed, or "none">
    Model: <the model id doing the work, e.g. claude-fable-5>

The Model trailer is mandatory in /vid develop and /vid fix commits (§9
model-change durability): a later model sees what it inherits, and a spike
in fix-injection can be correlated with a handover rather than guessed at.
DECISIONS.md entries may carry an optional `| model: <id>` field for the
same reason.
