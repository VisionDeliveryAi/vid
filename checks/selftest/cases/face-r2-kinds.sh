#!/bin/sh
# Purpose: selftest case — ViD's face R2 (0.26.10.29): a sitting is made of sections of seven kinds only (text,
# questions, list, objections, decided, figures; usability P7: alone); every item carries an id; every question can be answered in the
# person's own words, its recommendation among its choices. Convicts unless, at each of the four sittings: every section's kind is one of the seven, every
# item's id is non-empty, and every questions and alone section offers an act that takes words; and an item line with no id,
# or an id that is not one, is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-r2-kinds: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
seen=''
for s in interview pause-1 pause-2 pause-3; do
  fc_run write "$s" "lines.$s"; [ "$RC" = 0 ] || fail "$s refused: $OUT"
  bad=$(fc_json "[x['kind'] for x in d['sections'] if x['kind'] not in ('text','questions','list','objections','decided','figures','alone')]")
  [ "$bad" = '[]' ] || fail "$s has sections of other kinds: $bad"
  noid=$(fc_json "sum(1 for x in d['sections'] for i in x['items'] if not i['id'])"); [ "$noid" = 0 ] || fail "$s has $noid items with no id"
  q=$(fc_json "all(any(a['words'] for a in x['acts']) for x in d['sections'] if x['kind'] in ('questions','alone'))"); [ "$q" = True ] || fail "$s has a question with no way to answer in own words"
  seen="$seen $(fc_json "' '.join(sorted(set(x['kind'] for x in d['sections'])))")"
done
for k in text questions list objections decided figures alone; do printf '%s\n' $seen | grep -qx "$k" || fail "no sitting has a $k section"; done
# a recommendation is one of its question's choices: given alone, it becomes one
rm -f .vid/face/sitting.json   # 0.26.10.29.6 (S1): the pause-3 sitting on disk would make the interview a passed stop
printf 'section questions\nitem Q1 | Daily or weekly?\nrecommend | Daily\nsection challenge\nitem C1 | Search\n' > R1
fc_run write interview R1; [ "$RC" = 0 ] || fail "a lone recommendation was refused: $OUT"
[ "$(fc_json "[i['choices'] for x in d['sections'] for i in x['items'] if i['id']=='Q1'][0]")" = "['Daily']" ] || fail "a lone recommendation is not a choice: $(fc_json "[i['choices'] for x in d['sections'] for i in x['items'] if i['id']=='Q1']")"
printf 'section questions\nitem Q1 | Daily or weekly?\nchoice | Weekly\nrecommend | Daily\nsection challenge\nitem C1 | Search\n' > R2
fc_run write interview R2; [ "$(fc_json "[i['choices'] for x in d['sections'] for i in x['items'] if i['id']=='Q1'][0]")" = "['Weekly', 'Daily']" ] || fail 'a recommendation outside its choices is not added to them'
printf 'section questions\nitem | no id\n' > B1; fc_run write interview B1; [ "$RC" != 0 ] || fail 'an item with no id was written'
printf 'section questions\nitem Q"1 | a quote in the id\n' > B2; fc_run write interview B2; [ "$RC" != 0 ] || fail 'an id that is not one was written'
exit 0
