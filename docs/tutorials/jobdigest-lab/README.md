# The JobDigest lab

Everything you need to work ViD's tickets as the dev side, on a small practice product, without writing any code. You play every role yourself, one after the other: the lead who talks to ViD, and on the dev side the test author, test manager, builder, grader and merger. In real work those are different people; here the point is to learn the contract between the two sides.

**JobDigest:** two job feeds merged into one list, and a daily email of new matches for each saved search.

| Folder | What it is |
|---|---|
| `spec/` | The starter ViD project: the approved spec of JobDigest. You make it a git repository and start ViD in it |
| `code/` | The product's tests and code, step by step, to copy into your code repository and commit |
| `env/` | The test setup: one command runs a commit's tests in Docker, in a real browser, and writes the XML report; one command pushes a report |
| `reports/` | The few lines of each report you write by hand, and the deliberate breaks as patches |

**You need:** Claude Code with ViD installed, git, Docker, and the GitHub command line (`gh`) signed in. Two new private repositories of your own: one for the code (`<your-account>/jobdigest`), one for the spec (`<your-account>/jobdigest-spec`).

The step-by-step guide is `../TUTORIAL-GITHUB-TEAM.md`: every command, in order. The path through it, in short:

1. Push `code/0-start/` as the first commit of the code repository's `main`.
2. Copy `spec/` to a folder of its own, `git init`, commit everything. Then copy your installed ViD's `checks/` folder into it and commit that alone: ViD plans only in a project that holds it.
3. In that folder, start ViD's planner, give it the two repositories and one team of one person, and ask for the two rows the lab builds after the skeleton (ROW-006, then ROW-019) as steps of their own, right after the skeleton. Approve the plan.
4. Start ViD's run. Work the skeleton ticket, then the stage close ViD asks, then tell ViD to build on while staging waits (this lab has no test site).
5. Work the ticket of ROW-006, with its two questions.
6. Change the spec through ViD's door, in the run's session: a support address that reaches a person within one working day. Say yes to the draft.
7. Work the tickets that follow: the reached-rows ticket for ROW-006 and the ticket of ROW-019.
8. Run the step closes ViD asks.
