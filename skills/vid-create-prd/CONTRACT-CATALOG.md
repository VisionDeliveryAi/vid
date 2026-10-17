# Content-contract catalog — the 19-dimension floor

**Source:** carried over verbatim-in-substance from the pinned PDLC
default content contract (evidence:
`pdlc_v3/products/*/inputs/INPUT-prd-content-contract/prd_content_contract.v1.yaml`,
identical across both sealed example runs; the WOD seal cites all 19).
Item-type names are mapped to ViD's closed type list (the source's
`functional_requirement` is ViD's `functional`); everything else —
categories, demand, covered_by, facets, prompts with their boundary
clauses, defect-class provenance — is carried unchanged in substance.

**This file's law:**

- This catalog is **the floor each lens starts from, not the ceiling.**
  Every run's contract panel begins here; the fresh-lens panel proposes
  product-specific extensions on top; the owner ratifies the merged list
  at pause 1 — striking, merging, adding, and ruling every
  `case-by-case` dimension explicitly in or out.
- The entry rule, imported verbatim as contract law: *"a dimension that
  cannot name its defect class does not enter."* For catalog dimensions
  the defect class is the measured post-seal finding recorded below; for
  panel-added dimensions it is the `prompt:` line, and a panel proposal
  without one is refused at the sitting.
- **Hard cap: 24 dimensions** in any ratified contract — a contract that
  grows past recognition speed stops being ratifiable at recognition
  speed. The court refuses a larger one.
- Dimension ids are **stable** — a rename is a new id.
- This file is read by the contract panel and the completeness-audit
  pass. It is never installed into projects: the ratified contract in
  PRD.md is the project's record.

Categories: `mechanism` | `nfr` | `proof`. Demand: `required` |
`case-by-case`. `covered_by` lists the item types whose `covers:`
citations are legal for the dimension. Where `facets` are declared,
citations are facet-qualified and closure is per facet.

---

## DIM-identity — Identity, accounts & access tiers

- **category:** mechanism · **demand:** required
- **covered_by:** functional, data_entity, ux_flow, constraint
- **facets:** tiers, signin_reauth, verification
- **Covered means** a builder can answer without inventing, per facet:
  `tiers` — what user tiers exist (e.g. registered vs email-only
  subscriber) and which capabilities each has; `signin_reauth` —
  whether/how sign-in and re-authentication work; `verification` —
  whether identity verification (e.g. email confirmation) exists. If the
  product has any per-user state, this dimension applies. Boundary:
  contact permission belongs to DIM-consent; who may do what to which
  resource belongs to DIM-authorization.
- **Defect class:** the build team invents the entire auth/identity tier
  structure because "registered or subscribed" is load-bearing and
  undefined (evidence: wod-v3 F1 — both reviewers' highest-impact
  finding).

## DIM-consent — Contact permission & consent handling

- **category:** mechanism · **demand:** required
- **covered_by:** functional, nfr, constraint, data_entity, ux_flow
- **Covered means:** what contact permission is captured and when,
  whether transactional and marketing contact are separated, how a user
  withdraws consent or unsubscribes, and what happens to their data on
  account deletion. Applies to any product that stores contact details.
- **Defect class:** an email-loop product ships without consent
  separation, unsubscribe, or withdrawal — a compliance obligation, not
  polish (evidence: wod-v3 F7; v2 Q-015 died at the regeneration
  boundary).

## DIM-lifecycle — Entity time-lifecycle

- **category:** mechanism · **demand:** required
- **covered_by:** functional, data_entity, invariant, constraint
- **Covered means:** for each core entity with a temporal dimension
  (scope rule: every data_entity item whose statement carries dates,
  windows, or an active/inactive notion — mechanically enumerable from
  the item set), what states it passes through, what triggers each
  transition, and what each state means for visibility, editing, and
  notifications. Name the states; "handled appropriately" is not a
  state. Boundary: trust/quality states belong to DIM-trust-states;
  notification triggers to DIM-notifications.
- **Defect class:** core entities have no defined
  past/cancelled/postponed/expired behaviour; the team improvises
  transitions in week one (evidence: wod-v3 F5 — load-bearing where
  other rules depend on "future date").

## DIM-operations — Operational & admin surfaces

- **category:** mechanism · **demand:** required
- **covered_by:** functional, ux_flow, data_entity
- **Covered means:** every workflow that requires human review or
  operational action names the surface it happens on, the actor, the
  possible outcomes, and the states in between. If a requirement creates
  a queue, something must consume the queue.
- **Defect class:** user-facing intakes exist with no operator-facing
  review side — claims are reviewed by nobody specified, with no
  rejection, competing-claim, or revocation behaviour (evidence: wod-v3
  F2).

## DIM-feedback-intake — Corrections & user feedback handling

- **category:** mechanism · **demand:** required
- **covered_by:** functional, data_entity, ux_flow
- **Covered means:** what happens AFTER a user submits a correction,
  report, or piece of feedback — where it lands, who reviews it, what
  statuses it can reach, how it is applied, and whether the submitter
  learns the outcome. Intake without resolution is not coverage.
- **Defect class:** a correction/report submission path exists and
  terminates in a void — no entity, no review flow, no outcome; a
  /dev/null form passes acceptance (evidence: wod-v3 F3; the seed's own
  "corrections go to moderation" was shed at the thesis hop).

## DIM-trust-states — Trust-state production & freshness

- **category:** mechanism · **demand:** required
- **covered_by:** functional, data_entity, invariant, constraint, nfr
- **Covered means:** for every trust or quality state shown to users,
  what act or actor produces it, what removes it, and what clock governs
  staleness. A state with no producer is decoration.
- **Defect class:** trust states are display-side only — "verified" has
  no producer, freshness has no clock, staleness has no rule; the state
  machine must be invented (evidence: wod-v3 F4; seed §7/§17 shed at the
  thesis hop).

## DIM-authorization — Authorization: grants and denials

- **category:** mechanism · **demand:** required
- **covered_by:** functional, nfr, invariant, constraint, data_entity,
  ux_flow
- **Covered means:** for each granted capability, who is DENIED it and
  what happens on a denied attempt; which fields or actions are reserved
  from otherwise-authorized editors. Every grant needs its boundary.
- **Defect class:** capabilities are granted with no matching denial —
  owners can edit, nothing forbids non-owners; protected fields are
  unspecified (evidence: wod-v3 F2 / Codex finding 1).

## DIM-notifications — Notifications: triggers, preferences, delivery

- **category:** mechanism · **demand:** required
- **covered_by:** functional, data_entity, ux_flow
- **Covered means:** the concrete trigger list (what events cause a
  notification), what the user can configure, and what delivery state is
  tracked. If notifications carry the product's return loop, the
  triggers ARE the mechanism — name them. Boundary: unsubscribe and
  consent withdrawal belong to DIM-consent.
- **Defect class:** the retention loop rests on "reminders when
  available" — no trigger catalogue, no preferences, no unsubscribe, an
  escape hatch that makes the fail condition unassertable (evidence:
  wod-v3 F6/loss 2; seed §9.5 triggers shed at the thesis hop).

## DIM-data-integrity — Data identity, dedup & provenance recording

- **category:** mechanism · **demand:** required
- **covered_by:** functional, data_entity, invariant, nfr, constraint
- **facets:** record_identity, required_fields, dedup, provenance
- **Covered means,** per facet: `record_identity` — what makes two
  records the same record; `dedup` — how duplicates are prevented or
  merged; `required_fields` — which fields are required for a record to
  exist; `provenance` — whether data changes record their origin
  (who/when/source).
- **Defect class:** records duplicate or fragment silently, and edits
  carry no recorded origin — dedup rules and canonical identity left to
  the build team (evidence: v2 §8/§9 slot; partially covered in wod-v3,
  kept as a dimension so the coverage is a decision, not luck).

## DIM-nfr-security — NFR: security

- **category:** nfr · **demand:** required
- **covered_by:** nfr, constraint, invariant, functional
- **Covered means** minimum bars, not elaborate targets:
  session/credential handling posture, protection of private user data
  at rest and in transit, and abuse controls on public-facing intakes
  (claims, corrections, invites). "Industry standard" without naming the
  bar is not coverage.
- **Defect class:** a public product handling identities, ownership
  claims, and direct content editing ships with no stated security floor
  (evidence: wod-v3 F7 — five thesis-posture NFRs satisfied the type
  slot while security went unstated; v2 §14 slot).

## DIM-nfr-privacy — NFR: privacy & data protection

- **category:** nfr · **demand:** required
- **covered_by:** nfr, constraint, functional, data_entity
- **Covered means:** what personal data is held, the deletion/retention
  rule, and the compliance floor the product commits to for its actual
  audience (e.g. GDPR basics for EU users). Distinct from DIM-consent:
  consent is the mechanism, this is the obligation set.
- **Defect class:** privacy posture exists as product principles but no
  requirement covers data deletion, retention, or regulatory floor for
  the audience actually served (evidence: wod-v3 F7; seed §19 carried
  principles, not obligations).

## DIM-nfr-availability — NFR: availability & performance

- **category:** nfr · **demand:** required
- **covered_by:** nfr, constraint
- **Covered means** a stated floor a wrong build violates, with its
  measurement profile: page-load bound on the core public surfaces
  (metric + percentile + assumed conditions, e.g. p75 largest-content
  paint on a mid-tier mobile connection), an availability expectation,
  and what degrades first under load. Two models reading this must
  produce COMPARABLE bounds — a number without its measurement profile
  is not comparable. MVP-honest numbers are fine; absence is not.
- **Defect class:** no availability or performance floor exists; "it was
  slow and down" cannot violate any requirement (evidence: wod-v3 F7; v2
  §14 had core-web-vitals targets that died at the regeneration
  boundary).

## DIM-nfr-accessibility — NFR: accessibility

- **category:** nfr · **demand:** required
- **covered_by:** nfr, constraint
- **Covered means** a named baseline (e.g. a WCAG conformance level for
  public pages, keyboard navigability, image alts on content surfaces) —
  or an owner disposition explicitly deferring it. Silence is neither.
- **Defect class:** no accessibility baseline stated; a public content
  product excludes users silently and retrofits expensively (evidence:
  wod-v3 F7; v2 §14 slot).

## DIM-nfr-operability — NFR: operability (backup, observability, support)

- **category:** nfr · **demand:** required
- **covered_by:** nfr, constraint, functional
- **facets:** backup, observability, support
- **Covered means,** per facet: `backup` — data backup/restore
  expectation; `observability` — how failures surface to operators
  (logs/alerts at minimum); `support` — the support path a stuck user
  has. Bars, not architecture. One citation must not collapse the three.
- **Defect class:** nothing states backup/recovery, error observability,
  or how operators learn the product is broken; the first data-loss
  incident writes this dimension the hard way (evidence: wod-v3 F7).

## DIM-proof-thresholds — Decidable success thresholds

- **category:** proof · **demand:** required
- **covered_by:** metric, outcome, nfr, constraint, hypothesis
- **Covered means:** for each declared falsifier metric, the number, the
  time window, the denominator/cohort, and the weak/kill bands — or an
  explicit owner disposition that thresholds are set at a named later
  gate. "Regular return behavior" without a definition is not a metric.
- **Defect class:** the MVP is designed as a proof whose pass/fail
  cannot be adjudicated — metric NAMES exist but no numeric threshold,
  window, denominator, or kill band (evidence: wod-v3 F6/loss 6 — "the
  evaluation the MVP exists to perform is not executable from the
  document").

## DIM-instrumentation — Instrumentation for the declared metrics

- **category:** proof · **demand:** required
- **covered_by:** functional, nfr, metric
- **Covered means:** every metric in DIM-proof-thresholds names the
  events or queries that measure it, and those events are demanded by a
  requirement. A metric nothing records is a wish.
- **Defect class:** declared metrics have no defined measurement events;
  the proof window closes with unmeasurable claims (evidence: v2 §12
  slot; largely covered in wod-v3 — kept so coverage is asserted, not
  assumed).

## DIM-core-loop-continuity — Core-loop continuity (post-action journeys & recovery)

- **category:** mechanism · **demand:** required
- **covered_by:** functional, ux_flow, data_entity
- **Covered means:** for each load-bearing user journey the thesis
  depends on, the step AFTER the headline action is specified — where
  the user finds/manages/undoes what they did, what they see when the
  list is empty or the target is gone, and how the journey resumes on
  return. A loop is covered when a builder can walk it end-to-end
  without inventing a surface.
- **Defect class:** the load-bearing user loop stops at a persisted
  flag — save exists but no list/manage/remove surface, no follow-up
  behaviour, no empty/failure/recovery states; the loop's continuation
  is silently absent (evidence: wod-v3 F2-save/return in BOTH post-seal
  analyses — found by the evidence, missed by every other dimension;
  added per CR2-005).

## DIM-seo-technical — Technical SEO contract

- **category:** mechanism · **demand:** case-by-case
- **covered_by:** functional, nfr, constraint
- **Covered means** (applies when organic search is a declared
  acquisition channel or proof): the indexability rule, canonical-URL
  discipline (it interacts directly with record dedup), sitemap
  expectation, and structured-data commitment for the indexable page
  types.
- **Defect class:** organic search is a declared MVP proof while the
  build contract (indexability mechanics, canonicals vs dedup, sitemap,
  structured data) is absent — the strategy survives, its executable
  half does not (evidence: wod-v3 loss 5; v2 §13 died at the
  regeneration boundary).

## DIM-i18n-locale — Internationalisation & locale display

- **category:** mechanism · **demand:** case-by-case
- **covered_by:** functional, nfr, constraint
- **Covered means** (applies when the product serves multiple
  locales/timezones): how dates/times are shown (event-local vs
  viewer-local), currency display, and the language posture for the MVP.
- **Defect class:** a worldwide product leaves timezone/currency/date
  display undefined; every build team re-decides it inconsistently
  (evidence: v2 Q-029 — elicited once, then lost at the regeneration
  boundary).
