#!/bin/sh
# Purpose: selftest case — journeys paid per transition (v0.9.2 spec 3.5,
# §7.7; the authorship completeness case of §5 Phase C). Over the fixture in
# checks/selftest/fixtures/journey-transitions/: the reference return and
# tests acquit under return-check.sh (five rows → five returns; four
# transitions → four transition cases, each operated through the engine
# door; four verdict lines); a return of four lines for five rows convicts
# naming the missing row; a test whose transition 3 is performed through the
# API door convicts naming transition 3; a test missing a step convicts;
# three verdict lines for four transitions convict; on the empty product
# every case is collected and fails, none skipped. Env: CHECKS.
set -eu
FIX="$CHECKS/selftest/fixtures/journey-transitions"
[ -d "$FIX" ] || { echo 'journey-transitions: fixture missing' >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
OUT=$(sh "$FIX/return-check.sh" "$FIX/reference/RETURN.md" --verdicts "$FIX/reference/VERDICTS.md" 2>&1) || { printf '%s\n' "$OUT" >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'return-check: expectations=11 failed=0' || { printf '%s\n' "$OUT" >&2; exit 1; }
# four returns for five rows: convicted, the missing row named
cp "$FIX/reference/"*.sh "$T/"; grep -v '^ROW-013' "$FIX/reference/RETURN.md" > "$T/RETURN.md"
if sh "$FIX/return-check.sh" "$T/RETURN.md" >"$T/o1" 2>&1; then echo 'journey-transitions: four returns for five rows passed' >&2; exit 1; fi
grep -q 'FAIL  completeness' "$T/o1" && grep -q 'no return for: ROW-013' "$T/o1" || { cat "$T/o1" >&2; exit 1; }
# transition 3 performed through the API door: convicted naming it
cp "$FIX/reference/RETURN.md" "$T/RETURN.md"
sed 's/^  harness_press "\$1" "\$2" Withdraw$/  harness_api "$1" "$2" DELETE \/applications\/role-7 >\/dev\/null/' "$FIX/reference/journeys.sh" > "$T/journeys.sh"
grep -q 'harness_api "$1" "$2" DELETE' "$T/journeys.sh" || exit 1
if sh "$FIX/return-check.sh" "$T/RETURN.md" >"$T/o2" 2>&1; then echo 'journey-transitions: a transition reached by API passed' >&2; exit 1; fi
grep -q 'rejected transitions: 3(no control operated) 3(operated through the API door)' "$T/o2" || { cat "$T/o2" >&2; exit 1; }
grep -q "ok    journey ROW-010: every transition's step asserts its effect" "$T/o2" || exit 1   # the effect held — the API did the work; the door is what convicts
# a missing step: convicted
sed '/^journey_ROW_010_transition_4() {$/,/^}$/d' "$FIX/reference/journeys.sh" > "$T/journeys.sh"
if sh "$FIX/return-check.sh" "$T/RETURN.md" >"$T/o3" 2>&1; then exit 1; fi
grep -q 'rejected transitions: 4(no control operated)' "$T/o3" || { cat "$T/o3" >&2; exit 1; }
# three verdict lines for four transitions: convicted; four acquit
cp "$FIX/reference/journeys.sh" "$T/journeys.sh"; head -n 3 "$FIX/reference/VERDICTS.md" > "$T/V3.md"
if sh "$FIX/return-check.sh" "$T/RETURN.md" --verdicts "$T/V3.md" >"$T/o4" 2>&1; then exit 1; fi
grep -q 'FAIL  verdicts: one per transition for ROW-010 (4 transitions → 4 verdict lines; found 3)' "$T/o4" || { cat "$T/o4" >&2; exit 1; }
sh "$FIX/return-check.sh" "$T/RETURN.md" --verdicts "$FIX/reference/VERDICTS.md" >/dev/null 2>&1 || exit 1
# the empty product: every case collected and failed, no deferral
sh "$FIX/return-check.sh" "$FIX/reference/RETURN.md" --product empty >"$T/o5" 2>&1 || { cat "$T/o5" >&2; exit 1; }
grep -q 'ok    empty product: every transition case and behavior case collected and failed' "$T/o5" || exit 1
exit 0
