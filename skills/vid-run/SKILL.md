---
name: vid-run
description: Run a ticket-mode project as one long session — decide each ask, record each merge, re-plan, publish the next tickets, and wait with no model while nothing is new, with ViD's records on GitHub so that a session or its folder can be lost and a new one resumes. `/vid run <state repo>` in an empty folder restores first. Use when the owner says "vid run", "run the tickets", or wants ticket mode to go on.
---

# /vid run

One long session runs the tickets to the end. It writes no code, reads none (see "DevAgent's code") and starts no run: DevAgent starts every run, on what ViD asks on the ticket. `checks/round.sh` does what needs no judgement. You do what does: re-planning, answering from the spec, and telling the owner.

**A session that dies stays dead until someone runs `/vid run` again** (the owner types `/vid:vid-run`). Nothing restarts it. The watcher tells the owner, and that is all it does.

## Before any work

**The skills.** First invoke the `vid-connect`, `vid-read`, `vid-tickets`, `vid-accept-step`, `vid-step-close`, `vid-stage-close`, `vid-deploy`, `vid-answer`, `vid-replan`, `vid-triggers`, `vid-grade`, `vid-spec-publish` and `vid-sort` skills (the Skill tool), and again whenever a session takes over: Claude Code restores after a compaction only the skills that were invoked.

**The plan, first** (FB-2 A2). Without `--state` (an empty folder restores first, and its plan is in the records), when `.vid/plan/ratified` holds no `ratified` line, no plan was ever approved: invoke the `vid-plan` skill (the Skill tool) and do its sitting, the setup questions first, before the start below. At its page the sitting waits for the owner's words. End the turn there, asking for them; nothing is published and no lock is held. On the owner's yes the sitting's "The owner's words" ratifies and records the go, as it always has; then the start below. If the owner answers that a team of people works the tickets, the sitting's GitHub manual route runs (the `vid-mode` skill): then say in one line that `/vid:vid-next` drives this project, and end. A ratification that lapsed later, after a change to a ratified file, keeps the run's own path: a project already planned never re-enters the sitting here.

**The start.** The vid-connect skill's run's start: `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start --run`, with `--state <state repo>` in an empty folder, and again whenever a session takes over. Where it ends the run, end.

Every event this skill names is written with `sh checks/event.sh '<event>'`. Rewrite `.vid/RUN-STATE.md` at each step that changes what it says.

## The loop

Run `round.sh wait` and `round.sh step` yourself, in the foreground, in this turn; never from a script of your own, nor in the background. Every `round.sh` call runs with the Bash tool's timeout at 600000. A command that passes its time, or runs in the background, never ends your turn: go on at 1, and look at it each time. A landing in the background alone is waited on, as "After any owner message" says. A question to the owner is text in the chat beside its `Q<n>` line, never a box or any call that waits for the answer, and the round goes on at once: only what that question's line gates waits. Once at each session's start: `sh checks/round.sh step`, then, unless it printed `stop`, `sh checks/round.sh next`. Then, again and again:

1. `sh checks/round.sh wait`, in the foreground, with the Bash tool's timeout at 600000. It blocks with no model, for at most 9 minutes, and prints `new` or `timeout`. A wait never ends your turn: on `timeout`, go to 2.
2. `sh checks/round.sh step`: the round's read of GitHub is the vid-read skill's one read (`round.sh`'s own, GM-4 F3). Read its lines, and act on them. **Say them before the next command** (FB-7 B3): the owner sees your text alone, never what a command prints. What a row has you tell, say or print, and each `Q<n>` line new in RUN-STATE.md, whole (the question, its choices, what it recommends where it does), is your text in the chat before anything more is run, so `step` ends its Bash call; a line `say to the owner now, as text: …`, any command's, is said so at once:

| Line | What you do |
|---|---|
| `decided <p> <head> ticket: …`, `merged <p>`, `decisions recorded pr=<p> …`, `decisions recorded deploy=<id> …`, `decisions wait draft=<n>`, `decisions unread …`, `decisions export failed: …`, `decisions refused …`, `held <row>`, `closed-outside <n> <step>`, `closed-stage-rows <s> <N>`, `step-reopened <s> #<n>`, `split <row>` | The vid-accept-step skill's lines for them, in /vid run |
| `main-changed` (v0.26.10.28.2) | The code repository's main changed (an empty repository's first commit, most often): `sh checks/round.sh next` now, as on new work (4), so a ticket refused for want of main is tried again |
| `question <n> <k>` | The vid-answer skill's line for it, in /vid run |
| `note #<n> <k> <first line>` (FB-7 B7) | The vid-answer skill's line for it, in /vid run |
| `finding <ticket> <severity> <words>` | The vid-answer skill's line for it, in /vid run |
| `close <step>`, `asked <n> close <step>`, `closed <step>`, `close-again <step> <chunk>`, `close-lost …`, `close-red …`, `failing <row>`, `close-fix <step> <rows>`, `close-done <step>`, `close-twice <step> <row>`, `close-shrink <step> <rows>`, `close-numbers <step> <k> …`, `regression <close> <n>` | The vid-step-close skill's lines for them, in /vid run |
| `stage <N>`, `asked <n> close stage-<N>`, `asked <n> grade stage-<N>`, `candidate <N> <c>`, `stage-c3 <N> passed`, `close-held <run> <row>`, `close-unrun <run> <chunk> <rows> #<ticket>`, `s1 <N> read`, `s1-refused <N> <k>`, `walk <N>`, `walk-read <N>`, a stage's finding `stage:<N>:…`, `close-stage <N>`, `summary <N>`, `summary-refused <N> <why>`, `stage-closed <N> at <commit12>`, `held after stage <N>: the run stops` | The vid-stage-close skill's lines for them, in /vid run |
| `grade-ask <n> read <k>: …`, `vs <n> <REQ> <word> — <reason>`, `grade-ask-refused <n> <k>`, `grade-again <n>`, `grade-lost <n>` | The vid-grade skill's lines for them, in /vid run |
| `okay staging <N>`, `asked <n> okay stage-<N>`, `d1 <N> passed`, `staged <N>`, `d1-failed <N> <step>`, `d1-refused <N> <k>`, `close-again staging-<N> d1`, `d1-again <N>`, `d1-item <N> …`, `door d1-failed <N> #<i> at <step>`, `door differs <N> #<i>: …`, `cs <N>`, `asked <n> cs stage-<N>`, `paid <row>`, `stage-cs <N> passed`, `stand-in <N> <row> — …`, `staging-again <N>`, `hold <N> Q<m>`, `setup hold: …`, `okay rehearsal <N>`, `cr <N>`, `okay production <N>`, `cp <N>`, `production-yes-asked <N> <c>`, `logs <N>: …`, `production-duty <N> <duty>: …`, `not-needed d2 <N>: …`, `cs-closed #<n>`, `recovery-asked <N> #<n>`, `recovered <N> #<n> at <commit>`, `production-lost <N> #<n>`, `in production <N> at <commit>` | The vid-deploy skill's lines for them, in /vid run |
| `plan-stage <N>` | The vid-replan skill's line for it, in /vid run |
| The owner's "use production data on staging", or "made-up data on staging" | The vid-deploy skill's, in /vid run |
| The owner's "hold after this stage" | The vid-stage-close skill's, in /vid run |
| `context-window Q<m>` (v0.26.10.26.7) | The vid-answer skill's line for it, in /vid run |
| `door: /vid fix — …` | The door, the vid-fix skill's ticket-mode branch, run here on the words the line gives |
| `landed <n> at <commit>: …`, `reopened <step>`, `withdrawn <step> <k>`, `withdrawn stage-<N> <c>`, `ask-open stage-<N> <i>`, `stage <k>` | The vid-fix skill's line for them, in /vid run |
| `plan-refused <step>: <why>` | The vid-replan skill's line for it, in /vid run |
| `update` | Print `sh checks/queue.sh status` unchanged, then the `next:` line of `sh checks/queue.sh backlog` (the vid-answer skill, the backlog) |
| `publish #<n> <words>` (FB-5 C2) | The vid-triggers skill's line for it, in /vid run |
| `flag devagent-quiet <items>: no sign since <UTC>` (FB-7 B1) | Tell the owner once, in one line: `No sign from the dev side since <UTC>: it owes <items>. Start it with /vid:vid-devagent <job note> in a new conversation in its work folder, or in the background with dm.sh up <job note>, or check that it runs.` It stops nothing |
| `flag devagent-stopped <id>: <why>` (v0.26.10.28.6) | Tell the owner once, in one line: `The dev side stopped: <why>. Start it again with /vid:vid-devagent <job note> in a new conversation in its work folder, or in the background with dm.sh up <job note>.` Its newest report is a stopped one; a later report clears it. It stops nothing, and ViD starts nothing |
| `flag ticket-left <n>: <why>` (FB-2 A3) | Tell the owner once, in one line: `DevAgent left ticket #<n>: <why>. When what it needs is in place, /vid:vid-tickets reopen #<n> "<your words>" has it taken up again.` It stops nothing |
| `flag <word> <what>` | Say it to the owner in plain words, once. It stops nothing |
| `refused <what>: <why>` | The vid-replan skill's line for it, in /vid run |
| `error <step> …` | Read it, and go on. A third error running is a stop, below |
| `lock-lost` | Stop at once, and write nothing |
| `busy: round.sh <what>, since <UTC>, pid <p>` (FB-7 B2) | Look again at 1; once it has been the same for 20 minutes, tell the owner in one line what hangs and since when, and go on looking. It stops nothing |
| `stop <why>` | A genuine block, below. Nothing more is published until the owner has seen it |
| `nothing-left` | The vid-stage-close skill's line for it, in /vid run: its `complete`, its `unmet <n>`, and a `nothing-left` before the final close, each end the run as the stops below say |
| `idle` | Back to 1 |

3. **Re-plan** after a step that printed something new: Invoke the `vid-triggers` skill and say its lines (GM-4 K9). A line that calls for a re-plan, its or the round's, is the `vid-replan` skill's GitHub auto paragraph: the run manager's own re-plan, `plan.sh change`, by the rules every change is made by, read where they stand.
4. `sh checks/round.sh next`, when a step reported something new, `main-changed`, `retry tickets` or `retry spec-publish <12>` among it, or the plan changed: the vid-tickets skill's round, which publishes what the plan now lets go out; say each line it prints as that skill says. The owner's own `/vid:vid-tickets` call in this conversation borrows the run's lock and leaves it held, as that skill says.

5. **Sort** (FB-5 A1), after a step that raised or changed an item of the owner's list: Invoke the `vid-sort` skill and say its one line; with nothing new, changed or moved it reads and sorts nothing.

**After any owner message** (v0.26.10.26.7, R3), act on it, say in one line what you did, then go on at 2. An answer that lands
a draft runs in the background (the vid-answer skill's step 3): until its task ends (its notice), go on at nothing, neither 2
nor any other step, since every step reads or saves the spec files and ViD's records the landing is writing. That wait ends
your turn with nothing else run, the lock kept, no stop and nothing saved or freed: the landing's notice starts your next
turn; say its output and go on at 2 (FIX-BATCH-T2 OW-5). Asking the owner never ends your turn. Only the stops below, and
that wait, end it. When everything left waits on the owner, the hold's Q line included, that is the waiting stop: the `vid-sort` skill first, then write `run: waiting`, save, free the lock, and end. The owner's answer, a bare "continue" too, then starts the run again. The same holds when the vid-fix or vid-add skill's ticket-mode branch hands back: back to the loop at 2.

**The owner's queue** and every answer, the owner's own, under their delegation or from the spec, are the vid-answer skill's: each goes through it, and is acted on at once.

**The owner's `/vid grade`** (v0.26.10.27.2) runs here, as `/vid fix` does: the vid-grade skill's ticket-mode branch, in /vid run, in the owner's words.

**A change to rows during the run** (v0.26.10.25.5) comes through one door alone, the vid-fix skill's ticket-mode branch, which /vid add, /vid stage and /vid incorporate draft through: what comes through it, its draft, its ask and its landing are that branch's.

The owner's "pause" is `sh checks/queue.sh control pause "<their words>"`, and "continue" is `control continue`: while paused, nothing is published or asked, and every decision and merge goes on. A continue with no pause to end, while the setup hold holds, ends the hold (v0.26.10.26.2); while the hold's `Q<m>` line is open, the owner's continue is that line's answer (the vid-deploy skill's). When the owner asks where things stand, print `sh checks/queue.sh status` unchanged, never a table of your own.

**Your own defects and lessons.** An `error` line: `sh checks/queue.sh defect <step> "<what it said>"`, and one plain line to the owner. A decision reading `failing, a weak test`: the vid-accept-step skill's lesson, in /vid run.

**Claims.** Say what happened from what the records show: progress is rows accepted, from `progress:`, and nothing you can't point to. Of anything asked of the dev side, say *asked*, never *told* or *under way*, until a sign after it. Each progress claim rests on an observation, through `sh checks/watchdog.sh`, as develop's does. A session default you decide while the owner is away (a limit, a wait, a setting you pick) is `sh checks/watchdog.sh note '<what and why>'`, in the heartbeat, as develop's (skills/vid-develop/SKILL.md § "Long-run supervision (§8)"), so a morning review reads it from the records (0.26.10.29.5, DP-1 R6).

## DevAgent's code

ViD never writes, reads or runs DevAgent's code (0.26.10.28.4, M5). From DevAgent's side it reads only: the results reports; issues, pull requests, their comments and labels; whether a commit is in the code repository and what it descends from; the deploy reports; and, for the walk, the running product on staging. `.vid/code`, made by `sh checks/github.sh results-fetch`, holds the reports and the commits, with no file of the code: each fetch proves it, and a copy that holds a code file is removed and the fetch refused. Of a report branch ViD reads and fetches its own folder alone, whatever else the branch holds; a branch with no such folder is left out and flagged (`flag report-skipped`). A merge is read through its pull request: title, body, comments and ViD's decision; never its files or its diff.

## The only stops

Before each but a lost lock, the `vid-sort` skill, so the owner's list is as the run leaves it.

- **The run complete,** the vid-stage-close skill's `complete`: `sh checks/github.sh state-save`, `sh checks/github.sh lock-free`, and end, leaving `run: complete` as it was written.
- **Everything left waits on the owner, the end's `unmet <n>`, or a `nothing-left` before the final close:** `run: waiting` with a `Q<n>` line saying what waits, record `run state=waiting`, `sh checks/github.sh state-save`, `sh checks/github.sh lock-free`, and end. The owner resumes with `/vid:vid-run`.
- **A genuine block, a `stop` line, or a third error running:** `run: stopped <reason>`, the same record, the save, `lock-free`, and end.
- **A lost lock:** `run: stopped lost the lock`, on no write to GitHub. End.

Nothing else ends the session. A long wait is no stop. A question or a held row on one ticket stops that ticket alone.

**You never:** write or change code or tests; read DevAgent's code; start or ask for anything but through the forms of a ticket; answer a product question the spec does not answer; rule a held row without the owner's word (their delegation is their word, recorded `--by delegate`); restart a session; push to the code repository (the vid-spec-publish skill's one request to GitHub, the spec folder's pull request, is its one exception: nothing is pushed from this machine); publish a release.
