#!/bin/sh
# Purpose: selftest case — the genus bar and the per-arm probe count, as text (0.26.10.29.4 phase 3, R3 and R5). A text
# check gated on ViD's own skills beside checks/ (a project keeps no copy). Convicts unless: the genus lens brief
# (passes/genus-lens.md) and vid-test-inventory §2's "Loop until dry" each carry the bar (a believable wrong build) and
# the stop rule's three tests (a round that keeps no candidate; one that keeps no fewer than the round before; the end
# of round 3); §1's Tier-0 table row and vid-fix's probe bound give §4.3's count (a demand item per fail-if arm and way
# in), not the old "one sibling per protection" or "~one probe per protection", and vid-fix reruns an existing probe
# only when it covers this arm through this way in, an unprobed one getting its own row; and no skill, pass or template still
# says the old "10–15" probe count. Env: CHECKS.
set -eu
S=$CHECKS/../skills
[ -f "$S/vid-test-inventory/SKILL.md" ] || { echo 'needs skills/'; exit 77; }
BAD=''
no() { BAD="$BAD
genus-bar-and-arm-count: $*"; }
flat() { tr '\n' ' ' | tr -s ' '; }
stoprule() { # $1 the text, $2 its name
  case "$1" in *'believable wrong build'*) ;; *) no "$2 does not state the bar (a believable wrong build)" ;; esac
  case "$1" in *'keeps no candidate'*) ;; *) no "$2 lacks the stop test 'a round that keeps no candidate'" ;; esac
  case "$1" in *'no fewer than the round before'*) ;; *) no "$2 lacks the stop test 'no fewer than the round before'" ;; esac
  case "$1" in *'end of round 3'*) ;; *) no "$2 lacks the stop test 'the end of round 3'" ;; esac
}
I=$S/vid-test-inventory/SKILL.md
stoprule "$(flat < "$S/vid-test-inventory/passes/genus-lens.md")" 'passes/genus-lens.md'
stoprule "$(awk '/^\*\*Loop until dry\.\*\*/ { on = 1 } on && /^$/ { exit } on' "$I" | flat)" '§2 "Loop until dry"'
T0=$(grep '^| Tier-0 |' "$I" || true)
[ -n "$T0" ] || no '§1 has no Tier-0 table row'
case "$T0" in *'one sibling per protection'*) no "§1's Tier-0 row still says 'one sibling per protection'" ;; esac
case "$T0" in *'fail-if arm'*'way in'*) ;; *) no "§1's Tier-0 row does not give §4.3's count (per fail-if arm and way in)" ;; esac
F=$(flat < "$S/vid-fix/SKILL.md")
case "$F" in *'one probe per protection'*) no "vid-fix still bounds probes at '~one probe per protection'" ;; esac
case "$F" in *'§4.3'*'fail-if arm'*|*'fail-if arm'*'§4.3'*) ;; *) no 'vid-fix does not point to vid-test-inventory §4.3 for the per-arm count' ;; esac
# a rerun of an existing probe holds only for this arm through this way in; an unprobed arm or way in gets its own row
case "$F" in *'already has a hostility sibling, the fix re-runs the ritual against it rather than adding a second row'*) no 'vid-fix still reruns any existing sibling rather than adding a row, whatever arm and way in the correction shows' ;; esac
case "$F" in *'this arm through this way in'*'gets its own'*) ;; *) no 'vid-fix does not give an arm or way in the correction shows unprobed its own row' ;; esac
L=$(grep -rln '10–15' "$S" "$CHECKS/../templates" 2>/dev/null || true)
[ -z "$L" ] || no "the old 10–15 probe count is still in: $(printf '%s ' $L)"
[ -z "$BAD" ] || { printf '%s\n' "$BAD" >&2; exit 1; }
echo 'genus-bar-and-arm-count: ok'
