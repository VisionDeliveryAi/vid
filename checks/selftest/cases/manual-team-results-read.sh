#!/bin/sh
# Purpose: selftest case — how a row is read in GitHub manual (FB-3 A1.2), by results.sh read and decide.sh on the manual toy
# (fixtures/accept.sh). A row with a failed case in one file fails beside a passed one in another, the report it failed in named; an
# errored case fails it, a `setup:` one beside a pass stops nothing, one alone could not run. A journey's transitions are shared out over files; a
# row in no file but skipped ones is `evidence missing`. A rule row with no covers: line is accepted, with `covers: <row> 0` failing. A
# break given at the commit is read: missed, `failing, a weak test`; proven, accepted. A red run by a person is shown, one that is refused
# is said, and neither blocks. Two reports' files are one pool. A report with no results file is refused in words and left out of the
# rest; alone at the commit it is the refusal's `report left out` line. A file that is not whole fails a row and never passes one.
# A report made before a test's amendment is not read for that test, its covers: line and break with it. Of two reports' covers: lines the
# lowest counts. A regression row with no case keeps what a known limit or a close's fix makes of it. No row is asked a red, a break or an engine. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "manual-team-results-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
# tkt <n> <step> <row>…: a published ticket of those rows, a RULE row marked so
tkt() { n=$1; s=$2; shift 2; { mn_ticket "$n" "$s" step "$@" | sed 's/^- \(RULE-[0-9]*\) marks: none$/- \1 marks: rule/'; printf '\n## Engines\n\n- primary: alpha\n- also: beta\n'; } > ".vid/tw/out/issue-$n.md"; printf 'published %s kind=step step=%s rows=%s at=2026-11-18T09:00:00Z\n' "$n" "$s" "$(echo "$*" | tr ' ' ,)" >> .vid/tw/log; }
tkt "$AC_N" S02 ROW-001 ROW-002 ROW-004 ROW-006 ROW-010 ROW-012 ROW-020 RULE-001 RULE-002; c12=$(printf %s "$AC_C" | cut -c1-12)
dec() { sh "$CHECKS/github.sh" results-fetch > /dev/null 2>&1 || fail 'results-fetch failed'; sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'the read failed'
  sh "$CHECKS/results.sh" read --ticket "$AC_N" --at "$1" > "$T/ev" 2> "$T/out" || fail 'the read of the reports failed'; sh "$CHECKS/decide.sh" decide --ticket "$AC_N" --at "$1" > "$T/out" 2>&1 || fail 'the decision failed'; }
li() { grep -q -- "$1" "$T/out" || { cat "$T/ev" >> "$T/out"; fail "no line: $1"; }; }
rr_put unit-1 results.txt "$(printf 'by: A. Person\r\ncommit: %s\r\ncovers: RULE-002 0\nstand-in: the mail service - a file' "$AC_C")"
rr_put unit-1 'unit tests.xml' "$(rr_cases ROW-001=pass ROW-002=pass ROW-004-T1=pass ROW-004-T2=pass ROW-006=skip ROW-010=err:boom ROW-012=pass RULE-001=pass RULE-002=pass)"; ac_send unit-1
rr_put unit-2 results.txt "$(printf 'by: B. Person\ncommit: %s' "$AC_C")"; rr_put unit-2 a.xml "$(rr_cases ROW-001=fail:no_digest ROW-002=err:setup:_no_server ROW-004-T3=pass ROW-010=pass ROW-020=err:setup:_no_server)"; ac_send unit-2
rr_put noxml-3 results.txt "$(printf 'by: C. Person\ncommit: %s' "$AC_C")"; rr_put noxml-3 out.log 'all passed'; ac_send noxml-3
K=$(gh_issue 'a part'); gh_sub "$AC_N" "$K"; ac_report "red-$K-1" 'A. Person' "$AC_RED" 't.xml=ROW-001=fail:no_digest'
rr_put "red-$AC_N-1" results.txt "$(printf 'by: A. Person\ncommit: %s\nrows: ROW-002' "$AC_RED")"; ac_send "red-$AC_N-1"
dec "$AC_C"
li '^ROW-001 failing, a product failure — its test failed, unit-2'; li '^ROW-002 accepted$'; li '^ROW-004 accepted$'; li '^ROW-006 evidence missing — no case of it ran at this commit$'; li '^ROW-010 failing, a product failure — its test failed, unit-1'
li '^ROW-012 accepted$'; li '^ROW-020 evidence missing — its test could not run, '; li '^RULE-001 accepted$'; li '^RULE-002 failing, a product failure'; li '^report left out — vid-results/noxml-3: no whole results file with a test case'
! grep -qiE 'red|fault|covers: line|engine|split' "$T/out" || fail 'the decision asks a red, a break, a covers: line or an engine'
grep -q '^ROW-001	[^	]*	red	failed' "$T/ev" && grep -q "^report T2 red-$K-1 read" "$T/ev" && grep -q "^report T2 red-$AC_N-1 refused no whole results file" "$T/ev" || { cp "$T/ev" "$T/out"; fail 'the red run is not shown, or the refused one not said'; }
grep -q 'the mail service' .vid/results/stand-in.txt || fail "the report's stand-in line is not kept"
# breaks given at the commit, and a file that is not whole
tkt "$AC_N" S02 ROW-001 ROW-002 ROW-012; tk_dev 'C2'; C2=$(git -C "$T/dev" rev-parse HEAD); ac_grade "$C2" 'ROW-001 kept — seen'
rr_put unit-4 results.txt "$(printf 'by: A. Person\ncommit: %s' "$C2")"; rr_put unit-4 u.xml "$(rr_cases ROW-001=pass ROW-002=pass ROW-012=pass)"; rr_put unit-4 faults/ROW-001/control.txt ROW-012; rr_put unit-4 faults/ROW-001/out.xml "$(rr_cases ROW-001=pass ROW-012=pass)"
rr_put unit-4 faults/ROW-002/control.txt ROW-012; rr_put unit-4 faults/ROW-002/out.xml "$(rr_cases ROW-002=fail:it_breaks ROW-012=pass)"; ac_send unit-4
rr_put unit-5 results.txt "$(printf 'by: A. Person\ncommit: %s' "$C2")"; rr_put unit-5 whole.xml "$(rr_cases x=pass)"; rr_put unit-5 cut.xml '<testsuite><testcase name="ROW-012"><failure message="no page">x</failure></testcase><testcase name="y"/>'; ac_send unit-5
dec "$C2"; li "^ROW-001 held — failing, a weak test — its fault not proven, results-at-$(printf %.12s "$C2") "; li '^ROW-002 accepted$'; li '^ROW-012 failing, a product failure — its test failed, unit-5'
# the only report at a commit has no results file: the refusal says so
tk_dev 'C3'; C3=$(git -C "$T/dev" rev-parse HEAD); rr_put noxml-6 results.txt "$(printf 'by: C. Person\ncommit: %s' "$C3")"; ac_send noxml-6
ac_round accept "$AC_N" "$C3"; grep -qxF "refused #$AC_N no results at $(printf %.12s "$C3"); accepted outside ViD: /vid:vid-accept-step $AC_N $(printf %.12s "$C3") accepted \"<your words>\"" "$T/out" && grep -q '^report left out — vid-results/noxml-6: no whole results file with a test case' "$T/out" || fail 'a report with no results file, alone, is not refused in words'
# an amendment: the report made before it is not read for the test it restates
printf 'amended %s kind=step step=S02 rows=ROW-001,ROW-002,ROW-012 parts=2 at=2026-11-19T12:00:00Z added=- words="yes" restated=ROW-012\n' "$AC_N" >> .vid/tw/log
tk_dev 'C4'; C4=$(git -C "$T/dev" rev-parse HEAD); AC_WHEN='2026-11-19 10:00:00 +0000'; ac_report 'early&1st+' 'A. Person' "$C4" 'e.xml=ROW-001=pass ROW-002=pass ROW-012=pass'; dec "$C4"
li '^ROW-012 evidence missing — no case in results sent since its amendment'; li '^ROW-002 accepted$'
AC_WHEN='2026-11-19 13:00:00 +0000'; ac_report late-1 'A. Person' "$C4" 'l.xml=ROW-012=pass'; dec "$C4"; li '^ROW-012 accepted$'
# its covers: line and its break are not read either, and where it passed before the amendment is not named
tkt "$AC_N" S02 ROW-002 ROW-006 ROW-012 RULE-001; printf 'amended %s kind=step step=S02 rows=ROW-002,ROW-006,ROW-012,RULE-001 parts=2 at=2026-11-19T12:00:00Z added=- words="yes" restated=ROW-006,ROW-012,RULE-001\n' "$AC_N" >> .vid/tw/log
tk_dev 'C5'; C5=$(git -C "$T/dev" rev-parse HEAD); AC_WHEN='2026-11-19 10:00:00 +0000'; rr_put old-5 results.txt "$(printf 'by: A. Person\ncommit: %s\ncovers: RULE-001 0' "$C5")"; rr_put old-5 o.xml "$(rr_cases ROW-002=pass ROW-006=pass ROW-012=pass RULE-001=pass)"
rr_put old-5 faults/ROW-012/control.txt ROW-002; rr_put old-5 faults/ROW-012/out.xml "$(rr_cases ROW-012=pass ROW-002=pass)"; ac_send old-5; AC_WHEN='2026-11-19 13:00:00 +0000'; ac_report new-5 'A. Person' "$C5" 'n.xml=ROW-012=pass RULE-001=pass'; dec "$C5"
li '^ROW-012 accepted$'; li '^RULE-001 accepted$'; li '^ROW-006 evidence missing — no case in results sent since its amendment$'
# two reports' covers: lines, the lowest counts; a report with no commit, under the ticket's number, is left out in words
tk_dev 'C6'; C6=$(git -C "$T/dev" rev-parse HEAD); for x in a:0 b:3; do rr_put "cov-${x%:*}" results.txt "$(printf 'by: A. Person\ncommit: %s\ncovers: RULE-001 %s' "$C6" "${x#*:}")"; rr_put "cov-${x%:*}" c.xml "$(rr_cases RULE-001=pass ROW-002=pass ROW-012=pass)"; ac_send "cov-${x%:*}"; done
rr_put "step-$AC_N-x" results.txt 'by: A. Person'; rr_put "step-$AC_N-x" s.xml "$(rr_cases ROW-006=pass)"; ac_send "step-$AC_N-x"; dec "$C6"
li '^RULE-001 failing, a product failure'; li '^ROW-006 evidence missing — no case of it in the results at this commit$'; li "^report left out — vid-results/step-$AC_N-x: results.txt names no commit$"
# a regression row with no case: passing when what it lacks is a known limit, its state standing when a close's fix holds it
NJ=$(gh_issue 'the journey'); tkt "$NJ" S04 ROW-004; NR=$(gh_issue 'a later step'); AC_N=$NR; tkt "$NR" S03 ROW-002; printf '\n## Regression rows\n\n- ROW-004\n- ROW-010\n' >> ".vid/tw/out/issue-$NR.md"
printf '2026-11-19T09:00:00Z\tROW-004-T3\tlimit\t\towner\n' >> .vid/decide/rulings; mkdir -p .vid/decide/close/S05/1; printf 'issue\t9\ncommit\t%s\nasked\t2026-11-19T09:00:00Z\n' "$C6" > .vid/decide/close/S05/1/ask; printf 'ROW-010\tno list\n' > .vid/decide/close/S05/1/acted
tk_dev 'C7'; C7=$(git -C "$T/dev" rev-parse HEAD); ac_report run-7 'A. Person' "$C7" 'r.xml=ROW-002=pass ROW-004-T1=pass ROW-004-T2=pass'; ac_grade "$C7" 'ROW-002 kept — seen'; dec "$C7"; li '^ROW-004 passing$'; li '^ROW-010 its state stands$'; li '^ticket: accepted$'
exit 0
