#!/bin/sh
# Purpose: selftest case — reading a merged pull request (v0.26.10.9 spec R14, R17; §5 ticket-import). A feature ticket
# (fixtures/tickets.sh gh_feature) whose history holds the tests-first commit, CI having published JUnit reports for
# that commit (ROW-001 failing, run 200) and for the head (passing, run 201), reviewed and merged by the stand-in;
# `github.sh pull`, then `ticket.sh import <pr>`: the copy check passes (`copy-check … changed=0 missing=0`); the receipt
# <head>.ci-201-1.xml is published with .cases and .rows and `ledger-run type=ci repo= workflow= run=201 attempt=1
# commit= pr=`; `red-observed row=ROW-001 pr= commit=<the tests-first commit>`; INVENTORY.md is unchanged; `brief.sh
# return` accepts the hand-back, the commit descending from the ticket's base in the copy; a grader brief on the CI
# receipt credits its .rows. Refused imports, each publishing nothing (no receipt, no ledger-run): no report; a run of
# another workflow; a run of another commit; an expected test missing from the report; a rerun (attempt 2) whose only
# artifact is attempt 1's vid-junit-1. A later pull request changing the ticket's test records `changed=1`. Found by R-1
# and kept: the branch merged origin/main (a commit dated before its tests-first commit), and the tests-first commit is
# still found on the branch's own first-parent line.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "ticket-import: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gh_vid "$T/vid"
awk '/^labels-prefix:/ { print; print "test-framework: the toy runner"; print "test-dir: tests/invariants"; print "run-one: sh tests/run.sh <names>"; print "ci-workflow: CI"; print "report: vid-junit-<run attempt>"; next } { print }' ARCHITECTURE.md > A.x && mv A.x ARCHITECTURE.md
printf '\n## Placement rules\n\n- app/ only.\n\n## Ledger and docs laws\n\n- tests are law.\n\n## Import law\n\n- seams.\n\n## Law-change rule\n\n- standalone.\n' >> CLAUDE.md
printf '# Grading\n\n- reads well\n' > GRADING-CHECKLIST.md
g add -A && g commit -qm 'the test facts'
gh_feature || fail 'the feature ticket and its pull request were not made'
rep() { printf '<testsuites><testsuite name="t">\n'; for c in "$@"; do printf '  <testcase classname="tests/invariants/test_a.py" name="%s" time="0.1"%s\n' "${c%%=*}" "$( [ "${c#*=}" = failed ] && printf '><failure message="no"/></testcase>' || printf '/>')"; done; printf '</testsuite></testsuites>\n'; }
TF=$(git -C "$T/w1" rev-list --reverse "origin/main..vid/$N" | sed -n 2p)
# R-1 (F5): main gains a commit dated before the tests-first commit, and the branch merges it, as a resume does
GIT_AUTHOR_DATE='2020-01-01T00:00:00Z' GIT_COMMITTER_DATE='2020-01-01T00:00:00Z' tk_dev 'an older change on main' app/other/o.txt 'o'
( cd "$T/w1" && git fetch -q origin && git merge -q --no-edit origin/main && sh "$CHECKS/github.sh" push "vid/$N" > /dev/null 2>&1 ) || fail 'the branch did not merge origin/main'
HEAD1=$(git -C "$T/w1" rev-parse HEAD); gh_ci "$HEAD1" 202 1 success
rep 'test_1[ROW-001]=failed' > "$T/red.xml"; rep 'test_1[ROW-001]=passed' > "$T/green.xml"
gh_ci "$TF" 200 1 failure CI "$T/red.xml"; mkdir -p "$T/gh/artifacts/202/vid-junit-1"; cp "$T/green.xml" "$T/gh/artifacts/202/vid-junit-1/report.xml"
( cd "$T/wa" && sh "$CHECKS/github.sh" review "$P" && sh "$CHECKS/github.sh" merge "$P" ) > "$T/out" 2>&1 || fail 'the review and merge failed'
INV0=$(git hash-object INVENTORY.md)
git -C .vid/code fetch -q; sh checks/github.sh pull > "$T/out" 2>&1 || fail 'pull failed'
grep -q "^number=$P ticket=$N state=merged " ".vid/tickets/pr-$P/meta" || fail 'the merged pull request is not in .vid/tickets'
sh checks/ticket.sh import "$P" > "$T/out" 2>&1 || fail 'the import was refused'
H12=$(printf '%s' "$HEAD1" | cut -c1-12); R=$H12.ci-202-1.xml
grep -q "^copy-check pr=$P files=1 changed=0 missing=0 " .vid/metrics-events || fail 'the copy check is not recorded clean'
[ -f ".vid/ledger-results/$R" ] && [ -f ".vid/ledger-results/$R.cases" ] && grep -qx ROW-001 ".vid/ledger-results/$R.rows" || fail 'the receipt, its .cases or its .rows is missing'
[ ! -f ".vid/ledger-results/$R.tree" ] || fail 'a CI receipt has a .tree'
grep -q '^case tests/invariants/test_a.py::test_1\[ROW-001\] passed ' ".vid/ledger-results/$R.cases" || fail "the receipt's cases are wrong"
grep -q "^ledger-run type=ci report=$R repo=owner/code workflow=CI run=202 attempt=1 commit=$H12 pr=$P status=0 at=" .vid/metrics-events || fail 'the ledger-run event is wrong'
grep -q "^red-observed row=ROW-001 pr=$P commit=$(printf '%s' "$TF" | cut -c1-12) at=" .vid/metrics-events || fail 'no red-observed for the tests-first commit'
[ "$(git hash-object INVENTORY.md)" = "$INV0" ] && git diff --quiet -- INVENTORY.md || fail 'the import changed INVENTORY.md'
grep -q 'proved-red:' INVENTORY.md && fail 'a proved-red stamp was written'
grep -q '^ViD return: ok — .*(1 of 1 rows pass)' "$T/out" || fail 'brief.sh return did not accept the hand-back'
grep -q "^agent-returned role=builder .* agent=pr:$P" .vid/metrics-events || fail 'the hand-back is not recorded'
# a grader brief on the CI receipt: its rows from .rows
sh checks/brief.sh write --role grader --slice 1 --rows ROW-001 --receipt "$R" > "$T/out" 2>&1 || fail 'the grader brief on a CI receipt was refused'
GB=$(sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1)
sed -n "/^### The receipt's per-case status/,/^### /p" "$GB" | grep -q 'test_a.py::test_1\[ROW-001\] passed' || fail "the grader brief does not show ROW-001's case from the CI receipt"
# refusals: nothing published
nr() { ls .vid/ledger-results | grep -c . ; }; nl() { grep -c '^ledger-run ' .vid/metrics-events; }
refused() { : > "$T/gh/runs"; "$@"; N0=$(nr); L0=$(nl); sh checks/github.sh pull > /dev/null 2>&1
  if sh checks/ticket.sh import "$P" > "$T/out" 2>&1; then fail "imported: $WHAT"; fi
  grep -q "$MSG" "$T/out" || fail "the refusal of $WHAT does not say '$MSG'"
  [ "$(nr)" = "$N0" ] && [ "$(nl)" = "$L0" ] || fail "$WHAT published something"; }
WHAT='no report'; MSG='has no report named vid-junit-1'; refused gh_ci "$HEAD1" 210 1 success
WHAT='a run of another workflow'; MSG='not of the repository owner/code and workflow CI'; refused gh_ci "$HEAD1" 211 1 success Lint "$T/green.xml"
WHAT='a run of another commit'; MSG='tested another commit'; refused gh_ci "$TF" 200 1 failure CI "$T/red.xml"
rep 'test_9[ROW-009]=passed' > "$T/other.xml"
WHAT='an expected test missing'; MSG='lacks expected tests: ROW-001 (tests/invariants/test_a.py)'; refused gh_ci "$HEAD1" 212 1 success CI "$T/other.xml"
rr() { gh_ci "$HEAD1" 213 2 success; mkdir -p "$T/gh/artifacts/213/vid-junit-1"; cp "$T/green.xml" "$T/gh/artifacts/213/vid-junit-1/report.xml"; }
WHAT='a rerun with only attempt 1 s artifact'; MSG='run 213 attempt 2 has no report named vid-junit-2'; refused rr
# a later pull request that changes the ticket's test
( cd "$T/w1" && git fetch -q origin && git merge -q --no-edit origin/main && printf '# changed\n' >> tests/invariants/test_a.py && git commit -qam 'change the test' &&
  sh "$CHECKS/github.sh" push "vid/$N" --pr "$T/pr.md" > /dev/null 2>&1 ) || fail 'the second pull request was not opened'
P2=$(ls "$T/gh/prs" | sort -n | tail -n 1); [ "$P2" != "$P" ] || fail 'no second pull request'
H2=$(git -C "$T/w1" rev-parse HEAD); gh_ci "$H2" 220 1 success CI "$T/green.xml"
gh pr merge "$P2" -R owner/code --merge --body 'Stand-in: approver' > /dev/null 2>&1 || fail 'the second merge failed'
git -C .vid/code fetch -q; sh checks/github.sh pull > /dev/null 2>&1; sh checks/ticket.sh import "$P2" > "$T/out" 2>&1 || true
grep -q "^copy-check pr=$P2 files=1 changed=1 missing=0 " .vid/metrics-events || fail 'the changed test is not recorded changed=1'
grep -q "^ViD return: refused" "$T/out" && grep -q "ViD's copy check" "$T/out" || fail "the hand-back of a pull request that changed the test was not refused by the copy check"
exit 0
