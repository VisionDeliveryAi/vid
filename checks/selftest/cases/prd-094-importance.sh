#!/bin/sh
# Purpose: selftest case — prd.sh's importance floor (v0.9.4 spec §3.3, §7
# case 4), under `grammar: 0.9.4` and --pause only. A human answer must
# carry `importance: priority` when its settles: names a T0 item, when a T0
# item cites it in source:, or when it is the answer on the RESOLVED line
# of a carrier a T0 item routes to. From the 0.9.4 known-good fixture, each
# of these convicts under --pause and acquits by default: an answer cited
# by a T0 item without priority (its settles: moved off the T0 item); an
# answer on the RESOLVED line of a T0 carrier without it; an answer
# settling a T0 item without it. With the marker each acquits under
# --pause. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-094-importance: $*" >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
gaps() { printf '%s\n' "$OUT" | grep '^GAP' || true; }
floor() { # file, wanted GAP substring: acquits by default, convicts under --pause
  run "$1"; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail "$1 convicted by default — the floor runs only at --pause"; }
  run "$1" --pause; [ "$RC" -ne 0 ] || fail "$1 acquitted under --pause, expected the floor ($2)"
  gaps | grep -qF "$2" || { gaps | head -3 >&2; fail "$1 convicted under --pause but not for '$2'"; }
}
acquits() { run "$1" ${2:-}; [ "$RC" -eq 0 ] || { gaps | head -3 >&2; fail "$1 convicted, expected an acquittal"; }; }
cp "$FIXTURES/prd-094-good.md" G.md
acquits G.md --pause
# cited by a T0 item: INV-001 cites A-006; A-006 settles a T1 item instead, and loses its marker
sed 's/^\(A-006 | human | .*\) | settles: INV-001 | importance: priority$/\1 | settles: REQ-005/' G.md > CITED.md
grep -q '^A-006 .*| settles: REQ-005$' CITED.md || fail 'the CITED mutation did not apply'
floor CITED.md 'GAP  importance (A-006): a human answer shaping a must-never-break rule (cited by T0 INV-001) carries importance: priority.'
sed 's/^\(A-006 | human | .*\) | settles: REQ-005$/\1 | settles: REQ-005 | importance: priority/' CITED.md > CITEDOK.md
acquits CITEDOK.md --pause
# settles a T0 item
sed 's/^\(A-006 | human | .*\) | settles: INV-001 | importance: priority$/\1 | settles: INV-001/' G.md > SETTLES.md
floor SETTLES.md 'GAP  importance (A-006): a human answer shaping a must-never-break rule (settles T0 INV-001) carries importance: priority.'
# the answer on the RESOLVED line of a carrier a T0 item routes to: INV-002 also routes to OQ-5, resolved by A-011
awk '
  /^INV-002 \|/ { sub(/confirms_via: owner-decision OQ-3\/yes/, "confirms_via: owner-decision OQ-3 OQ-5/yes") }
  /^A-009 \| human/ { print; print "A-011 | human | 2026-08-28 | Q: may a subscriber export their own address history? | A: yes — the subscriber alone, from the account page | settles: thesis"; next }
  /^VID-QUESTION: \(OQ-3\)/ { print; print ""; print "RESOLVED: (OQ-5) A-011 — May a subscriber export their own address history?"; next }
  { print }' G.md > RES.md
grep -q '^RESOLVED: (OQ-5) A-011' RES.md && grep -q 'OQ-3 OQ-5/yes' RES.md || fail 'the RES plant did not apply'
floor RES.md 'GAP  importance (A-011): a human answer shaping a must-never-break rule (resolves OQ-5, which T0 INV-002 routes to) carries importance: priority.'
sed 's/^\(A-011 | human | .*| settles: thesis\)$/\1 | importance: priority/' RES.md > RESOK.md
acquits RESOK.md --pause
exit 0
