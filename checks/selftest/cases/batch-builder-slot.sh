#!/bin/sh
# Purpose: selftest case — builders keep a slot while a close batch runs (v0.9.7.0.12 spec 3.2; R2; §6 B). At a
# budget of two proved environments a batch alone runs two chunks at once; while another request is queued it runs
# at most one (stacks − 1), and its close-batch record says stacks-max=1. Found in rehearsal R-1: a chunk launched
# before the other request came, still waiting for a slot another project holds, gives way when that slot frees —
# the builder takes it, the chunk waits. v0.9.7.3 (R7): every wait is on the state itself, and the waiting chunk is
# whichever lost the race for the free slot. Env: CHECKS.
set -eu
T=$(mktemp -d); FP=''; trap 'set +e; [ -z "$FP" ] || kill "$FP" 2>/dev/null; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT   # v0.9.8.1 (R2): cleanup never decides the verdict
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-builder-slot: $*" >&2; cat "$T/req" "$T/wait" 2>/dev/null >&2; exit 1; }
batch_repo "$T/repo"
groups "$T/p1" 3 4; groups "$T/p2" 1 2
running() { _r=0; for _s in ".vid/requests/$TK"/chunks/*/state; do [ "$(cat "$_s" 2>/dev/null)" = running ] && _r=$((_r + 1)); done; echo "$_r"; }
# v0.9.7.3 (R7): what is awaited is the state itself — the chunks running, a chunk's state — never a sleep's guess;
# untilst <seconds> <test…>: true once the test holds, false after that many seconds
untilst() { _u=$1; shift; _i=0; until "$@"; do [ "$_i" -ge "$_u" ] && return 1; sleep 1; _i=$((_i + 1)); done; }
nrun() { [ "$(running)" -eq "$1" ]; }
c2is() { [ "$(cat "$C2/state" 2>/dev/null)" = "$1" ]; }
held() { touch "$T/hold"; rm -f "$T/entered"
  VID_CAP_SCALE=100 STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" batch || fail 'the batch was refused'
  waitfor "$T/entered" 120 || fail 'no chunk reached its up'; }
# alone: two chunks at once
held
untilst 120 nrun 2 || fail "a batch alone ran $(running) chunks at once"
rm -f "$T/hold"; bwait || fail 'the batch alone did not end green'
grep -q "^close-batch id=$TK .* stacks-max=2 " .vid/metrics-events || fail 'the batch alone did not record stacks-max=2'
# a builder's request waits (at a new tree: nothing adopted): one chunk at a time
printf '# b\n' > app/s3/b.py; commit_all b
Q=.vid/requests/20000101T000000Z-beef; mkdir -p "$Q"
printf 'type=iterate\nrole=builder\nrows=1\ncreated=%s\n' "$(date +%s)" > "$Q/request"; echo queued > "$Q/state"
held
# one chunk at a time is read from the batch's own record (stacks-max=1, below), not from a moment's sample
rm -f "$T/hold"; bwait || fail 'the batch beside a queued request did not end green'
grep -q "^close-batch id=$TK chunks=4 .* stacks-max=1 " .vid/metrics-events || fail "the batch beside a queued request: $(grep "^close-batch id=$TK" .vid/metrics-events)"
# a chunk launched first gives way at the slot: stack.2 is another project's while the batch starts
rm -rf "$Q"; printf '# c\n' > app/s3/c.py; commit_all c
sleep 600 & FP=$!; mkdir -p "$XDG_RUNTIME_DIR/vid-host/stack.2"; printf '%s\n/elsewhere\nother-project\n%s\n' "$FP" "$(date +%s)" > "$XDG_RUNTIME_DIR/vid-host/stack.2/holder"
held
# both chunks are launched; whichever took the free slot first runs, the other waits for the held one (C2)
launched() { [ -s ".vid/requests/$TK/chunks/1/pid" ] && [ -s ".vid/requests/$TK/chunks/2/pid" ]; }
untilst 120 launched || fail 'the two chunks were not both launched'
untilst 120 nrun 1 || fail "$(running) chunks ran with one slot free"
C2=''; for _c in 1 2; do [ "$(cat ".vid/requests/$TK/chunks/$_c/state" 2>/dev/null)" = queued ] && C2=.vid/requests/$TK/chunks/$_c; done
[ -n "$C2" ] && nrun 1 && c2is queued || fail 'the other chunk did not wait for the held slot'
VID_CAP_SCALE=100 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-003 --why 'a builder meanwhile' -- "$(w 2 3)" > "$T/req" 2>&1 || fail 'the builder request was refused'
BK=.vid/requests/$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/req")
kill "$FP"; FP=''; rm -rf "$XDG_RUNTIME_DIR/vid-host/stack.2"
# the builder's stub run can end within a second, so the order is read from the start times, not caught live
i=0; while [ ! -s "$BK/running-at" ] && [ "$i" -lt 120 ]; do sleep 1; i=$((i + 1)); done
[ -s "$BK/running-at" ] || fail "the builder did not get the freed slot ($(cat "$BK/state"); chunk 2 $(cat "$C2/state"))"
[ ! -s "$C2/running-at" ] || [ "$(cat "$C2/running-at")" -ge "$(cat "$BK/running-at")" ] || fail 'the waiting chunk took the freed slot before the builder'
rm -f "$T/hold"; bwait || fail 'the batch did not end green after giving way'
exit 0
