---
name: vid-devagent
description: Start ViD's own DevAgent, the dev side of GitHub auto, in a Claude Code conversation of its own, and follow it there — each pass shown in plain words as it ends, and a stop as soon as it is written. Typed in a new conversation opened in DevAgent's work folder, with the job note's path. Use when the user says "vid devagent", "start DevAgent here", or types /vid:vid-devagent <job note>.
---

# /vid:vid-devagent <job note>

This conversation starts DevAgent and follows it. DevAgent itself is its loop, which this conversation starts and never replaces: the loop's passes, limits, checks and stops are its own, and each pass is a fresh dev manager the loop starts. This conversation only shows them.

Every command here is one of DevAgent's own, run on DevAgent's script in the plugin, with `"<the note>"` the job note's path, quoted as given. Run no other script, read no file but the job note's head and what those commands print, and write nothing.

## Before anything

1. **The note.** No path given: ask for it in one line and stop. Read its `work:` line. When this conversation's folder is not that work folder, say so in one line, with the line to open the right one: `cd '<work>' && claude`, then `/vid:vid-devagent '<the note>'`. Stop.
2. **Say once, in one short block**, before the first command:
   - DevAgent runs on this machine, in its own process, apart from this conversation. Closing this conversation, or quitting Claude Code, ends only this view: DevAgent runs on. Stop it by saying "stop" here, or from any terminal with the down line `/vid:vid-run` printed.
   - Typing `/vid:vid-devagent` again in this folder follows the running loop, or starts one if none runs; it picks up where it stopped.
   - A word typed while this conversation waits is read when the wait ends, within 9 minutes. Pressing Esc ends only the wait, never DevAgent.
   - A permission prompt for the wait pauses only this view.
   - This conversation's turns run on whatever model this session uses; they only follow. DevAgent's agents run on the note's `model:`.

## Start, or follow what runs

3. `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" follow`, in the work folder, before anything is started: it prints whether a loop lives and `mark: …`. Keep the mark, so nothing the loop writes from here on is missed, a stop at its very start included. When its first line is `loop: alive, pid <p>`, a loop runs already: say so in one line, start nothing, and go to 5. (`sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" list` shows more, if the user asks what runs.)
4. Otherwise `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" check "<the note>"`. Show what it printed. On `missing:` lines, say each in plain words and stop: nothing is started. On `ready`, `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" up "<the note>"`, and show its one line.

## Follow

5. Then, from the mark kept at 3, again and again, in the foreground with the Bash tool's timeout at 600000: `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" follow <the mark>`. It waits with no model and returns at once when a pass ends or the loop writes a stop, and otherwise within 9 minutes with `nothing new`. Each time:
   - **Each `pass <id> ended: …` block, or `pass <id> cut off by the stop: …`:** say it in plain words, in at most three lines: which ticket, what the dev manager did (its hand-back's lines, shortened), and the report it pushed, or that it pushed none.
   - **Each `stop: …` line:** say it at once, word for word. It is the loop's own stop, the one ViD hears about.
   - **`nothing new …`:** say nothing, and wait again.
   - **`loop: not running`:** say that DevAgent has stopped, with the stop's words if they were shown (a `stop:` line, or the `last words of its log:` line under it), and that `/vid:vid-devagent` again in this folder starts it. Then stop following.
   - Keep the new `mark:` for the next wait.
   - **`and more passes: …` or `and more stops: …`:** the call held some back at its cap. Call again at once, from the new mark: it returns at once with the rest. `loop: not running` comes only once nothing is held back.
   - A wait that ends without its lines (Esc, a refused permission, a timeout): say so in one line and wait again from the last mark you kept.

## Stop

6. On the user's word "stop", or "stop DevAgent": `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" down "<the note>"`, show what it printed in one line, and stop following. Any other message: answer it in one line, then wait again.

## Never

Start an agent, a run or a loop yourself but through `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" up "<the note>"`; stop anything but through `sh "${CLAUDE_PLUGIN_ROOT}/devagent/dev-manager/dm.sh" down "<the note>"`; edit the job note or any file of the work folder; read the repository, the issues, or any record outside what these commands print; or change what a pass did.
