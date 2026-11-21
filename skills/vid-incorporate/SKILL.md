---
name: vid-incorporate
description: Incorporate a decision record or a proposal into a ViD project's spec — the owner names the record and says, in their own words, what to take; ViD reads it, shows the map (every place the spec changes, today's text, the change, the record's words; what is left out and why; what is open), writes the amendment (decision lines citing the record, replaced lines marked, architecture and stack edits, PRD appends where a promise changes, test rows for the new risks) and lands it through the mode's own door on the owner's yes. Never looks for records. Use when the owner says "vid incorporate", or names a decision record (ADR) or proposal (RFC) to take into the spec.
---

# /vid:vid-incorporate

One verb for a record someone already wrote: a decision record (a choice made) or a proposal (a change put forward).
The owner names it and says what to do with it ("this is a decision, take all of it"; "take the new write path, leave
the cost part for later"). Nothing else is read: a record the owner did not name is never read or acted on, and the
skill never goes looking for records. Requires an existing ViD project (CLAUDE.md with a ```vid-placement block),
else point the owner at /vid:vid-init.

Every call below is the project's `checks/` copy, run at the top of ViD's repository (the project, in develop). When
`checks/incorporate.sh` is not there, the project's `checks/` predates this verb: tell the owner it needs the refresh
(vid-develop's "Version skew"; in ticket mode, vid-connect's) and stop before any work.

## 0. The mode

- **develop:** `.vid/RUN-STATE.md` does not say `mode: tickets`.
- **GitHub manual:** `sh "${CLAUDE_PLUGIN_ROOT}/checks/devagent-start.sh" mode` prints `manual`. GM-3 U2: it drafts as GitHub
  auto does (one draft, one yes), so below, where a step names GitHub auto, GitHub manual takes it too.
- **GitHub auto:** `mode: tickets` otherwise (GitHub team drafts the same way, as `/vid add` does in ticket mode).

## 1. The input, the owner's words, the read

**The record** is, in every mode, a path in ViD's repository. It must be committed and unchanged:
`sh checks/incorporate.sh cite <path>` prints its cite, `<path>@<12-hex commit>`, and refuses otherwise. A path not yet
committed is committed first, on the owner's word, before it is read, so the cite names a commit (in GitHub manual
this is the only way a record the team wrote reaches ViD: the owner puts a copy in ViD's repository).

In GitHub auto it may also be a GitHub link, a file at a commit or a pull request: read it with
`sh checks/github.sh record-read <link>`, which writes nothing. Each file it prints follows a line
`record: <the blob link at that commit>`; that link is the cite. A pull request of several Markdown files gives one cite
a file: pass each to `check` with its own `--record`, and each new decision line's `why:` holds the one it rests on. In GitHub manual never call `record-read` and never
read a file of the team's repositories: the record is the owner's copy, a path, nothing else.

**The owner's words** say what the record is and what to take. Keep them verbatim: they go into the draft's `--why`
(GitHub auto, GitHub manual) or each commit's `Owner: "<words>"` trailer (develop). The owner asked for the
incorporation, so every incorporation waits for their yes, technical or not.

**The read.** Before writing anything, read the law in the order every door reads it: CLAUDE.md, PRD.md (base and
appends), BASELINE.md, ARCHITECTURE.md, DECISIONS.md; then the record, whole.

## 2. The map

The map is a file kept with the amendment, one entry a line (blank lines and lines starting `#` are skipped):

- a change: `<file> | <where> | today: <text, short> | change: <text, short> | record: <its words, short>`. For a new
  decision line `<where>` is its id, `D-NNN`; for a marked line, the marked line's id; elsewhere a section, row or line.
- `left: <file> | <where> | <why>`: a place the record names that the owner's words leave out, or a decision that
  brings no row (§4).
- `open: <question>`: anything the record leaves undecided. A link the record makes to an id (a decision, a
  requirement, a row, a section) that the spec does not hold is an `open:` line.

Its counts are `sh checks/incorporate.sh check`'s last line, `map: <c> changes, <l> left, <o> open`. Show the owner the
map and its counts in one plain message. Where it is kept: in GitHub auto and GitHub manual `land.sh draft --map` keeps it with the draft;
in develop it is `.vid/incorporate/<n>/map` (n the next free number), with the HEAD before the
amendment's first commit in `.vid/incorporate/<n>/base`.

In develop the map comes in **two parts**: the first holds the spec text (architecture, stack,
decisions, PRD) and its counts; the rows' lines (their changes and their `left:` lines) join it at their ratification
(§4). In GitHub auto and GitHub manual it is shown **whole**, after the rows are ratified.

## 3. The amendment

- **Every binding part is a decision line.** A rule the record sets (what writes where, what owns what, what must never
  happen) is a DECISIONS.md line in the template's form, its number from `sh checks/decisions.sh next` (one call per
  new line, made as the line is written: each call reserves the number it prints):
  `- **D-NNN** <what> | why: <why, then the cite> | enforced: convention | applies-to: <ids and codes>` (or `| scope:
  project` when it bears on many areas). Its `why:` holds the record's cite verbatim. Its `enforced:` is `convention`:
  its rows land after it, and a reference to a test not yet there is refused. Its label names the modules it bears on
  (new modules included: the architecture lands first) and the requirements it serves that existing rows derive from;
  it names no row this amendment adds, since those are committed after it.
- **ARCHITECTURE.md never carries a rule alone.** Edit it (and BASELINE.md) so the file stays true for a reader, but
  its prose is not quoted into briefs or tickets: every rule there is also a decision line.
- **A replaced line is marked, and only marked.** For each line a new one replaces, whole or in part:
  `sh checks/incorporate.sh mark <old D-id> <new D-id>` puts `| replaced-by: <new>` before the old line's ` | why:`,
  or adds the id to the mark it has. When the old line has no label the commit hook accepts, the helper labels it
  first, alone, through `checks/decisions.sh apply` (give it `--label "applies-to: <items>"` when you know where the
  line bears; it is `scope: project` otherwise). Never edit an old line's words, and mark nothing outside an
  incorporation.
- **A promise change goes through the answer route.** Where the record changes a promise (a requirement's statement
  or fail-if, a cost, what users see), append it to PRD.md exactly as /vid:vid-add's §2 does: a dated heading naming
  the source, `(/vid incorporate)`, the answers block with the owner's answer, the items in the PRD's grammar, the
  wording lens, the whole-set review in delta mode and its findings record, and the placement in STAGES.md a new
  pilot feature needs. Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running. A record that changes no promise appends nothing to the PRD.
- **The check.** Before the map is shown, and again before each landing:
  `sh checks/incorporate.sh check <map> --record <cite> [--record <cite>…] [--base <commit>] [--text]`. It refuses,
  naming each place, when a change is not on the map (DECISIONS.md by D-id, INVENTORY.md by row id, PRD.md by REQ id,
  the other files file by file), an old decision line's words change or a line is removed, the map names a change the amendment lacks, a new decision line lacks the cite or
  is not `enforced: convention`, a new or changed row derives from a decision id, a new row of any kind lacks its
  origin, or a new decision line has
  no row and no `left:` line. `--text` is the first part (develop): the spec text alone, INVENTORY.md
  untouched. `--base` is the HEAD before the amendment's first commit (`.vid/incorporate/<n>/base`).

## 4. The rows

The rows are the vid-test-inventory skill's (`${CLAUDE_PLUGIN_ROOT}/skills/vid-test-inventory/SKILL.md`), in
**append mode**, naming the delta as an incorporation's: the amendment's decision lines, with the REQs each one serves.
It derives over that delta with every axis, its genus lenses scoped to it, then the strength pass; presents NEW,
CHANGED, ORPHANED and UNCHANGED; and ratifies with its own questions, never one yes for items of different kinds.
- Each new row derives from the REQs its decision serves, never from a D-id, and carries
  `origin: incorporation <YYYY-MM-DD> D-NNN`; a rule row, which has no derived-from field, names its REQs after the
  D-id, `origin: incorporation <YYYY-MM-DD> D-NNN REQ-NNN`.
- A decision that serves no requirement and sets no rule a row can test brings no row:
  `left: DECISIONS.md | D-NNN | <why>`.
- A row whose premise the record changes (CHANGED) is amended in the same amendment, or named by
  `left: INVENTORY.md | <row id> | <why>`.
- Under tickets (GitHub auto and GitHub manual) and before the code skeleton, append mode stops after the
  ratification as it says: the rows are written `owed: spec-only — ticket` (or `— first stage`, or the owed form the
  inventory routes a row to, such as a deploy gate's), nothing materialised or run in ViD's repository.
- Append mode's own PRD records (its findings, and an open question it routes to the owner) are its own appends, not a
  promise the record changes: each gets a `PRD.md` change line on the map, by its id where it has one.

## 5. The landing, by mode

### develop

Outside a develop run, in /vid:vid-add's order, so no law file is left dirty under a commit:
1. Record `sh checks/event.sh "stage name=incorporate state=start session=$CLAUDE_CODE_SESSION_ID records=34 base=$(git rev-parse --short=12 HEAD)"`;
   a session that takes the incorporation over records it again with its first `base=`.
2. Write the first part in the working tree, `check --text`, and show the map's first part. On the owner's yes, the
   commits, each through the hooks with the owner's words in `Owner: "<words>"`: ARCHITECTURE.md and BASELINE.md (the
   lines in their law regions, `checks/lawfiles`, as a law commit of its own, since a law commit holds nothing else;
   then their other lines); then DECISIONS.md, with the marks, and any PRD append (the
   decisions commit); then any placement, as /vid:vid-add places. No yes: put the files back as HEAD holds them,
   record `sh checks/event.sh "stage name=incorporate state=end session=$CLAUDE_CODE_SESSION_ID"`, so the plan's guard
   holds nothing open, and stop.
3. Then §4 over the landed decision lines: ratified, the rows' lines join the map, `check` with `--base`, and the rows
   committed as append mode makes them, red and stamped.
4. The hand-over: record `sh checks/event.sh "stage name=incorporate state=end session=$CLAUDE_CODE_SESSION_ID"`,
   tell the owner the rows' counts in one line, then invoke the vid-develop skill (the Skill tool) and go on from its
   "Before any work". Inside develop the rows join the plan through `sh checks/plan.sh change add "<why>" --trigger
   scope-change --evidence commit:<the decisions commit> --expect "<one line>"`; work already built is changed only
   through the new and changed rows. An incorporation that brings no row (every decision a `left:` line, or every row
   declined at the ratification) has nothing to build: it still records the end event above, so the plan's guard holds
   nothing open, tells the owner the counts, and stops with no hand-over.

### GitHub auto

A draft through the door, the vid-fix skill's ticket-mode branch: no stage event, nothing committed. In the working tree: the spec
text, the rows ratified (§4), the map whole, `check`, the plan block as it will stand in a file (the step each new row
goes in, or a new step). Then the whole-set review in delta mode by a fresh agent, its output (`none`, or
`finding <row id> | <why>` lines) in a file. Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running. Then
`sh checks/land.sh draft --review <file> --why "/vid incorporate: <the owner's words>" --map <file> --plan <block>`
(refused, it names the check and keeps the tree); the door's ask and landing take it from there. The hand-back is the
door's: "the incorporation is draft <n>, asked as Q<k>", and that the owner's yes lands it.

### GitHub manual

GM-3 U2: a draft as GitHub auto's above, through the door, with GitHub manual's one difference as the vid-fix skill's
ticket-mode branch says it (no plan block: no `--plan`, placing the rows is `/vid next planning-analysis`'s):
`sh checks/land.sh draft --review <file> --why "/vid incorporate: <the owner's words>" --map <file>`. Nothing is
posted to GitHub; the change's `spec` lines show with it. The hand-back names the draft, and /vid:vid-next, where the
change waits as pending once landed.

## 6. Hand back

The map's counts, the rows' counts (append mode's buckets), and where it landed: the commits (develop),
or the draft and its question (GitHub auto, GitHub manual). Counts, never scores.
