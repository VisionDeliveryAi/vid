Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# contract-lens — pass brief

<!-- Moved verbatim from vid-create-prd SKILL.md §2 (the fresh-lens panel) — v0.9.1 spec 3.1. -->

receives: the genus statement, the catalog floor (`CONTRACT-CATALOG.md`), the one-question brief below.
must not receive: the other lenses' output — blind to the other lenses; the calling session's reasoning.

Spawn each as a fresh-context pass, blind to the others,
given the floor and asked one question:

> Beyond these, name the dimensions of this product on which a builder
> would otherwise have to invent a product decision. For each: an id, a
> category, the item types that could cover it, and one sentence stating
> what a builder would invent without it. A dimension that cannot name
> what it prevents does not enter.
