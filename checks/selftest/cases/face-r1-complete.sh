#!/bin/sh
# Purpose: selftest case — ViD's face R1 (0.26.10.29): at each of the four sittings the sitting holds every section the
# skill lists for it, in the skill's order (CP 191-233, 323-333, 470-488, 575-578), each pause ending with the check
# its draft would remove (usability, P7), pauses 2 and 3 holding what changed since a ratification after Decided for
# you (0.26.10.29.6, S4), and every line prd.sh --pause
# prints in those sections. Convicts unless: each sitting's section ids are exactly the skill's list, in order; every
# id --pause prints under the questions, the new ViD decisions, the features and the plain sentences of a sitting that
# lists them is an item, an item two sections present in both; the scorecard is the one presented (against the
# previous pause's PRD, with its flags); a section the session writes, left out, is refused by name; declared
# empty, it is written empty. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-r1-complete: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
want() { case $1 in
  interview) echo 'questions challenge' ;; pause-1) echo 'thesis contract features findings decisions withdrawn' ;;
  pause-2) echo 'gaps never size decisions changed sensitive duplicates plain scorecard withdrawn' ;;
  pause-3) echo 'decisions changed rewordings findings duplicates plain scorecard withdrawn' ;; esac; }
# 0.26.10.29.6 (S1): a sitting of a later stop on disk makes an earlier stop a passed one; each step back starts fresh
fresh() { rm -f .vid/face/sitting.json; }
for s in interview pause-1 pause-2 pause-3; do
  fc_run write "$s" "lines.$s"; [ "$RC" = 0 ] || fail "$s refused a good lines file: $OUT"
  got=$(fc_json "' '.join(x['id'] for x in d['sections'])")
  [ "$got" = "$(want "$s")" ] || fail "$s holds '$got', not the skill's '$(want "$s")'"
done
# every id --pause prints in a sitting's script sections is an item of it
sh "$CHECKS/prd.sh" PRD.md --pause > P 2>/dev/null || true
ids() { awk -v h="$1" 'index($0, h) == 1 { on = 1; next } on && /^  / { split(substr($0, 3), f, " "); print f[1]; next } on { exit }' P; }
fresh
fc_run write pause-2 lines.pause-2
for pair in 'questions (must-never-break:never' 'plain sentences:plain'; do h=${pair%:*}; sec=${pair##*:}
  for id in $(ids "$h"); do fc_json "'$id' in [i['id'] for x in d['sections'] if x['id']=='$sec' for i in x['items']]" | grep -qx True || fail "pause-2 lacks $id, which --pause prints under '$h'"; done; done
[ "$(ids 'plain sentences' | wc -l | tr -d ' ')" -ge 5 ] || fail 'the fixture prints too few plain sentences to prove anything'
fresh
fc_run write pause-1 lines.pause-1
for id in $(ids 'features:'); do fc_json "'$id' in [i['id'] for x in d['sections'] if x['id']=='features' for i in x['items']]" | grep -qx True || fail "pause-1 lacks feature $id"; done
# a new ViD decision --pause prints lands under decided: strip one shown: label
sed 's/^\(A-005 | model_proposed | .*\) | shown: pause-1 [0-9]*$/\1/' PRD.md > X && mv X PRD.md
fc_run write pause-1 lines.pause-1
fc_json "[i['id'] for x in d['sections'] if x['id']=='decisions' for i in x['items']]" | grep -q "A-005" || fail 'a new ViD decision is not in decided'
# an item two sections present is in both: a sensitive rule keeps its plain sentence
sed 's/^\(REQ-006 | .*\)$/\1 | covers: DIM-consent/' PRD.md > X && mv X PRD.md
sh "$CHECKS/prd.sh" PRD.md --pause 2>/dev/null | grep -q '^  REQ-006 | T2 | DIM-consent | rests on A-005$' || fail 'the sensitive mutation did not apply'
fresh
fc_run write pause-2 lines.pause-2; [ "$RC" = 0 ] || fail "pause-2 refused: $OUT"
for sec in sensitive plain; do fc_json "'REQ-006' in [i['id'] for x in d['sections'] if x['id']=='$sec' for i in x['items']]" | grep -qx True || fail "REQ-006 is sensitive but missing from $sec"; done
[ "$(fc_json "sum(len(i['detail']) for x in d['sections'] if x['id']=='plain' for i in x['items'] if i['id']=='REQ-006')")" = 1 ] || fail "REQ-006's plain sentence carries another section's detail"
# the scorecard is the one presented: against .vid/scorecard-previous.md where it is there, with its flags line
cp PRD.md .vid/scorecard-previous.md
sed 's/^\(REQ-003 | [^|]*| \)T1 /\1T2 /' PRD.md > X && mv X PRD.md
want=$(sh "$CHECKS/scorecard.sh" PRD.md --previous .vid/scorecard-previous.md 2>/dev/null | sed -n 's/^complete *| counted *| //p')
fc_run write pause-2 lines.pause-2
[ "$(fc_json "[i['value'] for x in d['sections'] if x['id']=='scorecard' for i in x['items'] if i['id']=='complete'][0]")" = "$want" ] || fail "the sitting's scorecard is not the one against the previous pause: $(fc_json "[i['value'] for x in d['sections'] if x['id']=='scorecard' for i in x['items'] if i['id']=='complete']")"
fc_json "[i['id'] for x in d['sections'] if x['id']=='scorecard' for i in x['items']]" | grep -q "'flags'" || fail 'the scorecard leaves out its flags line'
rm -f .vid/scorecard-previous.md
# a section the session writes, left out: refused by name, nothing written
fresh; fc_run write pause-1 lines.pause-1
cp .vid/face/sitting.json before
grep -vE '^section findings|^item F-01|^recommend [|] Fix' lines.pause-1 > L1
fc_run write pause-1 L1; [ "$RC" != 0 ] || fail 'pause-1 without its findings section was written'
printf '%s\n' "$OUT" | grep -q 'section "findings"' || fail "the refusal does not name the section: $OUT"
cmp -s before .vid/face/sitting.json || fail 'a refused write changed the sitting'
# declared empty: written empty
{ cat L1; echo 'empty findings | the critic found nothing'; } > L2
fc_run write pause-1 L2; [ "$RC" = 0 ] || fail "a declared-empty section was refused: $OUT"
fc_json "[x['empty'] for x in d['sections'] if x['id']=='findings'][0]" | grep -qx True || fail 'the declared-empty section is not marked empty'
# a script section with nothing printed is declared empty by the script
fc_json "[x['empty'] for x in d['sections'] if x['id']=='features'][0]" | grep -qx False || fail 'features with lines marked empty'
exit 0
