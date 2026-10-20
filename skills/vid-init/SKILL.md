---
name: vid-init
description: Start a ViD project in an empty directory — delegate product elicitation to the vid-create-prd skill (run inline as init's first act, its materiality-tested interview and three ratification pauses produce the enriched PRD.md) or adopt a PRD that skill already ratified, interview the owner for the technical foundation, generate BASELINE/DECISIONS/ARCHITECTURE/CLAUDE.md, run the design chain when the product has a face, ratify the Test Inventory and materialise it as failing ledger tests, scaffold the stack, install the hook courts and the Docker test harness, make the initial commit. Use when the owner says "vid init", "start a vid project", or wants to begin a new product under ViD.
---

# /vid init

You are setting up a ViD project for an owner who is a world-class product
expert and may know nothing about code. Run once, in an empty (or nearly
empty) directory. If the directory already contains a ViD project (a CLAUDE.md
with a ```vid-placement block), stop and point the owner at /vid add or /vid fix.

Init is the AUTHORITY PHASE. Everything the owner ratifies here is frozen
baseline; everything after is "make the ledger green". Three ratifications,
in order:

    product elicitation → /vid create-prd, run inline
      (its interview batch, three pauses, three
      commits) → the enriched PRD.md — or a PRD it
      already ratified, adopted                       ← ratification 1
    technical foundation (init's own channel) →
      BASELINE / ARCHITECTURE / DECISIONS / CLAUDE.md
    design brief (+ manifest) → owner authors →
      import reconciliation (fail-closed) → design/  ← ratification 2 (when the product has a face)
    Test Inventory rows (incl. genus rows and the
      census row classes) → owner ratifies →
      materialised as failing ledger tests           ← ratification 3
    the stage cut → /vid stage, run inline; one
      sitting: the owner ratifies the cards, changes
      them, or keeps a single stage (v0.26.10.5)      ← the stage sitting

Before anything else, read the plugin's seed library
(`${CLAUDE_PLUGIN_ROOT}/seed/`): rules.md and checklist.md are promoted
knowledge from prior runs — empty on a fresh install — pre-loaded as
proposals for the genus step and the grading checklist below;
seed/extractors/README.md is the extractor contract every generated
extractor must meet.

This plugin ships everything you need:

- `${CLAUDE_PLUGIN_ROOT}/templates/` — artifact skeletons ({{PLACEHOLDERS}} to fill)
- `${CLAUDE_PLUGIN_ROOT}/checks/` — the hook courts and scripts, copied verbatim
- `${CLAUDE_PLUGIN_ROOT}/seed/` — the promoted library: genus-row proposals,
  checklist lines, the extractor contract + class catalog (nothing installed
  verbatim; everything passes through ratification)

Throughout: narrate position briefly before each step ("interview done;
scaffolding the stack next") — visibility, never approval-seeking. Internal
issues (doc consistency, template friction, naming) are yours to sort out
autonomously; log the surprising ones to DECISIONS.md. Report "blocked" only
for the genuinely impossible (no git, no Docker AND the owner wants tests run,
no network for toolchain install) — say plainly what is missing and finish
everything that is still possible.

**Init's stage event comes first (v0.9.5 3.11, R11; RECORDS.md).** Before
step 1 record
`sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" "stage name=init state=start session=$CLAUDE_CODE_SESSION_ID records=1"`
— the plugin's copy of the helper, since checks/ is copied only at step 6;
it creates `.vid/`, which is how create-prd, design and test-inventory,
run inside init, know they are in a ViD project and record their own
stages. At the hand-back (step 8) record `state=end` in the same form.

**ViD's own defects (v0.26.10.3 R12, R13).** When a ViD check, hook,
skill or agent role misbehaves — it refuses legitimate work, crashes,
contradicts itself or its documentation, or gives a wrong count — or when
you use a workaround around one, append an entry to `.vid/VID-FINDINGS.md`
in the form of `${CLAUDE_PLUGIN_ROOT}/templates/VID-FINDINGS.md` (the file
is created from it at the first entry; entries are numbered in the file),
record `sh checks/event.sh 'vid-finding n=<n> area=check|hook|skill|agent file=<ViD
path>'`, and tell the owner in one line (before step 6 copies checks/, the plugin's
`sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh"`). A defect in the product being
built is not a ViD finding.

## 1. Product elicitation — delegated to /vid create-prd (the two-channel split)

Two channels, two owners. **Product elicitation** — what the product is,
for whom, the behaviors that make it real, what must never break or leak,
what is deliberately out, what wrong costs — belongs to the vid-create-prd
skill (`${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/SKILL.md`). Run it
now, inline, as init's first act: read that skill and follow it whole —
its materiality-tested interview batch (with the scope challenge), the
contract panel, the thesis and its red-team, item authoring under the
falsifier mandate, the completeness audit, the whole-set review, and its
**three ratification pauses, each ending in a commit**. The skill runs
`git init` when no repository exists (it announces it); inside init that
repository IS the project's — the three ratification commits are the
project's first history, and the skill's court gate
(`sh ${CLAUDE_PLUGIN_ROOT}/checks/prd.sh --pause PRD.md`) runs before each. Do
not shortcut, summarise, or re-ask: everything the skill's chain asks is
the product interview, and everything it settles is settled. When its
pause-3 hand-back arrives, continue here.

**Technical foundation** — design direction, architecture, stack — is
init's channel and never the skill's (that verb asks product questions
only). It is asked in step 1b, after the PRD is ratified.

**Adoption — a PRD ratified before init.** If the directory already holds
a `PRD.md` in the enriched grammar (a ```vid-prd block) whose
`## Ratifications` section carries a `final` line — a standalone
/vid create-prd run, the file carrying its seed, ledger, contract,
findings, and ratification shas — adopt it instead of delegating:

- run `sh ${CLAUDE_PLUGIN_ROOT}/checks/prd.sh PRD.md`; a conviction stops
  init naming the gaps — the owner repairs by append or re-runs the verb;
  init never edits a ratified base;
- `git init` if the directory is not a repository, and commit the file
  as it is — summary "adopt PRD.md ratified by /vid create-prd", body
  naming the court result and the three Ratifications lines verbatim
  (their shas name the standalone repository's commits; they are carried,
  not resolved here — the receiving repo's first commit of the file
  re-anchors the law); a file already committed here (the standalone run
  happened in place) needs no new commit;
- skip delegation entirely, and **never re-interview what the document
  settles**: its ledger, thesis, contract, and items are ratified.
  Product questions init hits later go to the owner freely as always and
  land as typed-row appends.

A pre-enrichment `PRD.md` (no ```vid-prd block) is not adoptable: it is a
document the owner can hand to the skill through its import door (seed
role) — say so, then delegate.

## 1b. Technical foundation — init's own channel

With the PRD ratified or adopted, ask the technical-foundation questions —
the two optional hint questions below are the whole list. Where the
owner skips one or says "you pick", choose a sensible default and log it
with `| origin: proposal` in DECISIONS.md when that file is generated in
step 2.

Always ask the two optional hint questions, verbatim:

1. **"Any directional hints on design?"** — prose is recorded verbatim in
   BASELINE.md's Owner hints. An ask for a real design pass → run
   /vid design (see the vid-design skill) after the artifacts exist: it
   derives the brief with its manifest, the owner authors, and the import
   court reconciles what comes back. /vid design asks whether you design
   from its brief in your own tool or ViD drafts it here; it only offers the
   second when it can see its own drawings. Promise nothing beyond that.
2. **"Any directional hints on architecture and technical stack?"** — accept
   ANY altitude, from "it's a website" or "it's a mobile app" to a full stack
   prescription. Record whatever is said verbatim in BASELINE.md's Owner
   hints section. Skipped → you choose the stack and log it
   (`origin: proposal`). When you choose: convention-heavy frameworks are a
   **scaling decision, not a taste preference** — a field run that hand-rolled
   framework equivalents spent 798 lines per requirement against 219 with
   framework leverage. Say so when recommending.

**Where it runs (v0.26.10.8 R4).** With hint 2, for every project, invoke
the `vid-staging-setup` skill's Part 1 (the Skill tool): where the product
runs, the staging and production addresses, the sending address, the
spend cap, how ViD gets access (a log-in or a variable's name, never a
value), the outside services' accounts and which go live on staging, and
the downtime tolerance; it checks the platform against BASELINE and writes
its DECISIONS entry. Its answers go only into ARCHITECTURE.md's
```vid-hosting block and DECISIONS, never verbatim into BASELINE's Owner
hints — a hosting answer given inside hint 2 goes there, not into the
hints. They are recorded when ARCHITECTURE.md is generated (step 2).

**Scale warning (state it when it applies, never refuse).** Only for a PRD
under a grammar before 0.9.4, whose pause 2 did not size it: past ~2 grader
batches (~60 demand items — the court's `demand=` count), say plainly that
cross-cutting ownership degrades first at this size.

Product questions stay free and immediate at every later step — the
skill's batch was for critical mass, not a quota; an answer that arrives
later lands as a typed-row append under `## Appends`.

## 2. Generate the artifacts

Fill every template; no placeholder survives. Specifics that matter:

- **PRD.md** — RECEIVED, never generated here: the artifact of step 1
  (delegated or adopted), already in the enriched grammar — stable REQ
  ids, one `fail-if:` per demand item, tiers, typed non-goals (`NG-`
  rows), the ratified content contract, the answer ledger, and open
  decisions as `VID-QUESTION: (OQ-n)` carriers (they block "done" —
  checks/coverage.sh counts them; resolving one rewrites its line
  `RESOLVED: (OQ-n) A-NNN — …` in the same commit as the answer and the
  amendment). Init adds nothing to the base and
  edits nothing above `## Appends`; a product decision init makes later
  (a design read-back, a lifecycle ruling at ratification 3) lands as a
  typed row append in the fix/add grammar.
- **BASELINE.md** — stack table where FORBIDDEN alternatives are NAMED (the
  plausible things a future session might reach for instead: the competing
  framework, ORM, database — not vague categories). Tier-0 rows matching
  every T0 item — demand rows and `invariant` rows alike. Machine blocks:
  - `vid-allowed-extensions`: every extension the scaffold legitimately uses,
    including `.md .yml .sh` and the config formats (`.toml`/`.json`/`.lock` as
    applicable) — the initial commit itself must pass conformance.
  - `vid-forbidden`: dependency/import tokens that must never appear in staged
    source additions. Pick tokens that will not legitimately occur otherwise
    (e.g. `sqlalchemy`, not `sql`).
- **DECISIONS.md** — seed with the real decisions made so far: stack choice,
  storage, hosting posture, anything from skipped hints. Every entry carries
  `| enforced:` and a label — `| applies-to: <ids and codes>`, or `| scope:
  project` only when it bears on many areas (both hook-rejected otherwise;
  a line written before the inventory exists is labelled in step 7's pass).
- **ARCHITECTURE.md** — a seam row per initial module, following the
  template's **column contract exactly**. The architecture step also
  enumerates every EXTERNAL boundary — each service on the other side of
  the network (payments, mail, feeds, search, auth, storage) becomes a
  provider seam row in INVENTORY.md at ratification 3, born
  `probe: owed` (§3.2 door 1), naming the module that talks to it
  (`| module: <module id>`). An external boundary without a seam row
  cannot be ratified. Column contract: Module is the repo path, Public
  surface leads with the backticked import specifier, Dependents is the
  comma-separated allow list. This table is executed — checks/imports.sh
  reads it at every commit — so an entry point per module, never one barrel
  for the world. Keep `Import court: enforce` (greenfield projects start
  enforced; report-only is for retrofits). The ```vid-hosting block
  (`vid-staging-setup` Part 1's answers, above) goes in its "Where it runs"
  section — never a credential; the pre-commit hook refuses any access
  shape but `cli-login <platform>`, `env <NAME>` or `none`.
- **CLAUDE.md** — from `templates/CLAUDE.project.md`: 3-line project summary,
  placement prose ("new X goes in Y") plus a `vid-placement` block that
  matches the scaffold exactly.
- **README.md** — what it is, how to run, how to test (`sh checks/test.sh`),
  the preview command (§6: the one product service from the one compose
  file), and the go-live sticky note from `templates/README.golive.md`
  verbatim.

## 3. The design chain (when the product has a face)

If the product has a visual surface and the owner wants it designed (the
hint question, or their own ask), run /vid design now — the PRD exists, so
the brief can be derived. That verb owns the whole chain: brief + manifest →
owner authors → `sh checks/design-join.sh` fail-closed reconciliation →
ratification into design/. Init waits for it because the inventory's surface
rows are the join's resolved output.

No visual surface, or the owner defers design → skip; the inventory derives
from the PRD and routes alone, and /vid design can run later (its import
reconciliation will then extend the inventory).

## 4. The Test Inventory — ratification 3, then materialisation (delegated to /vid test-inventory)

The Test Inventory is owned by the vid-test-inventory skill
(`${CLAUDE_PLUGIN_ROOT}/skills/vid-test-inventory/SKILL.md`) — the whole
test contract, every test the project will ever have, routed by what can
run it. Run it now, inline, in **init mode, call point 1**: read that
skill and follow it whole — the derivation from the three enumerable
sets and the enumeration joins, the genus deliberation through
fresh-context lenses, the counterexample-challenge lens, the governance
rows (rule, difference, exception, suppression, seam, hostility, the
control siblings, the golden sets), and the ratification sitting — with
the grading checklist created from `templates/GRADING-CHECKLIST.md` in
the same sitting. Do not shortcut, summarise, or re-derive: what that
skill derives is the inventory, and what the owner ratifies there is
ratification 3. When its hand-back arrives, continue at step 5. **The
materialisation of every expressible row as a FAILING ledger test is
that skill's §6 and runs at call point 2** (v0.9.2 3.3): the test-author
passes need the harness contract and the route table step 6 installs, so
materialisation is call point 2's first act, at step 7 below, before the
gate — the one ordering change of v0.9.2; what the owner sees is
unchanged. The red gate is the same call point's §7, after the scaffold,
the courts, the harness and the materialised ledger exist.

What init supplies to the skill, in place: the ratified PRD (step 1), the
resolved design join when a design exists (step 3), the seed library, the
external boundaries the architecture step declared (step 2 — an external
boundary without a seam row cannot be ratified), and — once step 6 has
generated it — the ratified routes extractor; route rows the derivation
could not see before then arrive when it does. Report the ledger
honestly: **red, green 0 / N** is the correct state at the end of init —
and the red gate (step 7) enforces it.

## 5. Scaffold the stack

The repo must BE the architecture before anything else runs — models conform
to surrounding code; this is what prevents stack invention.

- toolchain + lockfile, committed
- the directory shape from the placement block, real (a module skeleton per
  seam row, not empty gestures)
- ONE example route/module/screen on the golden path, fully wired end to end,
  with a `Purpose:` header and a comment citing the REQ it serves — and its
  inventory row, since the route table is court-read from here on. Wired
  so the scaffold is real, not so the REQ is met: the route renders a
  placeholder, never the behavior the REQ demands
- seed the ledger: at least one test in tests/invariants/ keyed to that REQ's
  ID, derived from its Fail-if, through the public surface only — it
  asserts the Fail-if, which the placeholder route does not satisfy, so
  it is red at the gate (step 7). An example whose test is born green has
  built the requirement, not the scaffold; the red gate catches it by name

## 6. Install the enforcement

- copy `${CLAUDE_PLUGIN_ROOT}/checks/` → `./checks/` (both hooks, placement,
  conformance, coverage, imports, inventory, census, seams, design-join,
  design-cite, prd — the enriched-PRD court, presence-gated, green on the
  ratified PRD from step 1 before the initial commit — metrics, watchdog,
  test runner, lawfiles, the event helper `event.sh` and
  `records-version` — the record contract this checks/ writes, RECORDS.md
  version 1 (v0.9.5 3.10) — selftest/ with its fixtures: the whole
  directory, verbatim), then
  `chmod +x checks/*.sh checks/hooks/* checks/selftest/run.sh checks/selftest/cases/*.sh`
- **Generate the extractors from the scaffold** — the plugin ships none;
  the contract and class catalog are in `seed/extractors/README.md`:
  - `checks/extractors/routes.sh` — REQUIRED: the route table for this
    stack's routing convention (`ok <route>` lines, in the literal form the
    inventory rows use). The inventory court reads it at every commit.
  - `checks/extractors/results.sh` — REQUIRED (v0.9.2 3.6, R9): the
    results reader — the runner's per-case report, written through the
    flag the harness contract names, normalised into `case <path>::<name>
    <passed|failed|skipped|error> <seconds>` lines; the receipt courts
    (checks/coverage.sh --strict, checks/metrics.sh) read only those. The
    contract is in seed/extractors/README.md; its selftest case: a report
    with one case of each status comes back as four lines.
  - one extractor per census class the scaffold supports — dead-path,
    divergence, reachability — each ~10–30 lines; needing more means the
    class is wrong for this stack: redesign or drop, never grow. The
    **collected-fields dead-path instance is mandatory**
    (`checks/extractors/dead-path.collected-fields.sh`: every field the
    product collects from a user and stores, joined to a read site other
    than validation and display — the vid-test-inventory skill's shape 9),
    and so is the **topology instance** (v0.9.3 3.4,
    `checks/extractors/dead-path.topology.sh`: every task-to-queue routing
    and every schedule the scaffold declares, joined to a declared process
    in the harness contract or a registered task; `inactive` until the
    first routing or schedule exists — a class extractor, never a rule
    row; contract in seed/extractors/README.md).
  - the **memory reader** `checks/extractors/memory.sh` (v0.9.3 3.9) when
    the host exposes free memory: one line, `free-mb <n>`, or `inactive
    <reason>` — the observer reports it, never enforces it.
  - the report-only vacuity extractor, realized for the ledger's own
    harness from the five law shapes (or-constant, literal-vs-literal,
    bare catch-all raises, status-span, skip-on-condition) **rebuilt from
    the measured classes** the vid-test-inventory skill names (§6 there:
    success-span with no error code, presence-only assertions keyed to
    static wrappers, substring filters matching nothing, zero-population
    loops, the placeholderless format string in an assertion, the circular
    fixture by its `Provenance:` header).
  - the report-only **strength** extractor (`checks/extractors/strength.<name>.sh`):
    each row-bound test's assertions classified on the ladder Existence →
    Type → Status → Value → Behavioral; an orphan is a Tier-0 row whose
    strongest assertion is Existence. **The grain is the function** (v0.9.2
    3.9a): the row-bound test is the function whose name or docstring
    names the row id, the scan scoped to it; a row whose cited file holds
    no such function is `unbound-row`; the selftest case plants the
    file-grain miss (the contract in seed/extractors/README.md). Report-only
    under the promote-or-delete gate, like vacuity.
  - the report-only RENDERED extractor (§9), when a ratified design/
    exists: canvas-pinned load-bearing properties (the paint-integrity
    set + identity colors — the owner-ruled scope in
    seed/extractors/README.md) joined against computed values on the
    running page, via the project's own browser harness. It CALLS the
    measure module installed with the harness below and is no second
    comparison (v0.9.2 3.4): it enumerates the routed markers, hands
    each state to the module and prints the module's `differs` lines as
    its orphans. It declares `inactive <reason>` whenever the surface is
    not up and runs at slice close, not per commit; selftest case at
    generation time like the rest.
  - **when the scaffold splits frontend from backend across an API (§6.2
    — derive the split from the scaffold in front of you, never from a
    stack list):** every internal API contract carries PAIRED contract
    tests keyed to the same contract, one on each side of the split, and
    the ARCHITECTURE.md public-surface column of the API module
    references them; frontend test doubles DERIVE from the backend's
    captured actual responses, never typed from memory — we own the
    backend, and capturing is running it. Generate the derivation check
    as an invariant-class extractor (frontend doubles ↔ captured-response
    files) with its selftest case, like every extractor. On a
    server-rendered stack this obligation is ABSENT entirely — no rows,
    no extractor, nothing to satisfy; neither branch ships as stack
    content. Closes the internal edition of test≠prod divergence (v0.5's
    507 green tests over a dead join).
  - a selftest case per generated extractor in `checks/selftest/cases/` —
    a known-bad fixture it must flag (~15 lines, same shape as the shipped
    court cases), planting **mutations beyond the canonical shape**: at
    least one unguarded site in a non-canonical form (a second vocabulary
    for the same guard) and one arm-broken compound command (a syntax
    error in one arm) — the contract in seed/extractors/README.md. Each
    is fixture-only: it builds its own scratch fixture and reads nothing
    else of the project. Unlisted in `checks/selftest/shipped`, it runs at
    every law commit — the hook's self-test memo skips only the cases the
    plugin ships (v0.9.5 3.9).
  The owner ratifies the extractor set at recognition level — extractors
  are law (checks/ is a protected path and every later change is a
  standalone law commit). Then `chmod +x checks/extractors/*.sh`.
- `git init` (if needed), then `git config core.hooksPath checks/hooks` —
  pre-commit, commit-msg and post-commit (v0.9.3 3.7: the amendment
  record) are all installed by it; `chmod +x checks/hooks/*`.
- **`.vid/budget`** (v0.9.3 3.10) — numbers only, the defaults unless the
  owner said otherwise: `stacks=1`, `memory-headroom-mb=<n>` (the observer
  reports it), `claims-per-slice=60`, `wall-hours-per-slice=8`,
  `court-seconds=300`, `builder-context-tokens=400000` (v0.9.7.0.7 3.7:
  the context at which a builder or fixer is told, once, to finish) — each line recorded in DECISIONS.md `origin:
  proposal`. It is not a law path.
- **the observer** (v0.9.3 3.9; v0.9.7.0.9 3.8) — develop starts the
  watcher itself (`sh checks/observe.sh start`, a detached loop tied to the
  run); the owner installs nothing.
- **the project's host settings** (v0.9.7.1 3.8, 3.12) — two plain
  questions, each written only on the owner's yes, into this project's
  `.claude/settings.json` (never the owner's own configuration):
  - may ViD set this project's compaction point to 300,000 tokens, so the
    build's session compacts before its context grows costly?
    (`"autoCompactWindow": 300000`; record `sh checks/event.sh
    'context-window requested=300000'`, or `requested=declined`);
  - `sh checks/brief.sh plugins` names the enabled plugins that are not
    ViD's: may ViD turn them off for this project only, since each one's
    skills reach every session start? (`"enabledPlugins":
    {"<name>@<marketplace>": false}` for each the owner names; a local
    setting or the organisation can still override it). develop's start
    says whether each still reads as enabled.
- **run the self-test**: `sh checks/selftest/run.sh` — the machine proven
  to convict on this stack. Any court or extractor whose known-bad fixture
  passes is a build failure naming it: fix before proceeding.
- **the harness** — create docker-compose.test.yml from the template,
  filled for the stack. The ledger runs ONLY there. What the filled file
  states (v0.9.2 3.6, R21, R9; checks/harness.sh reads it at every
  commit): **one product image** — the product is ONE service built from
  ONE context and ONE target, its static assets collected in that image,
  reached by the tests service only over the network at the service's
  name (the harness client's base URL), never a server bound inside the
  tests process and never a second product image or fixture server; the
  `x-vid-harness` key filled with the product service's name and the
  stack's in-process server shapes as the forbidden tokens (the
  harness.sh selftest plants them); `{{RESULTS_FLAG}}` — the flag THIS
  runner takes to write its per-case report to the results mount, the
  half of the harness contract `checks/extractors/results.sh` reads;
  `${VID_TEST_CONTEXT}:/app:ro` and `${VID_SELECTOR}` left as the
  template has them (checks/test.sh supplies both); **`completed:`, always**
  (v0.9.3 3.3) — the runner's own statuses that mean it ran to its end,
  all passed or some failed, never an interrupt, an internal error, a usage
  error or "nothing collected", which every runner also encodes in its
  exit status (a run with any other status publishes nothing); and, **when
  the scaffold or ARCHITECTURE declares any process beside the web
  process**, the deployed shape: `inline-switch:` (the product setting
  that runs asynchronous work inline), `schedule-fast:` (the setting that
  makes declared schedules fire promptly), `deployed-selector:` (the
  runner's syntax selecting the journey and `(process)` tests),
  `processes:`, the product environment anchor carrying both settings
  from `VID_INLINE` and `VID_SCHEDULE_FAST`, one service per process on
  the product's image reference byte for byte in the `deployed` profile,
  and the transport service. **Four harness rules** (v0.9.7.0.10 3.4,
  R9; rule 4 v0.9.7.0.11 3.2, R2), declared by **`rules: 2`** under
  `x-vid-harness`, which init writes into every new harness: (1) **nothing is installed or
  fetched when a service starts** — its dependencies are built into its
  own image, once (the tests service and any fake may carry their own
  `build:`; the product is still built once), and a service's own update
  check is switched off when the test does not need it; (2) **each service
  is ready before whatever uses it, and nothing waits for a service it
  doesn't use** (v0.9.7.0.10 revision 5) — the product waits only for
  what it needs in order to start, each of those declaring a readiness
  check and the product starting once they are ready; a service the
  product calls only while serving a request, or that only some tests use,
  starts with the stack but nobody waits for it at start: it goes under
  the tests' `depends_on` with `condition: service_started` (a service in
  no `depends_on` would not start at all), the product handles it being
  unavailable, as it must in production, and the tests that exercise it
  wait for it in one shared setup step, written once, that every such test
  goes through; the product declares a readiness check and the tests start
  once it is ready; which services are which is the project's, decided
  here from the scaffold (in an existing project by the upgrade's builder,
  shown in the owner's one question) (a slow
  start must not hide a race, and one slow service must not delay tests
  that never use it); (3) **a test service slow to start because of the
  data it loads may load a test-sized set** (a slow-starting dependency
  too), declared as a `difference` row — the setting, the
  test value, the production value, and why the tests' purpose survives
  it — which the owner approves like any other difference (a scanner, for
  example, proves the product sends every upload to it and acts on clean
  and infected, which its standard test signature shows; recognising real
  threats is the scanner vendor's job); (4) **no one case runs longer
  than `case-limit:` seconds** — init writes `case-limit: 600` (a choice,
  not a measure) and the tests service's `VID_CASE_LIMIT`, which
  checks/test.sh fills from it; the runner stops a case at the limit,
  reports it failed by its name, and goes on to the next case, through
  its own per-case time-limit option in the tests' command
  (`{{CASE_LIMIT_FLAG}}`; a runner without one gets the stack's per-case
  time-limit add-on, built into the tests' image). With `rules: 2`
  checks/harness.sh holds rule 2's readiness declarations and rule 4's
  (the limit a positive integer, the tests service naming
  `VID_CASE_LIMIT`); rules 1 and 3 it cannot check, and the runner's
  stopping is proved by running it.
  The inline switch and the fast-schedule setting derive `difference` rows
  like every knob. Beside it, in the same act:
  - **the harness client** `tests/invariants/harness.*` — the actor
    door (sign in as an actor kind through the product's own form and
    verify the session), the engine door for browser-class rows, the
    fixture builders through public paths (the fixture law), its
    docstrings — this public surface is what every test-author pass
    receives, so it says what it does.
  - **the measure module** `tests/invariants/measure.<ext>` — the ONE
    driver the surface instrument, the rendered extractor and the
    fidelity graders call; the contract is seed/extractors/README.md
    "The measure module" (one navigation per state, one evaluate,
    colours as colours and lengths as computed lengths, the denominator
    rule, its line vocabulary), realised for this stack's browser engine
    and the page conventions this harness contract names (how the
    section root carries its marker, how a console error is read).
  - **the surface instrument** `tests/invariants/<surfaces file>`, a
    file per screen (v0.9.8.1 R18) —
    listed here under the harness because it is the harness's first
    consumer, and NOT written here: it is the surface test-author pass's
    product (`skills/vid-test-inventory/passes/test-author.md`, batch
    `surface`), produced at call point 2 (§7) from the surface rows, the
    canvases and this measure module's contract — never by this session,
    never by the builder (the separate-author rule has no exception; a
    surface test or a pins hook written here is a defect).
  - **the README's preview command** — written by init: the compose
    command bringing up the product service alone from
    docker-compose.test.yml (`… -f docker-compose.test.yml up <product>`)
    and no other file; what the owner previews is what the ledger
    certified, or it is nothing.
  Run `sh checks/test.sh` — it must RUN (exit nonzero is expected: the
  materialised inventory is red until develop; the receipt it writes is
  `.live.` until the initial commit exists). If Docker is absent, that is a
  genuine blocker for running tests: say so plainly, finish everything
  else, and leave the command for the owner.

## 7. The red gate, the initial commit, proved-red (call point 2)

Run the vid-test-inventory skill's §6 and §7 now — **init mode, call
point 2**, verbatim as that skill states them. First §6, materialisation
(v0.9.2 3.3): the test-author passes spawned over every ratified row not
legitimately deferred — behavior batches, the journeys, the shell, and the
surface pass producing the instrument, a file per screen (step 6 listed
it under the harness) — each returned file committed unchanged and observed red; the
builder, and this session, write none of them. Then §7: prove the runner
can go red before reading any red; the par line (`par: rows=R
materialised=N legitimate=K deploy-owed=D other=J`, `J > 0` or `N + K + D
≠ R` fails init); the red gate (`green != 0` fails init, naming the green
rows — a build failure, not a report line); the labelling pass (v0.9.7.3
3.3, R3) over every decision line — step 2's, the later steps' (step 6's
budget lines included) and this step's own — immediately before the
initial commit, from `./checks/`: `sh checks/decisions.sh propose --all`
writes `.vid/briefs/labels-<n>.md`; one general-purpose agent reads it and
returns one line per decision, editing nothing; save the return as
`.vid/decision-labels.proposed`; then
`sh checks/decisions.sh apply --no-commit` — no question to the owner (an unsure label is written
`scope: project`), no commit of its own, the labels land in the initial
commit, where the hook's label rule sees a fully labelled file; the initial commit with the template message under `VID_ROLE=fix` (exempt from the law-change
standalone rule because it IS the ratification act — the hook skips that
rule while HEAD carries no `checks/`; the presence-gated courts, prd.sh
included, run on it):

    VID_ROLE=fix git commit -m "..."

then the proved-red stamp on every row whose test was observed red,
committed alone as a standalone law commit; hostility probes stamped only
by their own ritual, never by the gate. The skill owns the gate; init
owns the moment it runs — after the scaffold, the courts, the extractors
and the harness exist, and before anything else lands.

## 7b. The stage cut (v0.26.10.5 R1, R2)

After the proved-red stamp and before the hand-back, run the vid-stage
skill (`${CLAUDE_PLUGIN_ROOT}/skills/vid-stage/SKILL.md`) inline: it reads
the whole baseline, proposes a cut through its four lenses and presents
one card per stage in one sitting — the owner's last pause at init. The
owner ratifies the cut, changes it, or keeps a single stage (no
STAGES.md). Its hand-back's lines join step 8's.

## 8. Hand back

A few sentences, no ceremony — what was ratified (PRD — the create-prd
hand-back's counts: items by type, non-goals, pending and provisional
with their routing, the provisional sweep surface, open OQs; design if
any; inventory — the test-inventory hand-back's counts: rows by axis,
rule rows and census classes, DIF rows and paying steps, seam rows, the
hostility set against the Tier-0 count as two numbers, golden sets,
genus proposals kept per lens per round, proposed Fail-if amendments;
extractor set; and red-ledger count — proved red at the gate; the stages — one line each, or "one stage"), what was decided (call out every
`origin: proposal` default), where the artifacts live, and that the next
verb is /vid develop: make the ledger green. Then record
`sh checks/event.sh "stage name=init state=end session=$CLAUDE_CODE_SESSION_ID"`.
