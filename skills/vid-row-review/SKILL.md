---
name: vid-row-review
description: Internal — the fresh agent's review of the rows ViD adds to the ratified inventory, one text for every caller (GM-4 F12) — vid-plan's sitting, vid-mode's switch, vid-replan's analysis and /vid next's implement-replan `--review`. It spawns the reviewer with the pass brief, PRD.md, PLAN.md and the rows verbatim, and saves its output for the caller's script, which records it. It records nothing itself and is no verb: each caller's own command runs it.
user-invocable: false
---

# vid-row-review

One job: the rows ViD appended reviewed by a fresh agent, its output saved as a file. What counts as a finding, the record of the
review and the rounds are the caller's script's: `planner.sh review --in <file>` (vid-plan), `mode.sh … --review <file>` (vid-mode),
`replan.sh analyse` reading `.vid/next/candidate/review`, in the vid-replan skill; `implement-replan "<words>" --review "<file>"` (/vid next).

1. **The rows.** The caller's: `sh checks/planner.sh rows --added` (vid-plan, vid-mode), or `sh checks/planner.sh rows --added
   --at HEAD` (vid-replan, and implement-replan's `--review`). With no row printed there is nothing to review: say so, spawn none,
   and the caller's script records that itself.
2. **The reviewer.** Spawn a fresh agent (the Agent tool, general-purpose, no model override: it runs on the session's, claude-opus-5-5) with skills/vid-plan/passes/row-review.md, PRD.md, PLAN.md and those rows verbatim, and nothing else: it judges the rows ViD appended alone, the inventory's being the owner's, ratified.
   Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.
3. **The file.** Save its output, as it gave it and never edited, where the caller names: under `.vid/plan/` (vid-plan, vid-mode),
   `.vid/next/candidate/review` for the vid-replan skill, or the file implement-replan's `--review` names. Hand back the file's path and its
   count of `finding` lines, never a score.
