#!/bin/sh
# Purpose: selftest case — a red case ends the batch at its phase (v0.9.7.0.12 spec 3.3; R3; §6 B). A phase-1 case
# reported failed ends the batch `red phase 1, rows ROW-003` with a `red row=ROW-003 case=…` line — exit 1, state
# done — and no phase-2 chunk runs. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-red-ends: $*" >&2; cat "$T/req" "$T/wait" "$TD/result" 2>/dev/null >&2; exit 1; }
batch_repo "$T/repo"
groups "$T/p1" 3 4; groups "$T/p2" 1 2; printf '%s failed\n' "$(w 2 3)" > "$T/st"
STUB_STATUSES="$T/st" batch || fail 'the batch was refused'; TD=.vid/requests/$TK
rc=0; bwait || rc=$?; [ "$rc" -eq 1 ] || fail "the batch exited $rc"
[ "$(cat "$TD/state")" = done ] && [ "$(cat "$TD/exit")" = 1 ] || fail 'the red batch is not done, exit 1'
head -n 1 "$TD/result" | grep -qx 'red phase 1, rows ROW-003' || fail 'the result does not name the red row'
grep -qF "red row=ROW-003 case=$(w 2 3)" "$TD/result" || fail 'the result does not name the red case'
for c in 3 4; do [ ! -f "$TD/chunks/$c/running-at" ] || fail "phase-2 chunk $c ran"; done
grep -q "^close-batch id=$TK chunks=4 retried=0 " .vid/metrics-events || fail 'no close-batch record'
exit 0
