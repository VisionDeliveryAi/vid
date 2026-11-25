---
name: vid-spec-publish
description: The spec where the team reads it, with one repository (`layout: one`), in both GitHub modes — ViD's export of the ratified spec put into the folder of the code repository the setup names (`spec-path:`), as one pull request that changes only files ViD put there, its stamp file (`spec-stamp:`) set to the export, and a publish ticket naming it; the team merges it, or, in GitHub manual with the setup's `spec-publish: hand`, the team makes its own pull request from the files ViD lays out and ViD reads it, writing nothing; ViD merges nothing, reads and sends no code, and pushes nothing from this machine. `/vid:vid-spec-publish ["#<pull request>"] "<words>"`; /vid run's round and GitHub manual's apply run the same entry after their export. Use when the owner says "vid spec-publish", or asks for the spec to be published into the code repository's folder.
---

# /vid:vid-spec-publish

One entry, `sh checks/github.sh spec-publish ["#<pr>"] [--words "<the owner's words>"] [<export commit>]` (GM-4 K13); its header says what it sends and each refusal. With
`layout: separate` the spec reaches the team by the private spec repository's export alone (`sh checks/github.sh spec-export`):
the entry refuses, posting nothing, and the command says so. Every ticket names the export it rests on. With `layout: one` ViD's
export is kept in the project in GitHub manual (FB-3 B2: the commits of `refs/vid/export`, saved with the records; no spec repository
is asked, made, read or pushed); in GitHub auto it stays in the private spec repository, where DevAgent reads it.

**What it sends**, with `layout: one`: the export commit's spec tree, the newest export when none is named, put into
`spec-path:` (default `docs/specs`) on the code repository through GitHub's git data API, on main's tree as ViD's fetched copy
(`.vid/code`) records it; the stamp file `spec-stamp:` (optional, a file inside the folder) set to the export commit; a branch
`vid-spec/<12 hex>`, its pull request and a publish ticket naming it. It changes only files ViD put there (FB-3 B1): every file of
the folder the export lacks stays, and a file the spec dropped is deleted only while main holds it as an earlier publish of ViD's
put it there. Nothing outside the folder is sent: an entry that would
fall outside it is refused, and nothing is posted. It reads and sends no code, and pushes nothing from this machine: the one
request to GitHub the run's never-push names as its exception. The team merges the pull request; ViD merges nothing. Its record
is the log line `spec-published pr=<n> export=<12 hex> path=<folder> stamp=<file|-> at=<time> words="<the owner's words>"`, the
words there only when given; an export published already is said so, and
nothing more is sent. A newer publish closes each older folder pull request still open, and its publish ticket, each with one
comment naming the new pull request (a merged one, and its ticket, left as they are), logged `spec-replaced pr=<old> by=<new> …`.

**When the team publishes by its own process** (FB-3 B1: the setup's `spec-publish: hand`, in GitHub manual; `vid` while missing, and in GitHub auto ViD publishes whatever it says): the
entry writes nothing to GitHub. It fetches the code repository and reads the folder, names and ids alone, at main, or at the head of the pull
request `#<pr>` names, on any branch (one closed and not merged is refused). Every file of the export there: it logs `spec-published pr=<n|-> … at=<time> by=hand`, the
owner's words last, and everything that waits for the publish goes on. Not there: it lays the export out in
`.vid/spec-out/<12 hex>/files/`, with `changes.tsv` beside it (`new`, `changed` or `gone`, and the path in the folder; a `gone` one is
dropped from the spec), and refuses, naming the folder. The stamp, the texts and the team's other files are the team's; ViD closes
no pull request of theirs.

Which commit's spec the folder holds is told at each call from its files' names and ids (FB-4 B1, vid-read and vid-triggers), never from the stamp.

## The owner's command

`/vid:vid-spec-publish "<words>"`, or `/vid:vid-spec-publish #<pull request> "<words>"` with `spec-publish: hand`, the owner's words their own, never yours: their yes to this one publish, required in GitHub
manual (GM M16: nothing goes to the team but on the owner's words), where without them it says so in one line and publishes
nothing; optional in GitHub auto.

1. **The lock.** Inside /vid run's own conversation it uses the run's lock and leaves it held; anywhere else the vid-connect
   skill's start first and its end after, however the call ends (GM-4 S0). While another session holds the lock, the start says
   so, and nothing is published.
2. **The export.** `sh checks/github.sh spec-export`: the commit the team has (GM-4 F8), made only when something exported
   changed: in GitHub manual kept in the project (FB-3 B2), in GitHub auto pushed to the spec repository.
3. **The publish.** `sh checks/github.sh spec-publish ["#<pr>"] --words "<the owner's words>"`, when they gave words and, with
   `spec-publish: hand`, the number (quoted: unquoted, the shell reads `#` as a comment). Refused there because the folder does not hold the export: show the owner the laid-out folder
   and `changes.tsv`; they, or you when they ask for it, take the files through the team's process, and this command is called
   again with that pull request's number, or with none once it is merged. Say what it printed:
   the pull request and the publish ticket, with the owner's words said back as the yes they gave (the `spec-published` log line
   keeps them); the export published already; or the refusal, nothing posted.

## Its other callers

- **/vid run,** GitHub auto: `round.sh next` runs it after its export, and a refusal is its `refused spec-publish …` line, tried again once the export changes;
  a failed call to GitHub is its `failed spec-publish <12>: …` line, tried again at the next round (`round.sh step` says `retry spec-publish <12>`). DevAgent
  reads the private spec repository, as before, and merges only what ViD accepted, so the folder's pull request is the owner's to
  merge: one `Q<n>` line names it, gone once the read shows it merged.
- **The apply,** GitHub manual: `replan.sh apply` runs it after its export, before any ticket is posted: `done spec-publish
  <12 hex>`, or `owed spec-publish <12>: <why>`, which holds every post until it goes out.
- **The tickets** name the place each quotes, the spec repository or the folder; in GitHub manual, while the newest folder pull
  request is open, a ticket or amendment names it and asks the team to merge it first (the vid-tickets skill's writer).
- **A hand publish** made outside ViD is read by this entry with `spec-publish: hand`, and, for the applied version a switch finds, by the take-stock, `/vid:vid-mode`, from the stamp on main.
