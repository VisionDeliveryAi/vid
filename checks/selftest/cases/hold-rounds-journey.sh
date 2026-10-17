#!/bin/sh
# Purpose: selftest case — the allowance and the scope flag count journey
# briefs, and survive a journey's transient KEPT (v0.9.7.0.4 spec 3.2, R5;
# §6 A-3). A toy repository under `grammar: 0.9.3`; verdict events only.
# Convicts unless: one journey brief breaching three transitions is one
# round (`rounds=2`, counter 1, not held); the migrating breach — brief 1
# (BREACHED, KEPT), `reissued rounds=1`, brief 2 (KEPT, BREACHED) — holds
# `reason=rounds` with brief 2's events in either order, although brief 2's
# KEPT first computes a transient KEPT; the same two briefs with `scope=` on
# brief 1's breach and no reissue stay held `scope` in either order; the
# consumed round — brief 1 (BREACHED, KEPT), `reissued rounds=2`, brief 2
# (BREACHED class=test, KEPT), brief 3 (KEPT, BREACHED class=harness) —
# holds `reason=rounds` in both orders of brief 3, counter 2; and a brief
# whose every transition is KEPT ends the allowance (the control). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks/extractors tests/invariants app .vid/ledger-results
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
cat > checks/extractors/results.sh <<'RD'
#!/bin/sh
# Purpose: results reader (fixture)
[ -f "${1:-}" ] || { echo 'inactive no report'; exit 0; }
sed -n 's/.*<case name="\([^"]*\)" status="\([^"]*\)" time="\([^"]*\)".*/case \1 \2 \3/p' "$1"
RD
{ printf '# toy\n```vid-inventory\ngrammar: 0.9.3\n'
  for r in J1 M1 M2 S1 S2 C1 C2 K1; do printf 'ROW-%s | journey | apply | candidate | n/a | the journey %s | REQ-003 | tests/invariants/j.py\n' "$r" "$r"; done
  printf '```\n'; } > INVENTORY.md
printf '# Purpose: toy\n' > app/main.py
printf '# Purpose: ledger (fixture)\n' > tests/invariants/j.py
g add -A && g commit -qm root; Q=$(git rev-parse --short=12 HEAD)
{ echo '<r>'; for r in J1 M1 M2 S1 S2 C1 C2 K1; do printf '<case name="tests/invariants/j.py::j[ROW-%s]" status="passed" time="0.1"/>\n' "$r"; done; echo '</r>'; } > ".vid/ledger-results/$Q.full.xml"
# V row result class k/n brief [extra]
V() { printf 'verdict slice=1 row=%s result=%s class=%s transition=%s %sbrief=.vid/briefs/%s.md quoted-at=%s at=2026-10-02T09:00:00Z\n' "$1" "$2" "$3" "$4" "${6:-}" "$5" "$Q" >> .vid/metrics-events; }
RI() { printf 'reissued row=%s why=A-1 rounds=%s at=2026-10-02T09:01:00Z\n' "$1" "$2" >> .vid/metrics-events; }
col() { sh checks/metrics.sh row-state --table | awk -F'\t' -v id="$1" -v c="$2" '$1==id { print $c }'; }   # 5 held 11 allow 12 ar
fail() { echo "hold-rounds-journey: $*" >&2; sh checks/metrics.sh row-state --table >&2; cat .vid/metrics-events >&2; exit 1; }
: > .vid/metrics-events
# one brief, three breached transitions: one round
RI ROW-J1 2; V ROW-J1 BREACHED product 1/3 j1; V ROW-J1 BREACHED product 2/3 j1; V ROW-J1 BREACHED product 3/3 j1
[ "$(col ROW-J1 12)" = 1 ] && [ "$(col ROW-J1 5)" = - ] || fail 'one journey brief breaching three transitions is not one round'
# the migrating breach, brief 2 in order (M1) and reversed (M2)
for r in ROW-M1 ROW-M2; do V $r BREACHED product 1/2 "$r-1"; V $r KEPT product 2/2 "$r-1"; RI $r 1; done
V ROW-M1 KEPT product 1/2 m1-2; V ROW-M1 BREACHED product 2/2 m1-2
V ROW-M2 BREACHED product 2/2 m2-2; V ROW-M2 KEPT product 1/2 m2-2
[ "$(col ROW-M1 5)" = rounds ] || fail 'the migrating breach (brief 2 in order) is not held reason=rounds — a transient KEPT cleared the allowance'
[ "$(col ROW-M2 5)" = rounds ] || fail 'the migrating breach (brief 2 reversed) is not held reason=rounds'
# the same with scope= on brief 1 and no reissue: held scope in either order
for r in ROW-S1 ROW-S2; do V $r BREACHED product 1/2 "$r-1" 'scope="is the second hop in the promise?" '; V $r KEPT product 2/2 "$r-1"; done
V ROW-S1 KEPT product 1/2 s1-2; V ROW-S1 BREACHED product 2/2 s1-2
V ROW-S2 BREACHED product 2/2 s2-2; V ROW-S2 KEPT product 1/2 s2-2
[ "$(col ROW-S1 5)" = scope ] && [ "$(col ROW-S2 5)" = scope ] || fail 'a transient KEPT cleared the scope flag'
# the consumed round, brief 3 in order (C1) and reversed (C2)
for r in ROW-C1 ROW-C2; do V $r BREACHED product 1/2 "$r-1"; V $r KEPT product 2/2 "$r-1"; RI $r 2
  V $r BREACHED test 1/2 "$r-2"; V $r KEPT product 2/2 "$r-2"; done
V ROW-C1 KEPT product 1/2 c1-3; V ROW-C1 BREACHED harness 2/2 c1-3
V ROW-C2 BREACHED harness 2/2 c2-3; V ROW-C2 KEPT product 1/2 c2-3
[ "$(col ROW-C1 5)" = rounds ] && [ "$(col ROW-C1 12)" = 2 ] || fail 'the consumed round (brief 3 in order) is not counted: not held reason=rounds with counter 2'
[ "$(col ROW-C2 5)" = rounds ] && [ "$(col ROW-C2 12)" = 2 ] || fail 'the consumed round (brief 3 reversed) is not held reason=rounds with counter 2'
# the control: a complete KEPT brief ends the allowance
RI ROW-K1 2; V ROW-K1 BREACHED product 1/2 k1-1; V ROW-K1 KEPT product 2/2 k1-1
V ROW-K1 KEPT product 1/2 k1-2; V ROW-K1 KEPT product 2/2 k1-2
[ "$(col ROW-K1 11)" = 0 ] && [ "$(col ROW-K1 12)" = 0 ] && [ "$(col ROW-K1 2)" = kept ] || fail 'a brief whose every transition is KEPT did not end the allowance'
exit 0
