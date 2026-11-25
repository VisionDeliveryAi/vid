---
name: vid-sort
description: The owner's list in ticket mode, in both GitHub modes, sorted into what the owner sees — after a call's lines and raises, each open item put under My to do, Waiting, Changed or The rest, in product words, what can be prepared prepared, through one entry, `checks/queue.sh sort`. Invoked by /vid next after the moves and by /vid run where an item was raised or changed; the owner's command `/vid:vid-sort` sorts at any time. Use when the owner says "vid sort", or asks to have their list sorted again.
---

# /vid:vid-sort

One job (FB-5 A1): sort what is open into the owner's panel, in both modes by the same rules. The reads, the queue, the backlog and
every record stay as they are: this skill writes one file, through `sh checks/queue.sh sort`, posts nothing, answers nothing and
decides nothing.

**Called by the owner** as `/vid:vid-sort`: inside /vid run's own conversation it uses the run's lock and leaves it held; anywhere
else the vid-connect skill's start first and its end after, however the call ends, and between them the vid-read skill's read, then
`sh checks/queue.sh sync`, its lines said.

## The order

1. `sh checks/queue.sh open`: each open item, tab-separated: its id, `new`, `changed` (its words), `moved` (its state, set since) or `same`,
   its state, who, its words, what raised it, its next action, its note, and the line the last sort gave it (its section, its number,
   `placed`). The last line counts what is not sorted and what moved. Where nothing is new, changed or moved and no waiting line has reached its three working
   days, sort nothing and read nothing: say the one line `sh checks/queue.sh sorted --line` prints, and end.
   With no sort yet, every item is new.
2. **Judge only what is new, changed or moved,** and a waiting line whose days are up; the rest stands as it is. Read for it, and for it alone,
   what the records cannot say: the owner's own pull requests (the read's `publish` lines first), the issues assigned to them, the
   threads they asked in, one `gh issue view <n> --comments` or `gh pr view <n> --comments` each, and Slack's notes (`.vid/next/slack`). Nothing else on
   GitHub: no search, no file of the code repository, no pull request's diff; nor a script's source, since the form is below.
   A `context` line of the call is said, and is no item.
3. **Prepare before it is the owner's.** Whatever you can draft, look up or sum up first, you do, then put the line in.
4. What is owed outside ViD's lines is added first (`sh checks/queue.sh backlog add`, the vid-answer skill's backlog), and then has an id.
5. **Write the sort** in a file: start from `.vid/decide/queue/sorted` (copied; its `sum` and `raise` lines may stay), change the blocks judged
   again, take out each id that closed, and each `new` and Changed line the last sort said. A to-do's block copied unchanged whose items were
   all put off or set waiting since stays out of My to do: one that comes back is written again. Then `sh checks/queue.sh sort <the file>`. Refused: correct what it names and run it once
   more; refused again, go on: the panel keeps the last sort, and its line says `not sorted`. Each `flag` it prints is yours to
   write again in product words, or shorter, once; none stops the call. Say its last line, and nothing more of the list in the chat.

## The rules

- **My to do** (`todo`): only the owner can do or decide it, they can do it now, and nothing is left to prepare for that answer. A decision
  is summed up so that no document need be opened, with its choices (one to three), and what ViD would choose and why when ViD has a view.
  Two decisions on one thing are one line with two asks. A message is written out, ready to send. A document's choices come one at a time.
  An answer that ends a kind of question ("always so, from now on") is offered as a choice where one fits.
- **What a line of the record answers** is done and told under Changed, with the line, and never asked.
- **Waiting** (`waiting`): a person owes it: `who`, `what`, `since` when. Asked three working days ago, it becomes the owner's line, the message to
  chase it written; with the person away, the line says who else can. What nobody has taken is no person's: `plan`, the plan says it.
- **Changed** (`changed`): what moved since the last sort and needs nothing; its ids, or `-`. A line said at the last sort is not said again, so a `B<n>` in it
  that needs nothing more is done first (`sh checks/queue.sh backlog set <id> --state done`) and the line takes `-`; an item still open belongs to
  the section that says why it is open.
- **The rest**: `vid`, what ViD does, with ids or `-`; `later`, the owner's, not now (`then`: what brings it up); `team`, what goes to the team by itself;
  `suggested`, one line a kind, and only when ViD recommends it; `left-out`, weighed and left out, with why.
- **A pull request of the owner's** (`publish:<n>` in its item): a request for changes is ViD's work first, the change drafted, then the owner's yes;
  "waits for an approval" is `waiting`, with who.
- **An item set `aside`, or `waiting`,** since the last sort has left My to do by itself. Put it back in `todo` only when its wait is over or its time has come.
- **Order** of the to-dos: what most other work waits on; then a decision a person's answer waits for; then quick yeses and messages;
  then preparation. A date overrides. A line marked `placed` was put there by the owner: it stays there, over all of it, until it closes.
  Seven at most: what can wait is `later`.
- **An operation on staging or production:** its `choice` holds the owner's full explicit words for it, whole, and no other choice stands beside it but putting it off.
- **Words:** the product's, as the owner speaks of it. No id of a test, no `Q` or `B` number, no commit and no command in a shown part; those go
  in `details`, and a `message` is written for the person it goes to. Title and do, 10 words each; what, 55; an ask, 20; then, 35.

## The file

One labelled line a part, a blank line between blocks; ids comma-separated, every open item once and once only:

    line <todo|waiting|changed|vid|later|team|suggested|left-out|plan> <ids, or ->
    title <words>      do <words>      new <who, when>      what <words>
    ask <words>        about <words>   choice <words>       choose <n> <why>      message <words>
    then <words>       who <words>     since <words>        details <words>
    release <N> <how the release stands, in words>           name <login or team key> <the person's or the team's name>

A `todo` has `title`, `do`, `what`, `then` and one or two `ask`s, each followed by its own `about`, `choice`s, `choose` and `message`; a choice or a message at
least. `new`, when a person wrote or did something since the last sort, says who and when. Every other line says its one thing in `what`.
`release` and `name` stand outside the lines: a `name` names a person or a team, as the owner's own list says it, never looked up.
