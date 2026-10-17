run: active
session: {{CLAUDE_CODE_SESSION_ID}}
plan: required
now: -
questions: - · next Q1
slice: {{N_OR_-}} open    since: {{ISO_TIME}}    commit: {{SHA}}
modules: {{MODULE_PATHS_THIS_SLICE_TOUCHES}}
claims: {{ROW_IDS_UNDER_WORK}}
receipt: {{REPORT_NAME_OR_none}}    briefs: {{LIVE_BRIEF_FILES_OR_-}}
held: {{HELD_ROW_IDS_OR_-}}

<!-- .vid/RUN-STATE.md — the run's own record (v0.9.3 3.8, R7, R12; v0.9.5
     3.2, R2). Law as a RECORD, not an obligation: its existence and the
     keys above are required; the plan written below is the agent's own.
     Created at develop's start (`stage name=develop state=start`), before
     the first slice opens (`slice: -` until then), so the observer and the
     death record cover planning too; rewritten by the running session at
     every slice open, every slice close, every handoff and at the
     completion report, carrying every key over. Keys first, one line each,
     exactly as above:
       `run:` one of four — `active`; `waiting` (everything left depends on
         an open question below); `stopped <reason>` (genuinely blocked, or
         `stopped owner asked to pause`); `complete` (written only by
         `sh checks/metrics.sh completion --record`). Every resumption
         writes `run: active` first; every write of `run:` is also recorded
         as `sh checks/event.sh 'run state=<value>'`.
       `session:` the id of the session running the build
         ($CLAUDE_CODE_SESSION_ID), rewritten at develop's start, at a
         takeover, after a /clear and after any resume.
       `plan: required` (v0.9.6) — written by develop at its start; with it
         the run's gate is on (`sh checks/plan.sh gate`): frozen test runs
         kept by run, at this worktree, the run's home. A file without it
         is a 0.9.5 run.
       `strategy:` (v0.9.7.2) — absent, or `depth-first`: depth first, the
         default; `breadth-first`: the owner's choice, written only by
         `sh checks/plan.sh strategy <s> --by owner --words "<the owner's
         words>"`, which keeps the words in .vid/plans/decisions/. Under
         breadth first the plan's hardening steps and protected: line apply
         (below); switched back, they are inert.
       `now:` (v0.9.6) — one line in the build's own words, the last row of
         the progress update; written with `sh checks/progress.sh --now
         "<line>"`.
       `questions:` `<k> open · next Q<m>`, or `- · next Q<m>` — the next
         number is never reused.
       `slice:` N open|closed with its start time and the commit it opened
         on; `modules:` the module paths this slice touches; `claims:` the
         ROW ids under work; `receipt:` the current report's name and
         `briefs:` the live brief files under .vid/briefs/; `held:` the
         rows the verdict engine holds for the owner.
     Read by checks/observe.sh (every tick, and `resume`) and by the death
     record, never by a grader (a grader's read stops at the receipt its
     brief names). The history is the events, not this file: `slice-open`,
     `slice-close`, `slice-modules`, `question` and `run state` in
     .vid/metrics-events. RECORDS.md is the contract. -->

## The plan

<!-- v0.9.6 (3.1–3.5). The build's plan as steps, one machine-read block;
     the plan is yours — how many steps, their order, size and lanes — and
     every edit to the block is recorded with
     `sh checks/plan.sh change <what> "<why>"` (what: create add drop split
     merge reorder lanes rows other edge); an unrecorded edit refuses every
     admission. One line per step, and one shared: line:
       step <id> | name: <the step in plain product words> | modules: <path prefixes> | builds-on: <step ids or -> | rows: <ROW ids and ROW-a..ROW-b ranges> | lane: builder|orchestrator (<why>) [| kind: hardening]
       shared: <the paths every step depends on — the harness, the fakes, the compose file, migrations>
       protected: <ROW ids and ranges>   (optional, one line; it only grows)
     An id is never reused; every row must exist in INVENTORY.md, and in one
     step only. Why steps running side by side won't collide is said in the
     prose below the block.
     v0.9.7.2, under breadth first: a step ending `| kind: hardening` holds
     edge rows and nothing builds on it; a row moves into one only by
     `change edge`; a protected row — derived by `sh checks/inventory.sh
     protected`, or named on the protected: line — never sits in one. -->

```vid-plan
step {{S1}} | name: {{PLAIN_NAME}} | modules: {{PATH_PREFIXES}} | builds-on: - | rows: {{ROWS}} | lane: builder
shared: {{SHARED_PATHS}}
```

## Slice {{N}} — the plan

The slice plan and why: what it builds, the order and its rationale, what
was considered and rejected; which steps run side by side and why they
won't collide.

## Dependencies discovered

What turned up during the slice and what it changed — an unbuilt module a
row needs is written here the moment it is found.

## Open product questions

<!-- One line per open question, exactly, and nothing else in this section
     (the observer tells the owner when a line does not parse or the count
     above disagrees):
     - Q<n> · asked <UTC> · gates <rows | modules | all remaining work> · <the question, one plain sentence>
     The rows held for the owner, the rows owed on an owner decision and the
     grade findings awaiting adjudication are questions too, one line each.
     A line is deleted when its answer is appended to the PRD. -->

## Rows under work

By reference to their attempt records, `.vid/verdicts/<ROW-id>.md`.
