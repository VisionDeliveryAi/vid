#!/bin/sh
# Purpose: selftest case — DevAgent's side of a stage's candidate (v0.26.10.26.1 R7), on the fixture project with a local bare repository as origin.
# The rest chunk, req-<issue>-p1cx: the whole suite in the primary engine alone, its report less every case whose name matches a row left out (by the format's
# matching: ROW-00 leaves ROW-001 in) and less that row's covers: line, the counts taken after; the runner's words pass as given; none leaves nothing out; its next
# attempt; another engine, no --leave-out, a non-id in it, a line, no product, a malformed ask, and --leave-out on another ask, are not run. The stage grade,
# grade-<issue>: pushed alone as grade-<issue>-<k>/grade.txt, Role: GR, its next attempt apart from another issue's; refused, nothing pushed, for a missing, unasked or
# doubled requirement, a fifth word, a line with no reason, an untagged finding, a commit not the ask's, no --reqs, a second reader; a head's grade still pushes and takes
# no --reqs. Skips where devagent/ is absent (a project's layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
R=$CHECKS/../devagent/test-manager/run.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-stage-run: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T"
S=$T/work/dev-setup.txt; H=$(printf %s "$SP_C" | cut -c1-12); O="git -C $T/origin.git"
run() { RC=0; sh "$R" run --setup "$S" --commit "$SP_C" "$@" > "$T/out" 2>&1 || RC=$?; }
has() { $O rev-parse -q --verify "refs/heads/vid-results/$1" > /dev/null; }
tree() { $O ls-tree -r --name-only "vid-results/$1" | tr '\n' ' '; }
names() { $O show "vid-results/$1:$1/cases-alpha.xml" | sed -n 's/.*<testcase name="\([^"]*\)".*/\1/p' | tr '\n' ' '; }
# the rest chunk: the whole suite, one engine, the left-out row's cases and covers: gone, a near id kept
SP_COVER=1; export SP_COVER
run --ask req-9-p1cx --leave-out 'ROW-00 ROW-003'; [ "$RC" = 0 ] || fail "a rest chunk exited $RC"
[ "$(tree req-9-p1cx-1)" = 'req-9-p1cx-1/cases-alpha.xml req-9-p1cx-1/results.txt ' ] || fail "the rest chunk's tree: $(tree req-9-p1cx-1)"
[ "$(names req-9-p1cx-1)" = 'ROW-001-home ROW-002-product ROW-004-after ROW-005-value ROW-006-weak ' ] || fail "the rest chunk's cases: $(names req-9-p1cx-1)"
$O show vid-results/req-9-p1cx-1:req-9-p1cx-1/cases-alpha.xml | tail -n 1 | grep -qx '</testsuite>' || fail 'the rest chunk left its cases file cut'
$O show vid-results/req-9-p1cx-1:req-9-p1cx-1/results.txt > rq; [ "$(head -n 1 rq)" = 'by: TM' ] && grep -qx "commit: $SP_C" rq && grep -qx 'covers: ROW-001 3' rq && ! grep -qE '^(engines|stand-in|retested|rows):' rq || fail "the rest chunk's results.txt: $(cat rq)"
grep -q '^cases: 5 passed, 0 failed' "$T/out" || fail 'the counts hold a left-out case'
run --ask req-9-p1cx --leave-out ROW-001 --select 'ROW-00[14]'; [ "$RC" = 0 ] && [ "$(names req-9-p1cx-2)" = 'ROW-004-after ' ] || fail "the second attempt, the runner's words and a left-out row: $(names req-9-p1cx-2)"
! $O show vid-results/req-9-p1cx-2:req-9-p1cx-2/results.txt | grep -q '^covers: ROW-001' || fail "a left-out row's covers: line stayed"
# v0.26.10.26.7 (R7): every case a row's, dropped here or never run by the runner's words: no case, the tag closed, none left
run --ask req-12-p1cx --leave-out 'ROW-001 ROW-002 ROW-003 ROW-004 ROW-005 ROW-006'; [ "$RC" = 0 ] || fail "a rest chunk with every case a row's exited $RC: $(tail -n 3 "$T/out")"
! grep -q 'no results report' "$T/out" && [ -z "$(names req-12-p1cx-1)" ] && $O show vid-results/req-12-p1cx-1:req-12-p1cx-1/results.txt | grep -qx 'none left' || fail "the dropped rest chunk: $(names req-12-p1cx-1); $($O show vid-results/req-12-p1cx-1:req-12-p1cx-1/results.txt 2>&1 | tail -n 2)"
run --ask req-13-p1cx --leave-out 'ROW-001' --select 'NO-SUCH-CASE'; [ "$RC" = 0 ] || fail "a rest chunk the runner ran no case of exited $RC: $(tail -n 3 "$T/out")"
[ -z "$(names req-13-p1cx-1)" ] && $O show vid-results/req-13-p1cx-1:req-13-p1cx-1/results.txt | grep -qx 'none left' || fail "the runner's empty rest chunk: $(names req-13-p1cx-1)"
! $O show vid-results/req-9-p1cx-1:req-9-p1cx-1/results.txt | grep -qx 'none left' || fail 'a rest chunk with cases says none left'
unset SP_COVER; run --ask req-10-p1cx --leave-out none --select 'ROW-00[12]'; [ "$RC" = 0 ] && [ "$(names req-10-p1cx-1)" = 'ROW-001-home ROW-002-product ' ] || fail "none left out: $(names req-10-p1cx-1)"
for a in "--leave-out ROW-1 --engines beta|primary engine, alpha" "|needs --leave-out" "--leave-out x|row ids alone" "--leave-out ROW-1 --line stand-in:m|carries no" "--leave-out ROW-1 --no-product|product running"; do
  set -f; set -- ${a%%|*}; set +f; run --ask req-11-p1cx "$@"; [ "$RC" = 1 ] && grep -q "${a#*|}" "$T/out" && ! has req-11-p1cx-1 || fail "a rest chunk ran with: ${a%%|*}"; done
run --ask req-x-p1cx --leave-out none; [ "$RC" = 1 ] && grep -q "not a rest chunk's ask" "$T/out" || fail 'a malformed rest chunk ran'
run --ask req-11-p1c1 --leave-out ROW-1 --engines alpha; [ "$RC" = 1 ] && grep -q "a rest chunk's alone" "$T/out" && ! has req-11-p1c1-1 || fail 'another chunk took --leave-out'
# the stage grade
gr() { RC=0; sh "$R" grade --setup "$S" "$@" > "$T/out" 2>&1 || RC=$?; }
printf 'by: GR\ncommit: %s\nREQ-1 pass — kept, src/a:3\nREQ-2 facade — a setting never read, src/b:9\nfinding: bug — high; src/b:9; save then reload\n' "$SP_C" > g.txt
gr --ask grade-12 --commit "$SP_C" --reqs 'REQ-1 REQ-2' --file g.txt; [ "$RC" = 0 ] && grep -qx 'pushed vid-results/grade-12-1' "$T/out" || fail "a good stage grade exited $RC"
[ "$(tree grade-12-1)" = 'grade-12-1/grade.txt ' ] && [ "$($O rev-list --count vid-results/grade-12-1)" = 1 ] && $O log -1 --format=%B vid-results/grade-12-1 | grep -qx 'Role: GR' || fail "the stage grade's branch: $(tree grade-12-1)"
$O show vid-results/grade-12-1:grade-12-1/grade.txt | cmp -s - g.txt || fail 'the stage grade is not the file'
gr --ask grade-12 --commit "$SP_C" --reqs 'REQ-1 REQ-2' --file g.txt; has grade-12-2 || fail 'no second attempt'
gr --ask grade-1 --commit "$SP_C" --reqs 'REQ-1 REQ-2' --file g.txt; has grade-1-1 || fail "grade-1 took grade-12's attempts"
no() { gr --ask grade-13 --commit "$SP_C" --reqs "${2:-REQ-1 REQ-2}" --file b.txt ${3:-}; [ "$RC" = 1 ] && grep -q "$1" "$T/out" && ! has grade-13-1 || fail "a stage grade pushed: $1"; }
sed '/^REQ-2/d' g.txt > b.txt; no 'no line for REQ-2'
sed 's/^REQ-2 facade/REQ-2 kept/' g.txt > b.txt; no 'none of pass, partial, facade or absent'
sed 's/^REQ-2 facade — .*/REQ-2 facade/' g.txt > b.txt; no 'none of pass, partial, facade or absent'
{ cat g.txt; echo 'REQ-3 pass — x'; } > b.txt; no 'no requirement asked: REQ-3'
{ cat g.txt; echo 'REQ-1 absent — x'; } > b.txt; no 'there twice: REQ-1'
{ cat g.txt; echo 'finding: worry — x'; } > b.txt; no 'not tagged bug or rule'
cp g.txt b.txt; L=$(printf '%040d' 1); RC=0; sh "$R" grade --setup "$S" --ask grade-13 --commit "$L" --reqs 'REQ-1 REQ-2' --file b.txt > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "not the ask's commit" "$T/out" && ! has grade-13-1 || fail 'a grade at another commit pushed'
RC=0; sh "$R" grade --setup "$S" --ask grade-13 --commit "$SP_C" --file b.txt > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'needs --reqs' "$T/out" || fail 'a stage grade with no --reqs pushed'
no 'one reader' 'REQ-1 REQ-2' "--second g.txt"; no 'requirement ids alone' 'REQ-1 nonsense'
RC=0; sh "$R" grade --setup "$S" --ask "grade-pr-1-$H" --reqs REQ-1 --file g.txt > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q "a stage grade's alone" "$T/out" || fail 'a head grade took --reqs'
RC=0; sh "$R" grade --setup "$S" --ask grade-x --commit "$SP_C" --file g.txt > "$T/out" 2>&1 || RC=$?; [ "$RC" = 1 ] && grep -q 'nor a stage' "$T/out" || fail 'a malformed grade ask pushed'
printf 'by: GR\ncommit: %s\nROW-001 kept — r\n' "$SP_C" > h.txt; gr --ask "grade-pr-1-$H" --file h.txt; [ "$RC" = 0 ] && has "grade-pr-1-$H-1" || fail "a head's grade no longer pushes: $(cat "$T/out")"
exit 0
