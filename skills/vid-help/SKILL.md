---
name: vid-help
description: Show the installed ViD version and a one-line description of every verb. Read-only, changes nothing, asks nothing. Use when the owner says "vid help", asks what ViD can do, which verbs exist, or which version is installed.
---

# /vid help

The help card. Read-only: it changes nothing, commits nothing, asks the
owner nothing.

## Version — read it, never recall it

Report the version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
at the moment of asking — that is the installed plugin's version, which is
the one that matters (a repo checkout elsewhere may be newer). Never state
a version from memory.

## The verbs — present this table

| Verb | One line |
|---|---|
| **/vid init** | Once, in an empty directory: the authority phase, and it makes the spec only — product elicitation through create-prd (run inline, or a ratified PRD adopted), then the technical-foundation questions, where the product runs and how ViD gets access among them; design chain when the product has a face; Test Inventory ratified (its tests written later); courts, the spec commit, the stage cut. No code yet: /vid develop builds the code skeleton as its first step, or /vid plan sends it to a dev team as their first ticket. |
| **/vid create-prd** | Author the PRD: materiality-tested interview, owner-ratified content contract, typed items under the falsifier mandate, three ratification commits, court-grammared and portable. Init runs it inline as its first act; standalone in any directory, the result is adopted by a later init. Creation only — appends belong to fix and add. |
| **/vid test-inventory** | Own the Test Inventory — the whole test contract, every test the project will ever have, routed by what can run it: derived by enumeration joins from the PRD, the design join and the route table; genus deliberated by fresh-context lenses; challenged by a counterexample lens; ratified as rows at recognition speed; materialised red behind the red gate. Init runs it inline, add and design's standalone round call its append mode; standalone it re-derives after appends or a consolidation and presents the row-set diff. Never runs verification. |
| **/vid design** | Turn an owner-approved design into the visual half of the spec: brief + manifest derived from the PRD, then — once it has proven it can see its own drawings — it asks who makes the design: you in your own tool from the brief (recommended) or ViD here; canvases+tokens come back, the design-join court reconciles fail-closed, ratify — protected, marker-cited, token-fenced, fidelity-graded. |
| **/vid stage** | Cut the product into stages you ratify in one sitting — outcome, technical order, constraints, risk; a ladder from the finest cut whose stages are each usable and safe to release to a single stage, with counts; you pick a rung. Init runs it at its end, offering a technical stage 0 (a thin working skeleton, put on staging for real, never released) and asking once whether ViD may set up the test site and put each finished stage on it on its own; on request it re-cuts. Each closed stage can go to staging, and live if you say so. |
| **/vid develop** | Make the ledger green: build the entire PRD end to end, no approvals, ledger green at every commit, inventory and import courts at every commit; product questions come to the owner immediately, technical ones are decided and logged. Auto-grades at completion. |
| **/vid plan** | Ticket mode: send the plan to an outside dev team as GitHub tickets — a milestone per stage, an issue per step, tickets for the ready steps, the code skeleton first — after you approve the plan page. ViD's repository keeps the spec, the plan and the records; the code repository gets only issues, milestones, labels and comments. Never pushes, merges or deploys. |
| **/vid replan** | Ticket mode, run when asked (daily, or for a blocked ticket): read what the dev team returned — merged pull requests, their return blocks and CI results, drafts with questions — check ViD's tests are unchanged, grade the merged rows, route discoveries and questions to named answerers, close a stage from the dev team's CI run on main, publish the next tickets with their tests; a report page each round. |
| **/vid ticket-implement** | For a ticket-mode trial: the dev side's stand-in worker, in its own conversation and clone — claims a ready ticket, one fresh agent per ticket with only the ticket, opens the pull request (or a draft with its question). Never merges or touches ViD's repository. |
| **/vid ticket-approve** | For a ticket-mode trial: the dev side's stand-in reviewer — checks each pull request (CI green, the ticket's tests unchanged, paths inside the step, the return block), then merges at the reviewed head or sends it back. Never grades. |
| **/vid grade** | Read-only adversarial review by fresh-context graders against each REQ's Fail-if; exit bar + convergence stop rule for loops, --visual fidelity mode, court-edit sweep; ranked findings table + dated report under .vid/grades/. Always safe to run, any repo. |
| **/vid fix** | Targeted apply only: owner corrections or the accepted rows of a grade report → spec append + ledger test + fix in one commit, then a blast-radius re-grade (changed modules + declared dependents). Never sweeps. |
| **/vid add** | A feature after the fact: mini-interview → PRD appends → inventory delta → develop as it is → one grade, scoped to the add → adjudicate/fix. |
| **/vid deploy** | Two targets. **Deploy to staging** (a bare deploy): the rows changed since the last full pass on a scoped run, then one real action per provider seam — fast, repeatable. **Deploy to production**: staging's exact commit, the full run, the re-grade, a local rehearsal on a restored prod backup, owner-confirmed cutover. The only verb that touches anything real; never runs implicitly, except a staging deploy at a stage close, or at "continue" while staging is being set up, under your standing staging authorization. |
| **/vid view** | The project viewer: self-contained HTML snapshots of the project — now, and one for each milestone not yet made — read from git and ViD's records, one file each that opens offline by double-click, with an index. Read-only; writes only into its own folder outside the project; runs only when asked. |
| **/vid help** | This card. |

Close with the working sequence, one line: init (once; create-prd runs
inside it, or standalone before it; test-inventory runs inside it, and
on demand after any PRD append) → design (when the product has a
face) → develop (stage by stage, when the product is cut into stages) →
grade → fix → deploy; add re-enters the loop; stage re-cuts. In ticket mode: init → stage → plan → replan, round after round, while a dev team builds (the ticket-implement and ticket-approve stand-ins in a trial); a "stage" is a slice of the product, "staging" the test site — never the same thing. And the composition rule: grade discovers, the owner adjudicates,
fix applies — the owner is the pipeline between them.

## Law for maintainers

This table is release material: any commit that adds, removes, or
meaningfully changes a verb updates this table in the same commit.
