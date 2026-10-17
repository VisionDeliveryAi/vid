#!/bin/sh
# Purpose: selftest case — the test-author role (v0.9.7.0.1 spec 3.2, R6;
# §6 B-2). Inside a develop run `--role test-author -- <selector>` is a
# scoped run like a builder's: it freezes the working tree, takes a slot
# and no lock, keeps its receipt by run, and its `ledger-run` event says
# kind=scoped role=test-author. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "role-test-author: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
SHA=$(git rev-parse --short=12 HEAD)
touch "$T/hold"; ( STUB_HOLD="$T/hold" STUB_ENTER="$T/in" sh checks/test.sh --role test-author -- 'tests/new' > "$T/out" 2>&1 ) & P=$!
waitfor "$T/in" || fail 'the run never came up'
[ -d "$XDG_RUNTIME_DIR/vid-host/stack.1" ] || fail 'the run took no slot'
[ ! -d .vid/ledger.lock ] || fail 'the run took the lock'
rm -f "$T/hold"; wait "$P" || fail 'the test-author run failed'
kept | grep -qE "^$SHA\.live\.sel-[0-9]+\.run-[0-9TZ]+-[0-9]+\.xml\$" || fail "no scoped receipt kept by run: $(kept)"
grep '^ledger-run ' .vid/metrics-events | tail -n 1 | grep -qE '^ledger-run seconds=[0-9]+ kind=scoped report=[^ ]+ status=0 role=test-author tree=[0-9a-f]+ run=' || { tail -n 1 .vid/metrics-events >&2; fail 'the event does not say kind=scoped role=test-author'; }
grep -q '|tests/new|' "$STUB_LOG" || fail 'the selector did not ride'
exit 0
