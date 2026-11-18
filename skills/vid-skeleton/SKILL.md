---
name: vid-skeleton
description: Internal — invoked by vid-develop as its first step, in develop mode only, when `sh checks/plan.sh skeleton` says the code skeleton is not built (a spec-only init, or an adopted older one); not a verb, never run by the owner, no stage event of its own. The code skeleton in three parts, init's moved text — Part 1 "Build" (the toolchain, the layout, one golden-path example with its seed test, the harness, the README's preview command), Part 2 "Law" (the generated extractors, each with its self-test case), Part 3 "Red" (vid-test-inventory's call point 2 in skeleton mode: every spec-only row written, observed red and stamped, then the par line and the red gate).
user-invocable: false
---

# The code skeleton (v0.26.10.9 R2, R4)

Init makes the spec only; the code skeleton is develop's first step, built
here by the run itself, as init built it before 0.26.10.9. In ticket mode
none of this is ViD's: the dev team builds the skeleton as its first ticket
(vid-plan), and ViD writes the tests ticket by ticket. The text
below is init's, moved, not rewritten.

**When.** vid-develop invokes this skill (the Skill tool) after its start
checks and before the test environments are measured, with RUN-STATE's
`plan: skeleton` written, from the part `sh checks/plan.sh skeleton` names:
`not started provenance=spec-only` or `not started provenance=adopted` →
Part 1; `next part <k>` → Part k. `plan.sh gate` reads `plan: skeleton` as
off, so the skeleton's runs, receipts and stamps behave exactly as init's
did, outside the gate. At its end develop writes `plan: required` and goes
on (vid-develop, "Before any work").

**Its records, its one reader.** At the first part's start, once:
`sh checks/event.sh 'skeleton state=start provenance=<spec-only|adopted>'`
(the reader's provenance). At each part's end: `sh checks/event.sh
'skeleton state=part-done part=<1|2|3>'`. At Part 3's end: `sh checks/event.sh
'skeleton state=end sha=<HEAD> materialised=<n> red=<n> spec-only=<n>
prerequisite=<n>'` — the counts from the par line. `sh checks/plan.sh
skeleton` reads them: `done`, `next part <k>`, or, before any `skeleton`
event, `not started …` / `not needed`; once the skeleton has started, only
its events decide. A run interrupted mid-part resumes at that part: first
check what of it is already committed (git log, the files, the inventory),
and do only the rest.

**Commits.** Code commits are ordinary commits. The harness file
(docker-compose.test.yml, a law file), the harness client and the
example's inventory row are standalone law commits under the hooks as they
stand (`VID_ROLE=fix` where a path is protected: tests/invariants/,
checks/); the extractors are one standalone law commit; Part 3's stamps are
one standalone law commit per batch.

## Part 1 — "Build"

The toolchain and lockfile, the layout, the golden-path example and its
seed test, the harness, the README's preview command; `sh checks/test.sh`
must run.

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
  it is red at the gate (Part 3). An example whose test is born green has
  built the requirement, not the scaffold; the red gate catches it by name

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
  `x-vid-harness`, which the skeleton writes into every new harness: (1) **nothing is installed or
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
  than `case-limit:` seconds** — the skeleton writes `case-limit: 600` (a choice,
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
  - **the README's preview command** — written here: the compose
    command bringing up the product service alone from
    docker-compose.test.yml (`… -f docker-compose.test.yml up <product>`)
    and no other file; what the owner previews is what the ledger
    certified, or it is nothing.
  Run `sh checks/test.sh` — it must RUN (exit nonzero is expected: the
  ledger is red until its steps are built). If Docker is absent, that is a
  genuine blocker for running tests (it left init's list of blockers in
  0.26.10.9): say so plainly, finish everything else, and leave the command
  for the owner.

Record `skeleton state=part-done part=1`.

## Part 2 — "Law"

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
    every law commit — the hook runs only a project's own cases, never the
    ones the plugin ships (v0.26.10.12.1).
  Extractors are law (checks/ is a protected path and every later change is
  a standalone law commit). Then `chmod +x checks/extractors/*.sh`, and
  commit the set with its self-test cases as one standalone law commit
  (`VID_ROLE=fix`): its hook runs those cases, and any extractor whose
  known-bad fixture passes refuses it, naming the case — fix before
  proceeding.

**The extractor set is ViD's decision** (the owner's default):
record it in DECISIONS.md — one entry naming each extractor and its class,
`| enforced: checks/selftest/cases/<its case>`, `| origin: proposal`,
`| scope: project` — with no question to the owner. Record `skeleton
state=part-done part=2`.

## Part 3 — "Red"

Run the vid-test-inventory skill's §6 and §7 now — **skeleton mode, call
point 2**, verbatim as that skill states them, with this per-row order.
Its rows are every `spec-only` row (`owed: spec-only — first stage`); for an
adopted project, every `owed: prerequisite` row. **Each goes through the
whole rhythm before anything is counted:**
1. its test written by the test-author pass (§6: behavior batches, the
   journeys, the shell, and the surface pass producing the instrument, a
   file per screen) and committed unchanged (`VID_ROLE=fix`, the pass's
   `Tests-by:` trailer) — the builder, and this session, write none of them;
2. the runner proved able to go red (§7, before reading any red);
3. the row observed red;
4. its `test` field changed to its path and stamped `proved-red: <the
   commit that added its test>`, in a standalone law commit (one per batch).

A row the pass can't write becomes `owed: prerequisite — <what is missing;
paid at which slice or boundary>`, as §6 already turns an author's
`unwritable: missing prerequisite`; hostility probes are stamped only by
their own ritual, never by the gate. **Only then** the par line (`par:
rows=R materialised=N legitimate=K deploy-owed=D other=J`; the class split
must show `spec-only=0`, `J > 0` or `N + K + D ≠ R` fails the skeleton) and
the red gate (`green != 0` fails, naming the green rows — a build failure,
not a report line). Record `skeleton state=part-done part=3`, then `skeleton
state=end …` with the counts, and hand back to develop.
