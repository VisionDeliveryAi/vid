#!/bin/sh
# Purpose: selftest case — a capped run sets a floor (v0.9.7.0.9 spec 3.2,
# R2). Each `ledger-run … capped=yes` event at the home names its request;
# each row of that ticket's rows file is estimated at least the capped
# seconds ÷ the ticket's row count, rounded up — the LARGEST such floor
# written after the row's newest kept history, so a later, wider capped
# request does not erase a narrower one's. A row with no history takes the
# floor over its 10 s. A kept receipt newer than the floors that credits
# the row ends them. A real capped run's own event is read: the next
# request for its row is estimated at least its capped seconds. v0.9.7.3 (R7): the capped run starts after the
# first repository's stacks are torn down, and is held until it is capped. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T"/hold*; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "estimate-capped-floor: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
reader() { mkdir -p checks/extractors; printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh; g add -A && g commit -qm 'a reader'; }
hist() {
  _n=$1; _s=$2; shift 2; mkdir -p .vid/ledger-results
  for _kv in "$@"; do _r=${_kv%%=*}; _v=${_kv#*=}; printf 'case tests/invariants/t.py::test_%s[%s] %s %s\n' "${_r#ROW-}" "$_r" "${_v%%:*}" "${_v#*:}"; done > ".vid/ledger-results/$_n.cases"
  printf 'ledger-run seconds=%s kind=scoped report=%s status=0 role=builder at=%s\n' "$_s" "$_n" "$(utcnow)" >> .vid/metrics-events
}
# capped <ticket> <seconds> <rows…>: a capped request's event and its ticket's rows file
capped() {
  _t=$1; _s=$2; shift 2; mkdir -p ".vid/requests/$_t"; printf '%s\n' "$@" > ".vid/requests/$_t/rows"
  printf 'ledger-run seconds=%s kind=scoped report=none status=130 role=builder request=%s type=iterate rows=%s estimate=1 cap=2 capped=yes why="x" at=%s\n' "$_s" "$_t" "$#" "$(utcnow)" >> .vid/metrics-events
}
ask() { sh checks/test.sh request "$@" > "$T/out" 2>&1 || fail "the request was refused: $*"; sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
est() { sed -n 's/^estimate \([0-9]*\)s (start-up \([0-9]*\)s + cases \([0-9]*\)s.*/\3/p' "$T/out"; }
gated_repo "$T/r1"; gate_on; reader
hist r1 22 ROW-001=passed:5 ROW-002=passed:3     # start-up 14
capped 20261006T000001Z-aaaa 99 ROW-001 ROW-002              # 99 ÷ 2 → 50 each
capped 20261006T000002Z-bbbb 80 ROW-001 ROW-002 ROW-003 ROW-004   # wider and later: 20 each
touch "$T/hold"; export STUB_HOLD="$T/hold"
A=$(ask --type iterate --role builder --try t1 --rows ROW-001,ROW-002 --why 'two capped rows' -- tests/x)
[ "$(est)" = 100 ] || fail "the largest floor (50 each) is not the estimate: $(grep '^estimate' "$T/out")"
B=$(ask --type iterate --role builder --try t1 --rows ROW-003 --why 'no history, a floor' -- tests/x)
[ "$(est)" = 20 ] || fail "a row with no history did not take its floor over 10 s: $(grep '^estimate' "$T/out")"
# a kept receipt newer than the floors credits ROW-001: its floors end; ROW-002's stay
hist r2 20 ROW-001=passed:6                        # start-up 14
C=$(ask --type iterate --role builder --try t1 --rows ROW-001 --why 'credited since' -- tests/x)
[ "$(est)" = 6 ] || fail "a newer kept receipt did not end ROW-001's floor: $(grep '^estimate' "$T/out")"
D=$(ask --type iterate --role builder --try t1 --rows ROW-002 --why 'not credited since' -- tests/x)
[ "$(est)" = 50 ] || fail "ROW-002's floor ended without a newer receipt crediting it: $(grep '^estimate' "$T/out")"
# a floor below the row's own estimate changes nothing
capped 20261006T000003Z-cccc 4 ROW-001
E=$(ask --type iterate --role builder --try t1 --rows ROW-001 --why 'a low floor' -- tests/x)
[ "$(est)" = 6 ] || fail "a floor below the row's estimate changed it: $(grep '^estimate' "$T/out")"
rm -f "$T/hold"
# v0.9.7.3 (3.7, R7): each wait is on the state — repeated while the ticket is queued or running (the wait's 75)
waitend() { _i=0; while :; do _w=0; VID_WAIT_MAX=10 sh checks/test.sh wait "$1" > "$T/out" 2>&1 || _w=$?; [ "$_w" -eq 75 ] && [ "$_i" -lt 120 ] || return "$_w"; _i=$((_i + 1)); done; }
for k in "$A" "$B" "$C" "$D" "$E"; do waitend "$k" || fail "the run of $k did not end green"; done
# the first repository's stacks are torn down — its five teardown events — and their slots freed before the capped
# run, so it never queues behind them (it would start after its hold ended, and never be capped)
_i=0; until [ "$(grep -c '^teardown ' .vid/metrics-events)" -ge 5 ] && [ -z "$(ls "$XDG_RUNTIME_DIR/vid-host" 2>/dev/null | grep '^stack')" ]; do
  [ "$_i" -ge 120 ] && fail 'the first repository'"'"'s stacks were not torn down'; sleep 1; _i=$((_i + 1)); done
# a real capped run: a 1 s red history (start-up 0) caps a held green at 2 s — held until its ticket is capped, not
# for a time; its own event raises the next estimate
gated_repo "$T/r2"; gate_on; reader
hist red 1 ROW-005=failed:1
touch "$T/hold1"
F=$(STUB_HOLD="$T/hold1" ask --type iterate --role builder --try t1 --rows ROW-005 --why 'the green, at the red pace' -- tests/x)
waitend "$F" || true
rm -f "$T/hold1"
[ "$(cat ".vid/requests/$F/state")" = capped ] || fail 'the slow green at the red pace was not capped'
S=$(grep "^ledger-run .* request=$F .*capped=yes" .vid/metrics-events | sed -n 's/^ledger-run seconds=\([0-9]*\) .*/\1/p')
[ -n "$S" ] || fail 'the capped run wrote no capped event'
touch "$T/hold"
G=$(ask --type iterate --role builder --try t1 --rows ROW-005 --why 'after the cap' -- tests/x)
[ "$(est)" -ge "$S" ] && [ "$(est)" -ge 1 ] || fail "the capped run's $S s did not raise the next estimate: $(grep '^estimate' "$T/out")"
rm -f "$T/hold"; waitend "$G" || fail 'the run after the cap did not end'
exit 0
