# ViD — VisionDelivery.ai

A delivery method for one product-expert owner and strong coding models,
shipped as a Claude Code plugin. The spec binds the builders; the test
ledger binds the checkers. You own the product decisions; ViD builds,
tests and grades the rest, and records everything it does.

Official website: [VisionDelivery.ai](https://visiondelivery.ai) · Official repository: [VisionDeliveryAi/vid](https://github.com/VisionDeliveryAi/vid)

How it works, in one paragraph: **init** turns your brief into a PRD whose
every requirement says how it could fail, and a Test Inventory that routes
each failure condition to what can check it: most become tests that start
red. **develop**
then makes the ledger green: an orchestrating session plans the work in
steps and hands each to a short-lived agent (a builder, a fixer, a test
author), while independent graders judge every row against its Fail-if.
Every test run goes through one test manager onto shared Docker test
environments, on a frozen copy of the code. Product questions come to you
at once; technical decisions are made and logged. Small scripts (the
courts) check the law at every commit, and each court proves it still
convicts on a known-bad fixture. Nothing framework-specific ships: what is
stack-shaped is generated at init from your scaffold.

New to ViD? The tutorials are in [docs/tutorials/](docs/tutorials/).

## Install

ViD is a Claude Code plugin, distributed from this repository (which is
its own plugin marketplace). Three commands. First, from a terminal,
authenticate git for GitHub (once):

```bash
gh auth login
```

(HTTPS users: also `gh auth setup-git`. SSH users with a loaded key skip
both.) Then, inside Claude Code:

```
/plugin marketplace add VisionDeliveryAi/vid
/plugin install vid@vid
```

Then start Claude Code in an empty directory and type `/vid:vid-init`. Every
verb is a slash command of the plugin, `/vid:vid-<verb>`: type `/vid` to see them.

## Three ways to work

- **local auto** — ViD builds the whole product itself, on your machine, with no dev team: `/vid:vid-init`, then `/vid:vid-develop`.
- **GitHub auto** — ViD builds your product through GitHub, with no outside team. Every piece of work is a ticket and a pull
  request you can read, nothing merges without ViD's acceptance, and ViD's own DevAgent does the building, on your machine,
  started by you: `/vid:vid-init`, then `/vid:vid-plan` and `/vid:vid-run`. The run prints DevAgent's job note, filled in, and
  two ways to start it: first, in a new Claude Code conversation in its work folder, `/vid:vid-devagent <job note>`, which
  shows each piece of DevAgent's work as it ends; or in the background, `sh <plugin>/devagent/dev-manager/dm.sh up <job note>`
  (devagent/README.md says more).
  Where its deploys end, today: DevAgent deploys staging, the rehearsal and production only as local copies on its own
  machine. A deploy to a real host is done by your own DevAgent, in GitHub team, or comes in a later release.
- **GitHub team** — ViD writes GitHub tickets for an outside team's DevAgent, which builds, tests and merges in its own pipeline:
  `/vid:vid-init`, then `/vid:vid-plan` and `/vid:vid-run`.

The two GitHub modes are what the verbs below call ticket mode.

## Getting started

ViD has been run across versions on real products. The most recent built
a web product over two weeks with hundreds of agents, and ended with a
full grade of its test rows against their Fail-ifs. Before your first
project, check that your install works, as below.

### Prerequisites

- Claude Code, signed in, current version.
- git, plus a GitHub account with git authenticated (`gh auth login` +
  `gh auth setup-git`, or SSH).
- Docker Desktop, installed and running — ViD's test harness is
  Docker-only; a project's ledger cannot run without it.
- For GitHub auto: the `claude` command, signed in, since DevAgent's agents run on it; and, for a product
  with screens in either GitHub mode, a browser already on the machine ViD runs on, for ViD's walk through
  the screens (a container image that holds one, or an installed browser). ViD never installs one.
- **On a PC:** native Windows (Git Bash) works, but ViD's checks are
  slower there, since starting a process is slow on Windows. With WSL
  installed, ViD asks you once, at `/vid:vid-init`, whether it may run its
  checks there; the answer is kept for that PC in `.vid/windows`, and you
  change it by editing that file. Without WSL, or without your yes, ViD
  carries on natively.

### Install

The three commands in the Install section above.

### Check your install

An install is checked the way ViD checks anything: the judges prove they
convict, and one real init completes. Three steps, in order:

1. **Version.** Type `/vid:vid-help`. It shows the installed version, which must be **0.26.11.1.1**.
2. **Court self-test.** Ask Claude: *"Run ViD's court self-test suite —
   `checks/selftest/run.sh` under the installed plugin root — and report
   the verdict line."* Expected: every case that ran convicts, `selftest:
   <n>/<n> courts convict, 1 skipped`. The skipped one is view-page-diff, which
   checks only in ViD's own repository (it needs the design pack, which is not
   shipped); a skipped case prints `skipped — <what it needs>` and fails
   nothing. A case that hangs is stopped at its time limit and reported `TIMED
   OUT`; a failed case's last 20 lines print under it. A line ending "rescued by a
   retry" is not a clean pass. A court that fails to convict its
   known-bad fixture is worth reporting before you trust the verb that
   court guards.
3. **Toy init.** In a NEW empty directory, type `/vid:vid-init` and describe a
   deliberately tiny product (a page or two of behavior; accept default
   answers freely). Expected: the interview completes, the Test
   Inventory is ratified (its tests not written yet), the spec commit
   exists, and init's last words say there is no code yet — `/vid:vid-develop`
   builds the code skeleton as its first step. Init does not run the self-test:
   step 2 runs it, by its own command.

Self-test green and toy init complete: your install works. If either
fails, please report it.

### Updates

To update: `/plugin marketplace update vid`, then `/plugin update vid@vid`,
and confirm the version with `/vid:vid-help`. Versions are numbered
major.year.month.release (0.26.10.1 is the first release of October 2026).

### Reporting issues — one GitHub issue per finding

File an issue on the [official repository](https://github.com/VisionDeliveryAi/vid)
per finding, in this shape:

- **Verb & step** — which vid verb, at which point in its run.
- **Expected vs observed** — one paragraph each.
- **Stack** — the project's language/framework/database; your OS
  (macOS version, or WSL2 distro + Windows version); Docker version.
- **Evidence** — paste, never describe: court output, the selftest
  verdict line, ledger state, grade finding rows, the commit SHA.
- **Repro** — the commands or prompts, in order.
- **ViD version** — as reported by `/vid:vid-help`, never from memory.
- **Consequence** — what this blocks: the install, a verb, a court's
  verdict, or a specific claim the method makes.

No severity scores — the consequence line is the ranking. Counts and
pasted evidence outrank adjectives.

## The verbs

The working sequence: **init** (once) → **design** (when the product has a
face) → **develop** (build) → **grade** (look, any time) → **fix** (apply
specific corrections) → **deploy** (ship: the only verb that touches
anything real). **stage** cuts the product into stages (inside init, or
on request); **add** re-enters the loop for a new feature; **view** shows
the project; **help** prints the installed version and the verb list. In
ticket mode **plan** and **run** take develop's place while a dev team
builds. A *stage* is a slice of the product; *staging* is the test site.
Each verb is typed as Claude Code shows it, `/vid:vid-<verb>` (v0.26.10.26.7): the
plugin is `vid`, and each verb is one of its skills.

- **vid-init** (`/vid:vid-init`): once, in an empty directory. Runs **vid-create-prd** inline
  (or adopts a PRD it already ratified), asks the technical-foundation
  questions — where the product runs and how ViD gets access among them,
  recorded by name, never a credential — and writes BASELINE.md,
  DECISIONS.md, ARCHITECTURE.md and the CLAUDE.md law file. Runs the design chain when the product has a face,
  and **vid-test-inventory** to derive the Test Inventory, which you ratify.
  It installs the commit-hook courts, proves they convict, and makes the
  spec commit — **the spec only**, and it says so at its end: there is no
  code, no test harness and no written test yet. **vid-develop** builds the
  code skeleton as its first step (the stack so the repo is the
  architecture, the Docker-only test harness, the census extractors from the
  real scaffold, every ratified row written as a failing test, gated on red:
  a new test that passes against no implementation fails by name); or
  **vid-plan** sends the skeleton to a dev team as their first ticket.
- **vid-create-prd** (`/vid:vid-create-prd`): authors the PRD. One interview batch where each
  question must matter downstream, a content contract you ratify, typed
  requirements each carrying a Fail-if (a condition a wrong implementation
  breaks), a completeness audit and a whole-set review. You appear at the
  batch and three ratification pauses. Every decision says whose it is:
  yours, or ViD's, shown to you for confirmation. One court
  (`checks/prd.sh`) checks the PRD's grammar at every commit. Runs inside
  init or on its own.
- **vid-test-inventory** (`/vid:vid-test-inventory`): owns the Test Inventory, every test the project
  will ever have, routed by what can run it: rule rows counted over the
  whole code, ledger rows that execute, grading-checklist lines for what
  only judgment can see, and rows that record what is deliberately not
  tested and why. Derived from the PRD, the design and the routes, with a
  counterexample lens on every row. Runs inside init, and again after PRD
  changes, showing the row-set difference.
- **vid-stage** (`/vid:vid-stage`): cuts the product into stages, at the end of init or on
  request. Through five lenses (what each stage lets people do, what must
  be built first, your constraints, the risks, how much each stage holds) it finds the finest cut in
  which every stage is usable and safe to release, then coarser versions
  of it, shown as one ladder with counts; you pick a rung in one sitting,
  adjust it, or keep a single stage. The cut
  is `STAGES.md`, a law file; develop builds one stage at a time, closes
  and tags each, and deploy can ship a closed stage. At init it also
  offers a technical stage 0, a thin working skeleton put on staging for
  real and never released, and asks once whether ViD may set up the test
  site and put each finished stage on it on its own.
- **vid-design** (`/vid:vid-design`): turns an owner-approved design into the visual half of
  the spec. It derives the screen-and-state brief from the PRD; you design
  from it in Claude Design or any tool (one canvas per screen for new
  projects); what comes back is imported and reconciled screen by screen
  by a fail-closed court. Product decisions the design embodies are read
  back into the PRD.
- **vid-develop** (`/vid:vid-develop`): one command; makes the ledger green, end to end, with
  no approvals. The orchestrator writes a plan of steps and changes it
  only with a recorded reason. Builders, fixers and test authors run as
  separate agents (Claude, or Codex for builders when you say so), and
  graders that saw none of the build judge each row KEPT or BREACHED,
  classing a breach as the product's, the test's or the test harness's. Tests are written as their own job, with
  the satisfying conditions stated before the code. By your choice it
  works depth first, or breadth first (core paths and critical rows
  first, edge rows in hardening steps at the end). Product questions come
  to you immediately; the build keeps working on everything they don't
  hold up. Every hour the observer records the same short update in
  `.vid/PROGRESS.md`: what's done, what's left, your open questions and an
  estimate. The observer runs outside the session and writes a notice
  into the run's heartbeat when a question waits, when the build stops,
  dies or goes quiet, or when an agent goes quiet, and says how to resume;
  nothing pops up, and ViD never restarts a build itself. "Complete"
  is computed, never asserted. Your controls: "pause", "continue".
- **vid-grade** (`/vid:vid-grade`): the discovery verb, strictly read-only. Fresh-context
  graders review every requirement against its Fail-if with file:line
  evidence, probing dead code, default configuration, fixtures and
  end-to-end journeys. Where a ratified design exists, a screenshot
  review against it is part of every grade (`--visual` forces it). Findings come as a ranked table and a dated report; nothing is
  changed. Works on any repository, any time.
- **vid-fix** (`/vid:vid-fix`): the apply verb, targeted only: corrections you type, or the
  accepted rows of a grade report. A bug gets a spec append, a test seen
  red first, and the fix, in one commit; a rule gets a count over every
  site first. Then the changed modules and their dependents are graded
  again, because fixes inject defects.
- **vid-add** (`/vid:vid-add`): a feature after the fact: mini-interview, PRD appends,
  develop scoped to the change, then grade and fix scoped to it.
- **vid-view** (`/vid:vid-view`): the project viewer: self-contained HTML snapshots of the
  project, now and at each milestone, with a change log across them, read
  from git and ViD's records. Progress, your open and answered questions,
  decisions and the design. Read-only; it opens offline.
- **vid-share** (`/vid:vid-share`): send one run's logs to someone you choose without making
  them public. It builds a redacted bundle, shows you what it holds, and on your yes pushes it
  to a private repository in your own GitHub account (or an organisation you own), inviting
  the person you name, or no one; or it keeps it as one file you send by hand.
- **vid-deploy** (`/vid:vid-deploy`): ship in two targets. **Deploy to staging** (a bare
  deploy) is fast and repeatable: the rows changed since the last full
  pass run on a scoped run of the exact commit, then one real action
  through each live provider. **Deploy to production** takes the commit
  staging runs: the full run, a re-grade of every row changed since the
  last full pass, a local rehearsal on a restored production backup, and
  a production cutover you confirm every time. In a staged project you can
  say "hold after this stage": corrections to it then reach staging and
  production on their own until you say "continue". You authenticate and hold every secret value; the agent operates
  through the already-authenticated CLI and never sees one. Never invoked
  by anything but you, except a staging deploy at a stage close, or at
  "continue" while staging is being set up, under your standing staging
  authorization.
- **vid-plan** (`/vid:vid-plan`): ticket mode, for a dev team with its own pipeline. ViD's
  repository keeps the spec, the plan and ViD's records; the code
  repository on GitHub gets only issues, milestones, labels and comments.
  It writes the plan — every stage planned, the code skeleton first — and
  shows you one plan page to ratify; `/vid:vid-run` publishes the tickets from
  it. Each ticket carries its own instructions and the rows it must pass;
  nothing in the dev team's pipeline changes. ViD never pushes, merges or
  deploys.
- **vid-run** (`/vid:vid-run`): ticket mode, after the plan: one long session
  runs the tickets through to the end. It decides each ask, records each merge,
  re-plans, publishes the next tickets, and asks you only what it must, each as a
  numbered question.
- **vid-devagent** (`/vid:vid-devagent <job note>`): GitHub auto's dev side, started in a Claude
  Code conversation of its own, opened in DevAgent's work folder. It starts DevAgent and shows each
  piece of its work as it ends, and its stop as soon as it comes; closing the conversation leaves
  DevAgent running.
- **vid-help** (`/vid:vid-help`): the installed version, read live from the plugin, and the
  verb list.

**The review cycle is composition, not a verb:** grade discovers, you
adjudicate the findings (fix, dispute or defer), fix applies. And grade is
not test: the ledger runs the tests, deterministically; grade reviews,
adversarially.

### ViD's panel in the Claude desktop app

In the Claude desktop app, a ViD project gets a panel beside the chat: the
map of the nine stops of defining a project, and, at each of the four PRD
sittings (the interview and the three pauses), what ViD asks laid out to
answer, mark and send in one message. It opens by itself when a sitting
waits on you, or with `/vid-panel`. It only shows: everything ViD asks is
in the chat as before, the answer is your message in the chat, and the
PRD stays the only record. It sends only into the conversation that asked;
anywhere else it puts your answers in the message box for you to send.
The other stops (the technical hints, the design, the test list, the
releases) are answered in the chat for now. The terminal, VS Code and the
mobile app show no panel and nothing changes there.

## What's in the box

```
skills/     the verbs, and the internal skills develop uses (build,
            verify, test manager, test writing, staging setup, the code
            skeleton)
agents/     the agent roles ViD's verbs spawn: builder, fixer, grader,
            test author, test analyst
templates/  PRD, BASELINE, DECISIONS, ARCHITECTURE, DEPLOYMENT,
            INVENTORY, GRADING-CHECKLIST, RUN-STATE, SUMMARY, ANSWERERS
            (ticket mode), the CLAUDE.md law file, the go-live note, the
            test-harness skeleton
checks/     the courts and tools: commit hooks, the PRD, inventory,
            design, import and census courts, the test manager
            (test.sh) and test environments, the plan and brief records,
            Codex jobs, evidence, metrics and progress, the observer and
            watchdog, the deploy gates, ticket mode's GitHub adapter
            (github.sh, the one file that calls gh) and the page renderer
            (page.sh), and
            selftest/ (a known-bad fixture per court, the judge proven to
            convict)
hooks/      plugin hooks: the session and agent record, the death
            record, the re-entry page and compulsory re-read after a
            compaction, the builders' context limit, bounded waits,
            Codex protected paths
viewer/     the project viewer (view.sh, the page, its data contract)
seed/       the library a run learns into: ships with the
            stack-agnostic extractor contract and class catalog
```

## Philosophy

- **The spec and the ledger are the law.** The spec is re-read at every
  generation; the ledger runs at every commit. What sits between (the
  plan, the briefs, the records) is written down so it can be checked,
  never narrated.
- **Every correction writes twice.** A spec append binds the builders; a
  test binds the checkers. The system can't regress on anything you
  corrected.
- **Two channels.** Product questions go to you, immediately; technical
  questions are decided and logged, never asked.
- **The repo is the architecture.** Scaffold before building: models
  conform to the code around them.
- **Records, not memory.** A long run outlives any one conversation. The
  orchestrator keeps its state in records, so a compaction or a new
  session picks up where the last one stopped.
- **Measured, not narrated.** Progress, completion and cost are computed
  from the records; counts, never scores.

## Licence

Except where explicitly identified otherwise, the project code, prompts,
workflows and documentation in this distribution are licensed under the
Apache License, Version 2.0. Third-party material retains its applicable
licence and notices. See [LICENSE](LICENSE) for the terms and
[NOTICE](NOTICE) for project attribution.

ViD is provided "AS IS", with warranty exclusions and limitations of
liability as set out in sections 7 and 8 of the Apache License, Version
2.0. You are responsible for assessing its suitability and the risks of
using it. See LICENSE for the full terms, including exceptions required by
applicable law or agreed in writing.

Contributions: see [CONTRIBUTING.md](CONTRIBUTING.md). Security reports:
see [SECURITY.md](SECURITY.md).

## Credits

ViD / VisionDelivery.ai was founded by Florin Ciontu.

The official project is maintained, operated and published by
[AI Value Link](https://aivaluelink.com).
