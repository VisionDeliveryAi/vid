---
name: vid-mode
description: GitHub manual — `/vid mode manual` switches a ticket-mode project to GitHub manual and takes stock of the tickets already published; run again in GitHub manual, after any hand publish, amendment or spec application, it takes stock again. It posts nothing to the team's repositories. Use when the owner says "vid mode manual", or wants ViD to take stock of the published tickets.
---

# /vid:vid-mode

The switch's order, nothing more: every step and check is `checks/mode.sh`'s (GM-1 S2), each refusal printed by it.

1. **What the owner brings.** Ask for what is missing, each a file or words of theirs:
   - the register of the published step tickets, `<issue number> <step id>` a line;
   - the plan block, in the plan grammar `planner.sh check` takes;
   - the project's PLAN.md;
   - the commit the published tickets were written from (`--applied`; on a run in GitHub manual, only when it moves);
   - coming from GitHub auto, their words that DevAgent is stopped.
2. **The review.** When `sh checks/planner.sh rows --added` prints rows, spawn a fresh agent (the Agent tool,
   general-purpose, no model override) with skills/vid-plan/passes/row-review.md, PRD.md, PLAN.md and those rows verbatim, and nothing
   else, as /vid plan does; save its output under `.vid/plan/` for `--review`. Run it in the foreground. With no row added, there is nothing
   to review: the switch records that itself.
3. **The switch.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/mode.sh" manual --register <f> --plan <f> --plan-md <f> [--applied
   <c>] [--devagent "<their words>"] [--review <f>]`, then by its exit:
   - 3: each `ask <key>` line is a setup question. Ask each as /vid plan's setup asks it, record the answer with
     `sh checks/planner.sh setup <key> <answer> --words "<their words>"`, and run the switch again. The answer to
     `state-repo` is also the owner's yes to make that repository, private.
   - 4: the refresh of `checks/` waits, as in vid-connect: ask once; on a yes run again with `--refresh-yes`, on a no run
     `sh checks/connect.sh refresh-no "<their words>"` and end.
   - 1: say each refusal in plain words. When the page is written, show it to the owner
     (`.vid/pages/PLAN-PAGE.html`) and tell them what it holds, counts only. Rows to place need their words accepting
     them (`--to-place "<their words>"`); the ratification needs their yes (`--words "<their words>"`). Run the switch
     again with them. Any other refusal is fixed first; the next run goes on from what this one wrote.
   - 0: say what it recorded, line by line: the tickets taken over, those taken over from the body, those not taken
     over, the rows to place, the rows that differ at the applied commit, and the mode.

Three sets of the owner's words, each their own: DevAgent stopped, the rows to place, the ratification. Never one for
another.
