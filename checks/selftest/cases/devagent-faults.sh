#!/bin/sh
# Purpose: selftest case — DevAgent's blind copy, fault run, head grade and sort report (v0.26.10.24.4 R2, R4, R5, v0.26.10.24.7), on the fixture project
# with a local bare repository as origin. The blind copy is one commit holding the head's tree, each one fresh, and a patch made
# there applies to the head; a stub record with repo: alone serves. A fault makes its row's case fail and its control's pass, in
# faults/<row>/, with control.txt, in a new attempt holding T3's files unchanged; a patch that will not apply, a run with no report
# twice and a run stopped by its watcher give inconclusive.txt, and the next fault still runs; a test that stays green under its
# fault is reported green; a fault with no control has no control.txt; a later fault run keeps the folders that stand; nothing is left
# running and the head is untouched; with no head report nothing runs. A grade.txt and a sorted.txt are pushed alone, labelled by role; one whose
# first line is not by: GR, whose commit is not on origin, or that is not this ask's commit is not. Skips where devagent/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
R=$CHECKS/../devagent/test-manager/run.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-faults: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T"
S=$T/work/dev-setup.txt; H=$(printf %s "$SP_C" | cut -c1-12); A=pr-1-$H; O="git -C $T/origin.git"
run() { RC=0; sh "$R" run --setup "$S" --commit "$SP_C" "$@" > "$T/out" 2>&1 || RC=$?; }
has() { $O rev-parse -q --verify "refs/heads/vid-results/$1" > /dev/null; }
blob() { $O rev-parse "vid-results/$1:$2"; }
tree() { $O ls-tree -r --name-only "vid-results/$1" | tr '\n' ' '; }
# no head report, nothing runs
printf 'ROW-001\tnone.patch\tnone\tROW-001\n' > work/f0.txt; RC=0; sh "$R" run --setup "$S" --commit "$SP_C" --ask "$A" --faults work/f0.txt > out 2>&1 || RC=$?
[ "$RC" = 1 ] && grep -q 'no head report' out && ! has "$A-1" || fail 'a fault run with no head report ran'
run --ask "$A" --select 'ROW-00[156]'; [ "$RC" = 0 ] || fail "T3 exited $RC"
# R2: the blind copy, from a stub record
printf 'repo: %s/origin.git\n' "$T" > work/stub.txt
B=$(sh "$R" blind --setup work/stub.txt --commit "$SP_C"); B2=$(sh "$R" blind --setup "$S" --commit "$SP_C")
[ "$B" != "$B2" ] && [ -d "$B" ] || fail 'a blind copy is not fresh'; case $B in "$T"/work/*|/private"$T"/work/*) ;; *) fail "the blind copy is at $B" ;; esac
[ "$(git -C "$B" rev-list --count HEAD)" = 1 ] || fail 'the blind copy holds more than one commit'
[ "$(git -C "$B" rev-parse 'HEAD^{tree}')" = "$($O rev-parse "$SP_C^{tree}")" ] || fail "the blind copy's tree is not the head's"
RC=0; sh "$R" blind --setup work/stub.txt --commit 0123456789012345678901234567890123456789 > out 2>&1 || RC=$?; [ "$RC" = 1 ] || fail 'a blind copy of a commit not on origin'
echo bad > "$B/product.txt"; git -C "$B" diff > work/p5.patch; git -C "$B" checkout -q product.txt
printf 'diff --git a/nothing.txt b/nothing.txt\n--- a/nothing.txt\n+++ b/nothing.txt\n@@ -1 +1 @@\n-a\n+b\n' > work/no.patch
cp "$S" work/w.txt; echo 'silent-seconds: 3' >> work/w.txt; S=$T/work/w.txt
# an empty list runs nothing; R4: proven, no apply, no report twice, silent, green under its fault, no control, and a last line with no line break
: > work/f3.txt; RC=0; sh "$R" run --setup "$S" --commit "$SP_C" --ask "$A" --faults work/f3.txt > out 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'no needed fault' out && ! has "$A-2" || fail 'an empty list ran'
{ printf 'ROW-005\tp5.patch\tROW-001\tROW-00[15]\n'; printf 'ROW-003\tno.patch\tROW-001\tROW-001\n'; printf 'ROW-004\tp5.patch\tROW-001\tnoreport\n'
  printf 'ROW-002\tp5.patch\tROW-001\tquiet\n'; printf 'ROW-006\t%s/work/p5.patch\tROW-001\tROW-00[16]\n' "$T"; printf 'ROW-001\tp5.patch\tnone\tROW-001'; } > work/f1.txt
run --ask "$A" --faults work/f1.txt; [ "$RC" = 0 ] || fail "the fault run exited $RC"; has "$A-2" || fail 'no new attempt'
for f in results.txt cases-alpha.xml cases-beta.xml; do [ "$(blob "$A-1" "$A-1/$f")" = "$(blob "$A-2" "$A-2/$f")" ] || fail "T3's $f changed"; done
[ "$($O rev-list --count "vid-results/$A-2")" = 1 ] && $O log -1 --format=%B "vid-results/$A-2" | grep -qx 'Role: TM' || fail 'the report is not one commit labelled Role: TM'
show() { $O show "vid-results/$1:$2"; }; X=$(show "$A-2" "$A-2/faults/ROW-005/cases-alpha.xml")
printf %s "$X" | grep -q 'name="ROW-005-value".*<failure message="ROW-005: promised good, saw bad"' || fail 'the fault did not fail its row'
printf %s "$X" | grep -q 'name="ROW-001-home" time="[0-9]*"/>' || fail 'the control did not pass'
[ "$(show "$A-2" "$A-2/faults/ROW-005/control.txt")" = ROW-001 ] || fail 'control.txt does not name the control'
show "$A-2" "$A-2/faults/ROW-003/inconclusive.txt" | grep -q 'did not apply' || fail 'a patch that will not apply'
[ "$(show "$A-2" "$A-2/faults/ROW-004/inconclusive.txt")" = 'no results report: alpha wrote none, twice' ] || fail 'no report twice'
show "$A-2" "$A-2/faults/ROW-002/inconclusive.txt" | grep -q 'silent for 3s' || fail 'a silent fault run'
show "$A-2" "$A-2/faults/ROW-006/cases-alpha.xml" | grep -q 'name="ROW-006-weak" time="[0-9]*"/>' || fail 'a test green under its fault is not reported green'
tree "$A-2" | grep -q 'faults/ROW-001/control.txt' && fail 'a fault with no control has control.txt'; tree "$A-2" | grep -q 'faults/ROW-003/control.txt' && fail 'an inconclusive fault has control.txt'
tree "$A-2" | grep -q 'faults/ROW-001/cases-alpha.xml' || fail 'the fault with no control has no cases'
for l in 'fault ROW-005: 1 passed, 1 failed, 0 errored, 0 skipped' 'broken: 1 ROW-005: promised good, saw bad' 'leftovers: none'; do grep -qxF "$l" out || fail "the result lacks: $l"; done
kill -0 "$(cat product.was)" 2>/dev/null && fail 'the product is still running'
[ "$($O rev-parse main)" = "$SP_C" ] || fail 'the head moved'
# a later fault run replaces its row's folder and keeps the others
printf 'ROW-003\tp5.patch\tROW-001\tROW-00[14]\n' > work/f2.txt; run --ask "$A" --faults work/f2.txt; has "$A-3" || fail "the second fault run exited $RC"
[ "$(blob "$A-2" "$A-2/faults/ROW-005/cases-alpha.xml")" = "$(blob "$A-3" "$A-3/faults/ROW-005/cases-alpha.xml")" ] || fail 'a fault that stands was not carried'
tree "$A-3" | grep -q 'faults/ROW-003/inconclusive.txt' && fail "a fault's new run left its old folder"
# R12 (v0.26.10.25.3): a fault run is no head run: the pull request's setup count holds T3 alone
[ "$(awk '$1 == "pr-1" { print $2, $3 }' work/setup-errors 2>/dev/null)" = '0 1' ] || fail "a fault run counted as a head run: $(cat work/setup-errors 2>/dev/null)"
# the head grade
G=grade-pr-1-$H; gr() { RC=0; sh "$R" grade --setup "$S" --ask "$G" --file "$1" > out 2>&1 || RC=$?; }
printf 'by: GR\ncommit: %s\nROW-001 breached test — a thing\nROW-002 kept — seen\nROW-003 unclear — which?\nfinding: bug — a stray\n' "$SP_C" > s.txt; gr s.txt; [ "$RC" = 0 ] && has "$G-1" || fail "a grade exited $RC"
[ "$(tree "$G-1")" = "$G-1/grade.txt " ] || fail "the grade's tree: $(tree "$G-1")"; $O log -1 --format=%B "vid-results/$G-1" | grep -qx 'Role: GR' || fail 'the grade has no Role: GR'
printf 'commit: %s\nby: GR\n' "$SP_C" > g2.txt; gr g2.txt; [ "$RC" = 1 ] && ! has "$G-2" || fail 'a grade not beginning by: GR was pushed'
# v0.26.10.25.2 R1: two readers joined, one line a row, the findings of both; each refusal pushes nothing
jn() { printf 'by: GR\ncommit: %s\n%s\n' "$SP_C" "$2" > "$1"; }; g2() { RC=0; sh "$R" grade --setup "$S" --ask "$G" --file a.txt --second b.txt > "$T/out" 2>&1 || RC=$?; }; K=2
ok2() { g2; [ "$RC" = 0 ] && has "$G-$K" || fail "a join exited $RC"; $O show "vid-results/$G-$K:$G-$K/grade.txt" > "$T/j"; K=$((K + 1)); }; ln() { grep -qxF -- "$1" "$T/j" || { cat "$T/j" > "$T/out"; fail "no joined line: $1"; }; }; re() { g2; [ "$RC" = 1 ] && grep -q "$1" "$T/out" && ! has "$G-$K" || fail "not refused: $1"; }
jn a.txt 'ROW-001 kept — a
ROW-002 kept — b
ROW-003 breached test — c
ROW-004 kept — d
ROW-005 breached test — same
ROW-006 unclear — e
ROW-007 breached test — f
ROW-008 breached test — g
ROW-009 unclear — h
finding: bug — a stray
finding: rule — one'; jn b.txt 'ROW-001 kept — other words
ROW-002 breached product — b2
ROW-003 kept — c2
ROW-004 unclear — d2
ROW-005 breached test — same
ROW-006 breached product — e2
ROW-007 breached test — f2
ROW-008 unclear — g2
ROW-009 breached test — h2
finding: bug — a stray
finding: rule — two'; ok2
ln 'ROW-001 kept — a'; ln 'ROW-002 breached product — b2'; ln 'ROW-003 breached test — c'; ln 'ROW-004 unclear — d2'; ln 'ROW-005 breached test — same'; ln 'ROW-006 breached product — e2 — also: unclear — e'; ln 'ROW-007 breached test — f — also: breached test — f2'; ln 'ROW-008 breached test — g — also: unclear — g2'; ln 'ROW-009 breached test — h2 — also: unclear — h'; [ "$(head -n 2 "$T/j" | tail -n 1)" = "commit: $SP_C" ] && [ "$(head -n 1 "$T/j")" = 'by: GR' ] || fail 'the join has no head'; [ "$(grep -c '^ROW-' "$T/j")" = 9 ] && [ "$(grep -c '^finding: ' "$T/j")" = 4 ] || fail 'the join is not one line a row, and the findings of both'
cp b.txt c.txt; printf 'by: GR\ncommit: another\nROW-001 kept — a\n' > b.txt; re 'different commits'; jn b.txt 'ROW-001 kept — a'; re 'different rows'; jn b.txt 'ROW-001 kept — a
ROW-777 kept — a
ROW-003 kept — a
ROW-004 kept — a
ROW-005 kept — a
ROW-006 kept — a
ROW-007 kept — a
ROW-008 kept — a
ROW-009 kept — a'; re 'different rows'; cp c.txt b.txt; printf 'ROW-010 fine — no verdict\n' >> b.txt; re 'no verdict'; cp c.txt b.txt; printf 'ROW-001 kept — again\n' >> b.txt; re 'twice'; cp c.txt b.txt; sed '1s/.*/by: TM/' c.txt > b.txt; re 'begin by: GR'; rm -f b.txt; re 'no grade file'
# v0.26.10.25.2 R6: reached: is no report line
RC=0; sh "$R" run --setup "$S" --commit "$SP_C" --ask "$A" --line 'reached: ROW-001' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q 'not a report line' "$T/out" || fail 'a reached: line was taken'
# the sort report: the lines of to-sort.txt one for one
G=sort-pr-1-$H; gr() { RC=0; sh "$R" sort --setup "$S" --ask "$G" --lines l.txt --file "$1" > out 2>&1 || RC=$?; }
printf 'by: DM\ncommit: %s\nROW-001 breached test — a thing\nROW-003 unclear — which?\n' "$SP_C" > l.txt; printf 'by: SR\ncommit: %s\nROW-001 test it — a reason — ROW-001 breached test — a thing\nROW-003 note it — why — ROW-003 unclear — which?\n' "$SP_C" > g.txt; gr g.txt; [ "$RC" = 0 ] && has "$G-1" || fail "a sort exited $RC: $(cat out)"
[ "$(tree "$G-1")" = "$G-1/sorted.txt " ] || fail "the sort's tree: $(tree "$G-1")"; $O log -1 --format=%B "vid-results/$G-1" | grep -qx 'Role: SR' || fail 'the sort has no Role: SR'
sed 's/^by: SR/by: GR/' g.txt > g2.txt; gr g2.txt; [ "$RC" = 1 ] && ! has "$G-2" || fail 'a sort not beginning by: SR was pushed'
sed "s/^commit: .*/commit: $H$(printf %028d 0)/" g.txt > g3.txt; gr g3.txt; [ "$RC" = 1 ] && ! has "$G-2" || fail 'a sort of a commit not on origin was pushed'
{ cat g.txt; echo 'ROW-002 drop it — mine — ROW-002 kept — seen'; } > g4.txt; gr g4.txt; [ "$RC" = 1 ] && grep -q 'one for one' out && ! has "$G-2" || fail 'a sort with a line added was pushed'; sed 's/a thing/a changed thing/' g.txt > g5.txt; gr g5.txt; [ "$RC" = 1 ] && ! has "$G-2" || fail 'a sort with a line changed was pushed'
# a fault line's bare names go into the record's select-form: too
{ cat "$S"; echo 'select-form: ROW-00<words>'; } > work/sf.txt; printf 'ROW-006\tp5.patch\tROW-001\t[16]\n' > work/f9.txt; RC=0; sh "$R" run --setup work/sf.txt --commit "$SP_C" --ask "$A" --faults work/f9.txt > out 2>&1 || RC=$?
grep -q 'pass 1, selection ROW-00\[16\], at' "$(ls -td work/runs/*/ | head -n 1)log" || fail "the fault line did not take the record's form: $(cat out)"
exit 0
