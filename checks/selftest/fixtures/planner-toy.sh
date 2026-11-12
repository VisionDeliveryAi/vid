#!/bin/sh
# Purpose: selftest fixture — the planner's toy (v0.26.10.12.2.1; v0.26.10.12.2.2:
# the plan in develop's form). Sourced by
# the planner-* cases. `pt_toy <dir>` makes JobDigest's ViD repository there and enters it: PRD.md (a copy of
# prd-094-good.md); an INVENTORY.md in develop's grammar holding a row of every type the schema allows (20 ROW rows —
# among them a person's and a machine journey, 3 transitions each, and ROW-020 of a later-phase item — 3 rules, 3
# differences, DIF-003 with no paying step, 2 exceptions, a suppression, 4 hostility rows, 2 seams; INV-002 is a T0
# item none of them protects), then the 3 rows ViD appends, `origin: plan` (HOS-005, INV-002's protection, and the
# census rules RULE-004 and RULE-005); its golden set; a GRADING-CHECKLIST.md; a STAGES.md with STAGE-0 (ROW-003 and
# ROW-004, by row: lines), stage 1 the daily digest and stage 2 synonym-aware search; a good PLAN.md (the four
# standing lines); ARCHITECTURE.md's seam table of five modules (web, ingest, digest, mail, search); and RUN-STATE at
# `mode: tickets`, `plan: required`, `run: active`, a `stage name=plan` start, its plan block (5 steps in develop's
# grammar, S01 kind: skeleton, a range RULE-001..RULE-003 in S03, a needs line per step, each `| -` (v0.26.10.12.3.1,
# R10: each row's test needs only its own step's code), `shared: web`) and the prose below it, the plan
# recorded by `plan.sh change create … --trigger initial`. $PT_REH is the rehearsal row ViD appends once the gate-1 row
# is gone, ROW-021.
# Helpers: `pt_set <id> <line>` replaces the line whose id field is <id> (the first field, or the second on a rule,
# difference, exception, suppression, hostility or seam line; `step S0n`, `standing <kind>`), in INVENTORY.md and
# PLAN.md and RUN-STATE's block, `pt_del <id>` deletes it (and its id from a needs line), `pt_after <id> <line>` adds a line after it; `pt_nogate1`
# removes the gate-1 row ROW-009 (and its place in step S04); `pt_nostage0` removes stage 0, the skeleton becoming
# ROW-004 alone and ROW-003 joining S02; `pt_rs <sed expression>` edits RUN-STATE; `pt_record` records the block as it
# stands (plan.sh change create); `pt_teams <line>…` appends `team: <line>` lines to .vid/tw/settings; `pt_check` runs `planner.sh check` into $T/out (the toy's five setup answers recorded in .vid/plan/setup, v0.26.10.26.7) (its status in $PT_RC); `pt_has <flag start>` fails
# unless a flag line starts so. Reads only files under checks/. Env: CHECKS, T, fail().
pt_toy() {
  mkdir -p "$1" && cd "$1"
  cp "$CHECKS/selftest/fixtures/prd-094-good.md" PRD.md
  cat > INVENTORY.md <<'EOF'
# JobDigest — TEST INVENTORY

## Rows

```vid-inventory
grammar: 0.9.3
ROW-001 | behavior | REQ-001 | anonymous | n/a | Each saved search gets one digest a day, holding only jobs it has not sent before. Fails if a job from one day's digest appears again in a later digest for the same search, or one search gets two digests on the same day. | REQ-001 | owed: spec-only — first stage | origin: REQ-001
ROW-002 | behavior | REQ-006 | anonymous | n/a | A subscriber can keep up to ten saved searches, and an eleventh is refused with a message that states the limit of ten. | REQ-006 | owed: prerequisite — the harness holds no subscriber with ten saved searches; paid in the slice that builds saved searches | origin: REQ-006
ROW-003 | surface | S01 | anonymous | S01/saved | The S01/saved state, as drawn, shows the saved search, its address and the line Check your inbox to confirm. | REQ-001, S01/saved | owed: spec-only — first stage | origin: design 2026-08-28 S01/saved
ROW-004 | journey | journey | anonymous | n/a | The new subscriber: hears of the board on a forum (off-screen), saves a search, confirms it, and reads the next morning's digest. transitions: 1. anonymous at S01 · search and email fields · save · S01/saved · a confirmation email is sent ; 2. anonymous at the confirmation email · Confirm link · click · S02/active · the saved search shows as active ; 3. subscriber at the next morning's digest · a listed job · open · the job's source page · the job opened is the one listed | REQ-001, REQ-002, REQ-005 | owed: spec-only — first stage | origin: thesis journeys
ROW-005 | journey | ingest | (process) | n/a | A feed's new job reaches the digest: the feed is read, the job stored once, matched and sent. transitions: 1. (process) at a configured feed · scheduled read · fetch · job parsed · the job is in the listings · 2. (process) at the listings · the same job on the second feed · merge · one listing · the job is listed once · 3. (process) at the digest run · a matching saved search · select · digest built · the job is in the next digest | REQ-001, INV-001 | owed: spec-only — first stage | origin: thesis journeys
ROW-006 | shell | shell | anonymous | n/a | Every page shows the header with the product's name, and the footer with the support address and the unsubscribe help link. | REQ-012 | owed: spec-only — first stage | origin: design 2026-08-28 C00
ROW-007 | reachability | navigation | anonymous | n/a | A digest's unsubscribe link opens the unsubscribe page with no sign-in (entry: the digest). | REQ-002 | owed: spec-only — first stage | origin: derivation 2026-08-28
ROW-008 | behavior | REQ-001 | (process) | n/a | an operator exists — the trigger that builds each saved search's digest every morning is registered in the deployed shape and fires daily. | REQ-001 | owed: spec-only — first stage | origin: derivation 2026-08-28 trigger
ROW-009 | behavior | REQ-005 | n/a | n/a | When a new version goes live, the saved searches already kept survive the move unchanged. Fails if, on the restored copy of production's data, a saved search is missing or its words, address or last-digest time differ. | REQ-005 | owed: paid by /vid deploy gate 1 — the rehearsal on a restored backup reads the saved searches | origin: domain
ROW-010 | behavior | REQ-002 | anonymous | n/a | On staging, a real digest's unsubscribe link stops every digest to that address within a day. Fails if a digest reaches the address more than a day after the click. | REQ-002 | owed: paid by /vid deploy gate 2 — staging's real mail provider delivers the digests | origin: REQ-002 | paid-at: gate-2 2026-09-01 deploy-log 4
ROW-011 | behavior | REQ-010 | operator:admin | n/a | Production's listings and saved searches are backed up daily, and the written restore steps bring them back. Fails if no backup on production is less than a day old. | REQ-010 | owed: paid by /vid deploy gate 3 — production's backups are read | origin: REQ-010
ROW-012 | behavior | listings | anonymous | n/a | The listings at the stated size of 10,000 active jobs show the newest first on every page. Fails if a page of the listings at 10,000 jobs is missing a job or out of order. | REQ-001 | owed: fixture-source — a 10,000-job snapshot from the first feed partner, expected with the partner's sandbox | origin: domain volume
ROW-013 | behavior | ingest | (process) | n/a | Reading the same feed twice leaves the listings as one read does (repeat-idempotence). Fails if a second read of an unchanged feed adds, removes or changes a listing. | INV-001 | tests/invariants/test_feed_repeat.py | proved-red: 1a2b3c4 | origin: domain property-form
ROW-014 | behavior | REQ-002 | anonymous | n/a | control of HOS-002: the allowed case works and its effect is observed (a subscriber who has not unsubscribed keeps getting the digest). | REQ-002 | owed: guard-first — the protection HOS-002 does not exist yet; paid in the slice that builds it | origin: derivation control
ROW-015 | behavior | ingest | (process) | n/a | A saved search keeps its words, its address and its last-digest time through a feed outage. At ingest: fails if a feed outage or re-read loses a saved search or resets its last-digest time. | REQ-005 | owed: spec-only — first stage | origin: REQ-005 cross-cutting
ROW-016 | behavior | digest-selection | (process) | n/a | A saved search keeps its words, its address and its last-digest time through a feed outage. At digest-selection: fails if a feed outage or re-read loses a saved search or resets its last-digest time. | REQ-005 | owed: spec-only — first stage | origin: REQ-005 cross-cutting
ROW-017 | behavior | search | anonymous | n/a | A search finds jobs listed under other common names of the same occupation. Fails if a golden-set query's must-appear job is missing from the first page, or a must-not-appear job outranks a must-appear one. | REQ-003 | owed: golden-set — tests/invariants/golden/synonyms.golden to be ratified | origin: REQ-003 | golden: tests/invariants/golden/synonyms.golden | divergence: DIF-001
ROW-018 | behavior | REQ-011 | operator:admin | n/a | Every digest that fails to send is in the operator's log with that day's count. Fails if a failed send is missing from the log. | REQ-011 | owed: owner-decision — OQ-3 | origin: REQ-011
ROW-019 | behavior | REQ-012 | anonymous | n/a | Every digest's footer gives a support address that reaches a person. Fails if a digest's footer has no support address. | REQ-012 | owed: spec-only — first stage | origin: REQ-012 | law-changed: A-005 amended this row's footer clause
ROW-020 | behavior | REQ-020 | anonymous | n/a | A subscriber's chosen send hour is the hour their digest is sent. Fails if a subscriber's chosen send hour is ignored. | REQ-020 | owed: spec-only — first stage | origin: REQ-020
rule | RULE-001 | Every digest carries the support address in its footer | sites: every digest template :: guarded: those rendering the support footer | 1 | owed: census-armed — no template exists yet; armed with the first | origin: REQ-012
rule | RULE-002 | Every digest carries a one-click unsubscribe link | checks/extractors/invariant.unsubscribe.sh | 1 | owed: census-armed — the extractor lists every digest template; armed with the first | origin: REQ-002
rule | RULE-003 | state-machine subscription.status: pending>active active>unsubscribed | sites: every write of subscription.status | 0 | owed: census-armed — no write site exists yet | origin: REQ-002
difference | DIF-001 | synonym matching | a fixed synonym table | the synonym service | the table covers the golden set's occupations | paying-step: staging — re-run the golden set against the real synonym service
difference | DIF-002 | background execution | the digest built inline in the calling process | queued and consumed by the worker | the same code builds it | paying-step: close run, profile=deployed
difference | DIF-003 | mail provider | a fake that records each message | the real mail provider | what a provider does with an address is its contract, not a product promise
exception | EXC-001 | the unsubscribe confirmation email | RULE-001 | it is a one-off reply to the subscriber, not a digest
exception | EXC-002 | the footer's support link | seam | a content link, not an outbound call
suppression | SUP-001 | digest:footer | RULE-001 | the extractor reads templates only by their file name | when the extractor reads every template
hostility | HOS-001 | Send the same job on both feeds at once; expect exactly one listing | protects: INV-001 | disable: remove the merge by source id from the ingest | tests/invariants/test_hostility_dupes.py | proved-red: 5e6f7a8
hostility | HOS-002 | Click an unsubscribe link, then run the next digest; expect no digest to that address | protects: REQ-002 | disable: skip the unsubscribe check in the digest run | owed: guard-first — the protection REQ-002 does not exist yet; paid in the slice that builds it
hostility | HOS-003 | Save the eleventh search twice at once; expect the cap to hold at ten | protects: ROW-002 | disable: remove the cap check from saving | owed: guard-first — the protection ROW-002 does not exist yet; paid in the slice that builds it
hostility | HOS-004 | Send a digest whose template lacks the footer; expect the census to name it | protects: RULE-001 | disable: drop the footer from the base digest template | owed: guard-first — the protection RULE-001 does not exist yet; paid in the slice that builds it
hostility | HOS-005 | Have the product send a subscriber's address to a feed source or a third party; expect no request to a feed source and nothing sent to a third party to carry it | protects: INV-002 | disable: the guard that protects INV-002 | owed: spec-only — ticket | origin: plan INV-002
rule | RULE-004 | Every field a subscriber gives, the search's words and the email address, is acted on beyond being checked and shown | sites: every field a subscriber fills in, on saving a search and confirming the address | 1 | owed: spec-only — ticket | origin: plan REQ-005
rule | RULE-005 | Every task the product queues and every schedule it sets, each feed's read, the morning digest run and the daily backup, is taken up by a worker | sites: every queued task and every schedule, each feed's read, the morning digest run and the daily backup | 1 | owed: spec-only — ticket | origin: plan REQ-001
```

## Provider seams

```vid-inventory
seam | SEAM-001 | the mail provider | digest delivery | chosen: D-001 | credentials: not-yet | probe: owed | evidence: tests/contract/test_mail.py + tests/contract/captured/mail.json | quirks: none yet | module: jobdigest/mail | match: mailer
seam | SEAM-002 | the first job feed | scheduled read of the partner's active jobs | chosen: D-002 | credentials: not-yet | probe: unreachable-risk(credentials not-yet) | evidence: owed | quirks: none yet
```
EOF
  mkdir -p tests/invariants/golden
  printf 'Provenance: hand-authored\nquery | must-appear | must-outrank | must-not-appear\nelectrician | Electrical technician | - | Electronics sales\n' > tests/invariants/golden/synonyms.golden
  cat > GRADING-CHECKLIST.md <<'EOF'
# JobDigest — GRADING CHECKLIST

## Standing lines (every project)

- **Harness attacks.** Check that the test harness itself has not been defeated.

## Domain lines

- **Digest repeats.** Check that no job reaches the same search's digest twice across days.
EOF
  cat > STAGES.md <<'EOF'
# JobDigest — STAGES

## The cut

```vid-stages
STAGE-0 | The walking skeleton | technical
STAGE-1 | The daily digest | features: FEAT-01 FEAT-03
STAGE-2 | Synonym-aware search | features: FEAT-02
row: ROW-003 -> STAGE-0
row: ROW-004 -> STAGE-0
```

## Stage 0 — The walking skeleton (technical)

- **Outcome:** one thin journey end to end: a visitor saves a search and reads the first digest.

## Stage 1 — The daily digest

- **Outcome:** a job seeker saves searches and reads one digest a day of new matching jobs, and can leave in one click.
- **In:** saved searches, the daily digest, unsubscribe, the support address, backups and the failure log.
- **Out:** matching by other names of the same occupation, which waits for stage 2.
- **What proves it done:** the subscriber's journey, from saving a search to reading the first digest, and its rows.

## Stage 2 — Synonym-aware search

- **Outcome:** a search also finds jobs listed under other names of the same occupation.
- **In:** the synonym-aware search.
- **Out:** nothing else waits.
- **What proves it done:** the agreed set of test searches finds what it must, in the right order.
EOF
  cat > PLAN.md <<'EOF'
# JobDigest — PLAN

## Rows

```vid-rows
standing rehearsal | ROW-009
standing sign-in | none: subscribers never sign in; leaving takes one click, with no sign-in (REQ-002)
standing fields | RULE-004
standing work | RULE-005
```
EOF
  printf '# JobDigest — ARCHITECTURE\n\n| Module | Responsibility | Owned tables/data | Public surface | Dependents |\n|---|---|---|---|---|\n| web | the pages | none | the pages | none |\n| ingest | reading the feeds | listings | the listings | digest |\n| digest | the morning digest | saved searches | the digest run | none |\n| mail | sending mail | none | send | digest |\n| search | synonym-aware search | synonyms | search | digest |\n' > ARCHITECTURE.md
  mkdir -p .vid; cat > .vid/RUN-STATE.md <<'EOF'
run: active
session: S1
mode: tickets
plan: required
stage: 0

## The plan

```vid-plan
step S01 | name: save a search and read the first digest | modules: web digest | builds-on: - | rows: ROW-003 ROW-004 | lane: devagent | kind: skeleton
step S02 | name: new jobs only, each listed once | modules: ingest digest | builds-on: S01 | rows: ROW-001 ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 SEAM-002 DIF-002 RULE-005 | lane: devagent
step S03 | name: the footer, unsubscribe and the mail provider | modules: web mail | builds-on: S01 | rows: ROW-006 ROW-007 ROW-010 ROW-014 ROW-019 RULE-001..RULE-003 HOS-002 HOS-004 SEAM-001 HOS-005 | lane: devagent
step S04 | name: limits, backups, failures and the data move | modules: digest ingest | builds-on: S02 S03 | rows: ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004 | lane: devagent
step S05 | name: synonym-aware search | modules: search | builds-on: S02 | rows: ROW-017 | lane: devagent
needs ROW-003 ROW-004 | -
needs ROW-001 ROW-005 ROW-008 ROW-012 ROW-013 ROW-015 ROW-016 HOS-001 SEAM-002 DIF-002 RULE-005 | -
needs ROW-006 ROW-007 ROW-010 ROW-014 ROW-019 RULE-001 RULE-002 RULE-003 HOS-002 HOS-004 SEAM-001 HOS-005 | -
needs ROW-002 ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004 | -
needs ROW-017 | -
shared: web
```

S02 and S03 run side by side: the feeds and the mail share no module. S04 builds on S02 for the listings and on S03
for the mail; S05 builds on S02 for the listings. Stage 2 is a draft, planned again at stage 1's close.
EOF
  printf 'stage name=plan state=start session=S1 records=29 at=2026-11-03T09:00:00Z\ncontext-window requested=declined at=2026-11-03T09:00:00Z\n' > .vid/metrics-events   # v0.26.10.26.7 (R13): the compaction question answered
  mkdir -p .vid/plan; for k in layout team split repo spec-repo github-mode; do printf 'setup-answered key=%s value="the toy" words="the toy, answered" at=2026-11-03T09:00:00Z\n' "$k"; done > .vid/plan/setup   # v0.26.10.26.7 (R11): the toy's setup answered; github-mode (v0.26.10.28.8, R3) too
  pt_record
}
pt_rs() { sed "$1" .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x; }   # a sed of RUN-STATE's block
pt_record() { sh "$CHECKS/plan.sh" change create 'the first plan' --trigger initial --expect 'the skeleton ticket goes first' > /dev/null 2>&1; }
pt_ed() { for f in INVENTORY.md PLAN.md .vid/RUN-STATE.md; do awk -v id="$1" -v l="${3-}" -v m="$2" '
  { x = $0; n = split(x, a, "|"); k = a[1]; gsub(/^[ \t]+|[ \t]+$/, "", k)
    if (k ~ /^(rule|difference|exception|suppression|hostility|seam)$/) { k = a[2]; gsub(/^[ \t]+|[ \t]+$/, "", k) } }
  m == "del" && /^needs / { gsub(" " id " ", " "); if ($0 ~ /^needs [A-Z]/) print; next }   # R10: a row deleted leaves its needs line
  k != id { print; next } m == "set" { print l; next } m == "after" { print; print l }' "$f" > "$f.x" && mv "$f.x" "$f"; done; }
pt_set() { pt_ed "$1" set "$2"; }
pt_del() { pt_ed "$1" del; }
pt_after() { pt_ed "$1" after "$2"; }
pt_nogate1() { pt_del ROW-009; sed 's/^\(step S04 .*\) ROW-009 /\1 /' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x; }
pt_nostage0() { grep -v -e '^STAGE-0 ' -e 'STAGE-0$' STAGES.md > S.x && mv S.x STAGES.md
  sed -e 's/^\(step S01 .*\)rows: ROW-003 ROW-004 /\1rows: ROW-004 /' -e 's/^\(step S02 .*rows:\) /\1 ROW-003 /' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x; }
PT_REH="ROW-021 | behavior | REQ-005 | n/a | n/a | When a new version goes live, the saved searches already kept survive the move unchanged. Fails if, on the restored copy of production's data after the move, a saved search is missing or its words, its address or the time of its last digest differ. | REQ-005 | owed: paid by /vid deploy gate 1 — the rehearsal on a restored backup reads the saved searches after the move | origin: plan REQ-005"
pt_teams() { mkdir -p .vid/tw; for l; do printf 'team: %s\n' "$l" >> .vid/tw/settings; done; }   # v0.26.10.12.3.1 (R1)
pt_check() { PT_RC=0; sh "$CHECKS/planner.sh" check > "$T/out" 2>&1 || PT_RC=$?; }
pt_has() { grep -q "^$1" "$T/out" || fail "not flagged: $1"; }
