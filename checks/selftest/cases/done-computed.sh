#!/bin/sh
# Purpose: selftest case — done, computed (v0.9.7.2 spec 3.6, R9). S1 closed by a report, every row KEPT: closed,
# graded and done; `step-done step=S1` is stamped once, never again. A journey row graded on one transition of two is
# neither graded nor KEPT: not done. S2 closed by a batch whose frozen set was taken before ROW-008 joined: not closed
# at its current rows (event order is no proof), ROW-008 named. A hardening step is done by the same rule. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "done-computed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005..ROW-007' "$H1L" > /dev/null
sh checks/plan.sh start S1 > /dev/null; close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null
keepall ROW-001 ROW-002 ROW-003; verdict ROW-004 KEPT '' 1/2
ss S1 > "$T/out"; grep -q '^step-state step=S1 kind=feature closed=yes graded=no done=no ' "$T/out" || fail 'a part-graded journey reads graded'
grep -q '^ungraded step=S1 row=ROW-004' "$T/out" && grep -q '^not-kept step=S1 row=ROW-004' "$T/out" || fail 'ROW-004 is not named ungraded and not kept'
verdict ROW-004 KEPT '' 2/2
ss S1 > "$T/out"; grep -q '^step-state step=S1 kind=feature closed=yes graded=yes done=yes eligible=4 close=report:' "$T/out" || fail 'S1 is not done'
ss S1 > /dev/null; [ "$(grep -c '^step-done step=S1 ' .vid/metrics-events)" -eq 1 ] || fail 'the stamp was not written exactly once'
# a batch frozen before ROW-008 joined S2
sh checks/plan.sh start S2 > /dev/null || fail 'S2 was refused'
mkdir -p .vid/requests/B1/frozen; printf 'tree=x\nsteps=S2\n' > .vid/requests/B1/batch
for r in 5 6 7; do printf 'ROW-00%s\t1\tS2\t1\tinline\n' "$r"; done > .vid/requests/B1/frozen/required
printf 'step-closed step=S2 report=r9 batch=B1 at=%s\n' "$(utcnow)" >> .vid/metrics-events
keepall ROW-005 ROW-006 ROW-007
ss S2 > "$T/out"; grep -q '^step-state step=S2 .* closed=yes .* done=yes .* close=batch:B1' "$T/out" || fail 'S2 is not done at its frozen rows'
replan "$S1L" "$S2L" "$H1L"; chg rows 'ROW-008 joins S2' > /dev/null || fail 'ROW-008 was not added'
rcpt r8 HEAD inline ROW-008=passed; verdict ROW-008 KEPT
ss S2 > "$T/out"; grep -q '^step-state step=S2 .* closed=no .* done=no ' "$T/out" || fail 'a row added after the freeze left S2 closed'
grep -q '^not-closed step=S2 row=ROW-008' "$T/out" || fail 'ROW-008 is not named'
# a hardening step, by the same rule
sh checks/plan.sh start H1 > /dev/null || fail 'H1 was refused'
close H1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-005=passed ROW-006=passed ROW-007=passed ROW-008=passed ROW-009=passed ROW-010=passed ROW-011=passed ROW-012=passed > /dev/null || fail 'H1 did not close'
keepall ROW-009 ROW-010 ROW-011 ROW-012
ss H1 > "$T/out"; grep -q '^step-state step=H1 kind=hardening closed=yes graded=yes done=yes ' "$T/out" || fail 'the hardening step is not done'
exit 0
