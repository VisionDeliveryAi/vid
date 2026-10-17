#!/bin/sh
# Purpose: selftest case — deploy's gate record (v0.9.6.2 spec 3.5, R5; §6
# case 19). In a scratch project, every call of checks/deploy-gate.sh
# writes its event through checks/event.sh and exits 0: gate 1 skipped for
# a first deploy, a gate start and end (with a rollback target), an owner
# confirmation asked and answered, a rollback. A gate 3 start with no gate 2
# record is written like any other, never refused. A call that does not
# parse writes nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "deploy-gates: $*" >&2; cat .vid/metrics-events >&2 2>/dev/null; exit 1; }
mkdir -p "$T/p/checks"; cd "$T/p"; git init -q
[ -f "$CHECKS/deploy-gate.sh" ] || fail 'no checks/deploy-gate.sh'
cp "$CHECKS/deploy-gate.sh" "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
dg() { sh checks/deploy-gate.sh "$@" || fail "deploy-gate.sh $* exited non-zero"; }
last() { tail -n 1 .vid/metrics-events | grep -qxE "$1 $ATRE" || fail "not written: $1"; }
dg 1 skipped --reason first-deploy; last 'deploy-gate gate=1 state=skipped reason=first-deploy'
dg 3 start --candidate 0123456789ab --env production; last 'deploy-gate gate=3 state=start candidate=0123456789ab env=production'
dg confirm ask --what 'deploy v1 to prod? migration: no'; last 'deploy-confirm state=ask what="deploy v1 to prod\? migration: no"'
dg confirm answer --what 'deploy v1 to prod? migration: no' --result yes; last 'deploy-confirm state=answer what="deploy v1 to prod\? migration: no" result=yes'
dg 3 end --result fail --rollback-target v0; last 'deploy-gate gate=3 state=end result=fail rollback-target=v0'
dg rollback --gate 3 --why 'the smoke failed'; last 'deploy-rollback gate=3 why="the smoke failed"'
dg 2 start --candidate 0123456789ab --env staging; dg 2 end --result pass; last 'deploy-gate gate=2 state=end result=pass'
grep -q '^deploy-gate gate=2 ' .vid/metrics-events && [ "$(grep -n '^deploy-gate gate=2 ' .vid/metrics-events | head -n 1 | cut -d: -f1)" -gt "$(grep -n '^deploy-gate gate=3 state=start' .vid/metrics-events | cut -d: -f1)" ] || fail 'the gate 3 start before any gate 2 record was not written first'
N=$(grep -c . .vid/metrics-events)
if sh checks/deploy-gate.sh 4 start --candidate x --env y 2>/dev/null; then fail 'gate 4 parsed'; fi
if sh checks/deploy-gate.sh confirm answer --what x --result maybe 2>/dev/null; then fail 'a result other than yes or no parsed'; fi
[ "$(grep -c . .vid/metrics-events)" -eq "$N" ] || fail 'a call that does not parse wrote something'
exit 0
