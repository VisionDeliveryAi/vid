#!/bin/sh
# Purpose: selftest case — usability (P3, and P2's end of "all"): plain choices. Convicts unless the qualities'
# buttons are exactly "Needs it" and "Doesn't need it" (no Strike, In or Out), the first pause's findings are
# "Fix it" and "Leave it" (Leave it taking the person's words), the third pause's findings keep "Answer" and
# "Accept", and no section of any sitting offers the act "all" (Take all recommendations); and unless face.sh's head
# tells the session the three ways to recommend on a quality. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-acts-plain: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
acts() { fc_json "[(a['label'], a['words']) for x in d['sections'] if x['id']=='$1' for a in x['acts']]"; }
fc_run write pause-1 lines.pause-1; [ "$RC" = 0 ] || fail "pause-1 refused: $OUT"
[ "$(acts contract)" = "[('Needs it', False), (\"Doesn't need it\", False)]" ] || fail "the qualities' buttons are $(acts contract)"
[ "$(acts findings)" = "[('Fix it', False), ('Leave it', True)]" ] || fail "the first pause's findings' buttons are $(acts findings)"
fc_run write pause-3 lines.pause-3; [ "$RC" = 0 ] || fail "pause-3 refused: $OUT"
[ "$(acts findings)" = "[('Answer', True), ('Accept', False)]" ] || fail "the third pause's findings' buttons are $(acts findings)"
for s in interview pause-1 pause-2 pause-3; do
  fc_run write "$s" "lines.$s"; [ "$RC" = 0 ] || fail "$s refused: $OUT"
  [ "$(fc_json "[x['id'] for x in d['sections'] for a in x['acts'] if a['id']=='all' or a['label'] in ('Strike','In','Out','Overrule','Take all recommendations')]")" = '[]' ] || fail "$s still offers an old act: $(fc_json "[(x['id'], a['label']) for x in d['sections'] for a in x['acts'] if a['id']=='all' or a['label'] in ('Strike','In','Out','Overrule')]")"
done
for w in 'recommend | Needs it' "recommend | Doesn't need it" 'recommend | none'; do
  grep -qF "\`$w\`" "$CHECKS/face.sh" || fail "face.sh's head does not tell the session '$w'"
done
exit 0
