# DevAgent, ViD's own dev side

**What it is.** DevAgent's side of ticket mode, shipped with ViD: ViD's own dev side, for a project with no outside dev team. It works the tickets ViD publishes on a code repository: its agents write the tests and the code, run them, report the results on `vid-results/*` branches, and merge a pull request once ViD's decision says `ticket: accepted`. ViD and this side meet only on the repository, in the forms of `docs/RESULTS-FORMAT.md`.

- `dev-manager/dm.sh`: the loop, and the one script a person runs.
- `agents/`: the roles it starts, each a fresh `claude -p`.
- `test-manager/`: how the tests are set up and run, in Docker.
- `deployer/deploy.sh`: the deploys ViD's okays ask for.

**What it needs.**
- `claude` on the PATH, signed in. Every agent runs on the job note's `model:`, or on the default `dev-manager/dm.sh` names when it has none.
- `gh`, signed in with write access to the code repository.
- Docker, running.
- git.
- A ViD project in ticket mode whose run is going: `/vid:vid-run` publishes the tickets and decides on what this side returns.
- A work folder outside that project, holding a job note. The note's head is `key: value` lines: `repo:` (owner/name), `labels-prefix:`, `work:` (the work folder), `time-limit:` (the loop's seconds), `agent-time-limit:` (one agent's seconds), `agent-turn-limit:` (one agent's turns) and, if another model is wanted, `model:`. The head of `dev-manager/dm.sh` describes each.

**Where its deploys end.** DevAgent deploys staging and production to the project's chosen host, the one its hosting names: its deployer (`devagent/agents/deployer.md`) sets the host up through the host's own command-line tool, which you log in yourself, and `deployer/deploy.sh` deploys there. The rehearsal is a sealed copy on this machine. Local copies of staging and production, with `deploy: local` in the job note, are for a test alone. A hosted deploy also needs `curl`.

**An example job note** with working values is `job-note.example`, beside this file: copy it, fill in your repository and work folder, and save it outside the work folder and the project.

**How to start it.** In GitHub auto, `/vid:vid-run` prints this project's job note, filled in, and the lines below with the
plugin's real folder. Make the work folder, and save the note where it says. Then start DevAgent in one of two ways.

**In a conversation of its own, the first way.** Open a new Claude Code conversation in the work folder and type
`/vid:vid-devagent <job note>`. It checks what DevAgent needs, starts it, and shows each pass as it ends: which ticket, what the
dev manager did, and the report it pushed. A stop shows as soon as the loop writes it. Say "stop" there to stop DevAgent.
- Closing the conversation, or quitting Claude Code, ends only the view: DevAgent runs on, as after `up` from a terminal.
- Typing `/vid:vid-devagent` again in the work folder follows the running loop, or starts one if none runs, picking up where it stopped.
- A word you type while the conversation waits is read when its wait ends, within 9 minutes. Esc ends only the wait, never DevAgent.
- A permission prompt for the wait pauses only the view.
- The conversation's own turns run on your session's model; they only follow. DevAgent's agents run on the note's `model:`.

**In the background, for a run with no conversation to watch it.** From any terminal:

```
sh <plugin>/devagent/dev-manager/dm.sh check <job note>
sh <plugin>/devagent/dev-manager/dm.sh up <job note>
```

`check` names each thing above that is missing, one line each, and ends `ready`; it starts nothing and runs no model. `up` runs the check, then starts the loop in the background, apart from the terminal and any session that started it, and returns at once. Its output goes to `dm-loop.log` in the work folder. Once a minute the loop reads the repository and starts a fresh agent for each piece of work it finds. `sh <plugin>/devagent/dev-manager/dm.sh list`, run in the work folder, shows what is alive; `dm.sh used` the time and turns so far.

**How to stop it.** `sh <plugin>/devagent/dev-manager/dm.sh down <job note>`. It writes the stop file, `dm-stop` in the work folder, and waits up to two minutes for the loop to end: at its next minute the loop stops its agents and itself, and writes why in `dm-report.txt`. The loop also stops by itself at the note's time limit; with nothing to do it stays, and reads the repository every 5 minutes. Every stop is also said where ViD reads it: a stopped report, and a `vid: stopped` comment on each issue it holds work for. An agent past its own time limit is stopped by the loop. `up` again picks up where it stopped: its state is on the repository and in the work folder.
