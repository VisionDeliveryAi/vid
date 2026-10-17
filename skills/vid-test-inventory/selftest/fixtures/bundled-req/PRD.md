# JobDigest — PRD

> **Precedence rule:** the base of this file (everything above `## Appends`)
> is immutable after final ratification. All change is appended under
> `## Appends`. Later appends win over the base and over earlier appends.
> Authority order within the record: Seed and human answers > ratified
> thesis > sources > model proposals.

## Seed

I want a small job-alert product: two source feeds, merged into one
listing store, and subscribers save searches and get an email digest of
new matches. Search must understand occupational synonyms — exact-title
matching is the failure mode I am paying to avoid. Email-first: no
mobile app, no social features.

## Thesis

### Product summary

JobDigest merges two job feeds into one deduplicated listing store and
delivers per-search daily email digests of new matches to subscribers.

### Primary users

Job seekers in niche trades who save a handful of targeted searches and
read email daily.

### MVP focus

- G1: A subscriber receives a daily digest per saved search containing only new matches.
- G2: Matching understands occupational synonyms rather than exact titles.

### Explicitly not MVP

A mobile app, social features, hosted applications, employer accounts.

### Required core flows

- A subscriber saves a search and starts receiving digests for it.

### Value logic

The digest is the product: a subscriber hands over an email address only
while the alerts stay trustworthy — no repeats, no misses, easy exit.

### Evidence basis

No source conflicts: the seed is the only source in this run.

## Actors and journeys

### Subscriber

1. Hears about the board from a trade forum (off_screen)
2. Saves a search and confirms the address
3. Reads the next morning's digest and opens two listings
4. Applies on the source posting site (off_screen)

## Mechanisms

```vid-prd-mechanisms
MECH-01 | G1 | Feeds are polled on a schedule and normalised into one listing store. | stated: seed "two source feeds, merged"
MECH-02 | G2 | Relevance rests on a synonym-aware matching layer. | stated: answer A-002
```

## Content contract

```vid-prd-contract
DIM-notifications | Notifications — triggers, preferences, delivery | mechanism | required | covered_by: functional, data_entity, ux_flow | status: covered
DIM-consent | Contact permission and consent handling | mechanism | required | covered_by: functional, nfr, constraint, data_entity, ux_flow | status: covered
DIM-nfr-operability | Operability — backup, observability, support | nfr | required | covered_by: nfr, constraint, functional | facets: backup, observability, support | status: covered
DIM-proof-thresholds | Decidable success thresholds | proof | required | covered_by: metric, outcome, nfr, constraint, hypothesis | status: covered
DIM-seo-technical | Technical SEO contract | mechanism | case-by-case | covered_by: functional, nfr, constraint | status: na owner 2026-08-27 A-004
DIM-feed-trust | Source-feed trust and takedown | mechanism | required | covered_by: functional, invariant, constraint | prompt: what happens when a source feed sends garbage, and who can pull a listing | status: covered
```

## Criticality tiers

- **T0** — must never break or leak.
- **T1** — core behavior; getting it wrong is a defect.
- **T2** — desirable; getting it wrong is a fix-round item.

## Items

```vid-prd
REQ-001 | functional | T1 | P0 | A subscriber receives one digest per saved search per day; a digest contains only matches new since the last digest for that search; and a listing present in both feeds appears once in any digest. | fail-if: a digest repeats a job already delivered for that search, or two digests for one search arrive in one day | serves: trust in the alert channel — the reason a user hands over an email address | authority: authoritative | source: seed, A-001 | covers: DIM-notifications | derives: trigger-row
REQ-002 | functional | T1 | P0 | Every digest carries a working one-click unsubscribe that stops all digests for that address. | fail-if: a digest arrives after its address unsubscribed, or the unsubscribe link requires a sign-in | serves: consent exit — the trust floor of an email product | authority: authoritative | source: seed | covers: DIM-consent
REQ-003 | nfr | T1 | P1 | Search returns relevant results for occupational synonyms. | fail-if: a golden-set query's must-appear result is absent from the first page, or a must-not-appear result outranks a must-appear one | serves: the product's one differentiating promise | authority: provisional | confirms_via: measurement/yes | source: A-002 | derives: golden-set
REQ-005 | data_entity | T1 | P0 | A saved search stores its query terms, its owning address, and the timestamp of the last digest sent, and survives feed outages. | fail-if: a feed outage or re-poll loses a saved search or resets its last-sent timestamp | serves: the digest join — new-since-last is computed from this entity | authority: authoritative | source: thesis | covers: DIM-notifications | cross-cutting: ingest, digest-selection
REQ-006 | functional | T2 | P2 | A subscriber can hold up to ten saved searches; creating an eleventh is refused with the cap stated. | fail-if: an eleventh saved search is accepted, or the refusal does not state the cap | serves: bounds ingest and digest cost at MVP scale | authority: provisional | confirms_via: owner-decision/no | source: A-005
REQ-010 | nfr | T2 | P2 | The listing store and saved searches are backed up daily and a restore path exists. | fail-if: a store loss loses more than one day of saved searches, or no documented restore path exists | serves: the product's memory — subscribers will not re-enter searches | authority: authoritative | source: thesis | covers: DIM-nfr-operability/backup
REQ-011 | nfr | T2 | P2 | Digest delivery failures surface in an operator-visible log with a daily failure count. | fail-if: a day of failed sends leaves no operator-visible trace | serves: operators learn the product is broken before subscribers do | authority: authoritative | source: thesis | covers: DIM-nfr-operability/observability
REQ-012 | functional | T2 | P2 | Every digest footer carries a support contact address that reaches a person. | fail-if: the footer lacks a support address, or mail to it bounces | serves: a stuck subscriber has a path that is not silent churn | authority: authoritative | source: thesis | covers: DIM-nfr-operability/support
REQ-020 | functional | T1 | P1 | The digest send hour is configurable per subscriber. | fail-if: a subscriber's chosen send hour is ignored | serves: digests land when each subscriber actually reads mail | authority: pending | confirms_via: owner-decision OQ-1/no | source: thesis
INV-001 | invariant | T0 | - | A job present in both feeds appears once in the listing store. | serves: listing integrity — duplicates read as spam and double-count metrics; guards the seam where ingest meets the digest join | authority: authoritative | source: seed | covers: DIM-feed-trust | spans: REQ-001, REQ-005
NG-001 | non_goal | - | - | The product does not host applications; apply always hands off to the source posting. | serves: keeps the product out of applicant-data custody | authority: authoritative | source: A-003
MET-001 | metric | - | - | Digest open rate over a rolling 28-day window, denominator delivered digests, weak band below thirty percent, kill band below fifteen. | serves: the one number that says the alert channel is trusted | authority: authoritative | source: thesis | covers: DIM-proof-thresholds
```

## Answer ledger

```vid-prd-answers
A-001 | human | 2026-08-27 | Q: one digest per search or one combined? | A: per search — combined digests bury the niche searches | settles: REQ-001
A-002 | human | 2026-08-27 | Q: what does good search mean here? | A: synonym-aware; exact-title-only is the failure mode | settles: REQ-003, MECH-02
A-003 | human | 2026-08-27 | Q: do we host applications? | A: no — always hand off to the source posting | settles: NG-001
A-004 | human | 2026-08-27 | Q: is organic search an MVP channel? | A: no — distribution is email-first; technical SEO is out for MVP | settles: DIM-seo-technical
A-005 | model_proposed | 2026-08-27 | Q: how many saved searches per subscriber? | A: cap at ten for MVP, standing default | settles: REQ-006
A-006 | human | 2026-08-27 | Q: the contract sitting — which floor dimensions are struck, and how are the case-by-case entries ruled? | A: thirteen floor dimensions struck as out of this product's scope; technical SEO ruled in then NA'd on the audit's question; i18n ruled out | settles: contract
```

## Open decisions

VID-QUESTION: (OQ-1) Should the send hour be configurable per subscriber, and if so what is the default hour?

RESOLVED: (OQ-2) A-005 — How many saved searches may a subscriber hold?

## Findings

### 2026-08-27 — pause 1 sitting

```vid-prd-findings
F-01 | red-team | blocking | MECH-02 | routed OQ-1 | evidence: relevance rests on an answer while delivery timing stays undecided — the owner carrier holds it
F-02 | red-team | advisory | thesis | noted | evidence: value logic assumes email is read daily; nothing downstream changes if it is not
```

### 2026-08-27 — pause 3 sitting

```vid-prd-findings
F-03 | review | blocking | REQ-002 | repaired | evidence: the fail-if omitted the within-one-day bound the consent exit needs — repaired by the REQ-002 AMENDED append
F-04 | audit | advisory | DIM-seo-technical | accepted A-004 | evidence: organic search ruled out of MVP by the owner; the NA carries the ruling
F-05 | audit | advisory | REQ-006 | routed OQ-2 | evidence: the cap was a standing default; routed to the owner and later resolved by A-005 — the carrier is resolved, the reference still stands
```

## Ratifications

- 2026-08-27 — thesis+contract — 1111111
- 2026-08-27 — gap answers — 2222222
- 2026-08-27 — final — 3333333

## Appends

### 2026-08-28 (owner answer)

```vid-prd
REQ-002 AMENDED | functional | T1 | P0 | Every digest carries a working one-click unsubscribe that stops all digests for that address within one day. | fail-if: a digest arrives more than one day after its address unsubscribed, or the unsubscribe link requires a sign-in | serves: consent exit — the trust floor of an email product | authority: authoritative | source: seed | covers: DIM-consent
```

### 2026-08-29 (owner answer — the saved-search cap ruled by hand)

```vid-prd-answers
A-005 AMENDED | human | 2026-08-29 | Q: how many saved searches per subscriber? | A: ten confirmed as the launch cap — an owner ruling superseding the standing default | settles: REQ-006
```
