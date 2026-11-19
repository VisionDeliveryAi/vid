---
name: vid-next
description: GitHub manual — one call, which the owner makes by hand: connect, read GitHub (and Slack when set up), then show what is not yet with the team, the team's changes, the re-plan triggers in their tiers, the warnings and the moves. In phase 1 it posts nothing to the team's repositories and does no move. Use when the owner says "vid next", or "/vid next <moves>".
---

# /vid:vid-next

The call's order, nothing more: every tier, warning, count and check is in a script or a called skill.

0. **The mode.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/next.sh" mode`. A refusal names the verb that fits: say it, and end.
   Nothing is written.
1. **Connect.** Invoke the `vid-connect` skill (the Skill tool) and do its start. Where it ends the call, end.
2. **ViD's own work by its rules.** Off in this phase: say in one line that it starts in a later phase.
3. **Read.** Invoke the `vid-read` skill.
4. **Triggers, warnings, moves.** Invoke the `vid-triggers` skill.
5. **Show, and end.** The lines as `next.sh triggers` printed them. With `/vid next <moves>`, say for each move named that
   it is done from its phase, as its line says; nothing is done. Then vid-connect's end: the records saved, the lock
   freed.

Nothing goes to the code repository, the spec repository or Slack.
