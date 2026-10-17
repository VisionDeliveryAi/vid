#!/bin/sh
# Purpose: selftest case — a failing teardown keeps the slot (v0.9.6 spec
# 3.10, R10; §7 case 12). Inside the gate, a stub whose `down` fails: the
# run still publishes its receipt — before its teardown since v0.9.7.0.10
# (3.1, R4), so its `ledger-run` event no longer carries `teardown=failed`;
# a `teardown-failed request=- project=<p>` event follows it (no ticket
# here) — the host slot and the run folder are kept, both holder
# files gain `teardown-failed <UTC>`; the next run, under stacks=1, is
# refused naming the slot STALE, and reports the run folder STALE; the
# observer reports it STALE too. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "teardown-failed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
cp "$CHECKS/observe.sh" "$CHECKS/metrics.sh" "$CHECKS/brief.sh" "$CHECKS/watchdog.sh" checks/
STUB_DOWN_FAIL=1 sh checks/test.sh --role builder -- x > "$T/out" 2>&1 || true
grep -q 'teardown FAILED' "$T/out" || fail 'the failure was not said'
[ "$(kept | grep -c .)" -eq 1 ] || fail 'the run did not publish'
grep '^ledger-run ' .vid/metrics-events | tail -n 1 | grep -q ' teardown=failed' && fail 'the ledger-run event, written before its teardown, claims teardown=failed'
tail -n 1 .vid/metrics-events | grep -qE '^teardown-failed request=- project=vid-s1-repo at=' || fail 'no teardown-failed event after the ledger-run event'
[ -d "$T/run/vid-host/stack.1" ] || fail 'the slot was released after a failed teardown'
grep -qE '^teardown-failed [0-9TZ:-]+$' "$T/run/vid-host/stack.1/holder" || fail 'the slot holder is not marked'
[ "$(nruns)" -eq 1 ] || fail 'the run folder was removed after a failed teardown'
grep -q '^teardown-failed ' .vid/runs/*/holder || fail 'the run folder holder is not marked'
if sh checks/test.sh --role builder -- y > "$T/out" 2>&1; then fail 'a second run was admitted onto the kept slot'; fi
grep -q 'stack.1: STALE' "$T/out" || fail 'the refusal does not name the kept slot STALE'
grep -q 'STALE run folder' "$T/out" && grep -q 'its teardown failed' "$T/out" || fail 'the kept run folder is not reported'
sh checks/observe.sh > "$T/out" 2>&1 || true
grep -q 'STALE run folder .* its teardown failed' "$T/out" || fail 'the observer does not report the kept run folder'
exit 0
