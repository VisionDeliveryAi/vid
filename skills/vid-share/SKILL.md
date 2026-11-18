---
name: vid-share
description: Send one run's logs to someone you choose, without making them public — a share bundle of the run's records, its logs folder if you name one, and its conversations, redacted, shown to you, then sent only on your yes to a private repository in your own GitHub account (or an organisation you own), with the person you name invited, or no one; or kept as one file you send by hand. Reads the project and writes only its own folder. Use when the user says "vid share", wants to send a run's logs or findings to someone, or asks how to share a run privately.
---

# /vid:vid-share

One run, one share, each time the user asks (0.26.10.28.7). It works in every mode — local auto, GitHub auto and GitHub team —
from the project's home (`.vid/home`, when this session's checkout is a builder's worktree). It changes nothing of the
project but its own folder, `.vid/shares/`. It never starts a run, and it writes, reads and runs no DevAgent code.

The scripts hold the order; this skill holds the words. `checks/share.sh` builds, scans and packs the bundle;
`checks/github.sh`'s share subcommands make the repository, push and invite, each reading the repository private and yours
first. Never call `gh` yourself, never ask for, print or store a token, and never send anything the user has not said "send" to.

## 1. Build

Ask, one at a time, never in one message, taking a plain default when the user does not care:

- **The run's name**, `<yyyy-mm>-<mode>-<short-name>`, the short name from the project; the user can change it.
- **A logs folder**, if any: in GitHub auto, the dev side's work folder. In GitHub team, the DevAgent's side is out of reach,
  and the bundle says so.
- **Further sessions**, by their exact path or id, such as the dev side's own: ViD's events name only the sessions of this home.
- **Words to redact** beyond the built-in kinds: written to a file the build reads, never on a command line.

Then build, with those answers:
`sh checks/share.sh build --run <run> [--logs <folder>] [--session <path or id>]... [--redact-file <file>] [--leave-out conversations|logs]...`.
It writes the bundle under `.vid/shares/<run>/`, with its summary, `.vid/shares/<run>.summary`, beside it (and `.vid/shares/<run>.known`,
the personal values the scan needs, which never leaves the machine). Read what you show the user from the summary.
On Windows the build can take a few minutes; tell the user so before it starts.

## 2. Show it, then ask

Before any question about sending, show from the summary, in plain words:

- where the bundle is, its size, and its parts with their file counts;
- the redaction counts by kind;
- what was left out, and why, and what is missing;
- that **the conversations carry your own CLAUDE.md, your memory files, and anything a tool printed** during the run, and that
  you may leave the conversations out;
- that **a pattern catches only what it knows**: look at the bundle yourself before you send it.

Then ask **one question, with three answers:**

1. **send** — to a private GitHub repository in your account (below);
2. **file** — keep it as one file you can send by hand: `sh checks/share.sh pack .vid/shares/<run>`, and say its path;
3. **stop** — the bundle stays where it is, and nothing more happens.

**Leaving parts out:** if the user wants the conversations, or the logs, left out, rebuild with `--leave-out conversations` or `--leave-out logs` and show
it all again before asking again. Nothing is sent without "send".

## 3. Send

1. **The login.** `sh checks/github.sh share-login`. If it fails, say there is no GitHub login, so the bundle stays a file
   they can send by hand, and offer **file**.
2. **Whose account.** Ask whether the repository goes in their own account or in an organisation they own, and say in one
   line: **read-only access for a person you invite needs an organisation's repository**; this cannot be changed after the push.
   The repository's name has a default, `vid-shares`, which the user can change. Make it only on their yes:
   `sh checks/github.sh share-create --repo <owner>/<name>` (always private).
3. **The push.** `sh checks/github.sh share-push --repo <owner>/<name> --project <project> --run <run> .vid/shares/<run>`. It
   scans the bundle again first and refuses on anything left, saying which file and which kind; then tell the user, and stop.
   A run folder already in the repository is never overwritten: offer another run name.
4. **Who is invited: the user says.** Ask which GitHub account to invite, or **none**. There is no default: never suggest an
   account.
   - **None:** the repository stays private and nothing is invited. Say how to invite someone later: the repository's
     Settings, then Collaborators (or Collaborators and teams), then Add people.
   - **A name:** first say, in these words or plainer:

     > On a repository in a personal account, GitHub gives every invited person write access, not read only: they will be able to read, push and change it. A personal account's repository can invite only people, not an organisation. If you want read-only access, make the repository in an organisation you own; there you can give the Read role to a person, or to one of that organisation's own teams.

     Then ask **a second, separate yes** to invite. Only after that yes:
     `sh checks/github.sh share-invite --repo <owner>/<name> --who <login> --shown-write-words --second-yes`.
     In an organisation's repository the person is invited with the Read role; a team is added by hand, as the words say.
     An account that reads as an organisation is refused on a personal account's repository; an invitation pending or
     accepted is not sent again.
5. **At the end, say what was done:** the repository, the run's folder in it (`projects/<project>/<run>/`), whether an
   invitation went and to whom, and how to take that access away later (the repository's Settings, then Collaborators, then
   Remove) — or, with no one invited, how to invite someone later.
