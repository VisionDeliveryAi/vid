#!/bin/sh
# Purpose: selftest case — usability (P10): the critic's findings as margin notes. A finding may name the item it is
# about, `about | <section id>/<item id>`, under its item line. Convicts unless, of three findings (one naming a
# feature, one naming an item the sitting does not hold, one naming none), each carries what it names in `about`
# ("" for none), as written; unless every finding is still an item of the findings section, once; and unless an
# `about` that is not <section>/<item>, one with no finding above it, or one under an item of a section that is not
# findings, is refused by its line, nothing written. Where they are drawn is the panel's (its kit tests). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-about: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
fc_run write pause-1 lines.pause-1; [ "$RC" = 0 ] || fail "pause-1 refused: $OUT"
feat=$(fc_json "[i['id'] for x in d['sections'] if x['id']=='features' for i in x['items']][0]")
[ -n "$feat" ] || fail 'the fixture prints no feature'
grep -vE '^section findings|^item F-01|^recommend [|] Fix it' lines.pause-1 > L
cat >> L <<L
section findings
item F-01 | The daily digest has no time bound
about | features/$feat
recommend | Fix it: within one day
item F-02 | A quality the sitting does not show
about | contract/DIM-none
recommend | none
item F-03 | The unsubscribe is not tested
recommend | none
L
fc_run write pause-1 L; [ "$RC" = 0 ] || fail "three findings were refused: $OUT"
ab() { fc_json "[i['about'] for x in d['sections'] if x['id']=='findings' for i in x['items'] if i['id']=='$1'][0]"; }
[ "$(ab F-01)" = "features/$feat" ] || fail "F-01 is about '$(ab F-01)'"
[ "$(ab F-02)" = 'contract/DIM-none' ] || fail "F-02 is about '$(ab F-02)'"
[ "$(ab F-03)" = '' ] || fail "F-03, naming none, is about '$(ab F-03)'"
[ "$(fc_json "[i['id'] for x in d['sections'] if x['id']=='findings' for i in x['items']]")" = "['F-01', 'F-02', 'F-03']" ] || fail 'the findings are not each an item of the findings section, once'
[ "$(fc_json "all('about' in i for x in d['sections'] for i in x['items'])")" = True ] || fail 'an item carries no about field'
cp .vid/face/sitting.json before
n=$(wc -l < L | tr -d ' ')
for bad in 'about | features' 'about | /F-01' 'about | features/FEAT 01'; do
  { cat L; echo "$bad"; } > B; fc_run write pause-1 B
  [ "$RC" != 0 ] || fail "'$bad' was taken"
  printf '%s\n' "$OUT" | grep -q "line $((n + 1)):" || fail "'$bad' is not refused by its line: $OUT"
  cmp -s before .vid/face/sitting.json || fail "a refused '$bad' changed the sitting"
done
printf 'about | features/x\n' > B2; cat L >> B2; fc_run write pause-1 B2
printf '%s\n' "$OUT" | grep -q 'line 1:' || fail "an about with no item above it is not refused by its line: $OUT"
awk '{ print } /^item DIM-mech-digest/ { print "about | features/x" }' L > B3; fc_run write pause-1 B3
[ "$RC" != 0 ] || fail 'an about under a quality (not a finding) was taken'
exit 0
