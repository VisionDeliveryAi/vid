#!/bin/sh
# Purpose: selftest case — usability 3 (0.26.10.29.6, S2): a recommendation on each near-duplicate pair still shown.
# The pairs are printed by prd.sh --pause (here a stand-in that prints two); the session gives ViD's recommendation for
# a pair in its lines: `section duplicates`, then `item <a>~<b>` with no words and one `recommend | Merge`, `recommend |
# Keep apart` or `recommend | none` under it. Convicts unless the pair recommended Merge starts at Merge, said as ViD's;
# the pair with none starts unanswered, marked as having no recommendation; and every other line the session gives in
# that section (words on the item, a detail, a recommendation that is no button of it, a pair the script does not
# print) is refused, nothing written; unless a pair left unnamed is refused naming it; unless a pair takes one `look |
# <why>` line (S10), the pointed pairs first in the order the session names them, a why not of the three and a pointed
# pair after an unpointed one refused; and unless the first pause's critic's findings and the third
# pause's rewordings, each written with neither a recommendation nor none, are refused naming the item, while an
# item asked on its own (a rewording, a finding, a design line marked alone) is taken with none. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-pair-recommend: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
mkdir c; cp -R "$CHECKS/." c/; rm -f c/pages.sh
cat > c/prd.sh <<'P'
#!/bin/sh
echo 'pause material for PRD.md'
echo 'near-duplicates (not yet ruled; statement overlap ≥0.6 and statement+fail-if Jaccard ≥0.35): 2'
echo '  REQ-001 ~ REQ-002 | overlap 0.70 · jaccard 0.40'
echo '  REQ-003 ~ REQ-004 | overlap 0.65 · jaccard 0.38'
P
fr() { set +e; OUT=$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh "$@" 2>&1); RC=$?; set -e; }
dup() { fc_json "[(i['id'], i['preset'], i['presetBy'], i['norecommend']) for x in d['sections'] if x['id']=='duplicates' for i in x['items']]"; }
{ cat lines.pause-2; printf 'section duplicates\nitem REQ-001~REQ-002\nrecommend | Merge\nitem REQ-003~REQ-004\nrecommend | none\n'; } > G
fr write pause-2 G; [ "$RC" = 0 ] || fail "the pairs' recommendations were refused: $OUT"
[ "$(dup)" = "[('REQ-001~REQ-002', 'merge', 'vid', False), ('REQ-003~REQ-004', '', '', True)]" ] || fail "the pairs start: $(dup)"
cp .vid/face/sitting.json before
try() { { cat lines.pause-2; printf 'section duplicates\n'; printf '%s\n' "$@"; } > B; fr write pause-2 B
  [ "$RC" != 0 ] || fail "the session wrote into the pairs' section: $*"
  cmp -s before .vid/face/sitting.json || fail "a refused line changed the sitting: $*"; }
try 'item REQ-001~REQ-002 | Two rules on the digest'
try 'item REQ-001~REQ-002' 'recommend | Merge' 'detail | They say the same'
try 'item REQ-001~REQ-002' 'recommend | Cut'
try 'item REQ-005~REQ-006' 'recommend | Merge'
try 'item REQ-001~REQ-002' 'recommend | Merge' 'alone'
try 'item REQ-001~REQ-002' 'recommend | Merge' 'recommend | none'
# a pair the session does not name reaches the sitting with neither: refused, naming it
try 'item REQ-001~REQ-002' 'recommend | Merge'
printf '%s\n' "$OUT" | grep -q 'REQ-003~REQ-004' || fail "the refusal does not name the pair left without a recommendation: $OUT"
# where to look on a pair (S10): one of the three whys; the pointed pairs first, in the order the session names them
{ cat lines.pause-2; printf 'section duplicates\nitem REQ-003~REQ-004\nrecommend | none\nlook | No recommendation\nitem REQ-001~REQ-002\nrecommend | Merge\n'; } > L
fr write pause-2 L; [ "$RC" = 0 ] || fail "a pointed pair was refused: $OUT"
[ "$(fc_json "[(i['id'], i['look']) for x in d['sections'] if x['id']=='duplicates' for i in x['items']]")" = "[('REQ-003~REQ-004', 'No recommendation'), ('REQ-001~REQ-002', '')]" ] || fail "the pointed pair is not first with its why: $(fc_json "[(i['id'], i.get('look')) for x in d['sections'] if x['id']=='duplicates' for i in x['items']]")"
cp .vid/face/sitting.json before
try 'item REQ-001~REQ-002' 'recommend | Merge' 'item REQ-003~REQ-004' 'recommend | none' 'look | No recommendation'
try 'item REQ-003~REQ-004' 'recommend | none' 'look | It matters' 'item REQ-001~REQ-002' 'recommend | Merge'
# the first pause's critic's findings, the third pause's rewordings: each carries a recommendation or none (the
# qualities start at their standing act, Needs it, but for the two the skill asks about: the session's to mark)
rm -f .vid/face/sitting.json
fc_run write pause-1 lines.pause-1; [ "$RC" = 0 ] || fail "the fixture's pause-1 was refused: $OUT"
fc_run write pause-3 lines.pause-3; [ "$RC" = 0 ] || fail "the fixture's pause-3 was refused: $OUT"
rm -f .vid/face/sitting.json
grep -v '^recommend | Fix it' lines.pause-1 > N; fc_run write pause-1 N; [ "$RC" != 0 ] || fail "pause-1 took the critic's finding with neither"
printf '%s\n' "$OUT" | grep -q F-01 || fail "the refusal does not name the finding: $OUT"
grep -v '^recommend | Accept' lines.pause-3 > N; fc_run write pause-3 N; [ "$RC" != 0 ] || fail 'pause-3 took a rewording with neither'
printf '%s\n' "$OUT" | grep -q F-07 || fail "the refusal does not name the rewording: $OUT"
[ ! -f .vid/face/sitting.json ] || fail 'a refused write left a sitting'
# an item asked on its own may come with no recommendation (S2; spec 1, P7): a rewording proposing a looser bound,
# a finding, a design line, each marked alone, are taken and asked on their own
awk '{ print } /^recommend \| Accept$/ { print "item F-09 | The digest may arrive within two days, not one"; print "alone" }' lines.pause-3 > A3
fc_run write pause-3 A3; [ "$RC" = 0 ] || fail "a rewording asked on its own with no recommendation was refused: $OUT"
[ "$(fc_json "[(i['alone'], i['recommend'], i['norecommend']) for x in d['sections'] if x['id']=='rewordings' for i in x['items'] if i['id']=='F-09'][0]")" = "(True, '', False)" ] || fail "the alone rewording: $(fc_json "[i for x in d['sections'] for i in x['items'] if i['id']=='F-09']")"
rm -f .vid/face/sitting.json
{ cat lines.pause-1; printf 'item F-02 | A looser bound on delivery\nalone\n'; } > A1
fc_run write pause-1 A1; [ "$RC" = 0 ] || fail "a finding asked on its own with no recommendation was refused: $OUT"
printf 'section lines\nitem L1 | Spacing\nrecommend | Design wins\nitem L2 | The date in the subject\nalone\n' > A7
fc_run write design-lines A7; [ "$RC" = 0 ] || fail "a design line asked on its own with no recommendation was refused: $OUT"
exit 0
