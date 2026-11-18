#!/bin/sh
# Purpose: selftest case — usability 3 (0.26.10.29.6, S10): ViD points to where to look. A list section holds one item
# under each of the three rules (an open finding; shapes a rule that must never break; no recommendation), each with
# `look | <why>`, then one item without. Convicts unless each pointed item carries its why and the other none, in the
# sitting's order; a why that is none of the three is refused; and a section in which an item with `look` follows one
# without is refused naming that item, nothing written. The panel's two headings are the kit's (face-panel-kit).
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-look: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
cat > K <<'L'
section changes
item C1 | Two rules on digests are one now
recommend | Fine
look | An open finding
item C2 | The unsubscribe rule is shorter
recommend | Fine
look | Shapes a rule that must never break
item C3 | The sign-up rule names a second form
recommend | none
look | No recommendation
item C4 | A heading is reworded
recommend | Fine
empty alone | none
L
fc_run write consolidation K; [ "$RC" = 0 ] || fail "one item under each rule refused: $OUT"
[ "$(fc_json "[(i['id'], i.get('look')) for i in d['sections'][0]['items']]")" = "[('C1', 'An open finding'), ('C2', 'Shapes a rule that must never break'), ('C3', 'No recommendation'), ('C4', '')]" ] || fail "the pointed items: $(fc_json "[(i['id'], i.get('look')) for i in d['sections'][0]['items']]")"
cp .vid/face/sitting.json before
sed 's/^look | An open finding$/look | It matters most/' K > B
fc_run write consolidation B; [ "$RC" != 0 ] || fail 'a why that is none of the three was taken'
cmp -s before .vid/face/sitting.json || fail 'a refused why changed the sitting'
cat > R <<'L'
section changes
item C1 | Two rules on digests are one now
recommend | Fine
look | An open finding
item C4 | A heading is reworded
recommend | Fine
item C2 | The unsubscribe rule is shorter
recommend | Fine
look | Shapes a rule that must never break
empty alone | none
L
fc_run write consolidation R; [ "$RC" != 0 ] || fail 'an item with look after one without was taken'
printf '%s\n' "$OUT" | grep -q 'C2' || fail "the refusal does not name the item out of order: $OUT"
cmp -s before .vid/face/sitting.json || fail 'a refused order changed the sitting'
exit 0
