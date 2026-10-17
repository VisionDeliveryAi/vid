#!/bin/sh
# Purpose: selftest case — a slow start keeps the stack's timeline, and
# nothing becomes due (v0.9.7.0.10 spec 3.3, R6, revision 4; it was
# analyst-startup; v0.9.7.0.11 spec 3.7, R7: every gated pass keeps its
# timeline, so no threshold is left). A gated request whose run takes
# about 4 s outside its 0.1 s case keeps the stack's Compose logs in the
# ticket's timeline.inline.log, taken before its teardown; its result says
# no `analyst due` and the home has no `analyst-due` event. The same
# harness again: kept again. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "timeline-saved: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
tk() { sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
# slow <why>: a request whose run takes about 4 s with a 0.1 s case; its ticket in $TK, its result in $T/out
slow() { : > "$T/hold"; ( sleep 4; rm -f "$T/hold" ) &
  STUB_HOLD="$T/hold" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why "$1" -- tests/x > "$T/out" 2>&1 || fail "the request '$1' was refused"
  TK=$(tk); VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail "the run '$1' did not pass"
  waitfor ".vid/requests/$TK/timeline.inline.log" || fail "no timeline.inline.log for '$1'"; }
: > "$STUB_LOG"
slow 'a slow start'
grep -qx 'stub-logs vid-s1-repo' ".vid/requests/$TK/timeline.inline.log" || fail 'the ticket holds no timeline of the stack'
grep -nE ' logs --timestamps| down ' "$STUB_LOG" | head -n 1 | grep -q 'logs --timestamps' || fail 'the logs were not taken before the teardown'
grep -q '^analyst due' "$T/out" && fail 'the result says analyst due for a slow start'
grep -q '^analyst-due ' .vid/metrics-events && fail 'an analyst-due event for a slow start'
slow 'the same harness'
exit 0
