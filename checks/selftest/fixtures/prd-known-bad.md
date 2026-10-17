# BadDigest — PRD (known-bad court fixture)

<!-- Every seeded violation carries an adjacent `#` annotation naming the
     §5 join it must trip, so a future court edit that stops convicting
     is diagnosable. `#` lines inside machine blocks are ignored by the
     court. -->

> **Precedence rule:** the base of this file (everything above `## Appends`)
> is immutable after final ratification. All change is appended under
> `## Appends`. Later appends win over the base and over earlier appends.

## Seed

A job-alert product: two source feeds, merged into one listing store,
daily digests per saved search, synonym-aware matching, email-first.

## Thesis

### Product summary

Merges two job feeds and sends per-search daily digests.

### Primary users

Job seekers in niche trades.

### MVP focus

- G1: Daily digest per saved search.
- G2: Synonym-aware matching.
- G3: Employers can boost a listing.
<!-- join 11 (violation 15): G3 has no mechanisms row and no open question. -->

### Explicitly not MVP

Mobile app, social features.

### Required core flows

- A subscriber saves a search and receives digests.

### Value logic

Trustworthy alerts.

### Evidence basis

No source conflicts.

## Actors and journeys

### Subscriber

1. Hears about the board (off_screen)
2. Saves a search
3. Reads the digest

## Mechanisms

```vid-prd-mechanisms
MECH-01 | G1 | Feeds are polled on a schedule and normalised into one listing store. | stated: seed "two source feeds, merged"
# join 11 (violation 16): the excerpt below is not verbatim in the Seed section.
MECH-02 | G2 | Relevance rests on a synonym-aware matching layer. | stated: seed "a phrase that appears nowhere in the seed"
```

## Content contract

```vid-prd-contract
# join 9 (violation 13): 25 dimensions — one past the hard cap of 24.
# join 9 (violation 8): DIM-consent is uncited by any item and carries no owner NA.
DIM-consent | Contact permission and consent handling | mechanism | required | covered_by: functional, nfr, constraint, data_entity, ux_flow | status: covered
DIM-identity | Identity, accounts and access tiers | mechanism | required | covered_by: functional, data_entity, ux_flow, constraint | facets: tiers, signin_reauth, verification | status: na owner 2026-08-30 A-101
DIM-lifecycle | Entity time-lifecycle | mechanism | required | covered_by: functional, data_entity, invariant, constraint | status: covered
DIM-operations | Operational and admin surfaces | mechanism | required | covered_by: functional, ux_flow, data_entity | status: na owner 2026-08-30 A-101
DIM-feedback-intake | Corrections and user feedback handling | mechanism | required | covered_by: functional, data_entity, ux_flow | status: na owner 2026-08-30 A-101
DIM-trust-states | Trust-state production and freshness | mechanism | required | covered_by: functional, data_entity, invariant, constraint, nfr | status: na owner 2026-08-30 A-101
DIM-authorization | Authorization — grants and denials | mechanism | required | covered_by: functional, nfr, invariant, constraint, data_entity, ux_flow | status: na owner 2026-08-30 A-101
DIM-notifications | Notifications — triggers, preferences, delivery | mechanism | required | covered_by: functional, data_entity, ux_flow | status: covered
DIM-data-integrity | Data identity, dedup and provenance | mechanism | required | covered_by: functional, data_entity, invariant, nfr, constraint | facets: record_identity, required_fields, dedup, provenance | status: na owner 2026-08-30 A-101
DIM-nfr-security | NFR — security | nfr | required | covered_by: nfr, constraint, invariant, functional | status: na owner 2026-08-30 A-101
DIM-nfr-privacy | NFR — privacy and data protection | nfr | required | covered_by: nfr, constraint, functional, data_entity | status: na owner 2026-08-30 A-101
DIM-nfr-availability | NFR — availability and performance | nfr | required | covered_by: nfr, constraint | status: na owner 2026-08-30 A-101
DIM-nfr-accessibility | NFR — accessibility | nfr | required | covered_by: nfr, constraint | status: na owner 2026-08-30 A-101
# join 9 (violation 11): faceted dimension with uncited facets — only backup is cited; observability and support are not.
DIM-nfr-operability | Operability — backup, observability, support | nfr | required | covered_by: nfr, constraint, functional | facets: backup, observability, support | status: covered
DIM-proof-thresholds | Decidable success thresholds | proof | required | covered_by: metric, outcome, nfr, constraint, hypothesis | status: na owner 2026-08-30 A-101
DIM-instrumentation | Instrumentation for the declared metrics | proof | required | covered_by: functional, nfr, metric | status: na owner 2026-08-30 A-101
DIM-core-loop-continuity | Core-loop continuity | mechanism | required | covered_by: functional, ux_flow, data_entity | status: na owner 2026-08-30 A-101
DIM-seo-technical | Technical SEO contract | mechanism | case-by-case | covered_by: functional, nfr, constraint | status: na owner 2026-08-30 A-101
DIM-i18n-locale | Internationalisation and locale display | mechanism | case-by-case | covered_by: functional, nfr, constraint | status: na owner 2026-08-30 A-101
# join 9 (violation 12): a panel-added dimension (id outside the catalog) with no prompt: line.
DIM-panel-noprompt | Listing takedown authority | mechanism | required | covered_by: functional, invariant, constraint | status: na owner 2026-08-30 A-101
DIM-panel-a | Feed contract drift | mechanism | required | covered_by: functional, invariant | prompt: what happens when a feed changes shape silently | status: na owner 2026-08-30 A-101
DIM-panel-b | Digest content bounds | mechanism | required | covered_by: functional, constraint | prompt: how many listings a digest may carry and what overflow does | status: na owner 2026-08-30 A-101
DIM-panel-c | Address lifecycle | mechanism | required | covered_by: functional, data_entity | prompt: what happens to digests when an address hard-bounces | status: na owner 2026-08-30 A-101
DIM-panel-d | Search-term hygiene | mechanism | required | covered_by: functional, constraint | prompt: what a malformed or abusive saved search does | status: na owner 2026-08-30 A-101
DIM-panel-e | Listing freshness display | mechanism | required | covered_by: functional, nfr | prompt: how stale a listing may look before it is misleading | status: na owner 2026-08-30 A-101
```

## Criticality tiers

- **T0** — must never break or leak.
- **T1** — core behavior.
- **T2** — desirable.

## Items

```vid-prd
# join 3 (violation 1): a demand row with no fail-if:.
REQ-101 | functional | T1 | P0 | A subscriber receives one digest per saved search per day. | serves: trust in the alert channel | authority: authoritative | source: seed | covers: DIM-notifications
# join 3 (violation 2): a frame row carrying a fail-if:.
INV-101 | invariant | T0 | - | A job present in both feeds appears once. | fail-if: a duplicate listing renders | serves: listing integrity | authority: authoritative | source: seed
# join 2 (violation 3): an open enum value — `feature` is not one of the 11 types.
REQ-102 | feature | T1 | P0 | Subscribers can pause a saved search. | fail-if: a paused search still sends digests | serves: vacation control | authority: authoritative | source: seed
# join 5 (violation 4): a provisional row with no confirms_via:.
REQ-103 | functional | T2 | P2 | A subscriber can hold up to ten saved searches. | fail-if: an eleventh saved search is accepted | serves: bounds MVP cost | authority: provisional | source: thesis
# join 6 (violation 5): a pending row claiming covers.
REQ-104 | functional | T1 | P1 | Listings expire from the store after a retention window. | fail-if: an expired listing appears in a digest | serves: freshness of the store | authority: pending | confirms_via: owner-decision OQ-9/yes | source: thesis | covers: DIM-lifecycle
# join 7 (violation 6): a pending item whose settling answer is live in the ledger (A-103).
REQ-105 | functional | T1 | P1 | The digest send hour is configurable per subscriber. | fail-if: a chosen send hour is ignored | serves: digests land when subscribers read mail | authority: pending | confirms_via: owner-decision OQ-10/yes | source: thesis
# join 12 (violation 17): the two rows below carry the same statement.
REQ-106 | functional | T1 | P1 | A subscriber can delete a saved search and deletion stops its digests. | fail-if: a digest arrives for a deleted search | serves: subscriber control of the loop | authority: authoritative | source: seed | covers: DIM-lifecycle
REQ-107 | functional | T1 | P1 | A subscriber can delete a saved search and deletion stops its digests. | fail-if: a deleted search keeps its listing matches | serves: subscriber exit from one search | authority: authoritative | source: seed | covers: DIM-notifications
# join 9 (violation 9): covers: naming a ghost dimension and a ghost facet.
REQ-108 | nfr | T2 | P2 | Store restore is rehearsed monthly. | fail-if: a restore rehearsal is skipped for a calendar month | serves: backup that provably restores | authority: authoritative | source: thesis | covers: DIM-ghost, DIM-nfr-operability/ghostfacet
REQ-109 | nfr | T2 | P2 | The listing store is backed up daily. | fail-if: a store loss loses more than one day | serves: the product's memory | authority: authoritative | source: thesis | covers: DIM-nfr-operability/backup
# join 4 (violation 19): a demand row with no serves:.
REQ-110 | functional | T2 | P2 | Digest footers carry a support contact address. | fail-if: the footer lacks a support address | authority: authoritative | source: thesis
# join 9 (violation 10): a type-ineligible citation — metric is not in DIM-notifications' covered_by.
MET-101 | metric | - | - | Digest open rate over a rolling 28-day window, denominator delivered digests. | serves: the trust number | authority: authoritative | source: thesis | covers: DIM-notifications
# join 12 (violation 23): spans citing an item that exists nowhere in the effective set.
INV-102 | invariant | T0 | - | A digest never mixes two subscribers' saved searches. | serves: subscriber isolation at the send seam | authority: authoritative | source: seed | spans: REQ-999
# join 2 (violation 24): a cross-cutting: marker naming no surface.
REQ-111 | functional | T2 | P2 | Digest sends are throttled per sending provider. | fail-if: a provider burst exceeds its stated send rate | serves: deliverability across every surface that sends | authority: authoritative | source: thesis | cross-cutting:
# join 5 (violation 25): a pending row whose carrier (OQ-11) is already RESOLVED — the item must be amended.
REQ-112 | functional | T2 | P2 | Digests carry a listing count in the subject line. | fail-if: the subject omits the count | serves: triage at a glance | authority: pending | confirms_via: owner-decision OQ-11/no | source: thesis
```

<!-- join 10 (violation 14): zero non_goal rows anywhere in this fixture. -->

## Answer ledger

```vid-prd-answers
A-101 | human | 2026-08-30 | Q: which catalog dimensions are out for this MVP? | A: the listed dimensions are out of MVP scope | settles: DIM-identity, DIM-operations, DIM-feedback-intake, DIM-trust-states, DIM-authorization, DIM-data-integrity, DIM-nfr-security, DIM-nfr-privacy, DIM-nfr-availability, DIM-nfr-accessibility, DIM-proof-thresholds, DIM-instrumentation, DIM-core-loop-continuity, DIM-seo-technical, DIM-i18n-locale, DIM-panel-noprompt, DIM-panel-a, DIM-panel-b, DIM-panel-c, DIM-panel-d, DIM-panel-e
# join 7 (violation 6, the answer half): A-103 settles pending item REQ-105 while it is still pending.
A-103 | human | 2026-08-30 | Q: is the send hour configurable? | A: yes, per subscriber, default 08:00 | settles: REQ-105 | unchanged: REQ-999
# join 8 (violation 7): an untraced answer — REQ-888 exists nowhere.
A-104 | human | 2026-08-30 | Q: do we dedupe across feeds? | A: yes, one listing per job | settles: REQ-888 | notes: dedupe by title
```

## Open decisions

VID-QUESTION: (OQ-9) What is the listing retention window?

VID-QUESTION: (OQ-10) Should the send hour be configurable per subscriber?

RESOLVED: (OQ-11) A-104 — Do digest subjects carry a count?

<!-- join 8 (violation 26): a RESOLVED carrier naming an answer that does not exist. -->
RESOLVED: (OQ-12) A-777 — Are digests grouped by search?

## Findings

### 2026-08-30 — pause 1 sitting

```vid-prd-findings
# join 13 (violation 21): a blocking finding merely noted — the lock taken while the red team still objects.
F-901 | review | blocking | REQ-101 | noted | evidence: the digest row has no falsifier at all
# join 13 (violation 22): a finding whose target exists nowhere in the record.
F-902 | red-team | advisory | REQ-888 | noted | evidence: a target outside the set cannot be repaired or verified
```

## Ratifications

- 2026-08-30 — thesis+contract — 4444444

## Appends

### 2026-08-31 (owner answer)

```vid-prd
# join 12 (violation 18): an AMENDED row whose ID has no earlier ancestor.
REQ-777 AMENDED | functional | T1 | P1 | Digests group listings by saved search. | fail-if: a digest interleaves two searches' listings | serves: digest legibility | authority: authoritative | source: seed
```

```vid-prd-answers
# join 12 (violation 20): an AMENDED answer whose ID has no earlier ledger row.
A-999 AMENDED | human | 2026-08-31 | Q: are digests grouped? | A: yes, by saved search | settles: REQ-106
```
