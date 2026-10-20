#!/bin/sh
# Purpose: selftest case — the estimate counts lines it has not seen
# (v0.9.7.0.9 spec 3.1, R1). A row with history adds 10 s for each line
# naming it (ROW-n or ROW_n, whole) that its test file — the first token of
# its INVENTORY.md test field — has gained since the commit its history's
# receipt names; the request's no-history line lists it as `ROW-x (+k lines
# since its history)`. The control: a row whose test file is unchanged adds
# nothing and is not listed; an owed test field and a receipt naming no
# readable commit change nothing. The search is the builder brief's section
# 9 search: checks/test.sh and checks/brief.sh hold the same awk line, and
# both give the same output on one fixture. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T"/hold*; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "estimate-unseen: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ask() { sh checks/test.sh request "$@" > "$T/out" 2>&1 || fail "the request was refused: $*"; sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"; }
# the pin: one awk line in both scripts, the same output on one fixture
L1=$(grep "^ROWLINES='" "$CHECKS/test.sh") || fail 'checks/test.sh holds no ROWLINES line'
L2=$(grep "^ROWLINES='" "$CHECKS/brief.sh") || fail 'checks/brief.sh holds no ROWLINES line'
[ "$L1" = "$L2" ] || fail 'the section 9 search differs between checks/test.sh and checks/brief.sh'
printf 'ROW-7 a\nROW-70 b\nx_ROW_7 c\nROW_7\n# ROW-7, again\nROW-17\n' > "$T/pin"
O1=$( ( eval "$L1"; awk -v a=ROW-7 "$ROWLINES" "$T/pin" ) ); O2=$( ( eval "$L2"; awk -v a=ROW-7 "$ROWLINES" "$T/pin" ) )
[ "$O1" = "$O2" ] && [ "$O1" = '1,3,4,5' ] || fail "the two searches give '$O1' and '$O2', not 1,3,4,5"
gated_repo "$T/r"; gate_on
mkdir -p checks/extractors tests/invariants
printf '#!/bin/sh\n# Purpose: toy results reader\nsed -n '"'"'s/.*case name="\\([^"]*\\)" status="\\([^"]*\\)" time="\\([^"]*\\)".*/case \\1 \\2 \\3/p'"'"' "$1"\n' > checks/extractors/results.sh
cat > INVENTORY.md <<'INV'
# Test Inventory

```vid-inventory
ROW-001 | behavior | REQ-001 | anonymous | n/a | the first | REQ-001 | tests/invariants/t.py
ROW-002 | behavior | REQ-001 | anonymous | n/a | the second | REQ-001 | tests/invariants/u.py
ROW-003 | behavior | REQ-001 | anonymous | n/a | the third | REQ-001 | owed: a harness seam
ROW-004 | behavior | REQ-001 | anonymous | n/a | the fourth | REQ-001 | tests/invariants/t.py
```
INV
printf 'check one  # ROW-001\n  step\n# ROW-004\n' > tests/invariants/t.py
printf 'check two  # ROW_002\n  step\n' > tests/invariants/u.py
g add -A && g commit -qm 'rows and tests'
H=$(git rev-parse --short=12 HEAD)
# the history: one receipt at this commit (start-up 22 - 9 = 13), one naming no commit
mkdir -p .vid/ledger-results
printf 'case tests/invariants/t.py::test_1[ROW-001] passed 5\ncase tests/invariants/u.py::test_2[ROW-002] passed 3\ncase tests/invariants/t.py::test_4[ROW-004] passed 1\n' > ".vid/ledger-results/$H.live.sel-1.run-x.xml.cases"
printf 'ledger-run seconds=22 kind=scoped report=%s status=0 role=builder at=%s\n' "$H.live.sel-1.run-x.xml" "$(utcnow)" >> .vid/metrics-events
printf 'case tests/invariants/t.py::test_3[ROW-003] passed 2\n' > .vid/ledger-results/nohead.live.sel-2.xml.cases
printf 'ledger-run seconds=15 kind=scoped report=nohead.live.sel-2.xml status=0 role=builder at=%s\n' "$(utcnow)" >> .vid/metrics-events
touch "$T/hold"; export STUB_HOLD="$T/hold"
# the control: nothing gained since the history
A=$(ask --type iterate --role builder --try t1 --rows ROW-001,ROW-002,ROW-003,ROW-004 --why 'nothing gained' -- tests/x)
grep -q '^estimate 24s (start-up 13s + cases 11s) · stops after ' "$T/out" || fail "an unchanged test file changed the estimate: $(grep '^estimate' "$T/out")"
grep -q '^no-history' "$T/out" && fail 'a row whose test file is unchanged was listed'
# ROW-001's file gains 3 lines naming it (one as ROW_001, one in a comment); ROW-002's is unchanged; ROW-003 owed
printf 'check one-b  # ROW-001\n  step\ncheck_ROW_001_c\n  step\n# ROW-001 again\n' >> tests/invariants/t.py
printf 'ROW-003 has a file nobody names\n' > tests/invariants/v.py
B=$(ask --type iterate --role builder --try t1 --rows ROW-001,ROW-002,ROW-003,ROW-004 --why 'three lines gained' -- tests/x)
grep -q '^estimate 54s (start-up 13s + cases 41s) · stops after ' "$T/out" || fail "3 lines gained did not add 30 s: $(grep '^estimate' "$T/out")"
grep -qx 'no-history 0: ROW-001 (+3 lines since its history) — 10 s each; give --expect <seconds> when they are slow' "$T/out" || fail "the no-history line does not list ROW-001's gained lines: $(grep '^no-history' "$T/out")"
grep -q 'ROW-002\|ROW-003\|ROW-004' "$T/out" && fail 'an unchanged, owed or unreadable row was listed'
# committed, the gain still counts against the history's commit; a row alone: ROW-002 untouched
g add -A && g commit -qm 'more tests'
C=$(ask --type iterate --role builder --try t1 --rows ROW-001 --why 'committed' -- tests/x)
grep -q '^estimate 48s (start-up 13s + cases 35s) ' "$T/out" || fail "a committed gain was not counted: $(grep '^estimate' "$T/out")"
D=$(ask --type iterate --role builder --try t1 --rows ROW-002 --why 'the control alone' -- tests/x)
grep -q '^estimate 16s (start-up 13s + cases 3s) ' "$T/out" || fail "the unchanged row's estimate moved: $(grep '^estimate' "$T/out")"
rm -f "$T/hold"
for k in "$A" "$B" "$C" "$D"; do VID_WAIT_MAX=60 sh checks/test.sh wait "$k" > "$T/out" 2>&1 || fail "the run of $k did not end green"; done
exit 0
