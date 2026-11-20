# TW in GitHub manual (GM-2 T3, T5)

Read by the ticket writer (`SKILL.md` beside this file, "Before any work", step 1) when the project is in GitHub manual.

When `sh checks/next.sh mode` prints `mode: GitHub manual`, TW runs only inside a move the owner names in `/vid next`
(`checks/next-move.sh`), never in a round, and the tickets take the project's own layout. The rest of this skill holds,
but for these:
- **The go.** No `publish-approved` event is asked: each publish carries the owner's words instead (`tw-post --words`),
  kept on its log line. The gate's uncommitted-change check covers PLAN.md and the issue form alone. Everything the team
  is given is read at the applied commit (`.vid/tw/applied`).
- **The first post** is made in the project's own issue form, `issue-form:` in `.vid/tw/settings`, and is refused
  without it. The issue's body is the form filled in; every part of the full ticket goes in as a comment; the issue is a
  sub-issue of `issue-parent:` when the setup names one, and blocked by the tickets of the steps it builds on. A step it
  works against through fakes, or one with no ticket yet, is named in the body and not linked. The title is the form's
  first line, or the one the owner gives (`--title`).
- **An amendment** never changes the title. It changes only body text ViD wrote that still stands as ViD wrote it; every
  part goes in again as new comments, the earlier part comments are marked replaced, and the notice names what changed
  and each text ViD left because the team changed it.
- **What is owed.** `writer.sh due` owes an amendment only when the step's rows changed, never for wording alone. An
  amendment or a withdrawal is a move, done only when the owner names it in his words.
- **The order of a publish** is `next-move.sh`'s: the export, the sync, the round's read and the handovers, the admission,
  the write and its check, the post, the records saved.
