#!/bin/sh
# Purpose: selftest case — usability 3 (0.26.10.29.6, S1, S2): the eleven sittings of stops 6 to 9. Each is written
# from fixture lines, in the order of its stop, with no PRD needed; convicts unless each holds exactly the spec's
# sections (id, kind, title), their buttons in order, its stop and the last line of the message (none where the spec
# gives none), and its end closes no stop; unless what is asked on its own is so in the sitting written (every item
# of an alone section; a gap recommended "Leave it out"; an entry of "Look here first" recommended "Remove it"), the
# two host settings and stages-own answered Yes or No, the access item carrying its fixed line; unless a figure the
# session writes carries its value (`value |`), and a choice under an alone item is kept; and unless stages-own
# takes one item at a writing, and who makes the design two choices; and unless, with stages-own on disk, a write of
# design-lines writes nothing. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-stops-6-9: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
mv PRD.md PRD.away   # none of these sittings reads the PRD
# the spec's table, one line a sitting: name, stop, last line ("-" for none), then id:kind:title:buttons a section
want() { case $1 in
  technical) echo '6|-|hints:questions:Your hints on design and technology:In my own words,You pick,Skip|where:questions:Where it runs:Choose,In my own words|access:alone:Asked on its own:In my own words' ;;
  design-who) echo '7|-|who:questions:Who makes the design:Choose' ;;
  design-gaps) echo "7|With these rulings, the design's gaps are settled.|brief-only:list:In the brief, not in the design:Draw it,Leave it out,Owe it|design-only:list:In the design, not in the brief:Adopt it,Drop it,Fence it off|unknown:list:ViD cannot tell what this is:ViD's guess is right,Name it" ;;
  design-lines) echo '7|I have ruled every line.|lines:objections:Where the design and the PRD disagree:Design wins,PRD wins,Both change,Not a disagreement' ;;
  design-approval) echo '7|I approve the design.|decides:text:What the design decides:|findings:objections:Findings on the changes:Fix it,Leave it|alone:alone:Asked on their own:Choose,In my own words' ;;
  tests) echo '8|I approve the test list. I have not read it line by line.|counted:figures:The test list, counted:|look:list:Look here first:Keep it,Remove it,Change it|kinds:list:Kinds of failure ViD proposes to test for:Keep it,Drop it|alone:alone:Asked on their own:Choose,In my own words' ;;
  tests-review) echo '8|With these rulings, I approve the changes to the test list.|findings:objections:Findings on the changes:Fix it,Leave it|alone:alone:Asked on their own:Choose,In my own words' ;;
  consolidation) echo '8|I approve these changes.|changes:list:What consolidation changed in the PRD:Fine,Change|alone:alone:Asked on their own:Choose,In my own words' ;;
  settings) echo '9|-|settings:alone:Two settings on this machine:Choose' ;;
  stages) echo '9|With these answers, I approve the stage cut.|cuts:figures:The cuts, counted:|which:questions:Which cut:Choose|stages:text:The stages of the recommended cut:|open:questions:Product choices left open:Choose,In my own words|findings:objections:Findings on the changes the cut needs:Fix it,Leave it' ;;
  stages-own) echo '9|-|alone:alone:Asked on its own:Choose' ;;
esac; }
L() { printf '%s\n' "$@" > "lines.$S"; }
S=technical; L 'section hints' 'item H1 | Any hint on how it should look?' 'section where' 'item W1 | Where should it run?' 'choice | A small rented server' 'choice | Your own machine' 'recommend | A small rented server' 'section access' 'item X1 | How does ViD get access to the server?'
S=design-who; L 'section who' 'item D1 | Who makes the design?' 'choice | You, in your own tool, from the brief' 'choice | ViD, here' 'recommend | You, in your own tool, from the brief'
S=design-gaps; L 'section brief-only' 'item S-04 | The empty inbox screen' 'recommend | Leave it out' 'item S-05 | The error banner' 'recommend | Draw it' 'section design-only' 'item E-01 | A help corner' 'recommend | Fence it off' 'section unknown' 'item U-01 | A grey box on the settings screen' 'recommend | none'
S=design-lines; L 'section lines' 'item L1 | Button spacing: 8 in the design, 12 in the PRD' 'detail | The design is newer.' 'recommend | Design wins'
S=design-approval; L 'section decides' 'item P1 | The design decides' 'detail | Two screens and their states.' 'section findings' 'item F-01 | The empty state has no words' 'recommend | Fix it' 'section alone' 'item A1 | Fence off the help corner?' 'choice | Yes' 'choice | No'
S=tests; L 'section counted' 'item rows | Tests in the list' 'value | 214' 'section look' 'item ROW-0007 | The unsubscribe test waits on your decision' 'recommend | Keep it' 'item ROW-0009 | An owed test with no class' 'recommend | Remove it: the rule it tested is gone' 'section kinds' 'item K1 | A digest sent twice' 'section alone' 'item W1 | Two failure clauses are narrowed' 'detail | REQ-003, clause 2: narrowed'
S=tests-review; L 'section findings' 'item F-02 | A row has no fail-if' 'recommend | Fix it' 'empty alone | none this time'
S=consolidation; L 'section changes' 'item C1 | Two requirements merged' 'section alone' 'item C2 | A clause dropped' 'detail | It was the second clause of the rule on digests'
S=settings; L 'section settings' 'item set-1 | Let ViD run its checks without asking each time?' 'item set-2 | Keep the panel open at start?'
S=stages; L 'section cuts' 'item rung-1 | Three stages' 'value | 3 stages, 41 tests in the first' 'section which' 'item which | Which cut?' 'choice | Three stages' 'choice | One stage' 'recommend | Three stages' 'section stages' 'item s1 | Stage 1' 'detail | Subscribe and get the digest.' 'empty open | none' 'empty findings | none'
S=stages-own; L 'section alone' 'item stage-0 | Build stage 0, the walking skeleton, first?' 'recommend | Yes'
for S in technical design-who design-gaps design-lines design-approval tests tests-review consolidation settings stages stages-own; do
  fc_run write "$S" "lines.$S"; [ "$RC" = 0 ] || fail "$S refused its lines: $OUT"
  w=$(want "$S"); stop=${w%%|*}; rest=${w#*|}; close=${rest%%|*}; secs=${rest#*|}
  [ "$(fc_json "d['sitting'], d['stop'], d['state']" | tr -d "(),'")" = "$S $stop waiting" ] || fail "$S: $(fc_json "d['sitting'], d['stop'], d['state']")"
  [ "$close" = - ] && close=''
  [ "$(fc_json "d['closing']")" = "$close" ] || fail "$S ends '$(fc_json "d['closing']")', not '$close'"
  got=$(fc_json "'|'.join(x['id']+':'+x['kind']+':'+x['title']+':'+','.join(a['label'] for a in x['acts']) for x in d['sections'])")
  [ "$got" = "$secs" ] || fail "$S holds
  $got
not the spec's
  $secs"
  [ -n "$(fc_json "d['ready']")" ] || fail "$S has no ready phrase"
  nalone=$(fc_json "sum(1 for x in d['sections'] if x['kind']=='alone' for i in x['items'] if not i['alone'])"); [ "$nalone" = 0 ] || fail "$S: $nalone items of an alone section not asked on their own"
  fc_run end "$S"; [ "$RC" = 0 ] || fail "end $S refused: $OUT"
  [ "$(fc_stand "d['stops'][$stop - 1]['state']")" = here ] || fail "ending $S closed stop $stop"
  [ "$(fc_stand "d['stops'][$stop - 1]['sitting']")" = True ] || fail "the standing says stop $stop has no sitting"
  cp ".vid/face/sitting.json" "sit.$S"
done
# a later stop's sitting on disk is never replaced by an earlier stop's (S1)
cp .vid/face/sitting.json last
fc_run write design-lines lines.design-lines; [ "$RC" = 0 ] || fail "a write behind the map did not exit 0: $OUT"
cmp -s last .vid/face/sitting.json || fail 'design-lines replaced the stop-9 sitting on disk'
rm -f .vid/face/sitting.json   # the refusals below in a project with no sitting
j() { python3 -c "import json; d=json.load(open('sit.$1')); print($2)"; }
it() { echo "[i for x in d['sections'] if x['id']=='$1' for i in x['items'] if i['id']=='$2'][0]"; }
# what is asked on its own
[ "$(j design-gaps "$(it brief-only S-04)['alone']")" = True ] || fail 'a gap recommended "Leave it out" is not asked on its own'
[ "$(j design-gaps "$(it brief-only S-05)['alone'], $(it brief-only S-05)['preset']" | tr -d "(),'")" = 'False draw' ] || fail "a gap recommended \"Draw it\": $(j design-gaps "$(it brief-only S-05)")"
[ "$(j tests "$(it look ROW-0009)['alone']")" = True ] || fail 'an entry of "Look here first" recommended "Remove it" is not asked on its own'
[ "$(j tests "$(it look ROW-0007)['alone'], $(it look ROW-0007)['preset']" | tr -d "(),'")" = 'False keep' ] || fail "an entry recommended \"Keep it\": $(j tests "$(it look ROW-0007)")"
[ "$(j tests "$(it kinds K1)['preset']")" = keep ] || fail 'a kind of failure does not start at Keep it'
for s in settings stages-own; do
  [ "$(j "$s" "[i['choices'] for x in d['sections'] for i in x['items']]")" = "$([ $s = settings ] && echo "[['Yes', 'No'], ['Yes', 'No']]" || echo "[['Yes', 'No']]")" ] || fail "$s is not answered Yes or No: $(j "$s" "[i['choices'] for x in d['sections'] for i in x['items']]")"
done
[ "$(j technical "$(it access X1)['detail']")" = "['Name the way only. Never type a password, a key or a token here.']" ] || fail "the access item does not carry its fixed line: $(j technical "$(it access X1)['detail']")"
# the two line forms
[ "$(j tests "$(it counted rows)['value']")" = 214 ] || fail 'a figure of the session carries no value'
[ "$(j stages "$(it cuts rung-1)['value']")" = '3 stages, 41 tests in the first' ] || fail 'the cut figure carries no value'
[ "$(j design-approval "$(it alone A1)['choices']")" = "['Yes', 'No']" ] || fail 'a choice under an alone item was not kept'
printf 'section cuts\nitem r | One\nvalue | 1\nsection which\nitem w | Which?\nchoice | One\nsection stages\nitem s1 | Stage 1\nvalue | 12\nempty open | none\nempty findings | none\n' > V
fc_run write stages V; [ "$RC" != 0 ] || fail 'a value outside a figures section was taken'
# one item at a writing; two choices
printf 'section alone\nitem stage-0 | Build stage 0 first?\nitem perm | May ViD deploy to the test site?\n' > O
fc_run write stages-own O; [ "$RC" != 0 ] || fail 'stages-own took two items in one writing'
printf 'section who\nitem D1 | Who makes the design?\nchoice | You\nchoice | ViD\nchoice | A designer\n' > W3
fc_run write design-who W3; [ "$RC" != 0 ] || fail 'who makes the design took three choices'
# a gap, a line or an entry of "Look here first" with neither a recommendation nor recommend | none
printf 'section lines\nitem L1 | Spacing\n' > N
fc_run write design-lines N; [ "$RC" != 0 ] || fail 'a disagreement with no recommendation and no "recommend | none" was taken'
exit 0
