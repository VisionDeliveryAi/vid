Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# genus-lens — pass brief

<!-- Moved verbatim from vid-test-inventory SKILL.md §2 (the lens brief and the universal floor) — v0.9.1 spec 3.1. -->

receives: the effective PRD; the derived rows as ids and obligations; the universal floor below; the seed proposals; the one-question brief. A later round additionally receives the accepted candidate list so far.
must not receive: the other lenses' output (blind to the other lenses); the rejected candidates; the verdicts; the calling session's reasoning; any previous verdict.

**The lenses.** Derive the expert lenses FROM the PRD's own genus
statement — the thesis's product summary and primary users name the
product's review board: at least 4 and at most 8 lenses (a regulatory
reader, an operator who runs it at scale, an abuse-resistance reviewer who asks how the product will be misused, a data steward, a
first-day user, …, whatever THIS product implies). Spawn each as a
fresh-context pass (Agent tool, general-purpose), blind to the other
lenses, given: the effective PRD; the derived rows so far as ids and
obligations (artifact state — never this session's reasoning); the
universal shape list below as the FLOOR each lens starts from, never the
ceiling; the seed library's proposals; and one question:

> What would an expert of this kind check that this document never
> states? For each: the forbidden effect, the subject it happens to, and
> which tier it lands in — a ledger row, an everywhere rule with a census
> denominator, or a grader's question. A candidate that cannot name the
> harm it prevents does not enter.

**Universal shapes — the floor (always true, any project), each with its
finding provenance.** Stated as behaviour so they carry to any stack.
(P) marks a protection-class shape: a Tier-0 candidate that, once
ratified, spawns its hostility sibling under §4.3. (E) marks an
everywhere-class shape: it lands as a RULE row with a census denominator
or not at all. A shape that fires nothing across two runs is dropped
(seed law).

1. Out-of-bounds pagination and range inputs return an orderly state,
   never a server error. (field runs v0.6/v0.7)
2. Double-submit of a creating action does not double-create. (P)
3. Error surfaces leak no internals.
4. No secret or session token in logs, URLs, or exports.
5. Unicode survives every persisted round-trip.
6. Every render of stored or user-supplied data passes the
   output-escaping guard. (E)
7. **Truth-bearer:** a user-visible success claim reads a recorded
   outcome the operation wrote, never the attempt — "has been emailed"
   is true only when a send outcome was recorded; a bulk action that
   silently no-ops on an illegal state is a false claim. (v0.8 re-grade
   H-05, H-20; the swallowed send failures of G-16; the row form is an
   outcome timestamp read by the surface)
8. Every scheduled or background promise has an **operator**: a trigger
   registered in the deployed shape, firing, with its last firing
   recorded — "who runs this?" (v0.8 G-01: the logic was tested, no
   scheduler entry existed)
9. Every collected configuration field has a **reader** other than
   validation and display. (E, census — §4.1) (v0.8 G-01/G-02: two
   fields validated, required, displayed, read by nothing)
10. Empty-but-valid input is a state, not a success: an input carrying
    zero records neither destroys inventory nor reports healthy —
    ingest-shaped products. (v0.8 G-02)
11. Every public collection surface is **bounded** — a limit and a page
    on every list a caller can reach, machine-facing lists (sitemaps,
    feeds, exports) included. (E, census) (v0.8 G-16, G-13, H-08)
12. Every list surface stays **operable at the PRD's stated volume** —
    one volume row per list surface once a scale item exists. (v0.8
    G-13, H-08)
13. **Dependency failure during a protected operation fails closed**: the
    forbidden effect does not occur and the failure is recorded, never a
    silent success. (P — hostility shape) (v0.8 G-05: an erasure failed
    open when its store was down, and its probe could not fail for that)
14. **Concurrency against a protected operation**: two simultaneous
    attempts produce exactly one effect. (P — hostility shape) (v0.8
    H-13, H-21)
15. A bound keyed on caller identity holds when the client-controlled
    part of that identity is rotated or reshaped, and is normalised per
    address family. (P) (v0.7 rotated header; v0.8 H-14)
16. Account flows are **oracle-symmetric**: registration, reset, and
    sign-in answer identically for existing and non-existing identities.
    (P) (v0.8 H-06)
17. Cross-actor access: a valid session for actor A requesting actor B's
    resource is refused, with an audit entry. (P) (v0.6 cross-tenant)
18. A replayed one-time link or token yields exactly one effect. (P)
19. A privilege change rotates the session; a credential change
    invalidates the actor's other sessions. (P) (v0.8 H-28)
20. Unauthenticated mutators are bounded: every public write path
    carries a per-identity rate bound and input length caps. (P, E)
    (v0.8 G-10: an unthrottled public relay; H-33)
21. Every secret the product reads is declared in one registry, and
    every declared secret has a reader. (E, census — a candidate class)
    (v0.8 G-04: a throwaway key signing in the production shape)
22. A computational promise proved only by published, named examples is
    unproved: rows use generated or independently sampled inputs. (the
    Astera v0.7 run: exact fixture-named assertions satisfied by
    branching on the fixture names; the engines built in a later
    rewrite)
23. Realistic datasets and fixture generators derive from sources
    independent of the product's own tables. (v0.8 G-03: a corpus drawn
    from the geocoder's own table could not exercise the failure)
