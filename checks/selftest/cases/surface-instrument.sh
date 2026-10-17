#!/bin/sh
# Purpose: selftest case — the surface instrument (v0.9.2 spec 3.4, §5 Phase
# B's cut line, §7.6). The deterministic half over the fixture in
# checks/selftest/fixtures/surface-instrument/: (1) the reference instrument
# passes every expectation of the checker (the stray control fails its row;
# navigations = states × engines; the empty scaffold collects and fails every
# case; an emptied hook fails `pins not authored`; the grid, the missing
# element, the extra identifier, the notation and unit variants, the wrong
# paint, the 0.9.1 pin example, the console error, the missing marker; the
# extractor and the instrument on one module); (2) the checker's polarity —
# an instrument that never runs its hook, and one that navigates inside a
# hook, are convicted by name; (3) the inventory court accepts surface rows
# citing the instrument at a stamp, and refuses an appended row the
# instrument's table does not yet name (3.4's rhythm: the pass regenerates
# the file first). Env: CHECKS.
set -eu
FIX="$CHECKS/selftest/fixtures/surface-instrument"
[ -d "$FIX" ] || { echo 'surface-instrument: fixture missing' >&2; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# (1) the known-good acquits
OUT=$(sh "$FIX/surface-check.sh" "$FIX/reference/surfaces.sh" 2>&1) || { printf '%s\n' "$OUT" >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'surface-check: expectations=20 failed=0' || { printf '%s\n' "$OUT" >&2; exit 1; }
# (2) polarity: a hook never run is convicted; a hook that navigates is convicted
sed '/harness_run_hook/d' "$FIX/reference/surfaces.sh" > "$T/nohook.sh"
if sh "$FIX/surface-check.sh" "$T/nohook.sh" >"$T/nohook.out" 2>&1; then echo 'surface-instrument: an instrument that never runs its hooks passed the checker' >&2; exit 1; fi
grep -q 'FAIL  correct: every pins hook asserted' "$T/nohook.out" || { cat "$T/nohook.out" >&2; exit 1; }
sed 's/^pins_P01_empty() {$/pins_P01_empty() { harness_load "alpha" anonymous "\/" >\/dev\/null/' "$FIX/reference/surfaces.sh" > "$T/nav.sh"
grep -q 'pins_P01_empty() { harness_load' "$T/nav.sh" || exit 1
if sh "$FIX/surface-check.sh" "$T/nav.sh" >"$T/nav.out" 2>&1; then echo 'surface-instrument: a hook that navigates passed the checker' >&2; exit 1; fi
grep -q 'FAIL  correct: navigations = states' "$T/nav.out" || { cat "$T/nav.out" >&2; exit 1; }
grep -q 'FAIL  one module' "$T/nav.out" || exit 1
# (3) the court: rows citing the instrument join at the stamp; an appended row the table does not name is a GAP
R="$T/repo"; mkdir -p "$R/tests/invariants" "$R/checks"; cd "$R"
git init -q . && git config user.email f@x && git config user.name F
cp "$FIX/reference/surfaces.sh" tests/invariants/surfaces.sh
printf '# Purpose: the shell row ROW-001 (fixture stub)\n' > tests/invariants/shell.sh
cp "$FIX/INVENTORY.md" INVENTORY.md
mkdir -p app && printf '```vid-placement\napp/\n```\n' > CLAUDE.md
git add -A && git commit -q -m 'fixture' && SHA=$(git rev-parse --short HEAD)
sed -i.bak "s#| tests/invariants/surfaces.sh | origin: derived#| tests/invariants/surfaces.sh | proved-red: $SHA | origin: derived#" INVENTORY.md && rm INVENTORY.md.bak
git add INVENTORY.md   # default mode joins the staged rows (the commit under construction)
OUT=$(sh "$CHECKS/inventory.sh" --report 2>&1) || { printf '%s\n' "$OUT" >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q 'par: rows=4 materialised=4 legitimate=0 deploy-owed=0 other=0 — holds' || { printf '%s\n' "$OUT" >&2; exit 1; }
sh "$CHECKS/inventory.sh" >/dev/null 2>&1 || { echo 'surface-instrument: the stamped rows citing the instrument do not pass the court' >&2; exit 1; }
printf 'ROW-005 | surface | /jobs | anonymous | P02/empty | P02/empty is transcribed property-for-property; pins: the empty notice present | REQ-004 | tests/invariants/surfaces.sh | proved-red: %s | origin: derived\n' "$SHA" > "$T/row5"
awk -v r="$(cat "$T/row5")" '/^```$/ && !done { print r; done = 1 } { print }' INVENTORY.md > "$T/inv" && mv "$T/inv" INVENTORY.md
git add INVENTORY.md
if sh "$CHECKS/inventory.sh" >/dev/null 2>&1; then echo 'surface-instrument: a row the instrument never names passed the court' >&2; exit 1; fi
sh "$CHECKS/inventory.sh" --report 2>&1 | grep -q "GAP  ROW-005 — 'tests/invariants/surfaces.sh' at proved-red $SHA never names the row" || { sh "$CHECKS/inventory.sh" --report 2>&1 | grep ROW-005 >&2; exit 1; }
exit 0
