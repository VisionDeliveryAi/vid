Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# test-environments — pass brief

<!-- v0.9.6 spec 3.9 (R9). Develop's own step, spawned once by the
     orchestrating session at the run's home: it sets up two or three test
     environments so test runs never queue behind one, and proves they run
     side by side before a second is used. It reads Docker and Compose
     only. The owner's question, when memory is short, is the calling
     session's to ask; this pass only returns its figures. -->

```
receives:
  - the repository path — the run's home, where .vid/RUN-STATE.md holds
    `plan: required`
  - the selector of a short selection that runs to its end (a few rows
    of the first step, green or red), in the runner's own syntax
  - the rows that selection runs (their ROW ids), and, when they are
    slow, the case seconds they are expected to take (v0.9.7.0.2 3.4)
must not receive:
  - the build session's plan prose, verdicts or attempt records
```

## When the calling session spawns it

- At develop's start: after RUN-STATE is written (with `plan: required`)
  and the plan block exists, before the first test run.
- Again when `docker-compose.test.yml` changes, when a run is killed for
  memory (an `incident … memory` event), or when the session judges the
  machine changed.

## The steps

1. **Measure.** First `sh checks/testenv.sh heaviest` names the heaviest
   case in the home's receipt history (the largest recorded seconds), or
   none. The selection measured is the one received with that case added,
   in the runner's syntax, and its row added to `--rows` (v0.9.7.0.12): the
   memory measured is then a heavy run's, and `prove` runs the same
   selection. `sh checks/testenv.sh measure --rows <ROW-id,…>
   [--expect <seconds>] -- <selector>` runs the
   selection once in one environment, as a request to the test manager
   (an estimate, a cap and a ticket), samples its memory every 5 s, and
   records its peak, the Compose version, whether Compose takes the
   `!reset` tag, the median case seconds, Docker's total memory and what
   other containers use now. A measuring run that publishes no receipt is
   refused: return that, and the selection's output. So is one whose
   receipt lacks the heaviest case, naming it: add it and measure again.
2. **Pick.** `sh checks/testenv.sh pick` prints `k` — how many
   environments fit, at most 3, with the headroom `.vid/budget
   memory-headroom-mb` keeps free (default 2048 MB) — and what Docker's
   memory would need to be for 2 and for 3.
3. **Prove** — only when `k` is 2 or 3: `sh checks/testenv.sh prove`. It
   requests the measured selection and its rows twice at once, one per environment; both
   must publish and both must give exactly the measured run's case
   results. With `k` = 1 there is nothing to prove.
4. **Record.** `sh checks/testenv.sh record` writes `stacks`,
   `unverified-rows` (60 per environment) and `testenv=proved
   harness=<hash>` to `.vid/budget`, and the `testenv` event. Without a
   passed proof it records one environment. The proof holds for that
   harness only (v0.9.7.0.10): once the harness file changes, admission
   uses one environment until this step proves again.

Never change `docker-compose.test.yml`, any file init wrote, or another
project's containers: the step only reads them. When the proof fails,
`stacks` stays 1 and the failure is already recorded as an `incident`;
name what it says — a fixed host port or container name the override
could not reset, a file two runs both write, a fixture that is not per
run — and stop.

## Return

The four commands' last lines verbatim — `testenv measure …`, `testenv
pick …` (and its `testenv short: …` line when there is one), `testenv
prove …` or the proof's refusal, `testenv record …` — and nothing else.

## What the calling session does with it

- A `testenv short:` line (fewer than 2 fit, and more Docker memory would
  allow 2 or more): ask the owner once, as a question that gates nothing
  — a `Q<n>` line in RUN-STATE whose `gates` names no rows, and its
  event — in these words, with N and K from that line:

  > Raise Docker's memory to N GB so tests run in K environments instead of 1?

  Keep building with one environment; the answer re-runs this pass.
- A failed proof: repair what it names, or go on with one environment.
