# vid-create-prd — self-tests

Two kinds of fixture live under `fixtures/`, both procedural (a session
does the work, a checker or a reader judges), never part of
`checks/selftest/run.sh` (that runner is for courts that need no model).

## Seed fixtures (v0.8.1a, spec §12.2) — `seed-*/`, `import-contradiction/`

A `seed.md` (and an `import.md`) the full chain runs on, with an
`expected.md` in prose naming what the produced PRD.md must show. Judged
by reading; the acceptance record in the release's build notes (kept in the
repository's docs/, not shipped) carries the runs.

## Calibration fixtures (v0.9.1 3.10, 3.2, 3.5) — the reviewers and the wording lens, defective AND acceptable

Each directory holds a court-green `PRD.md` in the enriched grammar and
an `expected.md` of assertions over the findings a FRESH pass returns.
The checker is `pass-check.sh` (deterministic; grammar in its header).
The one kind of fixture the reviewers never had before 0.9.1 is the one
whose correct output is zero findings — `clean-set/` — and it is the
point: a reviewer that can accept good work is demonstrated, not
assumed.

| Fixture | Pass(es) | Pins |
|---|---|---|
| `clean-set` | red-team, audit, review | empty findings block from all three (the finiteness mandate observed) |
| `deliberate-deferral` | audit, review | a seed capability the owner deferred (A-002, Explicitly not MVP, NG-003) is never reported as an omission (10b) |
| `engineering-choice` | red-team, audit, review | a record explicitly silent on an ordinary implementation choice (A-008) draws no finding (10c) |
| `material-contradiction` | review | REQ-017 vs REQ-004/006/008 reported blocking with a 10a-shaped evidence line; every finding names the contradiction |
| `append-contradiction` (3.2) | review, `mode: delta` | one append: a proposal item contradicting REQ-004 (fix_from_record, both ids) and a ruling naming REQ-005 and REQ-006 that amends only REQ-005 (the propagation finding names REQ-006) — exactly two findings |
| `append-clean` (3.2) | review, `mode: delta` | the same ruling propagated to both items, the examined neighbours under `unchanged:` — empty findings block |
| `wording-arms` (3.5) | wording lens | REQ-018's three mechanism-worded arms come back harm-worded under an `arms:` that keeps all three (retained or strengthened) — one ```vid-prd-rewordings line |

### The protocol — stochastic, labelled as such

The passes are model calls; their output varies between runs. The case
therefore runs as vid-test-inventory's derive-check protocol does: a
fresh agent reviews, the checker judges, and the pasted checker output
lands in the build notes with the model id and a plain statement of
whether the agent was fresh.

1. Copy the fixture's `PRD.md` into a scratch directory.
2. Spawn a FRESH agent (Agent tool, general-purpose — the R17 mechanism:
   no authoring- or build-session context, nothing the calling session
   believes, never the previous verdict) with: the pass file under
   `../passes/` (its `receives:` line says which PRD sections to hand
   over — for the red-team the seed, thesis, journeys, mechanisms and
   ledger; for the audit the ratified thesis, the items, the ledger and
   the contract with `../CONTRACT-CATALOG.md`; for the review the whole
   effective set; for the review in `mode: delta` — the `append-*`
   fixtures — the effective set and, as the DELTA, the one dated append
   under `## Appends`; for the wording lens every demand item with its statement and fail-if, the seed and the thesis — the whole PRD carries them), the scratch path, and this output instruction only:
   *write your findings to `<scratch>/findings-<pass>.md` as one ```vid-prd-findings block in the PRD's findings grammar — `F-NN | <pass> | severity | target | - | evidence: … | triage: …` (triage on the review only) — an EMPTY block when you have no finding; write nothing else to disk.* For the wording lens the instruction names its own block instead: *one ```vid-prd-rewordings block, `REQ-NNN | fail-if: … | arms: …` per rewording, EMPTY when nothing is worded as a mechanism's absence.* The prompt names no expectation, no fixture name, no count.
3. Judge: `sh pass-check.sh fixtures/<name> <scratch>/findings-<pass>.md`.
   Exit 0 = every expectation held; one line per expectation.

Paste the checker output into the release's build notes (kept in the
repository's docs/, not shipped) with the model id that reviewed. A run whose agent
was not fresh, or whose prompt carried more than the brief and the
artifact, is stated plainly and does not count.

`checks/selftest/cases/passes.sh` pins the static half: every
calibration fixture exists, is court-green, carries an `expected.md`,
and `pass-check.sh` convicts a known-bad output and acquits a known-good
one — so the checker itself is never vacuous.
