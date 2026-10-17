# work-package — the fixed work package, the release bar (v0.9.3 spec §7 case 15, R21)

A fixture product, never installed: JobDigest — two public source feeds
pulled into one listing store, subscribers' saved searches, a daily digest
by mail, an operator who pulls a listing on a takedown request. It names no
stack; the evaluator chooses one at init.

What it carries (spec §7 case 15): **one feed boundary** (Feed A and Feed
B, pulled by the scheduler), **one queue** (`work`, consumed by the
worker), **one schedule** (the daily run), **two actor journeys** (the
Subscriber's and the Operator's, `## Actors and journeys`), **one
deploy-owed row** (the mail provider's credentials are `not-yet`, so its
seam's obligations are born `owed: paid by /vid deploy gate 2 — …`).
`PRD.md` is enriched and ratified (court-green: `sh checks/prd.sh PRD.md
--report` prints `gaps=0`), so `/vid init` adopts it without re-interviewing
the product.

## The run (the protocol)

1. A scratch directory holding `PRD.md` and `ARCHITECTURE.md` only, a
   container engine up, the plugin at this release.
2. `/vid init` in that directory. The owner's technical answers are
   `owner-answers.md` (the evaluator chooses the stack there, before the
   run, and records it); the three inventory sittings ratify every derived
   row at recognition speed.
3. The watcher, which develop starts itself (v0.9.7.0.9); its notices are
   timestamped `observe: notice —` lines in the run's heartbeat.
4. `/vid develop` to completion, the seeds applied at their named points.
5. The end grade develop triggers, then the counts.

`run-package.sh` drives steps 1–4 with headless sessions and the seeds; read it before running it.

## The seeds (applied by the evaluator at named points)

| Seed | Where | What is applied | Expected to be caught |
|---|---|---|---|
| (a) a routing with no consumer | after the first slice closes | one commit routing the digest task to a second queue, `mail`, that no declared process consumes (made by the evaluator in the product's own routing declaration) | at the commit — the topology census blocks it |
| (b) the session killed mid-slice | slice 2, after its first builder commit | the develop session's process is killed | the watcher records a notice within an interval; a fresh session resumes from `sh checks/observe.sh resume` |
| (c) a ledger run killed mid-way | slice 2's close run | the tests container is killed while the runner is mid-ledger | no report is published (`status=` outside `completed:`); the run is re-paid |
| (d) an owner append amending one Fail-if on a KEPT row whose case stays green | between slices 2 and 3 | `owner-answers.md`'s append for REQ-013 (seven days → five), committed as the owner's answer | the post-commit hook records `amended`; the row returns unverdicted and is re-verdicted blind |
| (e) the deploy-owed row | at init (by construction) | the mail seam's `credentials: not-yet` | present and named in every closure; never claimed by a sandbox test |
| (f) a row whose module no slice planned | at init (by construction) | REQ-032's operator view needs a module the seam table does not list | discovered by the builder and recorded in RUN-STATE's dependencies the moment it is found |

## The counts (counts.md — filled after the run, never a score)

The closure line at every slice close and at completion; minutes from the
kill in (b) to the notification and to resumed work; tokens by phase and
wall by role (`ledger-run … role=`); each seeded defect caught or not, and
where (commit, close, grade); whether a hostility probe was claimed before
its guard existed (the guard block in `inventory.sh --report`); the
RUN-STATE record of (f), quoted.
