# The reports you write by hand

Your test runner writes the `cases-chromium.xml` files. Everything else in a report is a few lines you write yourself. This folder holds each of them as it was sent in a real walk of this lab, with the commit ids left for you to fill in. Copy a file into the report's folder under the name the table gives, put in the full commit id, and push the folder with `env/push-report.sh`.

The ticket and issue numbers in a report's id are yours: they are whatever GitHub gave your issues. The results are run at the commit of `main` that holds the ticket's work, after the merge. ViD reviews each ticket itself: there is no grade and no sort to write.

## What each ticket needs

Each is one report, `step-<ticket>-<first 12 of the commit of main>-1`: `cases-chromium.xml` from the run at that commit, and its `results.txt`.

| Ticket | `results.txt` is |
|---|---|
| The skeleton | `1-skeleton/head-results.txt`. It declares your setup: `engines: chromium` and `environments: 1`, and one `stand-in:` line for each difference between these tests and production |
| The header and footer (ROW-006) | `2-header-footer/head-results.txt` |
| The digest footer (ROW-019) | `4-digest-footer/head-results.txt` |

`3-reached/head-results.txt` is the checked run's, from a reached-rows ticket of ROW-006 after the spec change. In GitHub manual the change sends ROW-006 in a follow-up ticket instead, which the tutorial leaves open.

## The closes

Each close issue lists its chunks. For each chunk: `req-<close issue>-<chunk>-1`, holding `cases-chromium.xml` from the run of that chunk's rows at the commit the issue names (`-k` with the rows' ids, `-` written as `_`, joined by ` or `), and `results.txt` = `5-closes/results.txt`. Comment `vid: started` before the first chunk and `vid: reported <chunk>-1` after each.

A stage close also asks a chunk `p1cx`, every other test of the suite. Run it with `-k` naming every row of the other chunks with `not … and not …`. When no other test exists, the results file holds no test case; add the line `none left` to its `results.txt`, and that is a correct report.

## Optional: read when you send it

Nothing is missing without these, and the tutorial sends none.

| What | Where it goes | What goes in it |
|---|---|---|
| A run that failed first, for ROW-006 or ROW-019 | A report of its own, `red-<ticket>-1` | `cases-chromium.xml` from the run at the commit that holds the tests alone, before any product code; `results.txt` = `2-header-footer/red-results.txt` or `4-digest-footer/red-results.txt` |
| A deliberate break of the skeleton's rows | In the skeleton's report, before you push it | `faults/ROW-003/cases-chromium.xml`, the run with `1-skeleton/fault-ROW-003.patch` planted; `faults/ROW-004/cases-chromium.xml`, the run with `1-skeleton/fault-ROW-004.patch` planted |
| A deliberate break of ROW-003 | In the header and footer's report, before you push it | `faults/ROW-003/cases-chromium.xml`, the run with `2-header-footer/fault-ROW-003.patch` planted and `-k "ROW_003 or ROW_006"`; `faults/ROW-003/control.txt` = `2-header-footer/control.txt` |

A break is planted with `run-tests.sh`'s `--fault` option, in the clean copy alone; it never reaches `main`. **A failure is the result you want:** it shows the test can catch the defect. A break the test misses makes its row `failing, a weak test`.
