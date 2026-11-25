#!/bin/sh
# Purpose: selftest case — a quick-gate refusal no longer hides a lane's (FB-4 C2). Stub courts: the seam court and the
# PRD court both refusing are both printed and both named, by=seams,prd, in one attempt, with a record each; a check
# after the courts speaks too (the grammar line lowered); the PRD court's memo is not written by a commit it refused,
# and is by one it passed. A passing commit prints nothing of it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
fail() { echo "hook-gate-and-lanes: $*" >&2; cat .vid/out >&2 2>/dev/null; exit 1; }
mkdir -p .vid; printf '# P\ngrammar: 0.9.5\n' > PRD.md; g add PRD.md; g commit -qm prd
MEMO=$(git rev-parse --git-path vid-memo)/prd
try() { : > .vid/hook-times; if sh checks/hooks/pre-commit > .vid/out 2>&1; then fail "passed: $1"; fi; BYS=$(sed -n 's/.* by=\([^ ]*\) .*/\1/p' .vid/hook-times); }
stage one; : > .fail/seams; : > .fail/prd
try 'two courts'; [ "$BYS" = seams,prd ] || fail "by=$BYS, not seams,prd"
grep -q 'seams refuses' .vid/out && grep -q 'prd refuses' .vid/out || fail 'not both courts printed'
[ "$(grep -c 'refused by:' .vid/out)" = 1 ] && grep -q 'refused by: seams prd$' .vid/out || fail 'not one line naming both'
A=$(ls .vid/refusals); grep -q '^court=seams ' ".vid/refusals/$A/meta" && grep -q '^court=prd ' ".vid/refusals/$A/meta" && [ -f ".vid/refusals/$A/seams.err" ] || fail 'the attempt has no record per court'
grep -q 'The order of commits' .vid/out && fail 'an order of commits with no law change'
[ ! -f "$MEMO" ] || fail 'the PRD memo was written by a court that refused'
rm -f .fail/prd; printf '# P\ngrammar: 0.9.4\n' > PRD.md; g add PRD.md
try 'the gate and the grammar line'; [ "$BYS" = seams,prd-grammar ] || fail "by=$BYS, not seams,prd-grammar"
[ -f "$MEMO" ] || fail 'the PRD court passed and its memo was not written'
rm -f .fail/*; g checkout -q HEAD -- PRD.md
sh checks/hooks/pre-commit > .vid/out 2>&1 || fail 'the repaired commit was refused'
! grep -qE 'refused by|message needs|order of commits' .vid/out || fail 'a passing commit prints a refusal line'
exit 0
