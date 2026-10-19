#!/bin/sh
# Purpose: selftest case — a module's contracts, as recorded (v0.26.10.2 spec R15). The viewer fixture with view_arch.
# Convicts unless mustNeverBreak is BASELINE.md's Tier-0 table as written (INV-001, which ROW-005 of app/s2's step S2
# carries; REQ-009, which no promise carries; a rule that is no id), a service's module: is its module (SEAM-001
# app/s1), null where the row names none (SEAM-002) and as written where it names no module id (SEAM-003), and a
# snapshot whose BASELINE.md has no Tier-0 table says so. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-contracts: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
varch "$N" | grep -qF '"mustNeverBreak":[{"rule":"INV-001","meaning":"No price is ever negative."}' || fail "the Tier-0 table is not as written: $(varch "$N" | grep -A3 mustNeverBreak)"
for x in '{"rule":"REQ-009","meaning":"Nothing is lost."}' '{"rule":"No secret","meaning":"No secret is in the repository."}'; do varch "$N" | grep -qF "$x" || fail "mustNeverBreak lacks $x"; done
vdata "$N" | grep -q '{"id":"ROW-005",.*"requirements":\["INV-001","REQ-001"\],.*"step":"S2"' || fail 'ROW-005 does not carry INV-001 in S2'
vmod "$N" app/s2 | grep -qF '"steps":["S2"]' || fail 'app/s2 does not hold S2'
vdata "$N" | grep '"id":"ROW-' | grep -q '"REQ-009"' && fail 'a promise carries REQ-009'
varch "$N" | grep -F '"id":"SEAM-001",' | grep -qF '"module":"app/s1"}' || fail 'SEAM-001 does not name app/s1'
varch "$N" | grep -F '"id":"SEAM-002",' | grep -qF '"module":null}' || fail 'SEAM-002 names a module'
varch "$N" | grep -F '"id":"SEAM-003",' | grep -qF '"module":"nowhere"}' || fail 'SEAM-003 is not as written'
printf '# Baseline\n\n## Stack\n\n| Layer | Choice | FORBIDDEN alternatives (named) |\n|---|---|---|\n| Language | Lang A 3 | Lang B |\n' > BASELINE.md; g add -A; vcommit 11:50 'no Tier-0 table'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the second run failed: $(cat "$T/r")"
varch "$N" | grep -qF '{"part":"mustNeverBreak","why":"BASELINE.md has no table under its Tier-0 rows heading at this commit."}' || fail "a missing Tier-0 table is not said: $(varch "$N" | tail -n 1)"
exit 0
