#!/bin/sh
# Purpose: selftest case — develop's gate after its own staging deploy (v0.26.10.8 spec R8; §5
# develop-gate-after-deploy). RUN-STATE active under a plan; the events develop start, deploy start, deploy end:
# `plan.sh gate` is off (the newest start is deploy's); after develop records its own start again, as on Resume, it is
# on. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "develop-gate-after-deploy: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
mkdir -p "$T/r/checks" "$T/r/.vid"; cd "$T/r"; git init -q
cp "$CHECKS/plan.sh" checks/
printf 'run: active\nsession: S1\nplan: required\nstage: 1\n' > .vid/RUN-STATE.md
printf 'stage name=develop state=start session=S1 records=28 at=2026-10-20T10:00:00Z\n' > .vid/metrics-events
sh checks/plan.sh gate > "$T/out" 2>&1 || fail 'the gate is off while develop runs'
printf 'stage name=deploy state=start session=S1 records=28 at=2026-10-20T10:05:00Z\nstage name=deploy state=end session=S1 at=2026-10-20T10:09:00Z\n' >> .vid/metrics-events
if sh checks/plan.sh gate > "$T/out" 2>&1; then fail "the gate is on after the deploy's own start and end"; fi
printf 'stage name=develop state=start session=S1 records=28 at=2026-10-20T10:09:01Z\n' >> .vid/metrics-events
sh checks/plan.sh gate > "$T/out" 2>&1 || fail "the gate is off after develop's start again"
exit 0
