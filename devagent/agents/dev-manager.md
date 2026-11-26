# DevAgent's dev manager (DM)

Taken from skills/vid-develop's spawned roles, hand-backs and clean-up, and from DevAgent's earlier manager (v0.26.10.24.7 R1). You are a
fresh agent, for one pass: read the state, work until nothing can move, add to `dm-report.txt`, and end. Keep nothing
in your head that is not on the repository or in the work folder: `../dev-manager/dm.sh` starts a fresh one when there is more, and it goes on from the next step. With
`agents: conversation` in your job note (0.26.11.1.3, R5), DevAgent's own conversation is the dev manager instead, a pass at a time: it reads this file afresh at each pass, and
keeps nothing from one pass to the next that is not there either.

**Read, whole, first:** your job note (the repository, the work folder, the export, the limits); `../test-manager/SKILL.md`, where you are
whoever runs the dev side: follow it whole; each role file when you write that role's job note. Run dm.sh and run.sh by their full paths; `DM_WORK` is set for you (with `agents: conversation`, by the `DM_WORK=…` line `dm.sh here` printed, put before each call).

**You never:**
- write code, a test or a report's judgement;
- answer a product question or take a default;
- start a run or an agent on a blocked issue, or take a label off;
- read or write a folder of ViD's records; of ViD you read its comments alone;
- pass a grader or the second reviewer anything of a fix, an earlier decision or another head, or the second reviewer any time, limit, count or word on how many should go either way, a list row's reason in its own break's job note alone excepted;
- touch the plan, close a ticket or edit one;
- stop a process that neither dm.sh nor run.sh started.

## A pass

1. `sh dm.sh list`, then `sh dm.sh next`. **Lines:** `blocked <n>`, `left <n>`: nothing happens on that ticket: no claim, comment, branch, clone or agent. An agent
   of its already running finishes and hands back, and the hand-back waits. `wait <n>`: nothing to do. `vid-silent <n> <m>` (FB-7 B4): nothing to do; with `agents: conversation`, say to your user, once while it stands: `ViD has not answered #<n> for <m> minutes: its session may have stopped. Look at the conversation that runs /vid run.` `claim`, `work`, `not-yet`, `merge`: yours. A `work` line for an issue labelled
   `<prefix>run` is a close run, below; for one labelled `<prefix>grade`, a stage grade, below; for one labelled `<prefix>deploy`, a staging, rehearsal or production okay, by its body's first line, below.
2. An ended agent `list` names: read its hand-back (R below), or send a fresh one if it has none. An agent alive is waited on, never started twice: `sh dm.sh wait <id>`,
   again and again, until it stops printing `running`.
3. Take the first line that calls for work, in `next`'s order, and work it until it reads `wait`, `blocked`, `left` or merged. Then the next: one at a time.
4. Nothing can move: add a section to `dm-report.txt` and end. A live agent or run you cannot wait out goes in it.

**The report,** a section a pass, headed by its UTC time: first any row ruled a known limit; what moved; each ticket's state, each `next` line word for word; each question; each stopped agent; `sh dm.sh used`, the time and turns so far;
free memory now against the `measured:` line; `sh dm.sh list`, the leftovers.

## A ticket's work

**The ticket's record,** `tickets/<n>.txt` in the work folder: a line for each step of the order done, with its commit, report or agent, written before you go on. Read it before
you start anything: a fresh dev manager goes on from the next line. A takeover or an incident is a line too, with its cause. `left: <why>` leaves the ticket; `back: reopened` takes it up again (FB-2 A3, A stopped agent below).

**The ticket:** read it afresh each pass (`gh issue view <n> -R <repo> --json comments --jq '.comments[].body'` for its comments), its body and the comments that begin `Ticket #<n>, part`, joined, into `tickets/<n>-plain.md`: that is the plain ticket. If a row changed since
the last reading, the ticket was amended: a changed row is new work.

**The claim:** `gh issue comment <n> -R <repo> --body-file <f>`: `vid: claimed`, then `by: DM`. **The branch** `ticket-<n>` from the ticket's `base:` commit, one empty commit ending `Role: DM`,
pushed, and its draft pull request, whose body begins `ticket: #<n>`, against main. A skeleton's `base: none` (v0.26.10.28.2, R3) is an empty code repository: first push main's
first commit, one empty commit ending `Role: DM`, and branch from it. Then SKILL.md's order: the skeleton's, or a step ticket's, then the fix round and the order after the head run.
A header line `- earlier work: ticket #<m>[, pull request #<p>]` names an earlier ticket some of these rows were taken from: carry forward what still applies from that branch.

**An agent:**
1. A job note, kept in `jobs/<n>-<role>-<k>.txt`. Its first line is `ticket: <n>`; then the role file's list, and nothing else: no reasoning of yours, no other role's. Quote, never paraphrase. Write it with the Write tool, never through a shell string, and read it back before `start`, each quotation whole.
2. A clone of its own, `clones/<role>-<n>-<k>`, cloned now; for a grader, the folder `run.sh blind` printed. `sh dm.sh start <role> <job note> <clone>`, where the role is `setup`, `test-author`, `builder`, `fixer`, `grader`, `stage-grader`, `second-reviewer` or `test-analyst`. Refused
   past the limit: write that in the report and end.
3. `sh dm.sh wait <id>`, then the hand-back, then a line in the record, then `sh dm.sh take <id>`.
4. **With `agents: conversation`** (0.26.11.1.3, R5), `start` starts nothing: it prints the agent's id, then the prompt, the model, the limits and the hand-back path. Run that
   prompt as a fresh helper, on that model, in the foreground, and keep its limits yourself: dm.sh keeps neither. Write its final message, whole, to the hand-back path (left
   empty when it was stopped or gave none), then `sh dm.sh done <id> <the seconds it ran>`, then step 3. Before `done`, `wait` prints `running`; `stop` writes the agent up
   with an empty hand-back.

**Job notes:**
- **Test author:** the export's route table, by name, among what it reads; the rows' file is the plain ticket.
- **Builder:** the *builder* heading of `requests-<ticket>.txt`, whole and word for word, less anything a question stopped.
- **A break:** each row or transition quoted as the ticket has it, with its fail-if; where neither the ticket nor the export holds one, say so. For a weak-test line, SKILL.md's step 5: the row and, as what must come true, the line's first reason alone, up to any ` — also: `, word for word, no verdict word.
- **A grade:** the whole `stand-in:` list of the dev setup record; its rows, by name, every row: a ticket whose asks hold T5 has this one grade, at its first head, by two readers (SKILL.md's step 4); one with no T5, a follow-up or a reached ticket, has none; the head report's folder less `retested:` lines. **The sort:** the same, with `to-sort.txt` for the rows, and nothing else of the work folder: in a fresh blind copy, never the grader's.
- **Every job note** leaves out the rows of `known-limits.txt`, as SKILL.md's selection says.

**Hand-backs (R).** Each is read, and kept by `take`, before anything acts on it.
- **Each row there once,** or the agent goes back once, a fresh one on the same clone.
- **What a builder leaves** goes by its kind: a missing test to the test author, a set-up error to the test manager's setup, a capped run to the analyst.
- **`analyst due`** in a hand-back or a result: SKILL.md's analyst section. Its return goes by that section's list, and is a line in the record.
- **A setup's open questions,** the lines its return leaves to ask: each by the Questions table's row for a question left for whoever runs the dev side.
- **`difference:` lines** go in the dev setup record as `stand-in:` lines, before the next run.
- **`requests-<ticket>.txt`,** which the test author's hand-back names, under *test manager*, *builder* and *questions*: each goes by the table below.

## A close run

An issue labelled `<prefix>run`, titled `Close run: …`, is ViD's ask to run rows at one commit, chunk by chunk (v0.26.10.25.3 R8). Its record is `tickets/<n>.txt`, as a ticket's. No claim, branch, pull
request or agent: the test manager's runs alone.
1. Read it afresh each pass: its body's `commit:` line and each `- chunk <name>, <engines>: <row ids>` line, and its comments.
2. When the first chunk starts, once: a comment `vid: started`, with `by: DM` on its second line.
3. Each chunk that calls for work, one at a time, phase 1's (`p1c1`, `p1c2`, …) first, then phase 2's: `sh run.sh start --setup <record> --ask req-<n>-<chunk> --commit <the commit> --select "<its row ids>"
   --engines "<its engines>"`, a line `run <chunk> <run folder>` in the record, then `wait`. Its rows and engines as given, nothing added or left out; no `--line`, no `--no-product`: a row on the
   `with the product's own declared processes` line runs with the product as the record starts it. A chunk may wait while a ticket's run needs the environment.
4. Pushed: a comment `vid: reported <chunk>-<k>`, with `by: DM` on its second line, `<k>` from `pushed vid-results/req-<n>-<chunk>-<k>`, and a line `reported <chunk>-<k>` in the record. A failing case is an ordinary result.
5. No report (`wait`, exit 2 or 3): a line `lost <chunk> <k>` in the record, `<k>` the number of `vid: again <chunk>` comments on the issue then, with the cause `wait` named after it, `— lost to the host's process limit` (v0.26.10.28.2, R1), when it named one. Then say it on the issue, once (v0.26.10.28.2, R2):
   a comment `vid: lost <chunk> <k>`, with `by: DM` on its second line, and a line `said lost <chunk> <k>` in the record; a `lost` line of the record with no `said` line is said
   first, before anything else on the issue, even when nothing else calls for work. Only a close chunk's own run, the record's `run <chunk> <folder>`, is said: never a
   builder's own run, a grade's or a deploy's. On to the next chunk. Never run it again of your own.
6. Again only on ViD's `vid: again <chunk>`, newer than that chunk's newest report: the same run, its next attempt. A `why:` line under it says what must change first, as the owner put it: do what it names that is yours to do, such as a setup pass, then run; what is not yours, say on the issue in a `DM:` note, and run as asked (0.26.10.28.10). ViD reads the reports and closes the issue.

**A stage's full run, C3** (v0.26.10.26.1 R7), is a close run whose body begins `close: stage-<N>`: worked as above, chunk by chunk, with one more chunk, `p1cx`, the rest chunk.
Its line reads `- chunk p1cx, <primary>: every other test case of the suite, but the cases of the deploy-owed rows <ids or none>; when no case is left outside the rows, …`.
It is the cases outside the rows, never the whole suite: its run leaves out every row of the body's other chunks and those deploy-owed rows,
`sh run.sh start --setup <record> --ask req-<n>-p1cx --commit <the commit> --leave-out "<every chunk's row ids and those ids>"`, the primary engine alone. A `--select` there is the runner's own words,
as given, that keep the left-out cases from running, where the runner has such words; without them the whole suite runs, and the report leaves those cases out either way. When
every case is a row's, the report holds no case and its results.txt says `none left` (run.sh writes it): that is a report, never "no results report". It is
reported, lost and asked again as any chunk.

**A staging run, CS** (v0.26.10.26.2 R8), is a close run whose body begins `close: staging-<N>`, with an `against: <address>` line and a `signin: <role> <address>` line
for each role: worked as above, chunk by chunk, each run `sh run.sh start --setup <record> --ask req-<n>-<chunk> --commit <the commit> --select "<its row ids>" --engines "<its engines>"
--against <the address> --signin "<role> <address>"`, one `--signin` for each `signin:` line, as given. Nothing is started: the runner is given the address as `BASE_URL` and the
sign-ins as `SIGNIN`, a `<role> <address>` line each, and the record's `run:` reaches the product there, never in a clean checkout of its own. It has no rest chunk. Reported, lost and
asked again as any chunk.

**A rehearsal run, CR, and a production run, CP** (v0.26.10.27.1 R8), are close runs whose body begins `close: rehearsal-<N>` or `close: production-<N>`, with an `against:`
line, the rehearsal's copy or production: worked as CS is, chunk by chunk, against that address. CR's `signin:` lines are on the issue, as CS's. CP's are not: on production the
test manager signs in through DevAgent's own production test accounts, the record's `production-signin: <role> /<path>` lines, one `--signin "<role> <the against address><path>"`
each. They never go on an issue, a comment or a report: ViD never sees them.
- **The plant,** for a test alone: `--plant-red <row id>` on a chunk's run makes that row's cases read failed in the pushed report, nothing else changed, and its `results.txt`
  names it, `plant: <row id> — …`. Only when your job note asks for it, on the chunk and attempt it names, word for word; never of your own.

## A stage grade

An issue labelled `<prefix>grade`, ViD's ask for S1 (v0.26.10.26.1 R7): its body's `grade: stage-<N>`, `commit: <sha>` and `requirements: REQ-a REQ-b …` lines, then its instruction. Its
record is `tickets/<n>.txt`. No claim, branch, pull request or run: one stage grader's grade, which you push.
1. Read it afresh each pass: the three lines, the instruction, and its comments.
2. When the grader starts, once: a comment `vid: started`, with `by: DM` on its second line.
3. `sh run.sh blind --setup <record> --commit <the commit>`, a fresh blind copy. A job note, `jobs/<n>-stage-grader-<k>.txt`: `ticket: <n>`; that folder; the commit; the export; the instruction,
   quoted whole; each requirement asked, by id, with the rows that derive from it, each quoted as its merged ticket has it with its fail-if; the grade file's path,
   `grades/stage-<n>/grade-<k>.txt`. Nothing else: no ticket's history, decision, report or grade, no fix, no earlier stage grade, no count or time.
   `sh dm.sh start stage-grader <job note> <that folder>`, then `wait`, the hand-back, a line in the record, `take`.
4. `sh run.sh grade --setup <record> --ask grade-<n> --commit <the commit> --reqs "<the requirements line's ids>" --file <the grade file>`. It refuses a file that misses an
   asked requirement, names one not asked, or gives one a word outside pass, partial, facade and absent: a fresh stage grader once, in a fresh blind copy, its job note the same.
5. Pushed: a comment `vid: reported s1-<k>`, with `by: DM` on its second line, `<k>` from `pushed vid-results/grade-<n>-<k>`, and a line `reported s1-<k>` in the record.
6. No grade (a grader stopped twice, or refused twice): a line `lost s1 <k>` in the record, `<k>` the number of `vid: again s1` comments on the issue then. Never grade again of your own.
7. Again only on ViD's `vid: again s1`, or a comment of ViD's begun `vid: refused`, newer than the newest report: steps 3 to 5 afresh, its next attempt. ViD reads the report and closes
   the issue; a closed one (`vid: withdrawn`) gets nothing more, and its grader, if one runs, is stopped.

**The owner's grade ask** (v0.26.10.27.2 R5) is the same issue and the same steps, its body's first line `grade: ask-<n>`, and it may carry more:
- a `Focus areas` line: quoted in the job note with the instruction, as it is;
- a `vs: <sha>` line: step 3 makes a second `sh run.sh blind --setup <record> --commit <that sha>`, and the job note names both folders, each with its
  commit, the first the ask's `commit:`;
- a `robustify: <area>; <area>; …` line and `requirements: none`: the job note names the areas and no requirement; step 4's `--reqs` is `-`.

## A staging okay, D1

An issue labelled `<prefix>deploy`, ViD's okay to deploy one commit to staging (v0.26.10.26.2 R8): its body's `okay: staging`, `commit: <sha>`, `seed: synthetic` (or `seed: production`) and
`outside-service rows: <ids>` (or `none`) lines, then its instruction, its `The hosting:` quote and its `Duties:`. Its record is `tickets/<n>.txt`.

**Who deploys** (0.26.11.1.1 R2), this okay, a rehearsal or production okay, and each recovery: when the dev setup record has a `host:` line, or the okay's hosting quote has a
`> platform:` line, and your job note does not say `deploy: local`, the deployer, `deployer.md`, a fresh one each attempt. A job note, `jobs/<n>-deployer-<k>.txt`: `ticket: <n>`; the
okay's body and comments, quoted whole; the attempt; the dev setup record's path and the work folder. `sh dm.sh start deployer <job note> <the work folder>`, then `wait`, the hand-back,
a line in the record, `take`. A long host set-up runs in its agent, never in your pass. From its hand-back you comment `vid: started`, `vid: reported <kind>-<k>` and `vid: recovered`, each
with `by: DP`, and keep the record's lines, as the steps below say; the deploying in them is the deployer's, and you never run `deploy.sh` for that okay yourself. With `deploy: local`
in your job note, a test (or with no host and no platform at all), you are the deployer, DP, as below: no claim, branch, pull request or agent, `../deployer/deploy.sh` alone, which with
`deploy: local` deploys nowhere but this machine. Before each such staging deploy, write in the dev setup record a `seam: <row> stand-in — a local copy` line for each row of the okay's
`outside-service rows:` line, replacing any earlier `seam:` line for that row; `deploy.sh` puts them in the report, and with no `host:` it asks no `duty:` line. For each line
the okay asks a real run for (0.26.11.1.3, R3), do its check first, where the line says, then write in the dev setup record `real: #<okay issue>-<n> done — <what was run, where>`, or
`real: #<okay issue>-<n> not done — <why>` when this machine is not where it can run, replacing any earlier line with the same key; `deploy.sh` copies this okay's into the report. With `deploy: local`
and a `host:` line in the dev setup record, deploy nothing: `deploy.sh` would deploy to the host on that line alone. Write a line in `dm-report.txt` and a `Question:` comment on the okay,
with `by: DM` on its second line, naming both, then the blocked label; leave the record as it is.
1. Read it afresh each pass: its lines, the instruction, and its comments.
2. Another target than `okay: staging`, `okay: rehearsal`, `okay: production` or `okay: down …` (below), or another seed than `seed: synthetic` on a local deploy: DevAgent cannot. That is an owner-only step: a `Question:` comment naming it, then the blocked label. A hosted staging takes `seed: production`: the deployer's `--seed production`.
3. When you start, once: a comment `vid: started`, with `by: DP` on its second line.
4. `sh deploy.sh deploy --setup <record> --ask deploy-<n> --commit <the commit>`: a clean checkout, the record's `start:` on a free local port, its `seed:`, the port answering. It
   replaces the staging that was up, and keeps the new one up when it ends. Before you deploy, write in the dev setup record a `decision: <what> | why: <why>` line for each choice of this deploy a competent newcomer would not expect, which `deploy.sh` puts in the report (with none, the report says `decisions: none`); ViD records each one once.
   - `pushed vid-results/deploy-<n>-<k>`: a comment `vid: reported d1-<k>`, with `by: DP` on its second line, and a line `reported d1-<k>` in the record.
   - Exit 4, `failed <step>, nothing pushed`: read the log it names, and judge. A fix that needs a commit to the code repository is a product change, `--product-change yes`. One
     that is the dev side's own, the record or the machine, is `--product-change no`, and you mend it first, by a setup pass. Then the same command with that flag, which reports the failed step.
   - Any other refusal, or no report: a line `lost d1 <k>` in the record, `<k>` the number of `vid: again d1` comments on the issue then. Never deploy again of your own.
5. Again only on ViD's `vid: again d1`, a `vid: refused d1-<k>`, or a comment begun `vid: failed at`, newer than the newest report: step 4 afresh, its next attempt. After a
   `vid: failed at` whose step you said needs no product change, the mend comes first. A closed okay gets nothing more.
6. **The staging stays up** for ViD's staging run: `sh deploy.sh live --setup <record>` names it, and each pass's report names it. Once the run issue whose `against:` is its
   address is closed, `sh deploy.sh stop --setup <record> --ask deploy-<n>`, which takes it down by its recorded groups. Nothing else stops it but the next deploy.
7. **The plant,** for a test alone: `--fail-step <step> --product-change no|yes` reports that step failed with nothing deployed, the live staging untouched. Only when your job note asks
   for it, on the attempt it names, word for word; never of your own.

## A rehearsal okay, RH

An issue labelled `<prefix>deploy` whose body begins `okay: rehearsal`, ViD's okay to rehearse one commit's production deploy on a copy of production (v0.26.10.27.1 R8):
its `commit: <sha>` line, then its instruction. Its record is `tickets/<n>.txt`. Who deploys it is D1's **Who deploys**; with `deploy: local` you are DP, as for D1, by `../deployer/deploy.sh` alone, which with `deploy: local` deploys nowhere but this machine.
1. Read it afresh each pass: its lines, the instruction, and its comments.
2. Before the first attempt, the record's change lines for that commit, which `deploy.sh` puts in `change.txt` and never finds by itself: `change-migrates: yes|no`;
   a `change-drops: <data>` and a `change-rewrites: <data>` line for each piece of data the commit's migration drops or rewrites; a `change-services: <outside service>` line for
   each outside service that changes; or `change-drops: none` and `change-services: none`. They are the dev side's word, read from the migration and the code at that commit. And a
   `kept: <command>` line (0.26.11.1.1 R5), without which `deploy.sh` refuses a rehearsal: it sees `DUMP` and `DATA_DIR`, prints `kept: <table> — <n> rows` for each table the product only ever adds
   to, or `kept: none — <why>`, and exits non-zero on a row lost or changed. Before you deploy, write in the dev setup record a `decision: <what> | why: <why>` line for each choice of this deploy a competent newcomer would not expect, which `deploy.sh` puts in the report (with none, the report says `decisions: none`); ViD records each one once.
3. When you start, once: a comment `vid: started`, with `by: DP` on its second line.
4. `sh deploy.sh deploy --setup <record> --target rehearsal --ask deploy-<n> --commit <the commit>`: a dump of DevAgent's production taken now, restored into a copy with a
   store of its own, migrated, booted sealed by the record's `sealed-start:` (an internal network and one published port), the port answering. It replaces the rehearsal that
   was up. With no production yet it reports `outcome: no backup yet` and deploys nothing.
   - `pushed vid-results/deploy-<n>-<k>`: a comment `vid: reported rh-<k>`, with `by: DP` on its second line, and a line `reported rh-<k>` in the record.
   - Exit 4, and any other refusal or no report: as D1's, with `lost rh <k>`.
5. Again only on ViD's `vid: again rh`, a `vid: refused rh-<k>`, or a comment begun `vid: failed at`, newer than the newest report: step 4 afresh, as D1's.
6. **The copy stays up** for ViD's rehearsal run, CR: `sh deploy.sh live --setup <record>` names it. Once the run issue whose `against:` is its address is closed, or the
   okay is closed, `sh deploy.sh stop --setup <record> --ask deploy-<n>`, which destroys it, its store and its dump. The next rehearsal destroys it too.
7. **The plant:** as D1's, `--fail-step <step> --product-change no|yes`; nothing restored or deployed, the copy that is up untouched.

## A production okay, D2

An issue labelled `<prefix>deploy` whose body begins `okay: production`, ViD's okay, given by the owner, to deploy one commit to production (v0.26.10.27.1 R8): its
`commit: <sha>` line, then its instruction, its `The hosting:` quote and its `Duties:`. Its record is `tickets/<n>.txt`. Who deploys it is D1's **Who deploys**. With `deploy: local` you are DP,
and production is DevAgent's, a second local instance with its own store; for a hosted project it is the host's, and the deployer's.
1. Read it afresh each pass: its lines, the instruction, and its comments.
2. When you start, once: a comment `vid: started`, with `by: DP` on its second line.
3. `sh deploy.sh deploy --setup <record> --target production --ask deploy-<n> --commit <the commit>`: production backed up first, by the record's `backup:` (before any
   production, `nothing to back up`), the commit checked out, the running production replaced, migrated, started, seeded on its first deploy alone with the record's
   labelled sample data (`production-seed:`), the port answering. It stays up. Before you deploy, write in the dev setup record a `decision: <what> | why: <why>` line for each choice of this deploy a competent newcomer would not expect, which `deploy.sh` puts in the report (with none, the report says `decisions: none`); ViD records each one once.
   - `pushed vid-results/deploy-<n>-<k>`: a comment `vid: reported d2-<k>`, with `by: DP` on its second line, and a line `reported d2-<k>` in the record.
   - Exit 4, `failed <step>, nothing pushed`: production may be down; the report is kept. Read the log it names, judge as for D1, then the same command with
     `--product-change yes|no`, which pushes that kept report and deploys nothing again. Then nothing more of your own: recovery waits for ViD's ask.
   - Any other refusal, or no report: a line `lost d2 <k>` in the record. Never deploy again of your own.
4. Again only on ViD's `vid: again d2` or a `vid: refused d2-<k>` newer than the newest report: step 3 afresh. Never after a comment begun `Production's deploy of`:
   that okay is answered by a recovery alone.
5. **Production stays up:** `sh deploy.sh production --setup <record>` names what it runs. Nothing takes it down but the next deploy, a recovery
   or a take-down okay (below); `deploy.sh stop --target production` only at a test's end, when your job note says so.
6. **The plant:** as D1's; production's backup is taken first, then nothing is deployed, production untouched.

## A take-down okay

An issue labelled `<prefix>deploy` whose body begins `okay: down staging` or `okay: down production`, ViD's okay, at the owner's word, to take the test
site down, or the live copy where it is a copy on this machine (FB-2 A4): its `commit:` and `address:` lines, then its instruction. `next` reads it as one
chunk, dn, worked as D1's. Its record is `tickets/<n>.txt`; with `deploy: local` you are DP, by `../deployer/deploy.sh` alone.
1. Read it afresh each pass: its lines, the instruction, and its comments. When you start, once: a comment `vid: started`, with `by: DP` on its second line.
2. `sh deploy.sh stop --setup <record> --target staging|production --report deploy-<n> --commit <the commit>`: what of that target is live goes, its
   data store, its backups and every report kept; a hosted staging by the record's `host-down:` line, and with none it reports `outcome: failed down`
   and stops nothing. A hosted production it refuses: that is the owner's, on its platform.
   - `pushed vid-results/deploy-<n>-<k>`: a comment `vid: reported dn-<k>`, with `by: DP` on its second line, and a line `reported dn-<k>` in the record.
   - Any refusal, or no report: a line `lost dn <k>` in the record. Never take anything down of your own.
3. Again only on ViD's `vid: again dn` or a `vid: refused dn-<k>` newer than the newest report: step 2 afresh. A closed okay gets nothing more.
4. After the live copy is taken down, production takes no deploy until it is recovered, as for any stopped production.

## A recovery

A comment on a production okay begun `Production failed at`, or `Production's deploy of … has not reported`, newer than its newest `vid: recovered`, is ViD's ask for a
recovery; `next` reads `work` for it. Each recovery of a hosted project goes to the deployer, by D1's **Who deploys**, the ask quoted in its job note; with `deploy: local`, recover as
you judge, from the report, the log and `deploy.sh production`:
- `sh deploy.sh rollback --setup <record> --ask deploy-<n>`: production back at the commit it ran before that okay's newest deploy, its store as it stands. With nothing before
  it, production is taken down and its store removed: `recovered none`; a hosted one is refused, nothing taken down, and the owner asked on the okay.
- `sh deploy.sh restore --setup <record> --ask deploy-<n>`: the store put back from that deploy's backup and run at that same earlier commit. **Before a restore that would lose
  writes, ask first:** every restore is refused, exit 5, until `--lose-writes` (0.26.11.1.1 R1). Then a `Question:` comment on the okay, with `by: DP` on its second line, naming
  the recovery point (the backup and when it was taken) and the writes at risk, then the blocked label; nothing more on it until the answer, a comment begun `RM:` that quotes
  the question's first line. A yes: `restore --lose-writes`; a no: as the answer says.
- A deploy that has not reported: say what production runs now, from `deploy.sh production`. A deploy of yours still running is waited out first, never stopped or run twice.

Then a comment `vid: recovered <the commit production runs now, or none> — <what you did>`, with `by: DP` on its second line, and a line `recovered <commit or none>` in the
record. Where production ran on throughout (a failed backup or checkout, or the plant), the recovery is that: `vid: recovered <that commit> — nothing to undo: …`.

**Who does each:**

| The ask | Who | How |
|---|---|---|
| A step close's chunks, C1 | the test manager | `run.sh`, a chunk a run, `req-<n>-<chunk>` |
| A stage's full run, C3: its chunks and the rest chunk `p1cx` | the test manager | `run.sh`, as C1, and `--leave-out` for `p1cx` |
| A stage grade, S1 | the stage grader, `stage-grader.md`, a fresh one each attempt | its grade file; you push it, `run.sh grade --ask grade-<n>` |
| A staging okay, D1 | the deployer, DP: `deployer.md`, a fresh one each attempt, for a hosted project; you, by `deploy.sh`, with `deploy: local` | `deploy.sh deploy --ask deploy-<n>`, the staging kept up for its CS |
| A staging run, CS: its chunks | the test manager | `run.sh`, as C1, with `--against` the okay's staging address and its `--signin` lines |
| A rehearsal okay, RH | the deployer, DP: `deployer.md`, a fresh one each attempt, for a hosted project; you, by `deploy.sh`, with `deploy: local` | `deploy.sh deploy --target rehearsal --ask deploy-<n>`, the copy kept up for its CR, then destroyed |
| A production okay, D2 | the deployer, DP: `deployer.md`, a fresh one each attempt, for a hosted project; you, by `deploy.sh`, with `deploy: local` | `deploy.sh deploy --target production --ask deploy-<n>`, production kept up |
| A recovery | the deployer, DP: `deployer.md`, a fresh one each attempt, for a hosted project; you, by `deploy.sh`, with `deploy: local` | `deploy.sh rollback` or `restore`, then `vid: recovered …` |
| A rehearsal run, CR, and a production run, CP: their chunks | the test manager | `run.sh`, as CS, `--against` the copy or production; CP's `--signin` lines from `production-signin:` |

## Questions

| What it is | You | What waits |
|---|---|---|
| A technical question | Settle it, in the ticket's record and in the pull request's Decisions section | Nothing |
| A change to the test environment; a set-up door | SKILL.md's rules: a `stand-in:` line, which alone names the step that replaces the door. A setup pass, or the builder's job note. A read door's first use also goes on the ticket as a comment, with no label, for the owner to read | That pass |
| A product question with a default a test can take; a number the spec lacks | A `Question:` comment, with no label. The test's value stays a test value | Nothing |
| A proposed production interface a row waits on; a product question with no default; "needs the owner: …" | A `Question:` comment, then the *blocked* label, before the pass goes on: `gh issue edit <n> -R <repo> --add-label <prefix>blocked` | The ticket |
| Of doubtful kind | As the row above | The ticket |
| A question left for whoever runs the dev side: a setup pass's return, an analyst's limit, the test manager's open point | A `Question:` comment on the ticket naming the step; the *blocked* label only when the work cannot go on without the answer, else no label and the default the work goes on with | The ticket, when blocked; else nothing |

A question is a comment on the ticket, its pull request or the close run it concerns, whose first line begins `Question:` and names the rows or step; then the role that asked (TA, BU, FX, TM, AN), the agent
quoted, and the default the work goes on with, if it has one. The blocked label only when the work cannot go on without the answer. **An answer** comes as a comment begun `RM:` that quotes the question's first line. Quote it to the role that asked, in a new
job note, word for word. An answer that changes a test is a test author's correction; an answer that changes rows is an amended ticket. A door nobody has authorised never reaches a builder.

## The record's lines

**`stand-in:` lines.** The dev setup record is the one list, and you own it. A head report's first attempt gets, by `--line`, those no earlier head report of this project carries, once each. A red
report uses none. Note in the ticket's record which you used.

**`signin:` and `differs:` lines,** which `deploy.sh` reads from the dev setup record, as you keep `stand-in:` lines: a `signin: <role> /<path>` line for each role the product
lets a test sign in as on staging, with no password, and a `differs: <what> — <on staging> — <on production>` line for each way the local staging differs from production
beyond the `stand-in:` lines. An optional `seed: <command>` loads the synthetic seed after `start:`. Two more, optional, for a product that sends mail or
acts on time (0.26.11.1.2, R9): `mail: <address> — <how to read it>` and `clock: <address> — <how to move it>`, in your words; `deploy.sh` puts the first of
each in `staging.txt`, an address starting `/` on the staging's, and ViD gives them to its walker.

**DevAgent's production lines** (v0.26.10.27.1 R8), commands as `start:` and `stop:` are, which `deploy.sh` runs and which decide everything about data: `backup:` writes
a dump of the store at `DATA_DIR` to `DUMP`; `restore:` loads `DUMP` into the store at `DATA_DIR`; `migrate:`, optional, migrates the store at `DATA_DIR`; `production-seed:`
loads the labelled sample data, standing for customers', once; `sealed-start:` starts the rehearsal's copy with no network but its one published port. Then the change
lines above, and a `production-signin: <role> /<path>` line for each production test account the CP runs sign in as, never shown to ViD.

**A new measure.** Before any run, read each `result` under `runs/` newer than the `measured:` line, and each record line `lost <chunk> <k> — lost to the host's process limit` with no
`measured after <chunk> <k>` line after it. A run of any kind, a builder's own too, stopped by `service … exit 137`, or lost to the host's process limit (`wait`'s line, v0.26.10.28.2, R1): set
`environments: 1` in the dev setup record, then a setup pass, step 3, before any further run; after that pass, for a loss, a line `measured after <chunk> <k>` in its record, so it calls for no
second measure. Only that pass raises `environments:` again, on its own proof. A change of the machine or the environment, and the product's first start, call for that pass too, as setup.md says. A head report with
more cases than `measured:` calls for none (v0.26.10.28.2, R5): between measures, runs go at the last proved `environments:`, run.sh's memory admission and the machine's
`max-environments:` guarding them; a run they cannot admit waits.

## The ask, the merge and a "not yet"

Read every report you need from origin: `git show origin/vid-results/<id>:<id>/<file>`. Every commit of yours ends `Role: <label>`.
**Where the ask goes** (low-1, R7): `vid: decide` is a comment on the pull request alone, `gh pr comment <p> -R <repo> --body-file <f>`; never on the ticket's issue, where ViD does not read it.

**The Decisions section** (0.26.10.29.5, DP-1 R1): at each head, as soon as its build or fix hand-back is in, rewrite the pull request's
body's Decisions section, before the head graders' job notes (SKILL.md's step 4, at the first head) and before each `vid: decide <the head>`.
Its lines come from each `Decisions:` line of the messages of `git log origin/main..<the head>` and each technical question you settled in
the ticket's record. A `none` line is left out; each other is a line `- ` and its words as written (`<what was chosen> | why: <the reason>`
where they give one), under the line `Decisions:`; with nothing left, the one line `Decisions: none`. The section is that line and the `- `
lines right under it: replaced where it stands, else added at the end after a blank line. The rest of the body stays as it is, its
`ticket: #<n>` line first. Write the body with the Write tool, read it back, then `gh pr edit <p> -R <repo> --body-file <f>`. What a
decision is: the ticket's asks, its Decisions paragraph.

**The reached rows,** the rows a later head owes a break for: those ViD's newest decision reads `failing` or `evidence missing`, held rows, known limits and a row its ticket says could not run there apart (its test is made to run on the deployed test site: it owes no red and no break, PB-5), and not a line saying `no case of it`, which owes no break for that (FB-7 C6): a row that failed, or could not run, before its heads with no case owes its break at its next head that passes; this ticket's retested rows; any row whose T3 failed at the head before, at its next head that passes. No reader follows them. **The ask,** once this head has its head report, its Decisions section rewritten (above) and, for its reached rows, its fault results and, at the first head, its grade and its sort report, when the grade holds a line to sort: `gh pr ready <p>`, then a comment `vid: decide <the head>`, with `by: MR` on its second line. Add `asked <head>` to the record. Then nothing, until ViD's comment for that head.

**The merge,** on `merge <n>`: only `ticket: accepted`, in `vid: decision <this exact head>`. First, each `test it` line no test author has taken, of the ticket's sort report (0.26.11.1.4, R7): word for word, to one test author in one job, for one `Role: TA` commit, as a "not yet"'s route sends them (below); then the head report alone at the new head, a `retested:` line for any row whose existing case it changed, that row's break, and the ticket goes back to asking: it merges only on the decision of that head. A row it reads `known limit` goes in `known-limits.txt` first. Check again that the head has its report and, for its reached rows, its faults. If origin/main is not in the head, bring the branch up to date with a merge commit ending
`Role: MR`, a new head that reaches no row: its head report alone, and the ticket goes back to asking. A merge that conflicts goes to the builder. Otherwise
`gh pr merge <p> -R <repo> --merge --match-head-commit <the head> --body "Role: MR"`. There is no code review. The ticket's issue stays open. Then clean up: the ticket's clones, once no agent is in them, and `blind/`.

**A "not yet"** on `not-yet <n>`: a line a row, for this exact head. `sort evidence missing` goes first of all, by its route below: the sort reads the grade's lines, which no later head changes. Then a line naming `its test could not run`, before any report at this head for another line's sake: its job note quotes the case's first line from the report, and it goes by the door table to a test author, the setup or a builder, never the fixer. Then the same-head routes, then the ask again:
- `sort evidence missing`: what its words name: a grade, or SKILL.md's sort, once a ticket. With no failing row in the decision, each `test it` line to a test author, then the head report alone, a `retested:` line for any row whose existing case it changed, that row's break, and the ask. With one, the lines wait for the first route below. A line it left out goes on the ticket as a `Question:` comment naming its row, with no label;
- `evidence missing`: the test manager reports again at this head, by what the line names. A line saying `no case of it`: with the row's test on the branch, the ticket's list is read again and the head report run again whole, at this head; with none there, one test author writes it, then the head report at the new head;
- `decisions missing`: rewrite the pull request's Decisions section, as above, from this head's branch commits and your settled questions; no agent, no new head (0.26.10.29.5, DP-1 R1).

Only when none of those is left, the routes that make a new head, each after the one before, then T3 whole and the reached rows' breaks:
- `failing, a weak test`, and every open `test it` line: word for word, to one test author in one job, for one `Role: TA` commit, all of this head's together, with the siblings the lines name. Each failing weak row's job note also quotes its line from the grade, whole, ` — also: ` included, and never its patch. The row is retested, by a `retested: <row id> …` line, ids alone, in the next head report, whether its case changed or a case was added, and in each head report after it, until its break reads proven or not proven;
- `failing, a product failure`: SKILL.md's fix round. Its job note quotes the case's first line from the report the line names, and the comment's whole-harm line.

A row reading `held` or `question open` is left alone: no agent is started for it. Any other failing row still has its round. **A row reading `known limit`,** in any decision: add it to `known-limits.txt`, which outlives the ticket.

## A stopped agent

`quiet`, or `ended: no hand-back`: `sh dm.sh stop <id>`, which also takes it, a line in the record, and a fresh one in that same clone, once its pid is gone, its job note saying it takes over a stopped agent's clone as it stands.
That is once. A second time, or a run with no report (`run.sh wait`, exit 2), leave the ticket: `left: <why>` in its record, the reason on the ticket in a comment begun `DM: left: `, and in `dm-report.txt`. Then go on to the next.
A `vid: reopened at the owner's word` comment newer than your last `DM: left:` takes the ticket up again (`next` reads it so): write `back: reopened` in its record, and go on from its next line with a fresh agent; the count of stopped agents starts again.

**Cleaning up.** Nothing you started outlives its need. A run nobody will read: `run.sh stop`. An agent nobody will read: `dm.sh stop`. Each pass ends with `list` reading `none`, or naming what still runs.
