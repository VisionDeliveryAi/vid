---
name: vid-deploy
description: Ship a ViD project — the only verb that touches anything real. Greenfield first deploy (platform interview, staging+prod build-out, DEPLOYMENT.md creation) and every deploy after, through three gates — local rehearsal on a restored production backup, staging with one real action per provider seam, owner-confirmed prod cutover. Never runs implicitly. Use when the owner says "vid deploy", "deploy this", "go live", or "ship it".
---

# /vid deploy

The shipping verb — the only verb that touches anything real. DEPLOY is not
TEST (the ledger: `sh checks/test.sh`, Docker-only, deterministic) and not
GRADE (adversarial fresh-context review). Deploy is the inverse of grade:
grade is always safe to run, so it may run anytime, unattended; deploy NEVER
runs on its own. No verb, no schedule, no automation may invoke it — only
the owner says the word.

**Stage events (v0.9.5 3.11, R11; RECORDS.md).** In the project, record `sh checks/event.sh "stage name=deploy state=start session=$CLAUDE_CODE_SESSION_ID records=4"` when this verb starts and `sh checks/event.sh "stage name=deploy state=end session=$CLAUDE_CODE_SESSION_ID"` when it hands back. Every event this skill names is written the same way, `sh checks/event.sh '<event>'`, which appends it to `.vid/metrics-events` with its time.

**The progress record (v0.9.5 3.10).** A gate that pays a deploy-owed row
changes row states outside any slice, so the verb's report — whenever it
hands back, whatever gate it reached — appends a `## deploy <UTC>` section
to `.vid/SLICE-REPORTS.md`: the computed block and the closure,
`printf '\n## deploy %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>
.vid/SLICE-REPORTS.md; sh checks/metrics.sh >> .vid/SLICE-REPORTS.md; sh
checks/metrics.sh closure >> .vid/SLICE-REPORTS.md`. The newest section is
what a viewer reads as current (RECORDS.md).

## The claim first — "development complete" is computed (v0.9.3 3.14, R19)

Open every run of this verb by stating ONE claim, computed, never
asserted: run `sh checks/metrics.sh completion` and say **"development
complete"** when its line reads `complete, N rows at deploy, M later`, or
**"not complete"** otherwise — with the closure's lines (contract
ambiguity, invalid test evidence, unfinished implementation; the
deploy-owed rows named; the `later` count). Deploy PREPARATION —
interviewing, provisioning, wiring environments — may proceed either way
and asserts nothing more; the gates below are unchanged, and gate 3
cannot open while a gate-1 or gate-2 row is unpaid. The later-stage
claims (staging verified, ready for cutover, deployed pending
observation, deployment complete) wait for a release record bound to the
candidate, which a later release defines with the first real deploy's
evidence; the deploy log below is written after cutover and cannot carry
them.

## Preconditions — deploy ships only done states

- `sh checks/test.sh` green.
- `sh checks/coverage.sh --strict` clean — open VID-QUESTION markers block
  deploy; the `deploy-owed` rows it lists are this deploy's checklist
  (v0.9.1 3.6).
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
position at each gate. Gates 1 and 2 run fully autonomously; gate 3 never
does.

**Gate 1 — REHEARSAL (local Docker).** Restore the latest production backup
into the no-egress Docker test sandbox (destroyed afterward) → run the
migrations → boot the app → verify Tier-0 invariants: every pre-existing row
of every append-only table survives verbatim → walk the golden path on the
migrated, real-shaped data. Catches data and migration failures. Side effect
by design: every release proves the backups actually restore. (First deploy:
no production exists yet, so no gate 1.) Record the gate (v0.9.6.2 3.5,
R5): `sh checks/deploy-gate.sh 1 start --candidate <commit> --env <name>`
as it opens and `sh checks/deploy-gate.sh 1 end --result pass|fail` as it
closes; on a first deploy, `sh checks/deploy-gate.sh 1 skipped --reason
first-deploy`.

**Gate 2 — STAGING (same platform, real providers).** Deploy the same
commit to staging and run one real action through each live provider seam:
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

Staging deploys the same commit and the same config-as-code as prod. Every
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
maintenance-window migrations).

## First deploy (greenfield) — a mini-init

Creates DEPLOYMENT.md, the sixth artifact — init never does. One batched
interview, product questions only:

- platform hint — any altitude accepted, "cheapest thing that works" to
  "Railway, EU"
- custom domain, or the platform subdomain
- region — a product question: where the users are and whose law applies
- spend cap
- which providers go live now, and which stay fake

Then:

1. **Validate the platform against BASELINE** from the platform's docs — db
   version, Docker/buildpack support, workers, cron, pricing vs the cap.
   Verdict is a DECISIONS entry naming the rejected alternatives. If the
   platform fundamentally cannot run the stack, that is a product tradeoff —
   escalate per the two-channel rule.
2. **Auth gate** — verify (e.g. `railway whoami`). Unauthenticated → hand
   the owner the login command and wait; that is the block.
3. **Build staging + prod environments** — versions pinned from BASELINE,
   never platform defaults.
4. Seed staging synthetically; wire providers per the state table; run the
   provider smoke on staging (gate 2).
5. Create DEPLOYMENT.md from
   `${CLAUDE_PLUGIN_ROOT}/templates/DEPLOYMENT.md` — no placeholder
   survives — and commit it (template message).
6. Gate 3: first prod cutover with owner confirmation → tag the commit
   (v0.N) → append the deploy log row → post-cutover smoke → show the owner
   how to tail the logs.

## Every deploy after

Preconditions → gate 1 rehearsal → gate 2 staging deploy + provider smoke +
env-diff conformance → gate 3 one-touch confirmation → back up prod and
record the snapshot ref → migrate within the logged downtime tolerance →
deploy → smoke → tag + deploy log row.

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
