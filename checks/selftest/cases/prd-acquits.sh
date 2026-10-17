#!/bin/sh
# Purpose: selftest case — prd.sh must ACQUIT the known-good fixture: a
# court that convicts everything is as false as one that convicts
# nothing. Exits 0 only on a clean pass with zero GAP lines and the
# report line present. Env: CHECKS (set by checks/selftest/run.sh).
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cp "$FIXTURES/prd-known-good.md" "$T/PRD.md"
cd "$T"
# default mode must pass.
sh "$COURT" PRD.md >/dev/null 2>&1 || exit 1
OUT=$(sh "$COURT" PRD.md --report 2>&1)
printf '%s\n' "$OUT" | grep -q '^GAP' && exit 1
printf '%s\n' "$OUT" | grep -q '^prd: items=' || exit 1
printf '%s\n' "$OUT" | grep -q 'gaps=0' || exit 1
# a legacy known-good file has nothing to report either: no NOTE line, and
# its unchanged: REQ-001 (v0.9.1 3.2) resolves — the field is legal on any file.
printf '%s\n' "$OUT" | grep -q '^NOTE' && exit 1
printf '%s\n' "$OUT" | grep -q 'grammar=legacy notes=0' || exit 1
# a legacy file keeps its five fields and its P0 count, and reports every item as pilot by default (3.6, 3.8)
printf '%s\n' "$OUT" | grep -qE 'P0=[0-9]+/[0-9]+ pilot=[1-9][0-9]* later=0' || exit 1
exit 0
