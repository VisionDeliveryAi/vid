---
name: vid-next
description: GitHub manual — one call, which the owner makes by hand: connect, read GitHub (and Slack when set up), then show what is not yet with the team, the team's changes, the re-plan triggers in their tiers, the warnings and the moves; then do the moves the owner names in the call, in his order, and write the plan page. Use when the owner says "vid next", or "/vid next <moves>".
---

# /vid:vid-next

The call's order, nothing more: every tier, warning, count, check and every move's rule is in a script or a called skill.

0. **The mode.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/next.sh" mode`. A refusal names the verb that fits: say it, and end.
   Nothing is written.
1. **Connect.** Invoke the `vid-connect` skill (the Skill tool) and do its start. Where it ends the call, end.
2. **ViD's own work by its rules.** Off in this phase: say in one line that it starts in a later phase.
3. **Read.** Invoke the `vid-read` skill.
4. **Triggers, warnings, moves.** Invoke the `vid-triggers` skill.
5. **Show.** The lines as `next.sh triggers` printed them. With no move named, `sh "${CLAUDE_PLUGIN_ROOT}/checks/next-move.sh" call`:
   it keeps what was shown and writes the plan page. Say its lines.
6. **The moves named.** With `/vid next <moves>`, in place of step 5's call:
   `sh "${CLAUDE_PLUGIN_ROOT}/checks/next-move.sh" call <move> [-- <move>]…`, each move as the owner named it, in his
   order, `--` between two, one argument each, quoted (a bare `#` would open a shell comment), his words the last. Each
   move is named by its kind and its subject, never by a number:
   - `publish <step> "<words>"`, then `--title "<title>"` when he gives the title in his words;
   - `amend "#<n>" "<words>"`, `withdraw "#<n>" "<words>"`;
   - `team-change "#<n>" <id> yes "<words>"`, or `no`;
   - `answer "#<n>:<k>" "<words>"`, or `answer "#<n>:<k>" there "<words>"` when he answered on GitHub himself;
   - `done "<kind> <subject>" "<words>"`, a to-do of the page done in his words;
   - `decline <what> ["<subject>"] "<words>"`;
   - `engines "<primary> <other>…" "<words>"`.

   Never pass a move he did not name, and never words that are not his. Say each line it prints, in plain words: what was
   done; what was refused, at which step and in what words; what is shown again and why (not done: he names it again if he
   still wants it); then the lines after the moves.
7. **Save.** vid-connect's end: the records saved, the lock freed. Run it however the call ends once the start held the
   lock, a failure included.

**After the call: the plan page.** Only once vid-connect's end has saved the records and freed the lock, so no lock is held
while a publish waits on the owner. The script's `page <path>` line names the page, `plan.html`. Read `plan-page:` in
`.vid/tw/settings`:
- No such line, `none`, or no Artifact tool in this session: nothing is published; say the page's path.
- `artifact`, the owner's yes, with no link yet: `sh checks/next-move.sh shell "<the page's path>"`
  writes the fixed shell beside the page. Publish the shell as a new private artifact (the Artifact tool), with the page as
  its one data file (`files`, published as `plan.html`). Keep its link in the setup:
  `sh checks/planner.sh setup plan-page "<the link>" --words "the plan page's link, on the owner's yes to plan-page: artifact"`.
- A link: read that artifact first (the Artifact tool, `action: "read"`), as the tool asks of a page this conversation
  did not publish. Then publish the new data file to that same link: `url` the link, the shell again as its page, `files`
  with `plan.html` the page's path.
- A publish refused or failed: say so in one line, with the page's path. Never give the link as current then, and
  never fail the call for it.

Nothing goes to the code repository, the spec repository or Slack but what a move named in the call posts.
