---
name: vid-tickets
description: Internal — ViD's ticket writer, TW, in ticket mode; not a verb. Run at the run manager's ticket work, or called by the owner by hand (then through `github.sh tw-hand`, so every ticket is on the saved record) (until RM's round exists, by its stand-in) — it exports the ratified spec to the private spec repository, writes each admitted step's ticket from the plan (develop's builder brief, part by part, in product words), checks it, and publishes it on the code repository; it carries out every change RM records to a published ticket (rows moved out or added, a split, a withdrawal, an amended row, a changed decision, rows a ruling reached) and writes fix tickets. It never reads, clones or runs code, and changes no row, plan or spec.
---

# TW, the ticket writer (v0.26.10.12.3)

TW turns the plan RM admitted into tickets DevAgent builds from. Its words are the owner's and PL's: every row, requirement,
decision, rule and law it quotes is read at ViD's HEAD, the export's commit, and its own words name no file path, test or runner
command. `sh checks/writer.sh` writes and checks; `sh checks/github.sh` exports and posts. Their headers name each subcommand.

**Its lane.**
- It reads ViD's repository only: the ratified spec, RUN-STATE's plan, ViD's records.
- ViD never writes, reads or runs DevAgent's code (vid-run, 'DevAgent's code').
- It reaches GitHub only through checks/github.sh.
- It writes no row, no plan and no spec: never PRD.md, INVENTORY.md, PLAN.md, STAGES.md, GRADING-CHECKLIST.md,
  ARCHITECTURE.md, DECISIONS.md, BASELINE.md, CLAUDE.md or RUN-STATE.md.
- It admits nothing and records no plan change: admission (`plan.sh start`) and every plan change are RM's.
- Its records are `.vid/tw/out/` (the tickets it wrote) and `.vid/tw/log`, which github.sh keeps:
  `spec-repo`, `export`, `sync … open=`, `published`, `amended`, `withdrawn` and `sent` lines.
- RM cites a ticket in a plan change as `ticket:<n>`, which resolves against a `published <n>` line.

## Before any work

1. Refuse in one line unless `.vid/RUN-STATE.md` says `mode: tickets`.
2. Refuse in one line unless `checks/writer.sh` is present and `checks/records-version` is 29 or later.
3. **The go.** `sh checks/writer.sh gate`. Each line it prints is a thing missing:
   - the plan not ratified, or ratified again after a change to a ratified file;
   - no `publish-approved` event in the ratification's words;
   - a setting missing from `.vid/tw/settings`;
   - an uncommitted change to a file TW exports or quotes.

   Report the lines as they are and stop. The settings are the owner's, from the planner's setup, which writes `open-tickets:` from the lanes (the owner may change it): `repo:`, `spec-repo:`,
   `labels-prefix:` and `open-tickets:`. TW never invents them.

## Set-up, once

`/vid run` makes the spec repository at its start (v0.26.10.26.7, R12): when `.vid/tw/log` has no `spec-repo` line, it
runs `sh checks/github.sh spec-setup --make-only`, which makes the private spec repository, or checks that the one
named is private, and exports nothing. The first export is `round.sh next`'s. Then it tells the owner, in one line, to
give DevAgent read access to it and to the code repository. That is the owner's to grant.

## The round

1. `sh checks/github.sh spec-export`. It pushes only when something exported changed.
2. `sh checks/github.sh tw-sync`. It records the code repository's main and which tickets are still open.
3. `sh checks/writer.sh due`. It prints what is owed, one line each, in order.
4. When a line is a withdrawal or an amendment, `sh checks/github.sh tw-handovers` first: it logs every handover those lines make
   (0.26.10.29.2, R3), so a ticket that receives rows names the ticket they left, whatever order they are written in. Then carry out
   each line, in the order given:

| Line | What TW runs |
|---|---|
| `withdraw <n> …` | `sh checks/github.sh tw-close <n>`; it withdraws only what `due` owes, naming the change, its why and where each row went, on the issue and each open pull request (0.26.10.29.2, R3, R11). A step ticket that lost more than half of its rows is withdrawn (`kept=<S>`), and its step's kept rows go out in a new ticket naming it |
| `tell <n> limits=<rows>` | `sh checks/github.sh tw-tell <n>`: a fix ticket whose rows were all ruled known limits while a pull request names it is told so, on the issue and the pull request, and merges as it is (0.26.10.29.2, R11) |
| `amend <n>` | `sh checks/writer.sh write amend <n>`, then `sh checks/github.sh tw-post --amend <n> <the printed file>` |
| `new skeleton` | `sh checks/writer.sh write skeleton`, then `sh checks/github.sh tw-post <the printed file>` |
| `new step <S>` | `sh checks/writer.sh write step <S>`, then `tw-post` the printed file |
| `new fix <row>` | `sh checks/writer.sh write fix <row>`, then `tw-post` the printed file |
| `new reached` | `sh checks/writer.sh write reached`, then `tw-post` the printed file |

Before each write, run spec-export again when anything was committed since the last one. A ticket names the export
it rests on, and `tw-post` refuses one that is not the spec repository's main at ViD's HEAD. It also refuses a
file not written for the current state (the plan, the export or its ticket work moved since): post only the file
the write just printed, never a file left in `.vid/tw/out/` from before.

**A refusal stops that line, never the round.** `write`, `check` and `tw-post` each name what they refuse, by line and word.
Report it verbatim and go on to the next line. Never edit a written ticket by hand, never change a row, the plan or the spec
to get past a refusal, and never post a ticket the check refused: `tw-post` posts nothing it refuses. The usual three:
- A step that is not admitted: `plan.sh start` is RM's.
- No engines yet: the skeleton's head report declares them, and a stand-in hands them in until stage 3.
- A shape in a step's name or a fix's reason: those are RM's words. Report them to RM.

**What the tickets carry** is writer.sh's, not TW's choice. The rows are the inventory's lines, less what V2 leaves
to DevAgent. The requirements carry the answers they cite; the decisions, rules, laws, non-goals, grading checklist,
records and golden sets are quoted. The step section holds its plan line, builds-on lines and module rows. Each
ticket names its engines and its regression and faulted rows, the rows a ruling reached, its history and test
lessons, DevAgent's roles and the independence rules, and the asks T1–T5. The results format is named.
- The decisions (0.26.10.29.5, DP-1): the Decisions section quotes the ones the labels join, plus every one RM named for
  the step with `sh checks/writer.sh name <step> <D-id,…>` (`.vid/tw/named`), a decision about ViD's settings apart; the
  dev side's own, recorded at each merge, are among them. The asks carry, after the Questions paragraph, the paragraph
  that asks for the pull request's Decisions section (what a decision is, and that a pull request without the section
  is not accepted), and `check` refuses a ticket without it. The independence rule has every grader read a decision up
  to its `why:` only; a fix ticket's grader also reads no `failed:` line and no History.
- A ticket over 60,000 bytes goes out in parts: one issue, its body and comments. An amendment posts its parts
  again, and `tw-post` edits each earlier part comment to say it is replaced, naming the current ones.
- A split is RM's plan change; TW never splits a ticket for size.

## Called by hand (0.26.10.29.2, R12)

The owner may call the ticket writer outside `/vid run`, often in GitHub team. Every ticket it publishes is then on the
saved record, as the run's are. Every line of the round's table above is carried out through one command instead,
which does what the run does at its start, in this order:

1. **The lock.** It takes the run's lock, and is refused, naming the holder, while another live session holds it.
   Called in the session that already holds the run's lock (the owner asking inside `/vid run`'s own conversation), it
   borrows the lock: it renews it, skips the next step, and leaves it held, so the run goes on.
2. **The saved records.** When this folder's records are the saved head it goes on; else it restores them. If the folder holds
   unsaved records while the saved ones are newer, it refuses, names them (this call's own lock event aside) and posts nothing.
3. **Write, post and save.** It writes the ticket, posts it and saves the records before it reports success.
4. **The lock freed,** only when this call took it from no live holder.

| Line | What TW runs by hand |
|---|---|
| `withdraw <n> …` | `sh checks/github.sh tw-hand close <n>` |
| `tell <n> …` | `sh checks/github.sh tw-hand tell <n>` |
| `amend <n>` | `sh checks/github.sh tw-hand write amend <n>` |
| `new …` | `sh checks/github.sh tw-hand write skeleton`, `write step <S>`, `write fix <row>` or `write reached` |

Outside the run, a bare `tw-post`, `tw-post --amend`, `tw-close` or `tw-tell` refuses while another live session holds
the run's lock, while this folder is not at the saved head, or while records are saved and this folder has none. A
hand-call saves only when it posted, and only at the saved head. In `/vid run` the round marks its own calls: no change.

## The hand-back

One line per item carried out, in the round's order: `published #<n>` with its kind and step; `amended #<n>` and
what named it; `withdrawn #<n>`; `refused` with its first reason.

Then a count line: published, amended, withdrawn, refused, and what `due` still owes. Nothing else: no summary of
the tickets' content, no advice on the plan.
