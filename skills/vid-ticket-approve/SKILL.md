---
name: vid-ticket-approve
description: The dev side's stand-in reviewer for a ticket-mode trial — in its own conversation and a plain clone, loops over the open, non-draft pull requests on vid/<n> branches, checks each (CI green on the reviewed head, the ticket's tests present and unchanged, paths inside the step, the return block), reads the diff against the ticket, then merges bound to the reviewed head or sends it back with its reasons. Comments, never formal reviews. Never grades, never changes the plan, never pushes. Use when the owner says "vid ticket-approve" with a repository, for a trial of ticket mode.
---

# /vid ticket-approve (v0.26.10.9 R23)

The dev team's review before the merge — the first of ticket mode's two
gates; ViD's grade after it (/vid replan) is the second. It works in its
own conversation and its own clone of the code repository, through the
plugin's `github.sh` (`sh "${CLAUDE_PLUGIN_ROOT}/checks/github.sh" …`), and
refuses to run in a folder holding ViD's `.vid/`.

## Start

`github.sh clone <owner>/<name> <dir> --labels-prefix <prefix>`, then work
in `<dir>`; `github.sh session --verb ticket-approve` (one line to
`.git/vid/sessions`, for the trial's usage count).

## The loop

`github.sh review --list` names the open, non-draft pull requests on
`vid/<n>` branches. For each:
1. **`github.sh review <pr>`** keeps the head commit it reviews and prints
   one line per check: the code repository's CI green on that head; each of
   the ticket's test files present and byte-identical to the ticket, or to
   the correction last sent in a ticket comment; every changed path under
   the step's `modules:` or the plan's `shared:` paths (both quoted in the
   ticket), or the ticket's tests — anywhere for the skeleton ticket; the
   block passing `ticket.sh return-check`.
2. **Read the diff against the ticket** for what no check sees: does the
   change do what the ticket asks, and nothing it doesn't?
3. **Merge** — `github.sh merge <pr>`: `gh pr merge --merge
   --match-head-commit <the reviewed head> --body "Stand-in: approver"`, and
   a comment `merged` with the checks. GitHub refuses the merge if the head
   moved; review the new head. **Or send back** — `github.sh review <pr>
   --send-back <reasons file>`: a comment `sent back` with each reason, and
   the pull request returned to draft. Both are comments, never formal
   reviews: in the trial one login is on both sides, and GitHub does not let
   a login approve its own pull request.

Stop when the list is empty, saying so in one line.

## It never

grades, changes the plan, or pushes.
