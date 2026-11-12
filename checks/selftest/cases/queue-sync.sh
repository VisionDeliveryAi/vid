#!/bin/sh
# Purpose: selftest case — the one voice to the owner (v0.26.10.25.3, R1–R7), checks/queue.sh on the toy and the fake gh. Each kind of
# `Q` line, its number stable and the `questions:` key true; a held row's recommendation by the rule, and the session's own; a
# `Question:` comment with no label, and a role-prefixed one, printed as questions; a blocked label left on while a question stands;
# a delegated answer posted `RM:` and in the status; an owner's question by `ask`, answered, the label off; a ticket's findings, a
# line for the ticket and one for a high one, a `finding` line once; a finding ruled known reaching the next ticket's known section,
# which passes the writer's check; an owner's ruling on a held row, and an answer not released; pause and continue; the status's block;
# a defect counted; a lesson. v0.26.10.26.3: the status's new lines, after the old ones (R1). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "queue-sync: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; QS=$CHECKS/queue.sh; R=owner/code; TAB=$(printf '\t')
qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; line() { grep -q -- "$1" .vid/RUN-STATE.md || fail "no Q line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'
# a ticket, #N, and its pull request 4 at a head H: two held rows, three comments
N=$(gh issue create -R $R --title t --body b --label ticket | sed 's/.*\///'); H=0123456789ab0123456789ab0123456789ab0123; h=0123456789ab
cm() { printf '%s\n' "$2" > "$T/c"; gh issue comment "$1" -R $R --body-file "$T/c" > /dev/null; }
cm "$N" 'Question: ROW-003, which colour? Default: blue, built.'; cm "$N" 'TA: questions on ROW-004, none stopping the work; the default is one a day'; cm "$N" 'Question: ROW-003 needs the owner: may the list be public?'
gh issue edit "$N" -R $R --add-label blocked > /dev/null
mkdir -p .vid/round .vid/decide .vid/results; sh "$GS" round-read > .vid/round/read 2> "$T/out" || fail 'round-read failed'
printf 'open\t4\t%s\t%s\tfalse\t\t1\t1\t2026-11-09T10:00:00Z\t\n' "$N" "$H" >> .vid/round/read
printf 'ROW-003\tROW-003\theld\tevidence missing\twaits\theld — evidence missing — no fault folder, pr-4-%s-1\t0\tpassed\t\t0\t\nROW-004\tROW-004\theld\tfailing\tnot-proven\theld — it did not shrink — failing, a weak test — its fault not proven, pr-4-%s-1\t0\tpassed\tw\t1\tw\n' "$h" "$h" > .vid/decide/pr-4-$h.rows
printf 'ROW-003\theld\tevidence missing\t4\t%s\t2026-11-09T10:00:00Z\nROW-004\theld\tfailing\t4\t%s\t2026-11-09T10:00:00Z\n' "$h" "$h" > .vid/decide/state
printf 'ticket %s, pull request 4, head %s\nfinding: bug high — the list leaks — the page — open it twice\nfinding: rule low — names drift\nfinding: note — a word\n' "$N" "$H" > .vid/results/pr-4-$h.txt
# the sync: the Q lines, numbered, the key true; the questions with no answer and no line printed; a finding line once
qs sync; [ "$RC" = 0 ] || fail 'sync failed'; ok "^question $N 1$"; ok "^question $N 2$"; ok "^question $N 3$"; ok "^finding $N high the list leaks"
line "^- Q1 · asked .* · gates #$N · held ROW-003 · #$N · evidence missing — no fault folder.* (a) accept by ruling .*recommended: a — "; line "· held ROW-004 · .*recommended: c — "
line "· gates nothing · findings of #$N · 1 high, 0 medium, 2 low · rule each: fix, a row, known, or no · .vid/decide/queue.html"; line "· gates nothing · finding of #$N, high · bug high — the list leaks"
grep -q '^questions: 4 open · next Q5$' .vid/RUN-STATE.md || fail "the questions key: $(grep '^questions:' .vid/RUN-STATE.md)"
cp .vid/RUN-STATE.md "$T/rs1"; qs sync; no_f() { ! grep -q "$1" "$T/out" || fail "a line again: $1"; }; no_f '^finding '; cmp -s "$T/rs1" .vid/RUN-STATE.md || fail 'a second sync moved the numbers'
# the session's own recommendation
qs recommend Q2 b 'the case was rewritten once already'; qs sync; line '· held ROW-004 · .*recommended: b — the case was rewritten once already'
# a delegated answer: posted RM:, the label stays while another question stands; the status lists it
qs answer "$N:1" --by RM 'Blue, as the spec says'; [ "$RC" = 0 ] || fail 'the delegated answer failed'; last=$(ls "$T/gh/issues/$N/comments" | sort -n | tail -n 1)
head -n 1 "$T/gh/issues/$N/comments/$last" | grep -qx "RM: Question: ROW-003, which colour? Default: blue, built." || fail 'the answer does not quote the question'
grep -q blocked "$T/gh/issues/$N/labels" 2>/dev/null || fail 'the label came off while questions stand'
qs status; ok '^== where things stand'; ok "question:$N:1 — Blue, as the spec says"; for k in tickets: rows: 'steps closed:' 'open questions:' 'plan changes since' flags: elapsed: stage: now: left: tests: 'test state:' debt: landings: cost: hardening: estimate:; do ok "^$k"; done
# an owner's question: asked, a Q line; answered, the line closes; the last question answered, the label off
C0=$(ls "$T/gh/issues/$N/comments" | grep -c .); mkdir -p "$T/failgh"; printf '#!/bin/sh\n[ "$1 $2" = "issue comment" ] && exit 1\nexec %s "$@"\n' "$(command -v gh)" > "$T/failgh/gh"; chmod +x "$T/failgh/gh"
RC=0; PATH="$T/failgh:$PATH" sh "$QS" ask "$N:3" > "$T/out" 2>&1 || RC=$?; ok "^waiting-comment-failed $N$"; [ "$(ls "$T/gh/issues/$N/comments" | grep -c .)" = "$C0" ] || fail 'a failed comment was posted'   # tried again at the next ask
qs ask "$N:3"; qs sync; line "· gates #$N · Question: ROW-003 needs the owner"; QN=$(sed -n "s/^- \(Q[0-9]*\) · .*needs the owner.*/\1/p" .vid/RUN-STATE.md)
# v0.26.10.26.7 (R8): the dev side hears, once, that it waits; the comment holds no question text, so no scan reads it as the answer
[ "$(ls "$T/gh/issues/$N/comments" | grep -c .)" = $((C0 + 1)) ] || fail 'no waiting comment'; last=$(ls "$T/gh/issues/$N/comments" | sort -n | tail -n 1)
[ "$(cat "$T/gh/issues/$N/comments/$last")" = "RM: this question waits on the lead ($QN); go on with what it does not block." ] || fail "the waiting comment: $(cat "$T/gh/issues/$N/comments/$last")"
qs ask "$N:3"; [ "$(ls "$T/gh/issues/$N/comments" | grep -c .)" = $((C0 + 1)) ] || fail 'the waiting comment was posted twice'
sh "$GS" round-read > .vid/round/read 2>/dev/null; printf 'open\t4\t%s\t%s\tfalse\t\t1\t1\t2026-11-09T10:00:00Z\t\n' "$N" "$H" >> .vid/round/read; qs sync
awk -F'\t' -v k="$N:3" '$1 == k { print $4 }' .vid/decide/queue/questions | grep -qx asked || fail "the scan read the waiting comment as the answer: $(grep "^$N:3" .vid/decide/queue/questions)"; line "· gates #$N · Question: ROW-003 needs the owner"
qs answer "$N:2" --by RM 'One a day stands'; grep -q blocked "$T/gh/issues/$N/labels" || fail 'the label came off with a question still asked'
qs answer "$QN" 'Yes, public'; [ "$RC" = 0 ] || fail "the owner's answer failed"; qs sync; ! grep -q 'needs the owner' .vid/RUN-STATE.md || fail "the owner's question stays after its answer"
! grep -q blocked "$T/gh/issues/$N/labels" 2>/dev/null || fail 'the label stayed with no question left'
# a finding ruled known: in the next ticket's known section, quoted, and the ticket passes the check
FQ=$(sed -n 's/^- \(Q[0-9]*\) · .*findings of #.*/\1/p' .vid/RUN-STATE.md); qs answer "$FQ" 2 known 'drift is known'; grep -qx 'rule low — names drift' .vid/tw/known-findings || fail 'the known finding was not recorded'
qs answer "$FQ" 1 fix 'fix it'; grep -q "finding:$N:1${TAB}fix${TAB}fix it${TAB}owner${TAB}to the door: SP drafts its row" .vid/decide/queue/answers || fail 'a fix ruling is not recorded for the door'
ok "^door: /vid fix — a new row for the finding of #$N: bug high — the list leaks"
sh "$GS" round-read > .vid/round/read 2>/dev/null; qs sync; grep -q "findings of #$N" .vid/RUN-STATE.md || fail 'the findings left with their pull request'; qs answer "$FQ" 3 no 'fine'; [ "$RC" = 0 ] || fail 'a finding could not be ruled once its pull request left the read'
printf 'open\t4\t%s\t%s\tfalse\t\t1\t1\t2026-11-09T10:00:00Z\t\n' "$N" "$H" >> .vid/round/read
tw_start S01 || fail 'S01 was refused'; sh "$GS" tw-sync > /dev/null 2>&1; tw_post skeleton || fail "the skeleton was refused: $(cat "$T/werr")"
awk '/^## Known, ruled by the owner/ { on = 1; next } on && /^## / { exit } on && NF' "$TW_F" | grep -qx '> rule low — names drift' || fail 'the known section does not quote the finding'
# the owner's ruling on a held row; the next decision still holding it is an answer not released
qs answer Q1 a 'accept it'; [ "$RC" = 0 ] || fail 'the ruling failed'; grep -q "ROW-003${TAB}accept" .vid/decide/rulings || fail 'the ruling did not reach decide.sh'
sleep 1; printf '%s\t4\t%s\tROW-003\theld\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$h" >> .vid/decide/log; qs sync; ok '^unreleased ROW-003$'
# pause and continue
qs control pause 'hold on'; grep -qx 'run: stopped owner asked to pause' .vid/RUN-STATE.md || fail 'no pause'; qs control continue 'go on'; grep -qx 'run: active' .vid/RUN-STATE.md || fail 'no continue'
grep -q 'queue-answered what=control by=owner' .vid/metrics-events || fail 'the control was not recorded'
# a defect, counted; a lesson
qs defect results 'a report was refused'; qs defect results 'a report was refused'; grep -q '^- seen: 2$' .vid/VID-FINDINGS.md || fail 'a defect seen twice is not one entry counted'
qs lesson ROW-004,ROW-005 'a test that reads a stated value'; grep -qx 'lesson ROW-004,ROW-005 | a test that reads a stated value | stand-in: RM' .vid/tw/handed || fail 'no lesson line'
exit 0
