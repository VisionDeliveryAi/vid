---
name: vid-deploy
description: Ship a ViD project — the only verb that touches anything real. Two targets — deploy to staging (fast and repeatable, the rows changed since the last full pass on a scoped run, gate 2's real action per provider seam) and deploy to production (staging's exact commit, the full run, the re-grade, gate 1's rehearsal on a restored production backup and the owner-confirmed cutover, gate 3); a bare deploy is staging. Greenfield first deploy splits along the same line; setting the test site up (where it runs, asked at init; the staging and production build-out; DEPLOYMENT.md) is the internal skill vid-staging-setup's. Never runs implicitly, except a staging deploy at a stage close, or at 'continue' while staging is being set up, under the owner's standing authorization. Use when the owner says "vid deploy", "deploy to staging", "deploy to production", "deploy this", "go live", or "ship it".
---

# /vid deploy

The shipping verb — the only verb that touches anything real. DEPLOY is not
TEST (the ledger: `sh checks/test.sh`, Docker-only, deterministic) and not
GRADE (adversarial fresh-context review). Deploy is the inverse of grade:
grade is always safe to run, so it may run anytime, unattended; deploy never runs on its own, with one exception: once the owner has
said that ViD may deploy to staging on its own (the standing staging
authorization, withdrawn by a word), develop sets staging up and
deploys each closed stage to it at its close, and retries the setup
when the owner says "continue". Nothing else may invoke it. Production
always needs the owner's word, and the owner's yes at gate 3.

**Stage events (v0.9.5 3.11, R11; RECORDS.md).** In the project, record `sh checks/event.sh "stage name=deploy state=start session=$CLAUDE_CODE_SESSION_ID records=28"` when this verb starts and `sh checks/event.sh "stage name=deploy state=end session=$CLAUDE_CODE_SESSION_ID"` when it hands back. Every event this skill names is written the same way, `sh checks/event.sh '<event>'`, which appends it to `.vid/metrics-events` with its time.

**Version skew (v0.26.10.7 R17; v0.26.10.8 R13).** Read `checks/records-version` first.
If it is absent or below 28, the project's checks/ predates this plugin:
tell the owner it needs the refresh and stop before either deploy. The
refresh is vid-fix's: first run `sh
"${CLAUDE_PLUGIN_ROOT}/checks/local-changes.sh"` from the project's top
level and show the owner its list, since the copy overwrites it; then copy
`${CLAUDE_PLUGIN_ROOT}/checks/` over `./checks/` and commit it alone with
`VID_ROLE=fix`, its subject `Refresh checks/ to VID <version>`. The refresh
is the owner's choice.

**The progress record (v0.9.5 3.10).** A gate that pays a deploy-owed row
changes row states outside any slice, so the verb's report — whenever it
hands back, whatever gate it reached — appends a `## deploy <UTC>` section
to `.vid/SLICE-REPORTS.md`. A staging deploy's section opens with one line,
"staging runs <commit>, <k> commits past the last full pass <sha>" (the
staging check's candidate, `ahead=` and base; v0.26.10.7 R7); then the
computed block and the closure, `printf '\n## deploy %s\n\n' "$(date -u
+%Y-%m-%dT%H:%M:%SZ)" >> .vid/SLICE-REPORTS.md; sh checks/metrics.sh >>
.vid/SLICE-REPORTS.md; sh checks/metrics.sh closure >>
.vid/SLICE-REPORTS.md`. The newest section is what a viewer reads as
current (RECORDS.md).

## The claim first — "development complete" is computed (v0.9.3 3.14, R19)

Open every run of this verb by stating ONE claim, computed, never
asserted: run `sh checks/metrics.sh completion` and say **"development
complete"** when its line reads `complete, N rows at deploy, M later`, or
**"not complete"** otherwise — with the closure's lines (contract
ambiguity, invalid test evidence, unfinished implementation; the
deploy-owed rows named; the `later` count). Deploy PREPARATION —
interviewing, provisioning, wiring environments — may proceed either way
and asserts nothing more; what each target requires is its check (the
preconditions below), and gate 3 cannot open while a gate-1 or gate-2 row
is unpaid. The later-stage
claims (staging verified, ready for cutover, deployed pending
observation, deployment complete) wait for a release record bound to the
candidate, which a later release defines with the first real deploy's
evidence; the deploy log below is written after cutover and cannot carry
them.

With `STAGES.md` and the project not complete, the claim is the stage's,
read from its recorded close — "stage N complete" or "no stage closed
yet" (Stages, below; v0.26.10.5 R12) — or "stage N closed and held" while
the owner holds the next stage (v0.26.10.7 R13).

## Two targets (v0.26.10.7 R1)

- **`/vid deploy staging`** ("deploy to staging") is fast and repeatable:
  the rows and probes changed since the last full pass, on a scoped run of
  the exact commit, then gate 2. It closes no stage and asks no
  confirmation beyond the owner's word to deploy. It may run as often as
  the owner asks.
- **`/vid deploy production`** ("deploy to production") takes the commit
  staging runs, and only that commit: the full run, coverage, the re-grade
  of every row changed since the last full pass, gate 1 (except the first
  production deploy) and gate 3, the owner's yes. A production deploy that
  passes becomes the new last full pass.
- **A bare `/vid deploy`** means staging. Its report ends with one line:
  say "deploy to production" when staging looks good.
- **Deploy to production** is started only by the owner's word. **Deploy
  to staging** is too, except at a stage close, or at "continue" while
  staging is being set up, under the standing staging authorization
  (R6). No schedule or other automation starts
  either.

**The candidate (R2).** `sh checks/stages.sh deploy --target
staging|production --platform none|present` prints it, with the claim, the
deploy debt and the first-deploy reading; every check below runs at it.
Staging's is HEAD with a clean worktree — without `STAGES.md`, once the
project is complete, or while the owner holds the next stage — else stage
N's newest candidate, `vid/stage-N` or its newest `vid/stage-N.k`.
Production's is the commit of the newest gate-2 pass, which must still be
staging's: equal to the tag, or, for HEAD, a commit whose tree differs from
HEAD's only in the deploy's own records (`.vid/`, `DEPLOYMENT.md`,
`tests/probes/captured/`). Any other change since — a contract test
re-based on a capture, a law commit stamping a seam `probed(…)` — means
staging is deployed once more first: a small scoped deploy that probes no
seam already probed, so it commits nothing of its own. A tag is read from
its record, never recomputed. **The last full pass (R3)** is printed by
`sh checks/metrics.sh deploy-check` as `base: <sha> (<record>)`: the
newest of a production record, a staging record with `tests=full`, and a
stage close, at or behind the candidate. **The change set (R4):** `sh
checks/metrics.sh change-set --base <sha>`.

**Deploy to staging (R7), in order:**
1. the claim, as above;
2. `sh checks/stages.sh deploy --target staging` (`--by develop` when
   develop runs it, below);
2a. **while no staging deploy has passed gate 2** (no `deploy-gate gate=2
   … result=pass` in the events): set the test site up with
   `vid-staging-setup` — its Part 1 first when ARCHITECTURE.md holds no
   `vid-hosting` block (under `--by develop` that is a stop naming what's
   missing), then its Part 2, the build-out. It hands back `built` or
   `stopped: <what>`; stopped ends this deploy there, recorded as failed
   with that reason (v0.26.10.8 R4);
3. the staging check: `sh checks/metrics.sh deploy-check --target
   staging`. When it says no staging receipt is current, request one —
   `sh checks/test.sh request --type staging --role orchestrator
   --rows-file <the change set> --why "<one line>" -- <selection>
   [--deployed-selection <selection>]`, the selections yours, in the
   runner's syntax, for the change set's rows and probes — wait for it,
   and check again. Work every `unmet` line; a row owed to a deploy gate
   is listed as that gate's checklist (`owed <row> gate <n>`), never
   required. With no last full pass, the full run and coverage apply
   instead (`--type full`). Ready: `--record`;
4. gate 2 on the candidate, as below: the build from the candidate's tree
   (`git archive <commit>`, never the working tree), the env-diff
   conformance, one real action per live provider seam, the seams paid
   there;
5. in a staged project, `sh checks/event.sh 'stage-deploy n=N staging=yes
   production=no'` (with `by=develop` when develop runs it; a failure
   writes `staging=failed … why="<one line>"`, below);
6. the report's `## deploy` section, opening "staging runs <commit>, <k>
   commits past the last full pass <sha>". On stage 0's deploy it also
   says the skeleton journey was walked on staging (R5).

**Stage 0 (v0.26.10.8 R5)** — the technical stage, the walking skeleton —
goes to staging and never to production: `stages.sh deploy --target
production` refuses with one line while the newest closed stage is 0. Its
staging deploys record `stage-deploy n=0 staging=yes production=no`, and on
them gate 2's smoke also walks the skeleton journey once on staging.

**Develop's own staging deploy (v0.26.10.8 R6, R8).** Under the owner's
standing staging authorization (`sh checks/stages.sh staging-auth on|off
--words "<the owner's words>"`; the newest stands; any verb records the
owner's "stop deploying to staging on your own" as `off`), vid-develop
runs this staging deploy itself at a ready stage close, and at "continue"
while the setup hold is on (vid-develop, "Staging at each close"). Nothing
else does: not a fix, a schedule, a re-cut or production.
- It runs with `--by develop`: `sh checks/stages.sh deploy --target staging
  --by develop` and `sh checks/metrics.sh deploy-check --target staging
  --by develop [--record]`. The script accepts it only with the
  authorization on, target staging, and the candidate the newest close's
  tag (or HEAD while the setup hold is on); the "develop paused" refusal
  does not apply, since develop is the caller, at a step boundary.
- **It never asks or waits.** During the setup it stops for what only the
  owner can do (vid-staging-setup's stop). After the setup, whatever would
  need the owner ends this deploy, recorded as failed with its reason — a
  log-in expired or missing (the reason names the log-in command), a new
  outside account, secret or variable value, any confirmation, an
  undeclared staging difference, a failing smoke or gate 2 — and develop
  carries on.
- **Recorded:** gate 2's records as below, then `sh checks/event.sh
  'stage-deploy n=N staging=yes|failed production=no by=develop
  [why="<one line>"]'`, and the `## deploy` section. It hands back to
  develop, pass or fail, with one line saying which and why.

No gate 1, no gate 3, no owner confirmation, no stage close.

**Deploy to production (R9), in order:**
1. the claim, as above;
2. `sh checks/stages.sh deploy --target production`: the candidate and
   the forward-only check (R11);
3. the production check: `sh checks/metrics.sh deploy-check --target
   production`. The full run is requested when missing (`sh checks/test.sh
   request --type full --role orchestrator`, with `--stage N` in a staged
   project); each `regrade <ROW-id>` row is graded by `vid-verify`'s
   row-verdict contract, as `vid-fix`'s re-grade does, `slice=deploy-<date>`;
   `owed <row> gate <n>` lines are the gates' checklist, not unmet;
4. a red row or a BREACHED verdict ends this deploy: it becomes a
   correction for `/vid fix`, then staging again, then production again;
5. `sh checks/metrics.sh deploy-check --target production --record`
   (in a project held at stage N it also tags `vid/stage-N.k`);
6. gate 1 on the candidate, except a first production deploy (v0.26.10.5
   R15, under Stages);
7. gate 3: the owner's one-touch confirmation, as always; it cannot open
   with a row owed to gate 1 or 2 unpaid;
8. cutover, smoke, tag, deploy log row; in a staged project, `sh
   checks/event.sh 'stage-deploy n=N staging=yes production=yes'`.

A "no" at gate 3 leaves production unchanged; the record stays the last
full pass.

**Deploy never changes product behaviour itself (R15).** A product
correction found during a deploy is a `/vid fix`; in the loop it costs one
staging deploy, which is cheap. Platform-shaped work stays gate 2's:
configuration, domains, mail, provider seams and their captures, contract
tests re-based by a test-author pass, migrations. A correction already
made inside a deploy is recorded by `/vid fix`, named by the owner with its
commit (vid-fix, "Recording a correction already made").

**An agent spawned during a deploy (R6, F-58).** A test author re-basing
contract tests, or a fixer, runs `sh checks/plan.sh home --brief <its
brief file>` as its first act, as its brief's header names, so its test
runs publish at the project and its hand-back is read here.

## Stages — what deploy ships (v0.26.10.5 R11–R15)

When `STAGES.md` exists and the project isn't complete (RUN-STATE's `run:
complete`), deploy ships a **stage**. Start every run with `sh
checks/stages.sh deploy --target staging|production --platform
none|present` (ask the platform's authenticated CLI first whether a
production deployment exists; without the flag the first-deploy line says
`unknown`). Without `STAGES.md`, or once the project is complete, the
claim is today's and the candidate is HEAD's; of what follows, only R15's
first-deploy reading and the forward-only check (v0.26.10.7 R11) apply.
With a technical stage 0 (`STAGE-0 | <name> | technical`), "stages 1 to N"
below reads "stages 0 to N" (v0.26.10.8 R2).

- **Develop paused (R11).** While a develop run is active or waiting the
  script refuses with one line, for both targets: say "pause" to the build,
  deploy, then say "continue". The build pauses for the deploy itself, not
  while the owner thinks; you never pause it on your own. Without
  `STAGES.md` production is refused too while develop runs (its full run
  binds HEAD); staging is not (it pins its commit).
- **A held stage (v0.26.10.7 R13).** While the owner holds the next stage,
  the claim reads "stage N closed and held" and staging's candidate is
  HEAD: corrections to stage N reach staging on their own. A production
  deploy then tags `vid/stage-N.k`; `vid/stage-N` never moves.
- **The claim (R12)** is read from the record, never recomputed: "stage N
  complete" from the newest `stage-closed n=N … ready` event, or "no stage
  closed yet" — preparation may proceed, the gates don't open. Its entry
  checks are that record's: the full run, coverage and completion scoped
  to stages 1 to N.
- **The candidate** is that close's commit, tagged `vid/stage-N` (or its
  newest supersession `vid/stage-N.k`). Build and ship the tag's tree —
  `git archive <the tag>` (`--tree <dir>` extracts it) — never the working
  tree: the half-built next stage never reaches staging or production. Operational records (DEPLOYMENT.md, the
  deploy log, paid stamps, probed seams, re-based contract tests) are read
  from and committed to the current branch as today, so every later stage
  tag holds them.
- **Corrections since the tag (R10):** the script's `since:` lines — tell
  the owner how many commits landed since the tag and that the live
  candidate lacks them; they ship with the next stage's close.
- **Production only moves forward (v0.26.10.7 R11; it replaces R14).**
  For every project, the deploy log's newest production commit must be
  the candidate or an ancestor of it; the script refuses any other, so a
  candidate on a side line never lacks a fix already live. A late "yes" to
  an older stage means going live with the newest ready stage.
- **The deploy debt of stages 1 to N:** the script's `owed:` lines. Gate 3
  cannot open with one owed to gate 1 or 2 unpaid (scoped to stages 1 to
  N); rows of later stages are not this deploy's.
- **Staging and production are separate runs (v0.26.10.7).** A deploy to
  staging runs gate 2 on the candidate and records `sh checks/event.sh
  'stage-deploy n=N staging=yes production=no'`; staging then holds the
  latest deployed stage, which may be ahead of production. A deploy to
  production runs gates 1 and 3 on the commit staging runs and records
  `stage-deploy n=N staging=yes production=yes`; a "no" at gate 3 leaves
  production unchanged.
- **The first production deploy (R15)** is the script's `first-deploy:
  yes`: the deploy log holds no production row, no `deploy-gate gate=3`
  start was ever recorded, and the platform shows no production
  deployment. Only then may gate 1 be skipped. An interrupted cutover (a
  gate-3 start with no log row) is reconciled first — what production now
  runs, recorded in the deploy log — and then gate 1 applies. A project
  whose staging deploys all said "no" still gets its first production
  deploy this way; from the second production row on, gate 1's rehearsal
  on a restored production backup is required.

## Preconditions — production ships only done states; staging may run ahead

- **Production:** `sh checks/metrics.sh deploy-check --target
  production` ready on the exact commit going live, a commit already on
  staging. That means: the full run green (in a staged project, stages
  1 to N); `coverage.sh --strict` clean (open VID-QUESTION markers
  block; the `deploy-owed` rows it lists are this deploy's checklist);
  and every row changed since the last full pass re-graded.
- **Staging:** `sh checks/metrics.sh deploy-check --target staging`
  ready on the exact commit: the rows and probes changed since the last
  full pass pass on a scoped run of it. With no last full pass,
  production's full run and coverage apply. Staging may run ahead of the
  last full pass; the record says how far.
- Before the first-ever go-live, a `/vid grade` is recommended, not gated:
  say so once, offer to run it, respect the owner's answer.

## The credential boundary (hard law)

The OWNER authenticates; the AGENT operates. The owner runs the platform CLI
login (browser-based), creates provider accounts, and enters secret VALUES
in the platform dashboard. You work through the already-authenticated CLI:
provision services, create env-var NAMES, document where each value lives.
The set of secret values you ever saw must be empty — by design, not by
promise. You never create accounts, never enter a credential or secret value
anywhere, never accept terms of service on the owner's behalf. CLI not
authenticated is a genuine block: hand the owner the exact login command and
wait.

## Three failure classes, three gates

Each gate catches what the previous one structurally cannot. Narrate
position at each gate. Gate 2 is staging's; gates 1 and 3 are
production's (v0.26.10.7). Gates 1 and 2 run fully autonomously; gate 3
never does.

**Gate 1 — REHEARSAL (local Docker).** Restore the latest production backup
into the no-egress Docker test sandbox (destroyed afterward) → run the
migrations → boot the app → verify Tier-0 invariants: every pre-existing row
of every append-only table survives verbatim → walk the golden path on the
migrated, real-shaped data. Catches data and migration failures. Side effect
by design: every release proves the backups actually restore. (First deploy:
no production exists yet, so no gate 1 — first means `sh checks/stages.sh
deploy --target production --platform none` says `first-deploy: yes`, v0.26.10.5 R15.) Record the gate (v0.9.6.2 3.5,
R5): `sh checks/deploy-gate.sh 1 start --candidate <commit> --env <name>`
as it opens and `sh checks/deploy-gate.sh 1 end --result pass|fail` as it
closes; on a first deploy, `sh checks/deploy-gate.sh 1 skipped --reason
first-deploy`.

**Gate 2 — STAGING (same platform, real providers).** Deploy the
candidate to staging and run one real action through each live provider seam:
one real OAuth login, one real email to the owner's address, one real file
upload. Catches provider and environment failures — the class the ledger can
NEVER see, because local fakes are the point of the ledger — plus
platform/build failures. That is staging's only reason to exist. Staging
runs on a synthetic seed by default; restoring a prod backup into staging is
owner-opt-in, for scary migrations. **A seam paid here is paid in full
(v0.9.2 3.10, R15)** — a seam ratified `probe: unreachable-risk(credentials
not-yet)` reaches this gate with a client written against the provider's
documented contract and contract tests over hand-authored fixtures; the
gate performs the smallest real calls the seam needs, captures their
answers under `tests/probes/captured/` (each capture's `Provenance:`
naming the seam and the date), has the contract tests RE-BASED on the
captures by a test-author pass
(`${CLAUDE_PLUGIN_ROOT}/skills/vid-test-inventory/passes/test-author.md`
— never by the deploy session, which commits the returned files
unchanged with their `Tests-by:` trailer), and then flips the seam row to
`probed(<date>)` as its own law commit. One real action through the
provider is the smoke; it is not the probe, and it does not pay the row.
Record the gate the same way: `sh checks/deploy-gate.sh 2 start
--candidate <commit> --env <name>`, then `sh checks/deploy-gate.sh 2 end
--result pass|fail`.

**Gate 3 — PROD CUTOVER (the owner's, always).** One-touch confirmation on
EVERY deploy, even with gates 1 and 2 green: "deploy vN to prod? migration:
yes/no; providers changing: <list or none>". Deploys happen from the owner's
hands — made literal. Record the gate (`sh checks/deploy-gate.sh 3 start
--candidate <commit> --env <name>`, then `sh checks/deploy-gate.sh 3 end
--result pass|fail [--rollback-target <ref>]`), and every owner
confirmation this verb asks, this one and the migration questions alike:
`sh checks/deploy-gate.sh confirm ask --what "<the question>"` when you ask
and `sh checks/deploy-gate.sh confirm answer --what "<the question>"
--result yes|no` when the owner answers. The script records and never
refuses.

**The deploy-owed rows.** Gates 1–3 read the inventory rows born `owed:
paid by /vid deploy gate N — <what the rung observes>` as their checklist
and pay each by the rung's evidence: a row paid by a rung is stamped
`| paid-at: gate-N <date> <deploy log row>` in a law commit; gate 3 cannot
open with an unpaid gate-1 or gate-2 row. Infrastructure-only obligations
(managed backups and point-in-time recovery, storage versioning, DNS, TLS,
monitoring) are done here and recorded in DEPLOYMENT.md; an owner
attestation (a provider's certification) is a DEPLOYMENT.md line, never a
row (v0.9.1 3.6).

## Staging anti-rot

Staging runs the same config-as-code as prod and holds the latest
deployed stage (v0.26.10.5), which may be ahead of production. Every
permitted staging/prod difference is enumerated in the ```vid-env-diff block
in DEPLOYMENT.md; anything not listed must be identical. An undeclared
difference found during a staging deploy STOPS the deploy. The diff is the
artifact.

## Provider cutover — per provider, gradual

Each real-service adapter is `fake` → `live-restricted` → `live`, tracked in
DEPLOYMENT.md's provider state table. New providers start `live-restricted`
(all outbound email redirected to the owner's inbox for the first week;
OAuth against the staging redirect URI first). Flipping a state is an
explicit act, recorded in the deploy log. This is the go-live sticky note,
operationalized.

## Migrations

The migration strategy is the migration code plus its DECISIONS entry —
never a plan document. Its only validation is gate 1 passing; the universal
Fail-if is stated once in DEPLOYMENT.md. Two product questions, always
asked: destructive data changes ("this drops X — confirm"), and downtime
tolerance — asked ONCE per project, logged as a D-entry (default: brief
maintenance-window migrations); since v0.26.10.8 it is asked at init, with
where the product runs (`vid-staging-setup` Part 1).

## First deploy (greenfield) — a mini-init

Creates DEPLOYMENT.md, the sixth artifact — init never does. It splits
along the two targets (v0.26.10.7 R1). **Deploy to staging** sets the test
site up first: the questions (where it runs, how ViD gets access, the
providers, the downtime tolerance) were asked at init and recorded in
ARCHITECTURE.md's `vid-hosting` block, and the platform checked against
BASELINE there (`vid-staging-setup` Part 1); the build-out — the log-in,
both environments, the database and seed, every outside service's
variables and state row, the sending domain, DEPLOYMENT.md — is its Part 2
(v0.26.10.8 R4). Then gate 2: the candidate deployed and the provider smoke
on staging. Its staging check has no last full pass, so it needs the full
run and coverage, and records `tests=full`. **Deploy to production** runs
the production check, then the first cutover:

- Gate 3: first prod cutover with owner confirmation → tag the commit
  (v0.N) → append the deploy log row → post-cutover smoke → show the owner
  how to tail the logs.

## Every deploy after

- **Staging:** the claim → the candidate → the staging check (its scoped
  run, `--record`) → gate 2: the staging deploy of the candidate's tree +
  provider smoke + env-diff conformance → the report's `## deploy`
  section.
- **Production:** the claim → the candidate (staging's commit) → the
  production check (the full run, coverage, the re-grade; `--record`) →
  gate 1 rehearsal → gate 3 one-touch confirmation → back up prod and
  record the snapshot ref → migrate within the logged downtime tolerance
  → deploy → smoke → tag + deploy log row.

Rollback is chosen from the failure and the migration's DECISIONS entry,
never restore-by-default (v0.9.3 3.14; DEPLOYMENT.md "Rollback"):
**application rollback keeping a compatible database** — redeploy the
previous build ref when the schema it expects still stands; **forward
repair** — fix forward through gates 1 and 2 when the migration cannot be
reversed without losing writes; **restoration from the snapshot** — only
when the data itself is damaged, stating the recovery point and the writes
at risk (every write since the snapshot is lost) to the owner before it is
done. First deploy: no backup exists; the empty-database path and the
worker subscriptions are the first staging run's evidence, the topology
census covering the subscriptions before then. Record a rollback as you
start it: `sh checks/deploy-gate.sh rollback --gate <1|2|3> --why "<one
line>"`.

"Blocked" is reserved for the genuinely impossible — CLI unauthenticated,
platform down, no network. Everything else is yours to sort out; log the
surprising choices to DECISIONS.md.
