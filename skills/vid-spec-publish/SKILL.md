---
name: vid-spec-publish
description: The spec where the team reads it, with one repository (`layout: one`), in both GitHub modes — ViD's export of the ratified spec mirrored into the folder of the code repository the setup names (`spec-path:`), as one pull request that changes that folder alone, its stamp file (`spec-stamp:`) set to the export, and a publish ticket naming it; the team merges it, ViD merges nothing, reads and sends no code, and pushes nothing from this machine. `/vid:vid-spec-publish "<words>"`; /vid run's round and GitHub manual's apply run the same entry after their export. Use when the owner says "vid spec-publish", or asks for the spec to be published into the code repository's folder.
---

# /vid:vid-spec-publish

One entry, `sh checks/github.sh spec-publish [<export commit>]` (GM-4 K13); its header says what it sends and each refusal. With
`layout: separate` the spec reaches the team by the private spec repository's export alone (`sh checks/github.sh spec-export`):
the entry refuses, posting nothing, and the command says so. The private spec repository stays in both layouts: it is ViD's
export, lock and saved records, and every ticket still names the export it rests on.

**What it sends**, with `layout: one`: the export commit's spec tree, the newest export when none is named, mirrored into
`spec-path:` (default `docs/specs`) on the code repository through GitHub's git data API, on main's tree as ViD's fetched copy
(`.vid/code`) records it; the stamp file `spec-stamp:` (optional, a file inside the folder) set to the export commit; a branch
`vid-spec/<12 hex>`, its pull request and a publish ticket naming it. Nothing outside the folder is sent: an entry that would
fall outside it is refused, and nothing is posted. It reads and sends no code, and pushes nothing from this machine: the one
request to GitHub the run's never-push names as its exception. The team merges the pull request; ViD merges nothing. Its record
is the log line `spec-published pr=<n> export=<12 hex> path=<folder> at=<time>`; an export published already is said so, and
nothing more is sent.

## The owner's command

`/vid:vid-spec-publish "<words>"`, the owner's words their own, never yours: their yes to this one publish, required in GitHub
manual (GM M16: nothing goes to the team but on the owner's words), where without them it says so in one line and publishes
nothing; optional in GitHub auto.

1. **The lock.** Inside /vid run's own conversation it uses the run's lock and leaves it held; anywhere else the vid-connect
   skill's start first and its end after, however the call ends (GM-4 S0). While another session holds the lock, the start says
   so, and nothing is published.
2. **The export.** `sh checks/github.sh spec-export`: the commit the team has (GM-4 F8), pushed to the spec repository only when
   something exported changed.
3. **The publish.** `sh checks/github.sh spec-publish`. Say what it printed: the pull request and the publish ticket, with the
   owner's words said back as the yes they gave (the `spec-published` log line keeps the export, the folder and the stamp, not the
   words); the export published already; or the refusal, nothing posted.

## Its other callers

- **/vid run,** GitHub auto: `round.sh next` runs it after its export, and a refusal is its `refused spec-publish …` line, tried again once the export changes. DevAgent
  reads the private spec repository, as before, and merges only what ViD accepted, so the folder's pull request is the owner's to
  merge: one `Q<n>` line names it, gone once the read shows it merged.
- **The apply,** GitHub manual: `replan.sh apply` runs it after its export, before any ticket is posted: `done spec-publish
  <12 hex>`, or `owed spec-publish <12>: <why>`, which holds every post until it goes out.
- **The tickets** name the place each quotes, the spec repository or the folder; in GitHub manual, while the newest folder pull
  request is open, a ticket or amendment names it and asks the team to merge it first (the vid-tickets skill's writer).
- **A hand publish** the owner makes outside ViD is read by the take-stock, `/vid:vid-mode`, from the stamp on main.
