#!/bin/sh
# Purpose: selftest case — the start-up is the recent passes' overhead (v0.9.8.1 R32, F-22). Kept receipts at the
# home give the old figure, 90 s; the newest inline ledger-run events carry overhead= 40, 50, 60, 70, 80: an iterate is
# estimated with start-up 60 s, their median. With only two such events the old figure stands. A proof's event is
# never read. In a second home, twelve events of 900 before ten of 20: start-up 20 s, the newest 10 only. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/estimate-files.sh"
fail() { echo "estimate-startup-recent-overhead: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ov() { printf 'ledger-run seconds=100 kind=scoped report=%s status=0 tree=x run=r overhead=%s at=%s\n' "$1" "$2" "$(utcnow)" >> .vid/metrics-events; }
gated_repo "$T/r"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold"
ef_hist k1 inline 100 'tests/invariants/t.py::test_a[ROW-001]=10'   # the old figure: 100 − 10 = 90
ov a.xml 40; ov b.xml 50
ef_req 'two overheads' -- 'tests/invariants/t.py::test_a[ROW-001]'
grep -q '^estimate [0-9]*s (start-up 90s + ' "$T/out" || fail "with two overheads the old figure did not stand: $(grep '^estimate' "$T/out")"
ov c.xml 60; ov d.xml 70; ov e.xml 80; ov p.proof.xml 1
ef_req 'five overheads' -- 'tests/invariants/t.py::test_a[ROW-001]'
grep -q '^estimate [0-9]*s (start-up 60s + ' "$T/out" || fail "the start-up is not the overheads' median: $(grep '^estimate' "$T/out")"
# the newest 10 only: twelve older ones of 900, then ten of 20
mkdir -p "$T/r2"; cd "$T/r2"; gated_repo "$T/r2"; gate_on; j=0; while [ $j -lt 12 ]; do ov "z$j.xml" 900; j=$((j + 1)); done; i=0; while [ $i -lt 10 ]; do ov "n$i.xml" 20; i=$((i + 1)); done
ef_req 'ten newest' -- 'tests/invariants/t.py::test_a[ROW-001]'
grep -q '^estimate [0-9]*s (start-up 20s + ' "$T/out" || fail "an event older than the newest 10 was read: $(grep '^estimate' "$T/out")"
rm -f "$T/hold"
exit 0
