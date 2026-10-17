---
name: vid-create-prd
description: Author a ViD PRD — the enriched, court-grammared PRD.md — through a materiality-tested interview, an owner-ratified content contract, typed items under the falsifier mandate, and exactly three ratification commits. vid-init runs it inline as its first act (product elicitation is this verb's channel; technical foundation stays init's); it also runs standalone — in a ViD project, any repo, or a bare directory — producing a portable PRD a later vid-init adopts without re-interviewing. Creation only; appends belong to vid-fix and vid-add. Use when the owner says "vid create-prd", wants a PRD authored, wants an existing document converted through the import door, or when vid-init delegates to it.
---

# /vid create-prd

The PRD verb. Two ways in: **vid-init runs it inline as its first act**
(the two-channel split — product elicitation here, technical foundation
there), or **the owner invokes it standalone** — in a ViD project, any
repository, or a bare directory — and hands the ratified file to a later
vid-init, which adopts it in place of delegation. Either way the chain,
the pauses, and the court are the same.

**Stage events (v0.9.5 3.11, R11; RECORDS.md) — only in a ViD project.**
When `.vid/` exists as this verb starts (after init, or inside init, which
has recorded its own start), record, with the plugin's copy of the helper
(this verb runs before any project checks/ exists):
`sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" "stage name=create-prd state=start session=$CLAUDE_CODE_SESSION_ID records=1"`
at the start; `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" "stage name=create-prd state=pause-N session=$CLAUDE_CODE_SESSION_ID"`
right after each ratification commit (N = 1, 2, 3: §5, §8, §12); and
`state=end` in the same form when the verb hands back. Every event it names
is written the same way, `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" '<event>'`. A standalone run in
a directory with no `.vid/` writes no event: its Ratifications lines carry
its dates.

## What this verb produces

One file: **PRD.md**, in the enriched grammar of
`${CLAUDE_PLUGIN_ROOT}/templates/PRD.md` (the template init ships — one
grammar, one home) — prose sections carrying what humans judge (seed,
thesis, journeys) and five machine blocks carrying what courts join
(items, contract, answers, mechanisms, findings). The document is the artifact:
no prose is written from the items that anyone reads back as demand,
and no data file shadows the markdown. It is **portable** — seed,
ledger, contract, and ratification record travel in the one file.

Where it runs: a ViD project, any repository, or a bare directory
(standalone mode, below). Scope is **creation only** — the append paths
of an existing PRD stay owned by vid-fix and vid-add; this verb never
edits a ratified base.

## The owner surface — the whole of it

The owner appears **exactly four times**: the interview batch that opens
the run, and three ratification pauses. Each pause ends in a commit.
**No other approval point exists** — anything asking the owner for
approval between pauses is a defect against this skill. Narration is
position updates ("authoring items", "running the court"), never
approval-seeking.

Two channels, one carried here: this verb asks **product questions
only**. Technical foundation — design direction, architecture, stack —
belongs to vid-init and is out of scope; if the owner volunteers stack
decisions, record them as ledger answers and move on, but never ask for
them. Product questions stay free and immediate at every stage; the
interview batch is for decision critical mass, not a quota.

## The court gate

`${CLAUDE_PLUGIN_ROOT}/checks/prd.sh` is the court for the produced
artifact — one court, one home: the same file init installs into every
project's `checks/`, where the pre-commit hook runs it at every commit.
**Before every ratification commit, run it explicitly, in pause mode,
by the plugin path:**

    sh ${CLAUDE_PLUGIN_ROOT}/checks/prd.sh --pause PRD.md

Always the plugin path — never a project's `checks/prd.sh`, which may be
an older copy that does not know the flag. `--pause` runs every join the
plain court runs, adds join 20 (every ViD decision carries a current
`shown:` label) and the importance floor (a human answer that shapes a
must-never-break rule carries `importance: priority`), and prints the
pause material the sittings present (§5, §8, §12). The pre-commit hook
keeps the plain run — between pauses an unshown ViD decision is
legitimate — so nothing but this gate enforces `--pause`: it is
honour-enforced, and this skill honours it. A conviction blocks the
pause until repaired: **the skill never presents a convicted artifact to
the owner as ratifiable.** The report line (`--report`) prints counts,
never scores. This verb installs no hooks (hook installation is init's
job) — where no hook exists, this explicit gate carries the whole
enforcement.

**The sequence at every pause:** (1) run `--pause` — it convicts on join
20 for the ViD decisions not yet shown and prints each beside the
checksum its label needs; (2) present its material, in the pause's order
below, and — once items exist — the `plain sentences` it lists, each
sentence beside its rule, for every item written or changed since the last
pause (v0.9.5 3.13: the owner approves both together); (3) write the owner's rulings and a `shown: pause-N <sum>` label
on every ViD decision presented; (4) re-run it green; (5) commit.

## The scorecard (v0.9.5 part B) — at pauses 2 and 3

Information for the owner, never a gate: it blocks nothing, and ViD
changes nothing because of it unless the owner asks. At pauses 2 and 3,
after `--pause` is green and before the sitting:

1. **The counted half:**

       sh ${CLAUDE_PLUGIN_ROOT}/checks/scorecard.sh PRD.md --previous <prev> --candidates .vid/scorecard-candidates.txt

   `<prev>` is the PRD as committed at the previous pause
   (`git show <that commit>:PRD.md > .vid/scorecard-previous.md`): the
   pause-1 PRD at pause 2, the pause-2 PRD at pause 3 (standalone mode:
   the copy saved at the previous pause).
2. **The judged half:** one restricted reader, in the foreground, with
   `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/scorecard-reader.md` as
   its whole brief, the candidates file, and PRD.md. It writes its lines
   to `.vid/scorecard-reader.txt` and spawns nothing. If it cannot read
   its input whole, say so and show the counted half alone; never split
   it.
3. **The tally:**

       sh ${CLAUDE_PLUGIN_ROOT}/checks/scorecard.sh --tally .vid/scorecard-candidates.txt .vid/scorecard-reader.txt

4. **Show the whole scorecard, every time** (owner ruling B2), in plain
   words, one line per quality: its numbers as the two outputs print
   them, each judged number with its agreement beside it ("12 of 17
   agreed" or "not yet checked"), and the items behind every flag. Never
   restate a number the outputs did not print. Size is the project's own
   (owner ruling B3): no count is called too many or too few.

## The findings record

What the grading passes found — and how each finding was dispositioned —
is part of the artifact, not of the session. At every pause, before its
commit, write the sitting into `## Findings` under a dated sub-heading:
one `vid-prd-findings` row per finding —

    F-NN | pass | severity | target | disposition | evidence: …

pass ∈ `red-team` | `audit` | `review`; severity ∈ `blocking` |
`advisory`; the target names item, `MECH-`, or `DIM-` ids, `thesis`, or
`seed`; the disposition is `repaired`, `overruled A-NNN`,
`accepted A-NNN`, `routed OQ-n`, or `noted` (advisory only). The court
joins all of it: a blocking finding without a resolving disposition
blocks the pause mechanically, dispositions must cite ledger rows or
live carriers that exist, and a finding whose target resolves to
nothing is refused. A clean sitting is recorded as a prose line under
its heading — **a finding is never manufactured to fill the block.**
The ratification sha thereby covers what the owner was SHOWN, not only
what they decided.

## The chain

```
 interview (owner, one batch)             ← materiality-tested
    ↓
 contract panel (fresh lenses)  ─┐
 thesis authoring + mechanisms   │ pass(es)
 thesis red-team (fresh)        ─┘
    ↓
 PAUSE 1 — thesis + contract ratified     ← a commit
    ↓
 item authoring (falsifier mandate)         pass
    ↓
 court + completeness audit (fresh)         joins + pass
    ↓
 PAUSE 2 — gap answers, NA rulings        ← owner; a commit
    ↓
 augment (additive only)                    pass
 wording lens (fresh)                       pass
 whole-set review (fresh)                   pass
 repair (one bounded round, a diff)         skill
    ↓
 PAUSE 3 — final ratification             ← a commit
```

> **One writer per step** (owner ruling, 2026-09-25). Every step that
> writes PRD.md — item authoring, augment, repair, applying the owner's
> rulings — and every fresh pass — the contract lenses excepted, which are
> separate lenses by design — runs as ONE agent over the whole of its
> input, never partitioned by area, topic, dimension or batch. The one
> writer spawns no agents. When the session must prove an author clean (it
> has read material the run may not use), it hands the whole step to one
> restricted writer and says so; a restriction is never a reason to split.
> If the one agent cannot read its input whole, the step stops: the
> session tells the owner at once — the PRD's size is the owner's product
> question — and never splits the work or reads a subset silently. A pass
> that could not read rows names them in its output.
>
> The one writer writes PRD.md in several appends, each in its own
> response, never the whole set in one: a response has an output cap, and
> its thinking counts against it. The appends are one agent's writes in
> sequence, over the whole input it has read; they are not a split of the
> work.

The contract lenses (§2) are the one existing exception: several fresh
lenses, each blind to the others, by design. They write no rows.

### 1. Interview — materiality-filtered, batched, recommendation-led

Absorb whatever the owner gave (a paragraph, a document through the
import door, a rant). Draft candidate questions, then apply the
materiality test to each:

> A question survives only if not answering it means a downstream stage
> INVENTS something. If the owner does not answer this, what does a
> downstream stage invent? If the answer is "nothing — a sensible default
> exists," the question is discarded and the default is taken as a
> `model_proposed` answer.

Ask ONE batched set at decision critical mass, a recommendation attached
wherever the evidence supports one. Every answer lands in the ledger,
tiered `human`; every skipped question or "you pick" lands as a
`model_proposed` row — routed, never narrated.

**Whose decision each row records.** An answer to a question ViD asked
is the owner's — `human` — whether given in the owner's words, as one
accepted recommendation, or in a blanket "all recommended": one ledger
row per question, its `A:` restating the value decided ("accepted as
recommended: 30 days"), because values are traced against `A:` texts and
consolidation drops `Q:`. The materiality defaults — the questions the
test discarded — are ViD's decisions: `model_proposed` rows, `Q:` the
decision, `A:` the default with its values stated, shown to the owner at
pause 1 among the ranked ViD decisions (§5). Where an answer shapes a
must-never-break (T0) rule, ViD marks it `importance: priority` and says
so; the owner may raise or lower any answer's marker — priority marks the
big decisions, and the rest are normal.

**The scope challenge — a distinct question class, not a loosened
filter.** The materiality test structurally never challenges scope on a
complete seed: a question the seed already answers does not survive it,
so a seed that over-specifies its MVP sails through whole (the measured
case: a same-seed sitting where the owner, asked directly, cut an entire
acquisition channel and banned a wall mode the seed carried). Alongside
the surviving questions, the batch therefore carries **one explicitly
labeled boundary challenge**: name the seed capabilities this MVP could
ship without, each with a cut-or-keep recommendation and the cost of
keeping it. The owner rules or declines — declining is acceptable — and
every ruling lands as a ledger answer (`human`). One challenge, in the
batch, at the same sitting: never a second interview, never a quota of
cuts.

**The ledger's supersession law** is the items' law: when a later ruling
changes an earlier answer, restate the FULL row as `A-NNN AMENDED` in an
append — latest wins, the court demands an ancestor, and every ref
resolves against the effective ledger. Never reconcile two answers in
prose ("A-017 is amended to this reading") while both stay live — that
is narration, and the court cannot see it.

### 2. The contract — catalog floor, panel extension, owner ratification

Before the thesis (the mechanism sweep reads the contract — order is
load-bearing). Two sources, one ratified list:

**The floor:** read `CONTRACT-CATALOG.md` (beside this skill) — the 19
imported dimensions with their categories, demand, covered_by lists,
facets, full "covered means…" prompts, and defect-class provenance.
The floor each lens starts from, not the ceiling.

**The extension — the fresh-lens panel:** derive 3–5 expert lenses
**from the product's own genus statement** — the product names its own
review board. Spawn each as `passes/contract-lens.md`.

Dedup the union against the floor and within itself; present the merged
list to the owner at recognition speed at pause 1. The owner strikes,
merges, adds, and **rules every `case-by-case` dimension explicitly in
or out** — never silently present, never silently dropped. The ratified
list is the contract, capped at 24. The entry rule is contract law:

> a dimension that cannot name its defect class does not enter

— for catalog dimensions the defect class is the measured finding
recorded in the catalog file; for panel-added dimensions it is the
`prompt:` line, and a panel proposal without one is refused at the
sitting. The panel — not the author — proposes extensions, because an
author proposing its own completeness bar sits structurally inside the
blind spot the audit exists to escape. One round, no loop.

### 3. Thesis authoring + mechanism sweep

One pass, inputs ordered: seed (verbatim, highest), sources, the
proposed contract's dimensions, the question pack, the answer ledger
with tiers. The conflict rule:

> the seed is the owner's own brief and outranks every other source;
> where sources conflict, say so in Evidence basis and prefer the seed
> and the human answers.

Produce the seven thesis sections — plus the optional eighth, `Future
or secondary`: coming-later context that CONSTRAINS today's foundations,
distinct from `Explicitly not MVP` (not now / never); it grounds
`constraint` items where a future phase binds a present decision, and is
omitted when nothing does — the actors and journeys — off-screen
phases marked, because *"the off-screen phase is the one thing only a
journey can hold, and the phase most likely to hide an unwritten
requirement"* — and the mechanism sweep: for every kept `G*` goal, the
mechanisms it depends on, one sentence each, typed grounding
(`stated: seed "<excerpt>"` with the excerpt word-for-word in the Seed
section, because the join is checked mechanically; `stated: answer
A-NNN`; or `open: OQ-n`). The sweep targets the contract's
**mechanism-category dimensions only** — never nfr or proof dimensions;
this category scope is stated here and repeated in the red-team charter
because one predicate must own it (evidence: register RUN-F1 — a critic
demanding mechanisms for nfr/proof dimensions forced 3 waivers and a
wasted repair call every run).

> A goal with no mechanism and no open question is a wish and will be
> refused.

— refused first by this pass's own mandate, then by the court's join,
then by the red-team. `Required core flows` is derived from the
journeys, never authored separately.

**Features.** After the mechanism sweep, declare the features:

> A feature is a part of the product the owner would name — narrower than
> a goal, one goal each where the goal exists. Every requirement will
> belong to exactly one.

They are the ```vid-prd-features block in `## Items`, before the items
block — `FEAT-NN | G-label | name`, the goal `-` only for an outcome
outside the thesis (the template's comment carries the law). The block
is presented and ratified at pause 1. No count is mandated.

### 4. Thesis red-team — fresh context, finite, owner-bounded

Spawn `passes/thesis-red-team.md` on the drafted thesis.

### 5. Pause 1 — thesis + contract ratification

Run `--pause` (the court gate's sequence). One sitting: the thesis, the
contract and the features presented; the red-team's findings adjudicated
(fix, or the owner overrules with the ruling recorded as a ledger
answer); the contract dimensions ratified — all 19 floor dimensions
presented, both `case-by-case` entries explicitly ruled in or out, a
struck floor dimension leaving no residue; the features ratified; the
interview's materiality defaults presented as the ranked ViD decisions
`--pause` prints, one line each, most consequential first — each one the
owner changes restated `human` in place, each one the owner lets stand
staying ViD's, labelled `shown: pause-1 <sum>`; and the thesis
ratified. **The sitting's contract rulings are attributed:** the strikes
and the case-by-case in/out rulings land as one ledger answer (`human`),
so ten struck dimensions are an owner decision the record can point to,
not a comment's claim. Write the sitting's findings rows with their
dispositions into `## Findings`, the labels, re-run `--pause` green,
write the Ratifications line, commit.

> A lock that can be taken while the red team still objects is a
> signature on an unread document.

— the skill **refuses to commit pause 1 with an unadjudicated blocking
finding**, naming the finding and the exits (fix, or owner overrule
recorded as an answer). After this commit the thesis is frozen: later
change is an owner append, never a quiet re-author.

### 6. Item authoring — the falsifier mandate

One pass over the **ratified** thesis (never a later draft), the ledger,
the seed, the sources, the contract. The framing sentence:

> WHAT YOU PRODUCE IS THE ARTIFACT. These items are the product's only
> requirements surface — no prose is written from them that anyone reads
> back as demand. Write product behaviour, not solution design. The
> consumer is a derivation that multiplies enumerable demand; every rule
> here exists to make that derivation guess-free.

The field mandates ride the grammar (`templates/PRD.md`): the file starts
from that template, whose header line `grammar: 0.9.8.1` puts it under the
0.9.5 court's rules and later ones (v0.9.8.1 R38: join 17 reads every
answer a `source:` cites) from its first commit — four positional fields (there is no
priority column; v0.9.1 3.8), `phase`, `feature:` and `plain:` on every
demand item and invariant, `arms:` on every amendment, `unchanged:` on
rulings. The authoring mandates:

- **The falsifier mandate:**

  > An acceptance criterion is a condition a WRONG implementation
  > VIOLATES. If you cannot describe a product that violates the
  > intended promise while passing the current evidence, and that your
  > condition fails, the condition is not testing anything.

  The failing case named — never "works as expected", never "meets the
  requirement".
- **The unit of a requirement, and what the record does not decide:**

  > **The unit of a requirement.** A requirement is the smallest statement
  > the owner could accept or change on its own, with every part of it
  > covered by a fail-if case. Split where the parts could be decided
  > differently; merge where they could only be decided together. A
  > requirement too big for one statement is two requirements, not a cut one
  > — and two statements the owner could only decide together are one.
  >
  > **What the record does not decide.** After pause 1, a product decision
  > nobody made is a ViD decision: a `model_proposed` ledger row (`Q:` the
  > decision, `A:` the default with its values stated, `settles:` the items
  > it grounds), cited by the item, which is authored `provisional |
  > confirms_via: owner-decision/no` — and, when a T0 item rests on it,
  > routed to its own question (`VID-QUESTION: (OQ-n) A-NNN — …`, listed
  > in the item's `confirms_via: owner-decision OQ-n…/yes`) with ViD's
  > recommendation. Never write a `human` row the owner did not give: between
  > sittings, every decision you take is a ViD decision. A setting whose every reasonable
  > choice leaves the user's outcome, permissions, data treatment and data
  > semantics unchanged — a password length, a link lifetime, a refresh
  > interval — is the builder's: it is not authored. A value the owner
  > deferred is `provisional | confirms_via: measurement`, citing the
  > answer that deferred it. A value taken from an external standard is
  > adopted by a decision that states it.
- **Every requirement belongs to one feature:** each demand item and
  invariant carries `feature:` — exactly one `FEAT-NN` from the ratified
  features block; a frame item may carry one.
- **Every requirement says itself in one plain sentence** (v0.9.5 3.13):
  each demand item and invariant carries `plain:` — exactly one sentence,
  at most 30 words, in the owner's words, with no ids, and every number in
  it taken from the item's own statement or fail-if (write "for example",
  not "e.g."). The court's join 21 checks the form; the owner approves the
  sentence beside its rule at every pause.
- **Importance as it cites** (v0.9.5 3.17):

  > A human answer that a T0 item rests on — one the item cites, one whose
  > `settles:` names it, or one that resolves a question it routes to —
  > carries `importance: priority`. When an item you write makes that true,
  > add the label to the answer as you write the item, and list the answers
  > you marked in your output. The owner may lower any of them at pause 2.
- **Non-goals are first-class demand.** Author them deliberately; *"a
  generator cannot infer a boundary from silence."*
- **Phase is membership, not ranking** (v0.9.1 3.6): *"every item
  carries `phase`; propose it from the thesis's MVP focus,
  Explicitly-not-MVP and Future sections; the owner ratifies it with
  the item; an item whose arms the owner wants in different releases is
  SPLIT."* `pilot | later`, default `pilot`; `later` is what the owner
  has deferred, never inferred from what the harness can observe; a
  phase change is an AMENDED row under the append law.
- **Interaction falsifiers:** where a failure mode is the JOINT behavior
  of two or more items — a preference that must not move another
  preference, a cache that must not answer for a changed query — one
  item's inline Fail-if cannot falsify the seam. Author the
  interaction's falsifier as an `invariant` row and name the interacting
  items in `spans:` (court-resolved against the effective set).
- **Serves is purpose, not citation:** *"When a downstream generator
  hits a tradeoff this text did not anticipate, purpose is the only
  thing that resolves it the way the owner would. 'Because the PRD says
  so' is not a purpose."*
- **Quality-bar flagging:** a demand whose bar is a judgment
  ("relevant", "good", "state of the art") cannot be falsified by words
  alone; author it `derives: golden-set`, its Fail-if written against
  the golden set that will exist, and its authority at most
  `provisional, confirms_via: measurement`.
- **Time-worded flagging:** a Fail-if with a schedule or deadline in it
  is authored `derives: trigger-row` — the promise needs an operator,
  and the downstream derivation must see that mechanically.

- **Cross-cutting marking:** a demand that belongs to no single
  surface — an audit rule, an isolation property, an evaluation
  process — carries `cross-cutting:` naming the surfaces or sides it
  lands on. These are exactly the items a per-surface downstream
  enumeration silently under-derives; the marker is what lets a
  derivation see them. **Optional to author, mandatory to read** (the
  demand strength ruled at integration): never empty when present
  (court-checked), and where present the inventory derivation emits one
  row per named surface, each carrying the item's Fail-if at that
  surface — the reason the field exists. The whole-set review probes the
  other direction: a demand whose Fail-if names more than one surface
  and carries no marker.

### 7. Court + completeness audit

The court runs first — the countable half. Then the judgment half, a
fresh pass under the audit mandate: spawn `passes/completeness-audit.md`.

### 8. Pause 2 — gap answers

Run `--pause`. Before the sitting, merge the near-duplicate pairs it
prints that are plainly one rule; a pair kept apart becomes a findings
row — `F-NN | review | advisory | REQ-a, REQ-b | noted | evidence:
near-duplicate kept — <why>` — and that row is the record, so the pair
is not shown again. Then present, in this order:

1. the questions: the audit's gaps, then the must-never-break questions
   (`--pause` lists each with ViD's recommendation and the T0 items
   waiting on it);
2. the size, in one plain sentence:

   > This PRD holds N requirements — about N/30 grading batches, where ViD
   > grades comfortably up to two. Past that, rules that span features are the
   > first to slip. The largest features are X (n) and Y (m); moving one to
   > "later" is the cheapest cut.

3. the new ViD decisions, ranked, one line each;
4. the sensitive list — T1 and T2 rules on security, privacy,
   authorization, consent or data integrity that rest on ViD decisions;
5. the near-duplicate pairs still unruled;
6. the plain sentences, each beside its rule (`--pause`'s `plain
   sentences`), which the owner approves with the items.
7. the scorecard (§ The scorecard), whole.

The owner answers the gap questions and rules the proposed NAs — the
only actor who may. Answers land in the ledger (`human`, one row per
question, the value restated in `A:`); rulings land in the contract rows
(`na owner <date> <ref>`). An answered must-never-break question restates
its ViD decision `human` with `importance: priority` under the same id,
its carrier is rewritten `RESOLVED: (OQ-n) A-NNN — …`, and each item
citing the decision stays provisional while any decision it cites is
still ViD's, then is amended `authoritative`. A ViD decision the owner
changes becomes the owner's (restated `human`); one the owner lets stand
stays ViD's, labelled `shown:`. Labels, `--pause` green, Ratifications
line, commit.

### 9. Augment — answers become coverage, additively

One pass, bounded exactly:

> you turn those ANSWERS into requirement coverage — additively, and
> nothing else.

New items (fresh ids, citing the answers in `source:`, `covers:` naming
what they satisfy) and coverage-citation additions on existing items
where the answers genuinely support them — *"a mention is not
coverage."* Never an edit to any other field of any existing item —
statement-level fixes belong to repair over findings, never here. Never
a covers on a pending item. A duplicate of an existing item aborts the
pass's output.

### 9b. Wording lens — harms, not mechanisms, before the freeze

Spawn `passes/wording-lens.md` over every demand item's fail-if (v0.9.1
3.5a). It returns, per clause worded as a mechanism's absence, the
harm-worded restatement — one line per rewording with its `arms:` (3.5b:
one entry per arm of the clause it replaces; a rewording never loses an
arm without a named ruling) — as proposed edits to the not-yet-frozen
base; the repair round (§11) applies them under that accounting. The
sitting sees the accounting, never a batch count: each rewording is
presented as one line with its `arms:`, never "nineteen rewordings,
accepted whole". Each rewording becomes a findings row in the pause-3
sitting record —

    F-NN | lens | advisory | REQ-x | repaired | evidence: arms: … — now: <new fail-if>

— the old text stays in the diff, and a rewording the owner declines is
`noted`.

### 10. Whole-set review — coherence + buildability

Spawn `passes/whole-set-review.md` in `mode: whole` on the entire
effective set. (The append doors — vid-add §2, vid-fix (a), vid-develop's
two-channel rule, vid-design §4, vid-test-inventory §5 — spawn the same
brief in `mode: delta` on one append against the effective set; v0.9.1
3.2.)

### 11. Repair — one bounded round, a diff

The skill resolves all `fix_from_record` and `fix_model_authority`
findings in one plan: *"you see every finding at once precisely so the
fixes cohere with each other and with the untouched remainder."* Two
rules:

> A fix must STRENGTHEN the artifact against its sources. Weakening an
> obligation so that a finding stops applying is not a fix; if the honest
> answer is that the item is wrong at its root, say so and route it to
> the owner.

> THE PLAN IS A DIFF, NOT A DOCUMENT. You never rewrite the artifact; you
> name surgical edits, each citing the finding it resolves, and every
> finding appears in the plan.

The plan also carries the wording lens's rewordings (§9b) as edits of
the same kind. **Every repair edit touching a fail-if carries the
`arms:` line beside the edit** (v0.9.1 3.5b, 3.10 10d): one entry per
arm of the clause it replaces — `retained · strengthened · moved <id> ·
withdrawn <A-NNN>` — so the diff shows what each acceptance arm became.
Before the freeze the accounting rides the diff; after it, an append's
`AMENDED` row carries the same field and checks/prd.sh join 14 joins it.

The review's findings are `vid-prd-findings` rows (pass `review`) in the
pause-3 sitting record, so the F-ids the plan cites are durable: a
resolved finding's row is dispositioned `repaired`, and its target names
where the edit landed. One round. Findings that survive it, plus every
`needs_owner`, go to pause 3.

### 12. Pause 3 — final ratification

Run `--pause` and present: the new ViD decisions, ranked; the lens
rewordings, one findings row each (§9b); the remaining findings; the new
near-duplicate pairs (merged, or kept with a findings row, as at pause
2); the scorecard (§ The scorecard), whole. The owner adjudicates what remains: `needs_owner` findings answered
(or explicitly accepted, the acceptance recorded as a ledger answer with the
bound stated and the finding row dispositioned `accepted A-NNN`),
advisory findings read (dispositioned `noted`). The court must pass —
and it holds this mechanically: a blocking finding row without a
resolving disposition refuses the commit. Write the
final Ratifications line and commit. A commit cannot contain its own
sha: each pause's Ratifications line is written immediately after its
commit and rides into the next one, and the final line lands in a
one-line record commit that is part of the pause-3 sitting. From here
the base is immutable and the append law owns all change — with one
exception, the resolution of an open decision: the carrier line is
rewritten `RESOLVED: (OQ-n) A-NNN — …` in the same commit as the answer
and the item's amendment. The hand-back gives counts, never lists: item
counts by type, the non-goal count, the pilot and later counts,
provisional and pending counts with their `confirms_via` routing (the
delegation surface), the features, the owner's decisions split priority
and normal, the ViD decisions (all shown), the open must-never-break
questions, and where the artifact lives. A must-never-break question left
open after pause 3 remains visible debt: the inventory sitting lists
blocking provisionals, and develop builds ViD's recommendation until it
is answered.

**The sweep surface.** Your ViD decisions are the ledger rows marked
`shown:`, reviewed at the pauses — nothing is re-listed at the end. The
owner settles any of them whenever they choose, each settlement an
`A-NNN` answer restating it `human` plus an `AMENDED` append; the court's
report line carries the counts (`provisional=N (owner-decision=M)`,
`priority=P`, `shown=S/M`).

## Pass mechanics — what each fresh context receives

Fresh-context passes are spawned exactly where the chain marks them
(the contract lenses, the thesis red-team, the completeness judgment,
the wording lens, the whole-set review, the scorecard reader), under the
chain's rule, repeated
here:

> **One writer per step** (owner ruling, 2026-09-25). Every step that
> writes PRD.md — item authoring, augment, repair, applying the owner's
> rulings — and every fresh pass — the contract lenses excepted, which are
> separate lenses by design — runs as ONE agent over the whole of its
> input, never partitioned by area, topic, dimension or batch. The one
> writer spawns no agents. When the session must prove an author clean (it
> has read material the run may not use), it hands the whole step to one
> restricted writer and says so; a restriction is never a reason to split.
> If the one agent cannot read its input whole, the step stops: the
> session tells the owner at once — the PRD's size is the owner's product
> question — and never splits the work or reads a subset silently. A pass
> that could not read rows names them in its output.
>
> The one writer writes PRD.md in several appends, each in its own
> response, never the whole set in one: a response has an output cap, and
> its thinking counts against it. The appends are one agent's writes in
> sequence, over the whole input it has read; they are not a split of the
> work.

Each pass brief names what the sub-session receives — and what it must
not:

| Pass | File | Receives | Must not receive |
|---|---|---|---|
| Contract lens (§2) | `passes/contract-lens.md` | the genus statement, the catalog floor, the one-question brief | the other lenses' output (blind to the other lenses); the calling session's reasoning |
| Thesis red-team (§4) | `passes/thesis-red-team.md` | seed, sources, ledger, the drafted thesis | the authoring session's reasoning — it judges the artifact, not the intent; any previous verdict |
| Completeness judgment (§7) | `passes/completeness-audit.md` | the ratified thesis, the effective item set, the ledger, the ratified contract with the catalog prompts | the authoring session's reasoning; any previous verdict |
| Wording lens (§9b) | `passes/wording-lens.md` | every demand item's id, statement and fail-if (the effective set), the seed, the ratified thesis | the authoring session's reasoning; any previous verdict; the derived inventory; other passes' findings |
| Whole-set review (§10) | `passes/whole-set-review.md` | `mode: whole` — the entire effective set with seed, sources, ledger, contract (at consolidation, 7b: the consolidated file plus the arm ledger); `mode: delta` (the append doors) — the effective set, the one append's rows and answers verbatim, the seed, the contract | the authoring session's reasoning; any previous verdict |

Every pass file opens with the same fixed header — the independence
mechanism (a separate agent, no authoring- or build-session context, a
re-run never told the previous verdict, a prompt carrying anything the
calling session believes is VOID and re-spawned); `checks/selftest/cases/
passes.sh` asserts it verbatim in every file under any `passes/`.

Hard schemas are permitted — and used — **only inside a pass's model
calls**: type lists, enums, and the ratified dimension list are passed
as closed enums in structured outputs, recovering generation-time
enum-closure. The schema exists only inside the call; what lands on
disk is only the markdown grammar. The durable artifact is never a
schema-shaped file.

Deleted machinery stays deleted — none of the following is rebuilt, in
any form, under any name: correction verbs or any CLI surface (the
owner edits markdown; the court re-validates on commit), an artifact
store or journals (git), seals or digests (ratification commits — the
sha names the bytes), projections or a handoff package (the PRD IS the
handoff), a replay bench (the fixture self-tests serve this role).

## Consolidation — the scheduled event (v0.9.1 3.4: 7a, then 7b)

Triggered in two places and nowhere else: vid-test-inventory §5 (init
mode, after the sitting's append lands — before the initial commit) and
vid-fix "After applying" (after the last batch of a grade adjudication —
before the final report). Never during develop's slices; never at add.

**7a — the mechanical copy.** `sh checks/prd-consolidate.sh` — a script,
no model: the seed to `SEED.md` with its hash on the header line, the
input's grammar when it is 0.9.4 or later and `grammar: 0.9.1` otherwise,
one ```vid-prd-features block of the effective feature rows (base and
appends, latest per id) before the effective rows (four positional
fields, `phase: pilot` when absent), the effective rulings (no `Q:` text;
the labels ride their rows), every open
carrier and every RESOLVED one-liner kept, Findings and Ratifications
untouched, Appends emptied to its comment; `PRD-HISTORY-<date>.md` keeps
verbatim and in order every append, every superseded row, every question
text and every sitting narrative; `.vid/consolidation-arms-<date>.md` is
the arm ledger — per amended item, its fail-if arms at first ratified
text and at consolidated text, side by side. It refuses to write unless
checks/prd.sh passes on its output, and a second run is byte-identical.

**7b — semantic repairs, proposed separately.** Spawn
`passes/whole-set-review.md` in `mode: whole` over the consolidated file
plus the arm ledger. It proposes — as ordinary AMENDED rows in their own
append, never as edits to 7a's output — ruling propagation across
affected sets, cross-item effects of amendments, and the restoration of
any arm the effective text carries weakened without an accounted
disposition; each proposal carries `arms:`. Record `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" 'tokens slice=N
phase=review n=T'` (in a ViD project only, as the stage events).

**The sitting.** The owner ratifies 7a and 7b as two commits after one
diff sitting in the row-set-diff shape: per effective item, NEW /
CHANGED / DROPPED against the pre-consolidation effective set (7a can
only produce UNCHANGED and CHANGED-by-field-removal; anything else is a
script defect and refuses), and the arm ledger for every item whose arms
changed since first ratification, one line per item for a ruling.
Meaning, not ids, is the criterion: `DROPPED=0` establishes nothing.

## Standalone (no-repo) mode

This verb is project-agnostic. One ratification law everywhere: **when
no repository exists at run start, announce it and run `git init` in
the working directory** — stated plainly, never silently — and
ratifications are commits there, exactly as everywhere else. The sha is
the digest; the Ratifications section names it; append precedence works
unmodified. No hooks are installed (hook installation is init's job);
the court gate above carries the enforcement — run it before each of
the three ratification commits.

The hand-back names the portability fact: **the PRD file carries the
whole record** — seed, ledger, contract, findings, ratification lines.
Moving it into a project later carries everything, and the receiving
repo's first commit of the file re-anchors the law — vid-init adopts
such a file in place of delegation and re-interviews nothing it settles.

**Inside vid-init:** after the pause-3 hand-back, control returns to
init, whose technical-foundation questions follow — ask none of them
here.

## The import door

Any textual document the owner hands over enters in one of two
**owner-declared roles** — ask which:

- **seed** — "this is my demand." The document lands verbatim in
  `## Seed` under a dated sub-heading, at seed authority: it grounds
  `authoritative` items.
- **source** — "this is evidence." The document lands verbatim in
  `## Sources` under a named, dated sub-heading, at supporting
  authority — below the seed and human answers, above model proposals:
  it grounds at most `provisional` items.

Either way **the full chain runs**. The interview shrinks to what the
documents leave inventable — the materiality test does this without a
special mode: a question whose answer the document supplies does not
survive it. The transcription prohibition:

> Items are **authored, never transcribed**: every item cites the
> document in `source:`, and statements are written to the grammar's
> mandates — a document's sentence is grounding, not an item.

Conversion of an existing PRD is therefore ratification-with-teeth: the
owner's old document goes in as seed, and what comes out has passed the
thesis red-team, the falsifier mandate, the completeness audit, and the
owner's three pauses. There is deliberately **no item-level fast
path** — a shortened chain that copies near-grammar items across is
transcription wearing a speed argument. A contradiction between an
imported document and the seed — or inside the seed itself — surfaces
to the owner as a question, never a silent resolution either way.
