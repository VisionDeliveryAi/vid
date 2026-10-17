Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# consistency — pass brief

<!-- v0.9.1 spec 3.3 (R3): design-vs-PRD consistency at import. The
     paragraph under "The pass" is the spec's text verbatim; the rest is
     the mechanism — what the context receives and how it answers. -->

mode: import | delta
receives: each canvas section with its marker; the effective rows its marker serves (from the manifest's marker→REQ join — the manifest is handed over for that join, with each row's `pins:`, the constraints the state must show); the `## Actors and journeys` section; the rulings ledger (the effective ```vid-prd-answers rows). mode delta (a standalone round): the DELTA canvases plus every existing canvas section that shares a component or a state with the delta, and C00 always, listed as `context:` — a context marker cannot be the target of a finding on its own; a disagreement always names a delta marker.
must not receive: the authoring session's reasoning; the brief-derivation session's reasoning; any previous verdict; an earlier round's DESIGN-AMENDMENT-BRIEF.md.

## The pass

**Consistency pass (after `design-join.sh` exits clean).** A fresh
context receives each canvas section with its marker, the effective
rows its marker serves (from the manifest's marker→REQ join), the
`## Actors and journeys` section, and the rulings ledger. It reports
DISAGREEMENTS only, defined narrowly: **(a)** a canvas contradicting an
effective row or ruling — it draws what a row forbids, draws a product
rule differently from the row (a count, an ordering, a state's
meaning, who may act), or omits a state or control a row demands;
**(b)** the pack contradicting itself — one element drawn two ways on
two canvases. **A canvas supplying a detail the PRD does not state is
not a disagreement**: it routes to the "decisions embodied" read-back
and lands as a DECISIONS entry, no ruling, unless the read-back finds
it embodies a product rule (then a proposed item, as today). One line
per disagreement: `marker · item id · canvas says · row says`. The
finiteness mandate holds; a clean pack returns a clean verdict.

**(c) Design-asserted configuration values (v0.9.2 3.13, R22).** A
canvas asserting a configuration VALUE — a colour, a name, a switch,
seeded content — that an effective row makes tenant- or operator-entered,
or that the PRD gives a placeholder default: the canvas draws the value
as if the product fixed it. It is a disagreement line, `marker · item id
· canvas asserts: <value> · row makes it: <whose input>`. A `{{
placeholder }}` where the value would stand is not this class; a literal
is. The class adds a consequence at the sitting, never a ruling value —
the four rulings stand and the amendment brief's two halves carry what
follows (vid-design §3).

## The answer — one line per disagreement, nothing else

One fenced block, ```vid-design-disagreements, one line per
disagreement, the fields separated by ` · ` (a middle dot with a space
each side):

    P03/default · REQ-006 · canvas says: an Edit target control beside Remove · row says: one Remove control; NG-001 forbids editing a target
    P03/default · P02/default · canvas says: footer address help@… · canvas says: footer address support@…

- class (a): the first field is the canvas marker (`ID/state`), the
  second the item or answer id the canvas disagrees with, then what the
  canvas draws and what the row says — both quoted or paraphrased
  closely enough that the owner can rule from the line alone;
- class (b): the first field is the delta canvas marker, the second the
  other canvas marker, then the two drawings — `canvas says … · canvas
  says …`; in mode delta the first marker is always a delta marker;
- class (c): the canvas marker, the item or answer id that makes the
  value an input (or gives the placeholder), `canvas asserts: <the literal
  as drawn>`, `row makes it: <whose input — tenant-entered,
  operator-entered at <step>, a placeholder default>`.

An EMPTY block is the clean verdict; a missing block is no verdict. A
line names one disagreement — a control that two rows forbid is one
line naming both ids, never two lines. Nothing else is written or
returned: no summary, no count, no detail the PRD does not state.
