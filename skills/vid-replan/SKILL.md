---
name: vid-replan
description: Re-planning in ticket mode, in both GitHub modes, by the same rules read where they stand, one paragraph per mode where GM's rulings make them differ — in GitHub auto the run manager changes the plan itself (`plan.sh change`) when a line calls for it; in GitHub manual the re-plan analysis, the `/vid next planning-analysis` move (what it covers, the candidate plan, the review of the rows ViD adds, the check, the proposal and its page), which records and posts nothing until the owner's `implement-replan`. Invoked by /vid run's re-plan step and /vid next's moves; the owner's command `/vid:vid-replan` in both modes. Use when the owner says "vid replan" or asks for a re-plan.
---

# /vid:vid-replan

Re-planning's order, nothing more: every check is a script's (`checks/plan.sh`, `checks/planner.sh`, `checks/replan.sh`, each
header says each), and each refusal is printed by it.

**Reading order, when you plan:** CLAUDE.md, the PRD with its appends, BASELINE, ARCHITECTURE, DECISIONS, the design, INVENTORY.md, STAGES.md.

**Called by the owner** as `/vid:vid-replan`, in either GitHub mode: inside /vid run's own conversation it uses the run's lock and
leaves it held; anywhere else the vid-connect skill's start first and its end after, however the call ends (GM-4 S0); while
another session holds the lock, the start says so, and nothing is done. In GitHub auto it is a re-plan by the run manager at the
owner's word, by GitHub auto's paragraph below, `--trigger owner-answer`, the owner's words its why; in GitHub manual it is the
analysis and its page, with the kinds, subjects and `without …` the owner names.

## The rules, in both modes

**The rules every change is made by** (0.26.10.29.2, R5), for every change after the first plan as for the first, read where they stand and never copied: develop's planning paragraph, skills/vid-develop/SKILL.md § "Plan, decompose, and sequence the PRD", as skills/vid-plan/SKILL.md adapts it (the cost lines of `queue.sh cost` in place of `build-cost`); the side-by-side sentence of skills/vid-develop/SKILL.md § "The plan is a record", whenever a change admits steps to run at once; and the pull-forward rule, skills/vid-develop/SKILL.md § "The pull-forward rule", recorded with `--trigger discovered-dependency` and `sh checks/event.sh 'pull-forward step=<id> decision=<D-id>'`. Where that rule asks the owner, ask while the run goes on, as a draft through the door: an addition to the stage is a draft you make through the vid-fix skill's ticket-mode branch; a re-cut is the owner's own `/vid stage`, which you ask them for in one plain line. Never wait on the owner for a pull-forward while other work is admissible.

## GitHub auto

The run manager re-plans itself, in /vid run (GM M10 holds for GitHub manual alone; here every change is a recorded plan change).

**Re-plan** when a line calls for it, the vid-triggers skill's or the round's: a row failing again and again, a step much bigger than planned, a dependency DevAgent names or a merge shows, an owner's answer, a ticket refused or held, an admission refused. A re-plan is `sh checks/plan.sh change <what> '<why>' --trigger <trigger> --evidence <evidence> --expect '<what should follow>'`, with the stage still `run`. Its evidence is in the forms plan.sh has: `ticket:`, `step:`, `refusal:`, `commit:`, `question:Q<n>`. When nothing changes, record nothing. In the run (0.26.10.29.2, R1), `change` holds the candidate to ticket mode's plan rules, `planner.sh check`, before it records it, counting the change's own raise (`other` with `unverified-rows=<n>` in its why), and refuses only on a flag the change adds over the newest recorded plan's: the refusal prints each added flag, `<kind> <id> — <why>`, keeps the decision `result=refused` and leaves the plan as it was. Change the block to clear those flags (split a step over the ceiling, or raise it; keep every planned row in a step) and run `change` again. A change that leaves a started step's row in no step (a known limit, later-phase row or record apart) is refused this way. A block only re-spaced, or a step's rows only re-ordered, still reads as ratified: record nothing for it. A raise stands through every merge whose report declares the same number of test environments; a different number measures the ceiling again, 60 a test environment, so a raise still needed is recorded again (R10). A step built on counts as closed only while every row it holds is accepted, ruled, owed, paid, held or a known limit (R9): rows it gained, rows a landing reset and rows a C3 marked failing hold its dependents until they settle, and the admission's refusal names them. Your cost signals are `sh checks/queue.sh cost [<step>]`, a line a ticket: a `cost` change cites the step it read, `--evidence step:<step>` (v0.26.10.26.3).

**Breadth first** (v0.26.10.26.3) is the owner's choice alone. On their words, and only then: `sh checks/plan.sh strategy breadth-first --by owner --words "<their words>"`; a switch back, `strategy depth-first`, is always allowed. Under it, hardening steps come after every feature step in the plan, so the round reaches one only when no feature step before it is admissible and a slot is free. A deferral is `sh checks/plan.sh change edge` moving a failing edge row out of a feature step's open ticket, which the writer then amends; its decision is the record. A row failing or held on a weak test is never moved: its test is fixed where it stands.

The round's lines that are re-planning's:

| Line | What you do |
|---|---|
| `plan-stage <N>` | Stage N-1's candidate is named and stage N holds no step yet: plan it in detail as a recorded change, `sh checks/plan.sh change …` with the trigger `initial` and the evidence `step:<a step of stage N-1>`. Never wait for the owner's production decision |
| `plan-refused <step>: <why>` | The fix's plan change was refused: record it by hand, `sh checks/plan.sh change other …` with the trigger `test-evidence` |
| `refused <what>: <why>` | Re-plan, or tell the owner, and go on |

## GitHub manual

GM-3 U4: the re-plan is a proposal, and nothing reaches the team until the owner's words to `implement-replan` (GM M3, M10). The
analysis, the `/vid next planning-analysis` move, records and posts nothing: it writes only `.vid/next/proposal/` and its page.
The move is `planning-analysis`, then each kind, subject or `without …` the owner names, one argument each, the last move named;
run it with those arguments, as the owner named them: `[<kind> [<subject>]]… [without #<n> <id> | without <step>]…`.

**GM M10's rules 1 to 6**, each read where it stands, never copied here:

1. **Every test in exactly one step, every step in one stage:** `replan.sh check`'s `rule-1` lines, from `planner.sh check`.
2. **A published ticket is only topped up; nothing is taken from it or withdrawn without the owner saying so:** its `rule-2`
   lines, and its `size` and `builds` warnings, which are never refusals. A withdrawal is the `withdraw` move, in the owner's words.
3. **Steps not yet published are split, merged or changed freely:** by develop's planning paragraph, above, with the rows' needs
   and the step size as `skills/vid-plan/SKILL.md` § "The plan" gives them.
4. **No test changes stage but by the owner's re-cut, through the door (`/vid stage`):** its `rule-4` lines.
5. **The team's placements come in as moves:** `team-change` (the vid-answer skill's), and the team's additions that only
   the pending spec holds through this analysis, into their tickets by default (`scope`'s `team-in` lines).
6. **Everything to the team through the apply move, each change with its trigger, evidence and expected effect:** its `rule-6`
   lines, in the forms `plan.sh change` takes.

The order:

1. **What it covers.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/replan.sh" scope <the move's arguments>`. Its lines are the
   analysis's whole input: the pending changes, the rows a re-cut moved, the to-place list, the team's additions it takes in
   or leaves out, the triggers it covers, the open published tickets with their tests, and whether a review is needed. A
   refusal is said in plain words and the move stops there.
2. **The candidate.** Write it in `.vid/next/candidate/`, replaced whole, in the forms `replan.sh`'s header gives (`block`,
   `PLAN.md` only when the candidate needs it, `changes`, `left`), from the plan as ratified (RUN-STATE's plan block) at
   HEAD's spec, by the rules above, each pending and to-place row placed or left in no step with why.
3. **The review.** Invoke the `vid-row-review` skill when step 1 said `review needed`, with the rows `sh checks/planner.sh
   rows --added --at HEAD` prints, its output saved as `.vid/next/candidate/review`. With `review none`, there is nothing to
   review.
4. **The analysis.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/replan.sh" analyse <the move's arguments>`. On exit 1, each line it
   printed names a breach or a gap: correct the candidate, never a rule, and run it again. On exit 0, tell the owner in plain
   words what `.vid/pages/REPLAN-PAGE.html` shows: each ticket's top-ups, the new or split steps and which the apply
   publishes, what moves, the warnings, what it leaves alone and why, and the review's findings, counts only, never a score.
   Say that nothing is recorded or posted, and that `/vid next implement-replan "<their words>"` applies it as shown,
   their words also their words past each warning and for each finding shown.

**The apply,** the move `implement-replan "<words>"`, then `--review "<file>"` when its line says the rows ViD's planner adds
need a fresh agent's review: that review made first by the `vid-row-review` skill and saved as the file. `replan.sh apply` posts
through the vid-tickets skill's one path, and, with `layout: one`, the spec into the folder first (the vid-spec-publish skill's
entry); its lines are said as it prints them.
