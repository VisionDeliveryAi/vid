#!/bin/sh
# Purpose: selftest case — fetching and the form of a report (v0.26.10.24.5 R2, R3). On the fake gh, results-fetch clones .vid/code and
# fetches every head and vid-results/* branch, again when more come. On made-up reports, a good T2, head report and sort report
# pass; each refusal the format names is printed with its reason, exit 1: a branch holding more than its folder, a commit not the one
# asked for, a commit the repository lacks, a first line naming the wrong role, the role's file absent, a head report with no
# cases file for an asked engine, or a fault folder's, a cases file cut short, a skeleton's head report with none of its own declared engines. A newer attempt
# replaces an older, T2 goes by row, and nothing crashes on an empty branch, an unknown id or an empty file. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "results-form: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
R=$CHECKS/results.sh; rr_project
ck() { RC=0; sh "$R" check "$@" > "$T/out" 2>&1 || RC=$?; }
good() { ck "$@"; [ "$RC" = 0 ] && grep -qx "ok $1" "$T/out" || fail "not ok: $*"; }
bad() { w=$1; shift; ck "$@"; [ "$RC" = 1 ] && grep -q "^refused .*$w" "$T/out" || fail "not refused ($w): $*"; }
rr_good; A=pr-4-$RR_H12-1; G=sort-pr-4-$RR_H12-1
good red-3-1 --ticket 3; good "$A" --ticket 3; good "$A" --ticket 3 --commit "$RR_H"; good "$G" --ticket 3 --commit "$RR_H"
# a retested: line holds row ids alone; a reached: line is read by nothing
cp "$T/r/$A/results.txt" "$T/rg"; rr_put "$A" results.txt "$(cat "$T/rg"; echo 'retested: ROW-001 — now reads it whole')"; rr_send "$A"; bad 'more than row ids' "$A" --ticket 3; rr_put "$A" results.txt "$(cat "$T/rg"; echo 'retested: ROW-001 ROW-002-T1')"; rr_send "$A"; good "$A" --ticket 3; rr_put "$A" results.txt "$(cat "$T/rg")"; rr_send "$A"
# a commit not the one asked for, or that the repository lacks
bad 'not the one asked for' "$A" --ticket 3 --commit "$RR_H2"; bad 'not the one asked for' "$G" --ticket 3 --commit "$RR_H2"
Z=0123456789012345678901234567890123456789
sed "s/$RR_H/$RR_H2/" "$T/r/$A/results.txt" > "$T/l"; rr_put pr-4-$RR_H12-2 results.txt "$(cat "$T/l")"; cp "$T/r/$A/cases-alpha.xml" "$T/r/pr-4-$RR_H12-2/"; rr_send pr-4-$RR_H12-2
bad "not this report's head" pr-4-$RR_H12-2 --ticket 3
sed "s/$RR_H/$Z/" "$T/r/$A/results.txt" > "$T/l"; rr_put pr-4-$RR_H12-3 results.txt "$(cat "$T/l")"; cp "$T/r/$A/cases-alpha.xml" "$T/r/pr-4-$RR_H12-3/"; rr_send pr-4-$RR_H12-3; bad "lacks the commit $Z" pr-4-$RR_H12-3 --ticket 3 --commit "$RR_H"
sed "s/$RR_RED/$Z/" "$T/r/red-3-1/results.txt" > "$T/l"; rr_put red-3-2 results.txt "$(cat "$T/l")"; cp "$T/r/red-3-1/cases-alpha.xml" "$T/r/red-3-2/"; rr_send red-3-2; bad "lacks the commit $Z" red-3-2 --ticket 3
git --git-dir=.vid/code update-ref -d refs/heads/vid-results/red-3-2
# the wrong role, and the role's file absent
sed 's/^by: TM/by: GR/' "$T/r/$A/results.txt" > "$T/l"; rr_put pr-4-$RR_H12-4 results.txt "$(cat "$T/l")"; cp "$T/r/$A/cases-alpha.xml" "$T/r/pr-4-$RR_H12-4/"; rr_send pr-4-$RR_H12-4; bad 'not by: TM' pr-4-$RR_H12-4 --ticket 3
sed 's/^by: SR/by: TM/' "$T/r/$G/sorted.txt" > "$T/l"; rr_put sort-pr-4-$RR_H12-2 sorted.txt "$(cat "$T/l")"; rr_send sort-pr-4-$RR_H12-2; bad 'not by: SR' sort-pr-4-$RR_H12-2 --ticket 3
good grade-pr-4-$RR_H12-1 --ticket 3 --commit "$RR_H"; sed 's/^by: GR/by: TM/' "$T/r/grade-pr-4-$RR_H12-1/grade.txt" > "$T/l"; rr_put grade-pr-4-$RR_H12-2 grade.txt "$(cat "$T/l")"; rr_send grade-pr-4-$RR_H12-2; bad 'not by: GR' grade-pr-4-$RR_H12-2 --ticket 3; rr_put sort-pr-4-$RR_H12-3 note.txt x; rr_send sort-pr-4-$RR_H12-3; bad 'no sorted.txt' sort-pr-4-$RR_H12-3 --ticket 3; sed 's/note it/maybe/' "$T/r/$G/sorted.txt" > "$T/l"; rr_put sort-pr-4-$RR_H12-4 sorted.txt "$(cat "$T/l")"; rr_send sort-pr-4-$RR_H12-4; bad 'none of the four words' sort-pr-4-$RR_H12-4 --ticket 3
rr_put pr-4-$RR_H12-5 cases-alpha.xml "$(rr_cases ROW-001=pass)"; rr_send pr-4-$RR_H12-5; bad 'no results.txt' pr-4-$RR_H12-5 --ticket 3
# more than its folder
RR_EXTRA=stray.txt; rr_send "$A"; RR_EXTRA=''; bad 'more than its folder: stray.txt' "$A" --ticket 3; rr_send "$A"; good "$A" --ticket 3
# cases files: none for an asked engine, cut short, empty
rr_put pr-4-$RR_H12-6 results.txt "$(cat "$T/r/$A/results.txt")"; rr_send pr-4-$RR_H12-6; bad 'no whole cases file for alpha' pr-4-$RR_H12-6 --ticket 3
head -c 60 "$T/r/$A/cases-alpha.xml" > "$T/r/pr-4-$RR_H12-6/cases-alpha.xml"; rr_send pr-4-$RR_H12-6; bad 'no whole cases file for alpha' pr-4-$RR_H12-6 --ticket 3
: > "$T/r/pr-4-$RR_H12-6/cases-alpha.xml"; rr_send pr-4-$RR_H12-6; bad 'no whole cases file for alpha' pr-4-$RR_H12-6 --ticket 3
# the skeleton: its own declared engines, every one with a file; T2 and a report's faults need the primary alone
S=pr-2-$RR_H12-1; rr_put "$S" results.txt "$(printf 'by: TM\ncommit: %s\nenvironments: 1' "$RR_H")"; rr_put "$S" cases-alpha.xml "$(rr_cases ROW-009=pass)"; rr_send "$S"; bad 'declares no engines' "$S" --ticket 1
rr_put "$S" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha beta\nenvironments: 1' "$RR_H")"; rr_send "$S"; bad 'no whole cases file for beta' "$S" --ticket 1
cp "$T/r/$S/cases-alpha.xml" "$T/r/$S/cases-beta.xml"; rr_send "$S"; good "$S" --ticket 1
# a fault folder: a whole primary cases file, or inconclusive.txt
rr_put pr-4-$RR_H12-6 cases-alpha.xml "$(rr_cases $RR_ALL)"; rr_put pr-4-$RR_H12-6 faults/HOS-001/control.txt ROW-001; rr_send pr-4-$RR_H12-6; bad 'in faults/HOS-001' pr-4-$RR_H12-6 --ticket 3
rr_put pr-4-$RR_H12-6 faults/HOS-001/inconclusive.txt 'no way in'; rr_send pr-4-$RR_H12-6; good pr-4-$RR_H12-6 --ticket 3
rm -rf "$T/r/pr-4-$RR_H12-6/faults"; : > "$T/r/pr-4-$RR_H12-6/cases-alpha.xml"; rr_send pr-4-$RR_H12-6
# an unknown id, an empty branch, nothing crashes
bad 'no branch' red-3-9 --ticket 3; bad 'not a T2' other-1 --ticket 3
rr_put red-3-3 a/b x; rr_send red-3-3; git --git-dir=.vid/code update-ref refs/heads/vid-results/red-3-4 "$RR_H"; bad 'more than its folder' red-3-4 --ticket 3; git --git-dir=.vid/code update-ref -d refs/heads/vid-results/red-3-4
git --git-dir=.vid/code update-ref -d refs/heads/vid-results/red-3-3
RC=0; sh "$R" read --ticket 3 --pr 4 --head "$RR_H" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "read exited $RC on broken reports"
grep -q "^report head pr-4-$RR_H12-6 refused " "$T/out" || fail 'the newest attempt was not the one read'
# R2, on the fake gh
mkdir -p "$T/q/.vid/tw"; cd "$T/q"; : > .vid/RUN-STATE.md; printf 'repo: owner/code\n' > .vid/tw/settings
git clone -q --bare "$T/p/.vid/code" "$T/code.git"; gh_fake; sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || fail 'results-fetch failed'
[ "$(git --git-dir=.vid/code rev-parse "vid-results/$A")" = "$(git --git-dir="$T/code.git" rev-parse "vid-results/$A")" ] && git --git-dir=.vid/code cat-file -e "$RR_H2^{commit}" || fail 'no report or head fetched'
# a new report, built on main with its folder alone (0.26.10.28.4: a branch holding the code is refused, results-copy.sh)
rb=$(printf 'by: TM\n' | git --git-dir="$T/code.git" hash-object -w --stdin); rt=$(printf '100644 blob %s\tresults.txt\n' "$rb" | git --git-dir="$T/code.git" mktree); rt=$(printf '040000 tree %s\tred-3-7\n' "$rt" | git --git-dir="$T/code.git" mktree)
git --git-dir="$T/code.git" update-ref refs/heads/vid-results/red-3-7 "$(git --git-dir="$T/code.git" -c user.name=t -c user.email=t@t commit-tree "$rt" -p main -m red-3-7)"; sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || fail 'the second results-fetch failed'
git --git-dir=.vid/code rev-parse -q --verify refs/heads/vid-results/red-3-7 > /dev/null || fail 'a new branch was not fetched'
exit 0
