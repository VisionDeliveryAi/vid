---
name: vid-read
description: The reads of a ViD call in ticket mode, in both GitHub modes: GitHub through the one read, `checks/round.sh read` into `.vid/round/read` (the round read; in GitHub manual each published ticket's body, its sub-issues at every depth and the issues assigned to the owner too), then Slack, when set up, for context alone. Invoked by /vid next; the owner's command `/vid:vid-read` shows it at any time. Use when the owner says "vid read" or asks what ViD reads on GitHub now.
---

# /vid:vid-read

One job: read, and write down what was read. It decides nothing, and never stops a call: it says what it could not read.

**Called by the owner** as `/vid:vid-read`, in either GitHub mode: inside /vid run's own conversation it uses the run's lock and
leaves it held; anywhere else the vid-connect skill's start first and its end after, however the call ends (GM-4 S0).

## GitHub

`sh checks/round.sh read`: the one read of GitHub (GM-4 F3), `github.sh round-read`'s lines written whole into
`.vid/round/read`; in GitHub manual with the ticket bodies, sub-issues and assignees, which `round.sh` adds itself. Say each
`unread` line it holds, in plain words: what could not be read, and why. In GitHub manual with one repository it also reads the names
and ids of the folder's files, no file's content (FB-4 B1, `.vid/round/folder`); a line saying that read failed is said, and stops nothing. On exit 1 the read failed and the file is as it
was: say the lines it printed.

## Slack, for context alone

Only when `slack-channels:` in `.vid/tw/settings` names channels and this session has a Slack connector's tools.

1. For each channel, read its messages since its mark in `.vid/next/slack-read` (`<channel> <the newest message's time>`,
   one line a channel; with no line, since GitHub manual was recorded, the newest `mode name=manual` event's time in
   `.vid/metrics-events`).
2. Match each message to a ticket, a sub-issue or a pull request of the code repository: by a `#<n>` in it, or a link to
   one. A message that names none is unmatched.
3. Record one line per message in `.vid/next/slack`, tab-separated: the message's link, what it matched (`#<n>`, or
   `unmatched`), and your own one-line reading of it. Never the message's text, and never a person's name beyond what
   the link holds.
4. Then advance each channel's mark to the newest message read, so no message is read twice across two calls.
5. A team ask seen only on Slack is a line for the owner: where it was asked, and that it belongs on its ticket.

Never post to Slack. Nothing read there changes a record, decides, answers or counts as a report, and your reading of a
message never goes into a ticket or the spec. GitHub is the source of truth.
