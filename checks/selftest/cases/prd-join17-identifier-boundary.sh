#!/bin/sh
# Purpose: selftest case — join 17's wider reading takes A-NNN only as a whole identifier (v0.9.8.1 R38 follow-up).
# From the 0.9.4 known-good fixture, A-005 a ViD decision (model_proposed), under a PRD headed grammar 0.9.8.1: an
# authoritative item whose source: cites only SRC-DATA-005 gets no join 17 line — SRC-DATA-005 is not A-005 (the
# fixture's other rows fail later grammars' joins, so the PRD's exit is not read). The control: the same item citing `(A-005)` is refused by join 17. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-join17-identifier-boundary: $*" >&2; printf '%s\n' "$OUT" | grep '^GAP\|^NOTE' | head -5 >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
cp "$FIXTURES/prd-094-good.md" G.md
grep -q '^A-005 | model_proposed ' G.md || fail 'the fixture holds no model_proposed A-005'
sed -e 's/^grammar: 0\.9\.4$/grammar: 0.9.8.1/' -e "s/^\(REQ-011 .*\)| source: thesis |/\1| source: SRC-DATA-005 |/" G.md > SRC.md
grep -q '^REQ-011 .*| source: SRC-DATA-005 |' SRC.md && grep -qx 'grammar: 0.9.8.1' SRC.md || fail 'the mutation did not apply'
run SRC.md
printf '%s\n' "$OUT" | grep -q 'join 17 (REQ-011)' && fail 'SRC-DATA-005 was read as A-005'
sed -e 's/^grammar: 0\.9\.4$/grammar: 0.9.8.1/' -e "s/^\(REQ-011 .*\)| source: thesis |/\1| source: SRC-DATA-005, the sitting (A-005) |/" G.md > BOTH.md
run BOTH.md
printf '%s\n' "$OUT" | grep -qF 'GAP  join 17 (REQ-011): authoritative but its source: cites A-005' || fail 'a whole (A-005) beside it was not refused'
exit 0
