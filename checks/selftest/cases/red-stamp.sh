#!/bin/sh
# Purpose: selftest case — proved red means the row's case failed on its
# real check (v0.9.6 spec 3.11, R11; §7 case 31). Inside a 0.9.6 develop
# run, the pre-commit hook refuses a newly staged `proved-red:` stamp on a
# ROW row with no `red-observed` event for it; with one whose receipt shows
# the case `error` (setup); with one whose case is absent from the
# receipt; with one naming an invalidated receipt; and passes it when the
# case is `failed`, recording `redstamp=<s>` in .vid/hook-times. Outside the
# gate the same unjoined stamp passes (the check is off). Env: CHECKS.
set -eu
T=$(mktemp -d); O=$(mktemp -d); trap 'set +e; rm -rf "$T" "$O" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "red-stamp: $*" >&2; cat "$O/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 3; commit_all rows
mkdir -p checks/hooks; cp "$CHECKS/hooks/pre-commit" checks/hooks/
for c in placement conformance; do printf '#!/bin/sh\n# Purpose: stub court\nexit 0\n' > "checks/$c.sh"; done
printf '# stub lawfiles\n' > checks/lawfiles
commit_all 'the hook and stub courts'
rcpt r1 HEAD inline ROW-001=failed ROW-002=error
stamp() { sed "s/^\\($1 | .*\\)\$/\\1 | proved-red: $(git rev-parse --short=12 HEAD)/" INVENTORY.md > x && mv x INVENTORY.md; g add INVENTORY.md; }
hook() { rm -rf "$(git rev-parse --git-path vid-memo)"; if sh checks/hooks/pre-commit > "$O/out" 2>&1; then echo pass; else echo refused; fi; }
stamp ROW-001
[ "$(hook)" = refused ] || fail 'a stamp with no red-observed event passed'
grep -q 'ROW-001: no red-observed event names it' "$O/out" || fail 'the refusal does not say no red-observed'
sh checks/event.sh 'red-observed row=ROW-001 report=r1 case=tests/invariants/test_s1.py::test_001[ROW-001] assertion="the order total is 12"'
[ "$(hook)" = pass ] || fail 'a stamp whose case failed on its check was refused'
tail -n 1 .vid/hook-times | grep -qE ' redstamp=[0-9]+ at=' || fail 'hook-times carries no redstamp='
g commit -qm 'ROW-001 proved red' --no-verify
stamp ROW-002
sh checks/event.sh 'red-observed row=ROW-002 report=r1 case=tests/invariants/test_s1.py::test_002[ROW-002] assertion="setup"'
[ "$(hook)" = refused ] || fail 'a stamp whose case errored passed'
grep -q "ended in error" "$O/out" || fail 'the error refusal does not say setup'
g reset -q INVENTORY.md; g checkout -q -- INVENTORY.md
stamp ROW-003
sh checks/event.sh 'red-observed row=ROW-003 report=r1 case=tests/invariants/test_s1.py::test_003[ROW-003] assertion="x"'
[ "$(hook)" = refused ] || fail 'a stamp whose case is absent passed'
grep -q 'is absent from r1' "$O/out" || fail 'the absent refusal does not say absent'
rcpt r2 HEAD inline ROW-003=failed
sh checks/event.sh 'red-observed row=ROW-003 report=r2 case=tests/invariants/test_s1.py::test_003[ROW-003] assertion="x"'
sh checks/event.sh 'invalidated slice=1 report=r2 a void run'
[ "$(hook)" = refused ] || fail 'a stamp on an invalidated receipt passed'
grep -q 'not a valid receipt' "$O/out" || fail 'the invalid-receipt refusal does not say so'
sed '/^plan:/d' .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md
[ "$(hook)" = pass ] || fail 'outside the gate the red-stamp check refused'
exit 0
