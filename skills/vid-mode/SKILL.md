---
name: vid-mode
description: GitHub manual — `/vid mode manual` switches a ticket-mode project to GitHub manual and takes stock of the tickets already published; run again in GitHub manual, after any hand publish, amendment or spec application, it takes stock again. It posts nothing to the team's repositories. Use when the owner says "vid mode manual", or wants ViD to take stock of the published tickets.
---

# /vid:vid-mode

The switch's order, nothing more: every step and check is `checks/mode.sh`'s (GM-1 S2), each refusal printed by it.

1. **Nothing asked first** (GM-3 S1). The switch finds its own inputs: the register from GitHub, the plan block, PLAN.md
   and the applied commit from ViD's records, each printed `found …` with where it came from. Ask the owner nothing before
   the first run, except, coming from GitHub auto, their words that DevAgent is stopped.
2. **The review.** When `sh checks/planner.sh rows --added` prints rows, spawn a fresh agent (the Agent tool,
   general-purpose, no model override) with skills/vid-plan/passes/row-review.md, PRD.md, PLAN.md and those rows verbatim, and nothing
   else, as /vid plan does; save its output under `.vid/plan/` for `--review`. Run it in the foreground. With no row added, there is nothing
   to review: the switch records that itself.
3. **The switch.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/mode.sh" manual [--devagent "<their words>"] [--review <f>]`, then by its exit:
   - 5: each `need <input> — <where ViD looked>` line is an input ViD could not find. Ask the owner for those alone, each a
     file or a commit of theirs, saying where ViD looked: the register of the published step tickets (`--register`,
     `<issue number> <step id>` a line), the plan block in the plan grammar `planner.sh check` takes (`--plan`), the
     project's PLAN.md (`--plan-md`), the commit the published tickets were written from (`--applied`), and, when the
     tickets quote rows the spec lacks, the copy they were written from (`--from <folder>`, GM-3 S2: its INVENTORY.md, and
     its PLAN.md and plan records where the project holds none). Run the switch again with them; each one given overrides
     what ViD would find.
   - 3: each `ask <key>` line is a setup question. Ask each as /vid plan's setup asks it, record the answer with
     `sh checks/planner.sh setup <key> <answer> --words "<their words>"`, and run the switch again. The answer to
     `state-repo` is also the owner's yes to make that repository, private.
   - 4: the refresh of `checks/` waits, as in vid-connect: ask once; on a yes run again with `--refresh-yes`, on a no run
     `sh checks/connect.sh refresh-no "<their words>"` and end.
   - 1: say each refusal in plain words. When the page is written, show it to the owner
     (`.vid/pages/PLAN-PAGE.html`) and tell them what it holds, counts only. Rows to place need their words accepting
     them (`--to-place "<their words>"`); the ratification needs their yes (`--words "<their words>"`). Rows to take over
     (`take-over-row` lines) need their yes to write those rows into the spec, on the commit the tickets were written from
     and at HEAD (`--take-over "<their words>"`); a `take-over-refused` row has no line in the copy matching the ticket's
     quote: say which and why, and write none. Run the switch again with them, the same flags kept; a take-over already
     made is found recorded and never asked again. Any other refusal is fixed first; the next run goes on from what this
     one wrote.
   - 0: say what it recorded, line by line: the inputs found and where each came from, the tickets taken over, those taken over from the body, those not taken
     over, the rows to place, the rows that differ at the applied commit, the take-over commit and the rows added at HEAD,
     the rows held since and left as they are, the rows taken out of steps not published (and a step left with none, taken
     out), and the mode.

Four sets of the owner's words, each their own: DevAgent stopped, the take-over, the rows to place, the ratification.
Never one for another.
