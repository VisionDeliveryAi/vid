Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# whole-set-review — pass brief

<!-- Moved verbatim from vid-create-prd SKILL.md §10 — v0.9.1 spec 3.1. -->

mode: whole | delta
receives: mode whole — the entire effective set with seed, sources, ledger, contract (at consolidation, 7b: the consolidated file plus the arm ledger `.vid/consolidation-arms-<date>.md`); mode delta — the effective set, the DELTA (the rows and answers of one append, verbatim), the seed, the contract, and the open entries `sh checks/prd.sh --arms` lists for the delta's own rows (each kept arm in other words: `<id> arm <n> <disposition> | was: <old arm> | now: <the item's fail-if>`; none when it lists none).
must not receive: the authoring session's reasoning; any previous verdict.

A fresh pass over the entire effective set. Three lenses: **coherence**
(contradictions between items; a dimension both decided and left
undecided; duplicates; claims grounded in nothing the record contains)
and **buildability** (*"could a competent team execute this without
guessing?"* — thin data entities on load-bearing flows, vacuous
falsifiers, a demand whose Fail-if does not falsify it, **unguarded
seams**: interacting items whose joint failure no `invariant` row with
`spans:` falsifies, and **unmarked cross-cutting demands**: a Fail-if
naming more than one surface on a row without `cross-cutting:` — the
row a per-surface derivation would under-derive), and **soundness**
(0.26.10.29.3, phase 2 R3: *would building an item exactly as written
harm the user or defeat its own purpose?* — a retry that repeats a real
action already completed, a permission that shows what it should hide, a
default that loses data). Soundness applies in both modes; in a re-read
round (the rounds after a repair, `skills/vid-create-prd/SKILL.md` Pass
mechanics) it also judges each recommended answer the caller gives you
for an open `needs_owner` finding. The red-team's
finiteness mandate applies verbatim to this pass. Every finding carries
severity (`blocking` | `advisory`), a target id (*"a finding with no
target cannot be repaired or verified"* — a finding naming a target
outside the set is refused whole; a target may be an item, a mechanism,
a dimension or an answer `A-NNN`), evidence, and a triage class:

| triage_class | meaning |
|---|---|
| `fix_from_record` | the answer already exists in the thesis, items or ledger — a mislink, duplicate, or contradiction the record settles |
| `fix_model_authority` | repairable with no new decision: thin wording, an implied denial, a missing restatement |
| `needs_owner` | requires a decision that exists nowhere in the record. *"Use this whenever answering would mean inventing product intent. Never guess it, and never downgrade it to keep the count low."* |

**A contradiction names every side (0.26.10.29.3, phase 2 R3).** Its
`target` lists every row in conflict, comma-separated (an item, a
mechanism, an answer), and its repair amends each side or names in
`unchanged:` the side it keeps. "One problem, one finding" (delta mode,
below) limits follow-on findings, never the sides a contradiction names.

**A repair that narrows or withdraws a fail-if arm (v0.9.8.1 R29)** is
`needs_owner`, never `fix_from_record`, even when an answer in the
record reads as settling it: the courts refuse it in the same sitting
(the withdrawing answer's `settles:` must name the row; an answer of
tier `model_proposed` caps the row at provisional). Its evidence names
the answer it follows (`per: A-NNN`) and the arm. Every other
`fix_from_record` repair is unchanged.

## Delta mode (v0.9.1 3.2 — the append doors; the three lenses and the triage classes above apply unchanged)

**Delta mode.** You examine one append against the effective set. First
identify the AFFECTED SET of each ruling in the delta: every item sharing
its subject or its contract dimension, the journeys and shared rules it
touches, and any release criterion in the criterion map that names an
affected item. Named ids are the minimum, never the scope. Then check
coherence across delta × affected set, and propagation: an answer that
names or affects an item must leave that item either AMENDED in the same
append or named in the answer's `unchanged:` field; an affected item in
neither is a finding, triage `fix_from_record`. Propagation reaches
every kind of row (0.26.10.29.3, phase 2 R3): a ruling that changes what
an earlier answer, a mechanism or a `plain:` line says is a finding,
unless that row is AMENDED in the same append or named in `unchanged:`
(which takes item, answer and mechanism ids; a `plain:` line is named by
its item). Its triage is `fix_from_record` for a mechanism, a `plain:`
line or a `model_proposed` answer; for a `human` answer it is
`needs_owner`, its recommended answer the restatement the owner may give
— never a human row the owner did not give. The finiteness mandate
holds: a clean append returns a clean verdict. A finding that would
override an owner answer is a QUESTION, never a correction. Your findings
are `vid-prd-findings` rows (pass `review`): the caller rules them and
writes them into the append's own findings block, beside the line
`review: delta, round <r>, <n> findings` — the record the commit hook asks
of every new append (0.26.10.29.3 R3; the round, phase 2 R2).

An item is AFFECTED by a ruling when the ruling changes what that item
requires or permits. Sharing a subject or a dimension puts an item in
the set you EXAMINE for contradictions — not in the set the ruling must
amend or list: `unchanged:` names what the ruling examined and left
standing, never every neighbour. In this mode the coherence lens reads
delta × affected set, and the buildability and soundness lenses read the
delta's own rows — no earlier pass has seen them. One problem, one finding: a delta
row that falls under a contradiction the record settles draws no further
finding on what else it would have needed had it stood — those consequences are the owner's question if
the ruling ever changes, not rows for this sitting. One more line, in
both modes (v0.9.1 3.6): flag a `pilot` item whose fail-if depends on a
`later` item.

**Kept arms in other words (0.26.10.29.4, phase 3 R4).** For each
`--arms` entry you receive, ask: *do the new words still fail every
wrong build the old words failed?* An arm kept word for word with a
condition added counts as new words: the condition can let a wrong build
through. When the new words fail less, the arm is weaker: a finding,
`blocking`, triage `needs_owner`, targeting the item, its evidence
opening `arm <n>`, raised in the review's one owner question beside the
narrowed and withdrawn arms (R29, above), never `fix_from_record`, even
when an answer in the record reads as settling it. The owner's ruling
lands as that row's disposition, `accepted A-NNN` or `overruled A-NNN`
under the owner's answer to that question (a `human` row of this sitting
or later, never one the amending row's `source:` cites, never one
carrying `delegated: yes`), and either corrects the disposition
(`withdrawn A-NNN`, in the amending row itself when it is not yet
committed: pre-commit refuses the arm accepted narrower and marked kept,
FB-4 C1) or restores the old words; only that ruling or a
restoration closes the entry. An entry whose new words fail every wrong
build the old ones failed draws no finding (the finiteness mandate).

**The narrowest landing, and its count (v0.26.10.3 R5).** A repair or a
recommended answer that restates an item keeps every clause it does not
change word for word. A `needs_owner` finding whose recommended answer
would change a fail-if or a row's obligation carries that answer as text
the caller can draft; the caller runs `sh checks/inventory.sh impact` on
the draft and quotes, in the owner's question, the rows it would reset and
put to confirm (vid-develop's two-channel rule).

## Consolidation review (v0.9.1 3.4 — 7b, mode whole over a consolidated file)

You receive the consolidated PRD (its `## Appends` empty, history
relocated) and the arm ledger: per amended item, its fail-if arms at
first ratified text and at consolidated text, side by side, flagged
`arm-losing` or `arm-changed`. You propose — as ordinary AMENDED rows in
their own append, never as edits to the consolidated text — ruling
propagation across affected sets, cross-item effects of amendments, and
the restoration of any arm the effective text carries weakened without
an accounted disposition. Each proposal carries `arms:`, which accounts
for the predecessor's arms only: an arm the amendment adds needs no
entry (v0.9.8.1 R38). The finiteness
mandate holds: a file whose amendments are all accounted for returns a
clean verdict; a flagged ledger line whose weakening the record settles
(a named ruling withdrew the arm) is not a finding.

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
