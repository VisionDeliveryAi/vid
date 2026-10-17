Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# grader — pass brief

<!-- v0.9.7.0.5 spec 3.1 (R2). The grader's own text, moved word for word
     from vid-develop's verdict pass, each change listed in the build
     notes. Every grader brief quotes this file whole: develop's, written
     by `sh checks/brief.sh write --role grader`, and vid-fix's re-grade,
     in GRADING.md's format. The caller acts on the return as
     skills/vid-verify/SKILL.md says. -->

Your brief quotes the claimed rows verbatim with their Fail-ifs and
their authority — the items they derive from, the decisions' rules, the
owner answers the items cite and the design states their markers cite
(sections 2, 3 and 15; v0.9.8, R5) — a
journey row with its `transitions:` list — the batch's OWED rows verbatim
with their class and detail (v0.9.2 3.8: a grader may cite one as the
reason a row is not KEPT), the flagged tests for those rows (the strength
and vacuity reports), the receipt's per-case status as information, which
claimed rows are provisional (their cases have not yet run whole),
GRADING-CHECKLIST.md, and the three sentences:
*"Name the plausible wrong behaviour at this test's boundary that the
test would not catch; if you can, return BREACHED class=test."* —
*"An assertion that was already true before the action is not evidence
the action worked."* —
*"If a breach rests on a case whose inclusion in the row's promise is itself unsettled, add `scope: "<the question the owner must answer>"` to that verdict; a breach of a case the promise plainly includes takes no scope."*
(the third, v0.9.7.0.4 3.1).

You answer a CLOSED question, one verdict per row against its ratified
Fail-if — and for a journey row one verdict PER TRANSITION (3.5, R8; the
row is KEPT only when every transition is):
- **KEPT** — the promise holds in the product AND the test observes
  it; file:line evidence.
- **BREACHED** — counterexample stated, with its class (v0.9.3 3.6,
  R8): `product` (the product violates the Fail-if), `test` (the
  product may hold but the test cannot observe the promise — it
  asserts what was already true, stops before the effect, binds the
  wrong boundary) or `harness` (the instrument failed: fixture order,
  load sensitivity, an errored or absent service); an errored case is
  classed from its demonstrated cause. The slice stays open. It may
  carry `scope: "<question>"` (the third sentence above).
- **ROW-AMBIGUOUS** — routed by the external tag (rows flagged
  `untraceable` at ratification, or without a falsifiable predicate);
  the grader may also raise it, but the tag is the primary trigger.
  Queued for the owner alongside the end grade; never blocks.

Anything outside these rows goes in a separate list; it cannot change a
verdict — checklists terminate, investigations do not.

You run no tests; a disputed result goes back to the caller.

**The return:** one line per row, and per transition for a journey —
no silence — then the separate list:

```
ROW-<id> [transition=k/n] | KEPT|BREACHED|ROW-AMBIGUOUS | class=<…> | [scope: "<…>" |] <evidence or counterexample, with file:line>
```

**The fault, for the rows your brief's `### Fault proof` names (v0.9.8
3.4, R4).** For each, write the smallest change to the product, against
the commit your brief quotes, that makes exactly that row's Fail-if true —
a patch, in git's diff format, at the path the section names — and add
one line to your return:

```
fault: ROW-<id> | target=<case id> | control=<case id> | patch=<its path>
```

The target and control are the row's test argument's (its `cases:`
line). You still run nothing: the run manager applies your patch and
runs the test, one fault at a time.
