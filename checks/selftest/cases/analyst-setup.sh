#!/bin/sh
# Purpose: selftest case — the setup trigger (v0.9.7.0.3 spec 3.1, R1, R2;
# §6 A-2). A red request whose run holds 5 failed cases each over 60 s,
# with five different messages, writes one `analyst-due reason=setup`
# event and one `analyst due: setup` result line; asked again, it fires
# again (no trigger is suppressed by an earlier one). The second request is
# made outside a develop run (vid-fix's standalone case), where the kept
# report has no .cases beside it and the results reader is read. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
fail() { echo "analyst-setup: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 5; commit_all rows
TF=tests/invariants/test_s1.py
report "$T/r" "$TF::test_1[ROW-001]=failed:61" "$TF::test_2[ROW-002]=failed:62" "$TF::test_3[ROW-003]=failed:70" "$TF::test_4[ROW-004]=failed:90" "$TF::test_5[ROW-005]=failed:61.5"
export STUB_STATUS=1
K=$(ask "$T/r" --type iterate --role builder --try t1 --rows ROW-001,ROW-002,ROW-003,ROW-004,ROW-005 --why 'five slow failures' -- "$TF") || fail 'the request was refused'
grep -q '^group failed n=1 message="m5"$' "$T/res" || fail 'the five failures do not carry five different messages'
[ "$(due "$K" | grep -c ' reason=setup')" -eq 1 ] || fail 'no single analyst-due reason=setup event'
due "$K" | grep -q ' group="m[1-5] (1 case); ' || fail 'the event names no group'   # v0.9.8.1 (R42): each group with its count
grep -q "^analyst due: setup request=$K " "$T/res" || fail 'the result says no analyst due: setup'
[ "$(due "$K" | grep -c .)" -eq 1 ] || fail 'another trigger fired'
gate_on stopped   # outside a develop run: the request lands here, its report has no .cases
K2=$(ask "$T/r" --type iterate --role fixer --try t1 --rows ROW-001,ROW-002,ROW-003,ROW-004,ROW-005 --why 'the same five, again' -- "$TF") || fail 'the second request was refused'
[ -d ".vid/requests/$K2" ] && [ "$K2" != "$K" ] || fail 'the second request made no ticket'
[ "$(due "$K2" | grep -c ' reason=setup')" -eq 1 ] || fail 'asked again, the setup trigger did not fire again'
grep -q "^analyst due: setup request=$K2" "$T/res" || fail 'the second result says no analyst due'
exit 0
