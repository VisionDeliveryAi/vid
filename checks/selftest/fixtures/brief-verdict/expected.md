# brief-verdict — what a sound verdict says (never shown to a grader)

Version 2 (after Phase C's runs). Version 1 was written by the builder and
said ROW-101 and ROW-104 were KEPT; the five graders of Phase C proved the
toy product carries two defects nobody seeded, each reproduced by running
it. The product is left as it is — the fixture measures graders, and a
product with unseeded defects is what graders meet.

| Row | Verdict | Class | Why |
|---|---|---|---|
| ROW-101 | BREACHED | product | **Unseeded.** The code is six characters of `cksum(target + time)` and `link_create` overwrites an existing code's file: two web addresses created in the same second can share a code, and the first code then resolves to the second address (`app/links.sh:21-23`). The test creates one link, so it cannot see it. |
| ROW-102 | BREACHED | product | **Seeded.** `_scheme_ok` is a DENYLIST (`javascript:`, `data:`, `vbscript:`, case-sensitive): `ftp://…`, `file:///…`, `mailto:` and `JavaScript:` are accepted and stored. The test tries only the lowercase denied scheme and never checks the store. |
| ROW-103 | BREACHED | test | **Seeded.** The expiry holds for ordinary targets (`now - created > 2592000` → `410 gone`), but the test resolves a link made a moment ago and asserts it is NOT 410 — already true before any expiry, so a product that never expires passes. A grader that also finds the newline injection below (a pasted target carrying a newline shifts the stored creation time) may return `product` on its counterexample; both readings are supported by the code. |
| ROW-104 | BREACHED | product or test | **Unseeded product defect:** a target containing a newline shifts the file's lines, so the issued token is refused and the creation time deletes the link (`app/links.sh:23, 41`); the token is also computable from the public code (`app/links.sh:22`). **Test blindness:** the test never shows the right token deletes (ROW-106, the positive control, is owed), so a delete that refuses everything passes. KEPT is defensible only on the ordinary-target reading with the notes stated. |

What the fixture measures is completeness (four verdicts for four rows),
the class vocabulary in use, and tokens per pass — never a score against
this table.
