#!/bin/sh
# Purpose: selftest case — init names its consolidation (FIX-BATCH-T2 §3, B-14). vid-init's §4 says call point 1 ends with
# consolidation, run through the plugin's own copy, sh "${CLAUDE_PLUGIN_ROOT}/checks/prd-consolidate.sh" (the project has no
# checks/ before step 6), and the list of what init still does names it; vid-test-inventory's init sentence and
# vid-create-prd's trigger name init's spec commit and the plugin's copy at init, and neither says "initial commit" there.
# Needs the skills beside checks/ (exit 77 without them). Env: CHECKS.
set -eu
fail() { echo "init-consolidation-text: $*" >&2; exit 1; }
K=$CHECKS/../skills; [ -f "$K/vid-init/SKILL.md" ] || { echo 'init-consolidation-text: needs the skills beside checks/'; exit 77; }
flat() { tr '\n' ' ' | tr -s ' '; }
PC='${CLAUDE_PLUGIN_ROOT}/checks/prd-consolidate.sh'
S4=$(awk '/^## 4\. / { on = 1; next } on && /^## 5\. / { exit } on' "$K/vid-init/SKILL.md" | flat)
printf '%s' "$S4" | grep -qi 'consolidation' || fail "vid-init's §4 does not name consolidation"
printf '%s' "$S4" | grep -qF "$PC" || fail "vid-init's §4 does not run the plugin's copy of prd-consolidate.sh"
L=$(awk '/^\*\*Init makes the spec only/ { on = 1 } on && /^$/ { exit } on' "$K/vid-init/SKILL.md" | flat)
printf '%s' "$L" | grep -qi 'consolidation' || fail "the list of what init still does does not name consolidation"
I=$(flat < "$K/vid-test-inventory/SKILL.md" | grep -o 'In init mode, consolidation[^§]*§*[^.]*\.[^.]*\.' | head -n 1)
[ -n "$I" ] || fail "no init sentence on consolidation in vid-test-inventory"
printf '%s' "$I" | grep -qi 'spec commit' || fail "vid-test-inventory's init sentence does not name the spec commit: $I"
! printf '%s' "$I" | grep -qi 'initial commit' || fail "vid-test-inventory's init sentence still says the initial commit: $I"
printf '%s' "$I" | grep -qF "$PC" || fail "vid-test-inventory's init sentence does not name the plugin's copy: $I"
C=$(awk '/^## Consolidation — the scheduled event/ { on = 1; next } on && /^\*\*7b/ { exit } on' "$K/vid-create-prd/SKILL.md" | flat)
printf '%s' "$C" | grep -qi 'spec commit' || fail "vid-create-prd's trigger does not name the spec commit"
! printf '%s' "$C" | grep -qi 'initial commit' || fail "vid-create-prd's trigger still says the initial commit"
printf '%s' "$C" | grep -qF "$PC" || fail "vid-create-prd's 7a does not name the plugin's copy at init"
echo 'init-consolidation-text: ok'
