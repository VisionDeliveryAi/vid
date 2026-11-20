---
name: vid-connect
description: Internal — the start and the end of a ViD call in ticket mode, one line each: the refresh of checks/ first, then the records' restore, the lock and GitHub's access check, then Slack; at the end the records saved and the lock freed. Invoked by /vid next and /vid mode; written so /vid run can invoke it too. Not a verb.
---

# vid-connect

One job: connect a call, and close it. It decides nothing. Every rule is in `checks/connect.sh` and `checks/github.sh`.

## The start

1. `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" start`, the plugin's own copy, from the project's top level. It runs the
   refresh of `checks/` first, before anything is restored or locked, then the restore, the lock and `github.sh access`.
   Say each line it prints, in plain words.
   - Exit 0, `connect: ready`: go on.
   - Exit 3, the refresh waits: it lists the local edits a copy of `checks/` would overwrite, and no lock is held. Show
     the owner the list and ask once. On a yes, run `connect.sh start --yes` at once. On a no, record it,
     `sh "${CLAUDE_PLUGIN_ROOT}/checks/connect.sh" refresh-no "<their words>"`, and end the call: every later call ends at
     the refresh until the owner says yes.
   - Exit 1, GitHub is not ready: end the call. The lock is not held: the script frees it.
2. **Slack.** Read `slack-channels:` in `.vid/tw/settings`.
   - `none`, or no such line: say "Slack: not used".
   - Otherwise say whether this session has a Slack connector's tools (a tool whose name holds `slack` and reads a
     channel). With none, say "Slack: no connector in this session". With one, read each channel the setup names once,
     its newest message alone, and say for each "Slack <channel>: read" or "Slack <channel>: not read, <why>".
   - A Slack line not ready is said, and the call goes on: Slack never stops a call.

## The end

`sh checks/connect.sh end`: the records saved, then the lock freed, one line each. Run it on every way the call ends once
the start held the lock, a failure included. If it exits 1, say which line failed. In `/vid next` it comes after the moves
named and the page (GM-2 T10): every move runs inside the lock the start took, its script calls marked as the call's own
(`VID_CALLER=next`), and nothing waits on the owner while the lock is held.
