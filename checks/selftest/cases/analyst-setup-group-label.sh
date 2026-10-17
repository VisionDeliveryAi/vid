#!/bin/sh
# Purpose: selftest case — the setup trigger names its own cases (v0.9.8.1
# spec R42, F-30). A red run holds three fast failures (30 s) with the most
# common message and five failures over 60 s in two other groups (three and
# two). The analyst-due setup line's group= names the two slow groups, each
# with its case count, and never the fast group the run's first red group
# is. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
fail() { echo "analyst-setup-group-label: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 8; commit_all rows
TF=tests/invariants/test_s1.py
report "$T/r" "$TF::test_1[ROW-001]=failed:30:fast" "$TF::test_2[ROW-002]=failed:31:fast" "$TF::test_3[ROW-003]=failed:29:fast" "$TF::test_4[ROW-004]=failed:61:wait" "$TF::test_5[ROW-005]=failed:62:fast" \
  "$TF::test_6[ROW-006]=failed:240:wait" "$TF::test_7[ROW-007]=failed:90:boot" "$TF::test_8[ROW-008]=failed:95:boot"
export STUB_STATUS=1
K=$(ask "$T/r" --type iterate --role builder --try t1 --rows ROW-001,ROW-002,ROW-003,ROW-004,ROW-005,ROW-006,ROW-007,ROW-008 --why 'slow and fast failures' -- "$TF") || fail 'the request was refused'
grep -q '^group failed n=4 message="fast"$' "$T/res" || fail 'the fast group is not the run'"'"'s first red group'
D=$(due "$K" | grep ' reason=setup') || fail 'the setup trigger did not fire'
G=$(printf '%s\n' "$D" | sed -n 's/.* group="\([^"]*\)".*/\1/p')
for e in 'wait (2 cases)' 'boot (2 cases)' 'fast (1 case)'; do
  printf '%s\n' "$G" | tr ';' '\n' | sed 's/^ //' | grep -qx "$e" || fail "group= does not name '$e': $G"
done
[ "$(printf '%s\n' "$G" | tr ';' '\n' | grep -c .)" -eq 3 ] || fail "group= names more than the slow cases' groups: $G"
exit 0
