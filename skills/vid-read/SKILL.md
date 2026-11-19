---
name: vid-read
description: Internal — the reads of a ViD call in ticket mode: GitHub through `checks/next.sh read` (the round read, each published ticket's body, its sub-issues at every depth, the issues assigned to the owner), then Slack, when set up, for context alone. Invoked by /vid next; written so /vid run can invoke it too. Not a verb.
---

# vid-read

One job: read, and write down what was read. It decides nothing, and never stops a call: it says what it could not read.

## GitHub

`sh checks/next.sh read`: `github.sh next-read`'s lines into `.vid/next/read`. Say each `unread` line it holds, in plain
words: what could not be read, and why.

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
