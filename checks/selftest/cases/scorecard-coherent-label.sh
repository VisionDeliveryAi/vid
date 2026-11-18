#!/bin/sh
# Purpose: selftest case — the scorecard's coherent line says what it counts (0.26.10.29.3 phase 2 R7). On the 0.9.4
# good fixture raised to 0.9.5 and on the known-good legacy fixture, checks/scorecard.sh prints its coherent line as
# `coherent      | counted | near-duplicate pairs=<n> (contradictions are the reviews' to find)`, exactly: near-duplicate
# pairs are all it counts, so the line never reads as a check for contradictions. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "scorecard-coherent-label: $*" >&2; exit 1; }
awk 'NR <= 3 && /^grammar: 0\.9\.4$/ { print "grammar: 0.9.5"; next }
  /^(REQ|INV)-[0-9]+( AMENDED)? \|/ { print $0 " | plain: The owner reads this rule in plain words"; next }
  { print }' "$CHECKS/selftest/fixtures/prd-094-good.md" > "$T/cur.md"
for f in "$T/cur.md" "$CHECKS/selftest/fixtures/prd-known-good.md"; do
  sh "$CHECKS/scorecard.sh" "$f" > "$T/out" || fail "the scorecard exited non-zero on $(basename "$f")"
  L=$(grep '^coherent ' "$T/out" || true)
  [ "$(printf '%s\n' "$L" | grep -c .)" = 1 ] || fail "not one coherent line on $(basename "$f"): $L"
  printf '%s\n' "$L" | grep -qxE "coherent      \| counted \| near-duplicate pairs=[0-9]+ \(contradictions are the reviews' to find\)" || fail "the coherent line on $(basename "$f") does not say what it counts: $L"
done
exit 0
