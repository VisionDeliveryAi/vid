#!/bin/sh
# Purpose: selftest case — the setup trigger's expected-empty controls
# (v0.9.7.0.3 spec 3.1, R1; §6 A-3). A red request with 4 failed cases
# over 60 s, and one with 20 failed cases each under 60 s (the ordinary
# red of new tests), write no analyst-due event and no `analyst due` line.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
fail() { echo "analyst-setup-small: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 5; commit_all rows
TF=tests/invariants/test_s1.py
ROWS=ROW-001,ROW-002,ROW-003,ROW-004,ROW-005
export STUB_STATUS=1
report "$T/four" "$TF::test_1[ROW-001]=failed:200" "$TF::test_2[ROW-002]=failed:61" "$TF::test_3[ROW-003]=failed:61" "$TF::test_4[ROW-004]=failed:61" "$TF::test_5[ROW-005]=failed:60"
K=$(ask "$T/four" --type iterate --role builder --try t1 --rows "$ROWS" --why 'four slow failures' -- "$TF") || fail 'the first request was refused'
grep -q '^cases failed=5$' "$T/res" || fail 'the first run did not report its five failures'
grep -q '^analyst due' "$T/res" && fail '4 slow failures said analyst due'
[ -z "$(due "$K")" ] || fail '4 slow failures wrote an analyst-due event'
set --; i=0; while [ "$i" -lt 20 ]; do r=$(( i % 5 + 1 )); set -- "$@" "$TF::test_$i[ROW-00$r]=failed:5"; i=$((i + 1)); done
report "$T/twenty" "$@"
K=$(ask "$T/twenty" --type prove-red --role test-author --rows "$ROWS" --why 'twenty new tests, red' -- "$TF") || fail 'the second request was refused'
grep -q '^cases failed=20$' "$T/res" || fail 'the second run did not report its twenty failures'
grep -q '^analyst due' "$T/res" && fail '20 fast failures said analyst due'
[ -z "$(due "$K")" ] || fail '20 fast failures wrote an analyst-due event'
exit 0
