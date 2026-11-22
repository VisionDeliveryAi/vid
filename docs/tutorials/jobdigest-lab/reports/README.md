# The reports you write by hand

Your test runner writes the `cases-chromium.xml` files. Everything else in a report is a few lines you write yourself. This folder holds each of them as it was sent in a real walk of this lab, with the commit ids left for you to fill in. Copy a file into the report's folder under the name the table gives, put in the full commit id, and push the folder with `env/push-report.sh`.

The ticket and issue numbers in a report's id are yours: they are whatever GitHub gave your issues. The head is the commit of `main` that holds the ticket's work, after the merge.

## The skeleton ticket

| Report | Folder (its id) | What goes in it |
|---|---|---|
| Head report, with the skeleton's breaks (T3, T4) | `step-<ticket>-<first 12 of the commit of main>-1` | `cases-chromium.xml` from the run at the head; `results.txt` = `1-skeleton/head-results.txt`; `faults/ROW-003/cases-chromium.xml`, the run with `1-skeleton/fault-ROW-003.patch` planted; `faults/ROW-004/cases-chromium.xml`, the run with `1-skeleton/fault-ROW-004.patch` planted. No `control.txt`: the skeleton's breaks have no control |
| Grade (T5) | `grade-step-<ticket>-<first 12 of the commit of main>-1` | `grade.txt` = `1-skeleton/grade.txt` |

The skeleton's head report is the one that declares your setup: `engines: chromium` and `environments: 1`, and one `stand-in:` line for each difference between these tests and production.

## The header-and-footer ticket (ROW-006)

| Report | Folder (its id) | What goes in it |
|---|---|---|
| Red run (T2) | `red-<ticket>-1` | `cases-chromium.xml` from the run at the tests-first commit; `results.txt` = `2-header-footer/red-results.txt` |
| Head report (T3, T4) | `step-<ticket>-<first 12 of the commit of main>-1` | `cases-chromium.xml` from the run at the head; `results.txt` = `2-header-footer/head-results.txt`; `faults/ROW-003/cases-chromium.xml`, the run with `2-header-footer/fault-ROW-003.patch` planted and `-k "ROW_003 or ROW_006"`; `faults/ROW-003/control.txt` = `2-header-footer/control.txt` |
| Grade (T5) | `grade-step-<ticket>-<first 12 of the commit of main>-1` | `grade.txt` = `2-header-footer/grade.txt` |

Why ROW-003 gets a break here: the tests commit changes a helper ROW-003's test uses, so the head report names ROW-003 on its `retested:` line, and a retested row needs a deliberate break. ROW-006 needs none: its red run showed its test can fail.

## The reached-rows ticket (ROW-006, after the spec change)

| Report | Folder (its id) | What goes in it |
|---|---|---|
| Head report (T3) | `step-<ticket>-<first 12 of the commit of main>-1` | `cases-chromium.xml` from the run at the head; `results.txt` = `3-reached/head-results.txt` |

The test is kept, so nothing is retested and no break is needed. There is no grade on this kind of ticket. A pull request needs at least one commit, so the test author's decision to keep the test goes in an empty commit (`git commit --allow-empty`). In GitHub manual the change sends ROW-006 in a follow-up ticket instead, which the tutorial leaves open; these lines are the checked run's.

## The digest-footer ticket (ROW-019)

| Report | Folder (its id) | What goes in it |
|---|---|---|
| Red run (T2) | `red-<ticket>-1` | `cases-chromium.xml` from the run at the tests-first commit; `results.txt` = `4-digest-footer/red-results.txt` |
| Head report (T3) | `step-<ticket>-<first 12 of the commit of main>-1` | `cases-chromium.xml` from the run at the head; `results.txt` = `4-digest-footer/head-results.txt` |
| Grade (T5) | `grade-step-<ticket>-<first 12 of the commit of main>-1` | `grade.txt` = `4-digest-footer/grade.txt` |

## The closes

Each close issue lists its chunks. For each chunk: `req-<close issue>-<chunk>-1`, holding `cases-chromium.xml` from the run of that chunk's rows at the commit the issue names (`-k` with the rows' ids, `-` written as `_`, joined by ` or `), and `results.txt` = `5-closes/results.txt`. Comment `vid: started` before the first chunk and `vid: reported <chunk>-1` after each.

A stage close also asks a chunk `p1cx`, every other test of the suite. Run it with `-k` naming every row of the other chunks with `not … and not …`. When no other test exists, the report holds no test case at all, and that is a correct report.

## No sort in this walk

Every line of the three grades here reads `kept`, so no ticket needed a sort and there is no `sorted.txt`. Your own grade may differ: grade what you see, not what this folder holds. A `breached test` line needs a break planted before you ask for the decision; a `breached product` or `unclear` line needs a sort before you ask for the decision.
