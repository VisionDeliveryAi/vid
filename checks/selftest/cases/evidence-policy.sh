#!/bin/sh
# Purpose: selftest case — one evidence rule under the gate (v0.9.6.1 spec
# 3.4, R4; §6 case 5). S2 builds on S1; a receipt passes S2's rows. Under
# the gate a change under S1's modules, and a change to a shared path,
# leave ROW-003 passing, its detail naming the commit it passed at
# (`passed at <sha>`), never as freshly tested; its own test file
# changing, an amendment after the receipt's commit, or a later failing
# receipt each change it. Outside the gate (the run stopped), 0.9.6's
# staleness holds: the same S1 change stales ROW-003 under a 0.9.6 map.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "evidence-policy: $*" >&2; exit 1; }
line() { sh checks/plan.sh map --all > "$T/map" 2>/dev/null; sh checks/evidence.sh rows --at "${2:-HEAD}" --map "$T/map" | awk -F'\t' -v r="$1" '$1 == r { print $2 "\t" $3 }'; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
  'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
H0=$(git rev-parse --short=12 HEAD)
rcpt r1 HEAD inline ROW-003=passed ROW-004=passed
[ "$(line ROW-003 | cut -f1)" = pass ] || fail 'the receipt is not current at its own tree'
line ROW-003 | cut -f2 | grep -q 'passed at' && fail 'a pass on the tree judged is labelled as an older pass'
printf 'the toolbar label\n' >> app/s1/main.py; commit_all 's1'; C1=$(git rev-parse HEAD)
L=$(line ROW-003); [ "$(printf '%s' "$L" | cut -f1)" = pass ] || fail "a change under S1's modules re-opened S2: $L"
printf '%s' "$L" | cut -f2 | grep -q "^passed at $H0 (r1)" || fail "the older pass does not name its commit: $L"
printf 'x\n' >> tests/invariants/harness.py; commit_all 'shared'
[ "$(line ROW-003 | cut -f1)" = pass ] || fail 'a change to a shared path re-opened S2'
# its own test changes
g checkout -q -b owntest; printf '# a stronger check\n' >> tests/invariants/test_s2.py; commit_all 'own test'
[ "$(line ROW-003 | cut -f1)" = stale ] || fail 'its own test changing left ROW-003 passing'
g checkout -q -
# an amendment after the receipt's commit
g checkout -q -b amend; printf 'amended row=ROW-003 sha=%s at=%s\n' "$(git rev-parse --short=12 "$C1")" "$(utcnow)" >> .vid/metrics-events
[ "$(line ROW-003 | cut -f1)" = pass ] && fail 'an amendment after the receipt left ROW-003 passing'
sed '$d' .vid/metrics-events > "$T/ev" && cat "$T/ev" > .vid/metrics-events; g checkout -q -
# a later failing receipt
rcpt r2 HEAD inline ROW-003=failed ROW-004=passed
[ "$(line ROW-003 | cut -f1)" = red ] || fail 'a later failing receipt left ROW-003 passing'
# outside the gate: 0.9.6's map and staleness
plan_repo "$T/off"; rows s1 1 2; rows s2 3 4; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
  'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003 ROW-004' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt r1 HEAD inline ROW-003=passed ROW-004=passed
printf 'the toolbar label\n' >> app/s1/main.py; commit_all 's1'
sed 's/^run: .*/run: stopped the owner paused/' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
sh checks/plan.sh gate > /dev/null 2>&1 && fail 'the gate is still on'
printf 'ROW-003\tS2\tapp/s2 app/s1 %s\n' "$PLANS_SHARED" > "$T/map96"
S=$(sh checks/evidence.sh rows --at HEAD --map "$T/map96" | awk -F'\t' '$1 == "ROW-003" { print $2 }')
[ "$S" = stale ] || fail "outside the gate a change under S1 did not stale S2 under 0.9.6's map: $S"
exit 0
