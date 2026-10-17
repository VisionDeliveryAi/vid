#!/bin/sh
# Purpose: selftest case — the gate is on only while a 0.9.6 develop run is
# the verb in progress (v0.9.6 spec 3.6, R6; §7 case 14). `plan.sh gate`
# is on with `plan: required`, `run: active` and a develop stage start as
# the newest start, and a test run then takes no lock. It is off — and a
# test run takes the lock and 0.9.5's names — with no `plan:` key; with
# `run: complete`; with `run: stopped owner asked to pause`, including while
# a grader brief is checked (grade writes no stage event); after a later
# `stage name=fix state=start` following the paused develop run; and after
# `stage name=develop state=end`. It comes back on after develop's next
# stage start with `run: active`. `run: waiting` is on. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "gate-scope: $*" >&2; cat "$T/out" >&2 2>/dev/null; sh checks/plan.sh gate >&2 || true; exit 1; }
gated_repo "$T/repo"
cp "$CHECKS/brief.sh" "$CHECKS/prd.sh" checks/
st() { sed "s/^run: .*/run: $1/" .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md; }
ev() { printf '%s at=%s\n' "$1" "$(utcnow)" >> .vid/metrics-events; }
on() { [ "$(sh checks/plan.sh gate | cut -d' ' -f1)" = on ] || fail "the gate is off: $1"
  VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- x > "$T/out" 2>&1 || fail "the gated run failed: $1"   # v0.9.7.0.2: a direct call, as the test manager makes
  grep '^ledger-run ' .vid/metrics-events | tail -n 1 | grep -q ' run=' || fail "the run was not gated: $1"; }
off() { if sh checks/plan.sh gate > "$T/out" 2>&1; then fail "the gate is on: $1"; fi
  grep -q '^off ' "$T/out" || fail "the gate did not say off: $1"
  sh checks/test.sh -- x > "$T/out" 2>&1 || fail "the ungated run failed: $1"
  tail -n 1 .vid/metrics-events | grep -q ' run=' && fail "the run was gated: $1"
  ls .vid/ledger-results | grep -qE '\.live\.sel-[0-9]+\.xml$' || fail "no 0.9.5 name: $1"; rm -f .vid/ledger-results/*; }
off 'no RUN-STATE'
gate_on; on 'plan: required, run: active, develop started'
sed '/^plan:/d' .vid/RUN-STATE.md > x && mv x .vid/RUN-STATE.md; off 'no plan: key'
rm -f .vid/RUN-STATE.md .vid/metrics-events; gate_on
st waiting; on 'run: waiting'
st complete; off 'run: complete'
st 'stopped owner asked to pause'; off 'the owner paused'
mkdir -p .vid/briefs/1; printf 'role: grader    slice: 1\nquoted-at: %s\n' "$(git rev-parse HEAD)" > .vid/briefs/1/grader-1.md
sh checks/brief.sh .vid/briefs/1/grader-1.md > /dev/null 2>&1 || true
off 'a grader brief checked while paused'
ev 'stage name=fix state=start session=S2 records=1'; st active; off 'fix started after the pause'
ev 'stage name=develop state=start session=S3 records=2'; on 'develop resumed'
ev 'stage name=develop state=end session=S3'; off 'develop ended'
ev 'stage name=develop state=start session=S4 records=2'; on 'develop started again'
exit 0
