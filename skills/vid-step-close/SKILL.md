---
name: vid-step-close
description: The step's close run in ticket mode, in both GitHub modes — once every ticket of a step is merged (in GitHub manual, accepted at a commit of main), ViD asks for the step's rows to be run in every engine, reads the run, and closes the step, or sends its red rows to one fix line; through one script, `close.sh`. `/vid:vid-step-close <step>` asks an owed close now, reads one that is out, or says what is missing; /vid run's round and /vid next's step 2 run the same entries. Use when the owner says "vid step-close", or asks for a step's close now.
---

# /vid:vid-step-close (GM-4 K3)

The order of a step's close and how each line is said, nothing more: when a close is owed, what it asks, how its run is read,
what closes a step and every refusal are `checks/close.sh`'s (its header says each). The fix ticket a red close owes is the
vid-tickets skill's; a close is asked or read by `close.sh` alone.

## The owner's command

`/vid:vid-step-close <step>`: `sh checks/close.sh step <step>` (GM-4 K3), the step close's one entry in both modes.

1. **The lock.** Inside /vid run's own conversation (this session holds the run's lock), run the entry alone: the lock stays
   held. Anywhere else, the vid-connect skill's start first, `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start`, and its end after,
   `sh checks/connect.sh end`, however the entry ends (GM-4 S0). While another session holds the lock, the start says so, and
   nothing is asked.
2. **The entry.** A close that is out: it fetches the reports and makes the one read first, then reads the run as the round
   reads it. A close that is owed: it asks it. Otherwise it posts and writes nothing, and says what is missing. Say each line it
   prints, as below:

| Line | What you do |
|---|---|
| `out <step> #<ask>` | Nothing yet: the close is out on issue #<ask>, and its run is not all in. Say so, in one line |
| `refused <step>: <what is missing>` | Exit 1, nothing posted: say the reason as it stands (a ticket of the step with no merge on record, the ticket writer owing the step a ticket, a close ask waiting on the owner's answer or on a fix, the stage's candidate due, no engines on record, the reports not fetched or the read failed) |
| `refused <step>: closed already` | Nothing more: the step closed earlier |

## The close's lines, in both modes

In GitHub auto the entry is also `close.sh owed`, `ask` and `decide` through /vid run's round (`round.sh step` and `next`),
unchanged; in GitHub manual through /vid next's step 2 (`round.sh step` and `asks`). /vid run loads this skill at its start and
says these lines as it says them.

| Line | What you do |
|---|---|
| `close <step>` | Nothing: `next` asks for the close run (in GitHub manual, `round.sh asks`) |
| `asked <n> close <step>` | Nothing: DevAgent runs the chunks |
| `closed <step>` | Say it to the owner, once: the step closed on a run in every engine |
| `close-again <step> <chunk>`, `close-lost …`, `close-red …` | Nothing for the first; the others are `Q<n>` lines for the owner. Where ViD's line gives no recommendation, give none of your own: relay the line as it stands, with the owner's earlier answer it shows (0.26.11.1.4, R2) |
| `failing <row>`, `close-fix <step> <rows>`, `close-done <step>` | Nothing: a close's red rows read failing and go in one fix line, which `next` makes one fix ticket; once its fix tickets merge, `next` asks the whole close again (v0.26.10.25.4) |
| `close-twice <step> <row>` | A `Q<n>` line: the row failed again after its fix. Tell the owner both reasons, and go on; their `again` writes another fix line, their `limit` rules it a known limit |
| `close-shrink <step> <rows>` (0.26.10.29.2, R7) | A `Q<n>` line: the close asked again after its fix tickets merged is red on rows that are not a strict subset of the close before it, so the fix loop has not shrunk and no fix line is written. Tell the owner both closes' red rows, as the line names them, and go on; their `again` writes the fix line, their `limit` rules the rows red now known limits. A stage's C3 is read the same way |
| `close-numbers <step> <k> …` | Say them to the owner, once: regressions introduced, defects still open, rows fixed, against the step's last close |
| `regression <close> <n>` | Tell the owner in one line, and go on: that close introduced `<n>` regressions. The status's debt line carries it until a later close of the step reads zero, or the step closes. The red close's plan change is already recorded; nothing more is asked of you (v0.26.10.26.3) |

## GitHub manual (GM M8, GM M3)

- **A closed step's tickets are closed** (GM M8: a step is decided on its ticket). Once `close.sh` writes `closed <step>`, each
  open published ticket of the step gets one comment, `vid: closed — the step's close passed at <commit12>`, and is closed:
  `ticket-closed #<n>`, said with the `closed <step>` line. `ticket-open #<n>`: GitHub refused the closing; it is tried again
  at each later close read, so say it once and go on. A ticket the team closed after its acceptance is recorded, with no comment.
- **A landing's withdrawals wait for the apply** (GM M3: every pending change reaches the team only through the apply move). A
  close ask a pending landing withdrew is neither told nor closed, nor asked again, until the applied commit holds that landing:
  `refused <step>: its close ask <k> was withdrawn by the landing <L12>, which the applied commit does not hold yet` says so, and
  the apply (the vid-replan skill's `implement-replan` move) lets the close be owed again.
