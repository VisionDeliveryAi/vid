---
name: vid-connect
description: Internal — the start and the end of every ViD call in ticket mode, in both GitHub modes, one line each. The connect, for every caller (/vid run, /vid next, /vid mode and every direct call): the refresh of checks/ first, the mode, the repositories, the records' restore, the lock, the notices, GitHub's access check and the call's stage, then Slack. The run's start, for /vid run alone: the run's stage, its state, the watcher, the context line and the dev side's start. At the end the call's stage ended, the records saved and the lock freed. Not a verb.
---

# vid-connect

One job: connect a call, and close it. It decides nothing. Every rule is in `checks/connect.sh` and `checks/github.sh` (GM-4 F2).

## In every call

- **Dates (FB-5 C1).** A date or a time written anywhere is read from a command (`date -u +%Y-%m-%d`, `date -u +%Y-%m-%dT%H:%M:%SZ`), never from the conversation.
- **Search, then ask (FB-5 C3).** Before a question to the owner, search the answers, the decisions and the spec: a line that settles it is done and told in one line, never asked. Before saying that the spec settles something, quote the line's id and words: with no line, it is open, and the owner's.

## The connect, for every caller

1. `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start`, the plugin's own copy, from the project's top level. In an empty folder
   with a state repository named, `--state <owner/name>`: the records are restored from it first, and a repository that is not
   private is refused. It runs the mode, the repositories, the records' restore and the lock first, then the refresh of
   `checks/`, the notices, `github.sh access` and the stage. Say each line it prints, in plain
   words:
   - `connect mode:` a refusal, said in one line as it prints it; nothing is recorded and no lock is held. A project whose `.vid/RUN-STATE.md` does not say `mode: tickets`: "this project is not in ticket mode". A project the old ticket mode planned (0.26.10.28.1, stage 9 R4) — `mode: tickets`, a `.vid/tickets/` folder and no `.vid/tw/settings`: "This project was planned by the old ticket mode; re-plan it with /vid plan.". A project recorded in GitHub team, which is retired (FB-1 C1): "this project is recorded in GitHub team, which is retired: /vid mode manual moves it to GitHub manual"; only `/vid mode`'s own call passes, to move it over. In GitHub manual with no `state-repo:` in `.vid/tw/settings` (GM M15): ask the owner for it as the line says. The run's start in GitHub manual (GM-1 S1): "this project is in GitHub manual: call /vid next"; `checks/round.sh` refuses too, as a backstop.
   - `connect repo:`, `connect spec-repo:`, `connect state-repo:` (FB-2 A1): for each repository `.vid/tw/settings` names, the code repository `repo:`, ViD's spec repository `spec-repo:` and its state repository `state-repo:`, when `.vid/tw/log` has no line for it under the name the settings hold now, `github.sh code-setup`, `spec-setup --make-only` or `state-setup` makes it, private and empty, or checks the one named (the spec and state repositories private; the code repository used as it is). With `layout: one` in GitHub manual there is no spec repository: ViD's export is kept in the project (FB-3 B2), so `connect spec-repo:` is not made, whatever the key says. Naming a repository at the setup is the owner's yes to make it. It exports nothing (the first export is a move's or the round's, under the lock). When the settings name a `spec-repo:`, unless the project is in GitHub manual with `layout: one`, or `sh "${CLAUDE_PLUGIN_ROOT}/checks/devagent-start.sh" mode` prints `auto` (GitHub auto, v0.26.10.28.8 R10: ViD's own DevAgent works on the owner's same `gh` sign-in, and needs no read access given), tell the owner, in one line, to give DevAgent read access to it and to the code repository.
   - `connect records:` `github.sh state-restore`, which brings a folder behind the records up to date and does nothing to one that is current.
   - `connect lock:` `github.sh lock-take`. If it refuses, say what it said in plain words, write nothing, and end: `run:` belongs to the session that holds the lock. A lock not renewed for 15 minutes may be taken, and the refusal says when.
   - `connect refresh:` the refresh prints `refresh: current`, or copies the plugin's `checks/` over `./checks/` and commits it alone (`VID_ROLE=fix`, `Refresh checks/ to VID <version>`).
   - The WSL notice (0.26.11.1.3, R2), `sh "${CLAUDE_PLUGIN_ROOT}/checks/lib/wsl.sh" notice`, which the connect runs: it prints nothing except once on a native Windows shell with no answer recorded for this PC: there it checks that WSL starts, records the answer and prints one line. Show the owner that line as written, and go on; it asks nothing.
   - `connect hooks:` the commit checks (FB-1 A1), `connect.sh hooks`, which the start runs right after the notices. With `core.hooksPath` already set, by ViD or another tool, it prints nothing. Else it runs the project's courts on the tree: all passing, it switches the checks on and says that a commit made by hand now needs the message lines `REQs:`, `Decisions:` and `Seams:`; one refusing, it prints a `refused by <court>` line for each, and that the next call switches them on once those are closed. Show the owner those lines as written, and go on; they never end the call.
   - `connect access …`: GitHub's access check, one line a part.
   - `connect stage:` the call's stage, opened once (`stage name=replan`), so every script the call runs finds the gate on and
     opens none of its own; or none, when a stage holds the gate on already. With `--run` (/vid run's alone), the run's start
     below in its place.

   By its exit:
   - 0, `connect: ready`: go on.
   - 3, the refresh waits: it lists the local edits a copy of `checks/` would overwrite, and the lock is freed. Show the owner the
     list and ask once. On a yes, run `connect.sh start --yes` at once, with the same options. On a no, record it,
     `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" refresh-no "<their words>"`, the one record of that no, and end the call: every
     later call ends at the refresh until the owner says yes.
   - 1, a refusal or GitHub not ready: end the call. The lock is not held: the script frees it.
2. **Slack.** Read `slack-channels:` in `.vid/tw/settings`.
   - `none`, or no such line: say "Slack: not used".
   - Otherwise say whether this session has a Slack connector's tools (a tool whose name holds `slack` and reads a
     channel). With none, say "Slack: no connector in this session". With one, read each channel the setup names once,
     its newest message alone, and say for each "Slack <channel>: read" or "Slack <channel>: not read, <why>".
   - A Slack line not ready is said, and the call goes on: Slack never stops a call.

## The run's start, /vid run's alone

`connect.sh start --run`, for /vid run alone (no other caller passes `--run`), at each `/vid run` start, a resume included, and
again whenever a session takes over. In place of the call's stage, after access, its lines:

- `connect stage:` the run's stage, `stage name=run state=start session=<the session> records=29`.
- `connect run:` the run's state, RUN-STATE's keys: `run: active` unless a pause is recorded, or a hold whose stage has closed (`run: stopped owner asked to hold after stage <N>` with its `stage-closed <N>` line: v0.26.10.26.5), `session:`, `plan: required`, and `run state=active` recorded. A recorded pause, `run: stopped owner asked to pause`, stays: the session keeps reading and deciding, and `round.sh next` publishes nothing.
- `connect watcher:` `sh checks/observe.sh start`, then `sh checks/observe.sh alive`, which exits 0 only when the watcher ticked here within the last 30 minutes. Not alive: tell the owner what it printed; the run is stopped, `run: stopped the watcher is not running`, the records saved and the lock freed, exit 1: end. Its notices are `observe: notice —` lines in the run's heartbeat.
- The context line, `sh checks/brief.sh context`: say its line. Then `sh checks/brief.sh plugins`: give the owner its lines when it names any plugin. It never stops the run. The compaction question is the vid-answer skill's.
- The dev side's start (v0.26.10.28.8, R4), `sh "${CLAUDE_PLUGIN_ROOT}/checks/devagent-start.sh"`, which the run's start runs after the refresh and before the loop. In GitHub auto (the owner's setup answer, `github-mode: auto`) it prints the line that makes DevAgent's work folder, the filled-in job note and where to save it, the first way to start DevAgent (`/vid:vid-devagent <job note>` in a new Claude Code conversation in the work folder, R12), then the background line, and the lines for check, list, used and down; in GitHub manual, or with no answer, it prints nothing. Show the owner devagent-start.sh's output as it is, unchanged, and go on: never run those lines yourself, never write the note, and never wait for the dev side.

## The end

`sh checks/connect.sh end`: the call's stage ended (when the start opened it), the records saved, then the lock freed, one line
each. Run it on every way the call ends once the start held the lock, a failure included. If it exits 1, say which line failed.
In `/vid next` it comes after the moves named and the page (GM-2 T10): every move runs inside the lock the start took and the
stage it opened, and nothing waits on the owner while the lock is held. /vid run ends by its own stops.
