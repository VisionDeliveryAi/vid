#!/bin/sh
# Purpose: selftest case — usability 3 (0.26.10.29.6, S4): "Changed since you agreed it". The fixture's PRD is
# committed and its first ratification recorded under ## Ratifications with that commit. Convicts unless the second
# and third pauses each hold the section (kind decided, filled by face.sh, the one button Change with words) right
# after "Decided for you"; unless it is empty while nothing of the thesis or the mechanisms differs; unless, with
# one mechanism edited after the ratification, it holds that line and no other: the line as it is now, with the line
# as it was as its detail; unless, with MECH-01 deleted as well, MECH-02 is still shown changed with its own wording as
# agreed and MECH-01 is shown gone with its wording; and unless an edited thesis line, which has no id, is shown as one
# line gone and one line new, never paired with another, and a new MECH-03 is shown new. Each write is made with no
# sitting on disk, so a later pause's sitting never stands in the way (S1). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-changed-since: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
git add PRD.md && git commit -qm 'the PRD at its first ratification'
sha=$(git rev-parse --short=12 HEAD)
awk -v l="- 2026-11-16 — thesis+contract — $sha" '{ print } /^## Ratifications/ { print ""; print l }' PRD.md > X && mv X PRD.md
git commit -qam 'its ratification line'
w() { rm -f .vid/face/sitting.json; fc_run write "$1" "lines.$1"; [ "$RC" = 0 ] || fail "$1 refused ($2): $OUT"; }
sec() { fc_json "[(x['kind'], x['title'], x['source'], [(a['label'], a['words']) for a in x['acts']], x['empty']) for x in d['sections'] if x['id']=='changed']"; }
items() { fc_json "[(i['id'], i['text'], i['detail']) for x in d['sections'] if x['id']=='changed' for i in x['items']]"; }
count() { fc_json "len([i for x in d['sections'] if x['id']=='changed' for i in x['items']])"; }
for s in pause-2 pause-3; do
  w "$s" 'nothing changed'
  [ "$(sec)" = "[('decided', 'Changed since you agreed it', 'vid', [('Change', True)], True)]" ] || fail "$s, nothing changed: $(sec)"
  [ "$(fc_json "[x['id'] for x in d['sections']].index('changed') - [x['id'] for x in d['sections']].index('decisions')")" = 1 ] || fail "$s: the section does not follow Decided for you"
done
old='MECH-02 | G2 | Relevance rests on a synonym-aware matching layer. | stated: answer A-002'
new='MECH-02 | G2 | Relevance rests on an exact-title matching layer. | stated: answer A-002'
grep -qxF "$old" PRD.md || fail 'the fixture has no MECH-02 line to edit'
awk -v o="$old" -v n="$new" '$0 == o { print n; next } { print }' PRD.md > X && mv X PRD.md
for s in pause-2 pause-3; do
  w "$s" 'after the edit'
  got=$(items)
  printf '%s\n' "$got" | grep -qF "('MECH-02', '$new', [" || fail "$s does not hold the mechanism as it is now: $got"
  printf '%s\n' "$got" | grep -qF "$old" || fail "$s does not hold the line as it was: $got"
  [ "$(count)" = 1 ] || fail "$s holds other lines: $got"
done
# MECH-01 deleted too: each line told apart by its own id, never paired by position
m1=$(grep '^MECH-01 | ' PRD.md) || fail 'the fixture has no MECH-01 line'
grep -v '^MECH-01 | ' PRD.md > X && mv X PRD.md
w pause-2 'MECH-01 deleted'
want=$(python3 -c "import sys; print(sorted([('MECH-01', 'This line is gone', ['As you agreed it: ' + sys.argv[1]]), ('MECH-02', sys.argv[2], ['As you agreed it: ' + sys.argv[3]])]))" "$m1" "$new" "$old")
[ "$(fc_json "sorted((i['id'], i['text'], i['detail']) for x in d['sections'] if x['id']=='changed' for i in x['items'])")" = "$want" ] || fail "with MECH-01 deleted and MECH-02 edited: $(items)"
# a thesis line with no id edited, and a new mechanism
t0='read email daily.'; grep -qxF "$t0" PRD.md || fail 'the fixture has no thesis line to edit'
awk -v o="$t0" '$0 == o { print "read email every morning."; next } { print } /^MECH-02 / { print "MECH-03 | G1 | Digests are sent once a day. | stated: seed" }' PRD.md > X && mv X PRD.md
w pause-2 'the thesis edited'
got=$(items)
printf '%s\n' "$got" | grep -qF "'This line is gone', ['As you agreed it: $t0']" || fail "the edited thesis line is not shown gone with its old wording: $got"
printf '%s\n' "$got" | grep -qF "'read email every morning.', ['Not there when you agreed it']" || fail "the edited thesis line is not shown new, unpaired: $got"
printf '%s\n' "$got" | grep -qF "('MECH-03', 'MECH-03 | G1 | Digests are sent once a day. | stated: seed', ['Not there when you agreed it'])" || fail "the new mechanism is not shown new: $got"
[ "$(count)" = 5 ] || fail "not five lines (MECH-01 gone, MECH-02 changed, MECH-03 new, the thesis line gone and new): $got"
exit 0
