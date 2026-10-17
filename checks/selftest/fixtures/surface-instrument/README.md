# The surface-instrument fixture (v0.9.2 3.4, R7, R20)

A toy job board, "Boardlet", on which the surface instrument — ONE ledger
test for every screen, the surface test-author pass's product — can be
produced by a fresh pass and judged by a checker, without a browser. It is
selftest evidence: nothing here is installed into a project, and nothing
here is a stack.

| Path | What |
|---|---|
| `INVENTORY.md` | the rows the pass receives: one shell row, three surface rows (P01/default, P01/empty, P02/default — the last carrying 0.9.1's own pin example) citing `tests/invariants/surfaces.sh` |
| `DESIGN-BRIEF.md` | the 0.9.2 brief with its manifest and pins |
| `design/screens/pack.html`, `design/tokens.css` | the canvases — every styled element identified (`data-element`) — and the tokens the toy resolves `var()` through |
| `harness/harness.sh` | the harness client contract the pass receives: two engines, the actor door, `harness_load` (records every navigation), the fixture's page size and records, `harness_count` / `harness_attr` / `harness_element_text`, the assertion counter, `harness_run_hook` |
| `harness/measure.sh` | the measure module (seed/extractors/README.md's contract) over a page reader: one operation per state, the literal set on stdin, the contract's lines out |
| `harness/run.sh` | the runner: rows × engines → `case <file>::<row>[<engine>] <status> <seconds>` (the results reader's own line), reasons on stderr; `TOY_EMPTY_HOOK` is the checker's probe |
| `harness/rendered.toy.sh` | the rendered extractor — the second reader of the one module |
| `scaffolds/<name>/pages/<actor>[/<fixture>]/<route>.html` | what the app rendered; `correct` is the base the deviations fall back to; `empty` has no page |
| `reference/surfaces.sh` | the known-good instrument the checker must acquit — never handed to a pass |
| `surface-check.sh` | the judge: `sh surface-check.sh <instrument>` |

The scaffolds and what each proves: `correct` (every case passes; six
navigations; every hook asserts) · `stray` (the empty state draws the
search action) · `empty` (no route at all: every case collected and red) ·
`grid-columns` (three columns drawn two) · `missing-element` ·
`extra-identifier` · `units-notation` (rgb for hex, px for rem, em for px:
equal) · `wrong-paint` · `wrong-count` · `no-salary` · `console-error` ·
`missing-marker`.

The procedural half — a FRESH surface pass producing the instrument from
`INVENTORY.md`, the canvases, the manifest and `harness/harness.sh`'s
contract, judged here — is in the vid-test-inventory skill's
`selftest/README.md`; the deterministic half (the reference through the
checker, the checker's polarity, the inventory court accepting rows that
cite the instrument) is `checks/selftest/cases/surface-instrument.sh`.
The toy's page conventions stand in for what init's harness contract
names per stack: the section root carries `data-screen-label="<marker>"`
(as the 0.8.1d run's did), a comment `<!-- console-error: … -->` is the
console, `<!-- status: N -->` the response.
