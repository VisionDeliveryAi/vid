#!/bin/sh
# Purpose: selftest case — inventory.sh must reject the four hostility
# failures of §4 (and, v0.8.1b, treat an unprotected Tier-0 demand item as
# debt): a probe cited but never observed red (no proved-red), a
# row whose disable: toggle is absent or "none", a row with no protects:,
# and (--strict) a Tier-0 rule row with no hostility sibling. Polarity: a
# fully-stamped probe passes, and a missing sibling does NOT block an
# ordinary commit — it is debt, not a gate.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
printf '```vid-placement\napp/\n```\n' > CLAUDE.md
mkdir -p app tests/invariants
: > tests/invariants/test_hos901.py

inv() { # $1..$n = machine-block lines
  { printf '# toy\n```vid-inventory\n'; for l in "$@"; do printf '%s\n' "$l"; done; printf '```\n'; } > INVENTORY.md
}

RULE0='rule | RULE-901 | one consent per candidate | echo site-a | 0 | tests/invariants/test_hos901.py | proved-red: deadbee'
PROBE='hostility | HOS-901 | replay the confirmation link twice, expect one consent | protects: RULE-901 | disable: remove the token-consumed guard in app/consent | tests/invariants/test_hos901.py'

# 1. probe cited, never observed red — rejected at materialisation.
inv "$RULE0" "$PROBE"
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi

# polarity: stamped with the sha where it was red — accepted, strict too.
inv "$RULE0" "$PROBE | proved-red: cafe123"
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1 || exit 1

# 2. no usable disable: toggle — the probe can never be watched failing.
inv "$RULE0" 'hostility | HOS-901 | replay the confirmation link twice | protects: RULE-901 | disable: none | tests/invariants/test_hos901.py | proved-red: cafe123'
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi

# 3. no protects: — a probe that is the sibling of nothing.
inv "$RULE0" 'hostility | HOS-901 | replay the confirmation link twice | disable: remove the guard | tests/invariants/test_hos901.py | proved-red: cafe123'
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then exit 1; fi

# 4. Tier-0 rule with no sibling — debt: blocks --strict, not the commit.
inv "$RULE0"
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
if sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1; then exit 1; fi

# polarity: a non-Tier-0 rule owes no hostility sibling at all.
inv 'rule | RULE-902 | footer year is current | echo site-a | 2 | tests/invariants/test_hos901.py | proved-red: deadbee'
sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1 || exit 1

# 5. (v0.8.1b) a Tier-0 DEMAND ITEM in PRD.md owes a sibling too — enriched
#    grammar: a T0 functional row with no probe protecting it is debt
#    (blocks --strict, not the commit); a probe naming the REQ, or a rule
#    row whose origin: carries it, pays it.
printf '# toy\n\n## Items\n\n```vid-prd\nREQ-901 | functional | T0 | P0 | One consent per candidate. | fail-if: two consents | serves: law | authority: authoritative | source: seed\nREQ-902 | functional | T1 | P1 | Footer year. | fail-if: stale | serves: polish | authority: authoritative | source: seed\n```\n' > PRD.md
inv 'ROW-901 | behavior | REQ-901 | n/a | n/a | one consent | REQ-901 | tests/invariants/test_hos901.py | proved-red: cafe123'
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || exit 1
if sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'OWED  REQ-901 (Tier-0 item)' || exit 1
# paid directly by the probe naming the REQ
inv 'ROW-901 | behavior | REQ-901 | n/a | n/a | one consent | REQ-901 | tests/invariants/test_hos901.py | proved-red: cafe123' \
    'hostility | HOS-901 | replay the confirmation link twice | protects: REQ-901 | disable: remove the guard | tests/invariants/test_hos901.py | proved-red: cafe123'
sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1 || exit 1
# paid through a rule row that carries the REQ in origin:
inv 'rule | RULE-901 | one consent per candidate | echo site-a | 0 | tests/invariants/test_hos901.py | origin: REQ-901 | proved-red: deadbee' \
    "$PROBE | proved-red: cafe123"
sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1 || exit 1
# an AMENDED row that lowers the tier wins (effective set)
printf '\n```vid-prd\nREQ-901 AMENDED | functional | T1 | P0 | One consent per candidate. | fail-if: two consents | serves: law | authority: authoritative | source: seed\n```\n' >> PRD.md
inv 'ROW-901 | behavior | REQ-901 | n/a | n/a | one consent | REQ-901 | tests/invariants/test_hos901.py | proved-red: cafe123'
sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1 || exit 1

# 6. the same law reads the block-form PRD.
printf '# toy\n\n### REQ-903 (T0) — consent (once)\nOne consent.\n**Fail-if:** two.\n\n### REQ-904 (T2) — footer (year)\n**Fail-if:** stale.\n' > PRD.md
inv 'ROW-903 | behavior | REQ-903 | n/a | n/a | one consent | REQ-903 | tests/invariants/test_hos901.py | proved-red: cafe123'
if sh "$CHECKS/inventory.sh" --strict >/dev/null 2>&1; then exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'OWED  REQ-903 (Tier-0 item)' || exit 1
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q 'REQ-904' && exit 1
rm -f PRD.md
exit 0
