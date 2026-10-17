# vid-design — self-tests

Calibration fixtures for the design-vs-PRD consistency pass (v0.9.1
spec 3.3), procedural like vid-create-prd's: a FRESH agent runs the
pass over a fixture pack, `pass-check.sh` judges its lines, and the
pasted checker output lands in the build notes with the model id.
Never part of `checks/selftest/run.sh`; `checks/selftest/cases/
design-consistency.sh` pins the static half (each pack joins clean
against its manifest, carries an `expected.md`, and the checker convicts
a known-bad output and acquits a known-good one) and the court's refusal
of an unfinished `DESIGN-AMENDMENT-BRIEF.md`.

Three packs read the same PRD, `fixtures/shortlink-PRD.md` (the
create-prd clean set: court-green, 24 items); `configured-value` reads
the `PRD.md` beside its brief (that PRD plus one append).

| Fixture | Pack | Pins |
|---|---|---|
| `forbidden-control` | P03 default + confirm; the deletion page draws an "Edit target" control | exactly one line naming P03/default and REQ-006 or NG-001 (class a: draws what a row forbids) |
| `clean-pack` | the same page without that control, plus PRD-silent details | EMPTY — a clean pack returns a clean verdict |
| `two-round` | round 1: P02 and P03 with one support address; `delta/`: P03 redrawn with another | exactly one line, `P03/default · P02/default · canvas says … · canvas says …` (class b, PRD-silent detail); P02 is context, never a target on its own |
| `configured-value` | the deletion page with the footer's support address drawn as a literal; reads its OWN `PRD.md` (the shared PRD plus one append: REQ-025 makes the address operator-entered at deployment) | exactly one line, `P03/default · REQ-025 · canvas asserts: support@shortlink.example · row makes it: …` (class c, v0.9.2 3.13, R22) |

### The protocol — stochastic, labelled as such

1. Copy the fixture directory and `shortlink-PRD.md` into a scratch
   directory.
2. Spawn a FRESH agent (Agent tool, general-purpose — the R17
   mechanism: no authoring- or build-session context, nothing the
   calling session believes, never the previous verdict) with: the pass
   file `../passes/consistency.md`, the canvases (for `two-round`: the
   `delta/` canvas as the DELTA and `design/screens/p02.html` as
   `context:`), `DESIGN-BRIEF.md` (its manifest is the marker→REQ join),
   the PRD (the rows the markers serve, the `## Actors and journeys`
   section, the answer ledger), and this output instruction only:
   *reply with exactly one ```vid-design-disagreements block — one line
   per disagreement in the brief's line shape, EMPTY when you have none —
   and nothing else; write nothing to disk.* The prompt names no
   expectation, no fixture name, no count.
3. Judge: `sh pass-check.sh fixtures/<name> <scratch>/lines.md`. Exit
   0 = every expectation held; one line per expectation.

The sitting half — the owner rules the lines and the verb writes
`DESIGN-AMENDMENT-BRIEF.md` — is exercised with a scripted owner and
recorded as such: ruled `PRD wins`, the brief holds one design
instruction and no PRD row; ruled `design wins`, one AMENDED row (with
`arms:`) and no design instruction; a clean pack writes no brief.
