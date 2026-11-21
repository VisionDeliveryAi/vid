---
name: vid-stage-close
description: The stage's end in ticket mode, in both GitHub modes — once every step of a stage is in and its candidate named, ViD asks the stage's full run and grade, starts and reads the walk of the staged product, writes the stage's summary in plain product words and closes the stage; with nothing left, it computes the completion report. Through `close.sh`, `walk.sh` and `end.sh`. `/vid:vid-stage-close <stage>` does whichever is next now, or says what is missing; `walk`, `read-walk` and `summary <stage>` do one alone; `end` computes the end. /vid run's round and /vid next's step 2 and moves run the same entries. Use when the owner says "vid stage-close", or asks for a stage's end now.
---

# /vid:vid-stage-close (GM-4 K4)

The order of a stage's end and how each line is said, nothing more: when a stage's run and grade are due, when its walk is due,
what closes a stage, what completes the run and every refusal are the scripts' (`checks/close.sh`, `checks/walk.sh`,
`checks/end.sh`; each header says them). The staging and production okays are the vid-deploy skill's; the owner's rulings on the
stage's findings, the vid-answer skill's.

## The owner's commands

- `/vid:vid-stage-close <stage>`: `sh checks/close.sh stage <N>` (GM-4 K4), the stage's end's one entry in both modes. It does
  whichever is next by the close's conditions: it asks the stage's full run and grade when they are due, starts the walk when it is
  due or reads it once its walker ended, writes the summary's facts, or closes the stage. Otherwise it posts and writes nothing,
  and says what is missing.
- `/vid:vid-stage-close walk <stage>`: `sh checks/close.sh walk <N>`; `/vid:vid-stage-close read-walk <stage>`:
  `sh checks/close.sh read-walk <N>`; `/vid:vid-stage-close summary <stage>`: `sh checks/close.sh summary <N>`. Each does that one
  alone, or says why it is not due.
- `/vid:vid-stage-close end`: `sh checks/end.sh complete`, in either mode.

1. **The lock.** Inside /vid run's own conversation (this session holds the run's lock), and inside /vid next (the call's start
   holds it), run the entry alone: the lock stays held. Anywhere else, the vid-connect skill's start first,
   `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start`, and its end after, `sh checks/connect.sh end`, however the entry ends (GM-4 S0). While another
   session holds the lock, the start says so, and nothing is asked.
2. **The entry.** Say each line it prints, as below and as "The stage's lines" say. A refusal exits 1: nothing was posted or
   written.

| Line | What you do |
|---|---|
| `refused stage <N>: <what is missing>` | Say the reason as it stands: a row failing, the stage's run or grade not passed, closed already at its commit, no candidate due, no walk due or none to read, the handed record naming no engines yet |
| `walk-brief <N> <folder>`, `walk-started <N> <pid>` | The walk's brief is written and its walker started by `walk.sh start`, a session of its own: say so in one line. Nothing waits for it; its walk is read once it ends |
| `facts <N> <k> at <path>`, then `summary <N>` | Write the summary beside those facts, as the `summary <N>` row below says |

## The stage's lines, in both modes

In GitHub auto the entries are also `close.sh ask --stage`, `summary` and `close-stage`, `walk.sh` and `end.sh complete` through
/vid run's round (`round.sh step` and `next`), unchanged; in GitHub manual through /vid next's step 2 (`round.sh step` and `asks`)
and the moves below. /vid run loads this skill at its start and says these lines as it says them.

| Line | What you do |
|---|---|
| `stage <N>`, `asked <n> close stage-<N>`, `asked <n> grade stage-<N>`, `candidate <N> <c>` (v0.26.10.26.1) | Nothing by hand: the round names the stage's candidate, main's newest merge, once every step of the stage has merged and its rows are accepted, ruled or owed; it asks C3, the full run, and S1, the stage grade. Say the candidate to the owner, once |
| `stage-c3 <N> passed`, `s1 <N> read`, `s1-refused <N> <k>` | Say a green C3 and the grades once; a refused S1 report is posted back to GR by the round. The stage's findings are counted in the status, and the owner rules them from 0.26.10.26.4 |
| `walk <N>` (v0.26.10.26.4) | Write the brief, `sh checks/walk.sh brief --stage <N>`, and start the walker, `sh checks/walk.sh start --stage <N>`: a session of its own on `claude-opus-5-5`, in the brief's folder outside the project, with nothing of yours. Never walk it yourself, and never tell it more than its brief. In GitHub manual, only through the owner's move (below) |
| `walk-read <N>` | The walker ended: `sh checks/walk.sh read --stage <N>` (in GitHub manual, through the owner's move). Say `w1 done` once; `w1 not-done <why>` is a `Q<n>` line (often no browser: say so plainly), whose `again` walks the same staged commit again; a refused return starts the walker once more, and a second is a `Q<n>` line. When `<why>` is `browser: none`, the owner may answer instead "close without the walk" (0.26.10.28.6): the owner's alone, so run `sh checks/queue.sh answer Q<n> close without the walk` only on the owner's own words, never `--by RM` or as a stood-in answer; the walk becomes a known limit, "walk not done: no browser on this machine", with who and when, and the stage closes without it. A not-done for any other reason (an unreachable address, a failed sign-in) has `again` alone. A stage with no screens and no journey row owes no walk: no `walk <N>` comes, and its walk is recorded "no walk: this stage has no screens and no journey" |
| A stage's finding, `stage:<N>:…` | A `Q<n>` line for each, from S1, the rest chunk and W1: the owner answers `row "<words>"` (or `fix`), `no`, `known`, or `later <M>` (a later stage, which asks it again there), each through the vid-answer skill. `row` prints a `door:` line: run the vid-fix skill's ticket-mode branch on it. You may recommend, `sh checks/queue.sh recommend Q<n> <answer> "<why>"`. 7.5's close needs none open |
| `close-stage <N>`, `summary <N>` (v0.26.10.26.5) | The stage's six conditions hold at its candidate. Write `<c>/summary.md` from `<c>/facts.txt`, in plain product words with no row ids: **Working now:** each `working` requirement by name · **Went back:** each `went-back` fact by its requirement's name, or "nothing" when there is none · **Decided for you:** each `decided` line, one line each, with its id: every answer given in the owner's place since the newest close (yours, a delegate's or a stand-in's, held-row rulings and the round's own stand-in rulings included, each with who gave it), each DECISIONS.md line added, the dev side's among them, and each `model_proposed` PRD answer added (0.26.10.29.5, DP-1 R4). A `walk` line (0.26.10.28.6) is said as it stands, word for word: why the stage had no walk, or the walk not done and who answered when. The stage closes once the summary exists (`next` in GitHub auto; `round.sh asks`, or `/vid:vid-stage-close <N>`, in GitHub manual); `summary-refused <N> <why>` says what it missed, and the summary is asked again. In GitHub manual, only through the owner's move `write-summary` (below) or the owner's own `/vid:vid-stage-close` command, which is the owner naming it |
| `stage-closed <N> at <commit12>`, `held after stage <N>: the run stops` | Tell the owner in one line, with the summary, then print `sh checks/queue.sh status`, and go on. A hold's stop stops only the next stage: corrections of stage N go on |
| `nothing-left` | Once the final stage is closed (v0.26.10.27.4): `sh checks/end.sh complete`, which computes completion from the records and writes `.vid/decide/completion.md`. `complete`: tell the owner in plain words what the report says and where it is. `unmet <n>`: say what is unmet. Before the final close, `nothing-left` is no end. In /vid run each ends the run as its stops say. Never write `run: complete` yourself: only `end.sh` writes it, and in GitHub manual it writes none (below). The report is no production okay |

## GitHub auto

**The owner's "hold after this stage"**, in /vid run: `sh checks/queue.sh control hold "<their words>"`: stage N+1 is admitted no
further, stage N builds on to its close, and the run stops there. Their "continue" after the close ends it and prints how many
merges staging runs past the held stage's closed candidate.

## GitHub manual (GM M16, D4)

- **The walk and the summary are moves the owner names** (GM M16: the stage's end is done at the moves named). When step 2 prints
  `walk <N>`, `walk-read <N>` or `summary <N>`, the call lists the move `walk-stage <N>`, `read-walk <N>` or `write-summary <N>`,
  which runs this skill's `walk`, `read-walk` or `summary` action; nothing starts and nothing is written until the owner names it.
  The walker is a session of its own, started by `walk.sh start`, and no call waits for it: a later call lists `read-walk <N>` once
  it ended. In GitHub auto the run does them by itself, as above.
- **A published step's stage is its ticket's** (D4): the stage its published ticket's header names, as the planner reads it.
- **The end**, decided for the owner: `end.sh complete` writes the completion report in both modes, and in GitHub manual leaves
  out the `run: complete` line and its event, for the owner may still change the spec through the door at any later call.

## The moves, in /vid next

Each is named by its kind and its stage, the owner's words the last, and runs only when the call listed it:

- `walk-stage <N> "<words>"`: `close.sh walk <N>`. `done walk-stage <N>: the walker started (pid <p>), …`: say that the walk is
  under way in a session of its own, and that a later call reads it.
- `read-walk <N> "<words>"`: `close.sh read-walk <N>`. `done read-walk <N>: <the walk's line>`: say the walk's line as the
  `walk-read <N>` row above says it.
- `write-summary <N> "<words>"`: `close.sh summary <N>`. `done write-summary <N>: facts …`: write `summary.md` beside the
  `facts.txt` that line names, as the `summary <N>` row above says; the stage closes at the next call's `round.sh asks`, or at
  `/vid:vid-stage-close <N>`.
- `refused <move> <N> at the stage's <action>: refused stage <N>: …`: nothing was started or written; say the reason as it stands.
