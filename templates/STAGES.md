# {{PROJECT_NAME}} — STAGES

> The stage cut, ratified by the owner in one sitting (vid-stage): the
> rung of the ladder the owner picked. The
> product is delivered in stages: each built stage is closed, tagged and
> can go to staging, and at each close the owner decides whether to go
> live or carry on. A project that keeps a single stage has no STAGES.md.
>
> The ```vid-stages block below is law (checks/lawfiles): a change to it is
> a standalone law commit, and a change to which stage anything is in — a
> `STAGE-` line, a `split:` or a `row:` line, or this file created or
> deleted — cites the owner's answer (`A-NNN`) in its commit message.
> The cards are the owner's reading; nothing reads them mechanically.

## The cut

<!-- One line per stage, numbered from 1, each pilot feature in exactly one:
       STAGE-<n> | <name> | features: FEAT-a FEAT-b …
     A stage whose requirements all come from split: lines (a second usable
     stage inside one feature) lists none:
       STAGE-<n> | <name> | features: -
     A split feature: its requirements that go to another stage, by id:
       split: REQ-x REQ-y -> STAGE-<n>
     A ROW whose requirements sit in different stages, placed (a census
     rule row is stage 1 unless placed later the same way):
       row: ROW-x -> STAGE-<n>
     An ordering edge, with where it comes from (never to a later stage):
       needs: FEAT-a needs FEAT-b — <source: a requirement, a module or a seam>
     checks/stages.sh judges the block at every commit; `sh checks/stages.sh
     scope --upto N` lists what stages 1 to N must hold. -->

```vid-stages
STAGE-1 | {{STAGE_NAME}} | features: {{FEAT_IDS}}
STAGE-2 | {{STAGE_NAME}} | features: {{FEAT_IDS}}
```

## Stage 1 — {{STAGE_NAME}}

<!-- One card per stage, in plain language: no ids unless the owner asks. -->

- **Outcome:** {{WHO_CAN_DO_WHAT_AT_THE_END_AND_WHO_IT_IS_FOR}}
- **In:** {{WHAT_IS_IN}}
- **Out:** {{WHAT_WAITS_FOR_A_LATER_STAGE}}
- **Features:** {{WHOLE_FEATURES; A_SPLIT_FEATURE_SHOWS_ITS_EXACT_REQUIREMENTS}}
- **Walking skeleton (stage 1 only):** {{ONE_THIN_JOURNEY_THROUGH_THE_MAIN_MODULES_AND_SERVICES_BUILT_FIRST}}
- **Prerequisites:** {{EACH_WITH_ITS_SOURCE_AND_WHETHER_PRODUCT_OR_TECHNICAL}}
- **Constraints:** {{DEADLINES_BUDGET_PROVIDERS_WHAT_MUST_NOT_BE_LIVE_EARLY}}
- **Risks and probes:** {{THE_ASSUMPTION_THAT_HURTS_MOST_IF_WRONG_AND_ITS_SMALLEST_PROBE}}
- **Why this order:** {{WHY}}
- **What proves it done:** {{THE_ROWS_AND_JOURNEYS_THAT_MUST_PASS}}
- **What to watch once live:** {{WHAT_TO_WATCH}}
- **Effort (an estimate):** {{S_M_OR_L}}
- **Counts:** {{N}} requirements, {{N}} rows, {{N}} journeys, {{N}} new outside services

## Stage 2 — {{STAGE_NAME}}

- **Outcome:** {{…}}
