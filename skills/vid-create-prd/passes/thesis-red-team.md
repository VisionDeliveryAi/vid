Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# thesis-red-team — pass brief

<!-- Moved verbatim from vid-create-prd SKILL.md §4 — v0.9.1 spec 3.1. -->

receives: seed, sources, ledger, the drafted thesis.
must not receive: the authoring session's reasoning — the red-team judges the artifact, not the intent; any previous verdict.

A fresh pass reads seed, sources, ledger, and the drafted thesis —
never the authoring session's reasoning. Its charter carries both
load-bearing mandates:

> Extract the load-bearing assumptions and test each against the seed and
> the ledger; steelman that the framing, the primary user, or the MVP
> boundary is wrong. A finding needs a MATERIAL CONSEQUENCE — if nothing
> downstream changes because of it, it is not a finding; wording you
> would have phrased differently is not a finding; style is not a
> finding. A CLEAN VERDICT IS AN ACCEPTABLE OUTCOME. You are not scored
> on how much you find.

> If a correction would override an answer the owner gave, say so in your
> evidence — the owner's hand outranks a later model guess, so such a
> finding is a QUESTION for the owner, never a correction you may assume.

Six probes: **vacuity** (a mechanism a wrong implementation could not
violate); **sweep** (kept goals with neither mechanism nor open
question — judged against mechanism-category dimensions only, the same
predicate as the sweep and the court); **reference-aptness** (a ref that
resolves but is about something else — the one thing the deterministic
join cannot see; blocking); **right-actor**; **value-coherence**;
**off-screen obligation** (what unwritten requirement does an off-screen
phase imply). The seed itself is in scope: a contradiction *inside* the
brief is a finding routed as a question — the seed is trusted as
authority, not as consistency. Every finding this pass returns becomes a
`vid-prd-findings` row (pass `red-team`) in the pause-1 sitting record,
dispositioned at the sitting.

## Precision (v0.9.1 3.10 — brief text only; stages, count, pauses and the finiteness mandate unchanged)

**A finding names its failure.** The `evidence:` field of a substantive
finding states the situation, the affected actor, the plausible wrong
outcome, the passages that permit, require or fail to resolve it, and
why the consequence is material to the agreed scope. "Lifecycle
handling needs more detail" does not qualify; two rules requiring
incompatible behaviour when a tenant is suspended does. Same finding
format — the `vid-prd-findings` row — no new document.

**Challenge your own finding first.** *Before reporting a gap or
contradiction, find the strongest evidence that it is already settled —
related items, owner answers, the Explicitly-not-MVP section, later
rulings — and report it only if the material problem survives that
check.* A deliberate deferral is never rediscovered as missing scope.
