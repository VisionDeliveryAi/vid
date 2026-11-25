---
name: vid-placement-review
description: Two independent readers of where a plan's tests go, in ticket mode, in both GitHub modes — one fresh agent judges every test the plan places by eight rules, a second tries to disprove each of its findings, and a script joins the two and counts (`planner.sh placements`). Their findings are judgement and refuse nothing; what stands reaches the owner on the plan page or the re-plan page. Invoked by vid-plan before the first ratification and by vid-replan before a proposal or a large change; the owner's command `/vid:vid-placement-review` reads the whole plan as it stands and shows what it finds. Use when the owner says "vid placement-review" or asks whether the tests are in the right steps.
---

# /vid:vid-placement-review

One job: where the plan's tests go, read by two agents who are told nobody's reasons, and what stands counted and shown. Which
placements are listed, the form of the two outputs, the join and the counts are `checks/planner.sh placements` (its header says
each); the rules are `passes/reader.md`, read there and never copied.

**Called by the owner** as `/vid:vid-placement-review`, in either GitHub mode: the whole plan as it stands, `write
.vid/plan/placement-check --all`, one round. Inside /vid run's own conversation it uses the run's lock and leaves it held; anywhere
else the vid-connect skill's start first and its end after, however the call ends; while another session holds the lock, the start
says so, and nothing is done. Say the counts and each finding that stands with its better place
(`sh checks/planner.sh placements show .vid/plan/placement-check`); nothing else is recorded, and no placement is changed by it.

**Called by a skill,** which names the folder and the arguments: `<dir>` and `<args>` below.

1. **The list.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/planner.sh" placements write <dir> <args>`. `listed 0`: nothing to review; say so and stop.
2. **The readers.** For each `<dir>/part-<k>.md`, all in parallel, spawn a fresh agent (the Agent tool, general-purpose, no model
   override: it runs on the session's, claude-opus-5-5) with skills/vid-placement-review/passes/reader.md and that part's file, and nothing else (a
   re-plan's candidate: also its `left` file). Save each output beside its part as `<dir>/part-<k>.reader`, as it gave it, never edited.
3. **The second readers.** For each part whose reader gave a finding, all in parallel, spawn a fresh agent the same way with
   skills/vid-placement-review/passes/refuter.md, skills/vid-placement-review/passes/reader.md for the rules, that part's file and its
   findings (and the `left` file). Save each output as `<dir>/part-<k>.refuter`. A part with no finding needs none.
   Run every helper in the foreground (`run_in_background: false` on the Agent call), wait for its result, and never end a turn, nor schedule a wake-up, while one, or a command you started in the background, is running.
   Where the session holds ViD's lock, `sh "${CLAUDE_PLUGIN_ROOT}/checks/github.sh" lock-renew` before each set of agents: a lock goes cold in 900 seconds, and two rounds take 12 to 26 minutes.
4. **The result.** `sh "${CLAUDE_PLUGIN_ROOT}/checks/planner.sh" placements result <dir> <args>`. A refusal names the part and the line
   out of form: that reader is spawned again with the same files, told nothing of its first output, and `result` run again; a refused
   first reader's second reader goes with it: step 3 is done again for that part, once its new output is saved. It prints the counts, never a score.
5. **One second round, the caller's.** The caller reads each finding that stands or stands in part, in `<dir>/result`, corrects the
   ones it agrees with and runs its own check again; then steps 1 to 4 once more over what the corrections changed, `write <dir> --again <args>` and
   `result <dir> --again <args>`. There is no third. What still stands is shown to the owner on the caller's page, with its better
   place; a finding the planner does not take up is left, its reason in the plan's prose or in the change's why.
