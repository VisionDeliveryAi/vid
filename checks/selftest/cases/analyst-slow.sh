#!/bin/sh
# Purpose: selftest case — the slow trigger (v0.9.7.0.3 spec 3.1, R1–R3;
# §6 A-4). A case of 241 s (its .cases seconds) fires `slow` naming its row;
# an inline case of a `(process)` row, which checks/evidence.sh reach
# credits to no row when the harness declares deployed-selector:, fires
# naming its case id; a 239 s case fires nothing. An `analyst-done …
# outcome=none` suppresses nothing; after the exact `analyst-done
# request=<ticket> reason=slow outcome=limit rows=<row>` the skill gives
# the conductor, the row's case fires no more, and the uncredited case
# fires no more after the same event with `cases=<case id>`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
COMPOSEFILE='x-vid-harness:
  product: product
  completed: [0, 1]
  deployed-selector: sel-dep
  processes: [worker]
services:
  product:
    build:
      context: ${VID_TEST_CONTEXT:-.}
    image: toy:test
  worker:
    image: toy:test
    profiles: [deployed]
  tests:
    image: runner
'
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/analyst.sh"
fail() { echo "analyst-slow: $*" >&2; cat "$T/res" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1
TF=tests/invariants/test_s1.py
awk '/^```$/ && !d { print "ROW-009 | behavior | s9 | (process) | - | x | REQ-001 | tests/invariants/test_s1.py"; d = 1 } { print }' INVENTORY.md > INVENTORY.x && mv INVENTORY.x INVENTORY.md
commit_all rows
PC="$TF::test_9[ROW-009]"
report "$T/r241" "$TF::test_1[ROW-001]=passed:241"
report "$T/r239" "$TF::test_1[ROW-001]=passed:239"
report "$T/rp" "$PC=passed:300"
slow1() { ask "$T/r241" --type iterate --role builder --try t1 --rows ROW-001 --why 'a slow row' -- "$TF"; }
slowp() { ask "$T/rp" --type iterate --role builder --try t1 --rows ROW-009 --why 'a slow process row' -- "$TF"; }
K1=$(slow1) || fail 'the 241 s request was refused'
grep -qx "analyst due: slow request=$K1 rows=ROW-001" "$T/res" || fail 'a 241 s case did not fire slow naming its row'
[ "$(due "$K1" | grep -c ' reason=slow rows=ROW-001 ')" -eq 1 ] || fail 'no analyst-due reason=slow rows=ROW-001 event'
sh checks/evidence.sh reach ".vid/ledger-results/$(sed -n 's/^status=[0-9]* ran-to-end=yes capped=no report=//p' "$T/res")" > "$T/reach0"
KP=$(slowp) || fail 'the process-row request was refused'
grep -q 'report=.*\.xml$' "$T/res" || fail 'the process-row run kept no receipt'
sh checks/evidence.sh reach ".vid/ledger-results/$(sed -n 's/^status=[0-9]* ran-to-end=yes capped=no report=//p' "$T/res")" > "$T/reach"
[ ! -s "$T/reach" ] && [ -s "$T/reach0" ] || fail 'reach credits the inline (process) case to a row, or the ordinary one to none'
grep -qxF "analyst due: slow request=$KP cases=$PC" "$T/res" || fail 'an uncredited slow case did not fire naming its case id'
K=$(ask "$T/r239" --type iterate --role builder --try t1 --rows ROW-001 --why 'just under' -- "$TF") || fail 'the 239 s request was refused'
[ -z "$(due "$K")" ] && ! grep -q '^analyst due' "$T/res" || fail 'a 239 s case fired'
# another outcome suppresses nothing
sh checks/event.sh "analyst-done request=$K1 reason=slow outcome=none"
K=$(slow1) && [ "$(due "$K" | grep -c ' reason=slow rows=ROW-001 ')" -eq 1 ] || fail 'after outcome=none the slow row no longer fired'
# the limit proposal with the owner: its row, then its case id, fire no more
sh checks/event.sh "analyst-done request=$K1 reason=slow outcome=limit rows=ROW-001"
K=$(slow1) || fail 'the request after the limit was refused'
[ -z "$(due "$K")" ] && ! grep -q '^analyst due' "$T/res" || fail 'a row named by a limit proposal fired again'
K=$(slowp) && grep -qxF "analyst due: slow request=$K cases=$PC" "$T/res" || fail 'a limit on another row suppressed the uncredited case'
sh checks/event.sh "analyst-done request=$KP reason=slow outcome=limit cases=$PC"
K=$(slowp) || fail 'the process-row request after its limit was refused'
[ -z "$(due "$K")" ] && ! grep -q '^analyst due' "$T/res" || fail 'a case id named by a limit proposal fired again'
exit 0
