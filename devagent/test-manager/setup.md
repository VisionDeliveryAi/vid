# The dev setup: the test manager's first job

The test manager's setup pass (v0.26.10.24.1 R3), lifted from skills/vid-test-manager/passes/test-environments.md with one
step before it, and from the harness rules in the comments of templates/docker-compose.test.yml. It runs as a fresh agent
with no other session's reasoning.

```
receives:
  - the dev side's work folder, which is outside any folder of ViD's records
  - the code repository's clone address
  - the ticket: its stack and hosting, its rows and marks, its test differences
must not receive:
  - any other session's reasoning, plans or verdicts
```

Everything below is guidance, apart from one firm point: the record exists before the first reported run, and every
head report of the skeleton declares its engines and environments.

## When it runs

Before the first run of a project, ahead of the test author, whose harness contract the record is. Again when the
environment or the machine changes, after a run killed for memory or lost to the host's process limit, and when the product first starts (step 3);
never only because the cases grew (v0.26.10.28.2, R5).

## The steps

1. **Find the local dev environment**, by looking, not by asking where looking will do: whether a container engine is
   there and running, and its memory; the runtimes and tools the machine has; what the ticket's stack and hosting need;
   the outside services the rows name, and which need a fake in the tests.
2. **Choose how the tests run:** in containers, or directly on the machine. The harness rules apply either way:
   - nothing is installed or fetched when a run starts;
   - each service is ready before what uses it, with a readiness check, never a fixed sleep, and nothing waits for a
     service it does not use;
   - the product is one thing, started the way it will be previewed, and the tests reach it from outside, never as a
     server bound inside the tests' own process;
   - no case runs past the case limit: the runner stops it, reports it failed by its name and goes on (the limit is a
     choice, set from the project's own case times);
   - a test-sized setting the tests use in place of production's is named as a test difference;
   - nothing is left running after a run, and a stop is final: no restart policy on anything in the environment; a failed `stop:` leaves `stop-failed` in the work folder, for a setup pass to mend and remove;
   - never real credentials in a test environment, and no network shared with the host.
3. **Measure, pick and prove** the number of test environments, once the test author's tests exist to measure with, and
   again when the product first starts, when the environment can run more than one. Otherwise one environment.
   - **Measure:** the heaviest selection there is, once, in one environment: peak memory, the engine's total memory,
     what other work uses now, the median case seconds.
   - **Pick:** how many environments fit, at most 3, keeping 2 GB of memory free. `environments:` is this work folder's; the machine's own cap,
     `max-environments:` (v0.26.10.28.2, R1), is whoever runs the dev side's to set, and a setup pass never raises it.
   - **Prove,** only when that is 2 or 3: the measured selection twice at once, overlapping, one per environment. Both
     must write reports and both must equal the measured run's case results. A proof that did not overlap counts for
     nothing. A failed proof leaves one environment, and names what it found: a fixed port or name, a file two runs both
     write, a fixture that is not per run.
   - **Record it** (v0.26.10.24.7 R8): the head's `measured: <cases> <peak MiB> <UTC>`, for the measured selection, and any `environments:` this pass proved. run.sh's memory admission
     reads its peak; a head report with more cases than it calls for no new measure (v0.26.10.28.2, R5).
   - Steps 1, 2, 4 and 5 come before the tests are written; this step amends the record.
4. **Ask once** whoever runs the dev side for what looking could not settle, and record the answer. Short of memory for
   a second environment, tell them, as a question that gates nothing, and go on with one.
5. **Record it,** in the work folder, never in ViD's folder or the product code (below).
6. **Journey and process rows** run with the product's own declared processes up, not inline, so `start:` brings those
   processes up with the product, and the record says how.
7. **Before any product code exists** (the skeleton ticket alone), the environment starts without the product:
   `start:` sees `NO_PRODUCT=1`. A case that reaches for the product errors with a message beginning `setup:`, and the run
   still writes its results report. That is not a failed run. At a step ticket's tests-first commit the product as it
   stands on the base starts, and a missing route, a 404 or a missing element on the row's own page fails on its assertion, which
   is a red. One on the way to the row's promise, a door or an earlier step, is no red: the helper says `setup:`.
8. **The product's entry** (v0.26.10.24.2 R9), named by a setup pass before the builder starts on the first ticket: one file
   or command in the product that `start:` runs to bring it and its declared processes up, and `stop:` runs to take them down.
   It is the builder's to write and keep, no environment file: a new process goes there, with `start:` and `stop:` unchanged.
   Step 3's run at the product's first start waits until it first works.
9. **The test differences** (v0.26.10.24.4 R6): the record keeps every one in use, one `stand-in:` line each, in the report's form, below
   the head, with any set-up door (the door table in `SKILL.md`) and, for a door alone, the row or step that replaces it.

## The record

`dev-setup.txt` in the work folder; run.sh's runs live beside it. Its head is one `key: value` a line, read by run.sh,
which will not run without the first seven keys. Each command runs in the clean checkout, or the builder's clone, under `sh -c`.

```
repo: <the code repository's clone address>
engines: <engine> [<engine> …]             the primary first
environments: <n>
max-environments: <n>                      optional, 3 when absent (v0.26.10.28.2, R1): at most this many test environments up at once on the
                                           machine, counted across every agent and builder of the dev side, whatever its work folder, the deployer's
                                           live instances among them; run.sh's runs wait for a free one, a staging run's chunk (--against) takes none.
                                           Set by whoever runs the dev side, as environments: is; a setup pass never raises it. The count is held in
                                           DEVAGENT_ENVIRONMENTS, ~/.devagent/environments when unset, the same folder for every agent on the machine
case-limit: <seconds>
start: <command>                           returns once the environment is ready; sees NO_PRODUCT
stop: <command>                            takes down all that start: started
run: <command>                             runs ENGINE and, in the runner's own syntax, SELECTION (empty for all), each
                                           case stopped at CASE_LIMIT, and writes its results report to RESULTS, each
                                           failure's message beginning with the assertion's own line, its traceback in the text,
                                           and lets a case's own `covers:` lines through to its output
select-form: <the runner's words>          how to name cases, with <words> where the names go, quoted as the runner needs: a dev manager gives the names alone
entry: <file or command>                   the product's entry (step 8); the builder's own runs need it
services: <command>                        optional: prints a line for each service that died, with its exit code, as
                                           `<name> died … exit <code>`, nothing while all live. 137 means memory
free-memory: <command>                     written with measured:: prints the MiB free now, for run.sh's memory admission
measured: <cases> <peak MiB> <UTC>         written by step 3
leftovers: <command>                       optional: prints what is still up of this run's RUN_ID, nothing when clear
logs: <command>                            optional: prints the environment's log lines with their times and each
                                           service's end state; it runs before stop:
silent-seconds: 1200                       optional, as are the next three: the limits, at develop's values
startup-seconds: 3600
run-seconds: 86400
service-seconds: 15
```

Below that head, in plain words: what was found and the choice, with why; how the environment starts and stops; how the
tests reach the product and read each fake; which fixtures must not change; how the product's processes start; the
measure, pick and prove figures, or the reason for one environment; the answers to step 4.

## Return

The record's path and at most 10 lines: the choice, the engines, the environments, and anything left to ask.
