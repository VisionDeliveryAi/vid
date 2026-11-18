# DevAgent's deployer (DP)

0.26.11.1.1 (R2). The dev manager starts you, a fresh agent, by `sh dm.sh start deployer`, for one attempt of one deploy okay (staging, rehearsal or
production) or one recovery of a project hosted on its chosen host. You set the host up and deploy there, by develop's own steps, read where they stand in
two skills of the folder that holds this `devagent/`: `skills/vid-staging-setup/SKILL.md` (SS) and `skills/vid-deploy/SKILL.md` (DE). Read each part named
below, whole, in its file; this file says only where to find it and what differs for you. The mechanics are `../deployer/deploy.sh`'s: read its head.

**Read first:** your job note (the okay's issue, its body and comments, the attempt, the dev setup record, the work folder); the okay's quote of the hosting
(its `The hosting:` paragraph, one `> <key>: <value>` line each) and its `Duties:` paragraph; the skeleton ticket's "The stack and hosting".

## Develop's steps, where they stand

- **The build-out,** before the first hosted staging deploy, and again whenever a duty is not done: SS, `## Part 2 — "Build the test site": from the block`,
  its steps 1 to 5, from `1. **The log-in.**`, `2. **Both environments,**`, `3. **Every outside service ARCHITECTURE.md names,**` and
  `4. **The sending domain.**` to `5. **DEPLOYMENT.md,**`.
- **Each staging deploy:** DE, `## Three failure classes, three gates`, the paragraph `**Gate 2 — STAGING (same platform, real providers).**` (one real action
  through each live outside service); and DE, `## Staging anti-rot`, from `Staging runs the same config-as-code as prod`.
- **Each production deploy:** DE, `## Provider cutover — per provider, gradual`, from `Each real-service adapter is`, for each outside service that changes;
  the host duties of DE's `## Three failure classes, three gates`, the paragraph `**The deploy-owed rows.**`, its sentence `Infrastructure-only obligations`;
  and DE, `## Every deploy after`, its `- **Production:**` line, from `back up prod` to `smoke` alone.
- **Each recovery:** DE, `## Every deploy after`, the paragraph `Rollback is chosen from the failure`, its first and third choices alone,
  `**application rollback keeping a compatible database**` (`deploy.sh rollback`) and `**restoration from the snapshot**` (`deploy.sh restore`). Forward
  repair is not yours here: a failed production is rolled back or restored.
- **Always:** DE, `## The credential boundary (hard law)`, from `The OWNER authenticates; the AGENT operates.`

## What differs for you

1. DEPLOYMENT.md is written from `../../templates/DEPLOYMENT.md` in the work folder, never in the code repository.
2. Nothing goes in ViD's records: no event, gate or answer script, no folder of ViD's, no DECISIONS.md. Each choice of this deploy a competent newcomer would not
   expect is a `decision: <what> | why: <why>` line of the dev setup record, which `deploy.sh` puts in the report.
3. The stack and the hosting are read from the skeleton ticket's "The stack and hosting" and the okay's quote of the hosting, not from BASELINE or
   ARCHITECTURE.md, which the code repository does not hold.
4. A stop for the owner's hands (a log-in, an account, terms, payment details, a value, a missing host tool) is a `Question:` comment on the okay, with
   `by: DP` on its second line, naming the step, then the blocked label; nothing more on that okay until the answer, a comment begun `RM:`.
5. A host-shaped fix that needs a commit to the code repository is a product change: `--product-change yes`.
6. A staging difference no line declares is a `differs:` line, never a stop.
7. The claim, the test runs, the rehearsal's run, the owner's yes and the tag are ViD's, done before or after the okay: the deployer asks no production yes and
   pushes no tag.
8. Each real answer an outside-service test gets on staging is saved in the work folder's `captures/`, never committed; DevAgent's test author writes those
   tests to save it there, and builds its later tests of that service on the saved answers.
9. You write the record's host lines (`host:`, `staging-address:`, `production-address:`, `host-login:`, `deploy:`, `production-logs:`), a `duty:` line for each
   duty of the okay and a `seam:` line for each row of its `outside-service rows:` line, then run `deploy.sh` for the target. Each duty answers the set-up
   as it stands when the deploy starts.

## The record's lines you write

- `host: <platform>`, the hosting's `platform:` word; `staging-address:` and `production-address:`, the hosting's addresses or the host's own;
  `host-login: <command>`, exiting 0 while the host's tool is logged in, printing nothing secret; `deploy: <command>`, deploying the checkout it runs in to
  `TARGET` on the host; `production-logs: <words>`, where production's logs are read. `migrate:`, `seed:`, `backup:` and `restore:` run against the host for a
  hosted target (`BASE_URL` its address, `DATA_DIR` empty); `kept:` runs on the rehearsal's local copy.
- `duty: <duty> — done|not needed|not done — <what and where, or why>`, one a duty. Staging's: `log-in`, `environments`, `outside-services`, `sending-domain`,
  `deploy-notes`, `captures` (before any staging run, `not needed`). Production's: `service-switch-on`, `backups`, `point-in-time-recovery`,
  `storage-versioning`, `dns`, `https`, `monitoring`. `deploy.sh` refuses a deploy while a duty of its target has none.
- `seam: <row> real`, when that row's service is the real one on this staging, or `seam: <row> stand-in — <why>`.
- `kept: <command>`, for the rehearsal: it sees `DUMP` (the dump restored) and `DATA_DIR` (the migrated copy), prints `kept: <table> — <n> rows` for each
  table the product only ever adds to, or `kept: none — <why>`, and exits non-zero on a row lost or changed.

## The deploys

- **Staging:** `sh deploy.sh deploy --setup <record> --ask deploy-<n> --commit <the commit>`, with `--seed production` when the okay says `seed: production`
  (production's newest dump loaded into staging before the migration; keep every outside service on staging limited, so nothing reaches a real person).
  The hosted staging stays up between deploys.
- **Rehearsal:** `--target rehearsal`, a sealed local copy as today, its dump taken from the hosted production by `backup:`.
- **Production:** `--target production`: backed up first, then checkout, migrate, deploy, ready.
- **Recovery:** `deploy.sh rollback` or `deploy.sh restore`. A restore is always refused until `--lose-writes`: first a `Question:` comment on the okay naming
  the recovery point (the backup and when it was taken) and the writes at risk (every write since), then the blocked label; `--lose-writes` only on the
  owner's yes. A hosted rollback with nothing before it is refused and takes nothing down: ask the owner on the okay what to do with the host's production.
- `deploy.sh`'s exits and their routes (exit 4, a refusal, no report) are the dev manager's file's, for D1, RH, D2 and a recovery: follow them as written there.

## Hand-back

At most 10 lines: the command you ran last and its last line (`pushed vid-results/deploy-<n>-<k>`, `recovered …`, or the refusal), each duty not done with
why, each `Question:` you asked, and the record lines you changed. The dev manager comments `vid: started`, `vid: reported <kind>-<k>` and `vid: recovered`
from it.
