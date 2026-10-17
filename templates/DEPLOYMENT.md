# {{PROJECT_NAME}} — DEPLOYMENT

Operational law and state. Created by /vid deploy on the first (greenfield)
deployment; updated by every deploy; law when present. Secret VALUES never
appear here or anywhere in the repo — names and locations only.

## Platform

| | |
|---|---|
| Platform | {{PLATFORM}} — validated against BASELINE, see D-{{NNN}} |
| Staging | {{STAGING_SERVICE_AND_URL}} |
| Production | {{PROD_SERVICE_AND_URL}} |
| Region | {{REGION}} — owner decision: {{WHY}} |
| Spend cap | {{CAP_AND_WHERE_SET}} |
| Deploy command | {{COMMAND}} |
| Logs | {{HOW_TO_TAIL_LOGS}} |

## Environment variables (names only — never values)

| Name | Purpose | Value lives |
|---|---|---|
| {{VAR_NAME}} | {{PURPOSE}} | {{platform dashboard / owner's password manager}} |

## Staging/prod diff — enumerated and exhaustive

Anything NOT listed here must be identical between staging and prod. An
undeclared difference found during a staging deploy stops the deploy.

```vid-env-diff
{{SETTING}}: staging={{X}} prod={{Y}}
```

## Provider states

Each real-service adapter is `fake` → `live-restricted` → `live`. Flipping a
state is an explicit act, logged in the deploy log. New providers start
`live-restricted` (e.g. all outbound email redirected to the owner's inbox
for the first week; OAuth against the staging redirect URI first).

| Provider | Adapter/seam | State | Restriction (if any) |
|---|---|---|---|
| {{PROVIDER}} | {{MODULE}} | {{STATE}} | {{RESTRICTION}} |

## Migration law

**Fail-if (universal, every deploy):** the deploy is invalid if, on a
restored copy of the latest production backup, the migration fails, any
Tier-0 append-only row is lost or altered, or the golden path breaks.

The rehearsal is the only migration validation: the strategy is the
migration code plus its DECISIONS entry — never a plan document. Destructive
data changes, and downtime beyond {{TOLERANCE}} (owner decision D-{{NNN}}),
are product questions — always asked first.

## Rollback (chosen from the failure, never always-restore — v0.9.3 3.14)

The choice is made from the failure and the migration's DECISIONS entry
(D-{{MIGRATION_DECISION}}), and stated before it is made:

1. **Application rollback keeping a compatible database** — the failure is
   in the application and the schema the previous build expects still
   stands (the migration was additive, or none ran): redeploy the previous
   build ref; no data is touched.

       {{APP_ROLLBACK_COMMANDS}}

2. **Forward repair** — the migration cannot be reversed without losing
   writes, or the previous build cannot read the new schema: fix forward,
   through gate 1 and gate 2 again, the site kept up or in its logged
   maintenance state within the downtime tolerance.
3. **Restoration from the snapshot** — the data itself is damaged: restore
   this deploy's backup snapshot ({{BACKUP_REF}}), stating the recovery
   point (the snapshot's time) and the writes at risk (every write since
   it, which are lost) — said plainly to the owner before, not after.

       {{RESTORE_COMMANDS}}

First deploy: no backup exists to restore; the empty-database path and the
worker subscriptions are the first staging run's evidence — the topology
census covers the subscriptions before then.

## Deploy log (append-only)

Provider state flips are appended between rows as dated one-liners.

| Version | Date | Commit | Migration | Backup ref | Previous build |
|---|---|---|---|---|---|
