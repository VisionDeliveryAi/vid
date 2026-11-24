#!/bin/sh
# Purpose: selftest case — one owner's queue (GM-4 F4, F9's I5, K6): an owner's item or answer is kept only in queue.sh. On the
# re-plan toy in GitHub manual (fixtures/manual.sh's mn_replan_toy), a draft of the door is asked through the queue (`queue.sh
# ask draft <n>`), a `Q<n>` line; `next.sh triggers` lists no accept-spec-change move; its answer with no words is refused, and
# `answer Q<n> yes "<words>"` lands it. `queue.sh raise` on the call's lines makes each trigger shown and each move a `Q<n>` line;
# a trigger's `decline "<words>"` (none without words) counts it declined at the next call's lines, its line closed; a move's
# `done "<words>"` takes it off the list, the move still listed. No .vid/next/shown, moves, declined, todo or questions is
# written, and next.sh's shown and decline, next-page.sh's todo-done and next-move.sh's accept-spec-change are gone. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"   # the plan page goes under HOME
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "one-queue: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
mn_replan_toy "$T/toy" || { cp "$T/mr" "$T/out"; fail 'the re-plan toy could not be made'; }
qsec() { awk '/^## Open product questions/ { on = 1; next } on && /^## / { exit } on' .vid/RUN-STATE.md; }
qof() { sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'; awk -F'\t' -v p="$1" 'index($2, p) == 1 { print $1; exit }' "$T/ql"; }
# the draft, asked through the queue and landed by the owner's answer
printf -- '- **Digest footer.** Check every digest names its support address.\n' >> GRADING-CHECKLIST.md
sh "$CHECKS/land.sh" draft --review "$T/mrv" --why '/vid fix: the digest footer line, in the owner words' > "$T/out" 2>&1 || fail 'the draft was refused'
D=$(sed -n 's/^draft \([0-9][0-9]*\)$/\1/p' "$T/out"); [ -n "$D" ] || fail 'the draft named no number'
sh "$CHECKS/queue.sh" ask draft "$D" > "$T/out" 2>&1 || fail 'the draft could not be asked through the queue'
QD=$(sed -n "s/^asked \(Q[0-9][0-9]*\) draft $D\$/\1/p" "$T/out"); [ -n "$QD" ] || fail "the ask named no Q line: $(cat "$T/out")"
qsec | grep -q "^- $QD · .*draft $D by SP" || fail "draft $D is no Q line in RUN-STATE: $(qsec)"
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'
! grep -q 'accept-spec-change' "$T/L" || fail 'the lines still list an accept-spec-change move'
RC=0; sh "$CHECKS/queue.sh" answer "$QD" yes '' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a yes with no words was taken'
[ ! -f ".vid/decide/drafts/$D/landed" ] || fail 'a yes with no words landed the draft'
sh "$CHECKS/queue.sh" answer "$QD" yes 'Yes, land the footer' > "$T/out" 2>&1 || fail 'the owner'"'"'s yes was refused'
[ -f ".vid/decide/drafts/$D/landed" ] || fail 'the owner'"'"'s yes did not land the draft'
grep -q "^[^$TB]*${TB}draft:$D${TB}yes${TB}Yes, land the footer${TB}owner${TB}landed\$" .vid/decide/queue/answers || fail "the queue holds no answer for the draft: $(cat .vid/decide/queue/answers)"
# what the call raised, each a Q line
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^trigger${TB}" "$T/L" && grep -q "^move${TB}" "$T/L" || { cat "$T/L" >&2; fail 'the toy raises no trigger or no move'; }
sh "$CHECKS/queue.sh" raise "$T/L" > "$T/out" 2>&1 || fail 'queue.sh raise failed'
awk -F'\t' '$1 == "trigger" { print " · " $2 " trigger " $3 " " $4 ": " } $1 == "move" { print " · the move " $2 " " $3 ": " }' "$T/L" > "$T/rx"
while IFS= read -r x; do qsec | grep -qF -- "$x" || fail "$x, raised, is no Q line: $(qsec)"; done < "$T/rx"
for f in shown moves declined todo questions; do [ ! -e ".vid/next/$f" ] || fail ".vid/next/$f was written beside the queue"; done
# a trigger declined through the queue
W=$(awk -F'\t' '$1 == "trigger" { print $3; exit }' "$T/L"); S=$(awk -F'\t' -v w="$W" '$1 == "trigger" && $3 == w { print $4; exit }' "$T/L")
QT=$(qof "trigger:$W:"); [ -n "$QT" ] || fail "the trigger $W $S has no open Q line: $(cat "$T/ql")"
grep -q "^$QT${TB}trigger:$W:[a-z]*:[0-9a-f]*:$S@[0-9]*${TB}decline" "$T/ql" || fail "the list names $QT without its key or its answers: $(grep "^$QT" "$T/ql")"
RC=0; sh "$CHECKS/queue.sh" answer "$QT" decline '' > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] || fail 'a decline with no words was taken'
sh "$CHECKS/queue.sh" answer "$QT" decline 'not this stage' > "$T/out" 2>&1 || fail 'the decline was refused'
sh "$CHECKS/next.sh" triggers > "$T/L2" 2> "$T/out" || fail 'next.sh triggers failed after the decline'
grep -q "^quiet${TB}[a-z]*${TB}$W${TB}$S${TB}.*${TB}declined\$" "$T/L2" || { cat "$T/L2" >&2; fail "$W $S, declined through the queue, is not counted declined"; }
! grep -q "^trigger${TB}[a-z]*${TB}$W${TB}$S${TB}" "$T/L2" || fail "$W $S, declined, is still shown"
sh "$CHECKS/queue.sh" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'; ! awk -F'\t' -v q="$QT" '$1 == q { f = 1 } END { exit !f }' "$T/ql" || fail "$QT, declined, is still open"
# a move's to-do done through the queue
QM=$(qof 'move:planning-analysis:'); [ -n "$QM" ] || fail "planning-analysis has no open Q line: $(cat "$T/ql")"
sh "$CHECKS/queue.sh" answer "$QM" done 'I have read it' > "$T/out" 2>&1 || fail 'the done was refused'
[ -z "$(qof 'move:planning-analysis:')" ] || fail 'planning-analysis, done, is still on the list'
grep -q "^move${TB}planning-analysis${TB}" "$T/L2" || fail 'planning-analysis is no longer listed as a move'
# the paths beside the queue are gone
RC=0; sh "$CHECKS/next.sh" decline "$W" 'x' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "next.sh decline is still a subcommand (exit $RC)"
RC=0; sh "$CHECKS/next.sh" shown "$T/L" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "next.sh shown is still a subcommand (exit $RC)"
RC=0; sh "$CHECKS/next-page.sh" todo-done publish S04 words 'x' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "next-page.sh todo-done is still a subcommand (exit $RC)"
RC=0; sh "$CHECKS/next-move.sh" call accept-spec-change "$D" 'x' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 2 ] || fail "accept-spec-change is still a move (exit $RC)"
for f in shown moves declined todo questions; do [ ! -e ".vid/next/$f" ] || fail ".vid/next/$f was written beside the queue"; done
exit 0
