#!/bin/sh
# Purpose: selftest case — prd.sh join 13's pass list with `lens` (v0.9.4
# spec §3.7 §9b, §7 case 8): a wording-lens rewording is a findings row
# `F-NN | lens | advisory | REQ-x | repaired | evidence: arms: … — now: …`.
# A `lens` row acquits on 0.9.4 (the known-good fixture carries one) and on
# 0.9.1 (the 0.9.1 known-good copy with one added); an unknown pass
# convicts on both. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-lens: $*" >&2; exit 1; }
to091() {
  { sed -n '1p' "$1"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$1"; } | awk '
    /^```vid-prd$/ { inb = 1; print; next }
    /^```$/ { inb = 0 }
    { if (inb && $0 ~ /^[A-Z]+-[0-9]+/) { n = split($0, f, "|"); out = f[1]; for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] } sub(/[ \t]+$/, "", out); print out " | phase: pilot" } else print }' > "$2"
}
cp "$FIXTURES/prd-094-good.md" G.md
grep -q '^F-05 | lens | ' G.md || fail 'the 0.9.4 fixture carries no lens row'
sh "$COURT" G.md >/dev/null 2>&1 || fail 'the 0.9.4 lens row convicts'
sed 's/^F-05 | lens | /F-05 | lenz | /' G.md > U.md
if sh "$COURT" U.md >/dev/null 2>&1; then fail 'an unknown pass acquits on 0.9.4'; fi
sh "$COURT" U.md --report 2>&1 | grep -qF "GAP  join 13 (F-05): unknown pass 'lenz' — red-team | audit | review | lens." || fail 'the unknown pass is not named on 0.9.4'
to091 "$FIXTURES/prd-known-good.md" B.md
awk '{ print } /^F-05 \| audit/ { print "F-06 | lens | advisory | REQ-012 | repaired | evidence: arms: 1 retained, 2 retained — now: the footer lacks a support address, or mail to it bounces" }' B.md > L.md
grep -q '^F-06 | lens ' L.md || fail 'the lens plant did not apply'
sh "$COURT" L.md >/dev/null 2>&1 || fail 'a lens row convicts on 0.9.1'
sed 's/^F-06 | lens | /F-06 | lenz | /' L.md > U1.md
if sh "$COURT" U1.md >/dev/null 2>&1; then fail 'an unknown pass acquits on 0.9.1'; fi
exit 0
