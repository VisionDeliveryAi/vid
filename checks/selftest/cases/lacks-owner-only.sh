#!/bin/sh
# Purpose: selftest case — what a team's older form lacked, told to the owner alone (FB-5 B1.8), on GitHub manual's toy and the fake gh
# (fixtures/accept.sh). At the end of a decision one line `lacks #<n> <c12> — …` names a transition with no test of its own name, a
# row's id written with other digits, results older than a row's amendment, a branch, a file and a break's
# folder left out, a pull request with no
# Decisions section and that no engine is named; nothing of it is posted, and the rows' own lines stand. With the team's rules on record
# (`team-rules`) the two lines about form leave the posted decision, and the Decisions section holds nothing: the ticket is accepted, the
# owner still told. A decision that lacks nothing has no such line. In GitHub auto there is none. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "lacks-owner-only: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
tkt() { _n=$1; _s=$2; shift 2; { mn_ticket "$_n" "$_s" step "$@"; printf '\nDecisions: the pull request'"'"'s body holds a section that begins with the line Decisions:.\n\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$_n.md"; printf 'published %s kind=step step=%s rows=%s at=2026-11-18T09:00:00Z\n' "$_n" "$_s" "$(echo "$*" | tr ' ' ,)" >> .vid/tw/log; }
tkt "$AC_N" S02 ROW-001 ROW-004 ROW-006 ROW-012
printf 'amended %s kind=step step=S02 rows=ROW-001,ROW-004,ROW-006,ROW-012 parts=2 at=2026-11-19T12:00:00Z added=- words="yes" restated=ROW-012\n' "$AC_N" >> .vid/tw/log
ac_unit part "$(printf 'ticket: #%s\n\nNo section.\n' "$AC_N")"; UP=$AC_P; C=$AC_M; c12=$(printf %.12s "$C")
AC_WHEN='2026-11-19 10:00:00 +0000'; rr_put any-1 results.txt "$(printf 'by: A. Person\ncommit: %s' "$C")"; rr_put any-1 a.xml "$(rr_cases ROW_1=pass ROW-004=pass ROW-006=pass ROW-012=pass)"
rr_put any-1 faults/ROW_20/out.xml "$(rr_cases ROW-020=fail:broken)"; rr_put any-1 cut.xml '<testsuite><testcase name="x"/>'; ac_send any-1
( cd "$T/dev" && git checkout -q -B bad main && echo code > app.py && git add app.py && g commit -q -m bad && git push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/red-$AC_N-9" && git checkout -q -f main )
ac_ask "$C"; ac_round accept "$AC_N" "$C"; [ "$RC" = 0 ] && grep -q "^decided #$AC_N $c12 ticket: not yet" "$T/out" || fail "accept exited $RC"
[ "$(grep -c "^lacks #$AC_N $c12 — " "$T/out")" = 1 ] || fail 'there is no one lacks line'
l=$(grep '^lacks ' "$T/out"); has() { case $l in *"$1"*) ;; *) fail "the lacks line does not name: $1" ;; esac; }
has 'ROW-004-T1 ROW-004-T2 ROW-004-T3: no test of its own name'; has 'ROW-001 written ROW_1'; has 'ROW-012: results older than its amendment'; has "vid-results/red-$AC_N-9 left out"; has 'any-1 cut.xml'; has 'faults/ROW_20: a break of no row'; has "no Decisions section — #$UP"; has 'no engine named'
case $l in *ROW-006*) fail 'a row with its test is named' ;; esac
ac_last > "$T/out"; ! grep -q 'lacks\|digits\|engine' "$T/out" && grep -qx "no Decisions section — #$UP" "$T/out" && grep -q "^report left out — vid-results/red-$AC_N-9" "$T/out" && grep -q '^ROW-001 evidence missing' "$T/out" || fail 'a lacks word is in the posted decision, or a line of it is gone'
# the team's rules on record: the two lines about form leave it, the rows' stay
sh "$CHECKS/planner.sh" setup team-rules team/rules.md --words 'their own rules' > "$T/out" 2>&1 || fail 'the rules could not be recorded'
ac_ask "$C"; ac_round accept "$AC_N" "$C"; grep -q "^lacks #$AC_N $c12 — .*no Decisions section — #$UP" "$T/out" || fail 'with the rules on record the owner is not told'
ac_last > "$T/out"; ! grep -q 'no Decisions section\|report left out' "$T/out" && grep -q '^ROW-001 evidence missing' "$T/out" && grep -qx 'ticket: not yet' "$T/out" || fail 'a line about form is in the posted decision, or a row'"'"'s line is gone'
# every row passing: accepted, the section holding nothing; then nothing lacking, no line
N2=$(gh_issue 'Step S03'); AC_N=$N2; tkt "$N2" S03 ROW-001 ROW-012; ac_unit two "$(printf 'ticket: #%s\n\nNo section.\n' "$N2")"; UP=$AC_P; D=$AC_M; AC_WHEN=''; ac_head "$D"; ac_grade "$D"; ac_ask "$D"; ac_round accept "$N2" "$D"
grep -q "^accepted #$N2 $(printf %.12s "$D")" "$T/out" && grep -qx "lacks #$N2 $(printf %.12s "$D") — no Decisions section — #$UP" "$T/out" || fail 'with the rules on record the section held the ticket, or the owner is not told'
ac_last > "$T/out"; ! grep -q 'Decisions section' "$T/out" || fail 'the accepted decision names the section'
N3=$(gh_issue 'Step S04'); AC_N=$N3; tkt "$N3" S04 ROW-001 ROW-012; tk_dev 'a later commit'; E=$(git -C "$T/dev" rev-parse HEAD); ac_head "$E"; ac_grade "$E"; ac_ask "$E"; ac_round accept "$N3" "$E"; grep -q "^accepted #$N3 " "$T/out" && ! grep -q '^lacks ' "$T/out" || fail 'a decision that lacks nothing says it does'
# the team's rules taken away: the section holds again, as before
sh "$CHECKS/planner.sh" setup team-rules none --words 'ours now' > "$T/out" 2>&1 || fail 'the rules could not be taken away'
N4=$(gh_issue 'Step S05'); AC_N=$N4; tkt "$N4" S05 ROW-001 ROW-012; ac_unit four "$(printf 'ticket: #%s\n\nNo section.\n' "$N4")"; ac_head "$AC_M"; ac_grade "$AC_M"; ac_ask "$AC_M"; ac_round accept "$N4" "$AC_M"; grep -q "^decided #$N4 .* ticket: not yet" "$T/out" || fail 'with none on record the section no longer holds the ticket'
# GitHub auto: none
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup; sh "$CHECKS/planner.sh" setup team-rules team/rules.md --words 'x' > /dev/null 2>&1 || true
( cd "$T/dev" && git checkout -q -B "ticket-$N4" main && g commit -q --allow-empty -m 'the pull request' && git push -q -f origin "ticket-$N4" 2>/dev/null && git checkout -q main ); gh pr create -R owner/code --head "ticket-$N4" --base main --title t --body "ticket: #$N4" > /dev/null
ac_round accept "$N4"; [ "$RC" = 0 ] && ! grep -q '^lacks ' "$T/out" || fail 'GitHub auto says what a form lacks'
echo 'lacks-owner-only: ok'
