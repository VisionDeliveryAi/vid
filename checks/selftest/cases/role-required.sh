#!/bin/sh
# Purpose: selftest case — inside a develop run every test run names its
# role; outside one a roleless run is today's (v0.9.7.0.1 spec 3.2, R5;
# §6 B-1). Gated with no --role: refused, exit 2, before the lock — no
# lock, no slot, no run folder, no Compose call — the message listing the
# roles. Ungated with no --role: it runs as before, with the same exit
# code (0 on a passing report, 1 on a completed red one), and its
# `ledger-run` event carries role=-. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "role-required: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"
# ungated: today's behaviour, recorded role=-
RC=0; sh checks/test.sh -- x > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 0 ] || fail "the ungated roleless run exited $RC"
tail -n 1 .vid/metrics-events | grep -qE '^ledger-run seconds=[0-9]+ kind=scoped report=[0-9a-f]+\.live\.sel-[0-9]+\.xml status=0 role=- form=legacy at=' || { tail -n 1 .vid/metrics-events >&2; fail 'the ungated event does not carry role=-'; }
RC=0; STUB_STATUS=1 STUB_CASE=failed sh checks/test.sh -- x > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] || fail "the ungated red run exited $RC, not 1"
tail -n 1 .vid/metrics-events | grep -q ' status=1 role=- form=legacy at=' || fail 'the ungated red event does not carry role=-'
# gated: refused before anything is held
gate_on; : > "$STUB_LOG"
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
RC=0; sh checks/test.sh -- x > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 2 ] || fail "the gated roleless run exited $RC, not 2"
grep -qF 'ViD test: refused — inside a develop run every test run names its role: --role builder|fixer|test-author|close|checkpoint|grader|testenv.' "$T/out" || fail 'the refusal does not list the roles'
[ ! -s "$STUB_LOG" ] || fail 'an environment was touched'
[ ! -d .vid/ledger.lock ] && [ -z "$(ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null)" ] && [ "$(nruns)" -eq 0 ] || fail 'the refused run took the lock, a slot or a run folder'
RC=0; sh checks/test.sh > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 2 ] || fail "the gated roleless full run exited $RC, not 2"
exit 0
