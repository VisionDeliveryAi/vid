# ViD in GitHub manual mode: the hands-on tutorial

For a team lead or a developer, or a product manager with a stronger technical interest. You take a small practice product from an approved spec to three accepted tickets, one change to the spec and three closed steps, on GitHub, with ViD on the product side and yourself as the whole dev side.

This is ViD's *GitHub manual* mode: your own developers build through GitHub tickets, ViD keeps to the product side, and you start each of ViD's turns with `/vid:vid-next`. The companion document, *ViD in GitHub manual mode: an overview*, explains what each thing is and why. This one is what you type. Read the overview first, or keep it open beside this.

---

## What you will do

**You write no product code and no tests here.** The practice product's real tests and code come with the lab, one folder for each commit. You copy a folder, commit it, run one command and send a report. What you learn is the contract between the two sides: what a ticket asks, what you send back, and what ViD says to it.

**At the end you will have:**

1. Planned a product from its spec, switched it to GitHub manual and approved the plan.
2. Worked the first ticket, the skeleton (the walking skeleton), from claim to acceptance.
3. Run a stage's full test run, chunk by chunk.
4. Worked an ordinary ticket: tests first, a failing run sent before any product code, a question to the product side, the merge, deliberate breaks, an independent review, the decision.
5. Changed the spec as the lead, applied the change, and seen what it sends your developers.
6. Closed three steps, the last two by a close run of their own.

**You play every role alone,** one after the other. As the lead you talk to ViD. As the dev side you are, in turn, the manager (DM), the test author (TA), the test manager (TM), the builder (BU), the grader (GR) and the merger (MR). Real work keeps some of these apart, and the ticket says which: the person who writes or runs the tests is never the builder, and the grader comes fresh and has not seen the builder's reasoning. In this lab you keep them apart only in what you sign: each comment and each report names the role that made it.

**How this tutorial was checked.** Part 1 was done once, on this practice product, against real GitHub repositories, and every ticket was accepted, in this mode's older form: one long ViD session read GitHub by itself, and each decision was asked for and given in the pull request's comments, before the merge. GitHub manual keeps that run's tickets, its reports, its tests and its breaks. What it changes is who starts ViD's turns (you, with `/vid:vid-next`), what reaches your developers (only what you publish or apply), and where the work is decided (on the ticket, at a commit of `main`, after the merge). Those parts are written here from ViD's own rules, its commands and its results format, and were not run for this tutorial. The excerpts are the checked run's; where GitHub manual shows something else, the text says so. The dev seat's commands are written from that run's record: shell variables stand where it had its own numbers, the lines that fill in a report's commit were written by hand there, and its false starts are left out. One thing here was not typed in that run and is marked where it comes: finding the `checks/` folder of an installed ViD. The lab's test command was run again on the lab's own files after this tutorial was written, at stop 5's head and with stop 5's first break. In that run ViD's session was driven by a script, not typed by a person. Where a typed session should behave differently (it asks you a question the script could not be asked, for example), the text says *typed session*. Part 2 was not run for this tutorial.

**Time.** Run by script without a pause, in the older form, Part 1 took 48 minutes. ViD's first plan took 4 minutes 25 seconds, and each of its other turns between one and two minutes. Reading as you go, allow an afternoon.

---

## Before you start

### What you need

- **Claude Code,** signed in, with ViD installed (the two lines below this list, typed inside Claude Code).
- **git,** and the **GitHub command line,** `gh`, signed in (`gh auth login`; with HTTPS also `gh auth setup-git`).
- **Docker,** running (Docker Desktop on macOS, or Docker Engine with the compose plugin on Linux), with about 1.6 GB of disk free. The practice product's tests run in it, in a real browser. The first test run fetches one base image and builds two; nothing is fetched after that.
- **A GitHub account** where ViD may create three private repositories for you, the code repository, the spec repository and one for its own records: it makes them in stop 4.

```
/plugin marketplace add VisionDeliveryAi/vid
/plugin install vid@vid
```

### The lab folder

Everything the lab needs is in `jobdigest-lab/`, beside this file:

| Folder | What it is |
|---|---|
| `spec/` | The starter project: the approved spec of the practice product |
| `code/` | The product's tests and code, one folder for each commit you will make |
| `env/` | The test setup: one command runs a commit's tests and writes the report; one command pushes a report |
| `reports/` | The few lines of each report that are written by hand, and the deliberate breaks as patches |

**The practice product is JobDigest:** two job feeds merged into one list, and a daily email of new matches for each saved search. Its spec holds nine requirements and a test inventory. You will build three small pieces of it.

### Two terminals

| Terminal | Who you are there | What runs in it |
|---|---|---|
| **The lead's seat** | The team lead, talking to ViD | A Claude Code session, in the spec folder |
| **The dev seat** | Your developers | A plain shell, in the code folder. No Claude Code is needed here |

ViD never sees the dev seat, and the dev seat never sees ViD's session. Everything between them goes through GitHub. That is the point of the lab, so keep to it.

### Names used in the commands

Set these once in the dev seat. Every command below uses them. The lead's seat is another terminal and does not have them; the one path typed there is written out in full.

```bash
export ACCOUNT=<your GitHub account>
export LAB=<the full path of the jobdigest-lab folder>
export WORK=$HOME/jobdigest-work
export REMOTE=https://github.com/$ACCOUNT/jobdigest.git
mkdir -p $WORK/reports
```

Three more change with each ticket, and each stop sets them: `T`, the ticket's issue number; `P`, the pull request's number; `SHA`, the full id of the commit a report is about. The numbers given below are the ones GitHub gave in the checked run. In GitHub manual yours may differ, since you choose when each ticket goes out: read each one off GitHub and never assume it.

![The thirteen stops of the lab, and which seat each is done from](img/lab-path.svg)

---

## Part 1. The practice product, from nothing to three closed steps

### Stop 1. The spec folder

*Dev seat.* You make no repository on GitHub: ViD makes them, private, at the switch of stop 4, under the names you give in stop 3. The code repository gets its first commit right after that switch.

The spec folder is a git repository of its own, on your machine, with everything committed. ViD refuses to plan from files that are not committed.

```bash
cp -R $LAB/spec $WORK/spec
cd $WORK/spec
git init -b main
git add -A && git commit -m "JobDigest: the starter spec"
```

You do not push the spec folder anywhere. ViD publishes from it to the spec repository when you publish the first ticket.

**Look at what you have.** `PRD.md` holds the requirements, each with its `fail-if` (its acceptance criterion). `INVENTORY.md` holds the rows (the test conditions), each tied to a requirement. `STAGES.md` cuts the product into three stages (releases): stage 0 is the skeleton, stage 1 the daily digest, stage 2 the search by other names of an occupation. The overview's section 2 reads these files closely.

### Stop 2. Give the spec folder ViD's checks

A ViD project carries a folder named `checks/`: ViD's own scripts, which it runs in the project. A project that ViD started itself already has it. The lab's starter spec does not, because the folder belongs to your installed ViD, so you copy it in by hand, once, and commit it alone.

*Dev seat.* Find the folder in your install. The folder above it is named by your ViD's version. (The checked run used ViD from a folder of its own, so this one line was not typed there; the copy and the commit were.)

```bash
ls -d $HOME/.claude/plugins/cache/*/vid/*/checks
```

Copy it and commit it, with the version from that path in the message:

```bash
cd $WORK/spec
cp -R <the path the command printed> ./checks
git add checks
VID_ROLE=fix git commit -m "Refresh checks/ to VID <the version>"
```

If you skip this stop, the plan refuses in its first minute and tells you the project's `checks/` needs refreshing. It will not copy the folder for you.

### Stop 3. The plan

*Lead's seat.* Start Claude Code in the spec folder and make ViD's first call:

```bash
cd $HOME/jobdigest-work/spec && claude
```

```
/vid:vid-next
```

Every ViD command is a slash command of this form. Type `/vid` to see the list. No plan is approved yet, so this first call plans before anything else: it is the planner's sitting, and nothing reaches GitHub before your approval in stop 4.

**The setup questions.** *Typed session:* before it plans, ViD asks where the code lives and where the specs go, who is on the team, who works the tickets, and how fine the steps should be. Answer:

| It asks | You answer |
|---|---|
| Where the code lives and the specs go | Two separate repositories: the code in `<your account>/jobdigest`, the spec in `<your account>/jobdigest-spec`. Neither exists yet: naming them is your yes for ViD to make them, private, at the switch of stop 4 |
| The teams | One team of one person, for the whole product |
| Who works the tickets | Your own developers. ViD leaves this one open: the switch of stop 4 answers it |
| The step size | Steps by journey, the default |

If it plans without asking (the scripted run did), it says it wrote the defaults and that the repositories are not named yet. Give them in your next message, as below.

**The draft.** After a few minutes (4 minutes 25 seconds in the checked run) ViD shows the plan as a page and says what it holds. In the checked run:

> **The plan:** 3 stages, 4 steps, 33 planned rows in 4 waves, one after another.
> - **S1, the skeleton (stage 0, 2 rows):** a visitor saves a search, confirms it and reads the first digest.
> - **S2 (stage 1, 6 rows):** the two feeds are read into one listing, each job listed once. …
> - **S3 (stage 1, 24 rows):** the daily digest per saved search, with the support address and the one-click unsubscribe. This is the largest step.
> - **S4 (stage 2, 1 row):** search also finds jobs listed under other names of the same occupation.

Your draft may be cut differently: the planner is a model, and it plans afresh. The skeleton will be the same, because the spec's stage cut names its two rows, ROW-003 and ROW-004.

**Ask for one change.** The lab has code for two small steps after the skeleton, so ask for those two as steps of their own. This is also what a lead really does with a plan: you say what you want built first, in words, and ViD re-plans. Type this, with your account's name:

```
The setup: the code repository is <your account>/jobdigest and the spec repository is <your account>/jobdigest-spec, both separate and private. One team of one person, steps by journey: your defaults are right. My own developers work the tickets: leave that question open, as I will switch this project to GitHub manual.

One change to the plan before I approve it. Right after the skeleton, put ROW-006 (the header and footer on every page) in a step of its own, and right after that ROW-019 (the support address in every digest's footer) in a step of its own, each building on the skeleton alone. Every other row stays where you put it.

On the page's questions: keep DIF-001, ROW-012 and ROW-018 where they are, for now.
```

Leave the last paragraph out if your page asks no such questions. The checked run's page asked three: rows that cannot be proven in the stage they sit in. Keeping them is a fair answer for a lab.

ViD answers with the new plan. In the checked run:

| Step | What it builds | Rows | Builds on |
|---|---|---|---|
| S1 | the skeleton: save a search, confirm it, read the first digest | 2 | nothing |
| S5 | the header and footer on every page (ROW-006) | 1 | S1 |
| S6 | the support address in every digest's footer (ROW-019) | 1 | S1 |
| S2 | the two feeds merged, each job listed once | 6 | S1 |
| S3 | the daily digest and the way out | 22 | S1, S2 |
| S4 | synonym-aware search | 1 | S2, S3 |

**Check three things before you approve:** the first step is the skeleton with ROW-003 and ROW-004; the next is ROW-006 alone; the one after is ROW-019 alone. The step names are the planner's and yours may differ (the new steps were numbered on, as S5 and S6). From here on this tutorial names a step by its row.

**Do not approve yet.** In the checked run the lead approved at this point and the spec was published at once. In GitHub manual the approval is made by the switch, in stop 4, in your words, and the spec reaches the spec repository with the first ticket you publish.

### Stop 4. Switch to GitHub manual, and publish the first ticket

*Lead's seat,* the same session: the call is still planning. You type no other command for the switch. Once the plan is as you want it, the call switches the project to GitHub manual itself, from the plan you just wrote, and asks only what it cannot find. Answer each in words:

| It asks | You answer |
|---|---|
| ViD's own state repository | `<your account>/jobdigest-state`. Your answer is also your yes for ViD to make it, private. It holds ViD's lock and saved records, and is neither of your two repositories |
| Any other setup question | As in stop 3 |

Then it shows the plan page again. **Approve.** Your words are recorded as the approval, so say what you mean:

```
Yes, I approve this plan as it stands on the page, for GitHub manual.
```

ViD says what it recorded, the mode last: GitHub manual, recorded. The switch has made the three repositories, private; the code repository is empty. The call then goes on as every call does, reads GitHub and shows its lines.

**The code repository's first commit.** *Dev seat.* Give it the lab's starter code on `main`, because the first ticket names the commit it starts from:

```bash
cd $WORK
gh repo clone $ACCOUNT/jobdigest code
cd code
cp -R $LAB/code/0-start/. .
git add -A && git commit -m "Initial commit"
git push -u origin main
```

*Lead's seat.* From here on, every turn of ViD's is a call you make, `/vid:vid-next`. Its lines say what is not yet with your team, the moves you may name, and that its own work is off. Name two moves, each with your own words:

```
/vid:vid-next own-work on "ViD decides, asks and closes at each of my calls from now on." publish S1 "Publish the skeleton ticket."
```

`own-work on` lets each later call decide what your team asks on a ticket, ask a step's close and a stage's full run, and post the okays. `publish S1` sends the skeleton's ticket, and the spec reaches the spec repository with it. `S1` is the skeleton's step in the checked run's plan: use the name your call's `publish` move gives it.

**Look at the spec repository on GitHub now.** Its `main` holds the spec as your developers see it. *Dev seat:*

```bash
cd $WORK/code
gh issue list
gh issue view 1
```

**Read the ticket before you do anything.** It is long, and it is self-contained by design: a developer needs nothing but the ticket and the spec repository. In the checked run its header read:

```
- number: 1
- kind: skeleton
- step: S1
- stage: 0, The walking skeleton
- plan: b29641317ced
- base: 89c179fe969575d79cc91a4e20f39fece3036f7e
- export: bb722ec234c76c2daa5c8fd875a70cf84aa5ccdd
- rows: ROW-003 ROW-004
```

`base` is the commit your branch starts from: `main`, as you pushed it. `export` is the commit of the spec repository the ticket quotes. Then come the rows with their fail-ifs, the requirements they serve, the decisions and rules that bear on them, the stack, the roles, and last the asks. The ticket calls your side *DevAgent*.

A skeleton ticket asks four things, where an ordinary ticket asks five:

> - T1 (TA): write at least one test per row, per transition for a journey, its name matching the row's id.
> - T3 (TM): at the pull request's head, run every row in each engine you declare. The head report declares the engines, the primary first, and how many test environments you run.
> - T4 (GR, then TM): at the same head, the skeleton's fault: GR writes the change that makes its rows' fail-if true, and nothing else; TM plants it and runs the rows' tests in the primary engine, with no control.
> - T5 (GR, SR): at the ticket's first head alone, two fresh GRs, each in its own blind copy, grade each row against its fail-if, the grading checklist and the test differences, a screen row also against the design, and their lines are combined. SR sorts what the grade leaves, once. No later head has a grade or a sort.
>
> There is no T2: the skeleton has no red, so its fault stands in for it.

In plain words: write the tests (T1); run them at the head (T3); break the product on purpose and show that the tests notice (T4, a small mutation test); have someone who did not build it review each row (T5). T2, sending a failing run before any product code, is left out for the skeleton, because there is no product yet for a test to fail against in a useful way.

**The head, in GitHub manual.** The asks say the pull request's head. In GitHub manual the head is the commit of `main` that holds the ticket's work, once your team has merged it: every report of the ticket's ask is about that commit, and the ask goes on the ticket's issue.

The ticket names no branch. You choose; this tutorial uses `ticket-<number>`. ViD ties your pull request to the ticket by the first line of its description, not by its branch.

### Stop 5. The skeleton ticket, worked by hand

*Dev seat,* all of it. Each block says which role you are.

**DM: claim the ticket.** One comment, two lines.

```bash
cd $WORK/code
T=1
gh issue comment $T --body "vid: claimed
by: DM"
```

**TA: the tests, alone in a commit, before any product code.**

```bash
git checkout -b ticket-$T
cp -R $LAB/code/1-skeleton-tests/. .
git add -A && git commit -m "tests: ROW-003 and ROW-004, the skeleton, before any product code"
```

Open `tests/test_journey_row_004.py` and look at a test's name: `test_ROW_004_T1_save_sends_confirmation`. The row's id is in the name. That is how ViD ties a test case in your report to a row; it never reads your test code. ROW-004 is a journey of three transitions, so it has at least one test for each: `ROW_004_T1`, `ROW_004_T2`, `ROW_004_T3`.

**DM: open the pull request.** Its description must begin with the line `ticket: #<number>`: the first line, with nothing above it. It also holds a Decisions section: one line for each technical decision the branch made, or the one line `Decisions: none`. The lab's builder made none you need to record; in your own work, list each one.

```bash
git push -u origin ticket-$T
gh pr create --base main --head ticket-$T --title "Ticket $T: the skeleton" --body "ticket: #$T

Decisions: none"
P=2        # the pull request's number, from the address gh printed
```

**BU: the product.**

```bash
cp -R $LAB/code/2-skeleton-build/. .
git add -A && git commit -m "save a search, confirm it, read the first digest"
git push
```

**MR: merge into `main`.** Your side merges, never ViD, and in GitHub manual the merge comes first: ViD decides the ticket at a commit of `main`.

```bash
gh pr merge $P --merge --body "Role: MR"
git checkout main && git pull
SHA=$(git rev-parse HEAD); H12=$(printf %s $SHA | cut -c1-12)
```

`SHA` is now the ticket's head: the merge commit on `main`, on `main`'s own line. Every report from here names it. (The pull request's own last commit is not on that line, and a decision asked there reads `not on main`.)

**TM: the run at the head (T3).** A report is a folder named by the report's id. For the run at a ticket's head in GitHub manual the id is `step-<ticket>-<first 12 characters of the commit>-<attempt>`.

```bash
R=$WORK/reports/step-$T-$H12-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R
```

The first run fetches a base image and builds two Docker images, about two minutes. Then it makes a clean copy of exactly that commit, starts the product and two fakes (a mail provider and a job feed), runs every test in Chromium and writes `cases-chromium.xml` into the folder: the standard JUnit XML that any test runner can write. Its last lines name the commit and the report file; above them you should see `7 passed`.

**GR writes the breaks, TM plants them (T4).** A break (a fault) is the smallest change to the product that makes a row's fail-if true. The lab has one for each row, as a patch. Look at one before you plant it:

```bash
cat $LAB/reports/1-skeleton/fault-ROW-003.patch
```

It removes one line from one page: *Check your inbox to confirm*. ROW-003 fails if that line is missing, so ROW-003's test must now fail. Run the rows' tests with each break planted. Each result goes in a folder of its own inside the report, `faults/<row>/`.

```bash
sh $LAB/env/run-tests.sh $WORK/code $SHA $R/faults/ROW-003 -k "ROW_003 or ROW_004" --fault $LAB/reports/1-skeleton/fault-ROW-003.patch
sh $LAB/env/run-tests.sh $WORK/code $SHA $R/faults/ROW-004 -k "ROW_003 or ROW_004" --fault $LAB/reports/1-skeleton/fault-ROW-004.patch
```

The first should end with 1 test failed, the second with 5. **Here a failure is the result you want:** it shows the tests can catch the defect they exist to catch. The break is planted in the clean copy alone and never reaches `main`.

**TM: the few lines written by hand.** Every test report holds a `results.txt`. The lab has each one ready, with the commit left for you to fill in:

```bash
sed "s/<the head commit, full id>/$SHA/" $LAB/reports/1-skeleton/head-results.txt > $R/results.txt
cat $R/results.txt
```

```
by: TM
commit: 48515924be63eab070523d824e849c2f2915fc0a
engines: chromium
environments: 1
stand-in: the mail provider — a fake that records each message — the real mail provider
stand-in: the digest schedule — every 2 seconds — each morning
stand-in: the store — a temporary file per run — a platform disk
stand-in: the addresses — plain http on the test network — the platform's https
stand-in: the feed — a fake — the partner feed
```

`by:` is the role, `commit:` the commit the run was made at. The skeleton's head report is the one that declares your setup, once: which browser engines you test in, how many test environments you can run side by side, and one `stand-in:` line for each way your tests differ from production. ViD shows those differences to every later grade, and the lead sees them. Be honest in them; they cost you nothing.

**TM: send the report.** A report travels as a branch of the code repository named `vid-results/<id>`, holding that one folder and nothing else.

```bash
sh $LAB/env/push-report.sh $REMOTE $R
```

Read `env/push-report.sh` once: ten lines. It copies the folder into a new, empty folder, makes one commit there and pushes it as the branch. Your working branch is never touched. In your own project you will write the same ten lines.

**GR: the grade (T5).** The grade is a second kind of report: one line for each row, with a verdict and the reason, written by someone who reads the code, the tests and the results and was not told the builder's reasoning. Its id is the head report's with `grade-` in front.

```bash
G=$WORK/reports/grade-step-$T-$H12-1; mkdir -p $G
sed "s/<the head commit, full id>/$SHA/" $LAB/reports/1-skeleton/grade.txt > $G/grade.txt
cat $G/grade.txt
sh $LAB/env/push-report.sh $REMOTE $G
```

Read the file. A journey gets one line for each transition. Each line reads `<row> kept — <why>`. The other verdicts are `breached product` (the product does not keep the row's promise), `breached test` (the test would pass on a product that breaks it) and `unclear`. The last line is a `finding:`, a defect the grader saw that no row covers; here, that the confirm and unsubscribe links act on a plain GET. Findings go to the lead, not into this ticket. Every line is `kept`, so there is nothing to sort.

In real work two graders each write a grade in a fresh context and their lines are combined. Here you copy the one a real grader wrote for this code. Grade what you see is the rule; the copy is the lab's shortcut.

**MR: ask for the decision.** One comment on the ticket's issue, naming the commit of `main` in full.

```bash
gh issue comment $T --body "vid: decide $SHA"
```

**ViD decides, at your call.** *Lead's seat:*

```
/vid:vid-next
```

With its own work on, the call reads the three reports you sent and answers on the ticket's issue. *Dev seat:*

```bash
gh issue view $T --comments
```

The checked run's decision:

```
vid: decision 48515924be63eab070523d824e849c2f2915fc0a
ticket: accepted
ROW-003 accepted
ROW-004-T1 accepted
ROW-004-T2 accepted
ROW-004-T3 accepted
ROW-004 accepted
```

That run gave it under the pull request, at its head; in GitHub manual the same lines come on the ticket's issue, naming your commit of `main`. One line for the ticket, one for each row. `accepted` means the runs a row needs were sent and read: its tests passed at this head, and its break made them fail. A row's state comes from runs alone. A grade can keep the ticket at `not yet` while a line of it is still open, but it does not by itself fail a row. Had the ticket line read `not yet`, each row short of that would carry its reason, and your next move would be to fix exactly that, merge the fix, and ask again at the new commit of `main`.

**Nothing is left to merge.** The work went into `main` before the ask, and the acceptance stands at that commit. That is a whole ticket. Everything else in this lab is a variation on it.

### Stop 6. The stage's full run

The skeleton is all of stage 0, so its acceptance completes a stage. With its own work on, the call that accepted it, or your next one, asks for the stage's full run: every row of the stage, again, at the accepted commit. It asks with a new issue, labelled `run`. If none is there yet, call `/vid:vid-next` again.

*Dev seat:*

```bash
gh issue list --label run
gh issue view 3
```

```
close: stage-0
commit: da6b3c70cf7a5a30cf0053e98da000cecd7f595c
engines: chromium
…
- chunk p1c1, chromium: ROW-003 ROW-004
- chunk p1cx, chromium: every other test case of the suite, …
```

A run is asked in chunks. You report each chunk as its own report, `req-<the issue>-<chunk>-<attempt>`, and say so with a comment. Before the first chunk you comment `vid: started`.

**TM:**

```bash
C=3
SHA=<the commit issue 3 names, in full>
gh issue comment $C --body "vid: started
by: TM"

R=$WORK/reports/req-$C-p1c1-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R -k "ROW_003 or ROW_004"
sed "s/<the commit the close issue names, full id>/$SHA/" $LAB/reports/5-closes/results.txt > $R/results.txt
sh $LAB/env/push-report.sh $REMOTE $R
gh issue comment $C --body "vid: reported p1c1-1"
```

In `-k`, a row's id is written with `_` for `-`, and the rows are joined by ` or `. You should see `7 passed`.

The second chunk, `p1cx`, is every test that belongs to no row of the first chunk. This product has none yet:

```bash
R=$WORK/reports/req-$C-p1cx-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R -k "not ROW_003 and not ROW_004"
sed "s/<the commit the close issue names, full id>/$SHA/" $LAB/reports/5-closes/results.txt > $R/results.txt
sh $LAB/env/push-report.sh $REMOTE $R
gh issue comment $C --body "vid: reported p1cx-1"
```

No test is selected, and the report holds no test case at all. That is a correct report: you were asked what else there is, and the answer is nothing. *Lead's seat:* call `/vid:vid-next` again. ViD reads both chunks, and tells you that the stage's full run passed and the skeleton's step closed.

### Stop 7. The staging deploy you will not make, and the next ticket

After a stage's full run passes, a call gives the okay to deploy that commit to a test site (staging). *Dev seat:*

```bash
gh issue list --label deploy
```

Issue 4, *Deploy to staging: stage 0, candidate 1*, asks your side to deploy the commit and report it. ViD deploys nothing itself: it gives the okay, your team deploys.

**This lab has no test site, so you leave that issue open.** Nothing waits on it. The checked run held the next stage here until the lead said `continue`; GitHub manual writes no hold, and the next ticket goes out when you publish it.

*Lead's seat:* `/vid:vid-next` shows the move `publish S5`: the step of ROW-006 alone, in the checked run's plan (use your plan's name for it). A warning may stand beside it, a risk ViD saw; it never holds the move back. Name it:

```
/vid:vid-next publish S5 "Publish the ticket of ROW-006, the header and footer on every page."
```

### Stop 8. An ordinary ticket: tests first, a red run, a question

*Dev seat:*

```bash
gh issue list --label ticket
gh issue view 5
```

This is a step ticket (`kind: step`) for ROW-006, the header and footer on every page. It has what the skeleton ticket lacked: an **Engines** section (which browser engines to run), **Regression rows** (ROW-003 and ROW-004: rows already accepted, which this work must not break), and the ask T2.

**DM: claim it.**

```bash
T=5
gh issue comment $T --body "vid: claimed
by: DM"
```

**TA: ask what the spec does not say.** To write ROW-006's tests the test author needs two facts the spec does not give: the support address, and where the footer's help link goes. Guessing silently is how a team builds the wrong thing. Asking and waiting is how it loses a day. The contract's answer is a question that carries its own default: you ask, you say what you will assume, and you go on.

```bash
gh issue comment $T --body "Question: ROW-006, REQ-012. Two questions from TA; neither stops the work, and the tests use the defaults below until answered.

1. ROW-006, REQ-012: what is the support address? The spec names none. Test value: support@jobdigest.example, and no other address in the footer.
2. ROW-006: where does the footer's unsubscribe help link go? No row or design draws that page. Test value: the product's own page at /help/unsubscribe, with the same header and footer and a few plain words on how to unsubscribe."
```

The first line begins `Question:` and names the rows. You do not label the issue `blocked`, because the work can go on. Use that label only when it cannot.

**TA: the tests alone, and the pull request.**

```bash
git checkout main && git pull
git checkout -b ticket-$T
cp -R $LAB/code/3-header-footer-tests/. .
git add -A && git commit -m "tests: ROW-006, the header and footer on every page, before any product code"
git push -u origin ticket-$T
gh pr create --base main --head ticket-$T --title "Ticket $T: the header and footer on every page" --body "ticket: #$T

Decisions: none"
P=6
```

**TM: the red run (T2).** Run the tests at this commit, where no product code for the row exists, and send the result. This is the *red* of red, green, refactor, made into evidence: it shows the tests can fail, and that they fail for the right reason.

```bash
SHA=$(git rev-parse HEAD)
R=$WORK/reports/red-$T-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R
```

You should see `6 failed, 7 passed`: the six new tests of ROW-006 fail, the seven of the skeleton pass. Each failure says what the product lacks (`ROW-006: S01/default: 0 headers …`), and none says the test could not run. A test that failed because the setup was broken proves nothing, and ViD does not count it as a red.

```bash
sed "s/<the tests-first commit, full id>/$SHA/" $LAB/reports/2-header-footer/red-results.txt > $R/results.txt
sh $LAB/env/push-report.sh $REMOTE $R
```

The red report's id is `red-<ticket>-<attempt>`, and its `results.txt` names the rows it is the red of: `rows: ROW-006`. The tests-first commit stays on your branch; the red run names it, and the code repository holds it once it is pushed.

**BU: the product change, and MR: the merge.**

```bash
cp -R $LAB/code/4-header-footer-build/. .
git add -A && git commit -m "the header and footer on every page"
git push
gh pr merge $P --merge --body "Role: MR"
git checkout main && git pull
SHA=$(git rev-parse HEAD); H12=$(printf %s $SHA | cut -c1-12)
```

**TM: the run at the head (T3).**

```bash
R=$WORK/reports/step-$T-$H12-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R
```

`13 passed`: the row's tests and the regression rows'.

**A retested row, its break and its control (T4).** ROW-006 needs no break: its red run already showed its tests can fail. But the tests commit also changed a helper that ROW-003's test uses, so ROW-003's test now checks something slightly different from the test that was accepted. The report must say so, with the line `retested: ROW-003`, and a retested row needs a break of its own.

An ordinary ticket's break also needs a **control**: a second test, run in the same broken copy, that must still pass. It shows the break was narrow, and that the test failed because of this defect and not because everything fell over. The test manager picks it and names it in `control.txt`. Here the control is ROW-006.

```bash
sh $LAB/env/run-tests.sh $WORK/code $SHA $R/faults/ROW-003 -k "ROW_003 or ROW_006" --fault $LAB/reports/2-header-footer/fault-ROW-003.patch
cp $LAB/reports/2-header-footer/control.txt $R/faults/ROW-003/control.txt
sed "s/<the head commit, full id>/$SHA/" $LAB/reports/2-header-footer/head-results.txt > $R/results.txt
cat $R/results.txt
sh $LAB/env/push-report.sh $REMOTE $R
```

`1 failed, 7 passed`: ROW-003's own test fails, and every test of ROW-006 passes. This `results.txt` is three lines. The engines and the stand-ins were declared at the skeleton and are not repeated.

**GR: the grade (T5).**

```bash
G=$WORK/reports/grade-step-$T-$H12-1; mkdir -p $G
sed "s/<the head commit, full id>/$SHA/" $LAB/reports/2-header-footer/grade.txt > $G/grade.txt
cat $G/grade.txt
sh $LAB/env/push-report.sh $REMOTE $G
```

The grade covers the ticket's row and the regression rows, and ends with two findings. Read the first: the support address is in a domain that can receive no mail, so a requirement will fail on the day the product ships. No test here could have shown that. It is what an independent review is for. Every row's line is `kept`, so again there is nothing to sort.

**MR: ask for the decision.**

```bash
gh issue comment $T --body "vid: decide $SHA"
```

*Lead's seat:* `/vid:vid-next`. *Dev seat:* `gh issue view $T --comments`, until the decision is there. The checked run's:

```
vid: decision 2dd4ae9a2a788ac29ecd983b06186224e8490cfa
ticket: accepted
ROW-006 accepted
ROW-003 passing
ROW-004 passing
```

As at stop 5, that run gave it under the pull request; in GitHub manual it is on the ticket's issue. The ticket's own row is `accepted`. The regression rows are `passing`: they were accepted before, and they still pass.

**The step's close.** ROW-006's step has no other ticket, so the same call, or your next one, asks for its close run: a new issue labelled `run`. A merged ticket is not a closed step: the close asks the step's rows and its regression rows once more, at the commit of its acceptance, as the step stands on `main`. The checked run's:

```bash
gh issue list --label run
gh issue view 7
```

```
close: S5
commit: fe385115d0e220e03f3bedce2530c5a753f39071
engines: chromium
…
- chunk p1c1, chromium: ROW-006 ROW-003 ROW-004
- with the product's own declared processes: ROW-004
```

The last line asks that ROW-004 be run against the product as it really starts, which the lab's setup always does. **TM,** at the commit the issue names:

```bash
C=7
SHA=<the commit issue 7 names, in full>
gh issue comment $C --body "vid: started
by: TM"
R=$WORK/reports/req-$C-p1c1-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R -k "ROW_006 or ROW_003 or ROW_004"
sed "s/<the commit the close issue names, full id>/$SHA/" $LAB/reports/5-closes/results.txt > $R/results.txt
sh $LAB/env/push-report.sh $REMOTE $R
gh issue comment $C --body "vid: reported p1c1-1"
```

`13 passed`.

**The lead answers the question, and publishes the next ticket.** *Lead's seat:* `/vid:vid-next`. This call reads the close and closes the step: ticket 5 gets the comment `vid: closed — the step's close passed at <commit12>` and is closed. It also shows your developers' question as a line of your queue, with its place on GitHub, `#5:<k>`: in GitHub manual every question is yours. And it shows the move `publish S6`, the step of ROW-019 in the checked run's plan. Name both, the answer in your words, with the place as the call shows it:

```
/vid:vid-next answer "#5:<k>" "1. The support address is support@jobdigest.example, and the support team reads it. 2. The unsubscribe help link opens the product's own page at /help/unsubscribe, with the same header and footer and a few plain words on how to unsubscribe." publish S6 "Publish the ticket of ROW-019, the support address in every digest's footer."
```

ViD posts your answer on the ticket as a comment beginning `RM:`, under the question's own first line. *Dev seat:* `gh issue view 5 --comments`. That comment is how an answer reaches your developers. Until it is there they hear nothing, which is why a question must carry a default. The ticket was decided with the question still open, because the question did not stop the work.

The new ticket, 8 in the checked run, is for ROW-019. **Leave it for now.**

### Stop 9. Change the spec

The grader's finding and your own answer point at the same weakness. REQ-012 says the support address must "reach a person", and nobody can test that. As the lead you tighten it.

A spec under ViD is never edited by hand. A change goes through ViD: it drafts the change, counts what the change touches, and asks you once. Nothing is written until you say yes, and nothing reaches your developers until you apply it.

*Lead's seat,* in the spec folder's session:

```
/vid:vid-fix REQ-012: the support address must reach a person within one working day. "Reaches a person" is too loose: mail to the support address is answered by a person within one working day.
```

ViD reads the spec, drafts, and asks. In the checked run:

> **Q4, draft 1:**
> - **REQ-012 is amended.** Mail to the support address must be answered by a person within one working day, and an automatic reply doesn't count. The existing two arms stand word for word …
> - **One row is added, ROW-021.** It checks that mail sent to the support address on production is answered by a person within one working day. A test run can't check a working-day reply, so this row is paid at the production deploy …
> - **No rows are reset. Three are reached:** ROW-006 (already accepted), ROW-019 and RULE-001. Their test text is unchanged.
>
> Say **yes** to land it, or **no**.

**Read the count before you answer.** The question itself carries it: *This changes 0 rows, adds 1, and reaches 3 more: ROW-006, ROW-019, RULE-001. Land it?* A *changed* row is one whose own text changes, so its test must be written again. A *reached* row is one whose requirement changed while its own text did not, so someone must look at its test and decide. The count is the price of your change in your developers' time, shown before you pay it. Here it is small. A change that read "changes 14 rows" would be the moment to think again.

Your draft may differ: ViD may change ROW-019 where the checked run added a row. Either is a fair reading of your words. Answer by the question's number, as a move:

```
/vid:vid-next answer Q4 yes "Land draft 1."
```

**If the yes does not land it.** Before it writes anything, ViD tries the change on a scratch copy and runs its own checks. In the checked run that trial refused the first draft, because the new row was in no step of the plan. ViD wrote nothing, made a second draft that placed the row in a step, and asked again as a new question. It does not carry your yes from one draft to the next:

```
/vid:vid-next answer Q5 yes "Land draft 2." answer Q4 no "Draft 2 replaces it."
```

**What lands.** ViD says what it wrote. Look for yourself, in the dev seat:

```bash
cd $WORK/spec && git log --oneline -4 && tail -5 PRD.md
```

The requirement was not edited. A new line was appended under the PRD's *Appends*, marked `AMENDED`, and the later line wins:

```
REQ-012 AMENDED | functional | T2 | Every digest footer carries a support contact address, and mail to it is answered by a person within one working day. | fail-if: the footer lacks a support address, or mail to it bounces, or mail to it is not answered by a person within one working day (an automatic reply is no answer) | …
```

The old text is still above it, word for word. That is what lets an old ticket quote the spec it was built from and stay true.

**Apply it.** The change is in ViD's folder alone. *Lead's seat:* `/vid:vid-next`. The call shows the change as pending, and the move `planning-analysis`, since the change added a row to place. Name it:

```
/vid:vid-next planning-analysis
```

ViD writes its proposal, what the change does to the plan and to each published ticket, and shows it as a page. It records and posts nothing. Read the page, then apply it as shown:

```
/vid:vid-next implement-replan "Apply the change as the page shows it."
```

If your draft added no row, the call lists `implement-replan` at once, with no analysis first. The apply exports the spec again to the spec repository and sends what the change owes your developers. Its lines say what it sent.

### Stop 10. What the change sent your developers

*Dev seat:*

```bash
cd $WORK/code
gh issue list --label ticket
gh issue view 8 --comments | tail -5
```

**The open ticket was amended in place.** Ticket 8, for ROW-019, was published before your change and nobody had started it. It now quotes the new text of REQ-012, its header has a line `amended:`, and a comment beginning `vid: amended` names its cause and says that earlier results for its changed rows do not count. (The checked run's comment named the spec export as its cause; GitHub manual's names the change you applied.) Had a developer already sent a red run for it, that run would no longer count. A team that reads only the first version of a ticket will build the old spec; read the comments.

**The accepted row went out again.** ROW-006 was accepted under the old text, and its step closed at stop 8. ViD does not take it back, and it does not let it stand unexamined either. In GitHub manual the apply sends it in a *follow-up ticket* of its step: its title begins *Follow-up ticket*, its header names the ticket it follows (`follows: #5`), and it asks no grade. The checked run sent the row in a reached-rows ticket instead, whose test was kept with an empty commit; the lab's files are for that ticket, not for a follow-up's asks. **Leave the follow-up open,** as you will leave the next step's ticket at stop 13. Your developers would work it as stop 8's ticket, by its own asks.

### Stop 11. The amended ticket

Ticket 8, ROW-019: the support address in every digest's footer. Nothing here is new. Do it without reading the explanations again, and see how much of the contract you already carry.

```bash
T=8
gh issue comment $T --body "vid: claimed
by: DM"
git checkout main && git pull
git checkout -b ticket-$T
cp -R $LAB/code/5-digest-footer-tests/. .
git add -A && git commit -m "tests: ROW-019, the support address in a digest's footer, before any product code"
git push -u origin ticket-$T
gh pr create --base main --head ticket-$T --title "Ticket $T: the support address in every digest's footer" --body "ticket: #$T

Decisions: none"
P=11
```

The red run. `3 failed, 14 passed`:

```bash
SHA=$(git rev-parse HEAD)
R=$WORK/reports/red-$T-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R
sed "s/<the tests-first commit, full id>/$SHA/" $LAB/reports/4-digest-footer/red-results.txt > $R/results.txt
sh $LAB/env/push-report.sh $REMOTE $R
```

The build, the merge, and the run at the head. `17 passed`:

```bash
cp -R $LAB/code/6-digest-footer-build/. .
git add -A && git commit -m "the support address in every digest's footer"
git push
gh pr merge $P --merge --body "Role: MR"
git checkout main && git pull
SHA=$(git rev-parse HEAD); H12=$(printf %s $SHA | cut -c1-12)
R=$WORK/reports/step-$T-$H12-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R
sed "s/<the head commit, full id>/$SHA/" $LAB/reports/4-digest-footer/head-results.txt > $R/results.txt
sh $LAB/env/push-report.sh $REMOTE $R
```

No break this time: ROW-019 had its red, and no accepted row's test changed what it checks, so nothing is retested. The grade, and the ask:

```bash
G=$WORK/reports/grade-step-$T-$H12-1; mkdir -p $G
sed "s/<the head commit, full id>/$SHA/" $LAB/reports/4-digest-footer/grade.txt > $G/grade.txt
sh $LAB/env/push-report.sh $REMOTE $G
gh issue comment $T --body "vid: decide $SHA"
```

*Lead's seat:* `/vid:vid-next`. *Dev seat:* `gh issue view $T --comments`, until the decision is there. The checked run's, given there under the pull request:

```
vid: decision 80204679ee079e004df992b16ba33857721c7cac
ticket: accepted
ROW-019 accepted
ROW-003 passing
ROW-004 passing
ROW-006 passing
```

### Stop 12. The step closes

ROW-019's step has no other ticket, so its close comes as ROW-006's did at stop 8: the call that accepted ticket 8, or your next one, opens a `run` issue for it, at the commit of the acceptance. Read its number off GitHub; each close names its own commit, so run it at the commit it names.

```bash
gh issue list --label run
```

**TM,** with its four rows:

```bash
C=<the number of the new run issue>
SHA=<the commit it names, in full>
gh issue comment $C --body "vid: started
by: TM"
R=$WORK/reports/req-$C-p1c1-1
sh $LAB/env/run-tests.sh $WORK/code $SHA $R -k "ROW_019 or ROW_003 or ROW_004 or ROW_006"
sed "s/<the commit the close issue names, full id>/$SHA/" $LAB/reports/5-closes/results.txt > $R/results.txt
sh $LAB/env/push-report.sh $REMOTE $R
gh issue comment $C --body "vid: reported p1c1-1"
```

`17 passed`. *Lead's seat:* `/vid:vid-next`. ViD reads the close, closes the step, and closes ticket 8 with its `vid: closed` comment.

The checked run's lead read a status page here. In GitHub manual, where things stand is what each call shows, and the plan page it writes: each step, what is left, and what waits on you. Each number on it is a count of evidence your side sent and ViD read. Nothing in it is anyone's estimate.

### Stop 13. Stop, and what is left

**You are done.** The next step's ticket, the two feeds, with six rows, is not published: nothing goes out until you name it, and the lab has no code for it. Leave it.

To stop: end the Claude Code session in the lead's seat. Nothing is read or decided until you call `/vid:vid-next` in that folder again, and each call restores ViD's records from its state repository.

Left open on purpose, and worth a look before you tidy:

- The staging deploy issue from stop 7, never deployed.
- The follow-up ticket of ROW-006 from stop 10, never claimed.
- In the lead's queue, the graders' findings, which wait for the lead's ruling. Each can be ruled a fix, a new row, a known limit or nothing. The overview's section 6 says what each means.

To tidy: delete the three repositories on GitHub (the code, the spec, and ViD's state repository) and the `$WORK` folder. Deleting a repository is permanent; check the name twice.

```bash
docker image rm jobdigest-lab-product jobdigest-lab-tests
```

---

## What this walk did not show you

Every ticket here was accepted at the first decision, because the lab's code and tests were already right. Your first real tickets will not be. Four things you did not see, each in the overview's section 4:

| What | When it happens | What your side does |
|---|---|---|
| **`ticket: not yet`** | Evidence a row needs is missing, a test failed, or the tests missed a deliberate break | Fix exactly what the decision names, merge the fix into `main`, and ask again at that new commit, with a new report |
| **A break after a grade** | A grade line reads `breached test`: the grader doubts the test would catch a broken product | Before you ask for the decision, plant a break aimed at what the line says and send the head report again as its next attempt, with the fault folder added. If the test fails under the break, the doubt is closed. If it passes, the test is weak and is fixed |
| **A sort** | A grade line reads `breached product` or `unclear` | Before the ask, a second reviewer, fresh, sorts each such line once: test it, note it or drop it. Then ask for the decision |
| **A held row** | A row has failed its rounds and cannot be accepted as it stands | Nothing: it goes to the lead, who accepts it, gives it more rounds, rules it a known limit or changes the spec. Every other ticket goes on |

---

## Part 2. Your own product

Part 1 used a spec that was already written. With your own product you write it first, with ViD. This part was not run for this tutorial; it follows the overview's section 3, which describes each sitting.

**1. An empty folder, and the interview.** In a new, empty folder, start Claude Code and say `/vid:vid-init`. ViD asks about the product, writes the PRD in three passes with your approval after each, asks the technical questions, derives the test inventory, and proposes the stage cut. A project started this way has its `checks/` folder from the start, so stop 2 does not apply. Give it a small product, something you could describe in ten sentences: the first spec is where you learn to read fail-ifs, and a large one teaches less.

**2. From here it is Part 1.** Name the code and spec repositories at the plan's setup; ViD makes them, private, at the switch, and you push the code repository's first commit after it (stops 3 and 4). Call `/vid:vid-next`: it plans first (stop 3); approve, its switch to GitHub manual made in the same call, and publish the skeleton (stop 4). From then on, call `/vid:vid-next` whenever your team has sent something.

**3. Your test setup replaces the lab's.** `env/` is this lab's, not ViD's. For your own product your team owns the same two things, in whatever tools it uses:

| What the lab's script does | Why the contract needs it |
|---|---|
| Runs the tests on a clean copy of exactly one commit | A report names a commit. What was not committed must not be in the run |
| Starts the product the way it really starts | Some rows ask for the product's own processes, not a shortcut inside the test |
| Writes a JUnit XML file for each browser engine, named `cases-<engine>.xml` | It is the one file ViD reads test results from. Any runner can write it |
| Puts each row's id in its tests' names | It is how a test case is tied to a row |
| Can apply a patch to the clean copy, then run a chosen few tests | The breaks, with their controls |
| Marks a test that could not run apart from one that failed | A broken setup is not a red, and not a product failure |
| Pushes one folder as one branch | How a report travels |

**4. Keep the roles apart.** In Part 1 you were everyone. With a team, the ticket's independence rules decide who may be whom, and the overview's section 4.2 turns them into a team of people. The short form: whoever writes or runs the tests does not build; the grader comes fresh; the builder never touches a test.

---

## When something does not go as written

| What you see | What it is | What to do |
|---|---|---|
| The plan refuses and names the `checks/` folder | Stop 2 was skipped | Do stop 2, then `/vid:vid-next` again |
| `/vid plan` is not a command | The commands are `/vid:vid-next` and `/vid:vid-fix`; the first call plans | Type `/vid` and pick from the list |
| The plan says the repositories are not named | The setup was not answered | Give the two repositories in words, as in stop 3 |
| The draft plan has no small step for ROW-006 | The planner cut it differently | Ask for the change in stop 3. Check the result by its rows, not its step names |
| The plan page does not open | The session could not publish it as a page | It gives a file's path instead; open that file in a browser |
| A move is shown again and not done | The call checks each move against what the last call listed | Call `/vid:vid-next` once, then name the move as it now shows it |
| No ticket comes after the skeleton's stage run | In GitHub manual a ticket goes out only when you publish it | `/vid:vid-next`, then its `publish` move (stop 7) |
| Nothing is decided though your team asked | ViD decides only at a call, with its own work on | `/vid:vid-next`. With its own work off, the call shows the ask with the command that decides it, `/vid:vid-accept-step <ticket> <commit>` |
| `run-tests.sh` stops with `setup: the product did not start` and an empty log | The base image could not be fetched | Check the network, `docker pull python:3.12-slim-bookworm`, then run again |
| `run-tests.sh` ends with every test failing on a line that begins `setup:` | The commit holds tests and no product | Expected at a tests-only commit of the skeleton. Anywhere else, check that you ran the right commit |
| `the fault … does not apply` | The patch does not fit that commit | Check `SHA` is the commit the stop names |
| The decision reads `not on main — <commit>` | The commit asked is not on `main`'s own line: a pull request's own last commit, for instance | Ask again at the merge commit, `git rev-parse origin/main` |
| The decision reads `no Decisions section — #<n>` | That pull request's description has no Decisions section | Add `Decisions: none`, or the decisions, to its description (`gh pr edit <n> --body …`), and ask again |
| The decision reads `not yet` | Something your side sent is missing or wrong | Read each row's line; it names what is short. The commonest causes here: a report pushed under the wrong id, or `SHA` not the commit of `main` you asked at |
| A question sits unanswered on a ticket | It is in the lead's queue, and nothing is said on GitHub until the lead answers | Lead's seat: `/vid:vid-next`, then its `answer` move |

---

## The contract on one page

**What your side writes on GitHub**

| Where | The words | Who | When |
|---|---|---|---|
| The ticket | `vid: claimed` / `by: DM` | DM | Before any work |
| The ticket, or a pull request of it | `Question: <rows> …`, with your default | Anyone | When the spec does not say |
| A pull request's description, as its first line | `ticket: #<n>` | DM | When it is opened |
| A pull request's description | `Decisions:` with one line a decision, or `Decisions: none` | DM | When it is opened |
| `main` | The ticket's pull requests, merged | MR | Before the head report |
| The ticket | `vid: decide <the commit of main, in full>` | MR | When the reports for that commit are pushed |
| A run issue | `vid: started` / `by: TM` | TM | Before the first chunk |
| A run issue | `vid: reported <chunk>-<attempt>` | TM | After each chunk's report is pushed |

**What your side pushes,** each as a branch `vid-results/<id>` holding one folder:

| The report | Its id | What is in the folder |
|---|---|---|
| The red run | `red-<ticket>-<k>` | `results.txt` (`by:`, `commit:`, `rows:`), `cases-<engine>.xml` |
| The run at the head | `step-<ticket>-<commit of main, 12>-<k>` | `results.txt` (`by:`, `commit:`, and `retested:` when a row is; at the skeleton also `engines:`, `environments:`, `stand-in:`), `cases-<engine>.xml`, and for each break `faults/<row>/cases-<engine>.xml` with `control.txt` (no control at the skeleton) |
| The grade | `grade-step-<ticket>-<commit of main, 12>-<k>` | `grade.txt`: `by: GR`, `commit:`, one verdict line a row, `finding:` lines |
| The sort, when a grade line is open | `sort-step-<ticket>-<commit of main, 12>-<k>` | `sorted.txt`: `by: SR`, `commit:`, one line for each open grade line |
| A chunk of a run | `req-<issue>-<chunk>-<k>` | `results.txt` (`by:`, `commit:`, `engines:`), `cases-<engine>.xml` |

The lab's `reports/README.md` names the head report, the grade and the sort in this mode's older pull request form; in GitHub manual use the ids above.

**What ViD writes**

| Where | What |
|---|---|
| An issue labelled `ticket` | A ticket, when the lead publishes it or applies a change: skeleton, step, follow-up or fix |
| A comment on the ticket | `vid: decision <commit>`, then `ticket: accepted` or `ticket: not yet`, then one line a row |
| A comment beginning `RM:` | The lead's answer to a question |
| A comment `vid: amended …` | The ticket's text changed with the spec |
| A comment `vid: closed — …` | The step's close passed; the ticket is closed |
| An issue labelled `run` | A run asked in chunks: a step's close, or a stage's full run |
| An issue labelled `deploy` | The okay to deploy a commit |

**What the lead types,** in a Claude Code session in the spec folder: `/vid:vid-next`, the first call planning and switching to GitHub manual, then alone or with its moves, each in the lead's own words (`own-work on`, `publish <step>`, `answer <its place or Q<n>> …`, `planning-analysis`, `implement-replan`); and `/vid:vid-fix <the change, in words>`.
