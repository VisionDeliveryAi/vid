#!/bin/sh
# Purpose: selftest case — /vid:vid-deploy in the GitHub modes (GM-4 K5), checks/close.sh deploy, on the writer's toy and the fake gh,
# in each GitHub mode, stage 1's candidate planted. `deploy staging` refuses an okay not due, naming why, posting nothing; once its
# full run passed, posts the staging okay; asked again, refuses it as asked already. In GitHub manual the okay holds no stage back
# (D4: no hold sentence, no setup hold's line in the owner's queue or its status); in GitHub auto both stay. `deploy production` with no words is
# refused; the stage closed and rehearsed, its words answer the open production yes, and the next round (round.sh asks, GM-4 K11 in
# GitHub manual too) posts the production okay. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/auto-t; mkdir -p "$T"; MO=auto
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "deploy-verb: $MO: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; R=owner/code; TAB=$(printf '\t')
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
nis() { ls "$T/gh/issues" 2>/dev/null | grep -c . || true; }
run() { MO=$1; tw_toy "$T/toy"; sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; mkdir -p .vid/round .vid/decide .vid/tw/out
  tw_hand 'engines alpha'; tw_hand 'stage-closed 0 | stand-in: RM at 000000000000 candidate 1'
  if [ "$MO" = manual ]; then printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
    printf 'state-repo: owner/vid-state\n' >> .vid/tw/settings; gh repo create owner/vid-state --private > /dev/null 2>&1 || true; fi
  CLAUDE_CODE_SESSION_ID=dv; export CLAUDE_CODE_SESSION_ID; sh "$GS" lock-take dv > "$T/out" 2>&1 || fail 'the lock could not be taken'
  sh "$GS" results-fetch > /dev/null 2>&1 || true
  # stage 1's candidate 1, named, its full run out
  X=$(git --git-dir="$T/code.git" rev-parse main); F=.vid/decide/stage/1/1; mkdir -p "$F"; printf 'issue\t90\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"; : > "$F/named"
  tw_hand "candidate 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"
  n0=$(nis); cs deploy staging; [ "$RC" = 1 ] || fail "an okay not due exited $RC"; ok "^refused staging: stage 1: its candidate 1's full run, C3, has not passed$"; [ "$(nis)" = "$n0" ] || fail 'a refused okay posted'
  : > "$F/passed"; : > "$F/done"; cs deploy staging; [ "$RC" = 0 ] || fail "the due okay exited $RC"; ok '^asked [0-9]* okay stage-1$'; O=$(sed -n 's/^asked \([0-9]*\) okay stage-1$/\1/p' "$T/out")
  if [ "$MO" = manual ]; then ! grep -q 'no ticket of stage 2 is published' "$T/gh/issues/$O/body" || fail 'the staging okay holds stage 2 back in GitHub manual'
    sh "$CHECKS/queue.sh" sync > /dev/null 2>&1 || true; ! grep -q 'waits until staging has passed once' .vid/RUN-STATE.md || fail "the setup hold is a line of the owner's queue in GitHub manual"
  else grep -q 'Until this deploy passes, or the owner says continue, no ticket of stage 2 is published.' "$T/gh/issues/$O/body" || fail 'the staging okay lost its hold sentence in GitHub auto'; fi
  sh "$CHECKS/queue.sh" status > "$T/st" 2>&1 || true; if [ "$MO" = manual ]; then ! grep -q '^setup hold:' "$T/st" || fail "the status line names a setup hold in GitHub manual: $(grep '^setup hold:' "$T/st")"
  else grep -q '^setup hold: ' "$T/st" || fail "the status line lost its setup hold in GitHub auto: $(cat "$T/st")"; fi
  n1=$(nis); cs deploy staging 1; [ "$RC" = 1 ] || fail "an okay asked already exited $RC"; ok "^refused staging: stage 1: its candidate 1's staging okay, #$O, is asked already$"; [ "$(nis)" = "$n1" ] || fail 'a refused okay posted'
  # production: no words refused; then the stage closed, staged, walked and rehearsed, the production yes asked
  cs deploy production ''; [ "$RC" = 1 ] || fail "a production yes with no words exited $RC"; ok "^refused production: the production yes is given only with the owner's own words"
  cs deploy production 'Yes, go live'; [ "$RC" = 1 ] || fail "a production yes before any rehearsal exited $RC"; ok '^refused production: no stage is closed'
  mkdir -p "$F/d1" "$F/cs" "$F/w1" "$F/rh" "$F/cr"; : > "$F/d1/passed"; : > "$F/cs/ask"; : > "$F/cs/passed"; : > "$F/cs/done"; : > "$F/w1/done"; tw_hand 'staged 1 | stand-in: D1'
  tw_hand "stage-closed 1 | stand-in: RM at $(printf %.12s "$X") candidate 1"; H=$(gh issue create -R $R --title 'Rehearsal' --body b | sed 's#.*/##')
  printf 'issue\t%s\ncommit\t%s\nasked\t2026-11-10T10:00:00Z\n' "$H" "$X" > "$F/rh/ask"; : > "$F/rh/passed"; : > "$F/cr/ask"; : > "$F/cr/passed"; : > "$F/cr/done"
  printf 'production:1:1:%s\tRehearsal of stage 1 passed: Deploy to production? yes or no\n' "$H" > "$F/yes"
  cs owed; ! grep -q '^okay production' "$T/out" || fail 'a production okay is owed with no yes'
  cs deploy production 'Yes, go live'; [ "$RC" = 0 ] || fail "the owner's production yes exited $RC"; ok '^yes production 1 1: '
  awk -F'\t' -v k="production:1:1:$H" '$2 == k && $3 == "yes" && $4 == "Yes, go live" && $5 == "owner" { f = 1 } END { exit !f }' .vid/decide/queue/answers || fail "the yes is no owner's answer in their words: $(cat .vid/decide/queue/answers)"
  cs deploy production 'Yes again'; [ "$RC" = 1 ] || fail "a second yes exited $RC"; ok '^refused production: .*given already'
  RC=0; sh "$CHECKS/round.sh" asks > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh asks exited $RC"; ok '^asked [0-9]* okay production-1$'
  [ -f "$F/d2/ask" ] || fail 'no production okay recorded'; }
run auto
T=$T0/manual-t; mkdir -p "$T"; run manual
exit 0
