#!/bin/sh
# Purpose: selftest case — the check that the builder touched no test (v0.26.10.24.2 R3), on the fixture project. A Role: BU
# commit changing product files passes; one changing a file a Role: TA commit added is named, exit 1, and so is one changing a
# test from an earlier ticket, a helper a Role: TM commit added, one deleting a test, and one changing a test's mode; a Role: BU commit restoring the file
# passes again, with no history rewritten; TA's own later correction passes; a merge of main passes, and an edit made inside a
# merge is named; a path with a space works; v0.26.10.24.3 R4: a Role: FX commit is held as a builder's; a commit it cannot find exits 2. Skips where devagent/ is absent (a project's
# layout). Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] || { echo 'needs devagent/'; exit 77; }
U=$CHECKS/../devagent/test-manager/untouched.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/devagent-project.sh"
fail() { echo "devagent-untouched: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
sp_project; cd "$T/dev"
ci() { r=$1; shift; git add -A; sp_git commit -qm "$*" -m 'Decisions: none' -m "Role: $r"; }
ck() { RC=0; sh "$U" "$T/dev" HEAD > "$T/out" 2>&1 || RC=$?; }
clean() { ck; [ "$RC" = 0 ] || fail "$1: exited $RC"; }
named() { ck; [ "$RC" = 1 ] && grep -q "^$2: $3, left at " "$T/out" || fail "$1: exited $RC, $3 not named"; }
# ticket 1's tests, by TA, and a helper by TM; ticket 1's product, by BU
mkdir -p t; echo 'assert 1' > t/one.py; echo 'assert 2' > 't/two words.py'; ci TA tests
echo helper > t/helper.sh; ci TM a helper
echo product > app.py; ci BU the product; clean 'a product commit'
grep -qx 'untouched: 3 of 3 files as the test author and test manager left them' "$T/out" || fail 'the count of files'
# a slip, named, and put right with no history rewritten
echo 'assert 0' > t/one.py; ci BU a slip; named 'a changed test' changed t/one.py
git show HEAD~1:t/one.py > t/one.py; ci BU put right; clean 'a restored test'
echo 'assert 0' > 't/two words.py'; ci BU a slip; named 'a path with a space' changed 't/two words.py'
git checkout -q HEAD~1 -- 't/two words.py'; ci BU put right; clean 'a restored test with a space'
# ticket 2, on top of ticket 1: a test of the earlier ticket, the test manager's helper, a deleted test
git branch main-1; git checkout -q -b ticket-2; echo 'assert 3' > t/three.py; ci TA tests of ticket 2
echo 'assert 0' > t/one.py; ci BU a slip; named "an earlier ticket's test" changed t/one.py; git checkout -q HEAD~1 -- t/one.py; ci BU put right; clean 'restored'
echo changed > t/helper.sh; ci BU a slip; named "the test manager's helper" changed t/helper.sh; git checkout -q HEAD~1 -- t/helper.sh; ci BU put right; clean 'restored'
echo 'exit 0' > t/run.sh; chmod +x t/run.sh; ci TA a runnable test; chmod -x t/run.sh; ci BU a slip; named "a test's mode" changed t/run.sh; chmod +x t/run.sh; ci BU put right; clean 'restored'
git rm -q t/three.py; ci BU a slip; named 'a deleted test' gone t/three.py; git checkout -q HEAD~1 -- t/three.py; ci BU put right; clean 'restored'
# TA's own later correction, and a test TA itself deleted, pass
echo 'assert 4' > t/three.py; ci TA a correction; clean "TA's correction"
git rm -q t/one.py; ci TA retired; clean "TA's deletion"
# the fixer: who last left a test counts, not who changed it
echo fixed >> app.py; ci FX a fix; clean "a fixer's product commit"
echo 'assert 0' > t/three.py; ci FX a slip; named "a fixer's changed test" changed t/three.py; git checkout -q HEAD~1 -- t/three.py; ci FX put right; clean "a fixer's restored test"
echo changed > t/helper.sh; ci FX a slip; named "a fixer's changed helper" changed t/helper.sh; git checkout -q HEAD~1 -- t/helper.sh; ci FX put right; clean "a fixer's restored helper"
# main moves on: a merge passes; an edit inside a merge is named
git checkout -q main; echo more > lib.py; ci BU more product; echo 'assert 5' > t/five.py; ci TA tests on main
git checkout -q ticket-2; sp_git merge -q --no-edit main > /dev/null; clean 'a merge of main'
git checkout -q main; echo evenmore > lib.py; ci BU more product; git checkout -q ticket-2
sp_git merge -q --no-commit --no-ff main > /dev/null 2>&1; echo 'assert 0' > t/five.py; git add t/five.py; sp_git commit -qm 'merge main'; named 'an edit inside a merge' changed t/five.py
# a commit it cannot find
RC=0; sh "$U" "$T/dev" nosuchcommit > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "a commit it cannot find exited $RC"
exit 0
