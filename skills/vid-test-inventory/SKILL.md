---
name: vid-test-inventory
description: Own a ViD project's Test Inventory — the whole test contract, every test the project will ever have, routed by what can run it (rule rows with census denominators, materialised ledger rows, grading-checklist lines, the governance rows for what is deliberately not tested, hostility and seam rows). Derives from the PRD's effective set, the resolved design join, and the route table by enumeration joins; deliberates genus through fresh-context expert lenses; challenges the derived evidence with a counterexample lens; ratifies rows with the owner at recognition speed; materialises them as failing ledger tests and holds the red gate. vid-init runs it inline (init mode, two call points), vid-add and vid-design's standalone round call its append mode; standalone it re-derives after PRD appends or a consolidation and presents the row-set diff. It never owns an executor and never runs verification. Use when the owner says "vid test-inventory", "re-derive the inventory", after a PRD consolidation, or when init, add, or design delegate to it.
---

# /vid test-inventory

The inventory verb. One skill owns the **entire test contract** — every
test the project will ever have; what differs between them is only the
executor. It never owns an executor and never runs a verification: the
ledger runs in its harness, the census runs in the commit gate, the
graders run in their fresh contexts. This skill decides what each of
them is obliged to check, gets the owner to ratify that as ROWS, and
hands back a red ledger with a red gate behind it.

**Stage events (v0.9.5 3.11, R11; RECORDS.md).** In a ViD project — after
init, or inside it (`.vid/` exists) — record
`sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" "stage name=test-inventory state=start session=$CLAUDE_CODE_SESSION_ID records=1"`
when this verb starts (in init mode, at its first call point) and
`sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" "stage name=test-inventory state=end session=$CLAUDE_CODE_SESSION_ID"`
when it hands back. This verb can run inside init before the project's
checks/ exists, so it calls the plugin's copy of the helper; every event it
names is written the same way, `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" '<event>'`, which appends
it to `.vid/metrics-events` with its time.

Routing, per obligation, by what can run it:

| Obligation shape | Lands as | Executor |
|---|---|---|
| countable everywhere | `rule` row + census command (+ an extractor where plain enumeration cannot see the sites) | checks/census.sh at every commit |
| executable once | `ROW-NNN` — a materialised failing ledger test | the ledger, in its harness |
| judgment-only | a GRADING-CHECKLIST.md line | fresh-context graders |
| the legal record of what is NOT tested and why | `difference` · `exception` · `suppression` rows | the census printout, every grading brief |
| a must-never-happen | `hostility` row, with its fail-first ritual | the ledger, fail-first |
| an external boundary | `seam` row, born owing a probe | checks/seams.sh, the deploy gate |

The row grammar and every class's semantics are in
`${CLAUDE_PLUGIN_ROOT}/templates/INVENTORY.md` — one grammar, one home;
this skill fills it, never redefines it. Courts are unchanged by this
verb: checks/inventory.sh, checks/census.sh and checks/seams.sh read what
it writes.

**The owner surface — the whole of it.** One ratification sitting per
invocation: a table, presented at recognition level, attention on the
exceptions. The owner ratifies ROWS, not test code, and never authors by
default — every row, golden query, and checklist line is PROPOSED by the
derivation or by a fresh-context lens and confirmed, struck, or amended
by the owner at recognition speed. No other approval point exists.
Narration is position updates ("deriving surfaces", "lens 3 of 6, round
2"), never approval-seeking.

## The entry contract and the three modes

Read, in order: CLAUDE.md → PRD.md (base + `## Appends`, the EFFECTIVE
set: an `AMENDED` row supersedes every earlier row with its id, for items
and answers alike) → BASELINE.md → ARCHITECTURE.md (the seam rows: every
external boundary the architecture declared) → DECISIONS.md →
DESIGN-BRIEF.md's resolved ```vid-design-manifest table when a design
exists → `checks/extractors/routes.sh` when it exists (else route rows
arrive when it does — the route table is court-read from then on) →
INVENTORY.md when it exists → the plugin's seed library
(`${CLAUDE_PLUGIN_ROOT}/seed/rules.md`, `seed/checklist.md`: promoted
knowledge from prior runs, empty on a fresh install, pre-loaded as
proposals for the genus step and the checklist; `seed/extractors/README.md`
is the extractor contract the caller's generated extractors must meet).

Three modes, chosen by what exists and who called:

- **init mode** — no INVENTORY.md; called by vid-init in place, at two
  call points: **call point 1** (init's step 4) runs §§1–6 below — derive,
  deliberate, challenge, ratify, materialise — and hands back; init's own
  steps (scaffold, courts, extractors, the harness) run between; **call
  point 2** (init's step 7) runs §7 — the red gate and the proved-red
  stamp. The owner's experience of init is one sitting in one place,
  unchanged.
- **append mode** — INVENTORY.md exists and the caller names a DELTA: the
  REQs an add introduced (vid-add, after its append commit and before
  develop) or the resolved surfaces a standalone design round produced
  (vid-design §4). Derivation runs over the delta with every axis of §1;
  genus lenses run scoped to the delta (one round each unless a lens is
  not dry); the row-set diff (§5) is presented; ratification;
  materialisation red; `proved-red` stamped at the parent sha where each
  test was observed red.
- **re-derivation mode** — the standalone invocation ("vid
  test-inventory"), over the whole effective PRD after appends or a
  consolidation: derive everything with every axis of §1, run the genus
  and counterexample lenses (one round each unless a lens is not dry),
  diff against the existing block, present the four buckets (§5), ratify,
  materialise the new rows red.
  Brownfield adoption and a reverse-PRD import arrive through this door
  when their callers exist; they are not verbs of this release.

## The chain

```
 derive — three sets, the axes, the enumeration joins        §1  mechanical
    ↓
 genus — fresh-context expert lenses, loop until dry         §2  fresh passes
    ↓
 counterexample challenge — the distinguishing-power lens    §3  fresh pass
    ↓
 governance rows — rules, DIF/EXC/SUP, seams, hostility,
   controls, golden sets, property-form rows, checklist      §4  mechanical + proposals
    ↓
 RATIFICATION SITTING — one table, recognition speed         §5  ← the owner
    ↓
 materialise — failing ledger tests, two tiers               §6
    ↓
 red gate + proved-red                                       §7  (init: call point 2)
    ↓
 hand-back — counts, never scores                            §8
```

## 1. Derive — three enumerable sets, then the joins

Derive INVENTORY.md from `${CLAUDE_PLUGIN_ROOT}/templates/INVENTORY.md`
— three enumerable sets, no authoring: required states (the PRD's
effective demand set and its `fail-if:` clauses), drawn surfaces (the
design-join's resolved marker table, when a design exists), actual
routes (the scaffold's route table, via the routes extractor the caller
generates). Generate the five mandatory row classes — every drawn screen
× state per auth state, every Fail-if, **the shell in each auth state**,
reachability (doors, not just rooms: entry points, resolving nav links,
session ⇒ sign-out control, no cross-auth controls), and the journeys of
the PRD's `## Actors and journeys` section (one row per journey; an
`(off_screen)` phase is where the product is absent — it stays in the
row's narrative and joins to no route or screen; the row's obligation
carries the narrative followed by `transitions:` — one numbered item per
transition, `<actor> at <state> · <entry control> · <action> · <next
state> · <observable effect>`, derived from the section's phases, the
sitting ratifying the list with the row, the row paid per transition —
v0.9.2 3.5, R8). Granularity is screen
× state. Every row carries `origin:` provenance. Rows whose obligation
lacks a falsifiable predicate, or that the design-join flagged
`untraceable`, are tagged at ratification — the tag routes them to
ROW-AMBIGUOUS in develop's verdict pass.

**Reading the enriched grammar.** The PRD is typed rows in a ```vid-prd
block; read the EFFECTIVE set — base plus every append, an `AMENDED` row
superseding every earlier row with its id, for items and answers alike —
and consume each type mechanically, so the derivation is guess-free:

- **Fail-ifs enumerate from the four demand types** (`functional`, `nfr`,
  `ux_flow`, `data_entity`): one behavior row per demand item, obligation
  = its `fail-if:` clause, `derived-from: REQ-NNN`. Frame types carry no
  Fail-if and yield no behavior row.
- **`derives: golden-set`** — the row is not payable until a golden set
  is ratified: in this sitting, ratify the golden set with the rows (the
  must-appear / must-not-appear pairs as a fixture the row's ledger test
  reads, its path stated in the row), and write the obligation against
  it. Until the set exists the row is `owed: golden set not ratified` —
  never a "search is good" assertion the ledger cannot falsify. The
  golden-set shape and its provenance rule are §4.6.
- **`derives: trigger-row`** — a second row per such item, the
  trigger-existence row (kind `behavior`, subject the item's id): the
  schedule or deadline the Fail-if names has
  an operator — a trigger exists and fires — inventoried, not assumed
  (the class where "daily refresh" was a requirement, the logic was
  tested, and no scheduler existed). **The marker is not the only door:**
  a Fail-if carrying a time word — a schedule, a deadline, a retention
  clock, "daily", "within N days", "after expiry" — derives the same row
  whether or not the item carries the marker (the derivation reads the
  words; the marker is the author's courtesy, never the derivation's
  precondition).
- **`invariant` rows are the RULE-row candidates**: propose each as
  `rule | RULE-NNN | <statement> | <census command> | tier | test` with a
  census denominator enumerating every site the invariant applies to (an
  extractor where plain enumeration cannot see them). A `spans:`
  invariant is the natural multi-item candidate — its denominator spans
  the sites of every item it names and its ledger test exercises the
  joint behavior, the interaction one inline Fail-if cannot falsify.
- **`non_goal` rows are the graders' fence list**: they yield no ledger
  row; they ride into GRADING-CHECKLIST.md's fences and every grading
  brief — a grader treats building one as a defect.
- **`pending` items and blocking-`provisional` items** (`confirms_via:
  …/yes`) are VISIBLE DEBT at this sitting: list them by id with their
  carrier or `confirms_via` before the table, so the owner rules now (a
  ledger answer plus an append) or ratifies the row born
  `owed: pending owner decision OQ-n`. The Fail-if still enumerates; the
  row is owed, never absent.
- **`cross-cutting:` items** — optional to author, mandatory to read (the
  ruled demand strength): one row per named surface, each carrying the
  item's Fail-if at that surface (`subject` = the surface,
  `derived-from: REQ-NNN`), so a per-surface enumeration cannot silently
  under-derive a demand that belongs to no single surface. An item
  without the marker derives one row like any other.
- **Tier-0 protections** are the T0 items — demand rows and `invariant`
  rows alike; the hostility siblings (§4.3) derive from them.
- **`phase` — derive from `pilot` items only** (v0.9.1 3.6): a `later`
  item derives nothing until an amendment moves it (append mode then
  derives its delta); a screen serving only `later` items yields no
  surface rows, and its manifest row is written `later:` — design-join,
  design-cite and coverage count it resolved. The hand-back names the
  `later` items as their own count.
- **Executor routing — the deploy-owed rows** (v0.9.1 3.6): a row whose
  obligation can only be observed through something the harness
  substitutes — a DIF row with a `paying-step:` or a seam with
  `credentials: not-yet` — is born `owed: paid by /vid deploy gate
  <1|2|3> — <what the rung observes>`, the seam rows' shape. The item
  stays `pilot`; its other arms derive ledger rows as today. A
  time-worded, scheduled, or worker-run obligation whose harness
  substitute is eager execution (the DIF-002 class) is exactly this
  case: the trigger row stays a ledger row (the schedule EXISTS), and a
  sibling deploy-gate-2 row is born for "the deployed worker consumes
  it". Never a sandbox test that claims to prove a deploy-owed row; the
  in-repo half is ordinary pilot work. **Narrowed under the deployed shape
  (v0.9.3 3.2, 3.3):** for a `difference` row whose paying step is `close
  run, profile=deployed` — the inline switch, a scheduler stand-in, the
  absent workers — the `(process)` row paid in the profile proves the
  harness half (the declared process consumes what the product routes),
  and the deploy-gate-2 sibling STAYS with its obligation narrowed to the
  platform half: *"the platform's worker consumes it"* (the recorded
  failure shape: a worker on the platform subscribed to the wrong queue
  while the local run passed). A difference that keeps `paying-step:
  staging` derives its sibling as before. Each half is paid where it can
  be observed; neither record claims the other's.

**Compound-promise decomposition — the ROW is the atomic unit.** A
demand item that bundles independently breakable promises gets one row
PER PROMISE, never one row's worth of demand for the bundle. The source
is the COMPLETE live requirement block — the statement, its Fail-if, the
design markers that apply to it, and every amendment — not the Fail-if
alone: the measured case (a security item naming ten protections under
one Fail-if and one test) kept its rate-limit promise in the statement,
where a Fail-if-only split would have lost it. Each promise-row is
`derived-from` the same REQ, its obligation the one thing that can
independently be wrong; the Fail-if stays the observable failure
statement of the item and is never the whole source denominator. No
sub-ids, no new schema: rows are rows.

**The enumeration-join principle.** Derivation saturates where it is a
join of two enumerations and starves where it depends on recall. For
every category below, both enumerations already exist in the artifacts;
multiply them, never wait to notice. Where no second enumeration exists
(genus, hostility shapes, which invariants deserve rules), the fresh-lens
treatment of §2 applies. EXC and SUP rows are exempt — the only
categories where more is worse.

| Category | Left enumeration | Right enumeration | Row produced |
|---|---|---|---|
| surfaces | resolved design-join markers | auth states | one surface row per marker × applicable auth state, its obligation written from the manifest row's `pins:` (v0.9.1 3.7b — the constraints the test reads, never an illustrative literal); paid by the surface instrument — a ledger test file per screen (v0.9.8.1 R18), the surface test-author pass's product (v0.9.2 3.4, `passes/test-author.md`), whose file every surface row of that screen cites |
| behaviours | demand items (effective set) | the promises in each complete block | one behavior row per promise |
| shell, reachability | the route table | link references in the templates; entry points per auth state | shell rows per auth state; reachability rows — promotable to the reachability census class once the extractor exists |
| journeys | the actors of `## Actors and journeys` | the thesis's `G*` goals | one journey row per stated journey; a proposed journey row per actor × goal the journeys section leaves uncovered (proposed, ratified or struck) |
| machine journeys (v0.9.3 3.2, R3) | every external input boundary ARCHITECTURE.md declares — feeds, uploads, webhooks, scheduled pulls, inbound mail | the observable consequences the PRD promises for what enters there — searchable, matched, notified, exported, expired, deleted | one journey row per chain, actor `(process)`, its `transitions:` the stages as the PRD states them (enter · parse · store · index · notify · expire), each with its observable effect |
| temporal | time-worded Fail-ifs (marker or words) | the trigger registry — the deployed shape's schedule table, once it exists | one trigger-existence row per item, actor `(process)` under `grammar: 0.9.3` (the deployed pass pays it): "an operator exists — the trigger is registered in the deployed shape, fires, and its last firing is recorded" |
| volume | list surfaces (every surface whose marker or route renders a collection) | the PRD's stated volume (a corpus, scale, or `data_entity` item naming a size) | one operability-at-volume row per list surface, materialised as a many-record fixture built through public paths |
| dependency failure | provider seams (ARCHITECTURE.md's external boundaries) | Tier-0 operations that touch that seam | one hostility row per pair (§4.3, the dependency-failure shape) |
| divergences | every knob the harness substitutes — provider fakes, engine stand-ins, thresholds, toggles | the harness's own configuration, at materialisation | one `difference` row per fake: every fake is a divergence by construction, derived, never waited for |
| operational guards | configuration fields the product collects, validates, and stores | reader sites other than validation and display | the collected-fields dead-path census instance (§4.1) — an empty right side is the finding |
| cross-cutting | items marked `cross-cutting:` | the surfaces named | one row per surface |
| Tier-0 | Tier-0 items and rule rows | the hostility shapes | one sibling per protection (§4.3) plus its control sibling (§4.4) |

**Bounded interaction examples (Tier-0 interacting factors).** Where a
Tier-0 promise has interacting factors — caller identity × entry path ×
limit bucket; consent state × delivery path × retry — derive a SMALL
bounded set of interaction cases rather than one-axis rows. These are
model-selected interaction EXAMPLES and are named so in the row's
obligation; they are not pairwise coverage, and the rows never claim a
coverage property they do not have. Genuine pairwise coverage needs an
explicit factor and value list, deterministic generation, and a
checkable every-pair denominator — machinery that must first earn its
place under the complexity law, and is not built here.

## 2. Genus — an iterative fresh-context deliberation, never a list

The PRD states what this product does; its genus ("it's a job board",
"it's multi-tenant", the stack the scaffold commits to) inherits
obligations nobody writes down because experts assume them. Genus is the
one judgment step in the method that used to run single-pass inside the
author's own context — structurally inside the blind spot it exists to
illuminate. It runs as fresh passes now, with the machinery the method
already trusts.

**The lenses.** Spawn each as `passes/genus-lens.md` — the lens brief and
the universal floor live there; the session derives WHICH lenses (at least
4, at most 8) from the PRD's own genus statement, as the brief says.

**Loop until dry.** Per lens, round by round: the session dedups the
round's candidates against stated REQs, existing rows, and every earlier
candidate — the same forbidden effect on the same subject is one
candidate — and records two counts, candidates returned and candidates
kept. A round that adds zero surviving candidates is DRY and ends the
lens; a hard cap of 3 rounds per lens ends it regardless. A later round
is a fresh context given the accepted candidate list so far (so it can go
beyond it) — never the dedup verdicts on rejected candidates, never the
previous round's reasoning: a re-run pass that knows the last answer is
anchored, not fresh.

**Routing, enforced.** Classify every survivor into an EXISTING evidence
tier — testable behavior → ledger-tested ROW; "everywhere" rule → RULE
row with its census command; judgment-only → a GRADING-CHECKLIST.md
line. **An everywhere-shaped obligation MUST land as a RULE row with a
census denominator, never as a spot test** — the measured case: "every
public collection endpoint is bounded" passed as one test while the
unbounded sitemap sailed by. This holds for a DEMAND ITEM whose promise is
everywhere-shaped too: it derives its rule row (`origin: REQ-NNN`, the
rule's ledger test asserting over the enumerated set) in place of a
behavior row, so the item's evidence grows with the codebase instead of
pinning one remembered site. Tag every proposal `origin: domain`. The
owner vetoes or confirms at recognition speed — expertise capture as
multiple choice, not essay. A vetoed proposal leaves no residue.

The floor's numbered shapes live in `passes/genus-lens.md`; the sitting reads them by number.

Shapes 15–20 are the **universal-protection group** — present them
together at the sitting as the must-never-happen list they are; each
ratified as Tier-0 spawns its hostility sibling. Shapes 9, 11, 21 are
census classes: shape 9 is a mandatory dead-path instance, 11 and 21
are candidates the sitting rules on.

**Stack layer** — derive the instances from the scaffold in front of
you, never from a list — e.g., for an ORM-backed web framework:
request-forgery protection on every mutating endpoint; every collection
query bounded; a schema migration for every persisted model; time
behavior across DST/timezone boundaries. **Domain layer** — the owner's
expertise + `seed/rules.md`, the promoted library, may be empty on a
fresh install — mined, not veto-only:

**The genus-domain interrogation (at the sitting, one screen).** Nouns
(the `data_entity` items) × lifecycles (the state-machine rows) × "what
must never happen to a <noun> in <state>?", with the lenses' candidate
answers pre-filled — the owner ticks, strikes, or adds one line per cell.
Recognition speed, never an essay, never veto-only.

## 3. The counterexample-challenge lens

Spawn `passes/counterexample-lens.md` over the WHOLE derived table, after the
other lenses.

## 4. Governance rows and the proposals the sitting rules on

### 4.1 Census row classes — the legal record

The census row classes ratify in the same sitting: RULE rows (each with
its census command — the denominator is law), DIF rows for every knob that
legitimately differs between test and prod, EXC/SUP rows only where the
initial censuses justify them. **At init every rule row is ratified
`owed:`** — before code exists every code-site census enumerates nothing,
and an owed rule reports `pending` rather than failing the zero-denominator
guard; materialising the rule's test in develop arms it. The joint
behavior an `invariant` (or a `spans:` invariant) promises may therefore
also carry a behavior ROW with a test materialised red now; the rule row
stays the denominator, the ROW is the executable half until the census
arms.

**Lifecycle fields land as state-machine rule rows (§6.1).** Where the
PRD implies a lifecycle — a status that moves through states — ratify its
transition table now: `rule | RULE-NNN | state-machine <field>: …` with a
census command enumerating the mutation and guard-read sites (a generated
`checks/extractors/state-machine.<field>.sh` where plain enumeration
cannot see them — the one extractor shape the census never runs as a
class; its contract is in seed/extractors/README.md). Develop-introduced
lifecycles land the same way, row before code. In the same sitting, mine
the `data_entity` items and the answer ledger for data-semantics choices
(§6.3 — what stored values mean: units, casing, monotonicity; what an
entity must survive) and land each as a constraint or a ledger test,
never prose only.

**The collected-fields census instance (mandatory).** Shape 9 lands as a
dead-path extractor instance the caller generates from the scaffold
(`checks/extractors/dead-path.collected-fields.sh`, contract in
seed/extractors/README.md): population = every field the product
collects from a user and stores; join = a read site other than
validation and display; an orphan is a field the product asks for and
never acts on. Empty right side on any field is the finding, and the
zero-denominator guard applies as for any census.

**The topology census instance (mandatory, v0.9.3 3.4, R5).** Beside it,
`checks/extractors/dead-path.topology.sh`, generated from the scaffold the
same way (contract in seed/extractors/README.md): population = every
task-to-queue routing and every schedule the product declares; join = a
declared process (the harness contract's `processes:`) consuming that
queue, or a registered task for the schedule's target; an orphan — a
routed queue nobody consumes, a schedule naming an unregistered task —
blocks the commit. It prints `inactive` until the first routing OR the
first schedule exists, so a schedule-only product arms it too. Like the
collected-fields instance it is a class extractor whose presence the
sitting ratifies, NEVER a rule row (a rule row's command handed
`inactive` meets the zero-population rule). A queue whose consumer
exists only on the platform is acquitted by a ratified `difference` row
or a deploy-owed row naming it, and its platform half is paid at deploy
gate 2.

**DIF rows derive from the harness.** Every fake the harness substitutes
for a real component — a provider stand-in, an engine stand-in, a
threshold, a toggle that differs — is a divergence by construction:
derive its `difference` row at materialisation from the harness
configuration, never wait to notice it. **The paying step (v0.9.3 3.3):**
a DIF whose knob is the inline switch, a scheduler stand-in or the absent
workers is paid by the close run's deployed pass — `paying-step: close
run, profile=deployed` — and its gate-2 sibling carries the platform half
only (above); the fast-schedule setting is a harness substitution too and
keeps `paying-step: staging`, as does every knob whose real component
exists only on the platform. A DIF row that legalises a
model or engine divergence for a golden-set item carries its paying
step (§4.6). **One named instance (v0.9.2 3.13, R22): configuration the
harness supplies that the spec does not provision** — a fixture setting a
brand value, a display name, a feature switch, seeded content, where the
effective set makes that value tenant- or operator-entered (or gives a
placeholder default) and no row provisions it — derives a `difference`
row at materialisation, `knob` the value, `test-value` what the harness
sets, `prod-value` the entered value, with `paying-step: staging — the
product, provisioned by its own path, serves the ratified value`, paid
at deploy gate 2 and briefed like any DIF. Surface rows measure against
the harness's configuration as today: the instrument's paint comparison
is not owed to provisioning, and the surface rows stay materialised — the
provisioning obligation is the DIF row's (and, when a design sitting
ruled `design wins` on such a value, the deploy-owed row's).

### 4.2 Provider seam rows

**Provider seam rows ratify here too (§3.1)** — one per external boundary
the architecture step declared, born `probe: owed` with `match:` tokens
the owner can recognise (client-library names, hostnames). The probe is
paid in develop BEFORE the first client line (§3.3); where the service
cannot be probed, `unreachable-risk(<reason>)` is the legal exit — stated,
never silent. Credentials state is declared honestly (`held`, `not-yet`,
`never`). **A seam with `credentials: not-yet` is ratified `probe:
unreachable-risk(credentials not-yet)`, never `owed`** (v0.9.2 3.10, R15):
the client is written against the provider's documented contract, its
contract test over a hand-authored fixture whose `Provenance:` says so,
and the seam is paid in full at deploy gate 2 (vid-deploy) — the smallest
real calls captured, the contract tests re-based on the captures by a
test-author pass, the row flipped to `probed(<date>)` in its own law
commit. Under a block carrying `grammar: 0.9.2` a `not-yet` seam born
`owed` is a GAP at the sitting's court (checks/inventory.sh): `owed` would
promise a probe develop cannot perform, and checks/seams.sh would block
every client line behind it. checks/seams.sh enforces both doors from the
initial commit on.

### 4.3 Hostility rows — the must-never-happen list

**Hostility rows ratify here too (§4.1)** — one sibling row per ratified
Tier-0 protection, each attempting the forbidden thing against the running
app through its real public surface. The set is DERIVED from the Tier-0
rules and items (T0 demand rows and T0 invariants) the owner has just
ratified, never invented: ~one
probe apiece (10–15 for a mid-sized product), from the behavior shapes in
templates/INVENTORY.md — concurrent double-submit, replayed one-time link,
cross-actor resource request, transition out of a forbidding state,
rotated client-identity header against a bound, stale-state resubmit,
**dependency failure during the protected operation, concurrency against
the protected operation**. It
is a fixed list, not a fuzzer and not a scanning tool; the way to add a
probe is to ratify the protection it is the sibling of. Each row is born
naming its `disable:` toggle — the reversible way that protection is
turned off — because the toggle is what makes the probe provable. Present
them with the rest of the table; the owner is ratifying a
must-never-happen list, which is exactly the recognition-level judgment
they are best placed to make.

The two shapes new since v0.8.1d: the **seam × Tier-0 product** — every
Tier-0 operation touching a declared seam derives a "seam fails
mid-operation" probe, `protects:` the item, `disable:` the fail-closed
handling itself (remove it and watch the forbidden effect occur; the
measured case: an erasure that failed open when its store was down while
its probe counted residue through the pointer it had just blanked, so it
could not fail for the failure that would actually happen); and the
**concurrency probe** — two simultaneous attempts against the protected
operation, `disable:` the serialisation guard.

### 4.4 Positive-control siblings

Every guard/never row derives its **control sibling**: the allowed case
demonstrably works, with the effect observed — "consent on → exactly one
send, recorded" beside "consent off → none". An ordinary ROW,
`derived-from` the same REQ, obligation opening "control of ROW-NNN: …";
no new field, no new class. It kills exactly one class — the
implementation that keeps the promise by never doing anything — and
claims nothing about one-path bypasses (a protected scheduled send beside
an unguarded retry passes both arms): those belong to the path
enumerations of §1, the everywhere routing of §2, and the hostility
siblings above.

### 4.5 Property-form rows

Interior depth lands as many-input datasets through the public surface —
real salary strings through ingest, an independent town sample through
the geocoder's public path — ratifiable and refactor-proof. Invariance
relations are legal property-form shapes, stated as rows over the public
surface: **reorder-invariance** (reordering inputs leaves the result
unchanged), **rename-invariance** (renaming identities leaves aggregates
unchanged), **repeat-idempotence** (repeating a request does not duplicate
the effect), **unrelated-state-unchanged** (one preference transition
leaves unrelated preferences unchanged). No oracle, no reference
implementation: a relation is a row with a falsifiable predicate over the
product's own outputs.

### 4.6 Golden sets

A quality-bar item (`derives: golden-set` — "state-of-the-art search",
matching, ranking, dedup confidence) is **unratifiable until a golden set
exists.** The set is a fixture file under `tests/invariants/` (a protected
path — the fixture is law), one line per query:

    query | must-appear | must-outrank | must-not-appear

against the realistic corpus, its path stated in the behavior row, the
row's obligation written against it. **Proposed by the fresh-context
lenses, never by the build or tuning context** — a session must not
propose the queries it is judged on — and ratified by the owner at
recognition speed; owner authoring is optional, never required. The
hand-back counts queries and triples.

**The paying step.** Where a `difference` row legalises a model or engine
divergence on that item's path (a stand-in embedder, a harness threshold
that differs from prod), the golden row carries `| divergence: DIF-NNN`
and that DIF row carries `| paying-step: staging — re-run <fixture path>
against the real component`. The DIF is thereby a deferred test with a
named paying step, not a permanent shrug; the ladder that executes the
step is the deploy verb's. checks/inventory.sh joins the two: a golden
row naming a DIF that does not exist, or one without a paying step, is a
GAP.

### 4.7 The grading checklist

**The grading checklist.** Create GRADING-CHECKLIST.md from
`templates/GRADING-CHECKLIST.md`: the harness-attack standing line ships in
the template; seed the domain lines from the interview and
`seed/checklist.md` when the library carries any (the judgment-only genus
proposals land here). It is owner-curated and injected verbatim into every
grading brief. In append and re-derivation modes, add lines; never remove
one without the owner striking it.

## 5. The ratification sitting

The owner ratifies ROWS, not test code: present the table for review at
recognition level in one sitting, attention on the exceptions. Ratification
fails closed on the four delta classes (when a design exists, run
`sh checks/design-join.sh` — unresolved deltas mean the sitting cannot
close; with no brief and no pack there is nothing to join and the court
is not run) and on any row without a falsifiable obligation.

Before the table: the visible debt (pending and blocking-provisional
items by id); the deferrals listed by class (v0.9.2 3.2 — every row whose
test field reads `owed: <class> — <detail>`, one list per class of the
closed vocabulary with its detail, the unclassed list first and expected
empty: the gate fails on it); the proposed Fail-if amendments from §3
(proposed, not applied); the genus-domain interrogation screen (§2); the
counts per lens per round.

**Append and re-derivation modes present a row-set DIFF, never the whole
block.** Match each derived row to the existing block by kind + subject
+ derived-from (exact), comparing obligations after whitespace
normalisation. Four buckets, in this order, one table:

| Bucket | Presented as | Owner act |
|---|---|---|
| NEW | full rows, grouped by axis (temporal, volume, seam × Tier-0, genus lens, control, …) | ratify / veto per row |
| CHANGED | same key, different obligation — one line, old → new | keep old / take new |
| ORPHANED | rows the effective PRD no longer derives, each with the append or amendment that orphaned it | keep (the owner names why: `origin: finding-NNN` or `domain`) / retire |
| UNCHANGED | a count and the id ranges — never re-presented | none |

New rows continue the id sequence and keep every existing row's id, test,
and `proved-red`. **Retiring a row is a law change**: its own standalone
commit whose Decisions: trailer cites the amendment that removed the
row's source; the row's test deletion rides the same commit. Rows are
otherwise never deleted or weakened — a row that seems wrong is a product
question.

**The sitting's rulings are an append, reviewed before ratification 3
commits.** Every owner ruling taken here (a Fail-if amendment accepted, a
debt item decided, a proposal ruled) lands as one dated append — `A-NNN`
rows, `AMENDED` rows — and before the ratification commits, spawn
`${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/whole-set-review.md`
in `mode: delta` on that append against the effective set (v0.9.1 3.2).
Its findings are ruled in this sitting, one line each: a
`fix_from_record` finding is an amendment in the same append, a question
is the owner's — and every finding that narrows or withdraws a fail-if
arm (v0.9.8.1 R29) is one owner question for the review, listing each
row, its arm and the answer it follows; the answer settles every row it
names. Record `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" 'tokens slice=N phase=review n=T'`
(`slice=0` before develop's first slice). No
append, no review. In init mode, consolidation follows this sitting and
precedes the initial commit (§7): the scheduled event of vid-create-prd's
"Consolidation" — 7a `sh checks/prd-consolidate.sh`, 7b's review, one
row-set-diff sitting, two commits.

## 6. Materialise — two tiers, one rhythm

Then **materialise**: every row that can be expressed pre-code becomes a
FAILING ledger test in tests/invariants/ — reachability, shell, journey
and surface rows are all directly writable pre-code, in the engines the
harness contract declares, inside the container-only harness. No test
can encode an implementation's assumptions, because no implementation
exists. **"Materialise" means "spawn test-author passes"** (v0.9.2 3.1,
3.3, R1, R2): `passes/test-author.md`, spawned over every row not
legitimately deferred, batched — behavior rows by REQ domain, journeys as
one pass, shell and reachability as one pass, the surface rows as one
pass — each pass returning one line per row briefed, never fewer; the
caller commits each returned file UNCHANGED as a free ledger addition,
observes it red with a scoped run, and stamps `proved-red`. The builder
never writes a ledger test; the boundary rule (R6) is in the pass file.
**Each test carries its argument** (v0.9.8 R1; amendments 2 and 3): every
pass writes each test with its test argument — its given, when and then,
the wrong product it rejects and its `cases:` line — by the test-writing
skill. **Small test files** (v0.9.8.1 R18): each new file holds one row,
or up to 5 related rows; a pass keeps its batch and returns several
files; existing files stay as they are, and no court counts their size.
A row the passes cannot write is deferred only by the closed vocabulary
(`owed: <class> — <detail>`, templates/INVENTORY.md; an author's
`unwritable: missing prerequisite` becomes `owed: prerequisite — …`;
"materialised when its surface exists" is a red test, and is written) —
blocked from completion by the coverage join and counted on the par line
(§7). Because the passes need the harness contract and the route table,
**in init mode materialisation runs after init's step 6, as the first act
of call point 2, before the gate** — the one ordering change of v0.9.2
(vid-init §4, §7); what the owner sees is unchanged: one sitting, then a
red ledger at the initial commit. **Surface rows are routed to the surface pass** (v0.9.2
3.4, R7): `passes/test-author.md`, batch `surface`, spawned once over
every surface row with the canvases, the manifest, the shell rows'
markers and the measure module's contract, produces the surface
instrument, a file per screen (v0.9.8.1 R18) each surface row of it
cites — its row table, its per-state literal set and each row's pins
hook, every file through the one measure module; a missing route or marker is one of its red
cases, never a deferral; the only legal deferral of a surface row is
`owed: prerequisite — <a harness fixture the state needs>`.
**Hostility probes materialise through that same harness**
(browser or HTTP, the project's own, inside Docker) and through no other:
a probe is an ordinary ledger test whose assertion happens to be about a
forbidden effect. Most stay `owed:` at init — the guard they attempt does
not exist yet, so there is nothing to disable and the ritual (§7) cannot
be performed; they are materialised in develop, in the slice that builds
the protection. Report the ledger honestly: **red, green 0 / N** is the
correct state at the end of init — and the red gate (§7) enforces it.

**Two tiers.** `tests/invariants/` is the ledger — the law tier, cited by
rows, evidence. `tests/scaffolding/` is the builder's non-law tier:
implementation-keyed tests as disposable instruments — never cited by a
row, never evidence, outside the coverage join, outside proved-red,
outside the vacuity and strength extractors, outside the deletion
tripwire, deletable without a law commit, and **never run by the gate**
(the builder runs it inside the same harness by explicit selector). The
split makes the deletion tripwire precise: a deletion in invariants/ is
decay; in scaffolding/ it is nothing.

**Behavior-keying is a court.** A ledger test file imports the harness
client and fixtures, never application internals: checks/imports.sh
rejects a `tests/invariants/test*` file importing a seam-table module
that does not name `tests/invariants` among its dependents — the harness
entry module declares it, internals do not. Dataset and fixture
generators live under `tests/`, where the same court sees them: a
generator importing the product's own tables is the same conviction
(the corpus that could not exercise the failure it was built to find).

**The rhythm, numbered** — for every row materialised after the initial
commit (develop, add, fix, re-derivation): (1) the test file, a free
ledger addition, observed red — committed first; (2) the row citing it,
a standalone law commit stamped `proved-red: <parent-sha>` — the parent
of the row commit, i.e. the commit that added the test, where it was
observed red; the file must exist there and name the row;
(3) the code that turns it green. checks/inventory.sh resolves cited
paths against the commit under construction (index + HEAD), never the
working tree — a row citing a worktree-only file fails its law commit.

**Fixture provenance.** Every fixture file under `tests/` opens with a
one-line `Provenance:` header — `hand-authored`, `captured from <seam
probe>`, `generated by <generator path under tests/>`, or (v0.9.8, R9)
`regression — <whose case, and the fix that used it>`: a grader's case
once used to fix the product stays as a regression test and is never
grading evidence again. A fixture whose
expected value was produced by the system under test is circular, and the
header is what lets the vacuity extractor see it.

**What the caller's generated extractors must carry** (init step 6
generates them; this skill states the requirement; the contract is
seed/extractors/README.md): the report-only **vacuity** extractor built
from the MEASURED classes, not the five law shapes alone — status
assertions spanning success codes with no error code; presence-only
browser assertions keyed to static wrappers that render even in the empty
state; substring filters matching nothing; zero-population loops; the
placeholderless format string inside an assertion; the circular fixture
(a `Provenance:` naming the product, or absent); the report-only
**strength** extractor — classify each row-bound test's assertions on the
ladder Existence → Type → Status → Value → Behavioral and report a Tier-0
row whose strongest assertion is Existence — both built with v0.9.8's
three repairs and shipped with their labelled fixture for `sh
checks/census.sh --measure` (R11; seed/extractors/README.md, "The repair
and the measure"); and, per generated extractor,
a selftest case that plants **mutations beyond the canonical shape**: at
least one unguarded site in a non-canonical form (a second vocabulary
for the same guard) and one arm-broken compound command. All report-only
classes ship under the promote-or-delete gate: promoted fail-closed or
deleted on the first run's measured number.

## 7. The red gate, the initial commit, proved-red

**Prove the runner can go red, before reading any red.** Invoke the ledger
runner with a selector naming a test that does not exist. Runners commonly
exit 0 on a selection that matches nothing — and a gate wired that way
reads `green == 0` from a run that executed nothing at all, satisfying
itself vacuously. If the empty selection exits 0, fix the invocation
before the gate below means anything. Then confirm the gate has a
denominator: `red` must equal the number of materialised rows, not merely
be nonzero.

**The par line, then the gate (v0.9.2 3.2, R2–R4).** `sh
checks/inventory.sh --report` prints, under a block carrying `grammar:
0.9.2`, `par: rows=R materialised=N legitimate=K deploy-owed=D other=J —
holds|FAILS`. Init FAILS when `J > 0` (a deferral outside the closed
vocabulary — the sitting classes it or the pass writes it) or when `N + K
+ D ≠ R`; only then the red gate below. In append and re-derivation
modes the same line over the delta's rows.

**The red gate (§3.6) — a build failure, not a report line.** Run the
ledger with per-test results. Every materialised test must FAIL against the
empty scaffold: `green != 0` fails init, naming the green rows — a test
that passes against no implementation cannot be testing the implementation
(the born-green class was found by graders in all three v0.6 rounds). Make
each named test falsifiable and re-run until green == 0. Only then:

Stage everything and commit with the template message (REQs: all seeded IDs;
Decisions: the D-entries; Seams: initial table; Model: this session's model
id) with `VID_ROLE=fix` set — init's ledger seed and courts are
owner-sanctioned by the interview and the ratifications. This commit is
exempt from the law-change standalone rule because it IS the ratification
act: the hook skips that rule while HEAD carries no `checks/` — the PRD's
three ratification commits (or the adoption commit) precede it as the
project's first history, and the commit that installs the courts is the
last one the rule does not govern. The presence-gated courts, prd.sh
included, run on it:

    VID_ROLE=fix git commit -m "..."

Then **stamp proved-red**: append `| proved-red: <initial-commit-sha>` to
every row whose materialised test was observed red, and commit INVENTORY.md
alone — a standalone law commit (the hook enforces it and re-runs the
self-test). Rows still `owed:` are stamped later, when their tests
materialise red.

**A hostility probe is stamped only by its own ritual (§4.2)**, never by
the red gate: the gate's red is "no implementation exists", which every
test shares and which proves nothing about an attempt. A probe materialised
here — the protection it attempts already stands in the scaffold — earns
its stamp by the four steps: prove the runner can go red (above), disable
the protection by the row's own `disable:` toggle and watch the probe fail
**on its assertion about the forbidden effect** (a red from a connection
error, a 404 or a fixture fault is the same false assurance in the other
direction), restore and watch it pass, then stamp the sha where step two
was observed. A probe with no verified failing state stays `owed:` —
checks/inventory.sh rejects the commit that cites it unstamped.

In append and re-derivation modes the gate is the same with the new rows
as its denominator: every newly materialised test observed red at the
parent, stamped in the row's own law commit; nothing previously green may
turn red.

## 8. Hand-back

The first line is the rows headline (v0.9.2 3.8, R10) — `sh
checks/metrics.sh`'s `rows: kept K · unverdicted U · breached B · red R ·
owed O · deploy-owed D (unmet …)`; at init `receipt: none` and every
materialised row red, which is the correct state — never a proportion.
Then a few sentences, no ceremony, counts never scores: rows by axis (surface,
behavior with promise-rows counted, shell, reachability, journey,
temporal, volume, control), rule rows and their census classes, DIF rows
(and how many carry a paying step), seam rows, the hostility set against
the Tier-0 count as two numbers, golden sets (queries and triples), genus
proposals kept per lens per round, the counterexample lens's kept rows,
proposed Fail-if amendments, the checklist lines added, the diff buckets
in append and re-derivation modes, the deploy-owed rows and the `later`
items as their own two counts (v0.9.1 3.6), and the red-ledger count —
proved red at the gate. Then return to the caller (init continues at its step 5, or
its step 8 after call point 2; add continues to develop) or, standalone,
name the next verb.

## Pass mechanics — what each fresh context receives

Fresh-context passes are spawned exactly where the chain marks them (the
genus lenses, the counterexample lens, the delta coherence review of §5,
the test-author passes of §6).
Each brief names what the sub-session receives — and what it must not:

| Pass | File | Receives | Must not receive |
|---|---|---|---|
| Genus lens (§2) | `passes/genus-lens.md` | the effective PRD; the derived rows as ids and obligations; the universal floor; the seed proposals; the one-question brief; a later round additionally the accepted candidate list so far | the other lenses' output (blind to them); the rejected candidates; the verdicts; this session's reasoning; any previous verdict |
| Counterexample lens (§3) | `passes/counterexample-lens.md` | the whole derived table; the effective PRD; the two-question brief | the build or tuning context — which is also why it, and never this session, proposes golden queries; this session's reasoning; any previous verdict |
| Delta coherence review (§5) | `skills/vid-create-prd/passes/whole-set-review.md` in `mode: delta` | the effective PRD; the sitting's append verbatim; the seed; the contract | this session's reasoning; any previous verdict |
| Test author — behavior, journeys, shell/reachability batches (§6; v0.9.2 3.1, 3.5) | `passes/test-author.md` | the batch's rows verbatim (for journeys the `transitions:` list); the effective items they derive from; the harness client contract (its public surface, the actor kinds, the fixture law, the Provenance rule); every existing file under tests/; the route table; the boundary rule | any application source, template, stylesheet or migration; the build session's plan, slice decomposition or reasoning; another batch's output; a previous author's verdict |
| Test author, surface batch (§6; v0.9.2 3.4) | `passes/test-author.md` | the surface rows with their `pins:`; the effective items they derive from; the harness client contract; every existing file under tests/; the route table; the canvases and the manifest; the shell rows' markers; the measure module's contract; the boundary rule | any application source, template, stylesheet or migration; the build session's plan or reasoning; another batch's output; a previous author's verdict |

Every pass file opens with the same fixed header — the independence
mechanism (a separate agent, no authoring- or build-session context, a
re-run never told the previous verdict, a prompt carrying anything the
calling session believes is VOID and re-spawned); `checks/selftest/cases/
passes.sh` asserts it verbatim in every file under any `passes/`.

Hard schemas are permitted only inside a pass's model calls (tier
enums, the row kinds); what lands on disk is only the markdown grammar.
Deleted machinery stays deleted: no correction verbs, no artifact store,
no seals, no projections, no replay bench — the derivation self-tests
beside this skill (`selftest/`) serve that role: fixture PRDs the chain
must derive correctly, judged by a deterministic checker, so the axes
above cannot regress silently.
