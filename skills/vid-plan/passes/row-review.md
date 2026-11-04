Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# row-review — pass brief

<!-- v0.26.10.12.2.1 R7: vid-create-prd's whole-set-review on the rows ViD appends; the inventory's rows are the owner's. -->

receives: PRD.md, PLAN.md and the output of `sh checks/planner.sh rows --added`, verbatim; nothing else.
must not receive: the planning session's reasoning; STAGES.md; any previous review or its findings; anything of the product's code or tests.

A fresh pass over every row ViD appends to the ratified inventory — the
lines `rows --added` gives, each ending `origin: plan <item>` — read against
that item in PRD.md. A ROW's fail-if is its "Fails if" sentence; a hostility
row's, that its attempt brings about what its item forbids; a rule's, a
place where its statement does not hold. Its marks are read from its form:
`protection` a hostility row, `rule` a rule, `owed-rehearsal`, `owed-staging`
or `owed-production` a test field paid at deploy gate 1, 2 or 3. Ask five
questions of each:

1. **Can someone who can't read code tell when this fail-if is true?** It
   names what a person would observe — what a page shows, what an inbox
   gets, what a log holds — and where. A fail-if that only says the thing
   "does not work", "is wrong" or "fails", or that needs the code read to
   decide, is vacuous: a finding.
2. **Does the fail-if break the promise?** When it is true the promise is
   broken, and the promise's plain way of breaking makes it true. A fail-if
   that checks something else, or misses that way, is a finding.
3. **Does the promise belong to its requirement?** It is part of what the
   named item asks: not another item's, and not more than the item says.
   A standing row belongs to its item by rule: owed to the rehearsal, the
   kept data survives the move to a new version; owed to staging, each
   role's test sign-in works there, and owed to production, none works
   there; a `rule` row, every collected field is acted on beyond validation
   and display, or every routed task and every schedule has a consumer.
4. **Does each protection row describe its item's forbidden effect?** A
   `protection` row's fail-if is what its must-never-happen item forbids,
   as it would be observed.
5. **Do the marks fit?** `journey`: a person's or a machine's path, written
   as transitions; `protection`: a must-never-happen item; `rule`: an
   obligation that holds everywhere (every page, every message); `seam`: one
   real action through one outside service, owed to staging with no
   `owed-staging` mark; `owed-staging`, `owed-production`, `owed-rehearsal`:
   observable only there; `shell`, `reachability`: the product's frame and
   its ways in. A missing or wrong mark is a finding.

**Finite.** Report only a row that fails one of the five, with the reason
in one line. A row that passes all five gets no line. Wording you would
prefer, style, and rows you would add are no findings. Never invent product
intent: a row that says what its item says is no finding for what the PRD
itself leaves open or gets wrong — that is the PRD's question, not the row's.

## Return format

Only lines of this form, one per finding, and nothing else — or, when no
row fails, the one line `none`:

    finding <row or transition id> | <the question it fails, and why, in one line>

The caller saves it with `sh checks/planner.sh review --in <file>`.
