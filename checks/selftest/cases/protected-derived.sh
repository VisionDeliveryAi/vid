#!/bin/sh
# Purpose: selftest case — derived protection, narrowed (v0.9.7.2 spec 3.3, R4; v0.9.7.3 spec 3.11, R11).
# `inventory.sh protected` names a row derived from a Tier-0 requirement, a row derived from a Tier-0 invariant, and a
# row a hostility row's protects: names by its ROW id — never a row tied to a tier-0 rule row only through its
# origin:, a row of a lower-tier requirement a probe names, nor a row of a later or Tier-1 item. Under breadth first a
# protected row is refused in a hardening step by create, by edge — however good the reason — and by setting breadth
# first over such a plan, the refusal quoting its from=; a row that becomes protected later is caught at the next
# check (every hardening row is checked, not only moved ones); the rows no longer protected move by edge. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "protected-derived: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
printf '# PRD\n\n```vid-prd\nREQ-001 | functional | T1 | works\nREQ-002 | functional | T0 | never leaks\nREQ-003 | functional | T1 | isolation\nREQ-004 | functional | T1 | audit\nREQ-005 | functional | T0 | later | phase: later\nREQ-006 | functional | T1 | export\nINV-001 | invariant | T0 | erasures stay erased\n```\n' > PRD.md
derive ROW-001 REQ-002; derive ROW-002 REQ-003; derive ROW-003 REQ-004; derive ROW-004 REQ-005; derive ROW-009 INV-001; derive ROW-006 REQ-006; derive ROW-010 REQ-003
awk '/^```$/ && !d { print "rule | RULE-001 | tenants never cross | grep x | 0 | owed: census-armed — later | origin: REQ-003"; print "rule | RULE-002 | audits kept | grep y | 1 | owed: census-armed — later | origin: REQ-004"; d = 1 } { print }' INVENTORY.md > x && mv x INVENTORY.md
hostile HOS-001 ROW-005 'owed: prerequisite — not yet'; hostile HOS-002 REQ-006 'owed: prerequisite — not yet'
commit_all 'protections'
sh checks/inventory.sh protected > "$T/out" 2>&1
for r in 'ROW-001 from=REQ-002' 'ROW-005 from=HOS-001' 'ROW-009 from=INV-001'; do grep -q "^protected $r\$" "$T/out" || fail "not protected: $r"; done
grep -q '^protected ROW-002 \|^protected ROW-010 ' "$T/out" && fail 'a row tied to a tier-0 rule row only by its origin: is protected'
grep -q '^protected ROW-006 ' "$T/out" && fail 'a row of a lower-tier requirement a probe names is protected'
grep -q '^protected ROW-003 \|^protected ROW-004 ' "$T/out" && fail 'a tier-1 rule row or a later Tier-0 item protects a row'
grep -q '^protected rows=3 ' "$T/out" || fail 'the count is not three rows'
bf_on > /dev/null
replan "$S1L" "$S2L" "$H1L"
if chg create 'the plan' > "$T/out" 2>&1; then fail 'create placed a protected row (ROW-009) in hardening'; fi
grep -q 'ROW-009 in hardening step H1 (protected: INV-001)' "$T/out" || fail 'the refusal does not name the row and its from='
bf_plan "$S1L" "$S2L" 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-010..ROW-012 | kind: hardening' 'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-009' > "$T/out" 2>&1 || fail 'the plan without it was refused (ROW-010, tied to RULE-001 by origin:, sits in H1)'
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005 ROW-007 ROW-008' 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-006 ROW-010..ROW-012 | kind: hardening' 'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-009'
chg edge 'ROW-006 is an edge case' > "$T/out" 2>&1 || fail 'edge refused a row whose requirement a probe names (no longer protected)'
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-007 ROW-008' 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-005 ROW-006 ROW-010..ROW-012 | kind: hardening' 'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-009'
if chg edge 'ROW-005 is an edge case, truly' > "$T/out" 2>&1; then fail 'edge moved a row a probe names by ROW id'; fi
grep -q 'ROW-005 in hardening step H1 (protected: HOS-001)' "$T/out" || fail 'the edge refusal does not name the row and its from='
replan "$S1L" 'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-005 ROW-007 ROW-008' 'step H1 | name: harden | modules: app/s3 | builds-on: S1 | rows: ROW-006 ROW-010..ROW-012 | kind: hardening' 'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-009'
derive ROW-011 REQ-002; commit_all 'ROW-011 protected later'
if sh checks/plan.sh check > "$T/out" 2>&1; then fail 'check missed a row protected after its placement'; fi
grep -q 'ROW-011 in hardening step H1 (protected: REQ-002)' "$T/out" || fail 'check does not name the row'
sh checks/plan.sh strategy depth-first --by owner --words 'depth' > /dev/null
if sh checks/plan.sh strategy breadth-first --by owner --words 'breadth' > "$T/out" 2>&1; then fail 'breadth first was set over a protected row in hardening'; fi
grep -q 'ROW-011 in hardening step H1' "$T/out" || fail 'the strategy refusal does not name the row'
exit 0
