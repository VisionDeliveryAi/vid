---
name: vid-triggers
description: A ViD call's lines in ticket mode, in both GitHub modes: what is not yet with the team, counted once by kind; the team's changes to published tickets; the re-plan triggers in their tiers, with their evidence; the warnings and the moves; and the plan page, its show. Invoked by /vid next, and by /vid run after a step that printed something new, which re-plans from its lines through the vid-replan skill; the owner's command `/vid:vid-triggers` shows them at any time. Use when the owner says "vid triggers" or asks what may call for a re-plan.
---

# /vid:vid-triggers

One job: `sh checks/next.sh triggers`, and show its lines as it prints them. The count, the tiers, the warnings and the
moves are its own; a publish's warnings are `plan.sh warnings`' lines, printed after its move (GM-4 K9). This skill adds none and
drops none. It reads ViD's records and `.vid/round/read` (vid-read's), and writes nothing. Its lines name their evidence: say them
in plain words, keeping each number as printed.

**Called by the owner** as `/vid:vid-triggers`, in either GitHub mode: inside /vid run's own conversation it uses the run's lock and
leaves it held; anywhere else the vid-connect skill's start first and its end after, however the call ends (GM-4 S0). The vid-read skill's read
comes first, so the lines judge what GitHub holds now.

**In /vid run** (GM-4 K9), after a step that printed something new: its lines, said once each; a trigger among them is a line that
may call for a re-plan, which the vid-replan skill's GitHub auto paragraph makes.

## The plan page

In GitHub manual, /vid next's call writes it (`page <path>`, `plan.html`) and its show is this skill's, once vid-connect's end
has saved the records and freed the lock, so no lock is held while a publish waits on the owner. Read `plan-page:` in
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
