#!/bin/sh
# Purpose: selftest case — usability 3 (0.26.10.29.6, S3): the owner rules the design's lines one by one. The
# design-lines sitting is written from three lines, each with one sentence of why, two with ViD's recommended ruling
# and one with `recommend | none`. Convicts unless every line is its own item of the section "Where the design and the
# PRD disagree", in the lines' order, with its why as its detail; the two recommended lines start at their ruling,
# said as ViD's; the third starts unanswered and is marked as having no recommendation; and a line with neither a
# recommendation nor `recommend | none` is refused naming its item, nothing written. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-design-lines: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
cat > D <<'L'
section lines
item L-01 | Space between the cards: 8 in the design, 12 in the PRD
detail | The design was drawn after the PRD set 12, and shows it on every screen.
recommend | Design wins
item L-02 | The digest's subject line: the design drops the date
detail | The PRD's rule on the subject line is a failure clause; the date proves the day's digest.
recommend | PRD wins
item L-03 | The sign-up screen shows a second button the PRD does not name
detail | Nothing tells whether it is meant or left over.
recommend | none
L
fc_run write design-lines D; [ "$RC" = 0 ] || fail "three lines refused: $OUT"
[ "$(fc_json "[x['title'] for x in d['sections']]")" = "['Where the design and the PRD disagree']" ] || fail "sections: $(fc_json "[x['title'] for x in d['sections']]")"
[ "$(fc_json "[i['id'] for i in d['sections'][0]['items']]")" = "['L-01', 'L-02', 'L-03']" ] || fail "items: $(fc_json "[i['id'] for i in d['sections'][0]['items']]")"
[ "$(fc_json "all(len(i['detail']) == 1 for i in d['sections'][0]['items'])")" = True ] || fail 'a line does not carry its one sentence of why'
[ "$(fc_json "[(i['preset'], i['presetBy'], i['norecommend']) for i in d['sections'][0]['items']]")" = "[('design', 'vid', False), ('prd', 'vid', False), ('', '', True)]" ] || fail "the starting rulings: $(fc_json "[(i['preset'], i['presetBy'], i['norecommend']) for i in d['sections'][0]['items']]")"
cp .vid/face/sitting.json before
grep -v '^recommend | none' D > N
fc_run write design-lines N; [ "$RC" != 0 ] || fail 'a line with neither a recommendation nor recommend | none was written'
printf '%s\n' "$OUT" | grep -q 'L-03' || fail "the refusal does not name the line's item: $OUT"
cmp -s before .vid/face/sitting.json || fail 'a refused write changed the sitting'
exit 0
