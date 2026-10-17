Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# completeness-audit — pass brief

<!-- Moved verbatim from vid-create-prd SKILL.md §7 (the judgment half) — v0.9.1 spec 3.1. -->

receives: the ratified thesis, the effective item set, the ledger, the ratified contract with the catalog prompts (`CONTRACT-CATALOG.md`).
must not receive: the authoring session's reasoning; any previous verdict.

> The ratified contract lists the dimensions this product's requirements
> must terminate on. Your one question, per dimension — and per facet,
> where the dimension declares facets: would a builder have to INVENT a
> product decision here? Citing an item that merely MENTIONS the topic is
> a gap wearing a citation, and one citation must not collapse a
> compound dimension's facets. Do not ask anything the ratified thesis or
> an existing ledger answer already settles. You propose — you never
> disposition: only the owner rules a dimension not-applicable.

The pass reads the catalog file's full prompts (the "covered means…"
text with its boundary clauses) for catalog dimensions, and the
`prompt:` row line for panel-added ones. Output per dimension:
`covered` (with the citations that genuinely answer it), or `gap` with
up to a handful of owner questions (each a product decision at PRD
altitude, with why-it-matters and answer guidance), or a **proposed**
`na` rationale awaiting the owner. Gaps and proposed NAs become
`vid-prd-findings` rows (pass `audit`) in the pause-2 sitting record,
dispositioned by the owner's answers and rulings there — an answered
gap is `accepted A-NNN`, an accepted NA proposal likewise, a gap the
owner routes onward `routed OQ-n`.

## Precision (v0.9.1 3.10 — brief text only; stages, count, pauses and the finiteness mandate unchanged)

**What a product decision is** — the trigger's definition, not a
narrowing: *a decision is a product decision when reasonable
implementations would produce materially different user outcomes,
permissions, data treatment, data semantics (what a stored value means,
its unit, casing, monotonicity) or release obligations; ordinary
engineering choices that preserve the intended outcome are the builder's
and are not findings; an enhancement or edge case a reviewer can imagine
is not a requirement because it can be imagined.*

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
