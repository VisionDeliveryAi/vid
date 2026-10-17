# brief-verdict — the brief fixture (v0.9.3 spec 3.1, §7 case 1)

A TOY project, never installed: Linkling, a link shortener in shell
(`tree/app/links.sh`), with the project files a ViD project carries —
CLAUDE.md, PRD.md (24 items, two non-goals), DECISIONS.md (20 entries),
ARCHITECTURE.md, INVENTORY.md under `grammar: 0.9.3` — its ledger
(`tree/tests/invariants/links.sh`, which prints the results reader's own
`case` lines) and a fixture results reader. The spec a whole-reading agent
is told to read is about 2,000 words; the four rows a slice grader
verdicts, ROW-101..ROW-104, need a small part of it.

Two uses:

1. **`checks/selftest/cases/brief.sh`** copies `tree/` into a scratch
   repository and writes briefs against its commits — the checker's
   convictions and acquittals (case 1).
2. **The stochastic half of Phase C's cut line** (0.9.1 §3.10's protocol,
   run by the builder, recorded in V0.9.3-BUILD-NOTES.md): fresh graders,
   each given only the repository path and a grader brief in the 3.1
   format, return one verdict per row; a control grader is given the
   repository path, the rows by id and the project's whole-reading rule.
   Counts: verdicts returned per rows briefed, classes, tokens per pass.

`expected.md` states what a sound verdict says. It is never shown to a
grader.
