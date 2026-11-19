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
pause (v0.9.5 3.13: the owner approves both together), and the owner questions `--pause` lists last (an arm withdrawn
under ViD's draft, § The owner's words, and the questions raised); (3) write the owner's rulings and a `shown: pause-N <sum>` label
on every ViD decision presented; (4) re-run it green; (5) commit, with the `Owner:` trailer(s) quoting the
owner's words (§ The owner's words, and the questions raised).

**The face (0.26.10.29): the same sitting, as data.** Where `.vid/` exists,
before you present a pause's material in step (2), write the same material
for the panel: `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write pause-N <file>`,
the file holding, in `face.sh`'s line form (its head), the sections no
script prints — at pause 1 `thesis`, `contract` and `findings`, at pause 2
`gaps`, at pause 3 `rewordings` and `findings` with its `plain-changed` line,
and at pauses 2 and 3 the recommendation on each pair `duplicates` shows
(below, "Every pause") — each
item under the id you present it by, or `empty <section> | <why>`. The
script reads the rest from `--pause` and the scorecard. A refused line
is rewritten and the call made again; the presentation itself is as
above, whether or not a panel is there. After step (5)'s commit:
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end pause-N`.

**Every pause, in the panel and in the chat alike (0.26.10.29.6, S1, S2,
S4, S7, S10).** This holds for the interview, the three pauses and
consolidation's sitting.
- **The page first.** Write the sitting before you ask, then give the
  owner what `face.sh write` printed about pages before anything else:
  the link, or the file's full path. Where those lines ask the question
  on publishing pages, ask it in the chat, on its own, after the page
  lines and before the pause's own material; the sitting stays as
  written. Then present the pause in the chat, in the sitting's order,
  the same whether or not a panel is there.
- **A stop the map has passed.** Where the map already stands past the
  sitting's stop, `face.sh write` writes nothing, says so in one line and
  exits 0, and `face.sh end` does the same: ask in the chat as below,
  with the page, item by item.
- **An answer is the owner's however it arrives:** sent from the panel,
  or typed in the chat after the same items were presented there. A
  message answers the items it names, one by one.
- **Asked on its own.** Mark `alone`, and ask in the chat as its own
  question, never in a list and never under a blanket yes, every item
  whose recommended answer would remove or weaken a test or a failure
  clause (a rewording that withdraws an arm, a finding that proposes a
  looser bound, a line of consolidation that drops an item or weakens a
  clause), and every setting or permission. A review's weakened clauses
  are one such item for that review, its rows its details.
- **A recommendation on every item that can have one,** in the button's
  own words: each critic finding at pause 1 (`Fix it`, or `Leave it`);
  each of the two qualities to rule in or out (`Needs it`, or `Doesn't
  need it`); each rewording at pause 3 whose arms are all kept or
  strengthened (`Accept`); each near-duplicate pair still shown (`Merge`,
  or `Keep apart`). Where the evidence supports none, write `recommend |
  none` and say "ViD has no recommendation". Every such item carries one
  of the two: `face.sh` refuses a sitting where one has neither. The
  pairs are printed by `--pause`; in the sitting's file write `section
  duplicates`, then for each pair still shown `item <a>~<b>` with no
  words, its one line `recommend | Merge`, `recommend | Keep apart` or
  `recommend | none`, and its `look | <why>` line where "Where to look"
  below asks for one; nothing else in that section. The chat gives the
  same.
- **A blanket yes** ("all recommended") covers only the items shown with
  a recommendation, never an item asked on its own. Answer it with what
  it covered, as counts by section, and ask what it did not cover. Never
  offer "confirm all" for items of different kinds, or for items not
  shown one by one.
- **One question, one decision.** When answering it would change
  something else, a rule or a name used elsewhere, that is a second
  question, asked after the first.
- **Where to look.** Give an item the line `look | <why>` by three counted
  rules and no other judgement: it has an open finding in the findings
  record ("An open finding"); it shapes a must-never-break rule ("Shapes
  a rule that must never break"); you have no recommendation for it ("No
  recommendation"). In each section write the items that carry `look`
  first, and present them first in the chat too; `face.sh` refuses a
  section where one follows an item without it.
- **Plain words, counted numbers.** Every number you give the owner is
  copied from a script's output printed in the same turn. Where
  `face.sh write` names lines that hold an id or one of ViD's own words,
  rewrite those lines in plain words and write the sitting again before
  you ask.
- **Changed since you agreed it.** At pauses 2 and 3, `face.sh` fills
  this section from the last Ratifications line: every line of the
  thesis and the mechanisms that differs since, with the line as it was.
  Present the same list in the chat, each line one item the owner may
  change.

## The scorecard (v0.9.5 part B) — at pauses 2 and 3

Information for the owner, never a gate: it blocks nothing, and ViD
changes nothing because of it unless the owner asks. At pauses 2 and 3,
it is computed after `--pause` is green and before the sitting is
written; it is shown with the pause, after the page lines, in the
sitting's order (0.26.10.29.6, S1; § The court gate, "Every pause"):

1. **The counted half:**

       sh ${CLAUDE_PLUGIN_ROOT}/checks/scorecard.sh PRD.md --previous <prev> --candidates .vid/scorecard-candidates.txt

   `<prev>` is the PRD as committed at the previous pause
   (`git show <that commit>:PRD.md > .vid/scorecard-previous.md`): the
   pause-1 PRD at pause 2, the pause-2 PRD at pause 3 (standalone mode:
   the copy saved at the previous pause).
2. **The judged half:** one restricted reader, in the foreground, with
   `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/scorecard-reader.md` as
   its whole brief, the candidates file, and PRD.md. It writes its lines
   to `.vid/scorecard-reader.txt` and spawns nothing.
   Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.
   If it cannot read
   its input whole, say so and show the counted half alone; never split
   it. **The scorecard waits for its reader** (0.26.10.29.3 phase 2, R7):
   no part of it is shown while the reader runs; tell the owner the reader
   is running and that the scorecard follows when it returns. At pause 3
   it reads the text as it stands at the sitting, after the reviews have converged
   (§ "Reviews converge").
3. **The tally:**

       sh ${CLAUDE_PLUGIN_ROOT}/checks/scorecard.sh --tally .vid/scorecard-candidates.txt .vid/scorecard-reader.txt

   When its flags name candidates the reader did not answer, run the
   reader once more on those candidates alone (a candidates file holding
   only their lines, numbers kept), add its lines to
   `.vid/scorecard-reader.txt`, and tally again. Once more, never a loop:
   then the scorecard is complete, any candidate still unanswered counted
   as such, and is shown with the pause, after the page lines.

4. **Show the whole scorecard, every time**, at its place in the
   pause's order, after the page lines, in plain
   words, one line per quality: its numbers as the two outputs print
   them, each judged number with its agreement beside it ("12 of 17
   agreed" or "not yet checked"), and the items behind every flag. Never
   restate a number the outputs did not print. Size is the project's own:
   no count is called too many or too few in the scorecard; the size
   sentence (§8, item 2) is the one place size is judged. The counted `coherent` line
   counts near-duplicate pairs only; contradictions are the reviews' to
   find, so never present it as a check for them.

## The findings record

What the grading passes found — and how each finding was dispositioned —
is part of the artifact, not of the session. At every pause, before its
commit, write the sitting into `## Findings` under a dated sub-heading:
one `vid-prd-findings` row per finding —

    F-NN | pass | severity | target | disposition | evidence: …

pass ∈ `red-team` | `audit` | `review` | `lens` | `final` | `strength` (the
inventory's strength pass, vid-test-inventory §3); severity ∈ `blocking` |
`advisory`; the target names item, `MECH-`, `DIM-` or answer (`A-NNN`)
ids, `thesis`, or `seed`, or another document — `INVENTORY.md:ROW-12`,
`DESIGN-BRIEF.md:D-149`, or the bare file name, one of `DESIGN-BRIEF.md`,
a path under `design/`, ARCHITECTURE.md, DECISIONS.md, BASELINE.md,
INVENTORY.md, GRADING-CHECKLIST.md or STAGES.md (the court checks such a
target's form, never looks its id up); a contradiction's target lists
every row in conflict, comma-separated; the disposition is `repaired`, `overruled A-NNN`,
`accepted A-NNN`, `routed OQ-n`, or `noted` (advisory only). The court
joins all of it: a blocking finding without a resolving disposition
blocks the pause mechanically, dispositions must cite ledger rows or
live carriers that exist, and a finding whose target resolves to
nothing is refused. A clean sitting is recorded as a prose line under
its heading — **a finding is never manufactured to fill the block.**
The ratification sha thereby covers what the owner was SHOWN, not only
what they decided.

**Every review is recorded here** (0.26.10.29.3 phase 2, R6), whenever
it runs: pauses 1 to 3 under their sitting headings; the append doors'
delta reviews in their own sections (0.26.10.29.3 R3); 7b, and the final
passes (vid-init's, and the one after init's cut), each under a dated
`## Findings` sub-heading of its own; and the inventory's strength pass
(vid-test-inventory §3, pass `strength`), under a dated `## Findings`
sub-heading of its own at every round it runs. A review held only in
`.vid/` is not recorded.

- **Severity.** A reviewer's own "critical" or "major" is recorded
  `blocking`, its word kept at the start of the evidence
  (`evidence: critical — …`); only "minor" or "advisory" is recorded
  `advisory`. A severity is never folded down.
- **Whole reports.** Save each pass's return verbatim, before reading
  it, as `.vid/reviews/<pass>-<date>-<n>-r<round>-<reader>.md`: `<n>`
  counts that pass's runs that day, `<reader>` is `agent` or `codex`,
  so two readers, or two runs on one day, never share a name. Write the
  rows from that file, every finding one row; a condensed copy is never
  the record. The pass's own output format is unchanged.
- **The review line** (R2). One line, outside any fence:
  `review: <mode>, round <r>, <n> findings`, and for a final review
  `, read: <files>` after it — `<mode>` is `delta`, `whole` or `final`;
  `<r>` is the round the review ended on (§ "Reviews converge"); `<n>` is
  the number of rows in the findings block under the same section or
  heading, every round and both readers merged, counted from the block
  itself; `read:` lists, space-separated, the documents the final pass
  read (`read: PRD.md DESIGN-BRIEF.md design/ ARCHITECTURE.md
  DECISIONS.md BASELINE.md INVENTORY.md GRADING-CHECKLIST.md`). A review
  of one round with no findings is `round 1, 0 findings`. It goes in an
  append section for a delta review, and in the review's `## Findings`
  sub-heading for a whole or final review (pause 3, 7b, the final
  passes), every round's and both readers' rows in that heading's one
  block. One exception: the strength pass's line sits under its own
  `## Findings` sub-heading in every mode, `review: delta, …` too in
  append mode and at materialisation. A repair append a whole or final review makes (7b's proposals,
  the final pass's PRD repairs) holds no rows of its own and carries
  `review: <whole|final>, round <r>, 0 findings, see <heading>`, naming
  the `### ` sub-heading under `## Findings` that holds them, its text
  without the `### ` (`see 2026-11-15 — consolidation review`), and no
  `read:`; a finding id appears once. A line written
  before this form (`review: delta, <n> findings`, no round) reads as
  round 1 and is never rewritten.
- **Dismissals.** A blocking finding ViD believes wrong is never
  dropped and never `noted`: it is a row, and only the owner disposes of
  it (`overruled A-NNN`). The question to the owner quotes the file and
  line ViD's belief rests on, so a false premise shows.

## The owner's words, and the questions raised (0.26.10.29.3, R2, R4)

The rule for every door that writes PRD answers — this verb's pauses, the
inventory's sitting, design's sitting, add, fix, stage and develop's
answers, delegated answers included; each door's skill points here.

**The owner's words live in the commit's `Owner:` trailer alone.** An
answer row, a decision line and a golden set's provenance state the
ruling in ViD's own words and cite its id; they never quote the owner.
Records are copied into briefs and into the spec an outside team reads,
and no rule on a quote's form can tell the owner's words from a quoted
screen string, so the copy stops at the source.

**An answer is the owner's only with the owner's words.** Between
sittings ViD drafts every answer as `model_proposed`: its own decision,
routed as §6 says. At a sitting, after the owner's yes, the yes is
recorded as a `human` row — the draft itself while it is still
uncommitted, else an `A-NNN AMENDED` row in a new append restating the
full row `human`. The commit that adds a human ruling carries at least
one `Owner:` trailer quoting the owner's words — `Owner: "<words>"` for
the sitting, or, when the answers came in different words, one per
answer, `Owner: A-NNN "<words>"`. An answer ViD writes under the owner's
delegation is the owner's at once: `human`, its row carrying the field
`delegated: yes`, its trailer quoting the delegation, and, in a ViD
project, marked delegated before its commit (`sh checks/metrics.sh
delegated --answer <A-id>`, which asks for the field). The owner's
confirmation of a delegated answer restates it `A-NNN AMENDED | human`
without the field, their own words in the trailer. One exception: an
answer that an `arms:` entry `withdrawn A-NNN` would cite. Under a
delegation it is written `model_proposed`, never `human`, and its
withdrawing amendment is not committed — join 14 holds it as a gap, and
the mark is refused for an answer a withdrawn arm cites. Nothing it would
remove is removed: the question goes to the owner at the next sitting,
and on their yes the answer is restated `human` with the owner's own
words in the `Owner:` trailer, not the delegation's, is not marked
delegated, and the withdrawal then lands. The court holds the order
too: an arm withdrawn under an answer whose row carries `delegated: yes`
— written before the answer or long after — is a gap at commit and an
owner question under `--pause`, as under a draft, until the answer is
confirmed. The commit-msg hook refuses a commit
whose staged PRD holds a `human` answer HEAD does not — a new id, a
changed `A:`, or a draft restated `human` — without one; consolidation
(which drops `Q:` text) and rows left as they were add none. Nothing
proves the words are real: the rule makes the honest record the easy
one.

**A draft never withdraws a fail-if arm on its own.** An `arms:` entry
`withdrawn A-NNN` under a `model_proposed` answer is a gap at commit;
under `--pause` it is not refused, and the pause material lists it last,
as an owner question: `arm N of REQ-x withdrawn under ViD's draft A-NNN`
(under a delegated answer: `… withdrawn under A-NNN, a delegated answer
not yet confirmed`).
Ask it at the sitting. Both exits are the owner's ruling on the answer,
recorded as one: the yes restates the answer `human`; the no restates it
`human` with the no in its `A:` and amends the item with the arm back
(while the withdrawing row is still uncommitted, the row is simply not
written); either way the owner's words go in the `Owner:` trailer. No
later amendment of the item clears the gap while the answer is still
ViD's draft.

**A question an agent raises is recorded at once.** A question a pass's
or an agent's report raises, which ViD cannot settle from the record — a
ruling, the seed, or an owner answer it can cite — becomes an open carrier
at once, `VID-QUESTION: (OQ-n) <the question>`, its number continuing the
sequence (under `## Open decisions` before the final ratification, in a
dated append after it), and is raised with the owner at the next sitting.
A question ViD settles from the record is no carrier: the message to the
owner names the record line that settles it. **Every hand-back that
states open questions quotes the court's count** — the `open-OQs=` field
of `sh ${CLAUDE_PLUGIN_ROOT}/checks/prd.sh --report PRD.md` — never a
number, or "none", of its own.

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
 repair, then read again (a diff)           skill
    ↓
 PAUSE 3 — final ratification             ← a commit
```

> **One writer per step**. Every step that
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

**The wait's parts, and the drafts (0.26.10.29.6, S11).** Where `.vid/`
exists, at the start of each wait below name its parts,
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" wait parts "<part>" …` in this
order, and as each step starts call `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" wait at <n>`:

| Before | Parts, and the step each is |
|---|---|
| the interview | Reading what you wrote (absorbing the seed) · Choosing the questions (the materiality test) |
| the summary | The qualities (§2) · The summary and the features (§3) · The critic (§4) |
| the gaps | Writing the requirements (§6) · Checking them (§7) · The scorecard (§ The scorecard, computed here, shown with the pause) |
| the final wording | Folding in your answers (§9) · The wording check (§9b) · The review (§10) · Repairs (§11) · The final pass (§11's reading again, and the scorecard) |

Show what you have so far with `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" draft <sitting> <file>`,
the same lines as its `write`: the qualities when the list is merged
(`draft pause-1`, `section contract`), the summary when it is written
(`draft pause-1`, `section thesis` with the qualities again), and the
gaps as the audit returns them (`draft pause-2`, `section gaps`).

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
accepted recommendation, or in a blanket "all recommended" (which covers
the items shown with a recommendation, and no item asked on its own;
§ The court gate, "Every pause"): one ledger
row per question, its `A:` restating the value decided ("accepted as
recommended: 30 days"), because values are traced against `A:` texts and
consolidation drops `Q:`. The materiality defaults — the questions the
test discarded — are ViD's decisions: `model_proposed` rows, `Q:` the
decision, `A:` the default with its values stated, shown to the owner at
pause 1 among the ranked ViD decisions (§5). Where an answer shapes a
must-never-break (T0) rule, ViD marks it `importance: priority` and says
so; the owner may raise or lower any answer's marker — priority marks the
big decisions, and the rest are normal. **After writing answers**, here,
at a pause or when applying the owner's rulings, run
`sh "${CLAUDE_PLUGIN_ROOT}/checks/prd.sh" PRD.md` and set the mark on
each answer its `importance` notes name before going on (0.26.10.29.6,
S6): the notes refuse nothing, and `--pause` refuses what is left.

**A request for research** (0.26.10.29.6, S5). When the seed or an
answer asks ViD to find something out before it decides (to understand
a market, read a competitor, check a rule), do it and give what you read
and what you concluded at the next pause, as a text section "What you
asked ViD to find out", or ask the owner one question: how far to go.
Until one of the two has happened it is an open question
(`VID-QUESTION: (OQ-n)`, § The owner's words, and the questions raised):
never a finding with a default exit, and no blanket yes closes it.

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

**No size number before pause 2** (0.26.10.29.4, phase 4 R4). The
interview gives no estimate of how many requirements the PRD will hold,
and pause 1 none either: requirements are authored in step 6, after it,
and a number that was not counted is never presented. Size is first
counted at pause 2 (§8, the size sentence).

**The face (0.26.10.29): the interview, as data.** Where `.vid/` exists,
before you ask the batch, write it for the panel:
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write interview <file>`, the
file holding, in `face.sh`'s line form (its head), `section questions`
with each question as you ask it (`item`, its `recommend` and `choice`
lines) and `section challenge` with each capability of the boundary
challenge. Once the answers are in the ledger:
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end interview`.

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

Run `--pause` (the court gate's sequence), then write the sitting,
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write pause-1 <file>`, and
give its page lines first (§ The court gate, "Every pause"); after the
commit, `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end pause-1`. One sitting: the thesis, the
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
write the Ratifications line, commit — staging `.gitattributes` with
PRD.md when the file is present (0.26.10.28.1: vid-init writes its line-ending
pins first, so this first commit carries them).

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
from that template, whose header line `grammar: 0.26.11.1.2` puts it under the
0.9.5 court's rules and later ones (v0.9.8.1 R38: join 17 reads every
answer a `source:` cites; 0.26.11.1.2 R13: a fail-if in numbered parts) from its first commit — four positional fields (there is no
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

  **A fail-if in numbered parts** (0.26.11.1.2, R13). Under
  `grammar: 0.26.11.1.2` the fail-if is written `fail-if: (1) <what a wrong
  product does>; (2) <another> …`, in the falsifier wording, one failure a
  part, still one field on one line. Each part is one arm: the count of
  `arms:` entries, the hostility rows per arm and the consolidation's arm
  ledger read the numbers, never a guess at "or". `checks/prd.sh` refuses a
  fail-if that does not open `(1) `, numbers that skip and an empty part;
  whether a part holds one failure is yours to write and the wording
  lens's to read. A PRD under an older grammar keeps its sentences as
  written.
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
- **A cut feature stays cut** (0.26.10.29.4, phase 3 R7). Once a feature
  is cut, out of scope or a non-goal, ViD never proposes bringing it
  back; it is re-opened only when the owner asks.
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
is not shown again. Then write the sitting,
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write pause-2 <file>`, give
its page lines first (§ The court gate, "Every pause"), and present, in
this order, with what changed since pause 1 (its section "Changed since
you agreed it"); after the commit, `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end pause-2`:

1. the questions: the audit's gaps, then the must-never-break questions
   (`--pause` lists each with ViD's recommendation and the T0 items
   waiting on it);
2. **the size sentence** (0.26.10.29.4, phase 4 R4), in plain words, its
   numbers from the `size:` line this pause's `--pause` prints, never
   estimated — N its `demand=`, P its `pilot=`, X and Y with n and m its
   `largest=`, and S the minimum number of stages so that none holds more
   than 60 requirements: P ÷ 60, rounded up:

   > This PRD holds N requirements — about N/30 grading batches, where ViD
   > grades comfortably up to two. Past that, rules that span features are the
   > first to slip. The P not marked "later" need at least S stages so that
   > no stage holds more than 60. The largest features are X (n) and Y (m).
   > You choose, at this pause and each later one: keep everything and stage
   > it, or move features to "later".

   When S is 1 its fourth sentence says instead that the P not marked
   "later" fit in one stage. Keeping everything hands size to the cut, which is held to
   it: no stage above 60 requirements (vid-stage). The same sentence, with
   the counts of that moment, is shown again at pause 3 (§12) and at the
   cut's sitting; moving features to "later" lowers P and S.

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
3.2.) Its findings are repaired (§11) and read again by the one rule,
§ "Reviews converge" (Pass mechanics), with the second reader beside the
fresh agent in every round (§ "The second reader").

### 11. Repair — a diff, then read again

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
where the edit landed. Then the same pass reads the repair again, round
by round, by § "Reviews converge" (Pass mechanics); every round's rows, and
both readers', go in this one sitting block under its line
`review: whole, round <r>, <n> findings` (§ "The findings record").
What the rounds could not close, and every `needs_owner`, go to pause 3
as the one list, each with ViD's recommended answer.

**Reporting repairs (0.26.10.29.6, S4).** Wherever you report repairs to
the owner, list them in two groups: first each repair that follows an
answer of the owner's, each entry giving that answer (`A-NNN`, in the
owner's words); then every other repair, under "On ViD's own judgement".
A count you give for a group is the count of the entries you list.
Never put both under "from what you've decided".

### 12. Pause 3 — final ratification

Run `--pause`, write the sitting,
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write pause-3 <file>`, give
its page lines first (§ The court gate, "Every pause"), and present: what
changed since pause 2 (its section "Changed since you agreed it"); the
repairs, in two groups (§11); the size sentence (§8, item 2), with the
counts this pause's `--pause` prints, and the owner's choice again; the new ViD decisions, ranked; the lens
rewordings, one findings row each (§9b); the remaining findings; the new
near-duplicate pairs (merged, or kept with a findings row, as at pause
2); the scorecard (§ The scorecard), whole. The owner adjudicates what remains: `needs_owner` findings answered
(or explicitly accepted, the acceptance recorded as a ledger answer with the
bound stated and the finding row dispositioned `accepted A-NNN`),
advisory findings read (dispositioned `noted`). Applying the owner's
rulings is a repair: before the commit the same loop reads what they
changed (§ "Reviews converge"), and only new product decisions and what it
could not close come back, in the same one list. The court must pass —
and it holds this mechanically: a blocking finding row without a
resolving disposition refuses the commit. Write the
final Ratifications line and commit, then
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end pause-3`. A commit cannot contain its own
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
questions, the open questions as the court's `open-OQs=` count (§ The
owner's words, and the questions raised), and where the artifact lives. A must-never-break question left
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
the wording lens, the whole-set review, the scorecard reader) and
where vid-init marks its final review, under the chain's rule, repeated
here:

> **One writer per step**. Every step that
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
| Whole-set review (§10) | `passes/whole-set-review.md` | `mode: whole` — the entire effective set with seed, sources, ledger, contract (at consolidation, 7b: the consolidated file plus the arm ledger); `mode: delta` (the append doors, and every re-read round of § "Reviews converge") — the effective set, the one append's rows and answers verbatim (a re-read: the rows the repair changed, their affected set, ViD's recommended answer to every open `needs_owner` finding), the open entries `sh checks/prd.sh --arms` lists for the delta's own rows, the seed, the contract | the authoring session's reasoning; any previous verdict |
| Final review (vid-init) | `final-review.md`, in this skill's passes folder | the PRD without its `## Findings` section, its append sections' `vid-prd-findings` blocks and its `review:` lines; the design when there is one (`DESIGN-BRIEF.md`, `design/screens/` with its `index.json`, `design/tokens.css`); ARCHITECTURE.md, DECISIONS.md, BASELINE.md, INVENTORY.md, GRADING-CHECKLIST.md; after the cut, STAGES.md and the output of `sh checks/stages.sh check` and `counts` | the session's reasoning; any previous verdict |

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

### Reviews converge (0.26.10.29.3 phase 2, R1)

The one rule for every fresh review whose findings ViD repairs: the
whole-set review (§10, and 7b), the append doors' delta reviews (vid-add
§2, vid-fix (a), vid-develop's two-channel rule, vid-design §4,
vid-test-inventory §5, vid-stage's answer; 0.26.10.29.3 R3) and the
final passes (vid-init's, and the one after init's cut), and the
inventory's strength pass (vid-test-inventory §3). The design
door's consistency pass is not one: it already loops until the design is
re-imported and the pass re-run empty. Nor is the contract panel (§2):
ViD repairs nothing it says, and it stays one round, no loop.

- **Round 1 is the pass as written, with no count limit.** A caller
  never caps how many findings a pass returns — not in the brief, the
  prompt, or the reading of its return.
- **Repair, then read again.** ViD repairs the `fix_from_record` and
  `fix_model_authority` findings by §11's rules (a fix strengthens; the
  plan is a diff). Whenever a round's findings were repaired, whatever
  their severity, the same pass runs again in `mode: delta` on three
  things: the rows the repair changed, their affected set, and ViD's
  recommended answer to every open `needs_owner` finding, which it judges
  for soundness.
- **Later rounds report blocking findings only, on what changed.**
- **Stopping.** These tests apply to the re-read rounds. The loop stops
  at the first of: a re-read round with no blocking finding; a round
  whose blocking count is not lower than the round before; the end of
  round 3. With two readers the count is the merged one (§ "The second
  reader").
- **What remains is still open, and the owner never fixes anything.**
  ViD gives the owner one list, each entry with ViD's recommended
  answer: the product decisions only the owner can make (`needs_owner`),
  and the findings the rounds could not close. For each of those, the
  owner either accepts it as a known gap — an answer stating the bound,
  the row dispositioned `accepted A-NNN`, as at pause 3 — or rules how it
  should go.
- **After the owner rules, the same loop runs again.** Applying the
  rulings is a repair like any other: the same pass reads what changed,
  ViD repairs what it finds itself, and the stop tests and the cap of
  three rounds apply. Only new product decisions, and what this loop
  could not close, go back to the owner, in the same one list. A new loop
  starts only from the owner's own answers, never by itself; each ends
  within three rounds, so the sitting ends when the owner has nothing
  more to rule.
- **The record.** Every round's rows go in the review's one findings
  block, and its `review:` line names the round it ended on (§ "The
  findings record").

### The second reader (0.26.10.29.3 phase 2, R5)

- **The question.** At the first whole-mode review on a machine, run
  `sh "${CLAUDE_PLUGIN_ROOT}/checks/lib/wsl.sh" reviewers ask`. It prints
  nothing unless `codex` is on the PATH and no answer is recorded; then
  it prints one question, which you ask the owner as written, alone, and
  record the answer with
  `sh "${CLAUDE_PLUGIN_ROOT}/checks/lib/wsl.sh" reviewers record yes` (or
  `record no`). The answer is `.vid/reviewers` at the main checkout,
  beside `.vid/windows`, so worktrees and other sessions follow it. It is
  a question about this machine, not a product question or an approval
  point: ViD never asks it again, and asks nothing when `codex` is
  absent.
- **Where it reads.** When `sh "${CLAUDE_PLUGIN_ROOT}/checks/lib/wsl.sh"
  reviewers` prints `yes`, every round of the whole-mode reviews — §10
  at pause 3, 7b, the final passes, and the strength pass's table pass
  in `mode: whole` (vid-test-inventory §3) — has Codex as a second reader
  beside the fresh agent. The delta reviews of appends keep one reader.
  Each reader reads the whole input: two readers are not a split of the
  work (the one-writer rule).
- **How.** Write the pass's brief to `.vid/briefs/<pass>-<n>.md`: the
  pass file and every input as a path, never their contents (an input
  that is not yet a file, such as a re-read round's rows, is written to
  a file beside the brief and named).
  Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.
  Start the fresh agent on that
  brief and, in the same message, in the background:

      codex exec --skip-git-repo-check -s read-only -o .vid/reviews/<pass>-<date>-<n>-r<round>-codex.md -C <project> "Read .vid/briefs/<pass>-<n>.md and the files it lists, and do what it says." < /dev/null

  on Codex's own configured model (no model flag). The argument stays
  that one short sentence: a real project's inputs run to hundreds of
  KB, past the command-line limit of every platform.
- **The merge.** A finding both readers raise is one row, its evidence
  naming both readers; every other finding is a row naming its reader.
  The round's blocking count, for the stop tests, is the merged one.
- **If Codex fails or times out** — a non-zero exit, no report, or no
  return 15 minutes after the fresh agent's — the round goes on with the
  fresh agent's report alone, and the owner is told in one line.

### While a pass runs (0.26.10.29.3 phase 2, R8)

- **Side by side.** Readers that do not need each other's output start
  at the same time, in one message — the two readers of a round. The
  scorecard reader is not one of them: it reads the text after the
  reviews have converged (§ "The scorecard").
- **Say what is running.** While a reader runs and no question is
  pending, tell the owner what is running and that you will report when
  it finishes. Never leave the owner with neither a question nor a
  stated wait.
- **Unpiped courts.** Run a court or check on its own, never piped
  (no `| tail`, no `| head`): its exit code is the result, and a refusal
  stops the step — a pass whose brief a court refused is not started.
- **The brief as written.** Start a pass with its brief file and its
  inputs, and nothing else. A sentence of the caller's own in the prompt
  — a steer, a hint, an expected answer, a count — makes the pass VOID,
  as its header says, and it is re-spawned clean.

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
fields, `phase: pilot` when absent), `## Mechanisms` as the effective
mechanism rows (base and appends, latest per id, the `AMENDED` marker
stripped, in first-appearance order — every owner-amended mechanism in
its amended wording; 0.26.10.29.3, R1), the effective rulings (no `Q:` text;
the labels ride their rows), every open
carrier and every RESOLVED one-liner kept, Findings and Ratifications
untouched, Appends emptied to its comment; `PRD-HISTORY-<date>.md` keeps
verbatim and in order every append, every superseded row, every question
text and every sitting narrative; `.vid/consolidation-arms-<date>.md` is
the arm ledger — per amended item, its fail-if arms at first ratified
text and at consolidated text, side by side. It refuses to write unless
its output's effective mechanism rows are its input's, row for row, and
checks/prd.sh passes on its output given the input as `--before` (the
court compares the effective mechanism rows of the two files); a second
run is byte-identical.

**7b — semantic repairs, proposed separately.** Spawn
`passes/whole-set-review.md` in `mode: whole` over the consolidated file
plus the arm ledger. It proposes — as ordinary AMENDED rows in their own
append, never as edits to 7a's output — ruling propagation across
affected sets, cross-item effects of amendments, and the restoration of
any arm the effective text carries weakened without an accounted
disposition; each proposal carries `arms:`. Its rounds follow § "Reviews
converge" (Pass mechanics), with the second reader (§ "The second
reader"). Its record (0.26.10.29.3 phase 2, R2, R6): every round's
findings, and both readers', ruled, as rows under a dated `## Findings`
sub-heading of their own (`### <date> — consolidation review`) with the line `review: whole, round <r>, <n>
findings`; its append holds no rows and carries `review: whole, round
<r>, 0 findings, see <that heading>`. Record `sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" 'tokens slice=N
phase=review n=T'` (in a ViD project only, as the stage events).

**The sitting.** The owner ratifies 7a and 7b as two commits after one
diff sitting in the row-set-diff shape: per effective item, NEW /
CHANGED / DROPPED against the pre-consolidation effective set (7a can
only produce UNCHANGED and CHANGED-by-field-removal; anything else is a
script defect and refuses), and the arm ledger for every item whose arms
changed since first ratification, one line per item for a ruling.
Meaning, not ids, is the criterion: `DROPPED=0` establishes nothing.

**Its sitting (0.26.10.29.6, S1, S2).** Where `.vid/` exists, write it
before you ask, `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write consolidation <file>`,
the file holding `section changes`, "What consolidation changed in the
PRD", and `section alone`, "Asked on their own". A dropped item, and each
line of the arm ledger that weakens or removes a clause, is in `alone`,
an item of its own, never in `changes`; 7b's review's weakened clauses
are one such item (§ The court gate, "Every pause"). `changes` holds
every other change only, one item each (it
starts at Fine); a section with nothing in it is `empty <section> | <why>`.
After the two commits,
`sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end consolidation`. Run from
vid-fix, after init, the map has passed the stop: the write writes
nothing and you ask in the chat, item by item, with the page.

## Standalone (no-repo) mode

This verb is project-agnostic. One ratification law everywhere: **when
no repository exists at run start, announce it and run `git init` in
the working directory** — stated plainly, never silently — and
ratifications are commits there, exactly as everywhere else. The sha is
the digest; the Ratifications section names it; append precedence works
unmodified. No hooks are installed (hook installation is init's job);
the court gate above carries the enforcement — run it before each of
the three ratification commits.

**First, on a PC (0.26.10.29.3, R6; 0.26.11.1.3, R2).** Standalone only (inside
vid-init, init has run it already): after the `git init` above and before
the interview, run `sh "${CLAUDE_PLUGIN_ROOT}/checks/lib/wsl.sh" notice`. It
prints nothing except once on a native Windows shell with no answer
recorded for this PC: there it checks that WSL starts, records the answer
and prints one line, which you show the owner as written, and go on. It
asks nothing and is not an approval point; the line names the file to edit
to turn WSL off.

The hand-back names the portability fact: **the PRD and its SEED.md
carry the whole record** (the PRD alone when the seed sits in its
`## Seed` section; 0.26.10.29.3, R9) — seed, ledger, contract, findings,
ratification lines. Moving both into a project later carries everything,
and the receiving repo's first commit of the file re-anchors the law — vid-init adopts
such a file in place of delegation and re-interviews nothing it settles.

**Inside vid-init:** after the pause-3 hand-back, control returns to
init, whose technical-foundation questions follow — ask none of them
here.

## The import door

Any textual document the owner hands over enters in one of two
**owner-declared roles** — ask which:

- **seed** — "this is my demand." The document lands verbatim in
  `## Seed` under a dated sub-heading, at seed authority: it grounds
  `authoritative` items. A seed document with its own `## ` headings goes
  to `SEED.md` beside the PRD instead, verbatim, with the header line
  `Seed: SEED.md (sha256 <its hash>)` from its first commit, which the
  court reads: a `## Seed` section ends at the next `## ` line, so such a
  seed would be cut short there (0.26.10.29.3, R9).
- **source** — "this is evidence." The document lands verbatim in
  `## Sources` under a named, dated sub-heading, at supporting
  authority — below the seed and human answers, above model proposals:
  it grounds at most `provisional` items.

Either way **the full chain runs**. The interview shrinks to what the
documents leave inventable — the materiality test does this without a
special mode: a question whose answer the document supplies does not
survive it. A document that asks ViD to find something out before it
decides is a request for research, done or asked about as §1 says, never
closed by a default (0.26.10.29.6, S5). The transcription prohibition:

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
