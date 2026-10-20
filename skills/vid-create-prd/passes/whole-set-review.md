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
receives: mode whole — the entire effective set with seed, sources, ledger, contract (at consolidation, 7b: the consolidated file plus the arm ledger `.vid/consolidation-arms-<date>.md`); mode delta — the effective set, the DELTA (the rows and answers of one append, verbatim), the seed, the contract.
must not receive: the authoring session's reasoning; any previous verdict.

A fresh pass over the entire effective set. Two lenses: **coherence**
(contradictions between items; a dimension both decided and left
undecided; duplicates; claims grounded in nothing the record contains)
and **buildability** (*"could a competent team execute this without
guessing?"* — thin data entities on load-bearing flows, vacuous
falsifiers, a demand whose Fail-if does not falsify it, **unguarded
seams**: interacting items whose joint failure no `invariant` row with
`spans:` falsifies, and **unmarked cross-cutting demands**: a Fail-if
naming more than one surface on a row without `cross-cutting:` — the
row a per-surface derivation would under-derive). The red-team's
finiteness mandate applies verbatim to this pass. Every finding carries
severity (`blocking` | `advisory`), a target id (*"a finding with no
target cannot be repaired or verified"* — a finding naming a target
outside the set is refused whole), evidence, and a triage class:

| triage_class | meaning |
|---|---|
| `fix_from_record` | the answer already exists in the thesis, items or ledger — a mislink, duplicate, or contradiction the record settles |
| `fix_model_authority` | repairable with no new decision: thin wording, an implied denial, a missing restatement |
| `needs_owner` | requires a decision that exists nowhere in the record. *"Use this whenever answering would mean inventing product intent. Never guess it, and never downgrade it to keep the count low."* |

**A repair that narrows or withdraws a fail-if arm (v0.9.8.1 R29)** is
`needs_owner`, never `fix_from_record`, even when an answer in the
record reads as settling it: the courts refuse it in the same sitting
(the withdrawing answer's `settles:` must name the row; an answer of
tier `model_proposed` caps the row at provisional). Its evidence names
the answer it follows (`per: A-NNN`) and the arm. Every other
`fix_from_record` repair is unchanged.

## Delta mode (v0.9.1 3.2 — the append doors; the two lenses and the triage classes above apply unchanged)

**Delta mode.** You examine one append against the effective set. First
identify the AFFECTED SET of each ruling in the delta: every item sharing
its subject or its contract dimension, the journeys and shared rules it
touches, and any release criterion in the criterion map that names an
affected item. Named ids are the minimum, never the scope. Then check
coherence across delta × affected set, and propagation: an answer that
names or affects an item must leave that item either AMENDED in the same
append or named in the answer's `unchanged:` field; an affected item in
neither is a finding, triage `fix_from_record`. The finiteness mandate
holds: a clean append returns a clean verdict. A finding that would
override an owner answer is a QUESTION, never a correction.

An item is AFFECTED by a ruling when the ruling changes what that item
requires or permits. Sharing a subject or a dimension puts an item in
the set you EXAMINE for contradictions — not in the set the ruling must
amend or list: `unchanged:` names what the ruling examined and left
standing, never every neighbour. In this mode the coherence lens reads
delta × affected set, and the buildability lens reads the delta's own
rows — no earlier pass has seen them. One problem, one finding: a delta
row that falls under a contradiction the record settles draws no further
finding on what else it would have needed had it stood — those consequences are the owner's question if
the ruling ever changes, not rows for this sitting. One more line, in
both modes (v0.9.1 3.6): flag a `pilot` item whose fail-if depends on a
`later` item.

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
