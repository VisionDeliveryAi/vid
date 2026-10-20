#!/bin/sh
# Purpose: selftest case — the estimate (v0.9.7.0.2 spec 3.1,
# R8; §6 B-5). With `.cases` history at the home, the estimate is each
# row's case seconds in the newest .cases naming it plus the start-up, the
# median of (event seconds − summed case seconds) over the newest 20 kept
# receipts. With no history: 10 s a row plus 90 s,
# and the answer says no-history. --expect replaces the rows' case total
# and is recorded on the request and its event. The control (v0.26.10.4 R5:
# the estimate stops nothing): a row whose history is a fast red runs its
# slow green to its end without --expect, and with --expect only its
# estimate changes — it finishes green as well. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T"/hold*; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "estimate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
reader() { mkdir -p checks/extractors; printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh; g add -A && g commit -qm 'a reader'; }
# hist <receipt> <event seconds> <ROW-nnn=status:seconds …>: a kept receipt's .cases and its event
hist() {
  _n=$1; _s=$2; shift 2; mkdir -p .vid/ledger-results
  for _kv in "$@"; do _r=${_kv%%=*}; _v=${_kv#*=}; printf 'case tests/invariants/t.py::test_%s[%s] %s %s\n' "${_r#ROW-}" "$_r" "${_v%%:*}" "${_v#*:}"; done > ".vid/ledger-results/$_n.cases"
  printf 'ledger-run seconds=%s kind=scoped report=%s status=0 role=builder at=%s\n' "$_s" "$_n" "$(utcnow)" >> .vid/metrics-events
}
ask() { sh checks/test.sh request "$@" > "$T/out" 2>&1 || fail "the request was refused: $*"; sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
# 1. history: start-ups 10, 14, 14 → 14; ROW-001 5 s and ROW-002 3 s in their newest .cases
gated_repo "$T/r1"; gate_on; reader
hist old 110 ROW-001=passed:100
hist r1 22 ROW-001=passed:5 ROW-002=passed:3
hist r2 15 ROW-003=failed:1
touch "$T/hold"; export STUB_HOLD="$T/hold"
A=$(ask --type iterate --role builder --try t1 --rows ROW-001,ROW-002 --why 'two rows with history' -- tests/x)
grep -q '^estimate 22s (start-up 14s + cases 8s) · stops after ' "$T/out" || fail 'the estimate is not the newest case seconds plus the median start-up'
grep -q '^no-history' "$T/out" && fail 'rows with history were named as without'
B=$(ask --type iterate --role builder --try t1 --rows ROW-009 --why 'a row with no history' -- tests/x)
grep -q '^estimate 24s (start-up 14s + cases 10s) · stops after ' "$T/out" && grep -q '^no-history 1: ROW-009 ' "$T/out" || fail 'a row with no history is not 10 s'
C=$(ask --type iterate --role builder --try t1 --rows ROW-001 --expect 300 --why 'a slow green expected' -- tests/x)
grep -q '^estimate 314s (start-up 14s + cases 300s, from --expect) · stops after ' "$T/out" || fail '--expect did not replace the case total'
grep -qx 'expect=300' ".vid/requests/$C/request" || fail '--expect is not recorded on the request'
rm -f "$T/hold"
for k in "$A" "$B" "$C"; do VID_WAIT_MAX=60 sh checks/test.sh wait "$k" > "$T/out" 2>&1 || fail "the run of $k did not end green"; done
grep "^ledger-run .* request=$C " .vid/metrics-events | grep -q ' expect=300 ' || fail '--expect is not recorded on the event'
grep "^ledger-run .* request=$B " .vid/metrics-events | grep -q ' no-history=1 ' || fail 'no-history is not recorded on the event'
# 2. no history at all: 90 s start-up and 10 s a row
gated_repo "$T/r2"; gate_on
touch "$T/hold"
D=$(ask --type iterate --role builder --try t1 --rows ROW-001,ROW-002 --why 'nothing ran yet' -- tests/x)
grep -q '^estimate 110s (start-up 90s + cases 20s) · stops after ' "$T/out" && grep -q '^no-history 2: ROW-001,ROW-002 ' "$T/out" || fail 'no history is not 10 s a row plus 90 s'
rm -f "$T/hold"; VID_WAIT_MAX=60 sh checks/test.sh wait "$D" > "$T/out" 2>&1 || fail 'the run did not end'
# 3. the control: ROW-003 was a 1 s red (start-up 0), its green takes about 5 s
gated_repo "$T/r3"; gate_on; reader
hist red 1 ROW-003=failed:1
touch "$T/hold1"; ( sleep 6; rm -f "$T/hold1" ) &
E=$(STUB_HOLD="$T/hold1" ask --type iterate --role builder --try t1 --rows ROW-003 --why 'the green, at the red pace' -- tests/x)
grep -q '^estimate 1s (start-up 0s + cases 1s) · stops after ' "$T/out" || fail 'the fast-red history is not the estimate'
RC=0; VID_WAIT_MAX=60 sh checks/test.sh wait "$E" > "$T/out" 2>&1 || RC=$?
[ "$(cat ".vid/requests/$E/state")" = done ] && [ "$RC" -eq 0 ] || fail 'the slow green at the red pace was stopped: the estimate stops nothing'
wait
touch "$T/hold2"; ( sleep 5; rm -f "$T/hold2" ) &
F=$(STUB_HOLD="$T/hold2" ask --type iterate --role builder --try t1 --rows ROW-003 --expect 10 --why 'the green, expected slow' -- tests/x)
# the green above kept a receipt, so the start-up's history moved; the cases are --expect's
grep -qE '^estimate [0-9]+s \(start-up [0-9]+s \+ cases 10s, from --expect\) · stops after ' "$T/out" || fail '--expect did not set the estimate'
VID_WAIT_MAX=60 sh checks/test.sh wait "$F" > "$T/out" 2>&1 || fail 'the slow green with --expect did not finish green'
[ "$(cat ".vid/requests/$F/state")" = done ] && grep -q '^status=0 ran-to-end=yes capped=no ' "$T/out" || fail 'the slow green with --expect did not run to its end'
exit 0
