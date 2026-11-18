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

mode: whole | delta
batch: rows <REQ domain> × <axis> | table
receives: the derived table — in a rows batch, that batch's rows verbatim with the effective items they derive from; in the table pass, the whole table (rows, rules, hostility rows, checklist lines) — the effective PRD; BASELINE.md's test environment and ARCHITECTURE.md's seam rows (the stand-in question); in the table pass, the open entries `sh checks/prd.sh --arms` lists (in mode delta, those for the delta's own rows); the two-question brief. Mode delta (append mode): the delta's rows and the rows sharing a subject with them, in place of the whole table; a later round: the rows the last round's repairs and every later write changed, in place of the whole table.
must not receive: the build or tuning context (which is also why it — and never the calling session — proposes golden queries); the calling session's reasoning; any previous verdict.

The strength pass (0.26.10.29.4, phase 3 R1): one more fresh-context
lens, run last, after the genus lenses, the governance rows and the
design rows, asked the distinguishing-power question beside the
coverage question:

> Describe a believable product that violates the intended promise
> while passing the current evidence, and the smallest row or
> observation that would catch it.

**Per row, in batches.** The per-row question runs in batches by REQ
domain and axis, one fresh reader per batch, as §6 batches its
test-author passes, so each reader holds its whole batch. For every row, rule, hostility row
and checklist line of your batch, ask: *what believable wrong product
would still pass this?* Report only the rows where one exists, each
with the wrong product and the smallest row or observation that would
catch it. A row that already fails every believable wrong product draws
no finding.

**Over the whole table, in one pass** (batch `table`, run beside the
batches), four questions and two more:

- **Rows that disagree.** Two rows require incompatible behaviour.
- **Rows that repeat.** Two rows hold the same obligation on the same
  subject. Name both, and say which is ratified, if either.
- **Rows the stand-in cannot test.** A row whose dependency is a seam
  the tests replace, so it can never fail. Count every seam of the seam
  rows as replaced in the test ledger until a `difference` row says how.
- **Censuses that cannot reach.** A rule's census that would miss a new
  instance, for example one that lists literal names.
- **Weakened arms.** For each open entry of `prd.sh --arms`: do the new
  words still fail every wrong build the old words failed? An arm kept
  word for word with a condition added counts as new words. One that
  fails less is a blocking finding, triage `needs_owner`, its evidence
  opening `arm <n>`.
- **Rows tied to a role they do not need** (0.26.10.29.4, phase 4 R1).
  A row that tests as a role, or derives from the requirement that only
  introduces the roles, where its behaviour does not depend on who acts:
  no permission, visibility or ownership is in its obligation. Name the
  row, the simplest actor that can trigger it (usually the first actor
  in `## Actors and journeys`) and the requirements its behaviour comes
  from. While the row is unratified the repair is ViD's, triage
  `fix_model_authority`: the actor and the derived-from are corrected.
  A ratified row is reported, never reworked; a re-cut places it by a
  `row:` line.

**Your output is finding rows,** in the whole-set review's shape: each
carries severity (`blocking` | `advisory`), a target (an inventory row
as `INVENTORY.md:ROW-12`, a rule or checklist line by its id, an item;
a disagreement or a repeat lists every row in it, comma-separated),
evidence (the wrong product, or the rows and the words that conflict)
and a triage class (`fix_from_record`, `fix_model_authority`,
`needs_owner`, as that pass defines them). The caller writes them as
pass `strength`. Same tier routing as the other lenses. The
finiteness mandate holds: a table that distinguishes returns a clean
verdict, and a finding is never made up to fill a batch. It is the cheap
core of the question "does this evidence distinguish the intended
product from a plausible wrong one?" — asked pre-code, as briefing
text; no variant generator, no blueprint, no second contract.

**Harm wording is the create-prd chain's job, not this lens's** (v0.9.1
3.5a moved the harm-wording tell to `vid-create-prd/passes/
wording-lens.md`, before the freeze): *a mechanism-worded fail-if
reaching this lens is a finding against the create-prd chain, reported,
never re-worded here.*
