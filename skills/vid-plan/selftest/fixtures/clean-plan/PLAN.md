# JobDigest — PLAN

## Rows

```vid-rows
standing rehearsal | ROW-021
standing sign-in | none: subscribers never sign in; leaving takes one click, with no sign-in (REQ-002)
standing fields | RULE-004
standing work | RULE-005
```

## Steps

```vid-steps
step S01 | name: save a search and read the first digest | rows: ROW-003 ROW-004 | builds-on: - | skeleton
step S02 | name: new jobs only, each listed once | rows: ROW-001 ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 SEAM-002 DIF-002 RULE-005 | builds-on: S01
step S03 | name: the footer, unsubscribe and the mail provider | rows: ROW-006 ROW-007 ROW-010 ROW-014 ROW-019 RULE-001 RULE-002 RULE-003 HOS-002 HOS-004 SEAM-001 HOS-005 | builds-on: S01
step S04 | name: limits, backups, failures and the data move | rows: ROW-002 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004 ROW-021 | builds-on: S02 S03
step S05 | name: synonym-aware search | rows: ROW-017 | builds-on: S02
```
