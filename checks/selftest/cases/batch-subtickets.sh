#!/bin/sh
# Purpose: selftest case — each chunk of a close batch is a sub-ticket of its own (v0.9.7.0.12 spec 3.2; R2; §6 B).
# Each `<ticket>/chunks/<n>/` holds its own request (id=<ticket>/<n>, batch=<ticket>), state, exit, result, watcher
# and timeline; its run's ledger-run event names request=<ticket>/<n> and batch=<ticket>; a slow case's analyst due
# is keyed request=<ticket>/<n> and is carried into the parent's result. The parent holds no run of its own (no
# pid, no passes, no watcher); one `wait` on the parent shows `running … chunks <done>/<total>` while chunks run and
# the result at the end. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-subtickets: $*" >&2; cat "$T/req" "$T/wait" 2>/dev/null >&2; exit 1; }
batch_repo "$T/repo"
groups "$T/p1" 3 4; groups "$T/p2" 1 2
touch "$T/hold"
VID_CAP_SCALE=100 STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" STUB_CASE_TIME=300 batch || fail 'the batch was refused'
TD=.vid/requests/$TK
waitfor "$T/entered" 30 || fail 'no chunk reached its up'
rc=0; VID_WAIT_MAX=3 sh checks/test.sh wait "$TK" > "$T/wait" 2>&1 || rc=$?
[ "$rc" -eq 75 ] || fail "wait on a running batch exited $rc"
grep -Eq 'running [0-9]+s — chunks 0/4 done' "$T/wait" || fail 'the parent wait does not show the chunks done'
rm -f "$T/hold"
bwait || fail "the batch did not end green: $(cat "$TD/result" 2>/dev/null)"
grep -qx green "$T/wait" || fail 'the last wait does not print the result'
for n in 1 2 3 4; do C=$TD/chunks/$n
  grep -qx "id=$TK/$n" "$C/request" && grep -qx "batch=$TK" "$C/request" || fail "chunk $n's request does not name its sub-ticket and batch"
  [ "$(cat "$C/state")" = done ] && [ "$(cat "$C/exit")" = 0 ] && [ -s "$C/result" ] || fail "chunk $n has no state, exit and result of its own: $(cat "$C/state" "$C/exit" "$C/result" 2>&1)"
  [ -s "$C/watcher" ] && [ -f "$C/timeline.inline.log" ] || fail "chunk $n has no watcher or timeline of its own"
  grep "^ledger-run .* request=$TK/$n " .vid/metrics-events | grep -q " batch=$TK " || fail "chunk $n's ledger-run does not name request=$TK/$n batch=$TK"
  grep -q "^analyst-due request=$TK/$n reason=slow " .vid/metrics-events || fail "chunk $n's analyst due is not keyed $TK/$n"
  grep -q "^analyst due: slow request=$TK/$n " "$TD/result" || fail "the parent result lacks chunk $n's analyst due"
done
[ "$(grep -c "^ledger-run .* request=$TK " .vid/metrics-events || true)" -eq 0 ] || fail 'the parent ran a test of its own'
for f in pid passes watcher; do [ ! -e "$TD/$f" ] || fail "the parent holds a $f"; done
exit 0
