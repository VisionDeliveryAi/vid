---
name: vid-accept-step
description: A step's end in ticket mode, in both GitHub modes — the team says a ticket's work is done, ViD decides it accepted or not yet by its decision rules, a held test goes to the owner, the merge and the dev side's decisions are recorded, a ticket closed before its acceptance is told. GitHub auto decides a pull request's ask at its head in /vid run's round; GitHub manual decides only a ticket, at a commit of main (GM M8), through one entry, `round.sh accept`. `/vid:vid-accept-step <ticket> [<commit>]`; /vid run's round and /vid next's step 2 run the same entries. Use when the owner says "vid accept-step", asks ViD to decide a ticket now, or names the engines.
---

# /vid:vid-accept-step (GM-4 K2)

The order of a step's end and how each line is said, nothing more: what is decided, posted and recorded, and every refusal,
are the scripts' (`checks/round.sh`, `checks/decide.sh`, `checks/results.sh`, `checks/decisions.sh`; each header says them).
Every decision is made by the existing decision rules, unchanged, in both modes.

## The owner's command

`/vid:vid-accept-step <ticket> [<commit>]`: `sh checks/round.sh accept <ticket> [<commit>]` (GM-4 E13), one argument each. It
decides one ticket at one commit: in GitHub manual a commit of the code repository's main, on its first-parent line, and with no
commit named the newest one there holding a head report of that ticket; in GitHub auto the open pull request naming the ticket,
at its head, as the round decides it, at the owner's word.

1. **The lock.** Inside /vid run's own conversation (this session holds the run's lock), and inside /vid next's step 2 (the
   call's start holds it), run the entry alone: the lock stays held. Anywhere else, the vid-connect skill's start first,
   `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start`, and its end after, `sh checks/connect.sh end`, however the entry ends (GM-4 S0). While another
   session holds the lock, the start says so, and nothing is decided.
2. **The entry.** It makes the one read and fetches the reports itself first, so a report just pushed is seen; it posts only
   that ticket's decision. Say each line it prints, as below. Exit 0: its lines said. 1: an `error …` line, said as it is. 3: the
   lock was lost: nothing more is written.

When its conditions are not met it posts nothing, and its line says what is missing: a head report not in, a ticket not
published, a ticket closed before its acceptance.

## In both modes

| Line | What you do |
|---|---|
| `decisions recorded pr=<p> n=<k> <ids>`, `decisions recorded deploy=<id> n=<k> <ids>` (0.26.10.29.5, DP-1 R2) | Nothing by hand: the round recorded the dev side's decisions, from a merged pull request's Decisions section or a deploy report's `decision:` lines, in DECISIONS.md, each numbered, labelled and marked `origin: dev-side`, and exported them. Later tickets they apply to quote them, an open one is amended, and the stage summary names them |
| `decisions wait draft=<n>` | Nothing: a draft waits on the owner, so the round records no decision until it is landed, declined or replaced, then records them |
| `decisions unread pr=<p>: <why>`, `decisions export failed: <why>` | Nothing the first time: the round tries again next round. Said again round after round, it is your own defect, `sh checks/queue.sh defect <its ticket's step, or the deploy's stage> "<the line>"` |
| `decisions refused pr=<p> <why>`, `decisions refused deploy=<id> <why>` | The hooks refused the dev side's lines, and nothing was written: `sh checks/queue.sh defect <its ticket's step, or the deploy's stage> "<the line>"`, and one plain line to the owner. It is not tried again; the status names it |
| `held <row>` | Its `Q<n>` line is in RUN-STATE with its recommendation: read it, change it with `sh checks/queue.sh recommend Q<n> <letter> "<why>"` only when the record says otherwise, then tell the owner in one plain message what the row promises, what it needs and the recommendation, and go on. Every other ticket goes on |
| `split <row>` | Say it once: every engine is now asked |

**A weak test's lesson.** A decision reading `failing, a weak test`: `sh checks/queue.sh lesson <rows, comma-joined> "<the cause, from the decision and the fault>"`, which the next ticket of those rows carries.

## GitHub auto

The entry is `sh checks/round.sh step`'s ask, merge and outside paths, unchanged: /vid run's round answers each unanswered
`vid: decide <head>` on a pull request, records each merge, closes its ticket's issue, and withdraws a ticket closed outside ViD.
/vid run loads this skill at its start and says these lines as it says them.

| Line | What you do |
|---|---|
| `decided <p> <head> ticket: …` | Nothing: it is posted. A `not yet` is DevAgent's to act on |
| `decided <p> <head> ticket: not yet` with `decisions missing — …` (0.26.10.29.5, DP-1 R8) | Nothing: a pull request whose description has no Decisions section, nor `Decisions: none`, is not accepted, and no row moves for it. DevAgent adds the section and asks again at the same head |
| `merged <p>` | Read the merged pull request's text, as a re-plan needs |
| `closed-outside <n> <step>` (v0.26.10.27.3) | Tell the owner once, in one line: ticket #<n> was closed on GitHub without its merge, so ViD reads it as withdrawn and writes it again. This holds for every kind of ticket, a step's, the skeleton's, a fix or a reached one, in every stage (0.26.10.29.2, R4) |
| `closed-stage-rows <s> <N>` (v0.26.10.27.3) | Tell the owner once, in one line: step <s>'s stage <N> is closed; any of its rows still open go out again in a new ticket, and the stage stays closed (0.26.10.29.2, R4; the line also prints for an older ticket already sent again) |
| `step-reopened <s> #<n>` (v0.26.10.27.3) | Nothing by hand: step <s> is open again, as ticket #<n> was closed outside ViD and its rows are owed a new ticket; its close is asked again once that ticket merges |

## GitHub manual (GM M8: only a ticket is decided, at a commit of main)

By GM M8 the team asks on the ticket's issue, a comment whose first line is `vid: decide <a full commit>`; a unit's pull request is
never decided, and a merge decides and closes nothing. `sh checks/round.sh step` decides nothing: it prints `decide #<n> <commit>` for
each ticket owed a decision, and each is decided through `round.sh accept`, the one entry of every decision here (GM-4 E13), in
/vid next's step 2 or by the owner's command. The ticket's acceptance is its merge: the step's close reads it there (the
vid-step-close skill).

| Line | What you do |
|---|---|
| `decide #<n> <commit>` | `sh checks/round.sh accept <n> <commit>`, in /vid next's step 2, its lines said as below |
| `decided #<n> <c12> ticket: …` | Posted once, on ticket #<n>'s issue: say it in one line, with each row it names. A `not yet` is the team's to act on; one naming `no Decisions section — #<p>` waits for the team to add the section to that pull request's description, or `Decisions: none`, and ask again |
| `decided #<n> <c12> ticket: not yet — not on main` | The commit asked is not on main's own line, so no row moved: say so, and that the team asks again at a commit of main |
| `accepted #<n> <c12>` | Say it once: ticket #<n> is accepted at <c12>; its acceptance is its merge, so its step's close is owed there |
| `accepted #<n> at <m12>; its close runs there` | Nothing more: the ticket was accepted already; the ask was answered at the commit asked, and nothing was decided again |
| `refused #<n> no head report on main`, `refused #<n> no head report at <c12>` | Nothing was posted: the team's head report of that ticket is not in yet. Say so, in one line |
| `refused #<n> no published ticket that is not withdrawn` | Nothing was posted: say which number was named |
| `closed #<n> not accepted — …`, `refused #<n> closed on GitHub before its acceptance: …` | Tell the owner, at every call, as the line names it: ticket #<n> was closed on GitHub before ViD accepted it, and stays told until they choose one of the ticket writer's two commands, `/vid:vid-tickets reopen #<n> "<their words>"` or `/vid:vid-tickets withdraw #<n> "<their words>"` (GM-4 E6). A ticket closed after its acceptance is not told |
| `context ask #<n> <c12> /vid:vid-accept-step <n> <c12>` | With own work off, say it with its command: the team asks ViD to decide ticket #<n> at <c12>, and `/vid:vid-accept-step <n> <c12>` decides it |
| `unit-merged <p> <ticket or ->` | Nothing: the unit's merge is on record, under the ticket its ticket line names; it decides and closes nothing |
| `context unit-ask #<p> <ticket or -> <h12>` | Say it once: pull request #<p> asks ViD to decide, which is never answered on a unit; the owner tells the team that the ask belongs on its ticket |
| `context no-ticket #<p>` | Say it once: merged pull request #<p> maps to no published ticket yet, so its decisions wait; they are read again at each call |
| `decisions wait proposal` | Nothing: a re-plan analysis is fresh, so the dev side's decisions wait for it |

## The moves, in /vid next

Named in the call and passed to `next-move.sh call` as the vid-next skill's step 6 passes every move, each with the owner's own words.

- `engines "<primary> <other>…" "<words>"`: the engines the team runs, the primary first, recorded through the one writer of the
  handed record's engines line, `sh checks/results.sh declare --engines "<them>" --words "<words>"` (GM-4 F16), the owner its
  stand-in (GM-2 T4): for a project with no skeleton ticket decided, since the skeleton's head report declares them at its
  acceptance (GM-4 E4).
- `own-work on|off "<words>"`: the owner's switch of /vid next's step 2, ViD's own work (GM §6: the phase's first write is one the
  owner names), recorded in the setup; it holds from the next call.

Say each line it prints, as the vid-next skill's step 6 says: `done engines <them>: …`, `done own-work on: …` or `off`, or what was
refused and why.
