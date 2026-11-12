#!/bin/sh
# Purpose: selftest case — a fix ticket with a row left open beside one ruled a known limit (0.26.10.28.6 R2), checks/round.sh, writer.sh
# and github.sh on TW's toy and the fake gh. The skeleton merged, S01 not closed, stage 0's candidate named; the round publishes the fix
# ticket of ROW-003 and ROW-004, and ROW-003 is ruled a known limit (the handed record's line). `writer.sh due` owes `amend <n>`, never its
# withdrawal; the round's next amends it in place to ROW-004 alone, its header and comment naming the rows ruled known limits; it stays
# open, and tw-close refuses it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "tw-limits-amend: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; W=$CHECKS/writer.sh
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1 failed ($RC)"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
tw_skel || fail 'the skeleton round failed'; M=$(git --git-dir="$T/code.git" rev-parse main); mkdir -p .vid/decide; echo 2 >> .vid/decide/merged-prs; printf '2\t1\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
grep -v '^closed S01 ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed; tw_hand 'candidate 1'
tw_hand 'fix ROW-003 ROW-004 | ROW-003: ROW-003 in chromium; ROW-004: ROW-004-T1 in chromium | close #9 of S01: req-9-p1c1-1'
rd next; F=$(sed -n 's/^published \([0-9]*\)$/\1/p' "$T/out"); [ -n "$F" ] && grep -q "^published $F kind=fix step=S01 rows=ROW-003,ROW-004 " .vid/tw/log || fail 'the fix ticket was not published'
tw_hand 'row ROW-003 known-limit'
sh "$W" due > "$T/out" 2>&1 || fail 'due failed'; ok "^amend $F\$"; no "^withdraw $F"
rd next; ok "^amended $F\$"; no "^withdrawn $F"; B=.vid/tw/out/issue-$F.md
grep -qx -- '- rows: ROW-004' "$B" && grep -qx -- '- amended: as its rows ROW-003 were ruled known limits or taken out of the plan' "$B" || fail "#$F is not amended to ROW-004, naming the limit: $(sed -n 's/^- \(rows\|amended\): //p' "$B" | paste -sd ';' -)"
grep -q "^amended $F kind=fix step=S01 rows=ROW-004 " .vid/tw/log || fail 'the amendment is not logged'
grep -rq "^vid: amended as its rows ROW-003 were ruled known limits or taken out of the plan\." "$T/gh/issues/$F/comments" || fail "#$F's amendment comment does not name the limit"
[ "$(cat "$T/gh/issues/$F/state")" = OPEN ] && ! grep -q "^withdrawn $F " .vid/tw/log || fail "#$F did not stay open"
if sh "$GS" tw-close "$F" > "$T/out" 2>&1; then fail "tw-close withdrew #$F, a row of it open"; fi; ok "the round owes no withdrawal of #$F"
sh "$W" due > "$T/out" 2>&1; no "^amend $F"; no "^withdraw $F"
exit 0
