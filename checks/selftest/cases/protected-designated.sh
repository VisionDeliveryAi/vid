#!/bin/sh
# Purpose: selftest case — designated protection (v0.9.7.2 spec 3.3, R4). The plan block's one `protected:` line
# designates rows the tiers can't see (isolation through a lower-tier requirement): a designated row is refused in
# a hardening step; a second protected: line and an id that is no row are refused by check. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "protected-designated: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" 'protected: ROW-007' > /dev/null || fail 'the plan with a protected: line was refused'
sh checks/plan.sh parse > "$T/out"; grep -qx "$(printf 'prot\tROW-007')" "$T/out" || fail 'the protected: line does not parse'
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005 ROW-006 ROW-008' 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-007 ROW-009..ROW-012 | kind: hardening' 'protected: ROW-007'
if chg edge 'tenant isolation is an edge case' > "$T/out" 2>&1; then fail 'a designated row moved into hardening'; fi
grep -q 'ROW-007 in hardening step H1 (protected: designated)' "$T/out" || fail 'the refusal does not name the designated row'
replan "$S1L" "$S2L" "$H1L" 'protected: ROW-007' 'protected: ROW-008'
if sh checks/plan.sh check > "$T/out" 2>&1; then fail 'a second protected: line was accepted'; fi
grep -q 'a second protected: line' "$T/out" || fail 'the second line refusal'
replan "$S1L" "$S2L" "$H1L" 'protected: ROW-007 ROW-099'
if sh checks/plan.sh check > "$T/out" 2>&1; then fail 'a protected: id that is no row was accepted'; fi
grep -q 'protected: ROW-099 is not a row of INVENTORY.md' "$T/out" || fail 'the unknown id refusal'
exit 0
