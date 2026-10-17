#!/bin/sh
# Purpose: selftest case — under an older PRD grammar the wider reading reports, never refuses (v0.9.8.1 R38). The
# 0.9.4 known-good fixture with REQ-011 authoritative citing the ViD decision A-005 only inside an entry: the court
# passes and prints a NOTE naming join 17, the row and the answer, "reported, not refused"; an entry starting
# `A-005` is refused as before. Env: CHECKS.
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
fail() { echo "prd-join17-old-grammar-reported: $*" >&2; printf '%s\n' "$OUT" | grep '^GAP\|^NOTE' | head -5 >&2; exit 1; }
run() { set +e; OUT=$(sh "$COURT" "$@" 2>&1); RC=$?; set -e; }
cp "$FIXTURES/prd-094-good.md" G.md
sed "s/^\(REQ-011 .*\)| source: thesis |/\1| source: thesis, the owner's sitting (A-005) |/" G.md > OLD.md
run OLD.md; [ "$RC" -eq 0 ] || fail 'the wider reading refused a row under grammar 0.9.4'
printf '%s\n' "$OUT" | grep -q '^NOTE  join 17 (REQ-011): authoritative but its source: cites A-005 .* reported, not refused, under grammar 0.9.4' || fail 'the row is not reported'
sed 's/^\(REQ-011 .*\)| source: thesis |/\1| source: thesis, A-005 (AM-15) |/' G.md > START.md
run START.md; [ "$RC" -ne 0 ] || fail 'an entry starting A-005 is no longer refused'
exit 0
