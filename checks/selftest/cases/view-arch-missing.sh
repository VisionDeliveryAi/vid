#!/bin/sh
# Purpose: selftest case — missing is shown as missing (v0.26.10.2 spec R7). The viewer fixture: at now without any
# architecture record, then with an ARCHITECTURE.md holding no Module table and a BASELINE.md with no Stack table.
# Convicts unless each absence is a missing entry naming its part and why — no ARCHITECTURE.md, no seam rows, no
# BASELINE.md (for the stack and the must-never-break rules); then no module table and no Stack table — and the
# parts' lists are empty. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-missing: $*" >&2; exit 1; }
view_project "$T/repo"
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
for x in '{"part":"modules","why":"There is no ARCHITECTURE.md at this commit."}' '{"part":"services","why":"INVENTORY.md has no seam rows at this commit."}' \
  '{"part":"stack","why":"There is no BASELINE.md at this commit."}' '{"part":"mustNeverBreak","why":"There is no BASELINE.md at this commit."}'; do
  varch "$N" | grep -qF "$x" || fail "missing lacks $x: $(varch "$N" | tail -n 1)"; done
varch "$N" | grep -qF '"architecture":{"modules":[],"planOnly":[{"name":"app/s1","steps":["S1"]},{"name":"app/s2","steps":["S2"]}],"services":[],"stack":[],"mustNeverBreak":[]' || fail "the parts are not empty: $(varch "$N")"
printf '# Architecture\n\nNo table yet.\n' > ARCHITECTURE.md; printf '# Baseline\n\n## Tier-0 rows\n\n| Rule | Meaning |\n|---|---|\n| INV-001 | No price is ever negative. |\n' > BASELINE.md
g add -A; vcommit 11:40 'records without tables'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the second run failed: $(cat "$T/r")"
varch "$N" | grep -qF '{"part":"modules","why":"ARCHITECTURE.md has no module table (a table with a Module column) at this commit."}' || fail "no module table is not said: $(varch "$N" | tail -n 1)"
varch "$N" | grep -qF '{"part":"stack","why":"BASELINE.md has no table under its Stack heading at this commit."}' || fail "no Stack table is not said: $(varch "$N" | tail -n 1)"
varch "$N" | grep -q '"part":"mustNeverBreak"' && fail 'a Tier-0 table that is there is said missing'
exit 0
