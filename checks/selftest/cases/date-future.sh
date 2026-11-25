#!/bin/sh
# Purpose: selftest case — a date in the future is refused (FB-5 C1). prd-apply.sh and prd-consolidate.sh, each with a --date after
# today (UTC): refused before anything is written, the line naming today and saying to leave --date out; today's date and an earlier
# one are taken, whatever the machine's own time zone. And, where the skills are, the one line that a date is read from a command,
# never from the conversation, in vid-connect and in the project's CLAUDE.md template. Env: CHECKS.
set -eu
fail() { echo "date-future: $*" >&2; cat out.txt >&2 2>/dev/null; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"; cd "$T"
FX=$CHECKS/selftest/fixtures; TD=$(date -u +%Y-%m-%d); TM=$(date -u -v+1d +%Y-%m-%d 2>/dev/null || date -u -d '+1 day' +%Y-%m-%d)
run() { RC=0; "$@" > out.txt 2>&1 || RC=$?; }
refused() { [ "$RC" = "$1" ] || fail "$2 exited $RC, not $1"; grep -q "refused.*$TD.*leave --date out" out.txt || fail "$2 does not name today and the way out"; }
# prd-apply.sh
mkdir a; sed '/^- .* — final — /d' "$FX/prd-094-good.md" > a/PRD.md; cp a/PRD.md a.md; printf 'field REQ-006 phase later\n' > ed.txt
for x in "$TM" 2999-01-01 2999-1-1; do run sh "$CHECKS/prd-apply.sh" a/PRD.md ed.txt --date "$x"; refused 2 "prd-apply --date $x"; cmp -s a.md a/PRD.md || fail "prd-apply --date $x wrote"; [ "$(ls -A a)" = PRD.md ] || fail 'prd-apply left a file beside PRD.md'; done
for z in Pacific/Kiritimati Pacific/Pago_Pago; do cp a.md a/PRD.md; run env TZ="$z" sh "$CHECKS/prd-apply.sh" a/PRD.md ed.txt --date "$TD"; [ "$RC" = 0 ] || fail "prd-apply refused today's date in $z"; done
for x in 2026-08-28 2026-8-28; do cp a.md a/PRD.md; run sh "$CHECKS/prd-apply.sh" a/PRD.md ed.txt --date "$x"; [ "$RC" = 0 ] && ! cmp -s a.md a/PRD.md || fail "prd-apply refused an earlier date, $x"; done
# prd-consolidate.sh
mkdir c d; cp "$FX/prd-known-good.md" c/PRD.md; cp c/PRD.md c.md; cp c.md d/PRD.md
for x in "$TM" 2999-01-01; do run sh "$CHECKS/prd-consolidate.sh" c/PRD.md --date "$x"; refused 1 "prd-consolidate --date $x"; cmp -s c.md c/PRD.md && [ "$(ls -A c)" = PRD.md ] || fail "prd-consolidate --date $x wrote"; done
run sh "$CHECKS/prd-consolidate.sh" c/PRD.md --date "$TD"; [ "$RC" = 0 ] && [ -f "c/PRD-HISTORY-$TD.md" ] || fail "prd-consolidate refused today's date"
run sh "$CHECKS/prd-consolidate.sh" d/PRD.md --date 2026-09-21; [ "$RC" = 0 ] && [ -f d/PRD-HISTORY-2026-09-21.md ] || fail 'prd-consolidate refused an earlier date'
# the line
R=$CHECKS/..; if [ -f "$R/skills/vid-connect/SKILL.md" ]; then for f in skills/vid-connect/SKILL.md templates/CLAUDE.project.md; do
  tr '\n' ' ' < "$R/$f" | tr -s ' ' > flat.txt; grep -qF 'A date or a time written anywhere is read from a command' flat.txt && grep -qF 'never from the conversation' flat.txt || fail "$f lacks the line on dates"; done; fi
echo 'date-future: ok'
