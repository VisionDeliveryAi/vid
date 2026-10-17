# JobDigest — TEST INVENTORY

> Ratified at init, same standing as PRD.md: the owner ratified these ROWS —
> what will be verified — before any code existed. A toy product's init
> inventory in the pre-0.9.2 grammar (no `grammar:` line): every deferral
> carries a prose `owed: <reason>`. Additions during development are
> permitted, never silent — checks/inventory.sh fails a commit whose new
> route has no row here, and every change to this block is a law change.

## Row schema

    ROW-NNN | kind | subject | actor/state | marker | obligation | derived-from | test

- `kind` — `surface` · `journey` · `shell` · `behavior` · `reachability`
- `subject` — route, screen id, or requirement id
- `actor/state` — `anonymous` · `subscriber` · `operator:<role>` · `n/a`
- `marker` — the design pack marker this row binds to (`S01/error`), or `n/a`
- `obligation` — one falsifiable sentence a fresh-context grader can check
- `derived-from` — `REQ-NNN` and/or a design marker; never "authored"
- `test` — path under tests/invariants/, or `owed: <reason>` (owed rows block
  completion — checks/inventory.sh --strict and checks/coverage.sh --strict).

Every row may carry optional trailing labeled fields: `| origin: …`,
`| proved-red: <sha>`, and on a golden-set row `| golden: tests/invariants/<fixture>`
with `| divergence: DIF-NNN` (the named difference row carries a `paying-step:`).

## Census row classes (read by checks/census.sh)

    rule       | RULE-NNN | statement | census-command | tier | test
    difference | DIF-NNN  | knob | test-value | prod-value | why-safe [| paying-step: <rung> — <what re-runs against the real component>]

## Provider seam rows (read by checks/seams.sh)

    seam | SEAM-NNN | service | purpose | chosen: D-NNN | credentials: <held|not-yet|never> | probe: <owed | probed(YYYY-MM-DD) | unreachable-risk(reason)> | evidence: <path or owed> | quirks: <one per ";", or "none yet"> | match: <patterns>

## Hostility rows (read by checks/inventory.sh)

    hostility | HOS-NNN | attempt | protects: <RULE-NNN|REQ-NNN|ROW-NNN> | disable: <toggle> | test [| proved-red: <sha>]

## Rows

Derived at init from the ratified PRD, the design pack's `@screen` markers,
the auth-state × surface axis and the genus deliberation.

```vid-inventory
# ===== behavior rows: one per independently breakable promise =====
ROW-001 | behavior | REQ-001 | n/a | n/a | never: a subscription is created for an address that has not confirmed it | REQ-001 | owed: materialised when its surface exists; the scaffold has no route for it | origin: REQ-001
ROW-002 | behavior | REQ-002 | n/a | n/a | never: a digest is sent to an address that has unsubscribed | REQ-002 | owed: materialised in the slice that builds the subject | origin: REQ-002
ROW-003 | behavior | REQ-003 | n/a | n/a | the unsubscribe link in any digest ends the subscription in one click, with no sign-in | REQ-003 | owed: materialised when its surface exists | origin: REQ-003
ROW-004 | behavior | REQ-004 | n/a | n/a | never: one subscriber's address appears in another subscriber's digest or its headers | REQ-004 | owed: materialised in the slice that builds the subject | origin: REQ-004
ROW-005 | behavior | REQ-005 | n/a | n/a | a digest lists only jobs that match at least one of the subscriber's keywords | REQ-005 | owed: materialised with the digest slice | origin: REQ-005
ROW-006 | behavior | REQ-006 | n/a | n/a | never: a job first seen more than 30 days before the send appears in a digest | REQ-006 | owed: materialised when the surface exists | origin: REQ-006
ROW-026 | behavior | REQ-013 | n/a | n/a | an administrator adds a job source and its next run is listed with its record count | REQ-013 | owed: materialised with the sources slice | origin: REQ-013
# ===== golden-set rows (derives: golden-set) =====
ROW-010 | behavior | REQ-008 | n/a | n/a | for every line of the ratified golden set, must-appear jobs are in the digest's top five and must-not-appear jobs are absent | REQ-008 | owed: golden set ratified at this sitting; test lands with the search slice | origin: REQ-008 | golden: tests/invariants/fixtures/golden_queries.txt | divergence: DIF-002
# ===== trigger-existence rows (time-worded promises need an operator) =====
ROW-007 | behavior | REQ-007 | n/a | n/a | trigger exists: the weekly digest schedule fires for every confirmed subscriber and its last firing is recorded | REQ-007 | owed: the schedule lands with the slice | origin: REQ-007
# ===== volume rows (list surfaces x the stated volume) =====
ROW-011 | behavior | REQ-009 | n/a | n/a | matching a digest over 1,000 jobs completes within two seconds | REQ-009 | owed: materialised with the load fixture | origin: REQ-009
# ===== control siblings (the allowed case demonstrably works) =====
ROW-008 | behavior | REQ-002 | n/a | n/a | control of ROW-002: a confirmed, subscribed address receives the weekly digest | REQ-002 | owed: materialised with its guard row | origin: REQ-002
ROW-009 | behavior | REQ-004 | n/a | n/a | control of ROW-004: two subscribers each receive their own digest, addressed to them alone | REQ-004 | owed: materialised with its guard row | origin: REQ-004
# ===== property-form rows (many-input datasets and invariance relations) =====
ROW-012 | behavior | REQ-010 | n/a | n/a | keyword matching is case-insensitive over every job of the corpus | REQ-010 | owed: needs the corpus fixture | origin: REQ-010
ROW-013 | behavior | REQ-010 | n/a | n/a | reordering a subscriber's keywords never changes the digest's contents | REQ-010 | owed: needs the dataset fixture under tests/ | origin: REQ-010
ROW-014 | behavior | REQ-011 | n/a | n/a | the same job listed by two sources appears once in a digest | REQ-011 | owed: materialised with the corpus fixture | origin: REQ-011
# ===== journeys (browser class, one per stated journey) =====
ROW-015 | journey | anonymous visitor / G1 | anonymous | n/a | subscribe with two keywords, confirm from the email, receive the first digest listing matching jobs | REQ-001,REQ-005 | tests/invariants/test_journeys.py | origin: REQ-001
ROW-016 | journey | subscriber / G2 | subscriber | n/a | unsubscribe from a digest link and receive no further digest | REQ-003,REQ-002 | tests/invariants/test_journeys.py | origin: REQ-003
# ===== shell rows (each auth state; header, footer, nav, error pages) =====
ROW-017 | shell | public shell | anonymous | n/a | header, footer and navigation render on every public page; no admin control is shown | REQ-012 | tests/invariants/test_shell.py | origin: REQ-012
ROW-018 | shell | admin shell | operator:admin | n/a | the admin navigation lists the sources and subscribers modules and a sign-out control | REQ-013 | owed: materialised in the slice that builds the subject | origin: REQ-013
# ===== reachability rows (doors, not rooms) =====
ROW-019 | reachability | /subscribe | anonymous | n/a | the subscribe page is linked from the homepage | REQ-001 | owed: materialised when its surface exists | origin: REQ-001
# ===== surface rows: routes and design pack @screen markers x applicable auth states =====
ROW-020 | surface | / | anonymous | H01/default | the homepage renders the subscribe form with its keyword field | REQ-012 | tests/invariants/test_req_012_homepage.py | origin: REQ-012
ROW-021 | surface | /healthz | n/a | n/a | the health endpoint answers 200 ok and reads no subscriber | REQ-014 | owed: the scaffold's health endpoint already satisfies this row, so its test cannot be observed red at the initial commit; it materialises with the monitoring slice, where it can be | origin: REQ-014
ROW-022 | surface | /subscribe | anonymous | S01/default | the subscribe page accepts an address and keywords and says a confirmation was sent | REQ-001 | owed: materialised when its surface exists; the scaffold has no route for it | origin: REQ-001
ROW-023 | surface | S01/default | anonymous | S01/default | the S01 Subscribe canvas section S01/default is transcribed property-for-property and renders without console error | REQ-001 | owed: browser render test lands with the screen's slice | origin: design S01/default
ROW-024 | surface | S01/error | anonymous | S01/error | the S01 Subscribe canvas section S01/error is transcribed property-for-property and renders without console error | REQ-001 | owed: browser render test lands with the screen's slice | origin: design S01/error
ROW-025 | surface | A01/default | operator:admin | A01/default | the A01 Sources canvas section A01/default is transcribed property-for-property and renders without console error | REQ-013 | owed: browser render test lands with the screen's slice | origin: design A01/default
# ===== rule rows (census denominators; every rule is ratified owed until develop arms it) =====
rule | RULE-001 | every query on the subscriber table filters on a confirmed address | checks/extractors/invariant.confirmed-only.sh | 0 | owed: armed when the first site exists | origin: REQ-001
rule | RULE-002 | state-machine subscription_state: pending>confirmed confirmed>unsubscribed pending>expired | checks/extractors/state-machine.subscription_state.sh | 0 | owed: armed when the first site exists | origin: REQ-002
rule | RULE-003 | every digest send names exactly one recipient | checks/extractors/invariant.one-recipient.sh | 0 | owed: armed when the first site exists | origin: REQ-004
rule | RULE-004 | every source run records its record count | checks/extractors/invariant.run-count.sh | 1 | owed: armed when the first site exists | origin: REQ-013
# ===== difference rows (every fake the harness substitutes) =====
difference | DIF-001 | MAIL_TRANSPORT | in-memory outbox | the mail provider's API | the provider seam is faked; content and recipients are asserted on the captured messages | paying-step: staging — one real digest through the mail provider (deploy gate)
difference | DIF-002 | CORPUS_SIZE | 300 jobs (harness snapshot) | 3,000 jobs (pilot) | the harness corpus keeps the stated mix at a tenth of the size so a ledger run stays short | paying-step: staging — re-run tests/invariants/fixtures/golden_queries.txt against the full corpus
# ===== provider seam rows (born owing a probe) =====
seam | SEAM-001 | job-feed | scheduled HTTP retrieval of the partner job feeds | chosen: D-003 | credentials: never | probe: probed(2026-09-10) | evidence: tests/probes/test_seam_contracts.py over tests/probes/captured/job_feed.json — fetch, not-modified, malformed item | quirks: a not-modified answer carries no body | match: feed.fetch(
seam | SEAM-002 | mail-provider | email API: digest sends and bounce webhooks | chosen: D-004 | credentials: not-yet | probe: owed | evidence: owed | quirks: none yet | match: mail.send(
seam | SEAM-003 | object-store | private bucket for digest archives | chosen: D-005 | credentials: never | probe: owed | evidence: owed | quirks: none yet | match: store.put(
# ===== hostility rows (one sibling per Tier-0 protection) =====
hostility | HOS-001 | POST the subscribe form for an address and, without confirming, trigger the weekly send; expect no digest to that address | protects: REQ-001 | disable: skip the confirmed check in the send query | owed: the protection does not exist yet; materialised and stamped by its own ritual in the slice that builds it
hostility | HOS-002 | unsubscribe an address, then trigger the weekly send; expect no digest to that address | protects: REQ-002 | disable: ignore the unsubscribed state in the send query | owed: the protection does not exist yet; materialised and stamped by its own ritual in the slice that builds it
hostility | HOS-003 | with two subscribers seeded, trigger the send and read every captured message; expect no message naming the other address | protects: REQ-004 | disable: batch both recipients into one send | owed: the protection does not exist yet; materialised and stamped by its own ritual in the slice that builds it
hostility | HOS-004 | seam mail-provider fails mid-operation: send a digest while the provider returns 500; expect the digest recorded unsent, never marked sent | protects: REQ-007 | disable: mark the digest sent before the provider accepts it | owed: materialised with the protection
hostility | HOS-005 | replay a used unsubscribe link for a different address; expect the other subscription untouched | protects: REQ-003 | disable: resolve the link by address instead of by its token | owed: materialised with the protection
```
