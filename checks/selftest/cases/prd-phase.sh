#!/bin/sh
# Purpose: selftest case — prd.sh join 15, phase (v0.9.1 spec 3.6), and the
# four-field row under the grammar line (3.8), both gated on `grammar:
# 0.9.1`. From the known-good fixture: a 0.9.1 copy (the grammar line, the
# priority column dropped, `phase: pilot` on every row) acquits and reports
# pilot=N later=0; one demand row without phase convicts; a third enum
# value convicts; a `later` row acquits and is counted; the legacy fixture
# (five fields, no phase) acquits with pilot=N in its report — a pre-0.9.1
# file is never convicted. Exits 0 only if every polarity holds.
# Env: CHECKS (set by checks/selftest/run.sh).
set -eu
COURT="$CHECKS/prd.sh"; FIXTURES="$CHECKS/selftest/fixtures"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
# to091 <in> <out>: the grammar line after the title; in ```vid-prd blocks drop
# the 4th positional field (priority) and append phase: pilot.
to091() {
  { sed -n '1p' "$1"; echo 'grammar: 0.9.1'; sed -n '2,$p' "$1"; } | awk '
    /^```vid-prd$/ { inb = 1; print; next }
    /^```$/ { inb = 0 }
    {
      if (inb && $0 ~ /^[A-Z]+-[0-9]+/) {
        n = split($0, f, "|"); out = f[1]
        for (i = 2; i <= n; i++) { if (i == 4) continue; out = out "|" f[i] }
        sub(/[ \t]+$/, "", out); print out " | phase: pilot"
      } else print
    }' > "$2"
}
to091 "$FIXTURES/prd-known-good.md" PRD.md
sh "$COURT" PRD.md >/dev/null 2>&1 || { echo 'prd-phase: the 0.9.1 known-good copy does not acquit' >&2; sh "$COURT" PRD.md --report 2>&1 | grep '^GAP' | head -5 >&2; exit 1; }
OUT=$(sh "$COURT" PRD.md --report 2>&1)
printf '%s\n' "$OUT" | grep -qE 'pilot=[1-9][0-9]* later=0' || exit 1
printf '%s\n' "$OUT" | grep -q 'grammar=0.9.1' || exit 1
printf '%s\n' "$OUT" | grep -q 'P0=' && exit 1                                   # the priority count is retired under 0.9.1
# one demand row without phase convicts
sed 's/^\(REQ-001 | [^|]*|[^|]*|.*\) | phase: pilot$/\1/' PRD.md > NOPHASE.md
grep -q '^REQ-001 .* phase: pilot' NOPHASE.md && exit 1
if sh "$COURT" NOPHASE.md >/dev/null 2>&1; then exit 1; fi
sh "$COURT" NOPHASE.md --report 2>&1 | grep -qF 'GAP  join 15 (REQ-001): no phase: under grammar 0.9.1' || exit 1
# a third enum value convicts
sed 's/^\(REQ-001 .*\) | phase: pilot$/\1 | phase: someday/' PRD.md > BADPHASE.md
if sh "$COURT" BADPHASE.md >/dev/null 2>&1; then exit 1; fi
sh "$COURT" BADPHASE.md --report 2>&1 | grep -qF "GAP  join 15 (REQ-001): unknown phase 'someday'" || exit 1
# a later row acquits and is counted
sed 's/^\(REQ-001 .*\) | phase: pilot$/\1 | phase: later/' PRD.md > LATER.md
sh "$COURT" LATER.md >/dev/null 2>&1 || exit 1
sh "$COURT" LATER.md --report 2>&1 | grep -qE 'pilot=[0-9]+ later=1' || exit 1
# the legacy fixture: five fields, no phase — acquits, reports pilot=N (default) beside P0=
OUT=$(sh "$COURT" "$FIXTURES/prd-known-good.md" --report 2>&1)
printf '%s\n' "$OUT" | grep -q 'gaps=0' || exit 1
printf '%s\n' "$OUT" | grep -qE 'P0=[0-9]+/[0-9]+ pilot=[1-9][0-9]* later=0' || exit 1
exit 0
