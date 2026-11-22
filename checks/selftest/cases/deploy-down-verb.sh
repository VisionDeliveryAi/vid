#!/bin/sh
# Purpose: selftest case — FB-2 A4: /vid:vid-deploy down in the GitHub modes, checks/close.sh deploy down, on the writer's toy and the
# fake gh, in each GitHub mode. `down staging` with no words, or blank ones, is refused, the owner's own words required; with words
# and no passed D1, refused, nothing up, nothing posted; with stage 1's D1 passed and its staging run not done, refused, staging
# taken, naming the run; its run done and its walk not, naming the walk; with its run and walk done and the site up, posted: an issue
# labelled deploy whose body begins `okay: down staging`, its `commit:` the candidate's and its `address:` the test site's, `asked <n>
# down staging`. While it is unread it holds staging: stage 2's staging okay, owed before it, is owed no more, and a second `down
# staging` is refused naming it, and so is `deploy staging 2`, `staging is taken: its take-down, #<n>, is not reported yet`. Once it
# is read, stage 2's okay posted and not reported refuses `down staging`, naming it, and once started, naming it started; that okay
# lost, the take-down posts. `down production` with no words is refused; with words and nothing in production, nothing up; with a
# production okay whose production run is not done, refused, naming it; with a live copy that is not on this machine, refused; then
# posted, its body beginning `okay: down production`, and a second one refused while it is unread. Nothing posted at a refusal. Where
# skills/ sits beside checks/: vid-deploy names both commands, develop's section "Taking the test site down" with its `deploy-down
# target=staging at=<commit>` event, and the two lines of its table. The guard: only close.sh's deploy entry calls the take-down, and no other script, nor any skill but
# vid-deploy, takes a site down. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/auto-t; mkdir -p "$T"; MO=auto
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "deploy-down-verb: $MO: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; TAB=$(printf '\t')
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
nis() { ls "$T/gh/issues" 2>/dev/null | grep -c . || true; }
refd() { n0=$(nis); cs deploy down "$@"; [ "$RC" = 1 ] || fail "deploy down $1 exited $RC, not refused"; [ "$(nis)" = "$n0" ] || fail "a refused take-down posted: $(cat "$T/out")"; }
run() { MO=$1; tw_toy "$T/toy"; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
  tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
  if [ "$MO" = manual ]; then printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
    printf 'state-repo: owner/vid-state\n' >> .vid/tw/settings; gh repo create owner/vid-state --private > /dev/null 2>&1 || true; fi
  CLAUDE_CODE_SESSION_ID=dd; export CLAUDE_CODE_SESSION_ID; sh "$GS" lock-take dd > "$T/out" 2>&1 || fail 'the lock could not be taken'
  X=$(git --git-dir="$T/code.git" rev-parse main); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs" "$F/w1"
  printf 'issue\t90\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"; : > "$F/named"; : > "$F/passed"; : > "$F/done"
  tw_hand "candidate 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
  # nothing up
  # FB-2 A4: the owner's own words, required: none, or blank, refused before anything else
  refd staging; ok "^refused down staging: the take-down of the test site is asked only with the owner's own words, as deploy down staging \"<words>\"$"
  refd staging '  '; ok "^refused down staging: the take-down of the test site is asked only with the owner's own words"
  refd staging 'Take the test site down'; ok '^refused down staging: nothing is up: no staging deploy has passed$'
  # D1 passed, its staging run not done: staging taken
  printf 'issue\t91\ncommit\t%s\nasked\t2026-11-09T12:00:00Z\n' "$X" > "$F/d1/ask"; : > "$F/d1/passed"; printf 'd1\tpassed\t1\nstaging\thttp://127.0.0.1:5001\nstays\tup\n' > "$F/d1/read"
  printf 'issue\t92\n' > "$F/cs/ask"
  refd staging 'Take the test site down'; ok "^refused down staging: staging is taken: stage 1's candidate 1's staging run, CS, is not done$"
  # its run and walk done, the site up: posted; stage 2's okay owed before it, not while it is unread
  # FB-2 A4: its run passed and done, its walk not done: staging taken, naming the walk
  : > "$F/cs/passed"; : > "$F/cs/done"; refd staging 'Take the test site down'; ok "^refused down staging: staging is taken: stage 1's candidate 1's walk is not done$"
  : > "$F/w1/done"
  G=.vid/decide/stage/2/1; mkdir -p "$G"; printf 'issue\t93\ncommit\t%s\nasked\t2026-11-10T11:00:00Z\n' "$X" > "$G/ask"; echo "$X" > "$G/commit"; : > "$G/named"; : > "$G/passed"; : > "$G/done"
  tw_hand "candidate 2 | stand-in: RM at $(printf %.12s "$X") candidate 1"
  cs owed; grep -q '^okay staging 2$' "$T/out" || fail "stage 2's staging okay is not owed before the take-down: $(cat "$T/out")"
  cs deploy down staging 'Take the test site down'; [ "$RC" = 0 ] || fail "the take-down of the test site exited $RC"; ok '^asked [0-9]* down staging$'; I=$(sed -n 's/^asked \([0-9]*\) down staging$/\1/p' "$T/out")
  B=$T/gh/issues/$I; [ "$(sed -n 1p "$B/body")" = 'okay: down staging' ] && grep -qx "commit: $X" "$B/body" && grep -qx 'address: http://127.0.0.1:5001' "$B/body" || fail "the take-down's body: $(cat "$B/body")"
  grep -qx deploy "$B/labels" || fail 'the take-down is not labelled deploy'; grep -q "^asked $I deploy stage=1 " .vid/tw/log || fail 'the take-down is not logged as asked'
  # FB-2 A4: the owner's words kept in the ask and on its event, never in the body the dev side reads
  grep -qx "words${TAB}Take the test site down" "$F/dn-staging/ask" || fail "the take-down's ask does not keep the words given ($(cat "$F/dn-staging/ask"))"
  grep -q "^stage-okay stage=1 candidate=1 issue=$I commit=$X kind=dn words=\"Take the test site down\"" .vid/metrics-events || fail "the take-down's event does not carry the words given ($(grep 'kind=dn' .vid/metrics-events))"
  ! grep -q 'Take the test site down' "$B/body" || fail "the owner's words are in the take-down body the dev side reads"
  cs owed; ! grep -q '^okay staging' "$T/out" || fail 'a staging okay is owed while a take-down is unread'
  refd staging 'Take the test site down'; ok "^refused down staging: staging is taken: its take-down, #$I, is not reported yet$"
  # FB-2 A4: the staging okay of stage 2, owed, is refused while the take-down is unread, okwhy naming what holds staging
  n0=$(nis); cs deploy staging 2; [ "$RC" = 1 ] || fail "deploy staging 2 exited $RC while the take-down is unread"; [ "$(nis)" = "$n0" ] || fail 'a staging okay was posted while the take-down is unread'
  ok "^refused staging: stage 2: staging is taken: its take-down, #$I, is not reported yet$"
  # production
  refd production; ok "^refused down production: the take-down of the live copy is asked only with the owner's own words"
  refd production 'Take the practice copy down'; ok '^refused down production: nothing is up: no production deploy has run$'
  mkdir -p "$F/d2" "$F/cp"; H=$(gh issue create -R $R --title 'Production' --body b --label deploy | sed 's#.*/##'); printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-10T12:00:00Z\n' "$H" "$X" > "$F/d2/ask"; : > "$F/d2/passed"
  printf 'd2\tpassed\t1\nproduction\thttps://shop.example.invalid\n' > "$F/d2/read"; printf '%s\tD2 #%s\t2026-11-10T12:30:00Z\n' "$X" "$H" > .vid/decide/production
  refd production 'Take the practice copy down'; ok "^refused down production: a production okay is in hand: the production okay #$H: its report, or its production run, CP, is not done$"
  : > "$F/cp/passed"
  refd production 'Take the practice copy down'; ok '^refused down production: the live copy at https://shop.example.invalid is not a copy on this machine'
  printf 'd2\tpassed\t1\nproduction\thttp://127.0.0.1:5201\n' > "$F/d2/read"
  cs deploy down production 'Take the practice copy down'; [ "$RC" = 0 ] || fail "the take-down of the live copy exited $RC"; ok '^asked [0-9]* down production$'; J=$(sed -n 's/^asked \([0-9]*\) down production$/\1/p' "$T/out")
  B=$T/gh/issues/$J; [ "$(sed -n 1p "$B/body")" = 'okay: down production' ] && grep -qx "commit: $X" "$B/body" && grep -qx 'address: http://127.0.0.1:5201' "$B/body" || fail "the live copy's take-down body: $(cat "$B/body")"
  ! grep -q 'Take the practice copy down' "$B/body" || fail "the owner's words are in the body the dev side reads"
  refd production 'Again'; ok "^refused down production: a production okay is in hand: its take-down, #$J, is not reported yet$"
  # FB-2 A4: the take-down of the test site read (planted done), stage 2's staging okay posted and not reported: down staging refused
  : > "$F/dn-staging/done"; cs deploy staging 2; [ "$RC" = 0 ] || fail "stage 2's staging okay exited $RC"; K=$(sed -n "s/^issue$TAB//p" "$G/d1/ask"); [ -n "$K" ] || fail "stage 2's staging okay was not posted"
  refd staging 'Take the test site down'; ok "^refused down staging: staging is taken: the staging okay #$K is posted and not reported yet$"
  # started (a `vid: started` comment in the round's read) and not reported: staging taken, naming it started
  printf 'vid: started\nby: DP\n' > "$T/c"; gh issue comment "$K" -R $R --body-file "$T/c" > /dev/null; sh "$GS" round-read > .vid/round/read 2>/dev/null || fail 'the round read failed'
  refd staging 'Take the test site down'; ok "^refused down staging: staging is taken: the staging okay #$K is started and not reported yet$"
  # once that okay is lost, it holds no more: the take-down posts
  printf 'lost d1 #%s\n' "$((K * 1000 + 1))" > "$G/d1/items"; cs deploy down staging 'Take the test site down'; [ "$RC" = 0 ] && ok '^asked [0-9]* down staging$' || fail "the take-down after the lost okay exited $RC"; }
run auto
T=$T0/manual-t; mkdir -p "$T"; run manual
# FB-2 A4, the guard: only the owner's command takes a site down. In checks/, close.sh's deploy entry alone calls cmd_down, cmd_down
# alone calls dnpost, and dnpost alone writes a take-down's body; no script of checks/ or devagent/ runs close.sh's deploy down; and of
# the skills, vid-deploy alone names it. Comment lines are not calls
code() { p=$1; shift; grep -n -- "$p" "$@" 2>/dev/null | grep -v '^[^:]*:[0-9]*:[[:space:]]*#' || true; }
MO=guard; cd "$CHECKS"; CD=$(code 'cmd_down' ./*.sh | grep -v 'cmd_down() {' || true)
[ "$(printf '%s\n' "$CD" | grep -c .)" = 1 ] && printf '%s\n' "$CD" | grep -q '^\./close\.sh:[0-9]*:  down) shift; cmd_down "\$@" ;;' || fail "cmd_down is called elsewhere than close.sh's deploy entry: $CD"
CE=$(code 'cmd_deploy' ./close*.sh | grep -v 'cmd_deploy() {' || true); [ "$(printf '%s\n' "$CE" | grep -c .)" = 1 ] && printf '%s\n' "$CE" | grep -q '^\./close\.sh:[0-9]*:  deploy) cmd_deploy "\$@" ;;' || fail "close.sh's cmd_deploy is called elsewhere than its deploy entry: $CE"
DN=$(code 'dnpost' ./*.sh | grep -v 'dnpost() {' || true); IN=$(awk '/^cmd_down\(\) \{/ { on = 1 } on && /dnpost/ { n++ } on && /esac; }$/ { exit } END { print n + 0 }' ./close-production.sh)
[ "$(printf '%s\n' "$DN" | grep -c .)" = 2 ] && [ "$IN" = 2 ] || fail "dnpost is called outside cmd_down: $DN"
OD=$(code 'okay: down' ./*.sh); [ "$(printf '%s\n' "$OD" | grep -c .)" = 1 ] && printf '%s\n' "$OD" | grep -q '^\./close-production\.sh:' || fail "a take-down body is written elsewhere than dnpost: $OD"
RUNS=$(code 'deploy down' ./*.sh | grep -v '^\./close\(-production\)\{0,1\}\.sh:' || true)
[ ! -d ../devagent ] || RUNS="$RUNS$(grep -rn 'close\.sh.*deploy down\|cmd_deploy down' ../devagent 2>/dev/null | grep -v '^[^:]*:[0-9]*:[[:space:]]*#' || true)"
[ -z "$RUNS" ] || fail "a script runs the take-down: $RUNS"
if [ -d ../skills ]; then SK=$(grep -rl 'deploy down' ../skills | sort); [ "$SK" = ../skills/vid-deploy/SKILL.md ] || fail "a skill other than vid-deploy names the take-down: $SK"; fi
cd - > /dev/null
# the skill's text
K=$CHECKS/../skills/vid-deploy/SKILL.md
if [ -f "$K" ]; then
  grep -qF '`/vid:vid-deploy down staging "<words>"`' "$K" && grep -qF '`/vid:vid-deploy down production "<words>"`' "$K" || fail "vid-deploy does not name the take-down's two commands"
  grep -q '^## Taking the test site down' "$K" || fail "vid-deploy has no develop section for the take-down"
  grep -qF "sh checks/event.sh 'deploy-down target=staging at=<commit> words=\"<their words>\"'" "$K" || fail "vid-deploy's develop section does not record deploy-down"
  grep -q '^| `asked <n> down <target>`' "$K" && grep -q '^| `down <target> <N>`, `down-failed <target>: <why>`' "$K" || fail "vid-deploy's table lacks the take-down's lines"
  awk 'NR == 1 && /^---$/ { on = 1; next } on && /^---$/ { exit } on' "$K" | grep -qF 'down' || fail "vid-deploy's description does not name the take-down"
fi
exit 0
