---
name: vid-ticket-implement
description: The dev side's stand-in worker for a ticket-mode trial — works a code repository's ViD tickets as an outside team would, in its own conversation and a plain clone (no ViD courts, no ViD records there): claims a ready ticket race-free, spawns one fresh agent per ticket with only the ticket, pushes its branch and opens the pull request with the vid-return block, or a draft with its question when blocked; resumes unblocked and sent-back tickets first. Never merges, never changes the plan or ViD's repository, pushes nothing but vid/<n> branches (and an empty repository's one root commit). Use when the owner says "vid ticket-implement" with a repository, for a trial of ticket mode.
---

# /vid ticket-implement (v0.26.10.9 R22, R24)

The stand-in proves the tickets, not ViD's builder: a fresh general agent
per ticket with only the ticket, so "buildable without asking" is measured,
not assumed. It works as an outside team would — in its own conversation
(parallel workers each run their own conversation and clone), in a plain
clone of the code repository, through the plugin's `github.sh` (`sh
"${CLAUDE_PLUGIN_ROOT}/checks/github.sh" …`, written `github.sh` below), the
one file that calls `gh`, under whoever's login runs it.

**No ViD courts, no ViD records in the code repository.** Its notes and
fetched tickets go in the clone's git directory (`.git/vid/`), never
committed or pushed; no hook runs for it. github.sh refuses its subcommands
in a folder holding ViD's `.vid/`, so it never writes into the planner's
records.

## Start

1. Ask for the repository (`<owner>/<name>`), this worker's number `<k>`
   (1 when alone; decision 5: two workers in the trial) and the labels'
   prefix the planner uses; `github.sh clone <owner>/<name> <dir>
   --labels-prefix <prefix>`; work in `<dir>` from here.
2. `github.sh session --verb ticket-implement` — one line to
   `.git/vid/sessions` (the session id and its transcript path): the trial
   report counts this worker's usage from those transcripts, the main
   conversation and its subagents. Nothing is collected while it runs.
3. **The empty repository's first commit.** In a code repository with no
   commit, make the dev side's one set-up: `github.sh push main --worker
   <k>` makes one empty root commit on main (`Initial commit`, `Stand-in:
   worker-<k>`) and pushes it, once; then the owner protects main (a pull
   request before merging, 0 approvals). Every product file still comes
   through tickets.
4. **The workflow scope.** The skeleton ticket includes the code
   repository's own CI workflow, the dev side's pipeline; pushing a
   workflow file needs `gh auth status` to list the `workflow` scope —
   github.sh checks it at that push ("run `gh auth refresh -s workflow`").

## The loop, until nothing is left

`github.sh next-ticket --worker <k>` first fetches `origin` and
fast-forwards main, then answers one line:

1. **`resume <n> unblocked|sent back`** — one of this worker's tickets
   whose draft is labelled ready again with ViD's answer, or was sent back
   by the approver: spawn an agent on the same ticket with the comment
   beside it (`.git/vid/tickets/<n>/`: the ticket, ViD's comments, the pull
   request's comments). The agent checks out the existing branch, merges
   `origin/main`, applies any corrected test from the comment byte for byte
   (a file quoted whole under `#### <path>`), and continues.
2. **`next <n>`** — a new ticket: `github.sh claim <n> --worker <k>` — an
   empty claim commit unique to the claimant on the ticket's base, pushed
   only if the branch does not exist; refused, take the next ticket. It
   joins the ticket's parts (`ticket.sh fetch`) into
   `.git/vid/tickets/<n>/ticket.md`. The skeleton ticket's base is main's
   root commit.
3. **`none`** — nothing is left: stop, and say so in one line.

**One fresh agent per ticket** (a general-purpose subagent), given the
clone's path and the ticket file and nothing else of this session. It
follows only the ticket's instructions — claim done; the acceptance tests
committed first, unchanged, as their own commit; build until they pass,
using the code repository's own commands to run tests; never edit or weaken
an acceptance test; stay inside the step's modules and the shared paths —
and returns its branch and its filled vid-return block. This is ViD's
builder discipline without ViD's machinery.

**When the agent returns:** `github.sh push vid/<n> --worker <k> --pr
<description file>` — the description holds "Closes #<n>" and the block at
its end; check it first with `sh "${CLAUDE_PLUGIN_ROOT}/checks/ticket.sh"
return-check <description file> --ticket .git/vid/tickets/<n>/ticket.md`
before it is marked ready. **Blocked** (a product question, or a test that
looks wrong): `github.sh push vid/<n> --pr <description> --draft` with the
block's `questions:` or `law-needed:` filled, `github.sh label <n> --add
blocked`, and the next ticket.

## It never

changes the plan or ViD's repository, merges, grades, or pushes anything
but `vid/<n>` branches (and the one root commit above) — never a force but
the claim's create-only lease.
