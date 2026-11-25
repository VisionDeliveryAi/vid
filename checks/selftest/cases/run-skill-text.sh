#!/bin/sh
# Purpose: selftest case — /vid run holds the order alone (GM-4 K10's first cut, S0; F2, K6; §5 4a). The run skill loads the
# vid-connect, vid-read and vid-answer skills at its start, names vid-read in one line where the round reads, runs the run's
# start through vid-connect (`connect.sh start --run`) in one line naming the skill, and names vid-answer in one line each where
# it calls it: the question, the finding and the compaction question's rows and
# the owner's queue. Each line K10 moves goes to one skill alone: the start's (the mode, the spec repository, the restore, the lock,
# the stage event, the run state, the refresh, the notices, the watcher, the context line, the dev side's start) to vid-connect,
# the answers' (a question, a finding, the compaction question, the owner's queue and delegation) to vid-answer; the run skill holds
# none of them, and the other skill none either. vid-connect holds its two lists: the connect for every caller and the run's start
# for /vid run alone (`--run`), `--state`, the refresh's no as `connect.sh refresh-no` (no `run: stopped checks/ needs the refresh`
# in either skill), GM M15's state-repo refusal, and no caller mark. GM-4 4b: the run also loads vid-tickets, vid-replan, vid-triggers
# and vid-spec-publish at its start; its re-plan step invokes vid-triggers and re-plans through vid-replan (K9); its never-push names
# vid-spec-publish's one request as the exception (K13), a verb taking the owner's words, run after the export, with layout: one alone,
# pushing nothing from this machine, listed by vid-help. GM-4 4c (K2, K3, F14): the run also loads vid-accept-step and vid-step-close at
# its start, names each in one row where it calls it (the decision, merge, decisions, held, closed-outside, split rows; the close's
# rows and regression), and holds none of their lines (the weak test's lesson among vid-accept-step's, FB-1 C2: the row of the round's
# `weak` line in its "In both modes" table), each line in one skill alone;
# both are verbs (`/vid:vid-accept-step <ticket> [<commit>]` through `round.sh accept`, `/vid:vid-step-close <step>` through
# `close.sh step`), listed by vid-help, each with its GitHub manual paragraph naming its ruling (GM M8; GM M3 for the close), GitHub
# auto's entry `round.sh step`, E6's line said with both of K1's commands; vid-spec-publish says the owner's words back. GM-4 4d (K4,
# K5, K8, K10 finished, F14): the run loads every skill K10 names at its start (vid-stage-close, vid-deploy and vid-grade too); vid-stage-close
# is a verb listed by vid-help, giving `close.sh stage <N>`, its walk, read-walk and summary actions and `end.sh complete`, with a GitHub
# manual paragraph naming GM M16 (no call waits for the walker), D4 and the end with no `run: complete`; vid-deploy refuses in no GitHub mode, its GitHub
# section giving `/vid:vid-deploy staging`, `/vid:vid-deploy production "<words>"`, the later work's duty (E9) and no hold (D4); vid-grade's
# ticket-mode branch runs outside /vid run too, its report read at the next /vid next call in GitHub manual; vid-help lists vid-deploy and
# vid-grade as the GitHub modes'. Every row of the run's line table names one skill at most, and a row naming none is one K10 keeps as
# the run's order; the stage's, the okays' and the grade ask's lines are each in one skill alone, none in the run skill. FB-2 A3: the
# table's `flag ticket-left <n>: <why>` row tells the owner the left ticket and /vid:vid-tickets reopen, the way back.
# FB-2 A2: "Before any work" holds the plan first, before the run's start: without --state, when .vid/plan/ratified holds no
# ratified line, the vid-plan skill's sitting, its turn ended at the page for the owner's words, nothing published and no lock held,
# a team of people sent to /vid:vid-next through the vid-mode skill; vid-plan's hand back sends either caller on at its own start.
# Reads skills/: skipped in a project's layout. Env: CHECKS.
set -eu
S=$CHECKS/../skills; [ -d "$S/vid-run" ] || { echo 'run-skill-text: no skills/ beside checks/ (a project layout)'; exit 77; }
fail() { echo "run-skill-text: $*" >&2; exit 1; }
T0=$(mktemp); trap 'rm -f "$T0"' EXIT
R=$S/vid-run/SKILL.md; C=$S/vid-connect/SKILL.md; A=$S/vid-answer/SKILL.md
[ -f "$C" ] || fail 'there is no vid-connect skill'; [ -f "$A" ] || fail 'there is no vid-answer skill'
# the start: both skills loaded, before the loop; the run's start one line, naming vid-connect
B=$(awk '/^## Before any work/ { on = 1; next } on && /^## / { exit } on' "$R")
printf '%s\n' "$B" | grep -i 'invoke' | grep -q '`vid-connect`' && printf '%s\n' "$B" | grep -i 'invoke' | grep -q '`vid-answer`' || fail 'the run skill does not load vid-connect and vid-answer at its start'
# GM-4 §5 4a: the round's read is vid-read's, loaded at the start, named in one line where the round reads
printf '%s\n' "$B" | grep -i 'invoke' | grep -q '`vid-read`' || fail 'the run skill does not load vid-read at its start'
grep -v -i 'invoke the' "$R" | grep -F 'vid-read' > "$T0" || fail 'the run skill names vid-read nowhere it reads'
[ "$(grep -c . "$T0")" = 1 ] && grep -q 'round\.sh' "$T0" || fail "the round's read is not one line naming vid-read: $(cat "$T0")"
[ "$(printf '%s\n' "$B" | grep -c 'connect.sh" start --run')" = 1 ] || fail 'the run skill does not run the run'"'"'s start once, through connect.sh start --run'
printf '%s\n' "$B" | grep 'connect.sh" start --run' | grep -q 'vid-connect' || fail 'the run skill'"'"'s start line does not name vid-connect'
# FB-2 A2: the plan, first — before the run's start, not with --state, when .vid/plan/ratified holds no ratified line (never
# ratified), the vid-plan skill's sitting, its turn ended at the page for the owner's words, nothing published and no lock held;
# a team of people is the sitting's GitHub manual route (the vid-mode skill), then /vid:vid-next drives the project
P=$(printf '%s\n' "$B" | grep '^\*\*The plan, first' || true); [ "$(printf '%s\n' "$P" | grep -c .)" = 1 ] || fail 'the run skill has no one plan-first step in "Before any work"'
pl=$(printf '%s\n' "$B" | grep -n '^\*\*The plan, first' | cut -d: -f1); sl=$(printf '%s\n' "$B" | grep -n 'connect.sh" start --run' | cut -d: -f1)
[ "$pl" -lt "$sl" ] || fail "the plan-first step does not come before the run's start"
for p in 'invoke the `vid-plan` skill' '`.vid/plan/ratified`' 'no `ratified` line' 'without `--state`' 'end the turn' "the owner's words" 'nothing is published' 'no lock is held' 'the `vid-mode` skill' '`/vid:vid-next`' 'never'; do
  printf '%s\n' "$P" | grep -qiF -- "$p" || fail "the plan-first step does not say: $p"; done
# and vid-plan's hand back: called from /vid run or /vid next, the caller goes on at its own start
HB=$S/vid-plan/SKILL.md; if [ -f "$HB" ]; then awk '/^## Hand back/ { on = 1; next } on && /^## / { exit } on' "$HB" | tr '\n' ' ' > "$T0"
  grep -qF '/vid run' "$T0" && grep -qF '/vid next' "$T0" && grep -qF 'goes on at its own start' "$T0" || fail "vid-plan's hand back does not send /vid run and /vid next on at their own start"; fi
# the answers: one line each naming vid-answer
for p in '| `question <n> <k>` |' '| `finding <ticket> <severity> <words>` |' '| `context-window Q<m>`'; do
  [ "$(grep -cF -- "$p" "$R")" = 1 ] || fail "the run skill has no one row $p"
  grep -F -- "$p" "$R" | grep -q 'vid-answer' || fail "the run skill's row $p does not name vid-answer"; done
grep '^\*\*The owner.s queue' "$R" | grep -q 'vid-answer' || fail 'the run skill'"'"'s owner'"'"'s queue line does not name vid-answer'
# each moved line goes to one skill: <phrase> <the skill that holds it> <the other one>
once() { ! grep -qF -- "$1" "$R" || fail "the run skill still holds: $1"
  grep -qF -- "$1" "$2" || fail "$(basename "$(dirname "$2")") does not hold: $1"; ! grep -qF -- "$1" "$3" || fail "$(basename "$(dirname "$3")") holds it too: $1"; }
once 'this project is in GitHub manual: call /vid next' "$C" "$A"
once 'give DevAgent read access' "$C" "$A"
once 'This project was planned by the old ticket mode; re-plan it with /vid plan.' "$C" "$A"
once 'does nothing to one that is current' "$C" "$A"
once '`run:` belongs to the session that holds the lock' "$C" "$A"
once 'stage name=run state=start' "$C" "$A"
once 'A recorded pause, `run: stopped owner asked to pause`, stays' "$C" "$A"
once 'lib/wsl.sh" notice' "$C" "$A"
once 'observe.sh alive' "$C" "$A"
once 'brief.sh context' "$C" "$A"
once "Show the owner devagent-start.sh's output as it is" "$C" "$A"
once 'never write the note, and never wait for the dev side' "$C" "$A"
once 'queue.sh ask <n>:<k>' "$A" "$C"
once 'A high one, or one whose words say the spec contradicts itself' "$A" "$C"
once 'autoCompactWindow' "$A" "$C"
once 'compaction point to 300,000 tokens' "$A" "$C"
once "The recommendation's rule" "$A" "$C"
once '`a` accept, `b <N>` more rounds, `c` a known limit, `d` amend' "$A" "$C"
once 'queue.sh answer Q<n> --by delegate' "$A" "$C"
once "Under delegation the owner's alone stays refused" "$A" "$C"
for p in 'refresh.sh"' 'devagent-start.sh' 'lock-take' 'state-restore' 'observe.sh start'; do ! grep -qF -- "$p" "$R" || fail "the run skill still holds the start's $p"; done
# the refresh's no: one record, the connect's
! grep -qF 'run: stopped checks/ needs the refresh' "$R" "$C" || fail "the run's start still records the refresh's no as run: stopped checks/ needs the refresh"
grep -qF 'connect.sh" refresh-no' "$C" || fail 'vid-connect does not record the refresh'"'"'s no through connect.sh refresh-no'
# vid-connect's two lists
grep -q '^## The connect, for every caller' "$C" && grep -q "^## The run's start, /vid run's alone" "$C" || fail 'vid-connect does not hold its two lists'
grep -qF -- '--state <owner/name>' "$C" && grep -qF 'state-repo:' "$C" && grep -qF 'GM M15' "$C" || fail 'vid-connect lacks --state or the state-repo refusal'
grep -- '--run' "$C" | head -n 1 | grep -q '/vid run' || fail 'vid-connect does not give --run as /vid run'"'"'s alone'
! grep -q 'VID_CALLER' "$C" || fail 'vid-connect still names a caller mark'
! grep -q 'written so /vid run can' "$C" || fail 'vid-connect still says /vid run may invoke it some day'
# GM-4 4b (K1, K7, K9, K13): the run loads vid-tickets, vid-replan, vid-triggers and vid-spec-publish at its start
for k in vid-tickets vid-replan vid-triggers vid-spec-publish; do printf '%s\n' "$B" | grep -i 'invoke' | grep -q "\`$k\`" || fail "the run skill does not load $k at its start"; done
# K9: after a step that printed something new, the re-plan step invokes vid-triggers and re-plans through vid-replan
grep '^3\. \*\*Re-plan\*\*' "$R" | grep -q 'Invoke the `vid-triggers` skill' && grep '^3\. \*\*Re-plan\*\*' "$R" | grep -q '`vid-replan`' || fail "the run skill's re-plan step does not invoke vid-triggers and re-plan through vid-replan"
# K13: never a push to the code repository, the vid-spec-publish skill's one request to GitHub its one exception
grep '^\*\*You never:\*\*' "$R" | grep -qF 'push to the code repository' && grep '^\*\*You never:\*\*' "$R" | grep -qF 'vid-spec-publish' || fail "the run skill's never-push does not name the vid-spec-publish skill's request as its one exception"
P=$S/vid-spec-publish/SKILL.md; [ -f "$P" ] || fail 'there is no vid-spec-publish skill'
awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$P" > "$T0"; ! grep -q '^user-invocable: false' "$T0" && ! grep -qiE '^description: *"?Internal|not a verb' "$T0" || fail 'vid-spec-publish is not a verb'
for f in '/vid:vid-spec-publish "<words>"' 'sh checks/github.sh spec-publish' 'sh checks/github.sh spec-export' 'layout: one' 'spec-path:' 'spec-stamp:' 'pushes nothing from this machine'; do grep -qF -- "$f" "$P" || fail "vid-spec-publish lacks: $f"; done
grep -q '^| \*\*/vid:vid-spec-publish\*\* |' "$S/vid-help/SKILL.md" || fail 'vid-help does not list /vid:vid-spec-publish'
# GM-4 4c (K2, K3, F14): vid-accept-step and vid-step-close loaded at the start, verbs, listed by vid-help
K2=$S/vid-accept-step/SKILL.md; K3=$S/vid-step-close/SKILL.md; [ -f "$K2" ] || fail 'there is no vid-accept-step skill'; [ -f "$K3" ] || fail 'there is no vid-step-close skill'
for k in vid-accept-step vid-step-close; do printf '%s\n' "$B" | grep -i 'invoke' | grep -q "\`$k\`" || fail "the run skill does not load $k at its start"
  awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$S/$k/SKILL.md" > "$T0"; ! grep -q '^user-invocable: false' "$T0" && ! grep -qiE '^description: *"?Internal|not a verb' "$T0" || fail "$k is not a verb"
  grep -q "^| \*\*/vid:$k\*\* |" "$S/vid-help/SKILL.md" || fail "vid-help does not list /vid:$k"; done
grep -qF '/vid:vid-accept-step <ticket> [<commit>]' "$K2" && grep -qF 'sh checks/round.sh accept <ticket> [<commit>]' "$K2" || fail "vid-accept-step does not give its command and its entry, round.sh accept"
grep -qF '/vid:vid-step-close <step>' "$K3" && grep -qF 'sh checks/close.sh step <step>' "$K3" || fail "vid-step-close does not give its command and its entry, close.sh step"
grep -q '^## GitHub manual' "$K2" && awk '/^## GitHub manual/ { on = 1; next } on && /^## / { exit } on' "$K2" | grep -q 'GM M8' || fail "vid-accept-step has no GitHub manual paragraph naming GM M8"
awk '/^## GitHub manual/ { on = 1; next } on && /^## / { exit } on' "$K3" > "$T0"; grep -q 'GM M8' "$T0" && grep -q 'GM M3' "$T0" || fail "vid-step-close has no GitHub manual paragraph naming GM M8 and GM M3"
grep -q '^## GitHub auto' "$K2" && awk '/^## GitHub auto/ { on = 1; next } on && /^## / { exit } on' "$K2" | grep -qF 'round.sh step' || fail "vid-accept-step does not give GitHub auto's entry, round.sh step"
grep -F '`context closed #<n> <words>`' "$K2" | grep -qF '/vid:vid-tickets reopen #<n>' && grep -F '`context closed #<n> <words>`' "$K2" | grep -qF '/vid:vid-tickets withdraw #<n>' || fail "vid-accept-step does not say E6's line with both of K1's commands"
# the rows that call them: one row each naming the skill; their lines held by the skill alone, never by the run skill
grep -F '| `decided <p> <head> ticket: …`' "$R" | grep -q '`vid-accept-step`\|vid-accept-step skill' || fail "the run skill's decision row does not name vid-accept-step"
grep -F '| `close <step>`' "$R" | grep -q 'vid-step-close skill' || fail "the run skill's close row does not name vid-step-close"
for p in '`merged <p>`' '`held <row>`' '`closed-outside <n> <step>`' '`closed-stage-rows <s> <N>`' '`step-reopened <s> #<n>`' '`split <row>`' '`decisions recorded pr=<p>'; do grep -F -- "$p" "$R" | grep -q 'vid-accept-step skill' || fail "the run skill names $p without the vid-accept-step skill"; done
for p in '`asked <n> close <step>`' '`closed <step>`' '`close-again <step> <chunk>`' '`close-twice <step> <row>`' '`close-shrink <step> <rows>`' '`close-numbers <step> <k> …`' '`regression <close> <n>`'; do grep -F -- "$p" "$R" | grep -q 'vid-step-close skill' || fail "the run skill names $p without the vid-step-close skill"; done
once 'A `not yet` is DevAgent' "$K2" "$K3"
once "Read the merged pull request's text, as a re-plan needs" "$K2" "$K3"
once 'marked `origin: dev-side`' "$K2" "$K3"
once 'a draft waits on the owner, so the round records no decision' "$K2" "$K3"
once "The hooks refused the dev side's lines" "$K2" "$K3"
once 'DevAgent adds the section and asks again at the same head' "$K2" "$K3"
once 'queue.sh recommend Q<n> <letter>' "$K2" "$K3"
once 'was closed on GitHub without its merge' "$K2" "$K3"
once 'any of its rows still open go out again in a new ticket' "$K2" "$K3"
once 'its close is asked again once that ticket merges' "$K2" "$K3"
once 'every engine is now asked' "$K2" "$K3"
once 'queue.sh lesson <rows, comma-joined>' "$K2" "$K3"
once 'Nothing: `next` asks for the close run' "$K3" "$K2"
once 'Nothing: DevAgent runs the chunks' "$K3" "$K2"
once 'the step closed on a run in every engine' "$K3" "$K2"
once "relay the line as it stands" "$K3" "$K2"
once "a close's red rows read failing and go in one fix line" "$K3" "$K2"
once 'the row failed again after its fix' "$K3" "$K2"
once 'the fix loop has not shrunk' "$K3" "$K2"
once 'regressions introduced, defects still open, rows fixed' "$K3" "$K2"
once 'that close introduced `<n>` regressions' "$K3" "$K2"
# the lesson's line named in the run skill, the rule gone
grep -F 'failing, a weak test' "$R" | grep -q 'vid-accept-step' || fail "the run skill's weak-test line does not name vid-accept-step"
# FB-1 C2: the round's `weak` line a row of vid-accept-step's "In both modes" table, the lesson run from it; no paragraph of its own
awk '/^## In both modes/ { on = 1; next } on && /^## / { exit } on' "$K2" | grep -F '| `weak <rows> <#n or pull request> <head 12> — <the row'"'"'s text>` |' | grep -qF 'queue.sh lesson <rows, comma-joined>' || fail "vid-accept-step's table has no weak row running queue.sh lesson"
! grep -qF "**A weak test's lesson.**" "$K2" || fail "vid-accept-step still holds the weak test's lesson as a paragraph of its own"
# the open item from 4b: the owner's words to a spec publish are said back (the log line keeps none)
grep -qF 'said back' "$P" || fail "vid-spec-publish does not say the owner's words back"
# GM-4 4d (K10): every skill K10 names loaded at the start, and again when a session takes over
for k in vid-connect vid-tickets vid-accept-step vid-step-close vid-stage-close vid-deploy vid-answer vid-replan vid-triggers vid-grade vid-spec-publish; do
  printf '%s\n' "$B" | grep -i 'invoke' | grep -q "\`$k\`" || fail "the run skill does not load $k at its start"; done
printf '%s\n' "$B" | grep -i 'invoke' | grep -qi 'whenever a session takes over' || fail 'the run skill does not load its skills again when a session takes over'
# K4: vid-stage-close, a verb, its commands and entries, its GitHub manual paragraph
K4=$S/vid-stage-close/SKILL.md; K5=$S/vid-deploy/SKILL.md; K8=$S/vid-grade/SKILL.md; H=$S/vid-help/SKILL.md
[ -f "$K4" ] || fail 'there is no vid-stage-close skill'
awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$K4" > "$T0"; ! grep -q '^user-invocable: false' "$T0" && ! grep -qiE '^description: *"?Internal|not a verb' "$T0" || fail 'vid-stage-close is not a verb'
grep -q '^| \*\*/vid:vid-stage-close\*\* |' "$H" || fail 'vid-help does not list /vid:vid-stage-close'
for f in '/vid:vid-stage-close <stage>' 'sh checks/close.sh stage <N>' 'sh checks/close.sh walk <N>' 'sh checks/close.sh read-walk <N>' 'sh checks/close.sh summary <N>' '/vid:vid-stage-close end' 'sh checks/end.sh complete'; do
  grep -qF -- "$f" "$K4" || fail "vid-stage-close lacks: $f"; done
awk '/^## GitHub manual/ { on = 1; next } on && /^## / { exit } on' "$K4" > "$T0"; for f in 'GM M16' 'D4' 'walk.sh start' 'no call waits' '`walk-stage <N>`' '`read-walk <N>`' '`write-summary <N>`' '`run: complete`'; do
  grep -qF -- "$f" "$T0" || fail "vid-stage-close's GitHub manual paragraph lacks: $f"; done
# K5: vid-deploy refuses in no GitHub mode; its GitHub section
! grep -qiF 'this verb refuses' "$K5" || fail 'vid-deploy still refuses in the GitHub modes'
grep -q '^## In the GitHub modes' "$K5" || fail 'vid-deploy has no GitHub section'
awk '/^## In the GitHub modes/ { on = 1; next } on && /^## / { exit } on' "$K5" > "$T0"; for f in '/vid:vid-deploy staging' '/vid:vid-deploy production "<words>"' 'later-work-off: the work listed below is off for the people using the product' 'E9' 'D4' 'GM M14' 'production-yes-asked'; do
  grep -qF -- "$f" "$T0" || fail "vid-deploy's GitHub section lacks: $f"; done
grep -qiF 'no hold' "$T0" || fail "vid-deploy's GitHub section does not say no hold is written in GitHub manual"
grep -qF '/vid:vid-deploy staging' "$H" && grep -qF '/vid:vid-deploy production' "$H" || fail "vid-help's vid-deploy row does not give its GitHub modes' commands"
# K8: vid-grade's ticket-mode branch outside /vid run's session, read at the next call in GitHub manual
G8=$(awk '/^## In ticket mode/ { on = 1; next } on && /^## / { exit } on' "$K8")
! printf '%s\n' "$G8" | grep -qF "inside \`/vid run\`'s" || fail "vid-grade's ticket-mode branch still runs inside /vid run's session alone"
printf '%s\n' "$G8" | grep -F 'GitHub manual' | grep -qF '/vid next' || fail "vid-grade's ticket-mode branch does not read the report at the next /vid next call in GitHub manual"
grep '^| \*\*/vid:vid-grade\*\* |' "$H" | grep -qF 'GitHub modes' || fail "vid-help's vid-grade row does not say it works in the GitHub modes"
# the rows that call them, one row each; their lines held by the skill alone
for p in '`stage <N>`' '`stage-c3 <N> passed`' '`walk <N>`' '`walk-read <N>`' '`stage:<N>:…`' '`close-stage <N>`' '`stage-closed <N> at <commit12>`' '"hold after this stage"' '| `nothing-left` |'; do
  grep -F -- "$p" "$R" | grep -q 'vid-stage-close skill' || fail "the run skill names $p without the vid-stage-close skill"; done
for p in '`okay staging <N>`' '`d1 <N> passed`' '`door d1-failed <N>' '`door differs <N>' '`cs <N>`' '`stand-in <N> <row>' '`hold <N> Q<m>`' '"use production data on staging"' '`okay rehearsal <N>`' '`production-yes-asked <N> <c>`' '`logs <N>: …`' '`production-duty <N>' '`cs-closed #<n>`' '`recovery-asked <N> #<n>`' '`in production <N> at <commit>`'; do
  grep -F -- "$p" "$R" | grep -q 'vid-deploy skill' || fail "the run skill names $p without the vid-deploy skill"; done
grep -F '`grade-ask <n> read <k>: …`' "$R" | grep -q 'vid-grade skill' || fail "the run skill names the grade ask's lines without the vid-grade skill"
grep '^\*\*The owner.s `/vid grade`' "$R" | grep -q 'vid-grade skill' || fail "the run skill's owner's grade line does not name vid-grade"
once "the round names the stage's candidate, main's newest merge" "$K4" "$K5"
once 'Say a green C3 and the grades once' "$K4" "$K5"
once 'walk.sh brief --stage <N>' "$K4" "$K5"
once 'walk.sh read --stage <N>' "$K4" "$K5"
once 'queue.sh answer Q<n> close without the walk' "$K4" "$K5"
once '`later <M>` (a later stage, which asks it again there)' "$K4" "$K5"
once 'in plain product words with no row ids' "$K4" "$K5"
once "A hold's stop stops only the next stage" "$K4" "$K5"
once 'queue.sh control hold "<their words>"' "$K4" "$K5"
once 'computes completion from the records' "$K4" "$K5"
once 'once a candidate'"'"'s C3 has passed, and staging holds no other candidate' "$K5" "$K4"
once 'test site:` line of `sh checks/queue.sh addresses <N>`' "$K5" "$K4"
once 'staging-owed row whose fail-if is that failure' "$K5" "$K4"
once 'production has <what> as <value>' "$K5" "$K4"
once 'the staging run of the golden path and the seam and staging-owed rows' "$K5" "$K4"
once 'CS passed an outside-service row the passed D1 did not mark real' "$K5" "$K4"
once 'Stage <N+1> waits until staging has passed once. Say continue to build on.' "$K5" "$K4"
once 'queue.sh control seed production\|synthetic' "$K5" "$K4"
once "The production yes is the owner's alone" "$K5" "$K4"
once "where production's logs are read" "$K5" "$K4"
once 'A passed production deploy is never sent back for its duties' "$K5" "$K4"
once 'so DevAgent may take the staging down' "$K5" "$K4"
once 'DevAgent recovers and comments `vid: recovered`' "$K5" "$K4"
once 'live copy:` line of `sh checks/queue.sh addresses <N>`' "$K5" "$K4"
once "a \`vs\` line is a passing requirement's grade at the second commit" "$K8" "$K4"
once 'An ask out keeps the session from ending at `nothing-left`' "$K8" "$K4"
for p in 'walk.sh' 'end.sh' 'grade.sh' 'control seed' 'control hold' 'queue.sh addresses' 'land.sh draft' 'close.sh okay'; do ! grep -qF -- "$p" "$R" || fail "the run skill still holds the rule of: $p"; done
# K10: each row of the run's line table names one skill at most; a row naming none is one K10 keeps as the run's order
awk '/^\| Line \| What you do \|/ { on = 1; next } on && !/^\|/ { exit } on && !/^\|---/' "$R" > "$T0"
while IFS= read -r l; do w=${l#| }; c1=${w%% | *}; c2=${w#* | }
  n=$(printf '%s\n' "$c2" | grep -oE '(^|[^:/])vid-[a-z-]+ skill' | sed 's/^[^v]*//' | sort -u | grep -c . || true)
  [ "$n" -le 1 ] || fail "a row of the run's table names two skills: $c1"
  if [ "$n" = 0 ]; then case $c1 in '`main-changed`'*|'`update`'|'`flag devagent-quiet <n>`'*|'`flag devagent-stopped <id>: <why>`'*|'`flag ticket-left <n>: <why>`'*|'`flag <word> <what>`'|'`error <step> …`'|'`lock-lost`'|'`stop <why>`'|'`idle`') ;;
    *) fail "a row of the run's table names no skill and is not one the run keeps: $c1" ;; esac; fi; done < "$T0"
# FB-2 A3: the row that tells the owner a ticket DevAgent left, and its way back
grep -q '^| `flag ticket-left <n>: <why>` (FB-2 A3) | Tell the owner once, in one line: `DevAgent left ticket #<n>: <why>\. When what it needs is in place, /vid:vid-tickets reopen #<n> "<your words>" has it taken up again\.` It stops nothing |' "$R" || fail "the run skill's table has no ticket-left row"
# review fixes (4d): a nothing-left before the final close is the waiting stop, never the genuine block (the setup hold's bare
# continue reads run: waiting); the summary is written in GitHub manual only through the owner's write-summary move
grep -F -- '- **Everything left waits on the owner' "$R" | grep -qF 'a `nothing-left` before the final close' || fail "the run skill's waiting stop does not take a nothing-left before the final close"
! grep -F -- '- **A genuine block' "$R" | grep -qF 'nothing-left' || fail "the run skill's genuine-block stop takes a nothing-left"
grep -F '| `close-stage <N>`, `summary <N>`' "$K4" | grep -qF "In GitHub manual, only through the owner's move \`write-summary\`" || fail "vid-stage-close's summary row writes the summary in GitHub manual without the owner's move"
echo 'run-skill-text: ok'
