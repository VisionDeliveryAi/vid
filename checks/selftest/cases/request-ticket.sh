#!/bin/sh
# Purpose: selftest case — a request answers at once (v0.9.7.0.2 spec 3.1,
# R1; §6 B-1). Inside a develop run, an `iterate` request made from a linked
# worktree with no .vid/ answers within 10 seconds (v0.9.8.1: 2 before), in at most 6 lines: the
# ticket, the estimate and the limits (v0.26.10.4; the cap before), the queue position and the next
# command, `sh checks/test.sh wait <ticket>`. Its folder is at the run's
# home, holding `request` and `state` (queued or running) — nothing in the
# worktree — and `wait` from the worktree finds it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "request-ticket: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/home"; gate_on
g worktree add -q "$T/wt" -b wt
cd "$T/wt"
touch "$T/hold"; export STUB_HOLD="$T/hold"
S0=$(date +%s)
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'the first proof' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
[ $(( $(date +%s) - S0 )) -le 10 ] || fail 'the request did not answer within 10 seconds'   # v0.9.8.1 (R2): 10 s, not 2 — a loaded host; the run it starts is held throughout
[ "$(grep -c . "$T/out")" -le 6 ] || fail 'the answer is longer than 6 lines'
TK=$(sed -n 's/^ViD test: request \([0-9TZ]*-[0-9a-f]*\) .*/\1/p' "$T/out")
[ -n "$TK" ] || fail 'the answer names no ticket'
grep -qE '^estimate [0-9]+s .* · stops after [0-9]+ (s|min|h) with no output, [0-9]+ (s|min|h) of start-up, or [0-9]+ (s|min|h)$' "$T/out" || fail 'the answer has no estimate and limits'
grep -q '^queue: ' "$T/out" || fail 'the answer has no queue position'
grep -qx "next: sh checks/test.sh wait $TK" "$T/out" || fail 'the answer does not name the wait command'
[ -f "$T/home/.vid/requests/$TK/request" ] || fail 'the ticket folder is not at the home'
grep -qE '^(queued|running)$' "$T/home/.vid/requests/$TK/state" || fail 'the ticket state is neither queued nor running'
[ ! -d "$T/wt/.vid/requests" ] || fail 'the ticket was made in the worktree'
VID_WAIT_MAX=1 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 && fail 'wait ended while the run was held'
grep -qE '^(queued|running) ' "$T/out" || fail 'wait from the worktree did not find the ticket'
rm -f "$T/hold"
VID_WAIT_MAX=30 sh checks/test.sh wait "$TK" > "$T/out" 2>&1 || fail 'the run did not end green'
exit 0
