#!/bin/sh
# Purpose: selftest case — the strength pass (0.26.10.29.4 phase 3, R1's "Done when" in the skill text). A text check,
# like review-rounds-pointers.sh, gated on ViD's own skills beside checks/ (a project keeps no copy). Convicts unless the
# lens brief, passes/counterexample-lens.md, receives BASELINE.md's test environment, ARCHITECTURE.md's seam rows and
# the open entries of prd.sh --arms, asks the per-row question in batches and the four table questions and the
# weakened-arm question, and returns finding rows written as pass `strength`; unless vid-test-inventory §3 places the
# pass last, before every ratification, in all three modes, the chain block shows it after the governance rows and
# before the sitting, and the modes list says so in each mode and no longer says
# "one round each unless a lens is not dry"; unless §6 carries the round at materialisation, not run in ticket mode;
# and unless vid-create-prd's findings record lists pass `strength`. Env: CHECKS.
set -eu
S=$CHECKS/../skills
[ -f "$S/vid-test-inventory/SKILL.md" ] || { echo 'needs skills/'; exit 77; }
BAD=''
no() { BAD="$BAD
strength-pass-pointers: $*"; }
flat() { tr '\n' ' ' | sed 's/^[[:space:]]*> *//' | tr -s ' '; }
L=$S/vid-test-inventory/passes/counterexample-lens.md
I=$S/vid-test-inventory/SKILL.md
R=$(grep '^receives:' "$L" || true)
for t in "BASELINE.md's test environment" "ARCHITECTURE.md's seam rows" 'prd.sh --arms'; do
  printf '%s' "$R" | grep -qF -- "$t" || no "the lens brief does not receive $t"
done
B=$(flat < "$L")
for t in 'in batches by REQ domain and axis' '**Rows that disagree.**' '**Rows that repeat.**' \
  '**Rows the stand-in cannot test.**' '**Censuses that cannot reach.**' '**Weakened arms.**' 'pass `strength`'; do
  printf '%s' "$B" | grep -qF -- "$t" || no "the lens brief does not say: $t"
done
sec() { awk -v h="$2" 'index($0, h) == 1 { on = 1; print; next } on && /^## / { exit } on' "$1" | flat; }
sec "$I" '## 3.' | grep -qF 'last, before every ratification, in all three modes' || no '§3 does not place the pass last in all three modes'
M=$(awk '/^Three modes, chosen by/ { on = 1 } on && /^## / { exit } on' "$I" | flat)
for m in 'init mode' 'append mode' 're-derivation mode'; do
  printf '%s' "$M" | awk -v m="**$m**" '{ i = index($0, m); if (!i) exit 1; r = substr($0, i + length(m)); j = index(r, "- **"); if (j) r = substr(r, 1, j); if (index(r, "strength pass last (§3")) exit 0; exit 1 }' ||
    no "the modes list does not run the strength pass last in $m"
done
# the chain block shows the same order: the strength pass after the governance rows, before the sitting
awk '/^## The chain/ { on = 1; next } on && /^## / { exit } on' "$I" | awk '
  /governance rows/ && !g { g = NR } /strength pass/ && !p { p = NR } /RATIFICATION SITTING/ && !r { r = NR }
  END { exit !(g && p && r && g < p && p < r) }' || no 'the chain block does not put the strength pass after the governance rows and before the sitting'
printf '%s' "$M" | grep -qF 'one round each unless a lens is not dry' && no 'the modes list still says "one round each unless a lens is not dry"'
X=$(sec "$I" '## 6.')
printf '%s' "$X" | grep -qF 'One more strength round at materialisation' || no '§6 does not carry the round at materialisation'
printf '%s' "$X" | grep -qF 'In ticket mode this round does not run' || no '§6 does not keep the round out of ticket mode'
C=$S/vid-create-prd/SKILL.md
if [ -f "$C" ]; then
  awk '/^## The findings record/ { on = 1; next } on && /^## / { exit } on' "$C" | flat | grep -qF '| `final` | `strength`' ||
    no 'vid-create-prd, "The findings record" does not list pass `strength`'
fi
[ -z "$BAD" ] || { printf '%s\n' "$BAD" | sed '/^$/d' >&2; exit 1; }
exit 0
