#!/bin/sh
# Purpose: selftest case — usability 3 (0.26.10.29.6, S9): the test list's sitting. Written from a fixture, convicts
# unless it holds the four sections in order ("The test list, counted" of figures with the values the session gives;
# "Look here first" with Keep it, Remove it and Change it, the last two with words, each entry at ViD's recommendation;
# "Kinds of failure ViD proposes to test for" with Keep it and Drop it, each starting at Keep it; "Asked on their own",
# its item asked on its own), its last line is "I approve the test list. I have not read it line by line.", an entry
# recommended "Remove it" is asked on its own, and a `look` line is refused in it (its section of that name already
# holds what needs the owner). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-tests-sitting: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
cat > X <<'L'
section counted
item rows | Tests in the list
value | 214
item owed | Owed to a later stage
value | 37
section look
item ROW-0007 | The unsubscribe test waits on your decision on the time bound
recommend | Keep it
item ROW-0012 | An owed test with no class
recommend | Change it: class it as a rule row
item ROW-0019 | The strength check finds the sign-up test cannot fail
recommend | Remove it: a stronger one replaces it
section kinds
item K1 | A digest sent twice
item K2 | A digest sent to an address that left
section alone
item W1 | Two failure clauses are narrowed by the review
detail | The sign-up rule, its second clause: narrowed, as your answer says
L
fc_run write tests X; [ "$RC" = 0 ] || fail "the test list's sitting refused: $OUT"
[ "$(fc_json "[(x['id'], x['kind'], x['title']) for x in d['sections']]")" = "[('counted', 'figures', 'The test list, counted'), ('look', 'list', 'Look here first'), ('kinds', 'list', 'Kinds of failure ViD proposes to test for'), ('alone', 'alone', 'Asked on their own')]" ] || fail "sections: $(fc_json "[(x['id'], x['kind'], x['title']) for x in d['sections']]")"
[ "$(fc_json "d['closing']")" = 'I approve the test list. I have not read it line by line.' ] || fail "last line: $(fc_json "d['closing']")"
[ "$(fc_json "[(a['label'], a['words']) for a in d['sections'][1]['acts']]")" = "[('Keep it', False), ('Remove it', True), ('Change it', True)]" ] || fail "Look here first's buttons: $(fc_json "[(a['label'], a['words']) for a in d['sections'][1]['acts']]")"
[ "$(fc_json "[a['label'] for a in d['sections'][2]['acts']]")" = "['Keep it', 'Drop it']" ] || fail 'the kinds of failure have other buttons'
[ "$(fc_json "[i['value'] for i in d['sections'][0]['items']]")" = "['214', '37']" ] || fail "the counts: $(fc_json "[i['value'] for i in d['sections'][0]['items']]")"
[ "$(fc_json "[(i['preset'], i['alone']) for i in d['sections'][1]['items']]")" = "[('keep', False), ('change:class it as a rule row', False), ('', True)]" ] || fail "Look here first starts: $(fc_json "[(i['preset'], i['alone']) for i in d['sections'][1]['items']]")"
[ "$(fc_json "[(i['preset'], i['presetBy']) for i in d['sections'][2]['items']]")" = "[('keep', 'standing'), ('keep', 'standing')]" ] || fail "the kinds start: $(fc_json "[(i['preset'], i['presetBy']) for i in d['sections'][2]['items']]")"
[ "$(fc_json "[i['alone'] for i in d['sections'][3]['items']]")" = '[True]' ] || fail 'the weakened clauses are not asked on their own'
cp .vid/face/sitting.json before
awk '{ print } /^recommend \| Keep it$/ { print "look | An open finding" }' X > Y
fc_run write tests Y; [ "$RC" != 0 ] || fail 'a look line was taken in the test list sitting'
cmp -s before .vid/face/sitting.json || fail 'a refused write changed the sitting'
exit 0
