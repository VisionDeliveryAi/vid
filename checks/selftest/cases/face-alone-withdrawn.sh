#!/bin/sh
# Purpose: selftest case — usability (P7): a question asked on its own. Each pause's sitting ends with a section of
# kind `alone`, "A check ViD's draft would remove", filled from the lines prd.sh --pause prints under "owner
# questions". Convicts unless, with a prd.sh that prints two withdrawn clauses of one requirement: the section is the
# last, its items are <REQ>~<clause> (two items), each with the rule's text, the printed line as a detail, a `says`
# line's words as its first detail, the choices "Keep the check" and "Remove it", no preset and alone; unless a
# finding the session marked `alone` is alone with no preset though ViD recommends it; unless a `says` naming no such
# item is refused, nothing written; and unless with the real prd.sh of this tree the section is there, empty or
# filled, at each pause. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-alone-withdrawn: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
for s in pause-1 pause-2 pause-3; do
  fc_run write "$s" "lines.$s"; [ "$RC" = 0 ] || fail "$s refused: $OUT"
  [ "$(fc_json "(d['sections'][-1]['id'], d['sections'][-1]['kind'], d['sections'][-1]['title'])")" = "('withdrawn', 'alone', \"A check ViD's draft would remove\")" ] || fail "$s does not end with the withdrawn section: $(fc_json "[x['id'] for x in d['sections']]")"
done
# a copy of checks/ whose prd.sh also prints two withdrawn clauses, as 0.26.10.29.3's does, last
mkdir c; cp -R "$CHECKS/." c/; rm -f c/pages.sh; mv c/prd.sh c/prd-real.sh
cat > c/prd.sh <<'S'
#!/bin/sh
sh "$(dirname "$0")/prd-real.sh" "$@"; rc=$?
case " $* " in *" --pause "*)
  echo "owner questions (an arm withdrawn under ViD's draft — asked here, a gap at commit until the owner's yes restates the answer human): 2"
  echo "  arm 2 of REQ-002 withdrawn under ViD's draft A-005"
  echo "  arm 3 of REQ-002 withdrawn under ViD's draft A-005" ;;
esac
exit $rc
S
cp lines.pause-1 L
cat >> L <<'L'
item F-02 | A looser bound on the digest's delivery
recommend | Fix it
alone
says REQ-002~2 | stops all digests for that address within one day
L
rm -f .vid/face/sitting.json   # 0.26.10.29.6 (S1): a later stop's sitting on disk would make this stop a passed one
set +e; OUT=$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh write pause-1 L 2>&1); RC=$?; set -e
[ "$RC" = 0 ] || fail "pause-1 with withdrawn clauses was refused: $OUT"
[ "$(fc_json "[i['id'] for i in d['sections'][-1]['items']]")" = "['REQ-002~2', 'REQ-002~3']" ] || fail "the withdrawn items are $(fc_json "[i['id'] for i in d['sections'][-1]['items']]")"
it() { fc_json "[i$2 for i in d['sections'][-1]['items'] if i['id']=='$1'][0]"; }
[ -n "$(it REQ-002~2 "['text']")" ] && [ "$(it REQ-002~2 "['text']")" != 'REQ-002~2' ] || fail "the item's text is '$(it REQ-002~2 "['text']")'"
[ "$(it REQ-002~2 "['detail'][0]")" = 'stops all digests for that address within one day' ] || fail "the says words are not the first detail: $(it REQ-002~2 "['detail']")"
it REQ-002~2 "['detail']" | grep -q "arm 2 of REQ-002 withdrawn under ViD's draft A-005" || fail "the printed line is not a detail: $(it REQ-002~2 "['detail']")"
[ "$(it REQ-002~3 "['detail'][0]")" = "arm 3 of REQ-002 withdrawn under ViD's draft A-005" ] || fail "with no says line the printed line is not the first detail: $(it REQ-002~3 "['detail']")"
[ "$(it REQ-002~3 "['choices']")" = "['Keep the check', 'Remove it']" ] || fail "the choices are $(it REQ-002~3 "['choices']")"
[ "$(it REQ-002~3 "['preset']")" = '' ] && [ "$(it REQ-002~3 "['alone']")" = True ] || fail "a withdrawn clause starts at '$(it REQ-002~3 "['preset']")', alone $(it REQ-002~3 "['alone']")"
[ "$(fc_json "[(i['preset'], i['alone']) for x in d['sections'] if x['id']=='findings' for i in x['items'] if i['id']=='F-02'][0]")" = "('', True)" ] || fail 'the finding marked alone starts marked, or is not alone'
# every line printed under owner questions is an item
n=$(sh c/prd.sh PRD.md --pause 2>/dev/null | awk '/^owner questions/ { on = 1; next } on && /^  / { n++ } on && !/^  / { on = 0 } END { print n + 0 }')
[ "$n" = "$(fc_json "len(d['sections'][-1]['items'])")" ] || fail "--pause prints $n withdrawn lines, the sitting holds $(fc_json "len(d['sections'][-1]['items'])")"
# a says line naming no withdrawn item: refused, nothing written
cp .vid/face/sitting.json before
{ cat L; echo 'says REQ-099~1 | no such clause'; } > L2
set +e; OUT=$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh write pause-1 L2 2>&1); RC=$?; set -e
[ "$RC" != 0 ] || fail 'a says line naming no item was taken'
cmp -s before .vid/face/sitting.json || fail 'a refused says changed the sitting'
exit 0
