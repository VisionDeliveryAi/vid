#!/bin/sh
# Purpose: selftest case — the owner's direct answer reads first (GM-4 S0: every way in runs the same entry with the same rules; GM
# M16). vid-answer's own command runs the connect, then the vid-read skill's read (`round.sh read`), then the answer, then the end.
# On GitHub manual's toy and the fake gh: a team question listed as a Q line, then edited by the team; the owner's direct answer, in
# that order, is refused, nothing posted or recorded, the lock freed after. The skill's command names the read before the answer.
# Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "answer-direct-read: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t'); R=owner/code
S=$CHECKS/../skills/vid-answer/SKILL.md
if [ -f "$S" ]; then awk '/^## The owner.s command/ { on = 1; next } on && /^## / { exit } on' "$S" > "$T/cmd"
  r=$(grep -n 'round\.sh read' "$T/cmd" | head -n 1 | cut -d: -f1); a=$(grep -n 'queue\.sh answer' "$T/cmd" | head -n 1 | cut -d: -f1)
  [ -n "$r" ] && [ -n "$a" ] && [ "$r" -lt "$a" ] || { cp "$T/cmd" "$T/out"; fail "vid-answer's command does not run the read (round.sh read) before the answer"; }
  grep 'round\.sh read' "$T/cmd" | grep -q 'vid-read' || fail "vid-answer's read does not name the vid-read skill"; fi
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings; gh repo create owner/vid-state --private > /dev/null
A=$(gh_issue 'Step S02'); printf 'Question: ROW-005, which feed is read first?\n' > "$T/c"; gh issue comment "$A" -R $R --body-file "$T/c" > /dev/null
printf 'published %s kind=step step=S02 rows=ROW-001 at=2026-11-18T09:00:00Z\n' "$A" > .vid/tw/log
# the listing, at a call before
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
QA=$(awk -F'\t' -v k="question:$A:1" '$2 == k { print $1; exit }' "$T/ql"); [ -n "$QA" ] || { cp "$T/ql" "$T/out"; fail 'the question is no Q line'; }
# the team edits it; the owner's direct answer: the connect, the read, the answer, the end
printf 'Question: ROW-005, which feed is read first, the new one or the old one?\n' > "$FAKEGH/issues/$A/comments/1"
C0=$(ls "$FAKEGH/issues/$A/comments" | grep -c .); CLAUDE_CODE_SESSION_ID=direct-answer; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/connect.sh" start > "$T/out" 2>&1 || fail 'the connect did not start'
sh "$CHECKS/round.sh" read > "$T/out" 2>&1 || fail 'round.sh read failed'
RC=0; sh "$CHECKS/queue.sh" answer "$QA" 'The new one first' > "$T/out" 2>&1 || RC=$?; cp "$T/out" "$T/ans"
sh "$CHECKS/connect.sh" end > "$T/out" 2>&1 || fail 'the connect did not end'
[ "$RC" != 0 ] || { cp "$T/ans" "$T/out"; fail 'the direct answer to a question edited since its listing was taken'; }
[ "$(ls "$FAKEGH/issues/$A/comments" | grep -c .)" = "$C0" ] || fail 'the direct answer to an edited question was posted'
! grep -q "${TB}question:$A:1${TB}" .vid/decide/queue/answers || fail 'the direct answer to an edited question was recorded'
[ -z "$(mn_lock)" ] || fail 'the lock is held after the end'
exit 0
