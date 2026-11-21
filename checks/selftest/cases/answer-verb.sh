#!/bin/sh
# Purpose: selftest case — every answer of the owner's through one entry (GM-4 K6, its script parts; I6). On TW's toy with a ticket
# #N holding three team questions, two held rows and a finding: the held row's `Q<n>` answered `a "<words>"` by queue.sh answer
# records the owner's answer and reaches decide.sh's ruling; an owner's answer with no words is refused, nothing recorded. A
# team question answered by its `Q<n>` posts one `RM:` comment, its first line the question's line, then the words, exactly as
# the answer move's form (`queue.sh answer <n>:<k>`, which next-move.sh's answer move runs) posts another; a second answer to
# either is refused, posting nothing. With every question the owner's (`owner-questions: all`, D6), a question only seen is a
# `Q<n>` line and posts no waits-on-the-lead comment; `queue.sh list` prints every open `Q<n>` line of RUN-STATE's section, in its
# order, with its key and the answers it takes (a held row's a, b, c, d, until the next decision re-decides it; a question's words
# or there; a finding's ruling). Every owner's answer needs the owner's words (K6): a finding's ruling and a production yes with
# none are refused, naming the words, nothing recorded.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "answer-verb: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; QS=$CHECKS/queue.sh; R=owner/code; TB=$(printf '\t')
qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
N=$(gh issue create -R $R --title t --body b --label ticket | sed 's/.*\///'); H=0123456789ab0123456789ab0123456789ab0123; h=0123456789ab
cm() { printf '%s\n' "$2" > "$T/c"; gh issue comment "$1" -R $R --body-file "$T/c" > /dev/null; }
cm "$N" 'Question: ROW-003, which colour? Default: blue.'; cm "$N" 'Question: ROW-004, how many a day?'; cm "$N" 'TA: question on ROW-003, may the list be public?'
rd() { sh "$GS" round-read > .vid/round/read 2> "$T/out" || fail 'round-read failed'; printf 'open\t4\t%s\t%s\tfalse\t\t1\t1\t2026-11-09T10:00:00Z\t\n' "$N" "$H" >> .vid/round/read; }
mkdir -p .vid/round .vid/decide .vid/results; rd
printf 'ROW-003\tROW-003\theld\tevidence missing\twaits\theld — evidence missing — no fault folder, pr-4-%s-1\t0\tpassed\t\t0\t\n' "$h" > .vid/decide/pr-4-$h.rows
printf 'ROW-003\theld\tevidence missing\t4\t%s\t2026-11-09T10:00:00Z\n' "$h" > .vid/decide/state
printf 'ticket %s, pull request 4, head %s\nfinding: bug high — the list leaks — the page — open it twice\n' "$N" "$H" > .vid/results/pr-4-$h.txt
qs sync; [ "$RC" = 0 ] || fail 'sync failed'; qs ask "$N:1"; [ "$RC" = 0 ] || fail 'the first question could not be asked'
qof() { awk -F'\t' -v p="$1" '$1 == p { print $2; exit }' "$T/keys"; }
sh "$QS" keys > "$T/keys" 2>&1 || fail 'keys failed'; QH=$(qof held:ROW-003); Q1=$(qof "question:$N:1")
[ -n "$QH" ] && [ -n "$Q1" ] || fail "no Q lines for the held row and the asked question: $(cat "$T/keys")"
# the held row: the owner's words required, then the ruling recorded as the owner's
qs answer "$QH" a; [ "$RC" != 0 ] || fail 'an owner'"'"'s ruling with no words was taken'; ! grep -q 'held:ROW-003' .vid/decide/queue/answers || fail 'a refused ruling was recorded'
qs answer "$QH" a 'accept it, its tests pass'; [ "$RC" = 0 ] || fail "the held row's answer was refused: $(cat "$T/out")"
grep -q "^[^$TB]*${TB}held:ROW-003${TB}a${TB}accept it, its tests pass${TB}owner${TB}accept\$" .vid/decide/queue/answers || fail "the held row's answer is not the owner's: $(cat .vid/decide/queue/answers)"
grep -q "ROW-003${TB}accept" .vid/decide/rulings || fail 'the ruling did not reach decide.sh'
# a team question by its Q line, and one by its place, as the answer move gives it: the same post
post() { last=$(ls "$T/gh/issues/$N/comments" | sort -n | tail -n 1); cat "$T/gh/issues/$N/comments/$last"; }
qs answer "$Q1" 'Blue, as the default says'; [ "$RC" = 0 ] || fail "the answer by $Q1 was refused: $(cat "$T/out")"
[ "$(post)" = "$(printf 'RM: Question: ROW-003, which colour? Default: blue.\n\nBlue, as the default says')" ] || fail "the answer by its Q line posted: $(post)"
qs answer "$N:2" 'Two a day'; [ "$RC" = 0 ] || fail "the answer by its place was refused: $(cat "$T/out")"
[ "$(post)" = "$(printf 'RM: Question: ROW-004, how many a day?\n\nTwo a day')" ] || fail "the answer by its place posted: $(post)"
C0=$(ls "$T/gh/issues/$N/comments" | grep -c .)
qs answer "$Q1" 'again'; [ "$RC" != 0 ] || fail 'a second answer by the Q line was taken'; qs answer "$N:2" 'again'; [ "$RC" != 0 ] || fail 'a second answer by the place was taken'
[ "$(ls "$T/gh/issues/$N/comments" | grep -c .)" = "$C0" ] || fail 'a refused second answer posted'
# every question the owner's: one only seen is a Q line, no waiting comment; the list holds every open line with its answers
printf 'owner-questions: all\n' >> .vid/tw/settings; rd; qs sync; [ "$RC" = 0 ] || fail 'sync failed with every question the owner'"'"'s'
! grep -q "^question $N 3\$" "$T/out" || fail 'a seen question was handed to the session, not the owner'
sh "$QS" keys > "$T/keys" 2>&1; Q3=$(qof "question:$N:3"); [ -n "$Q3" ] || fail "the seen question is no Q line: $(cat "$T/keys")"
[ "$(ls "$T/gh/issues/$N/comments" | grep -c .)" = "$C0" ] || fail 'the owner'"'"'s question posted a waiting comment'
qs list; [ "$RC" = 0 ] || fail "queue.sh list failed: $(cat "$T/out")"; cp "$T/out" "$T/list"
awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on && /^- Q[0-9]+ / { print $2 }' .vid/RUN-STATE.md > "$T/sec"
cut -f1 "$T/list" > "$T/lq"; cmp -s "$T/sec" "$T/lq" || fail "the list is not the section's open lines in order: $(paste -sd ' ' "$T/lq") vs $(paste -sd ' ' "$T/sec")"
grep -q "^$Q3${TB}question:$N:3${TB}\"<words>\" | there \"<words>\"${TB}TA: question on ROW-003, may the list be public?\$" "$T/list" || fail "the question's line: $(grep "^$Q3" "$T/list")"
grep -q "^Q[0-9]*${TB}findings:$N${TB}<finding> fix|row|known|no \"<words>\"${TB}findings of #$N" "$T/list" || fail "the findings' line: $(cat "$T/list")"
grep -q "^$QH${TB}held:ROW-003${TB}a | b <N> | c | d \"<words>\"${TB}held ROW-003" "$T/list" || fail "the held row's line: $(grep 'held:' "$T/list")"
# K6: a finding's ruling and a production yes with no words: refused, naming the words, nothing recorded
QF=$(awk -F'\t' -v k="findings:$N" '$2 == k { print $1; exit }' "$T/list"); [ -n "$QF" ] || fail 'no Q line for the findings'
qs answer "$QF" 1 known; [ "$RC" != 0 ] && grep -q "needs the owner's words" "$T/out" || fail "a finding's ruling with no words was taken ($RC): $(cat "$T/out")"
! grep -q "${TB}finding:$N:1${TB}" .vid/decide/queue/answers && ! grep -q 'the list leaks' .vid/tw/known-findings 2>/dev/null || fail "a finding's ruling with no words was recorded"
X=$(git --git-dir="$T/code.git" rev-parse main); C12=$(printf %.12s "$X"); F=.vid/decide/stage/1/1; mkdir -p "$F/d1" "$F/cs"
printf 'issue\t1\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$F/ask"; echo "$X" > "$F/commit"; : > "$F/named"; : > "$F/passed"
tw_hand "stage-closed 1 | stand-in: RM at $C12 candidate 1"; printf 'production:1:1:7\tRehearsal of %s: migrates no. Deploy to production? yes or no\n' "$C12" > "$F/yes"
tw_hand 'candidate 1'; sh "$QS" sync > /dev/null 2>&1; sh "$QS" keys > "$T/keys" 2>&1 || true
QP=$(awk -F'\t' '$1 ~ /^production:1:1:/ { print $2 }' "$T/keys"); [ -n "$QP" ] || fail "no Q line for the production yes: $(cat "$T/keys")"
qs answer "$QP" yes; [ "$RC" != 0 ] && grep -q "needs the owner's words" "$T/out" || fail "a production yes with no words was taken ($RC): $(cat "$T/out")"
! grep -q "${TB}production:1:1:" .vid/decide/queue/answers && ! grep -q '^production-yes ' .vid/metrics-events || fail 'a production yes with no words was recorded'
exit 0
