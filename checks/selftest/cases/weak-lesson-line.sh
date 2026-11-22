#!/bin/sh
# Purpose: selftest case — a weak test's lesson reaches the session in both modes (FB-1 C2). Right after each `decided` line the
# round prints, one `weak <row> <#n or pull request> <head 12> — <the row's text>` line for each row line of the posted decision that
# reads `failing, a weak test`. GitHub manual (fixtures/accept.sh): `round.sh accept` decides a ticket whose head report's fault folder
# for ROW-001 passes (its fault not proven); asked again with nothing changed, it prints no `decided` line and no `weak` line. GitHub
# auto (fixtures/tw-toy.sh): `round.sh step` decides a pull request whose fault folder for ROW-003 passes; the next step, deciding
# nothing again, prints no `weak` line; `round.sh accept 1` on that unchanged decision, twice, posts nothing again and prints its
# `decided` line, then the `weak` line. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T0=$(mktemp -d); trap 'rm -rf "$T0"' EXIT; T=$T0/man; mkdir -p "$T"
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "weak-lesson-line: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# GitHub manual: round.sh accept
ac_project "$T/p" || fail 'the manual toy could not be made'
ac_red; h=$(printf %s "$AC_C" | cut -c1-12); _i=step-$AC_N-$h-1
rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nenvironments: 1' "$AC_C")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-001=pass ROW-012=pass)"
rr_put "$_i" faults/ROW-001/control.txt ROW-001; rr_put "$_i" faults/ROW-001/cases-alpha.xml "$(rr_cases ROW-001=pass)"; ac_send "$_i"
ac_grade "$AC_C"; ac_ask "$AC_C"; ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept exited $RC"
ac_last | grep -q '^ROW-001 failing, a weak test' || { ac_last > "$T/out"; fail 'the scene is wrong: the posted decision has no weak ROW-001'; }
grep -q "^decided #$AC_N $h " "$T/out" || fail 'the scene is wrong: accept printed no decided line'
grep -q "^weak ROW-001 #$AC_N $h — failing, a weak test" "$T/out" || fail "accept printed no weak line for ROW-001 after its decided line"
[ "$(grep -n '^weak ' "$T/out" | cut -d: -f1)" -gt "$(grep -n '^decided ' "$T/out" | cut -d: -f1)" ] || fail 'the weak line does not follow the decided line'
! grep -q '^weak ROW-012 ' "$T/out" || fail 'a row not weak has a weak line'
ac_round accept "$AC_N" "$AC_C"; [ "$RC" = 0 ] || fail "accept again exited $RC"; ! grep -q '^decided ' "$T/out" || fail 'the scene is wrong: the unchanged re-decision printed a decided line'
! grep -q '^weak ' "$T/out" || fail 'a re-decision that printed no decided line printed a weak line'
# GitHub auto: round.sh step
unset CLAUDE_CODE_SESSION_ID; T=$T0/auto; mkdir -p "$T"; . "$CHECKS/selftest/fixtures/tw-toy.sh"; tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code; mkdir -p "$T/r"
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd next; [ "$RC" = 0 ] && grep -q '^published 1$' "$T/out" || fail 'the skeleton was not published'
D=$T/w; git clone -q "$T/code.git" "$D" 2>/dev/null; git -C "$D" checkout -q -B ticket-1 origin/main 2>/dev/null; git -C "$D" -c user.name=a -c user.email=a@b commit -q --allow-empty -m ticket-1; git -C "$D" push -q -f origin ticket-1 2>/dev/null; H=$(git -C "$D" rev-parse HEAD)
P=$(gh pr create -R $R --head ticket-1 --base main --title t --body "$(printf 'ticket: #1\n\nDecisions: none')" | sed 's/.*\///'); h=$(printf %s "$H" | cut -c1-12)
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
Q=pr-$P-$h-1; rr_put "$Q" faults/ROW-003/cases-alpha.xml "$(rr_cases ROW-003=pass)"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nenvironments: 2' "$H")"
rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-004-T3=pass)"; send "$Q"
rr_put "grade-$Q" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-003 kept — a\nROW-004-T1 kept — b' "$H")"; send "grade-$Q"
printf 'vid: decide %s\nby: MR\n' "$H" > "$T/c"; gh pr comment "$P" -R $R --body-file "$T/c" > /dev/null
rd step; [ "$RC" = 0 ] || fail "step exited $RC"; grep -q "^decided $P $h " "$T/out" || fail 'the scene is wrong: step printed no decided line'
grep -q '^ROW-003 failing, a weak test' "$T/gh/prs/$P/comments/$(ls "$T/gh/prs/$P/comments" | sort -n | tail -n 1)" || fail 'the scene is wrong: the posted decision has no weak ROW-003'
grep -q "^weak ROW-003 $P $h — failing, a weak test" "$T/out" || fail 'step printed no weak line for ROW-003 after its decided line'
rd step; [ "$RC" = 0 ] || fail "the next step exited $RC"; ! grep -q '^decided ' "$T/out" || fail 'the scene is wrong: the next step decided again'
! grep -q '^weak ' "$T/out" || fail 'a step that printed no decided line printed a weak line'
# GitHub auto's accept on the unchanged decision: nothing posted again, its decided line said all the same, and the weak line after it
for k in first second; do n0=$(ls "$T/gh/prs/$P/comments" | grep -c .); rd accept 1; [ "$RC" = 0 ] || fail "the $k auto accept exited $RC"
  [ "$(ls "$T/gh/prs/$P/comments" | grep -c .)" = "$n0" ] || fail "the $k auto accept of an unchanged decision posted again"
  grep -q "^decided $P $h " "$T/out" || fail "the scene is wrong: the $k auto accept printed no decided line"
  grep -q "^weak ROW-003 $P $h — failing, a weak test" "$T/out" || fail "the $k auto accept printed no weak line after its decided line"
  [ "$(grep -n '^weak ' "$T/out" | cut -d: -f1)" -gt "$(grep -n '^decided ' "$T/out" | cut -d: -f1)" ] || fail "the $k auto accept's weak line does not follow its decided line"; done
echo 'weak-lesson-line: ok'
