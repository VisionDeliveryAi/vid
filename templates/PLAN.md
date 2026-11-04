# {{PROJECT_NAME}} — PLAN

> The plan in ticket mode, written by ViD's planner (PL, vid-plan) on the
> ratified INVENTORY.md, PRD.md and STAGES.md, and ratified by the owner on
> the plan page. Every inventory line is a planned row, word for word
> (`sh checks/planner.sh rows`). The rows ViD adds are appended to
> INVENTORY.md, `origin: plan`; this file holds only the owner's classes
> and the standing lines. The steps are the plan block in RUN-STATE, in
> develop's form (`sh checks/plan.sh change` records each change). Product
> text only: no file path, no test, no command. `sh checks/planner.sh
> check` judges it all.

## Rows

<!-- The owner's class lines and the four standing lines:
       <row id> | moved: STAGE-<k> A-NNN
       <row id> | limit: A-NNN
       standing <rehearsal|sign-in|fields|work> | <row ids, or none: <why>>
     The rows ViD adds go into INVENTORY.md's rows block, in the schema's own form, the next free number of the
       class, `| origin: plan <item id>` last, and nothing else of the inventory changes:
       hostility | HOS-<n> | <attempt> | protects: <item> | disable: the guard that protects <item> | owed: spec-only — ticket | origin: plan <item>
         for an effective pilot T0 requirement or invariant that no hostility row protects;
       ROW-<n> | behavior | <item> | n/a | n/a | <promise>. Fails if <fail-if> | <item> | owed: paid by /vid deploy gate <1|2|3> — <what it observes> | origin: plan <item>
         the rehearsal row (gate 1) and the two sign-in rows (gates 2 and 3);
       rule | RULE-<n> | <statement> | sites: <the places, in words> | 1 | owed: spec-only — ticket | origin: plan <item>
         the two census rows.
     The standing lines name the rows that make each promise, the inventory's or ViD's, or say none: and why:
       rehearsal — when the PRD keeps data, a row owed to the rehearsal: the kept data survives the move to a new
         version (never none: while it keeps data);
       sign-in — when the product signs users in, a row owed to staging, each role's test sign-in works there with
         no password, and one owed to production, none works there, in the stage of the first such role;
       fields — when it collects fields from users, a rule row: every collected field is acted on beyond
         validation and display;
       work — when it routes work to queues or schedules, a rule row: every routed task and every schedule has a
         consumer.
     moved: puts a row in a later stage than its own; limit: makes it a known limit. Each A-NNN is an answer row
       of PRD.md, the owner's. A class line names a row, never a transition or a record.
     A row's class is read, never written: a known limit (limit:), moved by the owner (moved:), deploy-owed in its
       stage (an owed- mark or seam), planned to its stage, later phase (its items all phase: later), or a record
       (a difference with no paying step). -->

```vid-rows
standing rehearsal | {{ROW_IDS_OR_NONE}}
standing sign-in | {{ROW_IDS_OR_NONE}}
standing fields | {{ROW_IDS_OR_NONE}}
standing work | {{ROW_IDS_OR_NONE}}
```

