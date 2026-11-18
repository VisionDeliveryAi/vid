#!/bin/sh
# Purpose: selftest case — usability (P9): what there is to read, from .vid/pages/index (five tab-separated fields:
# id, title, the file's full path, the link or -, the stops it is due at or -). Convicts unless: the standing carries
# `pages`, one entry an index line in order, with the five fields (an empty list with no index); a sitting written
# beside a pages script runs `pages.sh for <its stop>` after the sitting is in place and the standing recomputed,
# prints that script's lines unchanged, and recomputes the standing once more (a page the call made is in it); ending
# a sitting runs the same call; a pages script that fails leaves the sitting written, says so in one line and exits
# 0; and `face.sh waiting` prints the waiting sitting's name, stop and title, then one line an item (id, a tab, its
# words), and nothing when none waits; and unless a page whose file is gone is left out, a page a pages script made
# before failing is in the standing, and a checkout whose path holds a backslash still has its pages, wait and agreed
# lines read; and unless `waiting` writes and removes nothing under .vid/face, a sitting waiting or none. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
fail() { echo "face-pages-index: $*" >&2; exit 1; }
. "$CHECKS/selftest/fixtures/face.sh"
TAB=$(printf '\t')
# no index: an empty list
fc_run standing; [ "$(fc_stand "d['pages']")" = '[]' ] || fail "with no index the standing carries $(fc_stand "d['pages']")"
mkdir -p .vid/pages; : > .vid/pages/PRD.html; : > .vid/pages/FOUNDATION.html
printf 'prd\tThe PRD\t%s/.vid/pages/PRD.html\thttps://claude.ai/artifact/abc\t3,4,5\nfoundation\tThe technical foundation\t%s/.vid/pages/FOUNDATION.html\t-\t6,7\ntests\tThe test list\t%s/.vid/pages/TESTS.html\t-\t8,9\n' "$T" "$T" "$T" > .vid/pages/index
fc_run standing
[ "$(fc_stand "[(p['id'], p['title'], p['file'], p['link'], p['stops']) for p in d['pages']]")" = "[('prd', 'The PRD', '$T/.vid/pages/PRD.html', 'https://claude.ai/artifact/abc', [3, 4, 5]), ('foundation', 'The technical foundation', '$T/.vid/pages/FOUNDATION.html', '', [6, 7])]" ] || fail "the standing carries $(fc_stand "d['pages']")"
# a pages script beside face.sh: it runs after the sitting is in place, its lines pass through, its page is in the standing
mkdir c; cp -R "$CHECKS/." c/
cat > c/pages.sh <<'S'
#!/bin/sh
echo "$*" >> .vid/pages.calls
grep -q '"state":"waiting"' .vid/face/sitting.json 2>/dev/null && grep -q '"turn":"person"' .vid/face/standing.json && echo 'in place' >> .vid/pages.calls
: > .vid/pages/FINDINGS.html; printf 'findings\tThe findings\t%s/.vid/pages/FINDINGS.html\t-\t5\n' "$PWD" >> .vid/pages/index
echo 'page: The findings | /x/FINDINGS.html | -'
S
rm -f .vid/pages.calls
set +e; OUT=$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh write pause-1 lines.pause-1 2>/dev/null); RC=$?; set -e
[ "$RC" = 0 ] || fail "pause-1 beside a pages script was refused"
[ "$(head -1 .vid/pages.calls)" = 'for 3' ] || fail "the pages script was called '$(head -1 .vid/pages.calls)', not 'for 3'"
grep -qx 'in place' .vid/pages.calls || fail 'the pages script ran before the sitting was in place and the standing recomputed'
printf '%s\n' "$OUT" | grep -qx 'page: The findings | /x/FINDINGS.html | -' || fail "the pages script's lines were not printed unchanged: $OUT"
fc_stand "[p['id'] for p in d['pages']]" | grep -q findings || fail 'the page the call made is not in the standing'
# waiting is a read: every file under .vid/face byte for byte, none gone, none added (a stale standing and old
# leftovers in place, which a recompute would rewrite or remove)
snap() { (cd .vid/face && for f in $(ls -A | sort); do printf '%s %s\n' "$f" "$(cksum < "$f")"; done); }
printf '{"stale":1}\n' > .vid/face/standing.stale; cp .vid/face/standing.json .vid/face/standing.keep
: > .vid/face/.standing.9; touch -t 202001010000 .vid/face/.standing.9; : > .vid/face/run.OLD; touch -t 202001010000 .vid/face/run.OLD
cp .vid/face/standing.stale .vid/face/standing.json; S1=$(snap)
W=$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh waiting)
[ "$(snap)" = "$S1" ] || fail "waiting, with a sitting waiting, changed .vid/face: $(snap)"
cp .vid/face/standing.keep .vid/face/standing.json; rm -f .vid/face/standing.stale .vid/face/standing.keep .vid/face/.standing.9 .vid/face/run.OLD
[ "$(printf '%s\n' "$W" | head -1)" = "pause-1${TAB}3${TAB}Agree the summary" ] || fail "waiting's first line is '$(printf '%s\n' "$W" | head -1)'"
printf '%s\n' "$W" | grep -qx "F-01${TAB}The unsubscribe has no time bound" || fail "waiting does not print the finding: $W"
[ "$(printf '%s\n' "$W" | tail -n +2 | wc -l | tr -d ' ')" = "$(fc_json "sum(len(x['items']) for x in d['sections'])")" ] || fail 'waiting prints a number of items the sitting does not hold'
printf '%s\n' "$W" | tail -n +2 | while IFS="$TAB" read -r id w; do fc_json "'$id' in [i['id'] for x in d['sections'] for i in x['items']]" | grep -qx True || fail "waiting prints $id, which the sitting does not hold"; done
# end runs the same call; then nothing waits
CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh end pause-1 > /dev/null 2>&1
[ "$(grep -c '^for 3$' .vid/pages.calls)" = 2 ] || fail 'ending the sitting did not run the pages call'
: > .vid/face/.standing.9; touch -t 202001010000 .vid/face/.standing.9; S2=$(snap)
[ -z "$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh waiting)" ] || fail 'waiting prints something when no sitting waits'
[ "$(snap)" = "$S2" ] || fail "waiting, with none waiting, changed .vid/face: $(snap)"
rm -f .vid/face/.standing.9
# a pages script that fails: the sitting stands, one line, exit 0
printf '#!/bin/sh\necho broken >&2\nexit 3\n' > c/pages.sh
set +e; OUT=$(CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh write pause-2 lines.pause-2 2>&1); RC=$?; set -e
[ "$RC" = 0 ] || fail "a failing pages script failed the write (exit $RC): $OUT"
[ "$(fc_json "(d['sitting'], d['state'])")" = "('pause-2', 'waiting')" ] || fail 'a failing pages script lost the sitting'
[ "$(printf '%s\n' "$OUT" | grep -c 'pages')" = 1 ] || fail "a failing pages script is not said in one line: $OUT"
# a pages script that makes a page and then fails: the page is in the standing all the same
printf '#!/bin/sh\n: > .vid/pages/STAGES.html; printf "stages\\tThe stages\\t%%s/.vid/pages/STAGES.html\\t-\\t9\\n" "$PWD" >> .vid/pages/index\nexit 1\n' > c/pages.sh
CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh write pause-2 lines.pause-2 > /dev/null 2>&1
fc_stand "[p['id'] for p in d['pages']]" | grep -q stages || fail "a page the failing pages script made is not in the standing: $(fc_stand "[p['id'] for p in d['pages']]")"
# with no pages script beside it: no call, as before
rm c/pages.sh; rm -f .vid/pages.calls
CLAUDE_CODE_SESSION_ID=sess-A sh c/face.sh write pause-2 lines.pause-2 > /dev/null 2>&1; [ ! -e .vid/pages.calls ] || fail 'a call was made with no pages script'
# a checkout whose path holds a backslash: the index, the wait and the agreed lines are still read
B="$T/panel\\test"; mkdir -p "$B/.vid/pages"; cp lines.interview "$B/"
( cd "$B" && git init -q . && : > .vid/pages/PRD.html && printf 'prd\tThe PRD\t%s/.vid/pages/PRD.html\t-\t3\n' "$(pwd -P)" > .vid/pages/index
  CLAUDE_CODE_SESSION_ID=sess-A sh "$T/c/face.sh" write interview lines.interview > /dev/null 2>&1
  CLAUDE_CODE_SESSION_ID=sess-A sh "$T/c/face.sh" end interview > /dev/null 2>&1
  CLAUDE_CODE_SESSION_ID=sess-A sh "$T/c/face.sh" wait parts One Two > /dev/null 2>&1 )
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if [p['id'] for p in d['pages']] == ['prd'] and len(d['wait']['parts']) == 2 and d['stops'][1]['agreed'].startswith('The interview: ') else 1)" "$B/.vid/face/standing.json" || fail "in a folder named panel\\test the standing is $(cat "$B/.vid/face/standing.json")"
exit 0
