---
name: vid-next
description: GitHub manual — one call, which the owner makes by hand: connect, read GitHub (and Slack when set up), then show what is not yet with the team, the team's changes, the re-plan triggers in their tiers, the warnings and the moves; then do the moves the owner names in the call, in the owner's order, and sort the owner's list, in the panel beside the chat. Use when the owner says "vid next", or "/vid next <moves>".
---

# /vid:vid-next

The call's order, nothing more: every tier, warning, count, check and every move's rule is in a script or a called skill.

0. **The mode.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/devagent-start.sh" mode`, the one mode command (GM-4 F15). `none`,
   with no `ratified` line in `.vid/plan/ratified` (FB-2 A2: no plan was ever approved): invoke the `vid-plan` skill (the Skill
   tool) and do its sitting, the setup questions first. At its page end the turn, asking for the owner's words; nothing is written to GitHub.
   The owner's yes is the sitting's GitHub manual route, `/vid mode manual … --words "<the owner's yes>"` (the `vid-mode` skill);
   then go on at step 1. If the owner answers that ViD's own DevAgent works the tickets, the sitting ends as in GitHub auto: say in
   one line that /vid:vid-run works this project, and end. Otherwise, unless it prints `manual`, say in one line that this project
   is not in GitHub manual and the verb that fits, and end: `auto`, /vid:vid-run works its tickets; `team`, an old answer of the
   retired team mode, /vid:vid-mode manual moves it over (FB-1 C1). Nothing is written.
1. **Connect.** Invoke the `vid-connect` skill (the Skill tool) and do its connect, for every caller. Where it ends the call,
   end. Its start opens the call's stage: every move below runs in it. The panel beside the chat shows the call's parts as they
   run; the scripts say them (FB-3 D2).
2. **ViD's own work by its rules,** behind the owner's switch: `sh "${CLAUDE_PLUGIN_ROOT}/checks/next.sh" own-work`.
   - Unless it prints `on`: say in one line that ViD's own work is off, with the move that turns it on, `own-work on "<your words>"`, and run nothing here. Each `context ask` line step 5 shows is then said with its command, as the vid-accept-step skill says it.
   - With it on, these in order, one line each, every line they print said as its skill says:
     - Invoke the `vid-accept-step` skill (the Skill tool): `sh "${CLAUDE_PLUGIN_ROOT}/checks/round.sh" step`, then `sh "${CLAUDE_PLUGIN_ROOT}/checks/round.sh" accept <n> <commit>` for each `decide` line it printed;
     - Invoke the `vid-step-close` skill (the Skill tool): the close's lines those printed;
     - Invoke the `vid-stage-close` skill (the Skill tool): the stage's lines those printed, the end among them;
     - Invoke the `vid-deploy` skill (the Skill tool): the okays' and the deploys' lines those printed;
     - Invoke the `vid-grade` skill (the Skill tool): the grade asks' lines those printed;
     - `sh "${CLAUDE_PLUGIN_ROOT}/checks/round.sh" asks`: the owed asks, okays and stage close, the step's close among them, each said as its skill says.
3. **Read.** Invoke the `vid-read` skill.
4. **Triggers, warnings, moves.** Invoke the `vid-triggers` skill.
5. **Show.** The lines as `next.sh triggers --short` printed them. With no move named, `sh "${CLAUDE_PLUGIN_ROOT}/checks/next-move.sh" call`:
   it keeps what was shown in the owner's queue and prints the re-plan's question when one is due: a `proposal due` line, its yes the
   move it names. No list is said in the chat: the panel has it, once sorted (step 7).
6. **The moves named.** With `/vid next <moves>`, in place of step 5's call:
   `sh "${CLAUDE_PLUGIN_ROOT}/checks/next-move.sh" call <move> [-- <move>]…`, each move as the owner named it, in the
   owner's order, `--` between two, one argument each, quoted (a bare `#` would open a shell comment), the owner's words the
   last. Each move is named by its kind and its subject, never by a number:
   - `publish …`: the `vid-tickets` skill's move, named as that skill gives it;
   - `amend …`: the `vid-tickets` skill's move, named as that skill gives it;
   - `withdraw …`: the `vid-tickets` skill's move, named as that skill gives it;
   - `reopen …`: the `vid-tickets` skill's move, named as that skill gives it;
   - `team-change …`: the `vid-answer` skill's move, named as that skill gives it;
   - `answer …`: the `vid-answer` skill's move, named as that skill gives it (a draft of the door is answered there too);
   - `done …`: the `vid-answer` skill's move, named as that skill gives it;
   - `decline …`: the `vid-answer` skill's move, named as that skill gives it;
   - `engines …`: the `vid-accept-step` skill's move, named as that skill gives it;
   - `own-work …`: the `vid-accept-step` skill's move, named as that skill gives it;
   - `walk-stage …`: the `vid-stage-close` skill's move, named as that skill gives it;
   - `read-walk …`: the `vid-stage-close` skill's move, named as that skill gives it;
   - `write-summary …`: the `vid-stage-close` skill's move, named as that skill gives it (its summary written as that skill says);
   - `planning-analysis …`: the `vid-replan` skill's move, named as that skill gives it;
   - `implement-replan …`: the `vid-replan` skill's move, named as that skill gives it; what its listed line says is missing for its
     posts (the `needs` lines of `replan.sh`) is said with it, with each command, before the owner's yes (FB-4 A3).

   Invoke each named move's skill (the Skill tool) first, unless this call has invoked it already. Never pass a move the owner did not name, and never words that are not theirs. Say each line it prints, in plain words:
   what was done; what was refused, at which step and in what words; what is shown again and why (not done: the owner names
   it again if they still want it); then the lines after the moves.

   **The analysis.** Invoke the `vid-replan` skill (the Skill tool) only when the script printed `checked
   planning-analysis`, with that move's arguments as the owner named them, after the other moves and before step 7; then the
   call's listing made again from the new proposal: `sh "${CLAUDE_PLUGIN_ROOT}/checks/next-move.sh" call`, with no move, its
   lines said as step 5 says them. The listing printed before the analysis offers the moves as they stood without it; this one
   keeps the analysis's own move in the owner's queue, so `/vid next implement-replan "<their words>"` applies it next call.
7. **Sort,** in a call with moves or without, after the moves and the analysis's listing. Invoke the `vid-sort` skill (the Skill tool): it sorts what the call
   left open into the owner's panel. Say its one line, the last of the call's; a sort that could not be made stops nothing.
8. **Save.** vid-connect's end: the records saved, the lock freed. Run it however the call ends once the start held the
   lock, a failure included.

**After the call,** once vid-connect's end has saved the records and freed the lock: when it made a re-plan proposal, the
`vid-replan` skill's show of it, its section "The re-plan page". Where there is no panel, `/vid:vid-answer backlog` (`sh checks/queue.sh backlog`) says the list, when the owner asks.

Nothing goes to the code repository, the spec repository or Slack but what a move named in the call posts.
