#!/bin/sh
# Purpose: selftest case — usability (P1): the sitting and the standing say format 2, the form that carries presets.
# Convicts unless every sitting written, and the standing, say format 2; every item of a sitting carries preset,
# presetBy, alone and norecommend; face.sh's head tells the session that a recommendation starts with the button's
# own words; and, in the plugin's layout, the panel reads formats 1 and 2 (hooks/face/model.ts) and its own tests
# draw a format-1 sitting (the kit runs them: face-panel-kit). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-preset-format: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
for s in interview pause-1 pause-2 pause-3; do
  fc_run write "$s" "lines.$s"; [ "$RC" = 0 ] || fail "$s refused: $OUT"
  [ "$(fc_json "d['format']")" = 2 ] || fail "$s says format $(fc_json "d['format']"), not 2"
  [ "$(fc_stand "d['format']")" = 2 ] || fail "the standing says format $(fc_stand "d['format']"), not 2"
  [ "$(fc_json "all(set(('preset','presetBy','alone','norecommend')) <= set(i) for x in d['sections'] for i in x['items'])")" = True ] || fail "an item of $s lacks a preset field"
done
grep -q "recommendation in a list or a findings section starts with the button's own words" "$CHECKS/face.sh" || fail "face.sh's head does not tell the session how a recommendation names a button"
M=$CHECKS/../hooks/face/model.ts
[ -f "$M" ] || exit 0
grep -q 'FORMATS = \[1, 2\]' "$M" || fail 'the panel does not read formats 1 and 2'
grep -q "^test('P1 a format-1 sitting is still drawn" "$CHECKS/../hooks/face/register.test.tsx" || fail "the panel's tests draw no format-1 sitting"
exit 0
