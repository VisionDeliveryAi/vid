#!/bin/sh
# Purpose: selftest case — the proof waits for free slots, then starts both runs (v0.9.8.1 R25, F-14). After a measure
# and a pick of k=3, a builder's request holds a slot: prove starts no run while it runs and says it waits; once it
# ends, prove starts its two runs back to back, they overlap, and the proof holds. With VID_PROVE_FREE_WAIT=4 and
# the slot still held, prove fails saying the runs could not overlap. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T"/h*; wait; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/docker-stub.sh"
fail() { echo "testenv-prove-waits-for-free-slots: $*" >&2; cat "$T/out" "$T/prove.out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
cp "$CHECKS/testenv.sh" checks/
mkdir -p checks/extractors
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
g add -A && g commit -qm 'testenv and a reader'
export DSTUB_HOME="$(pwd -P)" DOCKER_TOTAL_MB=8192
touch "$T/hm"; release_sampled "$T/hm"
STUB_HOLD="$T/hm" sh checks/testenv.sh measure --rows ROW-001 -- 'tests/x' > "$T/out" 2>&1 || fail 'measure'
sh checks/testenv.sh pick > "$T/out" 2>&1 && grep -q 'k=3 ' "$T/out" || fail 'pick'
_i=0; while [ -d "$T/run/vid-host/stack.1" ] && [ "$_i" -lt 120 ]; do sleep 1; _i=$((_i + 1)); done   # the measure's run, through its teardown
# a builder's request holds a slot
touch "$T/hb"
STUB_HOLD="$T/hb" STUB_ENTER="$T/hb-up" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'a builder' -- tests/b > "$T/out" 2>&1 || fail 'the builder request was refused'
BK=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out")
waitfor "$T/hb-up" 120 || fail "the builder's run did not start"
touch "$T/hp"
( STUB_HOLD="$T/hp" sh checks/testenv.sh prove > "$T/prove.out" 2>&1; echo "$?" > "$T/prove.rc" ) &
waitfor "$T/prove.out" 30 || fail 'prove did not start'
_i=0; until grep -q 'waiting for every slot to be free' "$T/prove.out" || [ "$_i" -ge 60 ]; do sleep 1; _i=$((_i + 1)); done
grep -q 'waiting for every slot to be free' "$T/prove.out" || fail 'prove does not say it waits'
grep -l 'testenv prove' .vid/requests/*/request > /dev/null 2>&1 && fail 'prove requested a run while a slot was held'
# the builder ends: the proof's two runs start and overlap
release_overlap "$T/hp" 2; rm -f "$T/hb"
VID_WAIT_MAX=120 sh checks/test.sh wait "$BK" > /dev/null 2>&1 || true
_i=0; until [ -f "$T/prove.rc" ] || [ "$_i" -ge 240 ]; do sleep 1; _i=$((_i + 1)); done
[ "$(cat "$T/prove.rc" 2>/dev/null)" = 0 ] || fail 'the proof failed once the slot was free'
grep -q '^testenv prove ok ' "$T/prove.out" || fail 'the proof did not report ok'
# a slot held past the bound: the proof fails, saying why
touch "$T/hb"
STUB_HOLD="$T/hb" sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'another builder' -- tests/b > "$T/out" 2>&1 || fail 'the second builder request was refused'
waitfor "$T/run/vid-host/stack.1" 120 || fail "the second builder's run took no slot"
if VID_PROVE_FREE_WAIT=4 sh checks/testenv.sh prove > "$T/prove.out" 2>&1; then fail 'a proof ran beside a held slot'; fi
grep -q 'other runs held a slot for 4 s' "$T/prove.out" || fail 'the bounded wait does not say why the proof failed'
rm -f "$T/hb"
exit 0
