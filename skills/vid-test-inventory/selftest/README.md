# vid-test-inventory — derivation self-tests

The court tradition applied to a judgment step: fixture PRDs the chain
MUST derive correctly, judged by a deterministic checker, so the
derivation axes cannot regress silently. Shipped with the skill; never
installed into a project; never part of `checks/selftest/run.sh` (that
runner is for courts that need no model).

## The protocol (procedural — a session derives, the checker judges)

For each fixture directory under `fixtures/`:

1. Copy the fixture's `PRD.md` (and `ARCHITECTURE.md`, `DESIGN-BRIEF.md`
   and `design/` when present — a design pack means the derivation's
   surface axis has a resolved join to read) into a scratch directory. Every fixture PRD is court-green:
   `sh checks/prd.sh PRD.md --report` prints `gaps=0`.
2. Spawn a FRESH session (Agent tool, general-purpose, no context from the
   spawning session) with: the skill text (`../SKILL.md` and its `passes/` files), the inventory
   template (`templates/INVENTORY.md`), the scratch directory, and the
   instruction: *derive INVENTORY.md in init mode through the end of §5 —
   every axis of §1, the genus floor of §2 applied without spawning lenses unless asked, §3's counterexample question asked by the deriving session itself, §4's governance rows — with every test field `owed: prerequisite — fixture replay, not materialised` (a class of the 0.9.2 vocabulary, so the derived block is legal under checks/inventory.sh's par line) except a row born deploy-owed, which keeps its own `owed: paid by /vid deploy gate N — …` reason; write the file; do not materialise, do not spawn test-author passes, do not commit.* A lens-bearing run (D-6)
   additionally spawns the lenses and records the per-round counts.
3. Judge: `sh derive-check.sh fixtures/<name> <scratch>/INVENTORY.md`.
   Exit 0 = every expectation held. The output lists each expectation with
   its match count.

Paste the checker output into the acceptance record in the release's build notes
(kept in the repository's docs/, not shipped) with the model id that derived. State plainly when the deriving session
was not fresh, or when the lenses were not spawned.

## Fixtures

| Fixture | Pins (spec §7) |
|---|---|
| `time-worded` | D-1: a time-worded Fail-if with and without `derives: trigger-row` yields a trigger-existence row |
| `seam-tier0` | D-2: a Tier-0 item touching a declared seam yields the dependency-failure hostility row beside the ordinary sibling, plus the seam row |
| `everywhere-shape` | D-3: an everywhere-shaped demand item lands as a rule row with a census command and no spot ROW |
| `bundled-req` | D-4: a requirement bundling three promises, one outside its Fail-if, yields one row per promise |
| `cross-cutting-golden` | D-5: a `cross-cutting:` item yields one row per surface; a `derives: golden-set` item cites a golden fixture path; a guard row has its control sibling |
| `phase-deploy` | v0.9.1 3.6: a `pilot` item with one harness-observable arm and one provider-shadowed arm (a seam with `credentials: not-yet`) and one `later` item → the ordinary ledger row plus one row born `owed: paid by /vid deploy gate 2 — …`, and nothing for the `later` item |
| `harness-config` | v0.9.2 3.13 (R22): phase-deploy's PRD plus REQ-021 (the sender name and brand colour operator-entered at setup) and an ARCHITECTURE whose harness sets both by fixture, with a small design pack → one `difference` row per harness-supplied value with `paying-step: staging — the product, provisioned by its own path, serves the ratified value`, and the surface rows still derived, none deferred for provisioning |

| `machine-journey` | v0.9.3 3.2, 3.3 (§7 case 2): a PRD promising "searchable within an hour" and "the subscriber is notified" for what enters at one feed boundary, and an ARCHITECTURE whose harness runs tasks inline and fires schedules at once → one journey row, actor `(process)`, its stages enter · parse · store · index · notify; a trigger row with actor `(process)`; the inline-switch DIF paid by `close run, profile=deployed` with a gate-2 sibling reading "the platform's worker consumes it"; the fast-schedule DIF keeping `staging` |

Every fixture also carries the D-6 expectations that apply without
lenses: no everywhere-shaped obligation as a ROW row for the items that
name one.

## The authorship self-test — the surface pass (v0.9.2 3.4)

The same tradition applied to `passes/test-author.md`'s surface batch:
the fixture `checks/selftest/fixtures/surface-instrument/` (a toy job
board with a toy harness in shell, so the instrument can run without a
browser) and its checker `surface-check.sh`. Procedural, like the
derivation cases — a FRESH pass produces, the checker judges; never part
of `checks/selftest/run.sh` (that runner holds the deterministic half:
the fixture's reference instrument through the checker, the checker's
polarity, the inventory court's join — `cases/surface-instrument.sh`).

1. Copy the fixture into a scratch directory WITHOUT `reference/`,
   `scaffolds/` and `surface-check.sh` (the scaffolds are the app's
   rendered pages — application source the pass must not receive; the
   reference is a previous author's output).
2. Spawn a FRESH session (Agent tool, general-purpose, no context from
   the spawning session; or another model's own agent runner) with:
   `passes/test-author.md`, and from the scratch copy `INVENTORY.md`,
   `DESIGN-BRIEF.md`, `design/`, `harness/harness.sh`, `harness/measure.sh`,
   `harness/run.sh` (the harness client contract, the measure module
   and the runner's declaration contract — what init's harness contract
   is to a project), and the instruction: *produce the surface
   instrument for the surface rows of INVENTORY.md as one shell file
   written against harness/run.sh's declaration contract
   (`surface_rows`, `surface_case`, one `pins_<marker>_<state>` hook per
   row, the literal sets read off the canvases now), and return one line
   per row; write nothing else.* Name the output file; hand over no
   expectation, no scaffold, no previous instrument.
3. Judge: `sh checks/selftest/fixtures/surface-instrument/surface-check.sh <the file>`.
   Exit 0 = every expectation held; the output lists each expectation.

Paste the checker output into the release's build notes (kept in the
repository's docs/, not shipped) with the model that authored, N runs, counts per expectation — never a score. State plainly
when the authoring session was not fresh.

## Expectation grammar

One assertion per non-comment line of `expected.md`:

    <verb> <class> [<field><op><value>]...  [<cmp> <n>]

`verb` ∈ `exists` · `absent` · `count`; `class` ∈ `ROW` · `rule` ·
`hostility` · `difference` · `seam` · `exception` · `suppression`; `op`
∈ `=` (exact) · `~` (case-insensitive regex) · `!~`; `cmp` (count only)
∈ `>=` · `=` · `<=`. Values carry no spaces; the pseudo-field `row`
matches the whole line. Fields by class: ROW — `id kind subject
obligation derived-from test origin`; rule — `id statement command test
origin`; hostility — `id attempt protects disable test`; seam —
`id service`; difference — `id knob`.
