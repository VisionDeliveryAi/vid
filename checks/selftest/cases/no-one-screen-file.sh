#!/bin/sh
# Purpose: selftest case — no shipped text requires one test file for every screen (v0.9.8.1 R18). Plugin repository
# only. Convicts unless skills/, agents/, templates/ and seed/ hold none of the single-file rule's wordings ("one
# ledger test for every screen", "ONE instrument for every screen", "one file — never a per-screen test", "a
# per-screen test or a … is a defect", "a per-screen authored test"), and unless the same scan run on a copy with one
# of them planted back is convicted. Env: CHECKS.
set -eu
R=$(cd "$CHECKS/.." && pwd)
[ -d "$R/skills/vid-test-writing" ] || exit 0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "no-one-screen-file: $*" >&2; exit 1; }
scan() { grep -rniE 'one ledger test for every screen|ONE instrument for every screen|one file — never a per-screen test|per-screen test or a [a-z ]*(is a defect|hook)|per-screen authored test|never writes a per-screen test' \
    "$1/skills" "$1/agents" "$1/templates" "$1/seed" 2>/dev/null | grep -v '/BUILD-NOTES\.md:' || true; }
H=$(scan "$R"); [ -z "$H" ] || fail "shipped text still requires one screen file: $(printf '%s\n' "$H" | head -n 3)"
mkdir -p "$T/p"; cp -R "$R/skills" "$R/agents" "$R/templates" "$R/seed" "$T/p/"
printf '\nThe surface instrument is one ledger test for every screen.\n' >> "$T/p/templates/INVENTORY.md"
[ -n "$(scan "$T/p")" ] || fail 'a planted single-file rule was not convicted'
exit 0
