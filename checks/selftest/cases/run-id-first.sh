#!/bin/sh
# Purpose: selftest case — the run id, first start (v0.9.6.2 spec 3.1, R1;
# §6 case 1). In a fresh repository, the first `stage … state=start` event
# written through checks/event.sh creates .vid/run (id=, path= the home,
# start= HEAD in 12 hex, parent=-, created=, team= and series= unknown) and
# the stage line carries ` run=<id>` with `at=` still its last token; an
# event that is not a stage start carries no run=. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "run-id-first: $*" >&2; cat .vid/metrics-events .vid/run >&2 2>/dev/null || true; exit 1; }
mkdir -p "$T/p/checks"; cd "$T/p"; git init -q
cp "$CHECKS/plan.sh" "$CHECKS/event.sh" checks/; [ -f "$CHECKS/run.sh" ] && cp "$CHECKS/run.sh" checks/
git -c user.email=vid@selftest -c user.name=vid commit -q --allow-empty -m root
sh checks/event.sh 'question n=1 the owner was asked' || fail 'the helper failed'
sh checks/event.sh 'stage name=develop state=start session=S1 records=4' || fail 'the helper failed'
[ -f .vid/run ] || fail 'no .vid/run'
ID=$(sed -n 's/^id=//p' .vid/run)
printf '%s\n' "$ID" | grep -qxE '[0-9]{8}T[0-9]{6}Z-[0-9a-f]{6}' || fail "the id is not the UTC time plus 6 hex ($ID)"
[ "$(sed -n 's/^path=//p' .vid/run)" = "$(pwd -P)" ] || fail 'path= is not the home'
[ "$(sed -n 's/^start=//p' .vid/run)" = "$(git rev-parse --short=12 HEAD)" ] || fail 'start= is not HEAD'
grep -qx 'parent=-' .vid/run && grep -qx 'team=unknown' .vid/run && grep -qx 'series=unknown' .vid/run && grep -q '^created=' .vid/run || fail 'parent, team, series or created not in their first form'
tail -n 1 .vid/metrics-events | grep -qxE "stage name=develop state=start session=S1 records=4 run=$ID at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z" || fail 'the stage line does not carry run=<id> before its last at='
head -n 1 .vid/metrics-events | grep -q ' run=' && fail 'an event that is not a stage start carries run='
exit 0
