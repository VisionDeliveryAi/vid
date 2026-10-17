---
name: vid-test-writing
description: Internal — loaded by every test author; not a verb, never run by the owner. Writing a ledger test that no wrong product can pass — the test argument and its cases line, the anti-cheating rules, the techniques as guidance, the mistakes catalogue, setup, small test files, the boundary rule, the screen instrument and the journey shapes.
user-invocable: false
---

# The test-writing skill (internal)

Internal — loaded by the test author (`vid:test-author`). Not a verb:
`vid help` does not list it, and the owner never runs it. Writing tests
is a job of its own (v0.9.8, R1). Your brief says
what you are asked and what you return; this skill says how a test is
made to tell a right product from a wrong one.

A test counts when a plausible wrong product fails it. A test that runs,
or fails on an empty product, shows only that it runs.

## The writer

### The test argument

Before the code of each row's test, write its argument — short — as a
comment beside the test, in the test file's own comment syntax, each of
its lines naming the row id:

- **promise:** the row's promise and its authority — the item of the
  row's authority bundle the expected result comes from (a PRD arm, an
  owner answer, a decision, a design state), by its id. Never the
  product's own code.
- **wrong product:** one plausible wrong product, concrete.
- **given, when, then:** the data that separates the right product from
  that wrong one; the action that reaches the decision; the promised
  effect, on the right object, after the work completes.
- **controls:** what shows the setup works and the harmful case is
  reached.
- **technique:** the technique you chose (below), and why.
- **cases:** one line, the only one read by a program:

      cases: ROW-<id> target=<case id> control=<case id>

  `target` is the case that fails when the row's promise is broken;
  `control` a case that passes on a right product and is untouched by
  such a fault — the setup working and the path reached. Case ids as the
  run's receipt names them. The grader and the run manager read this
  line for the fault proof; a row without it can't be proven.

### The anti-cheating rules

- **Before and after:** the result is absent before the action and
  present after it.
- **One exact place:** a record, a field or a labelled element, never
  "somewhere on the page".
- **Decoys:** the discriminating value in exactly one place, plus a near
  miss that must not match.
- **Fresh values:** unique per run, so no product can hard-code them.

### Techniques, as guidance

You pick, and the argument says which and why. The table is a starting
point, not a rule:

| When the promise… | Consider |
|---|---|
| has a threshold, a limit or a deadline | values just either side; the clock's origin |
| says "every", "never", "for all" | a property over generated inputs, plus one named example |
| has no exact expected value (ranking, search) | a relation between runs ("adding a filter never adds results"), plus one example |
| scores or matches | independent golden data, never used for tuning |
| reaches an external service | a fake checked against the real contract |
| protects isolation | the neighbouring entity that must stay untouched |

### The mistakes catalogue

Each was found in a real run; each passes a wrong product:

- right and wrong coincide in the data;
- an assertion that runs only in some cases;
- checking part of a list;
- the right values on the wrong items;
- a failure already true before the action;
- an expectation computed by the code under test;
- tuned-on grading data — a case already used to fix the product
  (`Provenance: regression`) is no grading evidence;
- the row's own example values ignored.

Your brief may carry lessons (`## 17 lessons`): each an earlier weak
test's bad example, why, and a good example, naming the file and the row
ids. Read them as part of this catalogue. A lesson has this form
(v0.9.8.1 R21; vid-verify's "Sweeps and lessons" writes it, no blank line
inside it):

```
## L-<n> · <UTC date> · from ROW-<id>
helpers: <the helper files it concerns, comma-separated, or none>
rules: <the REQ, RULE or ROW ids it concerns, comma-separated>
bad: <the weak test, one line>
why: <the wrong product it let pass>
good: <the strong form, one line>
```

### Setup

You own your step's setup, built through the shared harness contract:
fresh data builders, one clock, readiness waits, never fixed sleeps. A
setup failure is reported as setup, never as the row failing. A change
to the shared harness goes through the existing harness route
(`class=harness`).

### Small test files (v0.9.8.1 R18)

A new test file holds one row, or up to 5 related rows (one rule's
cases, one screen's states). Your batch keeps its size: return several
files, each named by the stack's runner convention. Shared setup stays
in the harness and the one shared measure module, never copied into
each file, and a helper you add stays a public harness boundary. Setup
that two rows' tests both need belongs in the project's shared fixture
code, never in another row's test file; a row still cites one test file
(v0.9.8.1 R36).
Existing files are not split or moved. There is no size court.

### Carried over

**The boundary rule (R6), verbatim:** *A promise is proved at the
cheapest boundary that observes it: the HTTP harness for rules and
behaviour; the browser only for paint and operation; a crawler's,
worker's or webhook's own entry point for its process; never an
implementation-keyed test.*

#### The surface pass — one instrument, a file per screen (3.4, R7, R20; v0.9.8.1 R18)

The batch is `surface`: every surface row of the inventory (screen ×
state × auth state), briefed together. The product is the ledger's
surface instrument, written as a file per screen —
`tests/invariants/<surfaces file for the screen>`, named by the stack's
runner convention, its states together (a screen with more than 5 rows
split by state) — every file through the one shared measure module, one
load and one evaluation per state, and never a pins hook written by
anyone but this pass. Its inputs are read now, at
production time, never at collection time: the surface rows (kind,
subject, actor/state, marker, obligation with its `pins:`), the shell
rows' markers, the canvases' declarations for each state, the manifest,
and the measure module's contract (seed/extractors/README.md, "The
measure module"). Each file carries, as a table at its head, the row ids
it serves with their marker, state, actor and route — checks/inventory.sh
joins each row to its file by that table — and, per state, the
**literal set** the canvas declares: for the section root and for every
element carrying an identifier (`data-element="<role>"`) every property
the canvas declares on it, the content the canvas draws for the state,
the controls it draws. At collection the file reads nothing but itself,
the harness and design/ (the canvases, for the measure). Reading
design/ is not reading application source.

**One case per surface row, per engine the harness contract declares.**
Each case: sign in as the row's actor through the harness's actor door
(`anonymous` needs none); reach the state's fixture through the harness
(a fixture the harness lacks is the only legal deferral, below); load
the state's route ONCE through the measure module, handing it the
state's literal set — one navigation, one evaluate — and assert that it
answered only `ok` lines: every declared property of every identified
element equal (colours as colours, lengths as computed lengths), the
state's content present, no control drawn by a sibling state present —
the denominator being every control on the page outside the shell
(header, footer, primary navigation, identified by the shell rows'
markers), never the box the implementation labelled — no console error,
no `missing element`, no `missing marker`, no `status` other than the
page's own. **Then the row's pins hook**, on the SAME loaded page:
for each surface row the file declares a hook `pins_<marker>_<state>`
(marker and state with `-` and `/` as `_`) and this pass writes its
body — the row's `pins:` constraints asserted against the loaded page
and the harness's own fixture data, two or three assertions, no
navigation: "card count = page size" reads the page size the fixture
set; "salary shown when the record carries one" reads a fixture record
that carries one and one that does not. An empty hook fails the case
(`pins not authored`); a hook that navigates is a defect.

**A missing route, a 404 or a missing marker is a FAILING case**,
collected and red — never a deferral, never a skip. At init the
instrument is red against the empty scaffold (no route, no marker) and
that red is the proved-red stamp. A surface row may be deferred ONLY as
`owed: prerequisite — <a harness fixture the state needs and the
harness lacks: a provider capture, an external dataset>`, returned as
`unwritable: missing prerequisite`; "no route yet", "not built yet",
"marker missing" are red cases, and the par gate treats such a deferral
as unclassed. Every case id names the row id (the receipt joins cases
to rows by it); every failure names the row.

**Element identifiers (R20).** The instrument maps every identified
canvas element to the app element carrying the same identifier inside
the marker's section and compares EVERY property the canvas declares on
it — layout, spacing, type, colour, radius — in the same single
evaluate; the section root is mapped by its marker; an identifier the
page lacks is `missing element <marker>/<state>/<identifier>`, a failing
case by name; an identifier the page carries that the canvas does not
falls under the stray-control rule. Property count is not the cost —
navigation was; one load per state still. The pins hooks remain for the
constraints that are not paint. An element the designer drew without an
identifier is invisible to the instrument and visible only to the
fidelity grader; the join court reports it, and this pass does not
invent an identifier for it.

**A surface row added later** (a design round, an append) goes through
the standard rhythm exactly: (1) this pass regenerates its screen's file — table,
literal set, the new hook — committed as a free ledger addition and
observed red by a scoped run at that commit; (2) the row's law commit
stamps `proved-red: <that commit>`; (3) the code. Because the file
collects from its own table, the new case exists and runs at step (1).

**What the instrument does not claim.** The measure is against the
tenant the harness provisions; configuration the product provisions
differently outside the harness is a divergence row and a deploy-gate
check, not this file's. It compares declared values, never pixels; it
reads the first element carrying an identifier when the page repeats
one (the hook counts them); font-metric-dependent values are out of its
scope by the owner's ruling on the rendered class.

#### The journeys pass — paid per transition (3.5, R8)

The batch is `journeys`: every journey row, each carrying its narrative
and its `transitions:` list — one numbered item per transition, `<actor>
at <state> · <entry control> · <action> · <next state> · <observable
effect>`; an `(off_screen)` phase is in the narrative and is no
transition. **The authoring rule:** the test runs in the browser (the
harness's engine door), operates the real control for every transition,
and asserts the transition's effect; setup may reach the starting state
through the API or a fixture, and may never perform an action that is
itself a transition; a crawler, worker or webhook journey uses its own
real entry point (HTTP, the queue, the hook) and no browser. **A
`(process)` journey (v0.9.3 3.2)** enters at the product's inbound
boundary — the address it polls, the upload path, the webhook route —
with the external party played by the harness's fake (itself a derived
`difference` row), and asserts each stage's effect where the product
exposes it. **Every journey test and every `(process)` test carries the
harness contract's deployed-shape selector** (`deployed-selector:`,
v0.9.3 3.3): the close run's deployed pass is its receipt, with the
product's declared processes running and nothing inline. **The
shape:** one test per journey row, its steps named for the transitions
in the row's order — a step per numbered transition, each operating that
transition's entry control through the engine door and asserting its
observable effect — so the verdict pass can return one KEPT / BREACHED
per transition and the row-count completeness check applies per
transition. **The return rule:** a transition operated through the API,
a fixture or any door but the engine's is not a paid transition; a
journey whose transitions cannot all be reached returns `unwritable:
missing prerequisite — <the fixture or interface the harness lacks> —
paid at <slice/boundary>` for the missing ones — never a test that stops
early and cites the whole row, never a test that reaches a transition by
API and asserts its effect as if operated. A row's return is one line:
the test path and function when every transition is operated, the
`unwritable:` line otherwise.
