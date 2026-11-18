#!/bin/sh
# Purpose: selftest case — a guard's "must still work" partner (0.26.10.29.3, R5, F10). A hostility row whose protects:
# names ROW-007 directly, with no row whose obligation opens "control of ROW-007", makes checks/inventory.sh print
# `NOTE  ROW-007 — no control sibling: the allowed case is never shown working (§4.4)` and count it; a protects: target
# that is a REQ is not resolved to rows, so it gets no NOTE. Adding the control sibling clears the NOTE and the count.
# The NOTE is not OWED: the default run and --strict exit the same with it and without it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "inventory-notes-control-sibling: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
printf '```vid-placement\napp/\ntests/\n```\n' > CLAUDE.md
mkdir -p tests; for t in a b c h1 h2; do printf 'ROW REQ HOS\n' > "tests/test_$t.py"; done
inv() { # $1: the extra rows
  printf '# Inventory\n\n```vid-inventory\nROW-007 | behavior | send | user | n/a | consent off: no mail is sent | REQ-001 | tests/test_a.py | proved-red: abc1234\nROW-009 | behavior | list | user | n/a | the list shows ten | REQ-002 | tests/test_b.py | proved-red: abc1234\n%shostility | HOS-001 | send with consent off | protects: ROW-007 | disable: the consent check | tests/test_h1.py | proved-red: abc1234\nhostility | HOS-002 | list past the cap | protects: REQ-002 | disable: the cap | tests/test_h2.py | proved-red: abc1234\n```\n' "$1" > INVENTORY.md
}
run() { RC=0; sh "$CHECKS/inventory.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
NOTE='NOTE  ROW-007 — no control sibling: the allowed case is never shown working (§4.4)'
inv ''
run; D1=$RC; grep -qxF "$NOTE" "$T/out" || fail 'the default run printed no NOTE for ROW-007, which HOS-001 protects with no control sibling'
grep -q '^NOTE  REQ-002' "$T/out" && fail 'a REQ target was resolved to a NOTE'
[ "$(grep -c '^NOTE  ' "$T/out")" = 1 ] || fail 'not one NOTE'
grep -qx 'inventory notes: control-siblings=1' "$T/out" || fail 'the NOTE is not counted'
run --strict; S1=$RC; grep -qxF "$NOTE" "$T/out" || fail '--strict printed no NOTE'
run --report; grep -qxF "$NOTE" "$T/out" || fail '--report printed no NOTE'
inv 'ROW-008 | behavior | send | user | n/a | control of ROW-007: consent on: exactly one mail is sent, recorded | REQ-001 | tests/test_c.py | proved-red: abc1234\n'
run; D2=$RC; grep -q '^NOTE  ' "$T/out" && fail 'the NOTE stayed after the control sibling was added'
grep -q '^inventory notes:' "$T/out" && fail 'the count stayed after the control sibling was added'
run --strict; S2=$RC
[ "$D1" = "$D2" ] || fail "the default run exits $D1 with the NOTE and $D2 without it"
[ "$S1" = "$S2" ] || fail "--strict exits $S1 with the NOTE and $S2 without it"
[ "$S1" = 0 ] || fail "--strict refused a fixture whose only finding is the NOTE ($S1)"
echo 'inventory-notes-control-sibling: ok'
