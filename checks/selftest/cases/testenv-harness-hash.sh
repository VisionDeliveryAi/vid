#!/bin/sh
# Purpose: selftest case — the test-environment proof names its harness
# (v0.9.7.0.10 spec 3.7, R14, Codex 8). Inside a develop run with
# `stacks=2`: `testenv=proved harness=<cksum of docker-compose.test.yml>`
# admits a second stack beside a held one; the harness changed (another
# hash) and a bare `testenv=proved` (proved on no known harness) each
# admit one environment only, and a checkpoint is refused; the proof
# re-written for the new hash admits two again. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; sleep 2; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "testenv-harness-hash: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
hh() { cksum < docker-compose.test.yml | cut -d' ' -f1; }
second() { VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- 'tests/b' > "$T/out" 2>&1; }
: > "$T/hold"
( STUB_HOLD="$T/hold" VID_REQUEST=selftest-direct sh checks/test.sh --role builder -- 'tests/a' > "$T/a.out" 2>&1 ) & AP=$!
waitfor "$XDG_RUNTIME_DIR/vid-host/stack.1/holder" || fail 'the first run took no slot'
printf 'stacks=2\ntestenv=proved harness=%s\n' "$(hh)" > .vid/budget
second || fail 'a proof on this harness did not admit a second stack'
printf '# the harness changed\n' >> docker-compose.test.yml; g add -A && g commit -qm 'the harness changed'
if second; then fail 'a proof on the previous harness admitted a second stack'; fi
grep -q 'allows 1 test stack' "$T/out" || fail 'the refusal does not state one slot'
if VID_REQUEST=selftest-direct sh checks/test.sh --role checkpoint -- 'tests/c' > "$T/out" 2>&1; then fail 'a checkpoint ran on a proof for the previous harness'; fi
grep -q 'a checkpoint runs only with two or more proved test environments' "$T/out" || fail 'the checkpoint refusal is not the proof one'
printf 'stacks=2\ntestenv=proved\n' > .vid/budget
if second; then fail 'a bare testenv=proved admitted a second stack'; fi
printf 'stacks=2\ntestenv=proved harness=%s\n' "$(hh)" > .vid/budget
second || fail 'the proof re-written for the new harness did not admit a second stack'
rm -f "$T/hold"; wait "$AP" || true
exit 0
