#!/bin/sh
# Purpose: selftest case — reading cases and the rows' evidence (v0.26.10.24.5 R4–R8). On made-up reports: a testsuites wrapper,
# system-out holding failure and an angle bracket, CDATA, a comment, entities, a self-closing case; a runner's class name before
# setup: and before a plain line; an indented forbidden-effect line, and another row's. Each value of red, t3, fault and grade; a
# journey's transitions; a deploy-owed row absent from T3; a regression row with no grade line; the skeleton; a retested row, of this
# ticket, of an earlier one, and deploy-owed; a reached ticket's rows; an attempt with faults over one without; a stand-in line at an older
# head, kept, and a refused report's or a superseded attempt's not; declare, read by the writer and by admission's budget. Nothing it prints of its own is a decision word.
# v0.26.10.25.3: an engine not asked, its failure, its split and its engine line, and every declared engine asked once a row has split (R11);
# the setup: count over the newest attempts (R12); a fault folder on a row the ticket does not list, read (R13). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "results-rows: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
R=$CHECKS/results.sh; rr_project; TAB=$(printf '\t')
rd() { sh "$R" read --ticket "$1" --pr "$2" --head "$3" > "$T/out" 2>&1 || fail "read exited 1"; }
# has <row> <red> <t3> <fault> <what it once graded, unread> [<words in the reason>]
has() { awk -F'\t' -v r="$1" -v a="$2" -v b="$3" -v c="$4" -v d="$5" -v w="${6:-}" '$1 == r && $3 == a && $4 == b && $5 == c && (w == "" || index($6, w)) { f = 1 } END { exit !f }' "$T/out" || fail "no line: $*"; }
H=$RR_H12; A=pr-4-$H-1; G=sort-pr-4-$H-1; F=$T/r/pr-4-$H-2/faults
# nothing sent: every row owed shows missing, a deploy-owed row owed
rd 3 4 "$RR_H"; has ROW-001 no-red missing missing missing 'no head report'; has DIF-001 n/a owed n/a missing; grep -qx 'report T2 none' "$T/out" || fail 'no T2 line'
# a good round: red; T3; the grade's words; the journey by transition; regression, rule, seam
rr_good; rd 3 4 "$RR_H"; has ROW-001 red passed n/a kept; has ROW-002-T1 red passed missing kept 'no fault folder'; has ROW-002-T2 red passed n/a kept
has HOS-001 red passed missing kept; has RULE-001 red passed n/a kept 'covers 3'; has DIF-001 n/a owed n/a kept; has SEAM-001 n/a owed n/a kept; grep -qF 'finding: note — a note — SEAM-001 unclear — which feed?' "$T/out" && ! grep -q 'a drop' "$T/out" || fail 'note it did not reach the evidence, or drop it did'; grep -qxF 'finding: bug — a stray route' "$T/out" && grep -q '^report grade grade-pr-4-' "$T/out" && grep -qx 'open grade line: SEAM-001' "$T/out" || fail "the grade's finding, or its open line, did not reach the evidence"; cp "$T/r/grade-pr-4-$H-1/grade.txt" "$T/g1"; rr_put grade-pr-4-$H-2 grade.txt "$(sed 's/^SEAM-001 .*/SEAM-001 kept — seen/' "$T/g1")"; rr_send grade-pr-4-$H-2; rd 3 4 "$RR_H"; grep -q 'open grade line: SEAM-001' "$T/out" && fail 'a superseded attempt kept a line open'; git --git-dir=.vid/code update-ref -d "refs/heads/vid-results/grade-pr-4-$H-2"; has ROW-009 n/a passed n/a n/a
[ "$(awk -F'\t' 'NF == 6' "$T/out" | wc -l | tr -d ' ')" = 8 ] || fail 'not 8 row lines'
grep -qx 'environments: 2' "$T/out" || fail 'no environments'; [ -f ".vid/results/pr-4-$H.txt" ] || fail 'no evidence file'
# R4: the odd shapes, all at once
X=$T/r/pr-4-$H-2/cases-alpha.xml; mkdir -p "$T/r/pr-4-$H-2"; sed 's/^environments: 2$/retested: ROW-009 ROW-008 DIF-001/; s/^stand-in:.*//' "$T/r/$A/results.txt" > "$T/r/pr-4-$H-2/results.txt"
cat > "$X" <<'XML'
<?xml version="1.0"?>
<!-- a comment <testcase name="ROW-003"/> -->
<testsuites name="all"><testsuite name="one">
<testcase name="ROW-001-saves"><system-out>failure &lt;error&gt; a < b
error in the log
<failure message="not this">said</failure></system-out><system-err><![CDATA[<failure message="nor this"></failure>]]></system-err></testcase>
<testcase name="test_ROW_002_T1_opens" time="0.1"><properties><property name="x" value="y"/></properties></testcase>
<testcase name="ROW-002-T2 b"/><testcase name="HOS-001 x" time="1"></testcase><testcase name="RULE-001"/>
<testcase name="ROW-009 &amp; more"/><testcase name="ROW-008 x"/><testcase name="ROW-0091 not this row"><failure message="no"/></testcase>
</testsuite></testsuites>
XML
rr_send "pr-4-$H-2"; rd 3 4 "$RR_H"; grep -q "^report head pr-4-$H-2 read: alpha 7 passed, 1 failed, 0 errored, 0 skipped" "$T/out" || fail 'the odd shapes'
has ROW-001 red passed n/a kept; has ROW-002-T1 red passed missing kept; has ROW-009 n/a passed missing n/a; has ROW-008 n/a passed missing n/a; has DIF-001 n/a owed n/a kept 'owed again'
# each t3 and a class name read past: an error, a skipped case, a failure, setup: behind a class name, no case
cat > "$X" <<XML
<testsuite name="one"><testcase name="ROW-001"><failure message="Failed: setup: the door is shut&#10;more">t</failure></testcase>
<testcase name="ROW-002-T1"><failure message="AssertionError: ROW-002: promised &lt;a&gt;, saw &#x62;&#10;assert">t</failure></testcase>
<testcase name="ROW-002-T2"><skipped/></testcase><testcase name="HOS-001"><error message="boom"/></testcase><testcase name="RULE-001"/></testsuite>
XML
sed -i.b 's/^covers:.*/covers: RULE-001 0/; s/^retested:.*//' "$T/r/pr-4-$H-2/results.txt"; rm -f "$T/r/pr-4-$H-2/results.txt.b"; rr_send "pr-4-$H-2"; rd 3 4 "$RR_H"
has ROW-001 red setup n/a kept 'errored: setup: the door is shut'; has ROW-002-T1 red failed waits kept 'ROW-002: promised <a>, saw b'; has ROW-002-T2 red failed n/a kept 'skipped'; has HOS-001 red failed waits kept 'errored: boom'
has RULE-001 red failed n/a kept 'covers 0'; has ROW-009 n/a missing n/a n/a 'no case'; grep -q '1 failed.*' "$T/out" || fail 'the counts'
sed -i.b '/^covers:/d' "$T/r/pr-4-$H-2/results.txt"; rm -f "$T/r/pr-4-$H-2/results.txt.b"; rr_send "pr-4-$H-2"; rd 3 4 "$RR_H"; has RULE-001 red missing n/a kept 'no covers: line'
# red: errored, setup: behind a class name, a passing case, T2 by row, and a refused T2
rr_put red-3-2 results.txt "$(printf 'by: TM\ncommit: %s\nrows: ROW-001 ROW-002-T1 HOS-001' "$RR_RED")"; rr_put red-3-2 cases-alpha.xml "$(rr_cases ROW-001=err:boom ROW-002-T1=fail:Failed:\ setup:\ no\ door HOS-001=pass)"; rr_send red-3-2
rd 3 4 "$RR_H"; has ROW-001 no-red setup waits kept 'errored: boom'; has ROW-002-T1 no-red failed waits kept 'T2: errored: setup: no door'; has HOS-001 no-red failed waits kept 'T2: it passed'; has RULE-001 red missing n/a kept
rr_put red-3-3 results.txt "$(printf 'by: GR\ncommit: %s\nrows: ROW-001' "$RR_RED")"; rr_put red-3-3 cases-alpha.xml "$(rr_cases ROW-001=fail:x)"; rr_send red-3-3; rd 3 4 "$RR_H"; has ROW-001 missing setup n/a kept 'T2 red-3-3 refused'
rr_put red-3-3 results.txt "$(printf 'by: GR\ncommit: %s' "$RR_RED")"; rr_send red-3-3; rd 3 4 "$RR_H"; has HOS-001 no-red failed waits kept 'T2: it passed'; has ROW-002-T2 red failed n/a kept
git --git-dir=.vid/code update-ref -d refs/heads/vid-results/red-3-3; git --git-dir=.vid/code update-ref -d refs/heads/vid-results/red-3-2
# faults, in a new attempt over one with none: proven, the indented line, another row's, not proven, inconclusive, waits, extra
A3=pr-4-$H-3; mkdir -p "$T/r/$A3/faults"; cp "$T/r/$A/results.txt" "$T/r/$A/cases-alpha.xml" "$T/r/$A3/"; F=$T/r/$A3/faults
fp() { mkdir -p "$F/$1"; [ -z "$2" ] || echo "$2" > "$F/$1/control.txt"; shift 2; rr_cases "$@" > "$F/$OW/cases-alpha.xml"; }
OW=HOS-001; fp HOS-001 ROW-001 'HOS-001=fail:AssertionError: HOS-001: two&#10;  vid-forbidden-effect: HOS-001&#10;assert' ROW-001=pass
OW=ROW-002-T1; fp ROW-002-T1 ROW-001 'ROW-002-T1=fail:no page' ROW-001=pass
OW=ROW-001; fp ROW-001 ROW-009 'ROW-001=fail:gone' ROW-009=pass
rr_send "$A3"; rd 3 4 "$RR_H"; has HOS-001 red passed proven kept 'HOS-001: two; control ROW-001 passed'; has ROW-002-T1 red passed proven kept; has ROW-001 red passed 'proven extra' kept
OW=HOS-001; fp HOS-001 ROW-001 'HOS-001=fail:two&#10;vid-forbidden-effect: ROW-001' ROW-001=pass; OW=ROW-002-T1; fp ROW-002-T1 ROW-001 ROW-002-T1=pass ROW-001=pass; rr_send "$A3"; rd 3 4 "$RR_H"
has HOS-001 red passed inconclusive kept 'no vid-forbidden-effect line'; has ROW-002-T1 red passed not-proven kept
OW=HOS-001; fp HOS-001 ROW-001 'HOS-001=fail:x&#10;vid-forbidden-effect: HOS-001' ROW-001=fail:broke; OW=ROW-002-T1; fp ROW-002-T1 ROW-001 ROW-002-T1=err:boom ROW-001=pass; rr_send "$A3"; rd 3 4 "$RR_H"
has HOS-001 red passed inconclusive kept 'control ROW-001 did not pass under the fault'; has ROW-002-T1 red passed inconclusive kept 'errored: boom'
rm -rf "$F/HOS-001"; mkdir -p "$F/HOS-001"; echo 'the patch did not apply' > "$F/HOS-001/inconclusive.txt"; OW=ROW-002-T1; fp ROW-002-T1 ROW-001 ROW-002-T1=pass ROW-001=pass; rr_send "$A3"; rd 3 4 "$RR_H"
has HOS-001 red passed inconclusive kept 'the patch did not apply'; has ROW-002-T1 red passed not-proven kept 'control ROW-001 passed'; mkdir -p "$F/ROW-777" "$F/notes"; echo x > "$F/ROW-777/inconclusive.txt"; echo x > "$F/notes/inconclusive.txt"; rr_send "$A3"; rd 3 4 "$RR_H"; grep -qx 'fault folder for no row: notes' "$T/out" || fail 'a folder for no row'; has ROW-777 n/a missing 'waits extra' n/a 'no case'; rm -rf "$F/notes"
# XML once more: spaces round an attribute's =, text after a comment inside a failure; an extra fault on a row failing at T3
rm -rf "$F/ROW-777" "$F/ROW-001"; mkdir -p "$F/HOS-001" "$F/ROW-001"; rm -f "$F/HOS-001/inconclusive.txt"; echo ROW-001 > "$F/HOS-001/control.txt"; echo HOS-001 > "$F/ROW-001/control.txt"; rr_cases ROW-001=pass > "$T/h1"
cat > "$F/HOS-001/cases-alpha.xml" <<'XML'
<testsuite><testcase name = "HOS-001"><failure message = 'two'><!-- a note -->
  vid-forbidden-effect: HOS-001
</failure></testcase><testcase name="ROW-001"/></testsuite>
XML
rr_cases ROW-001=fail:gone HOS-001=pass > "$F/ROW-001/cases-alpha.xml"; rr_cases ROW-001=fail:bad ROW-002-T1=pass ROW-002-T2=pass HOS-001=pass RULE-001=pass ROW-009=pass > "$T/r/$A3/cases-alpha.xml"; rr_send "$A3"; rd 3 4 "$RR_H"
has ROW-001 red failed 'waits extra' kept bad; has HOS-001 red passed inconclusive kept 'control ROW-001 did not pass at T3'
cp "$T/r/$A/cases-alpha.xml" "$T/r/$A3/cases-alpha.xml"; rr_send "$A3"; rd 3 4 "$RR_H"; has HOS-001 red passed proven kept 'two; control ROW-001 passed'
# a control whose rule has covers 0 at T3 fails there; a journey's own fault folder serves its transitions
sed -i.b 's/^covers:.*/covers: RULE-001 0/' "$T/r/$A3/results.txt"; rm -f "$T/r/$A3/results.txt.b"; mkdir -p "$F/ROW-001"; echo RULE-001 > "$F/ROW-001/control.txt"; rr_cases ROW-001=fail:gone RULE-001=pass > "$F/ROW-001/cases-alpha.xml"; rr_send "$A3"; rd 3 4 "$RR_H"
has ROW-001 red passed 'inconclusive extra' kept 'control RULE-001 did not pass at T3'; sed -i.b 's/^covers:.*/covers: RULE-001 3/' "$T/r/$A3/results.txt"; rm -f "$T/r/$A3/results.txt.b"; echo HOS-001 > "$F/ROW-001/control.txt"; rr_cases ROW-001=fail:gone HOS-001=pass > "$F/ROW-001/cases-alpha.xml"
rm -rf "$F/ROW-002-T1"; mkdir -p "$F/ROW-002"; echo ROW-001 > "$F/ROW-002/control.txt"; rr_cases ROW-002-T1=fail:no\ page ROW-002-T2=fail:no\ page ROW-001=pass > "$F/ROW-002/cases-alpha.xml"; rr_send "$A3"; rd 3 4 "$RR_H"; has ROW-002-T1 red passed proven kept; has ROW-002-T2 red passed 'proven extra' kept
grep -q 'fault folder for no row' "$T/out" && fail "a journey's own folder taken for no row"
# a byte that is no character stops nothing; a refused sort report is said and carries no note
rr_put "$G" sorted.txt "$(printf 'by: SR\ncommit: %s\nROW-001 note it — caf\351 — a word' "$RR_H")"; rr_send "$G"; LANG=en_US.UTF-8 rd 3 4 "$RR_H"; LC_ALL=C grep -aq 'finding: note — caf' "$T/out" || fail 'a byte stopped the reader'
rr_put "$G" sorted.txt "$(printf 'by: TM\ncommit: %s' "$RR_H")"; rr_send "$G"; rd 3 4 "$RR_H"; grep -q "^report sort $G refused" "$T/out" || fail 'no refused sort report'
# the skeleton: no red, its fault with no control, its declared engines
S=pr-2-$H-1; rr_put "$S" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha beta\nenvironments: 1' "$RR_H")"; rr_put "$S" cases-alpha.xml "$(rr_cases ROW-009=pass)"; rr_put "$S" cases-beta.xml "$(rr_cases ROW-009=fail:only\ here)"; rr_send "$S"; rd 1 2 "$RR_H"; has ROW-009 n/a failed waits missing 'only here'
rr_put "$S" cases-beta.xml "$(rr_cases ROW-009=pass)"; rr_put "$S" faults/ROW-009/cases-alpha.xml "$(rr_cases ROW-009=fail:gone)"; rr_send "$S"; rd 1 2 "$RR_H"; has ROW-009 n/a passed proven missing gone
# a journey's folder proves the transitions it failed and says nothing of the others, missing if retested; failing none, it proves none
Z=pr-6-$(printf %s "$RR_H2" | cut -c1-12)-1; z() { rr_put "$Z" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 1\n%s' "$RR_H2" "$1")"; rr_put "$Z" cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_put "$Z" faults/ROW-002/control.txt ROW-001; rr_put "$Z" faults/ROW-002/cases-alpha.xml "$(rr_cases "${3:-ROW-002-T1=pass}" "ROW-002-T2=$2" ROW-001=pass)"; rr_send "$Z"; rd 3 6 "$RR_H2"; }
z '' fail:x; has ROW-002-T1 red passed n/a missing; z '' fail:x ROW-000=pass; has ROW-002-T1 red passed n/a missing; has ROW-002-T2 red passed 'proven extra' missing; z 'retested: ROW-002-T1' fail:x; has ROW-002-T1 red passed missing missing; z 'reached: ROW-001' pass; has ROW-002-T1 red passed not-proven missing; ! grep -q '^reached:' "$T/out" || fail 'a reached: line in the evidence'
# a journey beyond the ticket's rows: one line needing every transition's cases; retested, a line each; faulted and marked by its own id
sed -e 's/^- ROW-009$/- ROW-002/' -e '/^## Rows$/,/^## Engines$/{/ROW-002/d;}' -e 's/^- HOS-001: make/- ROW-001: make/' .vid/tw/out/issue-3.md > .vid/tw/out/issue-7.md
Q=pr-9-$H-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 1' "$RR_H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=pass ROW-002-T1=pass HOS-001=pass RULE-001=pass)"; rr_send "$Q"; rd 7 9 "$RR_H"; has ROW-002 n/a missing n/a n/a 'T2: no case'
rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=pass ROW-002-T1=pass ROW-002-T2=pass HOS-001=pass RULE-001=pass)"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 1\nretested: ROW-002' "$RR_H")"; rr_send "$Q"; rd 7 9 "$RR_H"; has ROW-002-T1 n/a passed missing n/a; has ROW-002-T2 n/a passed missing n/a
sed -e 's/^- ROW-002 marks: journey;/- ROW-002 marks: journey; protection;/' -e 's/^- ROW-002-T1 (of the journey ROW-002): make this transition/- ROW-002: make this row/' .vid/tw/out/issue-3.md > .vid/tw/out/issue-8.md
Q=pr-10-$H-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 1' "$RR_H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_put "$Q" faults/ROW-002-T1/control.txt ROW-001; rr_put "$Q" faults/ROW-002-T1/cases-alpha.xml "$(rr_cases 'ROW-002-T1=fail:gone&#10;vid-forbidden-effect: ROW-002' ROW-001=pass)"; rr_send "$Q"; rd 8 10 "$RR_H"; has ROW-002-T1 no-red passed proven missing; has ROW-002-T2 no-red passed missing missing
# R1: setup alone, in every engine and transition, before covers 0; a failure, another error or a skip beside it stays failed; a fault waits. R2: a row its own control
awk '{ print } /^- primary: alpha$/ { print "- also: beta" }' .vid/tw/out/issue-3.md > .vid/tw/out/issue-11.md; Q=pr-12-$H-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 0' "$RR_H")"
rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=err:setup:\ x ROW-002-T1=fail:setup:\ y ROW-002-T2=err:setup:\ y HOS-001=err:setup:\ z RULE-001=err:setup:\ z ROW-009=err:boom)"; rr_put "$Q" cases-beta.xml "$(rr_cases ROW-001=pass ROW-002-T1=pass ROW-002-T2=skip HOS-001=fail:no RULE-001=pass ROW-009=pass)"
rr_send "$Q"; rd 11 12 "$RR_H"; has ROW-001 no-red setup waits missing 'setup: x'; has ROW-002-T1 no-red setup waits missing; has ROW-002-T2 no-red failed waits missing; has HOS-001 no-red failed waits missing; has RULE-001 no-red setup waits missing 'covers 0'; has ROW-009 n/a failed n/a missing
Q=pr-13-$H-1; ow() { rr_put "$Q" "faults/$1/control.txt" "$2"; shift 2; rr_put "$Q" "faults/$OW/cases-alpha.xml" "$(rr_cases "$@")"; rr_send "$Q"; rd 3 13 "$RR_H"; }; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 1' "$RR_H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases $RR_ALL)"
OW=HOS-001; ow HOS-001 HOS-001 'HOS-001-a=fail:two&#10;vid-forbidden-effect: HOS-001' HOS-001-b=pass; has HOS-001 red passed proven missing 'another case of the row passed'; ow HOS-001 HOS-001 'HOS-001-a=fail:two&#10;vid-forbidden-effect: HOS-001'; has HOS-001 red passed inconclusive missing 'no case of its own passed under the fault'
ow HOS-001 HOS-001 'HOS-001-a=fail:two&#10;vid-forbidden-effect: HOS-001' HOS-001-b=err:boom HOS-001-c=pass; has HOS-001 red passed inconclusive missing 'errored: boom'; OW=ROW-002; ow ROW-002 ROW-002 ROW-002-T1=fail:x ROW-002-T2=pass; has ROW-002-T1 red passed proven missing 'another case of the row passed'
# R1 of 0.26.10.25.1: a breached test line with a fault folder is no open line; with none, or on a deploy-owed row, it is
Q=grade-pr-13-$H-1; rr_put "$Q" grade.txt "$(printf 'by: GR\ncommit: %s\nHOS-001 breached test — sees nothing\nROW-001 breached test — sees nothing\nDIF-001 breached test — owed\nROW-002-T2 breached product — wrong' "$RR_H")"; rr_send "$Q"; rd 3 13 "$RR_H"
! grep -qx 'open grade line: HOS-001' "$T/out" && grep -qx 'open grade line: ROW-001' "$T/out" && grep -qx 'open grade line: DIF-001' "$T/out" && grep -qx 'open grade line: ROW-002-T2' "$T/out" || fail 'a weak-test line was not read as it should be'
# v0.26.10.25.2 R2, R3, R4: one grade. At a later head, a later grade is not read; the list holds every line not kept, closed or not; a weak-test line with no fault folder is closed, a deploy-owed one and any other stand open
H2=$(printf %s "$RR_H2" | cut -c1-12); Q=pr-13-$H2-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 1' "$RR_H2")"; rr_put "$Q" cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_send "$Q"; Q=grade-pr-13-$H2-1; rr_put "$Q" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-009 breached test — a later reader\nfinding: bug — a later finding' "$RR_H2")"; GIT_COMMITTER_DATE='2031-01-01T00:00:00Z' rr_send "$Q"; rd 3 13 "$RR_H2"
grep -qx "report grade grade-pr-13-$H-1 read" "$T/out" || fail 'the first grade was not the one read'; ! grep -q 'a later\|list: ROW-009' "$T/out" || fail 'a later grade was read'; for r in HOS-001 ROW-001 DIF-001 ROW-002-T2; do grep -qx "list: $r" "$T/out" || fail "no list line for $r"; done
! grep -qx 'open grade line: ROW-001' "$T/out" && grep -qx 'open grade line: DIF-001' "$T/out" && grep -qx 'open grade line: ROW-002-T2' "$T/out" || fail 'a later head read the weak-test lines wrongly'
Q=grade-pr-13-$H-2; rr_put "$Q" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-001 kept — the newer attempt' "$RR_H")"; GIT_COMMITTER_DATE='2032-01-01T00:00:00Z' rr_send "$Q"; rd 3 13 "$RR_H2"; grep -qx "report grade $Q read" "$T/out" && ! grep -q '^list: ' "$T/out" || fail 'the first head'"'"'s newest attempt was not read alone'
# a reached ticket: read as regression rows, a deploy-owed one owed; it asks no T2 and no T5
Q=pr-6-$H-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s' "$RR_H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=pass)"; rr_send "$Q"; rd 5 6 "$RR_H"; has ROW-001 n/a passed n/a n/a; has DIF-001 n/a owed n/a n/a; [ "$(grep -c "^ROW-001$TAB" "$T/out")" = 1 ] || fail 'a reached row twice'; grep -qE '^report (T2|grade) none' "$T/out" && fail 'a reached ticket shown a T2 or a grade'
# R7: every head report, an older head's line kept, and no older head in a newer evidence file
Q=pr-4-$(printf %s "$RR_H2" | cut -c1-12)-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\nstand-in: tide — a stub — the real sea' "$RR_H2")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=fail:later)"; rr_send "$Q"; rd 3 4 "$RR_H2"
has ROW-001 red failed n/a missing later; grep -qx "$H${TAB}stand-in: clock — a fake — the real one" .vid/results/stand-in.txt || fail 'an older head lost its stand-in line'; grep -q 'the real sea$' .vid/results/stand-in.txt || fail 'a newer line is missing'
rd 3 4 "$RR_H2"; [ "$(wc -l < .vid/results/stand-in.txt | tr -d ' ')" = 2 ] || fail 'a stand-in line twice'
sed 's/the real sea/the real tide/' "$T/r/$Q/results.txt" > "$T/l"; cat "$T/l" > "$T/r/$Q/results.txt"; rr_send "$Q"; rd 3 4 "$RR_H2"; grep -q 'the real sea' .vid/results/stand-in.txt && fail "a superseded attempt's stand-in line was kept"; grep -q 'the real tide' .vid/results/stand-in.txt || fail 'a newer attempt lost its line'
sed 's/the real tide/the real moon/' "$T/r/$Q/results.txt" > "$T/l"; cat "$T/l" > "$T/r/$Q/results.txt"; cp "$T/r/$Q/results.txt" "$T/l"; : > "$T/r/$Q/cases-alpha.xml"; rr_send "$Q"; rd 3 4 "$RR_H2"; grep -q 'the real moon' .vid/results/stand-in.txt && fail "a refused report's stand-in line was kept"
# v0.26.10.25.3 R11: every engine the head report holds. Not asked, beta: a failure or another error fails its row, a split; setup:, a skip or no case could not run, one line
Q=pr-15-$H-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 3' "$RR_H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_put "$Q" cases-beta.xml "$(rr_cases ROW-001=fail:only\ beta ROW-002-T1=err:setup:\ no\ door ROW-002-T2=pass RULE-001=err:boom ROW-009=skip)"; rr_send "$Q"; rd 3 15 "$RR_H"
has ROW-001 red failed n/a x 'only beta in beta'; has RULE-001 red failed n/a x 'errored: boom in beta'; has ROW-002-T1 red passed missing x; has HOS-001 red passed missing x; has ROW-009 n/a passed n/a x
grep -qx "split${TAB}ROW-001${TAB}alpha${TAB}beta" "$T/out" && grep -qx "split${TAB}RULE-001${TAB}alpha${TAB}beta" "$T/out" && [ "$(grep -c '^split' "$T/out")" = 2 ] || fail 'the split lines'
grep -qx 'engine beta: 3 could not run' "$T/out" && grep -q "^report head $Q read: alpha 6 passed.*; beta 1 passed" "$T/out" || fail 'the engine line, or the engines read'
# once a row has split, every declared engine is asked of an open ticket: a report without beta is refused, and beta's setup: and no case now count as asked
printf 'engines alpha beta | stand-in: results reader\nengine-split ROW-001 | stand-in: alpha beta\n' > .vid/tw/handed; rd 3 15 "$RR_H"; has ROW-002-T1 red setup waits x; has HOS-001 red missing waits x 'no case in beta'; ! grep -q '^engine beta' "$T/out" || fail 'an asked engine given the engine line'
Q=pr-15-$H2-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 3' "$RR_H2")"; rr_put "$Q" cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_send "$Q"; rd 3 15 "$RR_H2"; grep -q "^report head $Q refused no whole cases file for beta" "$T/out" || fail 'beta not asked once split'; rm -f .vid/tw/handed
# R12: the setup: errors of the pull request's head reports, each head's newest attempt alone
Q=pr-16-$H; rr_put "$Q-1" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 3' "$RR_H")"; rr_put "$Q-1" cases-alpha.xml "$(rr_cases ROW-001=err:setup:\ a ROW-002-T1=err:setup:\ b HOS-001=err:setup:\ c ROW-009=err:boom)"; rr_send "$Q-1"; rd 3 16 "$RR_H"; grep -qx 'setup errors alpha: 3 cases over 1 runs' "$T/out" || fail 'the setup count of one run'
mkdir -p "$T/r/$Q-2"; cp "$T/r/$Q-1/results.txt" "$T/r/$Q-2/"; rr_put "$Q-2" cases-alpha.xml "$(rr_cases ROW-001=err:setup:\ a ROW-002-T1=fail:setup:\ b HOS-001=pass)"; rr_send "$Q-2"; Q=pr-16-$H2-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 3' "$RR_H2")"; rr_put "$Q" cases-alpha.xml "$(rr_cases ROW-001=err:setup:\ a ROW-002-T1=err:setup:\ b ROW-002-T2=err:setup:\ b)"; rr_send "$Q"
rd 3 16 "$RR_H2"; grep -qx 'setup errors alpha: 5 cases over 2 runs' "$T/out" || fail 'the setup count over the newest attempts'
# R13: a fault folder for a row the ticket does not list is read, as a regression row: a break its test misses reads not proven, one it sees proven
Q=pr-17-$H-1; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\ncovers: RULE-001 3' "$RR_H")"; rr_put "$Q" cases-alpha.xml "$(rr_cases $RR_ALL ROW-008=pass)"; rr_put "$Q" faults/ROW-008/control.txt ROW-009; rr_put "$Q" faults/ROW-008/cases-alpha.xml "$(rr_cases ROW-008=pass ROW-009=pass)"; rr_send "$Q"; rd 3 17 "$RR_H"
has ROW-008 n/a passed 'not-proven extra' x 'still passes'; ! grep -q 'fault folder for no row' "$T/out" || fail 'a folder on an unlisted row left unread'
rr_put "$Q" faults/ROW-008/cases-alpha.xml "$(rr_cases ROW-008=fail:gone ROW-009=pass)"; rr_send "$Q"; rd 3 17 "$RR_H"; has ROW-008 n/a passed 'proven extra' x
# no decision word of its own, across every evidence file written
H3=$(cat .vid/results/pr-*.txt | grep -nE '\b(accepted|failing|held)\b' | head -n 1 || true); [ -z "$H3" ] || fail "a decision word: $H3"
# the page
sh "$R" page ".vid/results/pr-4-$H.txt" > "$T/out" 2>&1 || fail 'no page'; [ -f ".vid/results/pr-4-$H.html" ] && grep -q 'ROW-002-T1' ".vid/results/pr-4-$H.html" || fail 'the page lacks its rows'
# R8: declare, and nothing for a report that names neither; the writer's and admission's reading follow
printf 'candidate 0 | stand-in: x\nengines old | stand-in: x\n' > .vid/tw/handed; sh "$R" declare --pr 2 --head "$RR_H" > "$T/out" 2>&1 || fail 'declare failed'
[ "$(grep -c '^engines ' .vid/tw/handed)" = 1 ] && grep -qx 'engines alpha beta | stand-in: results reader' .vid/tw/handed && grep -qx 'candidate 0 | stand-in: x' .vid/tw/handed || fail 'the handed record'
grep -qx 'stacks=1' .vid/budget && grep -qx 'unverified-rows=60' .vid/budget || fail 'the budget record'
cp .vid/tw/handed "$T/handed"; cp .vid/budget "$T/budget"; sh "$R" declare --pr 6 --head "$RR_H" > "$T/out" 2>&1; cmp -s .vid/tw/handed "$T/handed" && cmp -s .vid/budget "$T/budget" || fail 'declare wrote for a report naming neither'
. "$CHECKS/selftest/fixtures/tw-toy.sh"; cp -R .vid/code "$T/code-copy"; tw_toy "$T/toy"; cp -R "$T/code-copy" .vid/code; printf 'stacks=1\nother=1\n' > .vid/budget
Q=pr-8-$H-1; (cd "$T/p"; rr_put "$Q" results.txt "$(printf 'by: TM\ncommit: %s\nengines: chromium firefox\nenvironments: 3' "$RR_H")"; rr_send "$Q"; git --git-dir=.vid/code push -q "$T/toy/.vid/code" "vid-results/$Q")
sh "$R" declare --pr 8 --head "$RR_H" > "$T/out" 2>&1 || fail 'declare in the toy failed'; sh "$CHECKS/writer.sh" gate > "$T/out" 2>&1 || fail 'the writer refused the handed file'
tw_start S01 && ! grep -q 'without a recorded' "$T/start" || { cat "$T/start" > "$T/out"; fail 'admission did not read the budget'; }; grep -qx 'other=1' .vid/budget || fail 'another budget key was lost'
exit 0
