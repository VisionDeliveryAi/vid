---
name: vid-accept-step
description: A step's end in ticket mode, in both GitHub modes — the team says a ticket's work is done, ViD decides it accepted or not yet by its decision rules, a held test goes to the owner, the merge and the dev side's decisions are recorded, a ticket closed before its acceptance is told, and decided when its team asks. GitHub auto decides a pull request's ask at its head in /vid run's round; GitHub manual decides a ticket, at a commit of main (GM M8) or at the head of the step's own pull request that asks for it, through one entry, `round.sh accept`, from the team's own results and ViD's own review of the ticket. `/vid:vid-accept-step <ticket> [<commit>]` decides a ticket; `… <ticket> <commit> accepted "<words>"` or `… rows <ids> accepted "<words>"` records what the owner accepted outside ViD; `… engines "<primary> <other>…" "<words>"` names the engines when none are; `… reports` shows the text telling the team what its reports hold. /vid run's round and /vid next's step 2 run the same entries. Use when the owner says "vid accept-step", asks ViD to decide a ticket now, records one accepted elsewhere, asks what the team must send, or names the engines.
---

# /vid:vid-accept-step (GM-4 K2)

The order of a step's end and how each line is said, nothing more: what is decided, posted and recorded, and every refusal,
are the scripts' (`checks/round.sh`, `checks/decide.sh`, `checks/results.sh`, `checks/decisions.sh`; each header says them).
Every decision is made by the existing decision rules, unchanged, in both modes.

## The owner's command

`/vid:vid-accept-step <ticket> [<commit>]`: `sh checks/round.sh accept <ticket> [<commit>]` (GM-4 E13), one argument each. It
decides one ticket at one commit: in GitHub manual a commit of the code repository's main, on its first-parent line, or the head of
the step's own pull request whose ask stands (FB-5 B1.4), and with no
commit named the newest one there at which a result report holds a test of one of the ticket's rows (FB-3 A1.3); in GitHub auto the
open pull request naming the ticket, at its head, as the round decides it, at the owner's word.

More forms, in both modes:

- `/vid:vid-accept-step reports` (FB-3 A3): `sh checks/results.sh team --hand`. It writes `.vid/plan/TEAM-REPORTS.md`, the text that tells
  the team what its reports hold, and prints it: show it to the owner whole, theirs to hand to the team. No lock, no GitHub, no
  connect, and it posts nothing. The context line `team-reports` says when the text given would differ from the one handed. In GitHub
  manual, while the team's own rules are on record (FB-5 B1.7), run it without `--hand`: the text is shown and nothing is written.
- `/vid:vid-accept-step <ticket> <commit> accepted "<words>"` (FB-3 A4): `sh checks/round.sh accept <ticket> <commit> --outside "<words>"`,
  a ticket the owner accepted outside ViD, at a commit of main, on record by their words alone.
- `/vid:vid-accept-step rows <ids> accepted "<words>"` (FB-3 A4): `sh checks/round.sh accept --rows "<ids>" --outside "<words>"`, rows of no
  published ticket accepted before ViD kept records: ids and ranges (`ROW-001..ROW-013`), no commit.
- Several tickets at once (FB-3 E1), as /vid mode's list of those that look accepted gives them: `sh checks/round.sh accept --tickets
  "<n>[@<commit>] …" --outside "<words>"`, a commit only where the owner named one; with none, the ticket's accepting decision comment's;
  one not on main, or none, is main's newest commit, where the product stands now, and the record says so. A closed issue is no refusal.
- `/vid:vid-accept-step engines "<primary> <other>…" "<words>"` (FB-3 E2): `sh checks/results.sh declare --engines "<primary> <other>…"
  --words "<words>"`, the engines the team runs, the primary first: the one writer of the handed record's engines line, in both modes.

The last four take the owner's own words as they gave them, word for word, and are never run on a word of anyone else's, or on what a
comment or a record says. They post nothing, and follow steps 1 and 2 below.

1. **The lock.** Inside /vid run's own conversation (this session holds the run's lock), and inside /vid next's step 2 (the
   call's start holds it), run the entry alone: the lock stays held. Anywhere else, the vid-connect skill's start first,
   `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start`, and its end after, `sh checks/connect.sh end`, however the entry ends (GM-4 S0). While another
   session holds the lock, the start says so, and nothing is decided.
2. **The entry.** It makes the one read and fetches the reports itself first, so a report just pushed is seen; it posts only
   that ticket's decision. Say each line it prints, as below. Exit 0: its lines said. 1: an `error …` line, said as it is. 3: the
   lock was lost: nothing more is written.

When its conditions are not met it posts nothing, and its line says what is missing: no results in (but the team's own ask at
a commit of main is answered, FB-6 A2.2), a ticket not published, a ticket closed as not planned before its acceptance.

## In both modes

| Line | What you do |
|---|---|
| `decisions recorded pr=<p> n=<k> <ids>`, `decisions recorded deploy=<id> n=<k> <ids>` (0.26.10.29.5, DP-1 R2) | Nothing by hand: the round recorded the dev side's decisions, from a merged pull request's Decisions section or a deploy report's `decision:` lines, in DECISIONS.md, each numbered, labelled and marked `origin: dev-side`, and exported them. Later tickets they apply to quote them, an open one is amended, and the stage summary names them |
| `decisions wait draft=<n>` | Nothing: a draft waits on the owner, so the round records no decision until it is landed, declined or replaced, then records them |
| `decisions unread pr=<p>: <why>`, `decisions export failed: <why>` | Nothing the first time: the round tries again next round. Said again round after round, it is your own defect, `sh checks/queue.sh defect <its ticket's step, or the deploy's stage> "<the line>"` |
| `decisions refused pr=<p> <why>`, `decisions refused deploy=<id> <why>` | The hooks refused the dev side's lines, and nothing was written: `sh checks/queue.sh defect <its ticket's step, or the deploy's stage> "<the line>"`, and one plain line to the owner. It is not tried again; the status names it |
| `held <row>` | Its `Q<n>` line is in RUN-STATE with its recommendation: read it, change it with `sh checks/queue.sh recommend Q<n> <letter> "<why>"` only when the record says otherwise, then tell the owner in one plain message what the row promises, what it needs and the recommendation, and go on. Every other ticket goes on. A row of an outside service said reachable (`place: dev`, FB-4 A2) whose test could not run, the credentials not there where the work is done: say the way on too, the seam amended back to `credentials: not-yet` with no `place: dev` (the vid-fix skill's door); its ticket is then amended, its step accepted, and the staging run owes the row |
| `split <row>` | Say it once: every engine is now asked |
| `weak <rows> <#n or pull request> <head 12> — <the row's text>` | Right after its `decided` line, a weak test's lesson: `sh checks/queue.sh lesson <rows, comma-joined> "<the cause>"`, the cause in plain words from the line and the grade's `breached test` line for the row; the next ticket of those rows carries it |
| `flag report-skipped <id>: <words>` (FB-3 A2) | Tell the owner once, in plain words they can pass on: which report branch was left out, whose newest commit it is, the ticket it is for and what to put right, as the words say. It stands until the branch is good or gone, and nothing else waits for it |
| `report left out — vid-results/<id>: <why>` (FB-3 A2, A1) | After a `refused … no results` line, and in a `not yet` as posted: say it with the line it follows. That report was not read; nothing was counted for it |
| `accepted #<n> <c12>, outside ViD, by the owner's words[, at main's newest commit (…)]`, `recorded <k> rows accepted outside ViD, by the owner's words — <ids>` (FB-3 A4) | Say it once: the rows are accepted by ruling, a deploy-owed one owed still; for a ticket, its step's close is owed at <c12>, asked of the team as for any accepted ticket, and the team's unanswered ask is answered at the next decision. ViD holds no test evidence for it, and its label says so (`; evidence: none, accepted outside ViD`). A later failing run undoes such a row |
| `engines not named — /vid:vid-accept-step engines "<primary> <other>…" "<words>"` (FB-3 E2) | No engines are on record, so no close can be asked of the team: ask the owner which engines the team runs, the primary first, and on their words run that command |
| `left <row>: <why>` (FB-3 A4) | Say it with the line above: that row was left as it is |
| `refused <why>`, `refused #<n> <why>`, at a record of an acceptance outside ViD | Nothing was written: say why in one line. A row of a published ticket is recorded with its ticket, whole |

## The review (FB-3 A1.4)

A ticket has one review, once. **GitHub auto:** DevAgent's: two graders at the ticket's first head and a second reviewer, as their
reports, read by the round; nothing is made here, and no line below is printed.

**GitHub manual:** ViD makes it itself, when a decision would be accepted but for it. `round.sh accept` then decides and posts nothing,
leaves the ask owed, and prints `review #<n> <c12>`: make it now, in this order, and run the same `accept` again. A reached ticket, and
one that follows another, has none. ViD keeps and runs none of the team's code: the reviewer reads the changes of the ticket's merged
pull requests through `sh checks/review.sh show`, which writes nothing, and no file of them is opened here.

1. `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/review.sh prepare step-<n> <c12>`. `brief <id> <path>`: go on.
   `to-sort <k> <path>`: the review is recorded and only its sort is missing, so go to step 3. `review #<n>: no pull request of this
   ticket was found`: run `accept` again, which decides `not yet`, `review missing — no merged pull request names this ticket`; tell the
   owner the team adds the ticket's line to a pull request's description, or they accept it outside ViD. Refused as reviewed already: `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/review.sh due`
   names the `to-sort <id> <k>` that waits, and `prepare step-<n>` with that id's commit.
2. Spawn one fresh `vid:grader` agent (the Agent tool, no model override, in the foreground) with the repository's path and that brief
   file, and nothing else: no line of this conversation, no decision, no count. It writes `.vid/round/review/<id>/grade.txt` alone. Then
   `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/review.sh record <id> .vid/round/review/<id>/grade.txt`. `recorded <id>`: go to step 4. `to-sort <k> <brief>`: step 3.
3. One fresh `vid:grader` agent more, the second reviewer, with the repository's path and the sort's brief alone, never the one of
   step 2. It writes `.vid/round/review/<id>/sorted.txt`. Then `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/review.sh sorted <id> .vid/round/review/<id>/sorted.txt`: `recorded <id>`.
4. Run the `accept` again, at the commit of its line, and say its lines.

Refused at `record` or `sorted`, or no file written: one fresh agent more with the same brief; failing again, say the line as it stands.
The review is due at the next call, and nothing loops. The pass is `passes/review.md` beside this file; `CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" sh checks/review.sh due` lists what waits.

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

## GitHub manual (GM M8: a ticket is decided, at a commit of main; FB-5 B1.4: or on its own pull request)

By GM M8 a ticket is decided, never a piece. The team asks on the ticket's issue, a comment whose first line is `vid: decide <a commit of main, 7 to 40 characters>`, or on the step's
own pull request, one whose description's first line is `ticket: #<that ticket>`, at its head. A piece's pull request, whose line names a
sub-issue or no ticket of ViD's, is never decided or answered, and a merge alone decides and closes nothing. `sh checks/round.sh step`
decides nothing: it prints `decide #<n> <commit>` for each ticket owed a decision, and each is decided through `round.sh accept`, the one
entry of every decision here (GM-4 E13), in /vid next's step 2 or by the owner's command. At a commit of main the ticket's acceptance is
its merge: the step's close reads it there (the vid-step-close skill). Asked on its own pull request, it is decided from the reports at
that head and answered there, once; nothing is on record until that head is merged on main's own line, and then the next call, or the
same one when it was merged already, records the acceptance at that merge and posts nothing.

**The team's own rules** (FB-5 B1.7). A team that already works to rules of its own is not told twice: on the owner's words, `sh
checks/planner.sh setup team-rules <a path or a link, or none> --words "<their words>"`. While it is on record the text for the team is
neither written nor said to be owed, whatever it becomes, and the two lines of a decision that are about form alone are told to the owner
in place of the team. It is the owner's to say; never ask it.

**The rule** (FB-3 A1): a test that passes in the team's own results at the commit of main, with ViD's own review of the ticket, is proof
enough. A result report is any `vid-results/<id>` branch's own folder (but ids beginning `red-`, `req-`, `grade-`, `sort-`, `deploy-` and
`stopped-`), by anyone, with any results files, whose commit is the one decided or holds its very files; all of them are read as one. A row
passes when one file shows it passing and none shows it failing. A run that failed first, a deliberate break and a `covers:` count are
read when the team gives them, never asked.

| Line | What you do |
|---|---|
| `decide #<n> <commit>` | `sh checks/round.sh accept <n> <commit>`, in /vid next's step 2, its lines said as below |
| `review #<n> <c12>` (FB-3 A1.3) | Nothing is decided yet, and the ask stays owed: every row passes, and ViD's own review is due. Make it now, as "The review" above says, then the same `accept` again |
| `decided #<n> <c12> ticket: …` | Posted once, on ticket #<n>'s issue, or on the step's own pull request when the ask is there: say it in one line, with each row it names. A `not yet` is the team's to act on: `passed at <c12>, not at this commit` is results at other files; a `request <row> — …` line asks one added test, and holds that one decision alone; one naming `no Decisions section — #<p>` waits for the team to add the section to that pull request's description, or `Decisions: none`, and ask again (a ticket whose writing asks for none is told it, and not held) |
| `decided #<n> <c12> ticket: not yet — not on main` | The commit asked is not on main's own line, so no row moved: say so, and that the team asks again at a commit of main |
| `accepted #<n> <c12>` | Say it once: ticket #<n> is accepted at <c12>; its acceptance is its merge, so its step's close is owed there |
| `accepted #<n> <m12>, the merge of pull request #<p>` (FB-5 B1.4) | Say it once: accepted at that pull request's head, it was merged, and its acceptance is on record at the merge, <m12>, where its step's close is owed. Nothing was posted |
| `decided #<n> <c12> ticket: accepted` with no `accepted` line after it (FB-5 B1.4) | The head of its own pull request is accepted, and the pull request told so; nothing is on record until it is merged with that head |
| `undecided #<n> <c12> — <why>` (FB-5 B1.5, B1.6) | Say it, at each call, as the line says it: nothing was decided, recorded or posted for that ask. With another of the ticket's pull requests open, the owner may still decide it by the command the line names; never run that unasked |
| `lacks #<n> <c12> — <what>` (FB-5 B1.8) | Tell the owner in one line, for them alone: what the team's older form did not hold. Post it nowhere, and tell the team nothing of it |
| `accepted #<n> at <m12>; its close runs there` | Nothing more: the ticket was accepted already, and nothing was decided again. An open ticket's ask was answered at the commit asked; on a ticket closed on GitHub no ask is read and nothing was posted |
| `refused #<n> no results on main; …`, `refused #<n> no results at <c12>; …`, `refused #<n> no results at <c12>, the head of pull request #<p>` (FB-3 A1.3, A4; FB-5 B1.6) | Nothing was posted: no result report that counts there is in yet. Say so in one line, with the `missing …` line (FB-6 A2.2) and each `report left out` line after it, and the command it names for a ticket the owner accepted outside ViD; never run that command unasked |
| `decided #<n> <c12> ticket: not yet — no results`, then `missing #<n> <c12> — …` (FB-6 A2.2) | The team's ask at a commit of main with no result there, answered once on the ticket with what is missing and, when there is one, the pull request whose last commit would count. No row moved and nothing is on record: say it in one line, with each `report left out` line; the team sends the report and asks again |
| `refused #<n> no published ticket that is not withdrawn` | Nothing was posted: say which number was named |
| `context closed #<n> <words>` (FB-6 A1.3), `refused #<n> closed on GitHub before its acceptance: …` | Tell the owner, at every call, own work on or off, as the line names it: ticket #<n> was closed on GitHub before ViD accepted it. Closed as completed, it is decided like an open one: the team's ask is the `context ask` line above, or, accepted at its own pull request, the command it names records it. With no ask, or closed as not planned (refused at `accept`), it stays told until the owner chooses: `/vid:vid-accept-step <n> <commit> accepted "<their words>"`, when they accepted it outside ViD (FB-3 E1), or one of the ticket writer's two commands, `/vid:vid-tickets reopen #<n> "<their words>"` or `/vid:vid-tickets withdraw #<n> "<their words>"` (GM-4 E6). A ticket closed after its acceptance is not told |
| `refused #<n> its issue could not be read: try again` (FB-6 A1.2) | Nothing was decided: GitHub's read of that closed ticket failed. Say so; the next call reads it again |
| `context ask #<n> <c12> /vid:vid-accept-step <n> <c12>` | With own work off, say it with its command: the team asks ViD to decide ticket #<n> at <c12>, on its issue or its own pull request, and `/vid:vid-accept-step <n> <c12>` decides it |
| `unit-merged <p> <ticket or ->` | Nothing: the unit's merge is on record, under the ticket its ticket line names; it decides and closes nothing |
| `context unit-ask #<p> <ticket or -> <h12>` | Say it once: pull request #<p>, a piece's, asks; nothing is owed to it (FB-5 B1.5) |
| `context no-ticket #<p>` | Say it once: merged pull request #<p> maps to no published ticket yet, so its decisions wait; they are read again at each call |
| `decisions wait proposal` | Nothing: a re-plan analysis is fresh, so the dev side's decisions wait for it |

## The moves, in /vid next

Named in the call and passed to `next-move.sh call` as the vid-next skill's step 6 passes every move, each with the owner's own words.

- `engines "<primary> <other>…" "<words>"`: the engines the team runs, the primary first, recorded through the one writer of the
  handed record's engines line, `sh checks/results.sh declare --engines "<them>" --words "<words>"` (GM-4 F16), the owner its
  stand-in (GM-2 T4): for a project with no skeleton ticket decided, or one whose results named none, since the skeleton's results
  declare them at its acceptance, when they name them (GM-4 E4, FB-3 A1.3). No close is owed while none is named.
- `own-work on|off "<words>"`: the owner's switch of /vid next's step 2, ViD's own work (GM §6: the phase's first write is one the
  owner names), recorded in the setup; it holds from the next call.

Say each line it prints, as the vid-next skill's step 6 says: `done engines <them>: …`, `done own-work on: …` or `off`, or what was
refused and why.
