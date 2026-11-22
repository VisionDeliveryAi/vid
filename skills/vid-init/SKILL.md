---
name: vid-init
description: Start a ViD project in an empty directory — delegate product elicitation to the vid-create-prd skill (run inline as init's first act, its materiality-tested interview and three ratification pauses produce the enriched PRD.md) or adopt a PRD that skill already ratified, interview the owner for the technical foundation, generate BASELINE/DECISIONS/ARCHITECTURE/CLAUDE.md, run the design chain when the product has a face, ratify the Test Inventory (its writable rows marked `owed: spec-only — first stage`, their tests not written yet), install the hook courts, make the spec commit, cut the stages. Init makes the spec only (v0.26.10.9): the code skeleton — the stack, the harness, the extractors, the written and red ledger — is /vid develop's first step, or the dev team's first ticket under /vid plan. Use when the owner says "vid init", "start a vid project", or wants to begin a new product under ViD.
---

# /vid init

You are setting up a ViD project for an owner who is a world-class product
expert and may know nothing about code. Run once, in an empty (or nearly
empty) directory. If the directory already contains a ViD project (a CLAUDE.md
with a ```vid-placement block), stop and point the owner at /vid add or /vid fix.

Init is the AUTHORITY PHASE. Everything the owner ratifies here is frozen
baseline; everything after is "make the ledger green". Three ratifications,
in order:

    product elicitation → /vid create-prd, run inline
      (its interview batch, three pauses, three
      commits) → the enriched PRD.md — or a PRD it
      already ratified, adopted                       ← ratification 1
    technical foundation (init's own channel) →
      BASELINE / ARCHITECTURE / DECISIONS / CLAUDE.md
    design brief (+ manifest) → owner authors →
      import reconciliation (fail-closed) → design/  ← ratification 2 (when the product has a face)
    Test Inventory rows (incl. genus rows and the
      census row classes) → owner ratifies; the
      writable rows `owed: spec-only — first stage`  ← ratification 3
    the stage cut → /vid stage, run inline; one
      sitting: the owner ratifies the cards, changes
      them, or keeps a single stage (v0.26.10.5)      ← the stage sitting

Before anything else, read the plugin's seed library
(`${CLAUDE_PLUGIN_ROOT}/seed/`): rules.md and checklist.md are promoted
knowledge from prior runs — empty on a fresh install — pre-loaded as
proposals for the genus step and the grading checklist below;
seed/extractors/README.md is the extractor contract every generated
extractor must meet.

This plugin ships everything you need:

- `${CLAUDE_PLUGIN_ROOT}/templates/` — artifact skeletons ({{PLACEHOLDERS}} to fill)
- `${CLAUDE_PLUGIN_ROOT}/checks/` — the hook courts and scripts, copied verbatim
- `${CLAUDE_PLUGIN_ROOT}/seed/` — the promoted library: genus-row proposals,
  checklist lines, the extractor contract + class catalog (nothing installed
  verbatim; everything passes through ratification)

Throughout: narrate position briefly before each step ("interview done;
scaffolding the stack next") — visibility, never approval-seeking. Internal
issues (doc consistency, template friction, naming) are yours to sort out
autonomously; log the surprising ones to DECISIONS.md. Report "blocked" only
for the genuinely impossible (no git, no network for toolchain install;
v0.26.10.9: no Docker is no longer init's blocker — it is the code skeleton's) — say plainly what is missing and finish
everything that is still possible.

**Init's stage event comes first (v0.9.5 3.11, R11; RECORDS.md).** Before
step 1 record
`sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh" "stage name=init state=start session=$CLAUDE_CODE_SESSION_ID records=29"`
— the plugin's copy of the helper, since checks/ is copied only at step 6;
it creates `.vid/`, which is how create-prd, design and test-inventory,
run inside init, know they are in a ViD project and record their own
stages. At the hand-back (step 8) record its end with `made=spec` (R6).
Right after it, pin the line endings (0.26.10.28.1, 9.1 R4):
`sh "${CLAUDE_PLUGIN_ROOT}/checks/eol.sh" write` — the plugin's copy too —
writes `.gitattributes` (or adds the pins it lacks), so the spec files,
the scripts and `checks/` keep LF line endings on every checkout, Git for
Windows' included. The project's first commit carries it: create-prd's
first ratification commit when create-prd runs inside init, else the
adoption commit below, else (create-prd ran standalone and its file is
already committed here) the spec commit, step 7. Every helper file ViD
writes for itself on the way — a script, a scratch copy, a draft a court
reads — is written as UTF-8 with Unix (LF) line endings, whatever the
machine's default (0.26.10.29.3, R9).
Then the WSL notice (0.26.10.29.3, R6; 0.26.11.1.3, R2): run
`sh "${CLAUDE_PLUGIN_ROOT}/checks/lib/wsl.sh" notice` — the plugin's copy too.
It prints nothing except once on a native Windows shell with no answer
recorded for this PC: there it checks that WSL starts, records the answer
(`.vid/windows`, per machine and untracked) and prints one line, which you
show the owner as written, and go on. It asks nothing, and the owner needs
to do nothing: the line names the file to edit to turn WSL off. The courts
follow the answer by themselves, so nothing else in this skill changes.

**Init makes the spec only (v0.26.10.9 R1, VS-3).** What init still does:
steps 1 to 4, with the inventory at call point 1 only; from step 6 only the
copy of `checks/` (the shipped courts, helpers and self-test), `git config
core.hooksPath checks/hooks`, `.vid/budget` and the two host-settings
questions; the final review (step 6b); the labelling pass; the spec
commit (step 7); step 7b, the stage cut, with its final review; the
hand-back. Nothing is rewritten: the code
skeleton's text moved to the internal `vid-skeleton` skill, which /vid
develop runs as its first step; in ticket mode (/vid plan) the skeleton is
the dev team's first ticket and ViD writes the tests ticket by ticket. Every
shipped court is presence-gated, so the spec commit and the stage cut pass
on a tree with no code, no harness and no extractor.

**ViD's own defects (v0.26.10.3 R12, R13).** When a ViD check, hook,
skill or agent role misbehaves — it refuses legitimate work, crashes,
contradicts itself or its documentation, or gives a wrong count — or when
you use a workaround around one, append an entry to `.vid/VID-FINDINGS.md`
in the form of `${CLAUDE_PLUGIN_ROOT}/templates/VID-FINDINGS.md` (the file
is created from it at the first entry; entries are numbered in the file),
record `sh checks/event.sh 'vid-finding n=<n> area=check|hook|skill|agent file=<ViD
path>'`, and tell the owner in one line (before step 6 copies checks/, the plugin's
`sh "${CLAUDE_PLUGIN_ROOT}/checks/event.sh"`). A defect in the product being
built is not a ViD finding.

## 1. Product elicitation — delegated to /vid create-prd (the two-channel split)

Two channels, two owners. **Product elicitation** — what the product is,
for whom, the behaviors that make it real, what must never break or leak,
what is deliberately out, what wrong costs — belongs to the vid-create-prd
skill (`${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/SKILL.md`). Run it
now, inline, as init's first act: read that skill and follow it whole —
its materiality-tested interview batch (with the scope challenge), the
contract panel, the thesis and its red-team, item authoring under the
falsifier mandate, the completeness audit, the whole-set review, and its
**three ratification pauses, each ending in a commit**. The skill runs
`git init` when no repository exists (it announces it); inside init that
repository IS the project's — the three ratification commits are the
project's first history, and the skill's court gate
(`sh ${CLAUDE_PLUGIN_ROOT}/checks/prd.sh --pause PRD.md`) runs before each. Do
not shortcut, summarise, or re-ask: everything the skill's chain asks is
the product interview, and everything it settles is settled. When its
pause-3 hand-back arrives, continue here.

**Technical foundation** — design direction, architecture, stack — is
init's channel and never the skill's (that verb asks product questions
only). It is asked in step 1b, after the PRD is ratified.

**Adoption — a PRD ratified before init.** If the directory already holds
a `PRD.md` in the enriched grammar (a ```vid-prd block) whose
`## Ratifications` section carries a `final` line — a standalone
/vid create-prd run, the file carrying its seed, ledger, contract,
findings, and ratification shas — adopt it instead of delegating:

- run `sh ${CLAUDE_PLUGIN_ROOT}/checks/prd.sh PRD.md`; a conviction stops
  init naming the gaps — the owner repairs by append or re-runs the verb;
  init never edits a ratified base;
- `git init` if the directory is not a repository, and commit the file
  as it is, with `.gitattributes` beside it and, when its header carries a
  `Seed:` line, the SEED.md it names, taken from beside the PRD and
  committed with it unchanged (0.26.10.29.3, R9) — summary "adopt PRD.md ratified by /vid create-prd", body
  naming the court result and the three Ratifications lines verbatim
  (their shas name the standalone repository's commits; they are carried,
  not resolved here — the receiving repo's first commit of the file
  re-anchors the law); a file already committed here (the standalone run
  happened in place) needs no new commit;
- skip delegation entirely, and **never re-interview what the document
  settles**: its ledger, thesis, contract, and items are ratified.
  Product questions init hits later go to the owner freely as always and
  land as typed-row appends. A ratified PRD carries no Test Inventory
  (vid-create-prd writes none), so step 4 derives it here, as for a PRD
  init authored.

A pre-enrichment `PRD.md` (no ```vid-prd block) is not adoptable: it is a
document the owner can hand to the skill through its import door (seed
role) — say so, then delegate.

## 1b. Technical foundation — init's own channel

With the PRD ratified or adopted, ask the technical-foundation questions —
the two optional hint questions below are the whole list. Where the
owner skips one or says "you pick", choose a sensible default and log it
with `| origin: proposal` in DECISIONS.md when that file is generated in
step 2.

Always ask the two optional hint questions, verbatim:

1. **"Any directional hints on design?"** — prose is recorded verbatim in
   BASELINE.md's Owner hints. An ask for a real design pass → run
   /vid design (see the vid-design skill) after the artifacts exist: it
   derives the brief with its manifest, the owner authors, and the import
   court reconciles what comes back. /vid design asks whether you design
   from its brief in your own tool or ViD drafts it here; it only offers the
   second when it can see its own drawings. Promise nothing beyond that.
2. **"Any directional hints on architecture and technical stack?"** — accept
   ANY altitude, from "it's a website" or "it's a mobile app" to a full stack
   prescription. Record what is said verbatim in BASELINE.md's Owner
   hints section, with the hosting answers taken out (where it runs, the
   addresses, the access, the accounts, the spend cap: they go to
   `vid-staging-setup` Part 1's block, below, never into the hints;
   0.26.10.29.3, R9). Skipped → you choose the stack and log it
   (`origin: proposal`). When you choose: convention-heavy frameworks are a
   **scaling decision, not a taste preference** — hand-rolled framework
   equivalents cost several times the lines per requirement that framework
   leverage does. Say so when recommending.

**Where it runs (v0.26.10.8 R4).** With hint 2, for every project, invoke
the `vid-staging-setup` skill's Part 1 (the Skill tool): where the product
runs, the staging and production addresses, the sending address, the
spend cap, how ViD gets access (a log-in or a variable's name, never a
value), the outside services' accounts and which go live on staging, and
the downtime tolerance; it checks the platform against BASELINE and writes
its DECISIONS entry. Its answers go only into ARCHITECTURE.md's
```vid-hosting block and DECISIONS, never verbatim into BASELINE's Owner
hints — a hosting answer given inside hint 2 goes there, not into the
hints. They are recorded when ARCHITECTURE.md is generated (step 2).

**The `technical` sitting (0.26.10.29.6, S1, S2).** The hints and Part 1's
questions are one pause. Where `.vid/` exists, before you ask:
1. write it: `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write technical <file>`,
   the file holding, in `face.sh`'s line form (its head), `section hints`
   with the two hint questions as items (no `choice` and no `recommend`
   line: their buttons are fixed), then Part 1's two sections, `section
   where` and `section access` (vid-staging-setup, Part 1, "The sitting's
   lines");
2. give the owner what the script printed about pages first: the link, or
   the file's path;
3. ask in the chat as above, in the sitting's order, whether or not a
   panel is there.

A refused line is rewritten and the call made again. When the script
names a line that holds an id or one of ViD's own words, rewrite that
line in plain words and write again before you ask. Once the answers are
recorded: `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end technical`. Then
ask the monthly spend cap in the chat, on its own: a face shows no amount
of money. An answer the owner types in the chat answers the items it
names, one by one, as a send from the panel does.

**A technical choice the owner asks about (0.26.10.29.6, S7)** is given
as: what each option means for the product; its effort, small, medium or
large, said to be an estimate; ViD's recommendation; and what would
change it. Product names come second, never first. If your
recommendation changes between two answers, say what changed. One
question settles one thing: when answering it would change something
else (a rule, a name used elsewhere), that is a second question, asked
after the first.

**Scale warning (state it when it applies, never refuse).** Only for a PRD
under a grammar before 0.9.4, whose pause 2 did not size it: past ~2 grader
batches (~60 demand items — the court's `demand=` count), say plainly that
cross-cutting ownership degrades first at this size.

Product questions stay free and immediate at every later step — the
skill's batch was for critical mass, not a quota; an answer that arrives
later lands as a typed-row append under `## Appends`.

## 2. Generate the artifacts

Fill every template; no placeholder survives. Specifics that matter:

- **PRD.md** — RECEIVED, never generated here: the artifact of step 1
  (delegated or adopted), already in the enriched grammar — stable REQ
  ids, one `fail-if:` per demand item, tiers, typed non-goals (`NG-`
  rows), the ratified content contract, the answer ledger, and open
  decisions as `VID-QUESTION: (OQ-n)` carriers (they block "done" —
  checks/coverage.sh counts them; resolving one rewrites its line
  `RESOLVED: (OQ-n) A-NNN — …` in the same commit as the answer and the
  amendment). Init adds nothing to the base and
  edits nothing above `## Appends`; a product decision init makes later
  (a design read-back, a lifecycle ruling at ratification 3) lands as a
  typed row append in the fix/add grammar. Write the rulings as an edits file and apply it with `sh "${CLAUDE_PLUGIN_ROOT}/checks/prd-apply.sh" PRD.md <file>`; never edit the machine blocks by hand or with a script of your own.
- **BASELINE.md** — stack table where FORBIDDEN alternatives are NAMED (the
  plausible things a future session might reach for instead: the competing
  framework, ORM, database — not vague categories). Tier-0 rows matching
  every T0 item — demand rows and `invariant` rows alike. Machine blocks:
  - `vid-allowed-extensions`: every extension the scaffold legitimately uses,
    including `.md .yml .sh` and the config formats (`.toml`/`.json`/`.lock` as
    applicable) — the spec commit itself must pass conformance.
  - `vid-forbidden`: dependency/import tokens that must never appear in staged
    source additions. Pick tokens that will not legitimately occur otherwise
    (e.g. `sqlalchemy`, not `sql`). The court reads the project's own files,
    never ViD's installed `checks/` (0.26.10.29.3, R7). Never narrow this block
    to get a commit through: a term the project's own files must use is the
    owner's ruling, asked in plain words.
- **DECISIONS.md** — seed with the real decisions made so far: stack choice,
  storage, hosting posture, anything from skipped hints. Every entry carries
  `| enforced:` and a label — `| applies-to: <ids and codes>`, or `| scope:
  project` only when it bears on many areas (both hook-rejected otherwise;
  a line written before the inventory exists is labelled in the labelling
  pass before the spec commit, step 7).
- **ARCHITECTURE.md** — a seam row per initial module, following the
  template's **column contract exactly**. The architecture step also
  enumerates every EXTERNAL boundary — each service on the other side of
  the network (payments, mail, feeds, search, auth, storage) becomes a
  provider seam row in INVENTORY.md at ratification 3, born
  `probe: owed` (§3.2 door 1), naming the module that talks to it
  (`| module: <module id>`). An external boundary without a seam row
  cannot be ratified. Column contract: Module is the repo path, Public
  surface leads with the backticked import specifier, Dependents is the
  comma-separated allow list. This table is executed — checks/imports.sh
  reads it at every commit — so an entry point per module, never one barrel
  for the world. Keep `Import court: enforce` (greenfield projects start
  enforced; report-only is for retrofits). The ```vid-hosting block
  (`vid-staging-setup` Part 1's answers, above) goes in its "Where it runs"
  section — never a credential; the pre-commit hook refuses any access
  shape but `cli-login <platform>`, `env <NAME>` or `none`.
- **CLAUDE.md** — from `templates/CLAUDE.project.md`: 3-line project summary,
  placement prose ("new X goes in Y") plus a `vid-placement` block that
  matches the scaffold exactly.
- **README.md** — what it is, and the go-live sticky note from
  `templates/README.golive.md` verbatim; how to run, how to test (`sh
  checks/test.sh`) and the preview command arrive with the code skeleton
  (vid-skeleton Part 1), since there is no code yet.

## 3. The design chain (when the product has a face)

If the product has a visual surface and the owner wants it designed (the
hint question, or their own ask), run /vid design now — the PRD exists, so
the brief can be derived. That verb owns the whole chain: brief + manifest →
owner authors → `sh checks/design-join.sh` fail-closed reconciliation →
ratification into design/.

**The order (0.26.10.29.4, phase 3 R6).**
- **The brief goes out only from a settled PRD:** after pause 3, and after
  every open PRD review loop has ended (vid-create-prd, "Reviews
  converge"). No brief goes out while an append's review is open.
- **No row is derived from an append whose review has not ended.**
- **While the owner designs in their own tool,** init waits only for the
  parts that need the design, since the inventory's surface rows are the
  join's resolved output. Go on to step 4 and derive every row that does
  not need the design (vid-test-inventory §§1, 2 and 4), so the wait is
  not idle; say once, plainly, what you are waiting for; and hold the
  screen rows, the strength pass (vid-test-inventory §3) and the sitting
  until the pack is imported and `sh checks/design-join.sh` exits clean.
  The sitting waits for the design.
- **A clean join comes first.** A pack's first consistency pass starts
  only once `sh checks/design-join.sh` exits 0, the court run on its own,
  never piped (vid-create-prd, "While a pass runs"). The re-run that lands
  ruled corrections follows the design skill's landing rule (vid-design
  §3, `landed`).
- A design round's PRD append (a read-back, a `design wins` ruling)
  amends the PRD: the rows that cite what it amends are found and
  rewritten by vid-test-inventory §5, "Rows that cite an amended item",
  and read again by the strength pass's next round.

No visual surface, or the owner defers design → skip; the inventory derives
from the PRD and routes alone, and /vid design can run later (its import
reconciliation will then extend the inventory).

## 4. The Test Inventory — ratification 3, then materialisation (delegated to /vid test-inventory)

The Test Inventory is owned by the vid-test-inventory skill
(`${CLAUDE_PLUGIN_ROOT}/skills/vid-test-inventory/SKILL.md`) — the whole
test contract, every test the project will ever have, routed by what can
run it. Run it now, inline, in **init mode, call point 1**: read that
skill and follow it whole — the derivation from the three enumerable
sets and the enumeration joins, the genus deliberation through
fresh-context lenses, the governance rows (rule, difference, exception,
suppression, seam, hostility, the control siblings, the golden sets), the
strength pass (the counterexample-challenge lens) last, after the design
rows, and the ratification sitting — with
the grading checklist created from `templates/GRADING-CHECKLIST.md` in
the same sitting. Do not shortcut, summarise, or re-derive: what that
skill derives is the inventory, and what the owner ratifies there is
ratification 3. A row that would be materialised is written with the
`test` field `owed: spec-only — first stage`; the deploy-gate form and the
legitimate deferral classes keep theirs (that skill's §5, call point 1).
When its hand-back arrives, continue at step 6. **Call point 2 — §6
materialisation, §7 the red gate and proved-red — is no longer init's**
(v0.26.10.9 R3): in develop mode its caller is vid-skeleton Part 3 (skeleton
mode); in ticket mode its §6 runs per ticket, with no red gate of ViD's
own.

What init supplies to the skill, in place: the ratified PRD (step 1), the
resolved design join when a design exists (step 3), the seed library, the
external boundaries the architecture step declared (step 2 — an external
boundary without a seam row cannot be ratified). Route rows the derivation
cannot see before code exists arrive with the routes extractor the code
skeleton generates. Report honestly: the writable rows are `spec-only`,
their tests not written yet — that is the correct state at the end of init.

## 5. The code skeleton — moved (v0.26.10.9 R2)

Not init's. The toolchain and lockfile, the layout, the golden-path example
and its seed test, the harness and the README's preview command are
vid-skeleton Part 1; the generated extractors Part 2; materialisation, the
red gate and the proved-red stamps Part 3 — /vid develop's first step. In
ticket mode the skeleton is the dev team's first ticket (/vid plan).

## 6. Install the enforcement

- copy `${CLAUDE_PLUGIN_ROOT}/checks/` → `./checks/` (both hooks, placement,
  conformance, coverage, imports, inventory, census, seams, design-join,
  design-cite, prd — the enriched-PRD court, presence-gated, green on the
  ratified PRD from step 1 before the spec commit — metrics, watchdog,
  test runner, lawfiles, the event helper `event.sh` and
  `records-version` — the record contract this checks/ writes, the RECORDS.md
  version its `records:` line names (v0.9.5 3.10) — selftest/ with its fixtures: the whole
  directory, verbatim), then
  `chmod +x checks/*.sh checks/hooks/* checks/selftest/run.sh checks/selftest/cases/*.sh`
- `git init` (if needed), then `git config core.hooksPath checks/hooks` —
  pre-commit, commit-msg and post-commit (v0.9.3 3.7: the amendment
  record) are all installed by it; `chmod +x checks/hooks/*`.
- **`.vid/budget`** (v0.9.3 3.10) — numbers only, the defaults unless the
  owner said otherwise: `stacks=1`, `memory-headroom-mb=<n>` (the observer
  reports it), `claims-per-slice=60`, `wall-hours-per-slice=8`,
  `court-seconds=300`, `builder-context-tokens=400000` (v0.9.7.0.7 3.7:
  the context at which a builder or fixer is told, once, to finish) — each line recorded in DECISIONS.md `origin:
  proposal`, with the mark `| about: vid-settings` beside its label (0.26.10.28.5): a decision about ViD's own settings, which no ticket
  quotes. It is not a law path.
- **the observer** (v0.9.3 3.9; v0.9.7.0.9 3.8) — develop starts the
  watcher itself (`sh checks/observe.sh start`, a detached loop tied to the
  run); the owner installs nothing.
- **the project's host settings** (v0.9.7.1 3.8, 3.12) — two plain
  questions, each written only on the owner's yes, into this project's
  `.claude/settings.json` (never the owner's own configuration):
  - may ViD set this project's compaction point to 300,000 tokens, so the
    build's session compacts before its context grows costly?
    (`"autoCompactWindow": 300000`; record `sh checks/event.sh
    'context-window requested=300000'`, or `requested=declined`);
  - `sh checks/brief.sh plugins` names the enabled plugins that are not
    ViD's: may ViD turn them off for this project only, since each one's
    skills reach every session start? (`"enabledPlugins":
    {"<name>@<marketplace>": false}` for each the owner names; a local
    setting or the organisation can still override it). develop's start
    says whether each still reads as enabled.

  **The `settings` sitting (0.26.10.29.6, S1, S2).** These two are asked
  after the test list's hand-back, each on its own: never in a list,
  never covered by a yes to anything else. Where `.vid/` exists, write
  them first: `sh "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" write settings <file>`,
  the file holding `section settings` with two items, the compaction
  point in plain words ("May ViD have this project's sessions shorten
  what they carry once they hold 300,000 tokens, so the build stays
  lean?") and the other plugins (their names as `detail` lines), with no
  `choice` line: their answers are Yes and No, fixed, and every item of
  the section is asked on its own; give the owner what the script printed about
  pages first; then ask the two in the chat, in that order, one message
  each. Once both answers are recorded: `sh
  "${CLAUDE_PLUGIN_ROOT}/checks/face.sh" end settings`.

## 6b. The final review (0.26.10.29.3 phase 2 R4)

After step 6 has written its budget lines and before step 7's labelling
pass, spawn `${CLAUDE_PLUGIN_ROOT}/skills/vid-create-prd/passes/final-review.md`
in `mode: whole`: one fresh pass over the whole spec, with exactly the
inputs its `receives:` line lists — the PRD without its `## Findings`
section, its append sections' findings blocks and its `review:` lines;
the design when there is one; ARCHITECTURE.md, DECISIONS.md, BASELINE.md,
INVENTORY.md and GRADING-CHECKLIST.md. Its rounds, its second reader and
its record follow vid-create-prd: "Reviews converge", "The second
reader" and "While a pass runs" (in "Pass mechanics"), and "The findings
record" — never a rule of this skill's own.
Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.

**ViD repairs what it wrote, the test list included.** Every repair is
read again by the pass's next round in `mode: delta`, so none goes unread:
- **the PRD** (ratified at pause 3): the repairs are one append, carrying
  `review: final, round <r>, 0 findings, see <heading>` — no rows of its
  own, since its review's rows are under the heading it names;
- **INVENTORY.md and GRADING-CHECKLIST.md**: strengthen a row, add a
  missing one, or rewrite words a test cannot measure, by the inventory's
  own rule — new rows continue the id sequence, and every existing row
  keeps its id and its test;
- **ARCHITECTURE.md, DECISIONS.md and BASELINE.md**: init's own drafts.

All of these are still uncommitted: they are edited in the working tree
and land in the spec commit.

**What goes to the owner**, as `needs_owner`, each with ViD's recommended
answer, in the one list vid-create-prd, "Reviews converge", gives the owner: a repair that
would weaken or remove a test row (a row that seems wrong is a product
question); a repair that needs a product decision the record does not
hold; any finding against the design, which is imported as the owner gave
it and changes only through the design door (/vid design).

**The record.** The findings go into PRD.md under a dated `## Findings`
heading, `### <date> — final review`, holding one line `review: final,
round <r>, <n> findings, read: <files>` — `<r>` the round the review ended
on, `<n>` the rows of that heading's one ```vid-prd-findings block (every
round's rows and both readers', merged; pass `final`), `read:` the
documents the pass read (for example `read: PRD.md DESIGN-BRIEF.md design/
ARCHITECTURE.md DECISIONS.md BASELINE.md INVENTORY.md GRADING-CHECKLIST.md`).
The heading lands in the spec commit: pre-commit refuses a commit that
adds INVENTORY.md beside an enriched PRD (one holding a
```vid-prd-answers block) with no new `review: final` line. The labelling
pass then labels every decision line, the repaired ones included; labels
classify a line and change no content, so they are not read again.

## 7. The labelling pass and the spec commit (v0.26.10.9 R1)

The labelling pass (v0.9.7.3 3.3, R3) over every decision line — step 2's
and the later steps' (step 6's budget lines included) — immediately before
the spec commit, from `./checks/`: `sh checks/decisions.sh propose --all`
writes `.vid/briefs/labels-<n>.md`; one general-purpose agent reads it and
returns one line per decision, editing nothing; save the return as
`.vid/decision-labels.proposed`; then
`sh checks/decisions.sh apply --no-commit` — no question to the owner (an unsure label is written `scope:
project`), no commit of its own, the labels land in the spec commit, where
the hook's label rule sees a fully labelled file.

**The spec commit** is the former initial commit without code: the
technical foundation's artifacts, INVENTORY.md and GRADING-CHECKLIST.md,
the design when there is one, PRD.md with step 6b's final review (its
findings heading and its repair append), `checks/`, and `.gitattributes` when no
earlier commit carries it (0.26.10.28.1, R4), under `VID_ROLE=fix` and the
template message:

    VID_ROLE=fix git commit -m "..."

It installs `checks/`, so the hook's exemption (it skips the standalone
rule while HEAD carries no `checks/`) applies to it exactly as it applied to
the initial commit, and to no later commit; the presence-gated courts,
prd.sh included, run on it. No red gate and no proved-red stamp here: no
test is written yet.

## 7b. The stage cut (v0.26.10.5 R1, R2)

After the spec commit and before the hand-back, run the vid-stage
skill (`${CLAUDE_PLUGIN_ROOT}/skills/vid-stage/SKILL.md`) inline: it reads
the whole baseline, proposes a cut through its five lenses and presents
one card per stage in one sitting — the owner's last pause at init. The
owner ratifies the cut, changes it, or keeps a single stage (no
STAGES.md). With two or more stages, init's run of vid-stage then runs
the final review once more, after STAGES.md is committed (vid-stage,
"After init's cut, the final review"); with one stage there is no second
run. Its hand-back's lines join step 8's.

## 8. Hand back

A few sentences, no ceremony, saying honestly what exists and what doesn't
(RL-5): what was ratified, what was decided (call out every `origin:
proposal` default), where the artifacts live, and, in these words: "the
spec is ratified; there is no code, no test harness and no written test
yet."

**Its numbers (0.26.10.29.6, S7).** Every number in it is copied from a
script's output printed in this turn: run each script below here, on its
own, and give its counts as it prints them. A count no script prints in
this turn is left out, never restated from an earlier turn (an earlier
hand-back's genus proposals per lens, its proposed Fail-if amendments):
- the PRD: `sh checks/prd.sh --report PRD.md` — its counts, items by type
  among them, and the open questions as its `open-OQs=` field, never a
  number or "none" of your own (0.26.10.29.3 R4);
- the test list: `sh checks/inventory.sh --report` — the counts of its
  `inventory:` line (the rows, the owed ones, the hostility set and the
  Tier-0 count as two numbers);
- the stages: `sh checks/stages.sh counts` — one line a stage, or "one
  stage" when there is no STAGES.md. A stage's count is every test of
  that stage, of every kind, called "tests", never set beside the test
  list's row count as if they were one;
- the design, when there is one, named, with no count.

Say which count a number is whenever two could be meant.

Then the next step, by what the owner wants to happen (0.26.10.29.6, S8),
in these words:
- "To have ViD's own agents build it on this machine, say `/vid develop`."
- "To build it through GitHub tickets, by ViD's agents or by your
  developers, say `/vid plan`."

Never "setup done". Then record
`sh checks/event.sh "stage name=init state=end made=spec session=$CLAUDE_CODE_SESSION_ID"`.
