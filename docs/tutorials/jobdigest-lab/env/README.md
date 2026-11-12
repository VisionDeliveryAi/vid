# The test setup

A self-contained test environment for the practice product, in Docker. It is the dev side's own: ViD never sees it, only the reports it produces.

**You need:** Docker (Docker Desktop on macOS, or Docker Engine with the compose plugin on Linux), git, and a POSIX shell. About 1.6 GB of disk for the two images.

## Run the tests of one commit

```bash
sh <this folder>/run-tests.sh <your clone> <commit> <report folder>
```

- It makes a clean copy of exactly that commit (`git archive`), so what you have not committed is never tested.
- It starts the two fakes (a mail provider that records each message, and a job feed), starts the product from its `Procfile` when the commit has one, runs every test in Chromium, and writes `<report folder>/cases-chromium.xml`. Then it removes everything it started.
- The first run fetches the base image and builds the two images (about 2 minutes). That is the only step that downloads anything: the test network has no way out.
- Exit 0: every test passed. Exit 1: some failed. Exit 2: the run itself could not be made.
- At a commit with no product yet (tests only), every test that needs the product fails with a message that begins `setup:`. That is a test that could not run, not a red.

Two options:

```bash
# only the tests whose names match (pytest's -k)
sh <this folder>/run-tests.sh <your clone> <commit> <report folder> -k "ROW_006 or ROW_003_S01_saved"

# a deliberate break: apply a patch to the clean copy first, then run
sh <this folder>/run-tests.sh <your clone> <commit> <report folder> -k "ROW_006 or ROW_003_S01_saved" --fault <patch>
```

## Push a report

```bash
sh <this folder>/push-report.sh <your code repository's address> <report folder>
```

The report folder must be named by the report's id (`red-7-1`, `pr-8-032e923e5dd7-1`, …) and hold `results.txt` and its cases files. The script copies it into a new, empty folder, makes one commit there and pushes it as the branch `vid-results/<id>`. Your working branch is never touched, and each branch holds that one folder alone.

## What is in here

| File | What it is |
|---|---|
| `run-tests.sh` | The one command above |
| `push-report.sh` | Pushes one report folder as its own branch |
| `compose.yml` | The environment: mail and feed fakes, the product, the tests, on a network with no way out |
| `product.Dockerfile`, `tests.Dockerfile` | The two images, with pinned versions |
| `product.sh` | Starts every line of the product's `Procfile` in one container |
| `tests-in-container.sh` | Runs pytest in the browser and writes the report |
| `finish_report.py` | Keeps `setup:` at the start of a failure's message, where ViD reads it |
| `fakes.py` | The fakes, standard library only |

## The differences between these tests and production

Each is a `stand-in:` line in the first head report that uses it:

```
stand-in: the mail provider — a fake that records each message — the real mail provider
stand-in: the digest schedule — every 2 seconds — each morning
stand-in: the store — a temporary file per run — a platform disk
stand-in: the addresses — plain http on the test network — the platform's https
stand-in: the feed — a fake — the partner feed
```
