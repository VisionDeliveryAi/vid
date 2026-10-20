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

Then start Claude Code in an empty directory and say `vid init`. Each
verb is also a slash command: type `/vid` to see them.

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
- **On a PC: WSL2 is required.** Do everything — the clone, Claude Code,
  git, `vid init` — inside a WSL2 distribution, with Docker Desktop's
  WSL2 integration enabled for that distribution. Native Windows
  (PowerShell or Git Bash) is not supported.

### Install

The three commands in the Install section above.

### Check your install

An install is checked the way ViD checks anything: the judges prove they
convict, and one real init completes. Three steps, in order:

1. **Version.** Say `vid help`. It must report **0.26.10.4**.
2. **Court self-test.** Ask Claude: *"Run ViD's court self-test suite —
   `checks/selftest/run.sh` under the installed plugin root — and report
   the verdict line."* Expected: `selftest: 539/539 courts convict`.
   One of the 539, view-page-diff, checks only in ViD's own repository
   (it needs the design pack, which is not shipped); elsewhere it passes
   without checking. A line ending "rescued by a
   retry" is not a clean pass. A court that fails to convict its
   known-bad fixture is worth reporting before you trust the verb that
   court guards.
3. **Toy init.** In a NEW empty directory, say `vid init` and describe a
   deliberately tiny product (a page or two of behavior; accept default
   answers freely). Expected: the interview completes, the Test
   Inventory is ratified and materialised as FAILING ledger tests, init
   reports its own court self-test green on your machine, and the
   initial commit exists.

Self-test green and toy init complete: your install works. If either
fails, please report it.

### Updates

To update: `/plugin marketplace update vid`, then `/plugin update vid@vid`,
and confirm the version with `vid help`. Versions are numbered
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
- **ViD version** — as reported by `vid help`, never from memory.
- **Consequence** — what this blocks: the install, a verb, a court's
  verdict, or a specific claim the method makes.

No severity scores — the consequence line is the ranking. Counts and
pasted evidence outrank adjectives.

## The verbs

The working sequence: **init** (once) → **design** (when the product has a
face) → **develop** (build) → **grade** (look, any time) → **fix** (apply
specific corrections) → **deploy** (ship: the only verb that touches
anything real). **add** re-enters the loop for a new feature; **view** shows
the project; **help** prints the installed version and the verb list.

- **vid-init**: once, in an empty directory. Runs **vid-create-prd** inline
  (or adopts a PRD it already ratified), asks the technical-foundation
  questions, and writes BASELINE.md, DECISIONS.md, ARCHITECTURE.md and the
  CLAUDE.md law file. Runs the design chain when the product has a face,
  and **vid-test-inventory** to derive the Test Inventory, which you ratify
  and which is materialised as failing tests. It scaffolds the stack so the
  repo is the architecture, installs the commit-hook courts and the
  Docker-only test harness, generates the census extractors from the real
  scaffold, proves the courts convict, and gates on red: a new test that
  passes against no implementation fails init by name.
- **vid-create-prd**: authors the PRD. One interview batch where each
  question must matter downstream, a content contract you ratify, typed
  requirements each carrying a Fail-if (a condition a wrong implementation
  breaks), a completeness audit and a whole-set review. You appear at the
  batch and three ratification pauses. Every decision says whose it is:
  yours, or ViD's, shown to you for confirmation. One court
  (`checks/prd.sh`) checks the PRD's grammar at every commit. Runs inside
  init or on its own.
- **vid-test-inventory**: owns the Test Inventory, every test the project
  will ever have, routed by what can run it: rule rows counted over the
  whole code, ledger rows that execute, grading-checklist lines for what
  only judgment can see, and rows that record what is deliberately not
  tested and why. Derived from the PRD, the design and the routes, with a
  counterexample lens on every row. Runs inside init, and again after PRD
  changes, showing the row-set difference.
- **vid-design**: turns an owner-approved design into the visual half of
  the spec. It derives the screen-and-state brief from the PRD; you design
  from it in Claude Design or any tool (one canvas per screen for new
  projects); what comes back is imported and reconciled screen by screen
  by a fail-closed court. Product decisions the design embodies are read
  back into the PRD.
- **vid-develop**: one command; makes the ledger green, end to end, with
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
- **vid-grade**: the discovery verb, strictly read-only. Fresh-context
  graders review every requirement against its Fail-if with file:line
  evidence, probing dead code, default configuration, fixtures and
  end-to-end journeys. Where a ratified design exists, a screenshot
  review against it is part of every grade (`--visual` forces it). Findings come as a ranked table and a dated report; nothing is
  changed. Works on any repository, any time.
- **vid-fix**: the apply verb, targeted only: corrections you type, or the
  accepted rows of a grade report. A bug gets a spec append, a test seen
  red first, and the fix, in one commit; a rule gets a count over every
  site first. Then the changed modules and their dependents are graded
  again, because fixes inject defects.
- **vid-add**: a feature after the fact: mini-interview, PRD appends,
  develop scoped to the change, then grade and fix scoped to it.
- **vid-view**: the project viewer: self-contained HTML snapshots of the
  project, now and at each milestone, with a change log across them, read
  from git and ViD's records. Progress, your open and answered questions,
  decisions and the design. Read-only; it opens offline.
- **vid-deploy**: ship through three gates: a local rehearsal on a
  restored production backup, a staging deploy with one real action
  through each live provider, and a production cutover you confirm every
  time. You authenticate and hold every secret value; the agent operates
  through the already-authenticated CLI and never sees one. Never invoked
  by anything but you.
- **vid-help**: the installed version, read live from the plugin, and the
  verb list.

**The review cycle is composition, not a verb:** grade discovers, you
adjudicate the findings (fix, dispute or defer), fix applies. And grade is
not test: the ledger runs the tests, deterministically; grade reviews,
adversarially.

## What's in the box

```
skills/     the verbs, and the internal skills develop uses (build,
            verify, test manager, test writing)
agents/     the agent roles ViD's verbs spawn: builder, fixer, grader,
            test author, test analyst
templates/  PRD, BASELINE, DECISIONS, ARCHITECTURE, DEPLOYMENT,
            INVENTORY, GRADING-CHECKLIST, RUN-STATE, SUMMARY, the
            CLAUDE.md law file, the go-live note, the test-harness
            skeleton
checks/     the courts and tools: commit hooks, the PRD, inventory,
            design, import and census courts, the test manager
            (test.sh) and test environments, the plan and brief records,
            Codex jobs, evidence, metrics and progress, the observer and
            watchdog, the deploy gates, and selftest/ (a known-bad fixture
            per court, the judge proven to convict)
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
