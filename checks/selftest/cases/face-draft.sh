#!/bin/sh
# Purpose: selftest case — usability (P13): watch it take shape. `face.sh draft <sitting> [<lines>|-]` takes the
# write's lines for any of the sitting's own sections and writes it in a third state, drafting, the sections not
# given left out. Convicts unless: two sections drafted give a sitting in state drafting holding those two (no
# script section, no PRD.md needed), the turn ViD's; a second draft replaces the cards; a draft keeps the wait's
# parts; a draft the script cannot read is refused by its line, the drafting sitting left byte for byte, no
# temporary file beside it; and `write` then gives the same sitting waiting, with every section, the turn the
# person's, the wait cleared. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-draft: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
mv PRD.md PRD.away
fc_run wait parts 'Draft the summary' 'Check it'
printf 'section thesis\nitem T1 | Product summary\ndetail | A digest.\nsection contract\nitem DIM-a | One digest a day\n' > D1
fc_run draft pause-1 D1; [ "$RC" = 0 ] || fail "a draft of two sections was refused: $OUT"
[ "$(fc_json "(d['state'], [x['id'] for x in d['sections']])")" = "('drafting', ['thesis', 'contract'])" ] || fail "the draft holds $(fc_json "(d['state'], [x['id'] for x in d['sections']])")"
[ "$(fc_stand "d['turn'], d['current']" | tr -d "(),'")" = 'vid 3' ] || fail "a drafting sitting gives $(fc_stand "d['turn'], d['current']")"
[ -f .vid/face/wait ] || fail 'a draft cleared the wait'
printf 'section thesis\nitem T1 | Product summary\ndetail | A daily digest.\nsection contract\nitem DIM-a | One digest a day\nitem DIM-b | Unsubscribe in one click\n' > D2
fc_run draft pause-1 D2; [ "$RC" = 0 ] || fail "the second draft was refused: $OUT"
[ "$(fc_json "[i['id'] for x in d['sections'] for i in x['items']]")" = "['T1', 'DIM-a', 'DIM-b']" ] || fail 'the second draft did not replace the cards'
cp .vid/face/sitting.json before
printf 'section thesis\nfrobnicate\n' > B; fc_run draft pause-1 B
[ "$RC" != 0 ] || fail 'a draft with a bad line was taken'
printf '%s\n' "$OUT" | grep -q 'line 2:' || fail "the bad draft is not refused by its line: $OUT"
cmp -s before .vid/face/sitting.json || fail 'a refused draft changed the sitting'
[ -z "$(ls -A .vid/face | grep -vxE 'sitting.json|standing.json|wait' || true)" ] || fail "a refused draft left a file: $(ls -A .vid/face)"
printf 'section features\nitem X | y\n' > B2; fc_run draft pause-1 B2; [ "$RC" != 0 ] || fail 'a draft of a script section was taken'
mv PRD.away PRD.md
fc_run write pause-1 lines.pause-1; [ "$RC" = 0 ] || fail "write after the drafts was refused: $OUT"
[ "$(fc_json "(d['state'], d['sitting'])")" = "('waiting', 'pause-1')" ] || fail "write gives $(fc_json "(d['state'], d['sitting'])")"
[ "$(fc_json "' '.join(x['id'] for x in d['sections'])")" = 'thesis contract features findings decisions withdrawn' ] || fail 'the written sitting lacks a section'
[ "$(fc_stand "d['turn']")" = person ] || fail 'the written sitting is not the person'"'"'s turn'
[ ! -e .vid/face/wait ] || fail 'write left the wait'
exit 0
