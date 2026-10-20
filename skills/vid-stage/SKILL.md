---
name: vid-stage
description: Cut a ViD project into stages the owner ratifies in one sitting — through four lenses (outcome, technical order, constraints, risk) it builds the finest cut whose every stage is usable, safe to release, buildable, protected and whole, then coarser rungs by merging neighbours, shown as one ladder with counts, the recommended rung's plain-language cards and the open product choices; the ratified cut is STAGES.md, a law file, or no file at all when the owner keeps a single stage. vid-init runs it at its end, after the inventory is materialised and proved red; it also runs on request for a re-cut. Use when the owner says "vid stage", wants the product delivered in stages, or wants the cut changed.
---

# /vid stage

A product large enough is delivered in stages: each built stage is
closed, tagged and can go to staging, and at each close the owner decides
whether to go live or carry on (vid-develop, vid-deploy). This skill
proposes the cut and records what the owner ratifies. It changes no
requirement, no row and no line of the PRD's grammar: `phase: pilot |
later` keeps its meaning, and stages 1 to N together are the pilot.

**Stage events (RECORDS.md).** Record `sh checks/event.sh "stage
name=stage state=start session=$CLAUDE_CODE_SESSION_ID records=25"` when
this skill starts and `sh checks/event.sh "stage name=stage state=end
session=$CLAUDE_CODE_SESSION_ID"` when it hands back.

## When

- **At the end of init** — vid-init calls it after the inventory is
  materialised and proved red, before its hand-back, so it sees the whole
  baseline.
- **On request** (`/vid stage`) — a re-cut. Stages already closed (a
  `stage-closed … ready` event) are shown as they stand; the re-cut is of
  the stages not yet closed.

## What it reads

- `PRD.md`: goals, actors, journeys, features, requirements, the owner's
  answers, every `phase: later`;
- `ARCHITECTURE.md`: modules, owned data, outside services;
- `INVENTORY.md`: rows, journeys, rule rows, hostility rows, seams;
- `BASELINE.md` and `DECISIONS.md`: stack limits, settled choices;
- the design brief and the route extractor, when present;
- `DEPLOYMENT.md`, when present;
- `.vid/RUN-STATE.md`, on a re-cut (`stage:` is the stage being built).

The stage court is 0.26.10.5's (`checks/records-version` 25): a project
whose checks/ is older is refreshed first, as develop's version check
says. `sh checks/prd.sh --effective` gives the effective items; `sh
checks/stages.sh scope --upto N --reqs` and `sh checks/stages.sh stage-of
<id>` read a cut back exactly as every court will.

## The four lenses

| Lens | The question | Whose |
|---|---|---|
| **Outcome** | Who can do what at the end of this stage, and what will being live teach? | The owner's |
| **Technical** | Which modules, data and services does it need? Is the order buildable? | ViD's |
| **Constraints** | Deadlines, budget, providers, what must not be live early | Stated by the owner; applied by ViD |
| **Risk** | Which assumptions hurt most if wrong? The smallest probe for each, and the stage it goes in | ViD proposes; the owner sees it |

## The steps

1. **Sort what is decided:** the owner's commitments, ViD's technical
   decisions, open assumptions. Keep every `later` the owner deferred —
   a later item has no stage.
2. **Outcome candidates:** for each plausible first outcome, the smallest
   usable journey, with its failure handling and its protections.
3. **Feasibility:** map each candidate to modules, data, services and
   contracts. Record each prerequisite with its source (a requirement, a
   module, a seam) and mark it product or technical. Not every link is a
   prerequisite: architecture's "may be used by" is a permission, and an
   invariant's `spans:` is an interaction — neither is an ordering edge
   on its own.
4. **Compare feasible orders** by outcome, constraints, the cost of
   waiting, integration risk and reversibility. Place the risk probes.
5. **Challenge each boundary:** does the stage work with every later
   capability absent? Was a shared protection — a must-never-break rule —
   postponed by accident? (Rules hold for the whole code from the first
   stage: a rule row is stage 1 unless a `row:` line places it later.)
   What would make this cut wrong?
6. **Present the ladder (amendment 1, R1a):** the finest cut, the
   coarser rungs made from it, the recommended rung, and the product
   choices left open (below).

Whole features by default; a feature is split only when an outcome needs
it, and the card then shows the exact requirements that go where. Two
usable stages may sit inside one feature: the feature's first stage lists
it, `split:` lines move the later requirements, and a stage whose content
comes only from `split:` lines lists no feature (`features: -`). Each
feature is still placed once.

## The ladder (amendment 1, R1a)

The owner favours smaller releases. Offer the finest cut that makes
sense, then coarser versions of it, and let the owner pick.

**The finest cut** is the most stages you can find in which every stage
meets all five constraints:
1. **Usable:** it gives someone a result they can use, not a technical
   layer.
2. **Safe to release:** it holds nothing that must not go live without a
   later stage — a public listing without takedowns, accounts without
   deletion, paid placement without the partner's reporting.
3. **Buildable:** it needs only earlier stages (the court's `needs:` rule).
4. **Protected:** it carries the must-never-break rules from the first
   stage they touch.
5. **Whole:** what can't be separated stays together.

On the card where a constraint stopped a finer split, name it, so the
owner sees why the cut is not finer.

**Coarser rungs** are made only by merging neighbouring stages of the
finest cut, which keeps the five constraints and the court's rules. At
most four rungs: the finest; one or two in between, merging at the cut
lines whose separation buys the least; and a single stage. A merge
renumbers the stages in `row:` and `split:` lines and drops the `row:`
lines and `split:` entries it makes redundant. On a re-cut a merge never takes in a stage already
closed or deployed.

**Each rung is tried before it is shown.** Write it into a scratch copy
outside the repository — PRD.md, INVENTORY.md, `checks/` and the
candidate STAGES.md — and there run `sh checks/stages.sh check` (it must
pass) and `sh checks/stages.sh counts`: per stage its requirements (REQ
ids: `scope --upto k --reqs` minus the same at k-1) and rows (`scope
--upto k` minus `--upto k-1`), and the rung's `row-lines` — the rows
placed by hand, judgement included. The project's own STAGES.md is never
overwritten by a candidate. Counts come from there, never estimated.

**One table, one decision.** The sitting's main question is the ladder,
shown as one table: each rung, its stages, the counts per stage, its
placed-row count, and what actually differs from the finest — fewer
stage closes and deploys, a later or bigger first release, a risk tested
later — or "unchanged" where nothing differs; claim no difference it
doesn't have. Recommend the finest rung unless one of its stages is too
small to be worth its own close and deploy, and then say so on that card.
Cards are drawn for the recommended rung only, and again for the rung the
owner picks.

## The sitting — one, at the end

The owner sees the ladder and the recommended rung's cards and, in one
sitting, picks a rung, adjusts one, or keeps a single stage (the top
rung). The picked rung's cards are drawn and shown. Each card has:

- the outcome and who it is for;
- what is in and what is out;
- the features — whole by default; a split feature shows its exact
  requirements;
- the prerequisites, with their sources;
- the constraints;
- the risks and their probes;
- why this order;
- what proves it done;
- what to watch once live;
- the effort, S/M/L, labelled an estimate;
- counts: requirements, rows, journeys, new outside services.

Stage 1's card names its **walking skeleton**: one thin journey through
the main modules and services, built first in stage 1.

**Plain language.** No ids in what the owner reads unless the owner asks
— a feature by its name, a requirement by what it lets someone do.
Counts only; no scores, no percentages.

## What it writes

1. **The owner's answer** as one human row in an appended
   ```vid-prd-answers block — `A-NNN | human | <date> | Q: how should the
   product be delivered — in which stages? | A: <the cut as ratified, in
   the owner's words — the rung picked, or "one stage"> | settles:
   contract` — committed on
   its own with ViD's decisions behind the cut in DECISIONS.md (each
   labelled, as every decision is).
2. **A single stage:** no `STAGES.md`; record `sh checks/event.sh
   'stage-cut n=1 answer=A-NNN'` and hand back.
3. **Two or more stages:** `STAGES.md` at the root from
   `${CLAUDE_PLUGIN_ROOT}/templates/STAGES.md` — the cards, and the
   ```vid-stages block (one `STAGE-N | <name> | features: FEAT-…` line per
   stage; `split:` lines for a split feature's requirements; `row:` lines
   placing a row whose requirements span stages, or a rule row placed
   later; `needs:` lines, each with its source). No placeholder survives.
   Run `sh checks/stages.sh` and resolve every refusal before committing:
   a row spanning stages is placed explicitly, never pushed to the latest
   stage automatically (often the later stage is right — say why), and no
   requirement's only rows may sit in a later stage than the requirement:
   split the row, bring its prerequisite forward, or move the requirement
   itself with a `split:` line. Commit STAGES.md alone — it is a law commit — with the
   answer cited in the message (`Stages: A-NNN`): commit-msg refuses a
   membership change without one. Then record `sh checks/event.sh
   'stage-cut n=<stages> answer=A-NNN blob=<git rev-parse HEAD:STAGES.md>'`.

A re-cut writes the same way: a new answer, the STAGES.md change as its
own law commit citing it, a new `stage-cut`. Deleting STAGES.md (back to
one stage) is a membership change too.

## Hand back

One line per stage — its name, its outcome, its counts — and that
`/vid develop` builds stage 1 first (or, on a re-cut, carries on with
the current stage).
