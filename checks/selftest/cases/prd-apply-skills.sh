#!/bin/sh
# Purpose: selftest case — every place a skill applies rulings to PRD.md names the one writer (FB-1 A2). vid-create-prd's
# pause 1, pause 2, repair and pause 3 steps and its consolidation section each name checks/prd-apply.sh; so do vid-add,
# vid-init and vid-test-inventory once, vid-design and vid-fix twice and vid-develop once; and RECORDS.md's PRD.md row
# names it among the writers. Every missing place is listed. Reads skills/ and RECORDS.md: exits 77 where checks/ stands
# alone. Env: CHECKS.
set -eu
R="$CHECKS/.."
[ -d "$R/skills" ] && [ -f "$R/RECORDS.md" ] || exit 77
miss=''
# step <heading> <next heading pattern>: the vid-create-prd text from that heading to the next names the writer
step() { awk -v h="$1" -v nx="$2" '$0 == h { on = 1; next } on && $0 ~ nx { exit } on' "$R/skills/vid-create-prd/SKILL.md" | grep -q 'checks/prd-apply\.sh' \
  || miss="$miss${miss:+; }vid-create-prd at '$1'"; }
step '### 5. Pause 1 — thesis + contract ratification' '^###? '
step '### 8. Pause 2 — gap answers' '^###? '
step '### 11. Repair — a diff, then read again' '^###? '
step '### 12. Pause 3 — final ratification' '^###? '
step '## Consolidation — the scheduled event (v0.9.1 3.4: 7a, then 7b)' '^## '
# skill <name> <places>: that skill names the writer on at least that many lines
skill() { n=$(grep -c 'checks/prd-apply\.sh' "$R/skills/$1/SKILL.md" || true); [ "$n" -ge "$2" ] || miss="$miss${miss:+; }$1 ($n of $2)"; }
skill vid-add 1; skill vid-init 1; skill vid-design 2; skill vid-test-inventory 1; skill vid-develop 1; skill vid-fix 2
grep '^| `PRD.md` |' "$R/RECORDS.md" | grep -q 'checks/prd-apply\.sh' || miss="$miss${miss:+; }RECORDS.md's PRD.md row"
[ -z "$miss" ] || { echo "prd-apply-skills: these places do not name checks/prd-apply.sh: $miss" >&2; exit 1; }
echo 'prd-apply-skills: ok'
