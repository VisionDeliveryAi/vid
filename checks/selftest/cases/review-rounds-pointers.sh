#!/bin/sh
# Purpose: selftest case — reviews converge, and every repair is read again (0.26.10.29.3 phase 2, R1). A text
# check, like create-prd-sentences.sh, gated on ViD's own skills beside checks/ (a project keeps no copy). Convicts
# unless vid-create-prd's "Pass mechanics" holds the one rule, under its own heading "### Reviews converge": no count
# cap, the re-read in `mode: delta` after every repaired round, the three stop tests, the one list for the owner and
# the loop after the owner's rulings; §11 no longer says "One round"; and each place that runs a repaired review
# points to it by name, `"Reviews converge"`: create-prd's §10, §11 and 7b, vid-test-inventory §5, vid-add §2, vid-fix
# (a), vid-develop's two-channel rule and vid-design §4; and each of those five doors writes the line with its round,
# `review: delta, round <r>, <n> findings`, never phase 1's form without one. Env: CHECKS.
set -eu
S=$CHECKS/../skills
[ -f "$S/vid-create-prd/SKILL.md" ] || { echo 'needs skills/'; exit 77; }
BAD=''
no() { BAD="$BAD
review-rounds-pointers: $*"; }
flat() { tr '\n' ' ' | sed 's/^[[:space:]]*> *//' | tr -s ' '; }
C=$S/vid-create-prd/SKILL.md
# the rule: "### Reviews converge" inside "## Pass mechanics"
R=$(awk '/^## Pass mechanics/ { pm = 1; next } pm && /^## / { exit } pm && /^### Reviews converge/ { on = 1; next } on && /^###? / { exit } on' "$C" | flat)
if [ -z "$R" ]; then no 'Pass mechanics has no "### Reviews converge" section'
else
  for t in 'A caller never caps how many findings a pass returns' 'mode: delta' 'whatever their severity' \
    'a re-read round with no blocking finding' 'not lower than the round before' 'the end of round 3' \
    'the owner never fixes anything' 'accepted A-NNN' 'never by itself'; do
    printf '%s' "$R" | grep -qF -- "$t" || no "the rule does not say: $t"
  done
fi
P='"Reviews converge"'
sec() { awk -v h="$2" 'index($0, h) == 1 { on = 1; print; next } on && /^#/ { exit } on' "$1" | flat; }
for h in '### 10.' '### 11.'; do sec "$C" "$h" | grep -qF -- "$P" || no "create-prd $h does not point to $P"; done
sec "$C" '### 11.' | grep -qF 'One round.' && no 'create-prd §11 still says "One round."'
awk '/^\*\*7b —/ { on = 1 } on && !NF { exit } on' "$C" | flat | grep -qF -- "$P" || no "create-prd 7b does not point to $P"
for x in 'vid-test-inventory|## 5.' 'vid-add|## 2.' 'vid-design|## 4.' 'vid-develop|## The two-channel question rule'; do
  f=$S/${x%%|*}/SKILL.md; [ -f "$f" ] || { no "no $f"; continue; }
  sec "$f" "${x#*|}" | grep -qF -- "vid-create-prd, $P" || no "${x%%|*} ${x#*|} does not point to vid-create-prd, $P"
done
awk '/^- \(a\)/ { on = 1 } on && /^- \(b\)/ { exit } on' "$S/vid-fix/SKILL.md" | flat | grep -qF -- "vid-create-prd, $P" || no "vid-fix (a) does not point to vid-create-prd, $P"
# 0.26.10.29.3 (phase 2 R1, R2): each door writes the line that names its round, never phase 1's form without one
for d in vid-add vid-fix vid-test-inventory vid-design vid-develop; do
  f=$S/$d/SKILL.md; [ -f "$f" ] || continue
  grep -qF 'review: delta, <n> findings' "$f" && no "$d still writes the line without a round, review: delta, <n> findings"
  flat < "$f" | grep -qF 'review: delta, round <r>, <n> findings' || no "$d does not write review: delta, round <r>, <n> findings"
done
# a door that still exempts its rulings from the re-read
grep -n 'not reviewed again' "$S"/vid-add/SKILL.md "$S"/vid-fix/SKILL.md "$S"/vid-test-inventory/SKILL.md "$S"/vid-develop/SKILL.md "$S"/vid-design/SKILL.md > /dev/null 2>&1 && no 'a door still says its rulings are "not reviewed again"'
[ -z "$BAD" ] || { printf '%s\n' "$BAD" | sed '/^$/d' >&2; exit 1; }
exit 0
