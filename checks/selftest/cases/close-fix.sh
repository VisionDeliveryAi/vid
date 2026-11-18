#!/bin/sh
# Purpose: selftest case — fix tickets from a close (v0.26.10.25.4, R1, R3, R4), checks/close.sh with the writer, the queue and the plan on
# the toy and the fake gh. A red chunk holding a row that could not run is asked again and nothing is acted on; once every row is read, the
# red rows read failing with one count each, a later ticket leaves them out of its regression rows, and they go in one fix line, its plan
# change accepted, the ask's issue closed, the asks kept by number; the fix ticket takes the line's three rows; the close is not owed again
# while the fix ticket is open, and is once it merges, whole, at the fix's merge commit; a row red at an earlier close goes to the owner, a
# `Q` line with both reasons and the three numbers, and no fix line, so the close is not owed again; the owner's again gives it its fix line;
# the third close's numbers, a regression introduced, red on another row than the second's, so the owner's (0.26.10.29.2, R7), whose
# again gives it its fix line; the owner's limit empties the unpublished line and the step closes. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "close-fix: $*" >&2; cat "$T/out" "$T/werr" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; CS=$CHECKS/close.sh; QS=$CHECKS/queue.sh; W=$CHECKS/writer.sh; R=owner/code; mkdir -p "$T/r"; : > "$T/werr"
cs() { RC=0; sh "$CS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
key() { printf '%s' "$1" | cksum | cut -d' ' -f1; }; reg() { awk '/^## Regression rows/ { on = 1; next } on && /^## / { exit } on' "$1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; gh issue create -R $R --title t --body b --label ticket > /dev/null; tw_close 1
sh "$GS" tw-sync > /dev/null 2>&1; tw_start S01 || fail 'S01 was refused'; mkdir -p .vid/round .vid/decide .vid/tw/out
M=$(git --git-dir="$T/code.git" rev-parse main); printf 'close-chunk-minutes: 20\nclose-wait-minutes: 0\n' >> .vid/tw/settings
# S01's ticket, #1, merged as pull request 2: two rows, one a journey, and two regression rows; every row accepted
printf '# t\n\n## Header\n\n- number: 1\n- kind: skeleton\n\n## Rows\n\n> ROW-003 | behavior | a | b | n/a | x | REQ-001 | o\n- ROW-003 marks: none\n> ROW-004 | journey | j | b | n/a | x transitions: 1. a 2. b | REQ-001 | o\n- ROW-004 marks: journey\n\n## Regression rows\n\n- ROW-001\n- ROW-002\n' > .vid/tw/out/issue-1.md
printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log; echo 2 > .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" > .vid/decide/merges
for r in ROW-003 ROW-004 ROW-001 ROW-002; do tw_hand "row $r accepted"; done; tw_hand 'engines alpha'
tw_hand 'candidate 1'   # v0.26.10.26.1: a later stage's candidate, so S01's close stays a step close, C1, as this case proves (stage 0 names none)
 sh "$GS" tw-sync > /dev/null 2>&1
send() { rm -rf "$T/x"; mkdir -p "$T/x"; cp -R "$T/r/$1" "$T/x/"; git -C "$T/x" init -q; git -C "$T/x" add -A; git -C "$T/x" -c user.name=a -c user.email=a@b commit -qm "$1"; git -C "$T/x" push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1"; }
rq() { Q=req-$N-$1; C0=$2; shift 2; rm -rf "$T/r/$Q"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$C0")"; rr_put "$Q" cases-alpha.xml "$(rr_cases "$@")"; send "$Q"; }
fetch() { sh "$GS" results-fetch > /dev/null 2>&1; sh "$GS" round-read > .vid/round/read 2>/dev/null; }
merge() { ( cd "$T/dev" && git -c user.name=a -c user.email=a@b commit -q --allow-empty -m "$1" && git push -q origin main ); MC=$(git --git-dir="$T/code.git" rev-parse main); echo "$2" >> .vid/decide/merged-prs; printf '%s\t%s\t%s\t%s\n' "$2" "$3" "$MC" "$MC" >> .vid/decide/merges; tw_close "$3"; sh "$GS" tw-sync > /dev/null 2>&1; fetch; }
# a hand fix line of the close's step, written before the close: the golden rows are regression rows
L0='fix ROW-002 | ROW-002: a hand case in alpha | close #1 of S01: none'; tw_hand "$L0"; K0=$(key "$L0"); F0=$(sh "$W" write fix "$K0" 2> "$T/werr") || fail 'the hand fix was refused'
reg "$F0" | grep -qx -- '- ROW-003' || fail "before the close ROW-003 is no regression row: $(reg "$F0")"
# ask 1: a red chunk with a row that could not run is asked again, nothing acted on
cs owed; ok '^close S01$'; cs ask S01; [ "$RC" = 0 ] || fail 'the ask failed'; N=$(sed -n 's/^asked \([0-9]*\) close.*/\1/p' "$T/out"); N1=$N; [ -f .vid/decide/close/S01/1/ask ] || fail 'the ask is not kept as ask 1'
rq p1c1-1 "$M" ROW-003=fail:broke ROW-004-T1=fail:lost ROW-004-T2=pass ROW-001=err:setup:\ no\ door ROW-002=pass; fetch; cs decide S01
ok '^close-again S01 p1c1$'; no '^failing '; no '^close-fix'; grep -q '^row ROW-003 accepted' .vid/tw/handed || fail 'a row was acted on while one could not run'
# lost again with no row red, an item for the owner; then its late report, read whole, ends the loss
rq p1c1-2 "$M" ROW-003=err:setup:\ no\ door ROW-004-T1=pass ROW-004-T2=pass ROW-001=err:setup:\ no\ door ROW-002=pass; fetch; cs decide S01; ok '^close-lost S01 p1c1$'; no '^failing '
# read whole: failing, a count each, one fix line, the plan change, the issue closed, the lost item gone
rq p1c1-3 "$M" ROW-003=fail:broke ROW-004-T1=fail:lost ROW-004-T2=pass tests/x.py::test_ROW_001_lists_each_job_once=fail:gone ROW-002=pass; fetch; cs decide S01; [ "$RC" = 0 ] || fail 'decide failed'
for r in ROW-003 ROW-004 ROW-001; do grep -qx "row $r failing | stand-in: close #$N" .vid/tw/handed && grep -qx "$r close#$N" .vid/decide/counts || fail "$r does not read failing with one count"; done
grep -q '^row ROW-002 accepted' .vid/tw/handed || fail 'a green row was touched'
FL="fix ROW-003 ROW-004 ROW-001 | ROW-003: ROW-003 in alpha; ROW-004: ROW-004-T1 in alpha; ROW-001: ROW-001 lists each job once in alpha | close #$N of S01: req-$N-p1c1-3"; KF=$(key "$FL")
grep -qxF "$FL | stand-in: RM" .vid/tw/handed || fail "the fix line: $(grep '^fix ' .vid/tw/handed)"; ok '^close-done S01$'; [ "$(cat "$T/gh/issues/$N/state")" = CLOSED ] || fail 'the ask stayed open'; ! grep -q '^lost ' .vid/decide/close/S01/1/items || fail 'the loss outlived its late report'
no '^plan-refused'; grep -q '^plan-change what=other ' .vid/metrics-events || fail 'no plan change was recorded'
cs decide S01; no '^failing '; no '^close-fix'; [ "$(grep -c "^ROW-003 close#$N" .vid/decide/counts)" = 1 ] && [ "$(grep -c '^fix ROW-003' .vid/tw/handed)" = 1 ] || fail 'a read again acted again'
F1=$(sh "$W" write fix "$K0" 2> "$T/werr") || fail 'the hand fix was refused after the close'; ! reg "$F1" | grep -q 'ROW-003\|ROW-004' || fail "a failing row is still a regression row: $(reg "$F1")"
grep -vxF "$L0 | stand-in: the self-test" .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed
# a journey ruled a known limit by its transitions is no longer owned
cp .vid/decide/state "$T/st0" 2>/dev/null || : > "$T/st0"; printf 'ROW-004-T1\tknown limit\tx\nROW-004-T2\tknown limit\tx\n' >> .vid/decide/state; cs owned; no '^ROW-004$'; cat "$T/st0" > .vid/decide/state
# the fix ticket of three rows; not owed again while it is open; owed once it merges
cs owned; ok '^ROW-003$'; ok '^ROW-004$'; sh "$W" due > "$T/out" 2>&1; ok "^new fix $KF$"; cs owed; no 'close S01'
tw_post fix "$KF" || fail 'the fix ticket was refused'; grep -qx -- '- rows: ROW-003 ROW-004 ROW-001' "$TW_F" && grep -qx -- '- step: S01' "$TW_F" || fail 'the fix ticket is not the three rows in S01'
sh "$GS" tw-sync > /dev/null 2>&1; cs owed; no 'close S01'
# another step's close, labelled, shares ROW-003 while S01's fix is open: the row waits there, no count, no second fix line; owed once the fix merges
printf 'published 98 kind=step step=S09 rows=ROW-002 at=2026-11-09T10:00:00Z\n' >> .vid/tw/log; mkdir -p .vid/decide/close/S09/1; printf 'issue\t97\ncommit\t%s\nchunk\tp1c1\talpha\tROW-003 ROW-002\n' "$M" > .vid/decide/close/S09/1/ask
N0=$N; N=97; rq p1c1-1 "$M" ROW-003=fail:broke ROW-002=pass; N=$N0; fetch; cs decide S09; ok '^close-waits S09 ROW-003$'; no '^failing '; ! grep -q '^ROW-003 close#97' .vid/decide/counts && [ "$(grep -c '^fix ROW-003' .vid/tw/handed)" = 1 ] || fail 'the shared row was taken twice'
cs owed; no 'close S09'; merge 'the fix' 6 "$TW_N"; M2=$MC; cs owed; ok '^close S01$'; ok '^close S09$'; cs owned; no ROW-003
# ask 2, whole, at the fix's merge: ROW-003 red again goes to the owner with both reasons and the numbers; no fix line, so not owed again
cs ask S01; N=$(sed -n 's/^asked \([0-9]*\) close.*/\1/p' "$T/out"); B=$T/gh/issues/$N/body; [ -f .vid/decide/close/S01/2/ask ] && grep -qx "commit: $M2" "$B" || fail 'the close again is not ask 2 at the fix merge'
for r in ROW-003 ROW-004 ROW-001 ROW-002; do grep -q -- "^- chunk p1c1, alpha: .*$r" "$B" || fail "the close again leaves out $r"; done
rq p1c1-1 "$M2" ROW-003=fail:still ROW-004-T1=pass ROW-004-T2=pass ROW-004-T3=pass ROW-001=pass ROW-002=pass; fetch; cs decide S01
ok '^close-twice S01 ROW-003$'; ok '^close-numbers S01 2 regressions introduced 0 · defects still open 1 · fixed 2$'; [ "$(grep -c '^fix ' .vid/tw/handed)" = 1 ] || fail 'a row red at an earlier close got a fix line'
sh "$QS" sync > /dev/null 2>&1; grep -q "· gates step S01 · the close of S01, ROW-003 failed again after its fix: now: ROW-003 in alpha · before: ROW-003 in alpha · regressions introduced 0 · defects still open 1 · fixed 2 · answer again" .vid/RUN-STATE.md || fail 'no Q line for the row red again'
cs owed; no 'close S01'; VID_STATUS_KEEP=1 sh "$QS" status > "$T/out" 2>&1; ok '^fixes: tickets open 0 · merged 1 · S01 close 2: regressions introduced 0 · defects still open 1 · fixed 2$'
# the owner's again: its own fix line, ticketed, merged; ask 3: ROW-003 fixed, ROW-002 a regression introduced, its fix line
QN=$(sed -n 's/^- \(Q[0-9]*\) · .*failed again after its fix.*/\1/p' .vid/RUN-STATE.md); sh "$QS" answer "$QN" again 'one more fix' > "$T/out" 2>&1 || fail 'the again answer failed'
cs decide S01; ok '^close-fix S01 ROW-003$'; L2="fix ROW-003 | ROW-003: ROW-003 in alpha | close #$N of S01: req-$N-p1c1-1"; grep -qxF "$L2 | stand-in: RM" .vid/tw/handed || fail 'the again line is not written'
tw_post fix "$(key "$L2")" || fail 'the again fix ticket was refused'; merge 'the fix again' 7 "$TW_N"; M3=$MC; cs owed; ok '^close S01$'; cs ask S01; N=$(sed -n 's/^asked \([0-9]*\) close.*/\1/p' "$T/out")
rq p1c1-1 "$M3" ROW-003=pass ROW-004-T1=pass ROW-004-T2=pass ROW-004-T3=pass ROW-001=pass ROW-002=fail:new; fetch; cs decide S01
ok '^close-numbers S01 3 regressions introduced 1 · defects still open 0 · fixed 1$'
# 0.26.10.29.2 (R7): red on ROW-002 after ROW-003, not a strict subset: the owner's, no fix line; their again writes it
ok '^close-shrink S01 ROW-002$'; no '^close-fix'; sh "$QS" sync > /dev/null 2>&1; QS3=$(sed -n 's/^- \(Q[0-9]*\) · .*did not shrink.*/\1/p' .vid/RUN-STATE.md); [ -n "$QS3" ] || fail 'the close that did not shrink has no Q line'
sh "$QS" answer "$QS3" again 'one more fix' > "$T/out" 2>&1 || fail 'the again answer failed'; cs decide S01; ok '^close-fix S01 ROW-002$'; L3="fix ROW-002 | ROW-002: ROW-002 in alpha | close #$N of S01: req-$N-p1c1-1"
# the owner rules ROW-002 a known limit: the unpublished line owes nothing, and the step closes
printf 'ROW-002\taccepted\taccepted\t2\t%s\tx\n' "$(printf %.12s "$M")" >> .vid/decide/state; sh "$QS" sync > /dev/null 2>&1
QR=$(sed -n 's/^- \(Q[0-9]*\) · .*the close of S01, chunk p1c1, failing:.*/\1/p' .vid/RUN-STATE.md); grep -q "failing: alpha:ROW-002 · regressions introduced 1 · defects still open 0 · fixed 1 · a fix ticket is written" .vid/RUN-STATE.md || fail 'the red Q line has no numbers'
sh "$QS" answer "$QR" limit 'leave it' > "$T/out" 2>&1 || fail 'the limit failed'; sh "$W" due > "$T/out" 2>&1; no "new fix $(key "$L3")"
cs decide S01; ok '^closed S01$'; grep -q "^closed S01 | stand-in: close #$N at $(printf %.12s "$M3")" .vid/tw/handed || fail 'no closed line'; cs owed; no 'close S01'
exit 0
