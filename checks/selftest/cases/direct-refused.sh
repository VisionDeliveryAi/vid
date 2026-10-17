#!/bin/sh
# Purpose: selftest case — direct calls (v0.9.7.0.2 spec 3.4, R4, R5; §6
# C-5). Inside a live develop run a direct `sh checks/test.sh -- x` (and a
# full run, and a role-carrying one) is refused at once, exit 2, naming the
# request form and vid-test-manager, before any lock, slot or Compose call.
# Outside a run the plain forms run as in 0.9.7.0.1 — exit codes unchanged,
# green 0, red 1 — and their events carry form=legacy. (testenv.sh's runs
# as requests: testenv-request.sh.) Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "direct-refused: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"
RC=0; sh checks/test.sh -- x > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 0 ] || fail "ungated green exited $RC"
tail -n 1 .vid/metrics-events | grep -qE '^ledger-run .* status=0 role=- form=legacy at=' || fail 'the ungated event does not carry form=legacy'
RC=0; STUB_STATUS=1 STUB_CASE=failed sh checks/test.sh --role builder -- x > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] || fail "ungated red exited $RC, not 1"
tail -n 1 .vid/metrics-events | grep -qE '^ledger-run .* status=1 role=builder form=legacy at=' || fail 'the ungated red event does not carry form=legacy'
gate_on; : > "$STUB_LOG"; N=$(grep -c '^ledger-run' .vid/metrics-events)
for a in '-- x' '--role builder -- x' '--role close' ''; do
  RC=0
  # shellcheck disable=SC2086
  sh checks/test.sh $a > "$T/out" 2>&1 || RC=$?
  [ "$RC" -eq 2 ] || fail "a direct call ($a) inside the run exited $RC, not 2"
  grep -q 'sh checks/test.sh request' "$T/out" && grep -q 'vid-test-manager' "$T/out" || fail "the refusal ($a) does not name the request form and vid-test-manager"
done
[ ! -s "$STUB_LOG" ] || fail 'a refused direct call reached Compose'
[ -z "$(ls "$T/run/vid-host" 2>/dev/null)" ] && [ "$(nruns)" -eq 0 ] && [ ! -d .vid/ledger.lock ] || fail 'a refused direct call took a slot, a run folder or the lock'
[ "$(grep -c '^ledger-run' .vid/metrics-events)" -eq "$N" ] || fail 'a refused direct call wrote an event'
exit 0
