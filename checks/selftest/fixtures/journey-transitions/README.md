# The journey-transitions fixture (v0.9.2 3.5, R8; 3.1's completeness)

A five-row batch of the Boardlet toy — one journey row with four
`transitions:` and four behavior rows of the applications domain — on
which a fresh test-author pass authors and a checker judges its RETURN:
one line per row, the journey operated through the engine door for every
transition, one verdict per transition. Selftest evidence; nothing here is
installed or a stack.

| Path | What |
|---|---|
| `INVENTORY.md`, `ITEMS.md` | the rows the pass receives and the items they derive from |
| `harness/harness.sh` | the harness client contract: the ENGINE door (`harness_press`, `harness_page`, `harness_text`), the API door (`harness_api`), setup (`harness_reset`, `harness_actor` — two members, `member` and `other-member`, each with their own applications), the assertion counter; the toy product's state in files; `TOY_PRODUCT=empty` is the empty scaffold |
| `harness/run.sh` | the runner: a journey's steps one case per transition (`::ROW-010[transition=k/4]`), behavior cases by row; the log carries `transition <row> <k> begin|end` |
| `reference/` | the known-good: `journeys.sh`, `applications.sh`, `RETURN.md` (five lines), `VERDICTS.md` (four lines) — never handed to a pass |
| `return-check.sh` | the judge: `sh return-check.sh <RETURN.md> [--tests <dir>] [--verdicts <file>] [--product empty]` |

The procedural half — a FRESH pass over `INVENTORY.md`, `ITEMS.md` and the
harness contract, its RETURN and files judged here — follows the
vid-test-inventory skill's `selftest/README.md`; the deterministic half is
`checks/selftest/cases/journey-transitions.sh`.
