#!/bin/sh
# Purpose: selftest case — a full lease waits (v0.9.6 spec 3.8, R8; §7 case
# 13). Inside the gate, stacks=1, the one slot held by another live
# process: `--wait 30` takes the slot freed at 12 s and its event carries
# `waited=<s>`; `--wait 5` is refused past its bound, naming the holder; a
# TERM while waiting ends the run with nothing held — no slot, no run
# folder; without --wait the refusal is immediate, as before. Env: CHECKS.
set -eu
T=$(mktemp -d); H=''; trap 'set +e; [ -n "$H" ] && kill "$H" 2>/dev/null; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "lease-wait: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
sleep 120 & H=$!
hold() { mkdir -p "$T/run/vid-host/stack.1"; printf '%s\n/elsewhere\nother-project\n%s\n' "$H" "$(date +%s)" > "$T/run/vid-host/stack.1/holder"; }
hold
S=$(date +%s)
if sh checks/test.sh --role builder -- x > "$T/out" 2>&1; then fail 'a run without --wait was admitted onto a held slot'; fi
[ $(( $(date +%s) - S )) -lt 5 ] || fail 'the refusal without --wait was not immediate'
S=$(date +%s)
if sh checks/test.sh --role builder --wait 5 -- x > "$T/out" 2>&1; then fail '--wait 5 took a slot held throughout'; fi
E=$(( $(date +%s) - S )); [ "$E" -ge 5 ] && [ "$E" -lt 15 ] || fail "--wait 5 ended after $E s"
grep -q "stack.1: held by pid $H — repository /elsewhere" "$T/out" || fail 'the refusal does not name the holder'
( sleep 12; rm -rf "$T/run/vid-host/stack.1" ) &
S=$(date +%s)
sh checks/test.sh --role builder --wait 30 -- x > "$T/out" 2>&1 || fail '--wait 30 did not take the slot freed at 12 s'
E=$(( $(date +%s) - S )); [ "$E" -ge 12 ] && [ "$E" -lt 30 ] || fail "the wait took $E s"
grep '^ledger-run ' .vid/metrics-events | tail -n 1 | grep -qE '^ledger-run .* waited=(1[2-9]|2[0-9]) ' || { grep '^ledger-run ' .vid/metrics-events | tail -n 1 >&2; fail 'the event does not carry waited='; }
hold
sh checks/test.sh --role builder --wait 60 -- x > "$T/out" 2>&1 & W=$!
waitfor .vid/runs/*/holder 10 || true
sleep 2; [ "$(nruns)" -eq 1 ] || fail 'a waiting run has no run folder (the observer could not count it)'
kill -TERM "$W"; wait "$W" && fail 'the signalled wait exited 0'
[ "$(nruns)" -eq 0 ] || fail 'a signal while waiting left the run folder'
[ "$(sed -n 1p "$T/run/vid-host/stack.1/holder")" = "$H" ] || fail 'a signal while waiting disturbed the held slot'
[ "$(ls "$T/run/vid-host" | grep -c .)" -eq 1 ] || fail 'a signal while waiting left a slot held'
exit 0
