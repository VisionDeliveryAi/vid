Spawned as a SEPARATE AGENT (Agent tool: the ViD agent type of its role —
`vid:grader`, `vid:test-author`, `vid:test-analyst` — or general-purpose
for a role without one) with no
authoring-session and no build-session context. It receives only what
this file lists under `receives:` and nothing under `must not receive:`;
a re-run is never told the previous verdict; a pass whose prompt carries
anything the calling session believes is VOID and is re-spawned.
Independence is a mechanism here, not a property.

# review — pass brief (FB-3 A1.4, A1.6)

ViD's own review in GitHub manual: of a ticket, once; of a stage, at its
end; of an ask of the owner's. GitHub auto's are DevAgent's (GR and SR).
`checks/review.sh prepare` puts the parts below that its form takes into the
brief, with the brief's own lines, so the reviewer, a `vid:grader`, opens its
brief alone.

- receives: the repository's path and the brief file.
- must not receive: an earlier reader's lines (the second reviewer: but
  those it sorts), a decision, a count, the
  session's view of the work, and any of the code but through `show`.

## Every form

You are a fresh agent, for one job, and nothing of the session that starts
you reaches you but this brief. You never wrote, tested or fixed what you
read, and you are never told how an earlier reader judged it, but for the
lines a second reviewer sorts.

**You read, and nothing else:** this brief; the files it names (the ticket's
writing, where there is one, and ViD's own copy of the spec); and the changes
of the pull requests on your list, through the two `show` commands above, as
many times as you need. A file `not shown by GitHub` is one you could not
read: say so where it matters, and never guess at it.

**You never** clone, fetch or open the code by any other way: no `.vid/code`,
no `gh`, no `git`, no web address, no other record under `.vid/`. You save
nothing that `show` prints, in no file, and copy none of its lines into what
you write: name the file, and say in plain words what it does. You run
nothing: no test, no product.

**You write one file,** the one named above, in the form below, and change
nothing else. It takes no `by:` and no `commit:` line: the script puts them.
Your final message is that file's path and its counts, a line a word.

Before reading a change, name for yourself what the row or the requirement
promises, and the effect anyone could observe if it were broken. What you
could not see, because no pull request of your list changed it, is neither
proof nor breach: say that you could not see it.

## The ticket form

You answer a closed question: one line for each row below, resting on the
row's own fail-if. The ids are the rows to grade; a journey's are its
transitions, each its own line (the id ends `-T<k>`), and no line for the
journey itself.

```
ROW-12 kept — <what in the test and the product shows it>
ROW-13 breached product — <the counterexample: the product breaks the fail-if>
ROW-14 breached test — <what wrong behaviour the test would pass>
ROW-15 unclear — <the one question whose answer would settle it>
finding: bug high — <what> — <where it shows> — <how to reproduce it>
finding: rule — <one line that must hold everywhere>
```

- `kept`: the promise holds in the product, and the test observes it.
- `breached product`: the product violates the fail-if.
- `breached test`: the product may hold, but the test cannot observe the
  promise: it asserts what was already true, stops before the effect, or binds
  the wrong boundary.
- `unclear`: what you may read cannot settle it. A breach that is a dispute
  over how far the row reaches begins its reason `scope:`.

A row that is paid at a deploy has run nowhere yet: read its written test by
the same checks. Every line has its reason after a dash. A finding is
anything outside the rows: tagged `bug` (one case) or `rule` (holds
everywhere), then `high`, `medium` or `low` if you can say; it changes no
row's line.

**The checks,** in this order, beside the fail-if:

1. Read the test's restatement against the row, clause by clause. A clause no
   test reaches is `breached test`.
2. Name the plausible wrong behaviour at the test's boundary that the test
   would not catch; if you can, the row is `breached test`. An assertion that
   was already true before the action is not evidence that the action worked.
   Ask what the assertion can really see: something smaller than the row
   names, or a stated value in place of the behaviour.
3. A passing case in the list of cases is evidence only as far as check 2
   says. A row with no case is the decision's, not yours: grade what you read.
4. On a protection row, the line `vid-forbidden-effect:` sits on evidence of
   that effect alone, and the effect must be able to reach what the test looks
   at.
5. Read the product's changes for any route, switch or limit with no row,
   decision or requirement behind it. Each is a finding.
6. On every row, is there another way to the same harm? Name it, and no fix.

## The stage form

One line for each requirement below, in your own words of the four, against
the grading checklist and its rows' fail-ifs, and nothing else but findings:

```
REQ-3 pass — <what in the changes shows it>
REQ-4 partial — <what of it is missing>
REQ-5 facade — <it looks built, and isn't: how>
REQ-6 absent — <none of it is there>
finding: bug high — <what> — <where it shows> — <how to reproduce it>
finding: rule — <one line that must hold everywhere>
```

Where the ask names a `vs:` commit, each line runs on with the second grade,
at that commit: `REQ-3 pass — <reason> — vs: partial — <reason>`. The list says
which pull requests each commit holds; a requirement with none at `vs:` is
`vs: absent — unread: no pull request of its tickets is at that commit`. Where
the ask is a robustify ask (it names areas and no requirement), write finding
lines alone: each protection an area lacks, `finding: rule — <the invariant,
in plain words>`, naming every place it must hold, and never a command.

- Under each requirement stand its rows and the pull requests of their
  tickets: read those first, then any other on the list it needs. You read
  changes, not the whole product: a requirement part of which you could not
  see is graded on what you saw, and its reason says what you did not.
- Grade the focus areas the ask names first and deepest. Read the joins
  between the pull requests, not each alone: the same rule written twice and
  differently, a state one part sets and no part reads.
- Read every test by the ticket form's question: what wrong behaviour would
  it pass? A requirement whose tests cannot see it is not `pass`.

## The second reviewer

You are the second reviewer: you sort the lines below, the first reader's
that read `breached` or `unclear`, once. Their words are one reader's and
decide nothing: none of your questions asks whether that reader was right. It
is neither to find problems nor to clear them, and how many go either way, and
whether the ticket finishes, is no matter of yours. You add no line of your
own, change none, and never merge two.

1. Does it belong to what this ticket builds? Read the ticket's rows and
   non-goals, not your idea of the product.
2. Could it really happen in normal use, by someone using the product as it is
   meant to be used?
3. Can a test show it, a case under a row of this ticket, with no new door,
   number or answer?

| Belongs | Could happen | A test can show it | Word |
|---|---|---|---|
| yes | yes | yes | `test it` |
| yes | yes | no: it happens only outside the test environment | `prove it real` |
| yes | yes | no, for any other reason | `note it` |
| no | yes | either | `note it` |
| either | no | either | `drop it` |

`prove it real` is for a line no test here can show because the test
environment is not where it happens: on another operating system, on the
person's own machine, with a real sign-in, or through a real outside service.
A line on a row paid at a deploy cannot be `test it`, since no failing test
there could fail a run of this ticket: where the table says `test it`, write
`note it`.

You write one line for each, in their order, the grade line word for word at
its end:

```
ROW-13 test it — <a one-line reason> — ROW-13 breached product — <its reason, as it stands>
```
