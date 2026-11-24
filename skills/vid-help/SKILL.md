---
name: vid-help
description: Show the installed ViD version and a one-line description of every verb. Read-only, changes nothing, asks nothing. Use when the owner types /vid:vid-help, asks what ViD can do, which verbs exist, or which version is installed.
---

# /vid:vid-help

The help card. Read-only: it changes nothing, commits nothing, asks the
owner nothing.

## Version — read it, never recall it

Report the version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
at the moment of asking — that is the installed plugin's version, which is
the one that matters (a repo checkout elsewhere may be newer). Never state
a version from memory.

## The three ways to work — present these first

- **local auto** — ViD builds the whole product itself, on this machine, with no dev team: `/vid:vid-init`, then `/vid:vid-develop`.
- **GitHub auto** — ViD builds your product through GitHub, with no outside team: each piece of work a ticket and a pull request you can read, nothing merged without ViD's acceptance, ViD's own DevAgent building it, started by you: `/vid:vid-init`, then `/vid:vid-plan` and `/vid:vid-run`, which prints the job note and two ways to start DevAgent: first, in a new Claude Code conversation in its work folder, `/vid:vid-devagent <job note>`, which shows each piece of its work as it ends; or in the background, `sh <plugin>/devagent/dev-manager/dm.sh up <job note>` (devagent/README.md).
- **GitHub manual** — ViD writes GitHub tickets for a team of people, who build, test and merge them by hand, and you make each of ViD's calls yourself: `/vid:vid-init`, then `/vid:vid-plan`, `/vid:vid-mode manual`, and at each call `/vid:vid-next`.

The two GitHub modes are ticket mode, the mechanism the plan and run rows below name.

## The verbs — present this table

Each verb is typed as Claude Code shows it, `/vid:vid-<verb>` (v0.26.10.26.7): the plugin is `vid`, and each verb is one of its skills.

| Verb | One line |
|---|---|
| **/vid:vid-init** | Once, in an empty directory: the authority phase, and it makes the spec only — product elicitation through create-prd (run inline, or a ratified PRD adopted), then the technical-foundation questions, where the product runs and how ViD gets access among them; design chain when the product has a face; Test Inventory ratified (its tests written later); courts, the spec commit, the stage cut. No code yet: /vid:vid-develop builds the code skeleton as its first step, or /vid:vid-plan sends it to a dev team as their first ticket. |
| **/vid:vid-create-prd** | Author the PRD: materiality-tested interview, owner-ratified content contract, typed items under the falsifier mandate, three ratification commits, court-grammared and portable. Init runs it inline as its first act; standalone in any directory, the result is adopted by a later init. Creation only — appends belong to fix and add. |
| **/vid:vid-test-inventory** | Own the Test Inventory — the whole test contract, every test the project will ever have, routed by what can run it: derived by enumeration joins from the PRD, the design join and the route table; genus deliberated by fresh-context lenses; challenged by a counterexample lens; ratified as rows at recognition speed; materialised red behind the red gate. Init runs it inline, add and design's standalone round call its append mode; standalone it re-derives after appends or a consolidation and presents the row-set diff. Never runs verification. |
| **/vid:vid-design** | Turn an owner-approved design into the visual half of the spec: brief + manifest derived from the PRD, then — once it has proven it can see its own drawings — it asks who makes the design: you in your own tool from the brief (recommended) or ViD here; canvases+tokens come back, the design-join court reconciles fail-closed, ratify — protected, marker-cited, token-fenced, fidelity-graded. |
| **/vid:vid-stage** | Cut the product into stages you ratify in one sitting — outcome, technical order, constraints, risk; a ladder from the finest cut whose stages are each usable and safe to release to a single stage, with counts; you pick a rung. Init runs it at its end, offering a technical stage 0 (a thin working skeleton, put on staging for real, never released) and asking once whether ViD may set up the test site and put each finished stage on it on its own; on request it re-cuts. Each closed stage can go to staging, and live if you say so. |
| **/vid:vid-develop** | Make the ledger green: build the entire PRD end to end, no approvals, ledger green at every commit, inventory and import courts at every commit; product questions come to the owner immediately, technical ones are decided and logged. Auto-grades at completion. |
| **/vid:vid-plan** | The GitHub modes (ticket mode): plan the project for a dev team that works from GitHub tickets — the setup asked once, every ratified inventory row a planned row, the plan in develop's form (every stage, the skeleton first), one plan page for you to ratify. Product text only; nothing is written to GitHub: /vid:vid-run's ticket writer publishes from the ratified plan. |
| **/vid:vid-run** | The GitHub modes (ticket mode): one long session runs the tickets through to the end: it decides, records merges, re-plans and publishes the next ticket, and waits with no model while nothing is new. `/vid:vid-run <state repo>` in an empty folder resumes from GitHub alone. |
| **/vid:vid-mode** | GitHub manual, for a team of people who split ViD's tickets into their own units: `/vid:vid-mode manual` switches the project and takes stock of the tickets already published (the plan ratified in a planning sitting, nothing posted to the team's repositories); run again after any publish, amendment or spec change made by hand. `/vid:vid-mode auto` switches it back to GitHub auto, once no open ticket has sub-issues, nothing is pending or to place, and the plan is ratified again in GitHub auto. |
| **/vid:vid-next** | GitHub manual: one call, made by hand — GitHub read (and Slack, for context), then what is not yet with the team, the team's changes to its tickets, the re-plan triggers by how critical they are, the warnings and the moves; then it does the moves the owner names in the call, in your words (publish, answer, decline, done, engines, own-work; amend, withdraw and team-change; walk-stage, read-walk and write-summary), and writes the plan page. |
| **/vid:vid-answer** | The GitHub modes: every answer of yours to what waits on you, `/vid:vid-answer <Q<n> or #<n>:<k>> <answer> "<your words>"` — a held row, a team question, a finding, a close, a draft of a change (yes lands it), a trigger or a move a call raised; it lists what still waits, with the answers each takes. |
| **/vid:vid-read** | The GitHub modes: GitHub read now, the one read ViD's own work uses (and Slack, for context, when set up), with what could not be read. |
| **/vid:vid-triggers** | The GitHub modes: what is not yet with the team, the team's changes to its tickets, the re-plan triggers with their evidence, the warnings and the moves, shown at any time. |
| **/vid:vid-replan** | The GitHub modes: re-planning by the same rules — in GitHub manual the re-plan analysis and its page, with what it covers as you name it, nothing reaching the team until your words to apply it (/vid:vid-next implement-replan); in GitHub auto a re-plan the run makes at your word. |
| **/vid:vid-tickets** | The GitHub modes: a step going out and every change to a published ticket, through one path — `admit <step>` (may it start: its holds and warnings, nothing posted), `publish <step>`, `amend #<n>`, `withdraw #<n>`, `reopen #<n>`, `fix <key>` and `reached`, each with your words, required in GitHub manual. |
| **/vid:vid-accept-step** | The GitHub modes: a step's end, a ticket decided now by the same decision rules, `/vid:vid-accept-step <ticket> [<commit>]` — in GitHub manual at a commit of the code repository's main, the newest one with the team's head report when you name none; in GitHub auto at the head of the pull request naming it. Nothing is posted but that ticket's decision, and nothing at all while its report is not in. |
| **/vid:vid-step-close** | The GitHub modes: a step's close, `/vid:vid-step-close <step>` — asked now when it is owed, read when it is out, or what is missing said; in GitHub manual a closed step's tickets are closed. |
| **/vid:vid-stage-close** | The GitHub modes: a stage's end, `/vid:vid-stage-close <stage>` — its full run and grade asked when due, its walk started or read, its summary written, or the stage closed, whichever is next, or what is missing said; `walk`, `read-walk` or `summary <stage>` does one alone, and `end` computes the completion report. In GitHub manual the walk and the summary are moves you name in /vid:vid-next. |
| **/vid:vid-spec-publish** | The GitHub modes, one repository: the spec published into the code repository's folder the setup names, as one pull request the team merges, its stamp set to the export, `/vid:vid-spec-publish "<your words>"`, or, when your team publishes by its own process, read from its pull request, `/vid:vid-spec-publish #<n> "<your words>"`; nothing pushed from your machine. |
| **/vid:vid-devagent** | GitHub auto: ViD's own DevAgent started in a Claude Code conversation of its own, `/vid:vid-devagent <job note>` typed in a new conversation opened in its work folder. It starts DevAgent and shows each piece of its work as it ends, and its stop as soon as it comes; "stop" there stops it, and closing the conversation leaves it running. |
| **/vid:vid-grade** | Read-only adversarial review by fresh-context graders against each REQ's Fail-if; exit bar + convergence stop rule for loops, --visual fidelity mode, court-edit sweep; ranked findings table + dated report under .vid/grades/. Always safe to run, any repo. In the GitHub modes, an ask for a grade by the dev side, in your words, its report read at the next round or /vid:vid-next call and its findings yours to rule. |
| **/vid:vid-fix** | Targeted apply only: owner corrections or the accepted rows of a grade report → spec append + ledger test + fix in one commit, then a blast-radius re-grade (changed modules + declared dependents). Never sweeps. |
| **/vid:vid-add** | A feature after the fact: mini-interview → PRD appends → inventory delta → develop as it is → one grade, scoped to the add → adjudicate/fix. |
| **/vid:vid-incorporate** | a decision record or proposal the owner names: the map, the amendment, one yes |
| **/vid:vid-deploy** | Two targets. **Deploy to staging** (a bare deploy): the rows changed since the last full pass on a scoped run, then one real action per provider seam — fast, repeatable. **Deploy to production**: staging's exact commit, the full run, the re-grade, a local rehearsal on a restored prod backup, owner-confirmed cutover. The only verb that touches anything real; never runs implicitly, except a staging deploy at a stage close, or at "continue" while staging is being set up, under your standing staging authorization. In the GitHub modes ViD deploys nothing: `/vid:vid-deploy staging` posts the staging okay for DevAgent's deploy when one is due, and `/vid:vid-deploy production "<your words>"` is your production yes. |
| **/vid:vid-view** | The project viewer: self-contained HTML snapshots of the project — now, and one for each milestone not yet made — read from git and ViD's records, one file each that opens offline by double-click, with an index. Read-only; writes only into its own folder outside the project; runs only when asked. |
| **/vid:vid-share** | Send one run's logs to someone you choose without making them public: a redacted bundle shown to you first, then, on your yes, a private repository in your own account (or an organisation you own) with the person you name invited, or no one; or one file you send by hand. |
| **/vid:vid-help** | This card. |

Close with the working sequence, one line: init (once; create-prd runs
inside it, or standalone before it; test-inventory runs inside it, and
on demand after any PRD append) → design (when the product has a
face) → develop (stage by stage, when the product is cut into stages) →
grade → fix → deploy; add re-enters the loop; stage re-cuts. In the GitHub modes, ticket mode: init → stage → plan → run, one long session to the end, while a dev team builds (ViD's own dev side in GitHub auto); in GitHub manual, a team of people: init → stage → plan → mode manual → next, one call at a time; a "stage" is a slice of the product, "staging" the test site — never the same thing. And the composition rule: grade discovers, the owner adjudicates,
fix applies — the owner is the pipeline between them.

## Law for maintainers

This table is release material: any commit that adds, removes, or
meaningfully changes a verb updates this table in the same commit.
