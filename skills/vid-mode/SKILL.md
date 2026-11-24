---
name: vid-mode
description: GitHub manual and GitHub auto, both ways — `/vid mode manual` switches a ticket-mode project to GitHub manual and `/vid mode auto` switches it back to GitHub auto, each taking stock of the tickets already published; run again in the mode it is in (in GitHub manual after any hand publish, amendment or spec application), it takes stock again. The switch to auto is refused while an open ticket has sub-issues, a change is pending or a row is to place, and until the plan is ratified again in GitHub auto in the owner's words. It posts nothing to the team's repositories. Use when the owner says "vid mode manual" or "vid mode auto", or wants ViD to take stock of the published tickets.
---

# /vid:vid-mode

The switch's order, nothing more: every step and check is `checks/mode.sh`'s (GM-1 S2; GM-4 F13), each refusal printed by it.
`/vid:vid-mode auto|manual`: `manual` switches to GitHub manual, or takes stock again in it; `auto` switches from GitHub manual
to GitHub auto, or takes stock again in it (GM M2). From any other mode, `auto` is refused.

1. **Nothing asked first** (GM-3 S1). The switch finds its own inputs: the register from GitHub and ViD's record, the plan block, PLAN.md
   and the applied commit from ViD's records, each printed `found …` with where it came from. Ask the owner nothing before
   the first run, except, coming from GitHub auto to manual, their words that DevAgent is stopped.
2. **The review.** Invoke the `vid-row-review` skill (GM-4 F12) with the rows `sh checks/planner.sh rows --added` prints; its
   output saved under `.vid/plan/` is the switch's `--review`. With no row added, there is nothing to review: the switch records
   that itself.
3. **The switch.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/mode.sh" manual [--devagent "<their words>"] [--review <f>]`, or
   `sh "${CLAUDE_PLUGIN_ROOT}/checks/mode.sh" auto [--review <f>]`; `--applied, --from, --take-over, --devagent and --to-place`
   are the switch to manual's alone, never passed to auto. While it runs, the panel beside the chat shows its parts, and at a stop
   what it needs; the script says them (FB-3 D2), and you write none. Then by its exit:
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
     `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" refresh-no "<their words>"` and end.
   - 1: say each refusal in plain words. When the page is written, show it to the owner
     (`.vid/pages/PLAN-PAGE.html`) and tell them what it holds, counts only. Rows to place need their words accepting
     them (`--to-place "<their words>"`; on a take-stock only the rows not accepted before, or changed since, are listed and
     asked); the ratification needs their yes (`--words "<their words>"`; on a take-stock only when the spec or the plan is not
     as last ratified). Rows to take over
     (`take-over-row` lines) need their yes to write those rows into the spec, on the commit the tickets were written from
     and at HEAD (`--take-over "<their words>"`); a `take-over-refused` row has no line in the copy matching the ticket's
     quote: say which and why, and write none. Run the switch again with them, the same flags kept; a take-over already
     made is found recorded and never asked again. A `stages STAGES.md — <why>` flag is a cut the stage court refuses: the fix
     is a commit of the spec, given with `--applied`. Any other refusal is fixed first; the next run goes on from what this
     one wrote.
     The switch to auto's refusals (GM M2), each said as mode.sh prints it, the mode left GitHub manual: `no-auto sub-issues`
     (an open ticket has sub-issues: DevAgent works whole tickets, so the team closes or merges them first), `no-auto pending`
     (a change is pending: the apply brings it to the team, through /vid next), `no-auto to-place` (a row is to place: /vid
     next's re-plan places it). Then the plan is ratified again in GitHub auto: the page shown, and the owner's yes, `--words
     "<their words>"`; until then the switch is refused.
   - 0: say what it recorded, line by line: the inputs found and where each came from, the tickets taken over, those taken over from the body, those not taken
     over, those on record GitHub no longer has (`not-found`), those that look accepted (`looks-accepted`, below), the rows and the ratification kept (`to-place-kept`,
     `ratified-kept`: nothing was asked), each ticket the switch to auto finds `unlabelled`, the rows to place, the rows that differ at the applied commit, the take-over commit and the rows added at HEAD,
     the rows held since and left as they are, the rows taken out of steps not published (and a step left with none, taken
     out), and the mode: `mode: GitHub manual, recorded` or `mode: GitHub manual, re-taken`, `mode: GitHub auto, recorded` or
     `mode: GitHub auto, re-taken`. Once in GitHub auto, /vid:vid-run works the tickets.
     In GitHub manual a last line names the text that tells the team what its reports hold (FB-3 A3):
     `team-reports .vid/plan/TEAM-REPORTS.md new`, `changed` or `unchanged`. At `new` or `changed`, show the owner that file whole
     and say it is theirs to hand to the team; ViD posts it nowhere. At `unchanged`, nothing.
     `/vid:vid-accept-step reports` shows it again at any time.
     `engines not named — …` (FB-3 E2): no engines are on record. Ask the owner which engines the team runs, the primary first, and on
     their words do `/vid:vid-accept-step engines "<them>" "<words>"` (the vid-accept-step skill) once this call has ended.

**Stories already accepted** (FB-3 E1). In GitHub manual the call prints `looks-accepted #<n> <step> <commit or -> <why>` for each ticket
on record whose issue is closed and which ViD has not accepted. It ends nothing and records nothing. After the call has ended (exit 0),
show the list once, in plain words: each ticket's number, its step and its decision comment (the commit, by whom, when), or that it was
closed with none; and what is missing, ViD holds no test evidence for them. Ask once whether the owner accepts them. On their words,
under the vid-accept-step skill's own start and end (its step 1),
`sh "${CLAUDE_PLUGIN_ROOT}/checks/round.sh" accept --tickets "<n>[@<commit>] …" --outside "<their words>"`, the tickets they named, each
line it prints said as that skill says it; a commit only where they gave one. No answer, or a no: write nothing; the next take-stock
lists them again.

**What stays readable after the switch** (GM-4 F13): what GitHub manual recorded at a step's end is read in both modes, and the
switch keeps it as it is: each ticket's `step-` decision files and merge lines, and the units' merges in `.vid/decide/unit-merges`,
so the next round in GitHub auto reads each acceptance as a merge.

Four sets of the owner's words, each their own: DevAgent stopped, the take-over, the rows to place, the ratification (the
switch to auto takes the ratification's alone). Never one for another. A switch asks each; a take-stock asks only what is new.
