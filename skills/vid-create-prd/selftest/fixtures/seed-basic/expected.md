# Expected — seed-basic (spec §12.2 case 7: falsifier completeness)

A full chain run from this seed must produce a ratified PRD.md in which:

- **every demand item carries exactly one `fail-if:` naming a failing
  case** — zero Fail-ifs of the "works as expected" / "meets the
  requirement" shape (checked by reading, and by the court's two-way
  join 3);
- the run pauses exactly three times after the interview batch, each
  pause ending in a commit whose sha appears in the Ratifications
  section (case 12);
- the pause-1 contract sitting presents all 19 catalog floor dimensions
  and both `case-by-case` entries are explicitly ruled in or out
  (case 15);
- the court is green at each of the three ratification commits.
