Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# counterexample-lens — pass brief

<!-- Moved verbatim from vid-test-inventory SKILL.md §3 — v0.9.1 spec 3.1;
     the harm-wording paragraph moved on to vid-create-prd (3.5a). -->

receives: the whole derived table; the effective PRD; the two-question brief.
must not receive: the build or tuning context (which is also why it — and never the calling session — proposes golden queries); the calling session's reasoning; any previous verdict.

One more fresh-context lens, run after the others, over the WHOLE
derived table (rows, rules, hostility rows, checklist lines), asked the
distinguishing-power question beside the coverage question:

> Describe a believable product that violates the intended promise
> while passing the current evidence, and the smallest row or
> observation that would catch it.

Same loop-until-dry bound, same dedup, same tier routing, same
recognition-speed ratification as the other lenses. It is the cheap
core of the question "does this evidence distinguish the intended
product from a plausible wrong one?" — asked pre-code, as briefing
text; no variant generator, no blueprint, no second contract.

**Harm wording is the create-prd chain's job, not this lens's** (v0.9.1
3.5a moved the harm-wording tell to `vid-create-prd/passes/
wording-lens.md`, before the freeze): *a mechanism-worded fail-if
reaching this lens is a finding against the create-prd chain, reported,
never re-worded here.*
