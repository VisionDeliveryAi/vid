Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# test-author — pass brief

<!-- v0.9.2 spec 3.1 (R1, R5, R6), 3.4 (R7, R20), 3.5 (R8). The builder
     never writes a ledger test; this pass does, from the rows, and the
     caller commits its files unchanged. -->

```
receives:
  - the batch's rows, verbatim (id · kind · subject · actor/state ·
    marker · obligation · derived-from), and for journeys the
    transitions list (3.5)
  - the effective PRD items the rows derive from (full blocks)
  - each row's authority bundle (v0.9.8, R5): those items, the
    decisions joined to the rows, the owner answers the items'
    `source:` cites and the design states the rows' markers cite —
    sections 2, 3 and 15 of the brief, quoted at its commit
  - the harness client contract: tests/invariants/harness.* public
    surface and its docstrings; the actor kinds; the fixture law
    (CLAUDE.project.md "Fixture law"); the Provenance header rule
  - the files of the rows it is briefed and the declared measure
    module (v0.9.8.1 R19) — with the harness contract above, so the
    pass binds to real fixtures and naming instead of inventing them;
    for a screen row, its screen's canvas and state, and apart from it
    the component canvases that screen uses (brief section 15)
  - the route table (checks/extractors/routes.sh output)
  - for the surface pass: every surface row with its `pins:` (0.9.1
    §3.7b), the canvases (design/screens) and the manifest, the shell
    rows' markers, the measure module's contract (3.4) — the pass
    produces the whole instrument: a file per screen (v0.9.8.1 R18),
    each with its row table and per-state literal set, and the pins
    hook per row
  - the test-writing skill (`skills/vid-test-writing/SKILL.md`),
    preloaded — the brief quotes its boundary rule (R6) verbatim
must not receive:
  - any application source, template, stylesheet or migration
  - the build session's plan, slice decomposition or reasoning
  - another batch's output
  - a previous author's verdict on the same rows (a re-run is never
    told the previous result)
returns, one line per row briefed, never fewer:
  - <row id> → <test path>::<function name>   (the file committed
    unchanged by the caller; the function names the row id)
  - <row id> → unwritable: ambiguous obligation — <why>
  - <row id> → unwritable: missing oracle — <what must be ratified>
  - <row id> → unwritable: missing prerequisite — <fixture or
    interface contract the harness lacks> — paid at <slice/boundary>
  - <row id> → kept — <why its test stands under the changed
    authority>   (a row briefed as authority-changed, v0.9.8 R6)
```

**The brief is a file (v0.9.3 3.1).** The caller writes this pass's brief
as `.vid/briefs/<slice>/test-author-<n>.md` in vid-develop's "Spawned
roles" format — the items listed under `receives:` above, quoted, never
summarised — and runs `sh checks/brief.sh` on it before the spawn. A row
born after the brief's `quoted-at` (the rhythm writes the test before its
row) is quoted from the working tree's INVENTORY.md or listed
`pending-birth: ROW-…`; an item a fix appends with the fix is listed
`pending-append: REQ-…`. A develop or fix test-author brief is written
with `sh checks/brief.sh write --role test-author` (v0.9.7.0.5 3.5),
which does both from the working tree; the init pass is unchanged.

**A `test`-class re-brief (v0.9.3 3.6).** When a verdict returns BREACHED
`class=test` — the product may hold but the test cannot observe the
promise — the caller re-briefs this pass with the row and the grader's
reason, never the verdict's wording as a target; the pass returns
ADDITIONS — new cases, or a strengthened case beside the old one — which
are free ledger additions. Weakening or removing an existing assertion is
never this pass's return: it stays a law change with an owner answer.

**A harness-upgrade brief (v0.9.7.0.10 3.6, R13).** A brief carrying
`## 13 harness upgrade` asks for rule 2's shared setup step: its notes
name the services the harness starts but nobody waits for at start (the
tests' `depends_on` with `condition: service_started`: one the product
calls only while serving a request, or that only some tests use). Write
ONE setup step,
beside the harness client, that waits for such a service to be ready —
bounded, and failing with the service's name when it is not — and route
every existing test that uses one of them through it, so each waits
there and nowhere else. Add the step and its calls only: no assertion is
removed or weakened, and a test that cannot be routed without that is
returned `unwritable:`, never changed. The caller commits the return as
the upgrade's support files, before its law commit.

**What the caller does with the return.** It commits each file
UNCHANGED as a free ledger addition (the rhythm's step 1), observes it
red with a scoped run, and stamps `proved-red`; its commit carries
`Tests-by: test-author <date> <batch>` (checks/hooks/commit-msg refuses
a ledger addition without it; `init` and `builder` are never values). A
file the caller edits before commit is the builder writing a test — the
trailer would be false, and no court can see that. Honest limit, stated
here as the spec requires (3.1c): the trailer and this header are
declared; the proof of separation is the separate-agent spawn the
header mandates.

## Batching, and the four doors (3.1)

Behavior rows by REQ domain, ~25–30 per pass (the grading batch size,
for the same reason: a pass holds one domain's coherence); journeys as
one pass; shell and reachability as one pass; the surface rows as one
pass (below). A pass keeps its batch and returns several small files —
one row, or up to 5 related rows, a file (v0.9.8.1 R18; existing files
stay as they are). Passes run in parallel; the caller collects, commits each
file unchanged as a free ledger addition (rhythm step 1), observes it red
with a scoped run (3.7), and stamps `proved-red`. Every case names the
row id it pays (the receipt joins cases to rows by it); a file pays only
the rows it was briefed. **Callers:** vid-test-inventory §6 (init and
append modes; re-derivation); vid-develop step 1 (a new route, a Tier-0
protection's probe after the guard exists — the probe's fail-first ritual
stays the builder's to RUN, its file the author's to WRITE); vid-fix's
dual-write and rule-shaped tests; vid-add via append mode. One mechanism,
four doors. A row the pass cannot write is returned as one of the three
`unwritable:` lines, never silently and never as a test that asserts less
than the row; the caller records the row `owed: prerequisite — …` (a
missing fixture or interface contract) or brings the ambiguity or the
missing oracle to the sitting.

## The craft — the test-writing skill (v0.9.8, R1)

How a test is made — the test argument and its `cases:` line, the
anti-cheating rules, the techniques, the mistakes catalogue, setup, the
boundary rule, small test files, the surface pass's file per screen and the
journeys pass's shape — is the test-writing skill,
`skills/vid-test-writing/SKILL.md`, preloaded by the `vid:test-author`
agent. This file says what the role receives and returns. Every test
this pass writes or repairs — at init, and later in develop, fix and add —
carries its test argument with its `cases:` line, written then, by the
skill (v0.9.8 amendments 2 and 3).
