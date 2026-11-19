---
name: vid-devagent
description: Start ViD's own DevAgent, the dev side of GitHub auto, in a Claude Code conversation of its own — its agents run either through the claude command, the conversation following each pass in plain words as it ends and a stop as soon as it is written, or in the conversation itself, which is then the dev manager, one pass at a time. Typed in a new conversation opened in DevAgent's work folder, with the job note's path. Use when the user says "vid devagent", "start DevAgent here", or types /vid:vid-devagent <job note>.
---

# /vid:vid-devagent <job note>

DevAgent's agents run in one of two ways, by the job note's `agents:` line (0.26.11.1.3, R5):
- **`agents: command`:** each agent is a `claude -p` of its own, which needs the `claude` command signed in. DevAgent is then its loop, which this conversation starts and never replaces: the loop's passes, limits, checks and stops are its own, and each pass is a fresh dev manager the loop starts. This conversation only shows them.
- **`agents: conversation`:** no `claude` sign-in is needed. This conversation is DevAgent's dev manager, one pass at a time, and each agent is a fresh helper it runs. There is no loop.

Every command here is one of DevAgent's own, run on DevAgent's script in the plugin, with `"<the note>"` the job note's path, quoted as given, and `claude auth status` for the mode's question. Run no other script. With `agents: command`, read no file but the job note's head and what those commands print, and write nothing but the note's `agents:` line.

## Before anything

1. **The note.** No path given: ask for it in one line and stop. Read its `work:` line. When this conversation's folder is not that work folder, say so in one line, with the line to open the right one: `cd '<work>' && claude`, then `/vid:vid-devagent '<the note>'`. Stop.
2. **The mode.** When the note's head has `agents: conversation` or `agents: command`: ask nothing, and go on in that way. When it has neither, run `claude auth status` and ask once, in one line, how DevAgent's agents should run: in this conversation, with no sign-in needed but this conversation kept open, or through the `claude` command, signed in, running on its own; and recommend `conversation` when `claude` is not on the PATH or its status does not say `"loggedIn": true`, and `command` otherwise. Write the answer as one line at the end of the note, `agents: conversation` or `agents: command`, the one line this conversation writes there, so the question is never asked again for this note.
3. **Say once, in one short block**, before the first command:
   - With `agents: command`, closing this conversation, or quitting Claude Code, ends only this view: DevAgent runs on this machine, in its own process. Stop it by saying "stop" here, or from any terminal with the down line `/vid:vid-run` printed. Typing `/vid:vid-devagent` again in this folder follows the running loop, or starts one if none runs; it picks up where it stopped.
   - With `agents: conversation`, this conversation is DevAgent: closing it stops DevAgent until the conversation is opened again, in this folder, with `/vid:vid-devagent` and the note. It picks up where it stopped: its state is on the repository and in the work folder.
   - A word typed while this conversation waits is read when the wait ends, within 9 minutes. Pressing Esc ends only the wait.
   - This conversation's turns run on whatever model this session uses. DevAgent's agents run on the note's `model:`.

## With `agents: command`: start, or follow what runs

4. `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" follow`, in the work folder, before anything is started: it prints whether a loop lives and `mark: …`. Keep the mark, so nothing the loop writes from here on is missed, a stop at its very start included. When its first line is `loop: alive, pid <p>`, a loop runs already: say so in one line, start nothing, and go to 6. (`sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" list` shows more, if the user asks what runs.)
5. Otherwise `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" check "<the note>"`. Show what it printed. On `missing:` lines, say each in plain words and stop: nothing is started. On `ready`, `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" up "<the note>"`, and show its one line.

### Follow

6. Then, from the mark kept at 4, again and again, in the foreground with the Bash tool's timeout at 600000: `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" follow <the mark>`. It waits with no model and returns at once when a pass ends or the loop writes a stop, and otherwise within 9 minutes with `nothing new`. A permission prompt for the wait pauses only this view, and Esc ends only the wait, never DevAgent. Each time:
   - **Each `pass <id> ended: …` block, or `pass <id> cut off by the stop: …`:** say it in plain words, in at most three lines: which ticket, what the dev manager did (its hand-back's lines, shortened), and the report it pushed, or that it pushed none.
   - **Each `stop: …` line:** say it at once, word for word. It is the loop's own stop, the one ViD hears about.
   - **`nothing new …`:** say nothing, and wait again.
   - **`loop: not running`:** say that DevAgent has stopped, with the stop's words if they were shown (a `stop:` line, or the `last words of its log:` line under it), and that `/vid:vid-devagent` again in this folder starts it. Then stop following.
   - Keep the new `mark:` for the next wait.
   - **`and more passes: …` or `and more stops: …`:** the call held some back at its cap. Call again at once, from the new mark: it returns at once with the rest. `loop: not running` comes only once nothing is held back.
   - A wait that ends without its lines (Esc, a refused permission, a timeout): say so in one line and wait again from the last mark you kept.

### Stop

7. On the user's word "stop", or "stop DevAgent": `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" down "<the note>"`, show what it printed in one line, and stop following. Any other message: answer it in one line, then wait again.

## With `agents: conversation`: this conversation is the dev manager

8. `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" check "<the note>"`. Show what it printed. On `missing:` lines, say each in plain words and stop. On `ready`, once: `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" here "<the note>"`. It sets the work folder up and prints a `DM_WORK=…` line: put that line before every later command of DevAgent's that this conversation runs, the dev manager file's included.
9. **Each pass:** read `${CLAUDE_PLUGIN_ROOT}/devagent/agents/dev-manager.md` whole, afresh, as a fresh dev manager would, and do one pass as it says, from its `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" next`. What it says a dev manager writes (job notes, records, comments, the report) this conversation writes.
10. **Each agent it starts:** `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" start <role> <job note> <clone>` starts nothing. It prints the agent's id, the prompt, the model, the limits and the hand-back path.
   - Run that prompt as a fresh helper, on that model, in the foreground, and wait for it to end. Past the limits it printed, stop it.
   - Write the helper's final message, whole, to the hand-back path; a helper stopped, or ended with no final message, leaves it empty.
   - Then `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" done <id> <the seconds it ran>`, and go on as the dev manager file says: the hand-back, a line in the record, then `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" take <id>`.
11. **A pass ended,** where the dev manager file ends one: say it in at most three lines: which ticket, what was done, and the report pushed, or none. Then the next pass. When `next` calls for nothing, say so, wait 5 minutes in one foreground call, and read it again. Past the note's `time-limit:`, stop and say so.
12. On the user's word "stop", or "stop DevAgent": let a helper that runs hand back and run `done` for it, end the pass as the dev manager file ends one, and say that DevAgent is stopped until `/vid:vid-devagent` is typed again in this folder. Any other message: answer it in one line, then go on.

## Never

- With `agents: command`: start an agent, a run or a loop yourself but through `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" up "<the note>"`; stop anything but through `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" down "<the note>"`; edit the job note, but for its `agents:` line, or any file of the work folder; read the repository, the issues, or any record outside what these commands print; or change what a pass did.
- With `agents: conversation`: start an agent but by a helper run in the foreground on the prompt `start` printed; give a helper anything beyond that prompt; or write a hand-back other than the helper's own final message.
