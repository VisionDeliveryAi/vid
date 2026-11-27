---
name: vid-answer
description: Every answer of the owner's in ticket mode, in both GitHub modes, through one entry, `checks/queue.sh answer`, with the owner's words — a held row, the team's product questions, a ticket's or a stage's findings, a close that could not finish, a stand-in, a duty not done, a draft of the door, a trigger or a move a call raised, the compaction question; and the backlog, the owner's one list in their order, `/vid:vid-answer backlog`. `/vid:vid-answer <Q<n> or #<n>:<k>> <answer> "<words>"`; /vid run and /vid next call it for the same. Use when the owner answers a question ViD asked, rules a held row or a finding, says yes or no to a draft, or asks what waits on them or for the backlog.
---

# /vid:vid-answer

The answer's order and how its lines are said, nothing more: what each answer takes, what it records and posts, and every
refusal are `checks/queue.sh`'s (its header says each). Every answer goes through `sh checks/queue.sh answer`, from every caller
and in every mode (GM-4 K6); no other path records one.

## The owner's command

`/vid:vid-answer <Q<n> or #<n>:<k>> <answer> "<words>"`, the owner's words their own, never yours.

1. **The lock.** Inside /vid run's own conversation (this session holds the run's lock): run the read and the entry alone (2 and 3), and the lock stays
   held, so the run goes on. Anywhere else: the vid-connect skill's start first, and its end after, however the call ends. While
   another session holds the lock, the start says so, and nothing is answered.
2. **The read.** The vid-read skill's one read, `sh checks/round.sh read`, under the lock step 1 holds, before the answer, in every
   case: the answer then checks the question as it was listed against GitHub's words now (GM M16), and an answer to words that
   changed is shown again, nothing posted.
3. **The answer.** `sh checks/queue.sh answer <Q<n>|<n>:<k>> <answer> "<their words>"`, one argument each, quoted. Say what it
   printed in plain words: what was recorded, what was posted, or what was refused and why. A refusal records nothing.
   **An answer that lands a draft** (the `yes` of a draft's `Q<n>` line, which runs `sh checks/land.sh <n>`, alone or among a
   call's moves) can take longer than one command may run (a landing took about eleven minutes in a run on Windows, and the
   tool allows ten): start it with `run_in_background: true`, under no `timeout` of your own, and wait until its task ends
   (its notice) before anything else touches the spec files or ViD's records: under /vid run no round step, `round.sh` or
   save runs meanwhile; never stop it, by a limit or by hand. Then say its output as any answer's (FIX-BATCH-T2 OW-5).
4. **A `door:` line.** The answer changes rows: the change goes through the door, the vid-fix skill's ticket-mode branch, run here
   on the words the line gives. It drafts and asks; it lands nothing.
5. **What waits.** After an answer, its one line: `sh checks/queue.sh sorted --line`. When the owner asks what waits, `sh checks/queue.sh list`: each
   open line, `Q<n>`, its key, the answers it takes and its words, in plain words, with the answers it takes as the script gives them; then
   `sh checks/queue.sh backlog`, and end with its `next:` line.

## The backlog (FB-3 D1)

One list of everything open, kept with the records in both GitHub modes: `.vid/decide/queue/backlog`, which
`checks/queue.sh` alone writes. The panel beside the chat draws it as the vid-sort skill last sorted it (FB-5 A1). `/vid:vid-answer backlog`
says it where there is no panel, with no lock and no read: `sh checks/queue.sh backlog`, My to do, Waiting, Changed and The rest, numbered, each
to-do with the ids it covers, then its `next:` line, then, in GitHub manual, the plan and each team, all said as printed, in plain words.

- **What is in it.** Each `Q<n>` line, added and closed by the script at every sync; in GitHub manual each issue assigned to the
  owner; and what comes up as you work, which no script sees (a person waited for, a push, a decision owed), added by you at once:
  `sh checks/queue.sh backlog add "<words>" [--who <who>] [--next "<next action>"] [--note "<note>"]`, a `B<n>`.
- **What you work on** is the `next:` line, the first of My to do (with no sort yet, the top open item, neither waiting nor aside). A new
  thing lands at the end, not sorted yet, and interrupts nothing: never ask it on its own, and never put it above a line the owner placed.
- **As the work goes** you keep it true: `sh checks/queue.sh backlog set <id> --state doing` (one item at most), `waiting` with
  `--note` saying on whom and since when, `--next`, `--who`, and `--state done` for a `B<n>`. A `Q<n>` closes by its answer alone.
- **Order, and what is set aside,** are the owner's, changed only on the owner's say: `backlog set <id> --place top|after <id>`, which moves
  its line in the sort too and keeps it there until it closes, and `--state aside`, which takes it out of My to do at once.
- **An answer pressed in the panel** comes as the owner's words, `<number> · <title>: <answer> (<ids>)`: answer by the ids, never by the number alone;
  "Put it off" is `--state aside` on each.
- It posts nothing and records no answer. Every answer ends with the `next:` line.

## The owner's queue (v0.26.10.25.3)

Whatever waits on the owner is a `Q<n>` line in RUN-STATE, written by `round.sh step` in GitHub auto and by /vid next's call in
GitHub manual: a held row, a question only the owner can answer, a ticket's findings, a close that could not finish, a draft,
and in GitHub manual each trigger and move the call raised. Every answer goes through `sh checks/queue.sh answer Q<n> …`, with the
owner's words, and is acted on at once:

- a held row: `a` accept, `b <N>` more rounds, `c` a known limit, `d` amend. The recommendation's rule: tests passing with only the evidence missing, (a); a weak test whose break the corrected test still misses, (c); a product failure or a row passing at its head, (b) with 1 more round. Amend prints a `door:` line: the change goes through `/vid fix`'s door (above);
- a question: the owner's words, posted as the `RM:` answer, or `there "<words>"` when the owner answered it on GitHub;
- ViD's own question (FB-1 B2, `own:<id>`, "ViD's question: …"): the owner's words, posted nowhere; it prints a `door:` line, and the draft is made with that answer through the door;
- findings: `<finding> fix|row|known|no`, one by one; `known` reaches every later ticket, and `fix` and `row` print a `door:` line: SP drafts the new row the finding needs, whose ticket's red shows the defect;
- a close: `again` or `limit`; for a row red again after its fix, `again` is another fix ticket;
- a draft (v0.26.10.25.5): `yes "<their words>"` lands it, `no` declines it;
- a trigger a call raised (GM-4 F4): `decline "<words>"`, and for a critical one `done "<words>"`; a move it raised: `done "<words>"`.

**An answer under the owner's delegation** (v0.26.10.28.8). When the owner has told you, in their own words, to answer in their place (every question, or one kind), each answer you give that way is `sh checks/queue.sh answer Q<n> --by delegate …`, never the bare form: the bare form records the owner's own answer, given in their own words. An answer the spec gives stays `--by RM`. Under delegation the owner's alone stays refused: the production yes, a question on a production okay, what production runs, and "close without the walk". The status's delegated answers list each one, so the owner can read them back: every answer not given by the owner, by RM, a delegate or a stand-in, held-row rulings included, read from the same records as the stage summary's facts and the completion report's section 8 (0.26.10.29.5, DP-1 R4).

## In /vid run: the round's lines

| Line | What you do |
|---|---|
| `question <n> <k>` | Read comment `<k>` of issue or pull request `<n>`. If the spec answers it: `sh checks/queue.sh answer <n>:<k> --by RM "<the answer>"`, which posts it begun `RM:`, marks it delegated and takes the blocked label off when nothing else stands. If only the owner can say: `sh checks/queue.sh ask <n>:<k>`, which makes it a `Q<n>` line. Every other ticket goes on |
| `note #<n> <k> <first line>` (FB-7 B7) | Read comment `<k>` whole, and say in one line what it says and what you did about it, or that it asks nothing of ViD; when it says an ask cannot be met or takes a claim back, act on that before anything more is asked there |
| `finding <ticket> <severity> <words>` | A high one, or one whose words say the spec contradicts itself: tell the owner at once, and go on. The rest wait for the status at the step's close, but a ticket's whose stage has its candidate named are told at once: the stage's close waits for them. |
| `context-window Q<m>` (v0.26.10.26.7) | Ask the owner once, in plain words: may ViD set this project's compaction point to 300,000 tokens, so this session compacts before its context grows costly? And go on; their yes or no is `sh checks/queue.sh answer Q<m> yes\|no "<their words>"` |

**The compaction question** is a `Q<n>` line (v0.26.10.26.7, R13): unless `.claude/settings.json` sets `autoCompactWindow`, or a `context-window` event records the owner's answer, `queue.sh sync` makes it one and prints `context-window Q<m>` once. Ask it then, in plain words, as that line; the owner's answer is `sh checks/queue.sh answer Q<m> yes|no "<their words>"`, which writes the setting on a yes and the event either way. Never ask it outside the line. GitHub manual makes no compaction question (GM-4 K6): its calls are short, and `queue.sh` makes none there.

## In /vid next: the answer, decline, done and team-change moves

Every question is the owner's in GitHub manual (D6, the setting the switch writes): the call answers none from the spec. The
owner's answers, named in the call and passed to `next-move.sh call` as the vid-next skill's step 6 passes every move, each run
`queue.sh answer`:

- `answer "#<n>:<k>" "<words>"`, a team question by its place, or `answer "#<n>:<k>" there "<words>"` when the owner answered it
  on GitHub; `answer Q<n> <its answer> "<words>"` for any open `Q<n>` line, with the answer `queue.sh list` gives it (a draft's
  `yes`, landed by the door's landing, included);
- `decline <what> ["<subject>"] "<words>"`: each open line of a trigger of that what (and subject) the last call raised, declined.
- `done "<kind> <subject>" "<words>"`: a to-do of the list done in the owner's words, its `Q<n>` line answered `done`;
- `team-change "#<n>" <id> yes "<words>"`, or `no`: the team's change to a published ticket's test taken in or declined; a yes
  amends the ticket through the vid-tickets skill's one path, `github.sh tw-hand` (GM-4 F5), a no is one comment on it.

Each open `Q<n>` line, with the answers it takes, is `queue.sh list --short`'s, one line a kind (`queue.sh list` gives each on its own), for the
session: the owner's list is the panel's, sorted by the vid-sort skill. A `door:` line among the call's lines goes through the door, as above.
