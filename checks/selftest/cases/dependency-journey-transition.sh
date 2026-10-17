#!/bin/sh
# Purpose: selftest case — the safeguard reads the eligible verdict state (v0.9.7.2 spec 3.4, R5). A journey row whose
# transition 2 is BREACHED (class product) while transition 1 is ungraded — no row-level verdict at all — is held by
# the safeguard; once its row is amended (every verdict wiped), the same move is accepted. A done dependent never
# holds a move: S2 done, a breached row moves without --not-needed-by. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "dependency-journey-transition: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
verdict ROW-003 BREACHED product 2/2
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 ROW-004' "$S2L" 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-003 ROW-009..ROW-012 | kind: hardening'
if chg edge 'the journey later' > "$T/out" 2>&1; then fail 'a breach on one transition of a part-graded journey was missed'; fi
grep -q 'ROW-003, needed by S2 (not done)' "$T/out" || fail 'the refusal does not name S2'
echo y >> app/s1/main.py; commit_all 'amend ROW-003'
printf 'amended row=ROW-003 sha=%s at=%s\n' "$(git rev-parse HEAD)" "$(utcnow)" >> .vid/metrics-events
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 ROW-004' "$S2L" 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-003 ROW-009..ROW-012 | kind: hardening'
chg edge 'the journey later' > "$T/out" 2>&1 || fail 'an amended row (its verdicts wiped) was still held'
# a done dependent holds nothing
sh checks/plan.sh start S1 > /dev/null; keepall ROW-001 ROW-002 ROW-004
close S1 ROW-001=passed ROW-002=passed ROW-004=passed > /dev/null || fail 'S1 did not close'
sh checks/plan.sh start S2 > /dev/null || fail 'S2 was not admitted'
keepall ROW-005 ROW-006 ROW-007 ROW-008
close S2 ROW-001=passed ROW-002=passed ROW-004=passed ROW-005=passed ROW-006=passed ROW-007=passed ROW-008=passed > /dev/null || fail 'S2 did not close'
ss S2 > "$T/out"; grep -q '^step-state step=S2 .* done=yes ' "$T/out" || fail 'S2 is not done'
verdict ROW-002 BREACHED product
replan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-004' "$S2L" 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-002 ROW-003 ROW-009..ROW-012 | kind: hardening'
chg edge 'ROW-002 later, S2 is done' > "$T/out" 2>&1 || fail 'a done dependent held the move'
exit 0
