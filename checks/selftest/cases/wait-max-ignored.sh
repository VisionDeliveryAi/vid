#!/bin/sh
# Purpose: selftest case — a builder cannot widen its wait (v0.9.7.3 spec 3.9, R9; a Codex builder set VID_WAIT_MAX
# itself). A held request: in the run's own checkout VID_WAIT_MAX=2 bounds the wait (the self-test's override); in a
# builder's worktree whose .vid/home names the run, VID_WAIT_MAX=2 is ignored — the wait is still waiting after 4 s,
# within its 200 s bound. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "wait-max-ignored: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/r"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'held' -- tests/x > "$T/out" 2>&1 || fail 'the request was refused'
K=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
S=$(date +%s); VID_WAIT_MAX=2 sh checks/test.sh wait "$K" > "$T/out" 2>&1 || true
[ $(( $(date +%s) - S )) -lt 30 ] || fail 'VID_WAIT_MAX did not bound the wait in the run'"'"'s own checkout'
git worktree add -q "$T/b" -b b 2>/dev/null; mkdir -p "$T/b/.vid"; printf '%s\n' "$T/r" > "$T/b/.vid/home"
( cd "$T/b" && VID_WAIT_MAX=2 sh checks/test.sh wait "$K" > "$T/out.b" 2>&1; echo done > "$T/w.done" ) &
sleep 4
[ ! -f "$T/w.done" ] || { cat "$T/out.b" >&2; fail 'VID_WAIT_MAX bounded the wait in a builder worktree'; }
rm -f "$T/hold"; wait
exit 0
