#!/bin/sh
# Purpose: selftest case — a legacy plain run is never checked (v0.9.7.0.3
# spec 3.1, R1; §6 A-5). Outside a develop run, a plain `sh checks/test.sh
# -- <selector>` whose report is red with 6 failed cases over 60 s and a
# 300 s case writes no analyst-due event and no ticket. The same report
# through a request fires setup and slow, so the control is not vacuous.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
fail() { echo "analyst-legacy: $*" >&2; cat "$T/out" "$T/res" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 6; commit_all rows
gate_on stopped
TF=tests/invariants/test_s1.py
report "$T/r" "$TF::test_1[ROW-001]=failed:61" "$TF::test_2[ROW-002]=failed:61" "$TF::test_3[ROW-003]=failed:61" "$TF::test_4[ROW-004]=failed:61" "$TF::test_5[ROW-005]=failed:61" "$TF::test_6[ROW-006]=failed:300"
RC=0; STUB_REPORT="$T/r" STUB_STATUS=1 sh checks/test.sh -- "$TF" > "$T/out" 2>&1 || RC=$?
[ "$RC" -eq 1 ] && grep -q '^ledger-run .* form=legacy ' .vid/metrics-events || fail "the plain run did not run as a legacy run (exit $RC)"
grep -q '^analyst-due ' .vid/metrics-events && fail 'a legacy plain run wrote an analyst-due event'
[ ! -d .vid/requests ] || fail 'a legacy plain run made a ticket'
K=$(STUB_STATUS=1 ask "$T/r" --type iterate --role fixer --try t1 --rows ROW-001,ROW-002,ROW-003,ROW-004,ROW-005,ROW-006 --why 'the same run, asked' -- "$TF") || fail 'the request was refused'
due "$K" | grep -q ' reason=setup' && due "$K" | grep -q ' reason=slow rows=ROW-006' || fail 'the same report through a request did not fire setup and slow'
exit 0
