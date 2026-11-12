# The practice product's code, step by step

Each folder holds the files one step adds or changes, exactly as they stand after that step. You never write product code or tests in this lab: you copy a folder over your clone of the code repository and commit it.

```bash
cp -R <this folder>/<step>/. <your clone>/
cd <your clone> && git add -A && git commit -m "<the message below>"
```

| Folder | When | Commit it as | Role |
|---|---|---|---|
| `0-start/` | Once, before the plan: the code repository's first commit, on `main`, pushed | `Initial commit` | anyone |
| `1-skeleton-tests/` | The skeleton ticket, on its branch: the tests of ROW-003 and ROW-004, before any product code | `tests: ROW-003 and ROW-004, the skeleton, before any product code` | TA |
| `2-skeleton-build/` | The skeleton ticket, on the same branch: the product that makes them pass | `save a search, confirm it, read the first digest` | BU |
| `3-header-footer-tests/` | The ticket of ROW-006 (the header and footer on every page), on its branch: the tests alone | `tests: ROW-006, the header and footer on every page, before any product code` | TA |
| `4-header-footer-build/` | The same ticket: the product change | `the header and footer on every page` | BU |
| `5-digest-footer-tests/` | The ticket of ROW-019 (the support address in every digest's footer), on its branch: the tests alone | `tests: ROW-019, the support address in a digest's footer, before any product code` | TA |
| `6-digest-footer-build/` | The same ticket: the product change | `the support address in every digest's footer` | BU |

What the code is: Python 3, Flask pages, SQLite, a worker that sends the morning digest, and one mail module. The tests are pytest with a real browser (Chromium, through Playwright). Each test's name holds its row's id, which is how ViD matches a test to a row: `test_ROW_004_T1_save_sends_confirmation` is ROW-004's first transition.

Things in the tests to notice:

- `3-header-footer-tests/` also changes `tests/measure.py`, a helper that ROW-003's test uses. So ROW-003's test now checks something a little different: that ticket's head report names it on a `retested:` line and gives it a deliberate break of its own.
- The tests of ROW-006 assume two things the spec does not say: the support address is `support@jobdigest.example`, and the footer's help link opens a page at `/help/unsubscribe`. Ask both as questions on the ticket, with these as your defaults, before you commit the tests.
- `5-digest-footer-tests/` moves the support address from ROW-006's test file into the shared helpers. No check of ROW-006 changes, so ROW-006 is not retested.
