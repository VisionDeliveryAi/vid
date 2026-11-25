#!/bin/sh
# Purpose: selftest case — the backlog is fed and closed by the queue (FB-3 D1). On GitHub manual's toy (fixtures/manual.sh) two
# calls' lines are raised (queue.sh raise): each Q line is once in .vid/decide/queue/backlog, `to do`, the owner's, in the order it
# came, its next action the answers it takes; the same lines raised again leave the file byte for byte. A trigger whose evidence
# changed keeps its place, its mark and the next action set for it, its Q number and words fresh, and a new move lands at the end.
# A call read in part closes nothing and makes no second line of a trigger whose evidence changed. An answer closes its line with
# the owner's words; a line no longer raised by a whole call is done, `no longer there`. `queue.sh backlog` (FB-5 A1: as text)
# holds the open lines in order, then `next:`, always with an open line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "backlog-fed: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/decide/queue/backlog >&2 2>/dev/null; exit 1; }
mn_project "$T/p"; printf 'mode: tickets\nplan: required\nrun: waiting\n' > .vid/RUN-STATE.md
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied; printf 'owner-questions: all\n' >> .vid/tw/settings
B=.vid/decide/queue/backlog; QS=$CHECKS/queue.sh
qs() { RC=0; sh "$QS" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "queue.sh $1 exited $RC"; }
ln() { printf "$1\t$2\t$3\t$4\t$5\n"; }
row() { awk -F'\t' -v s="$1" '$3 != "done" && index($2, s) == 1' "$B"; }
f() { row "$1" | cut -f"$2"; }
{ ln trigger critical blocked '#4' 'label vid:blocked'; ln trigger important step-slow S02 'out 9 days'; ln move publish S03 0123456789abcdef 'publishes the ticket of S03'; } > "$T/L1"
qs raise "$T/L1"; [ -f "$B" ] || fail 'a call that raised three lines left no backlog'
sh "$QS" list > "$T/ql" 2> "$T/out" || fail 'queue.sh list failed'
[ "$(cut -f1 "$T/ql" | paste -sd ' ' -)" = "$(cut -f1 "$B" | paste -sd ' ' -)" ] && [ "$(grep -c . "$B")" = 3 ] || fail 'the backlog is not the three Q lines, once each, in order'
[ "$(cut -f3,4 "$B" | sort -u)" = "$(printf 'to do\tyou')" ] || fail 'a new line is not to do, the owner'"'"'s'
[ "$(f trigger:blocked: 6)" = 'decline|done "<words>"' ] || fail 'the next action is not the answers the line takes'
[ "$(awk -F'\t' '{ print NF }' "$B" | sort -u)" = 9 ] && [ "$(cut -f9 "$B" | sort -u)" = - ] || fail 'an open line is not nine fields, its end -'
cp "$B" "$T/b1"; qs raise "$T/L1"; cmp -s "$T/b1" "$B" || fail 'the same lines raised again changed the backlog'
# a trigger whose evidence changed keeps its place, its mark and its set next action; a new move lands at the end
Q2=$(f trigger:step-slow: 1); qs backlog set "$Q2" --state aside --next 'ask the team' --note 'until Monday'
{ ln trigger critical blocked '#4' 'label vid:blocked, again'; ln trigger important step-slow S02 'out longer than its sibling'; ln move publish S03 0123456789abcdef 'publishes the ticket of S03'; ln move publish S04 1123456789abcdef 'publishes the ticket of S04'; } > "$T/L2"
qs raise "$T/L2"
[ "$(cut -f2 "$B" | cut -d: -f1,2 | paste -sd ' ' -)" = 'trigger:blocked trigger:step-slow move:publish move:publish' ] && f move:publish: 5 | tail -n 1 | grep -q S04 || fail 'the order did not hold: the new move is not last, or a changed trigger moved'
[ "$(f trigger:step-slow: 1)" != "$Q2" ] || fail 'the changed trigger kept its old Q number'
f trigger:step-slow: 5 | grep -q 'longer than its sibling' || fail 'the changed trigger kept its old words'
[ "$(f trigger:step-slow: 3)|$(f trigger:step-slow: 6)|$(f trigger:step-slow: 7)" = 'aside|ask the team|until Monday' ] || fail 'the changed trigger lost its mark, its next action or its note'
# a call read in part closes nothing, and a trigger changed in it is still one line, in its place
{ ln trigger critical blocked '#4' 'label vid:blocked, a third time'; printf 'unread\tround\t-\tthe read failed\n'; } > "$T/L3"; qs raise "$T/L3"
[ "$(awk -F'\t' '$3 == "done"' "$B" | grep -c . || true)" = 0 ] && [ "$(grep -c . "$B")" = 4 ] || fail 'a call read in part closed a line or doubled one'
[ "$(sed -n 1p "$B" | cut -f2 | cut -d: -f2)" = blocked ] && sed -n 1p "$B" | grep -q 'a third time' || fail 'a trigger changed in a part-read call lost its place or kept its old words'
# an answer closes its line with the owner's words
qs raise "$T/L2"; Q1=$(f trigger:blocked: 1); qs answer "$Q1" decline 'not now, the team knows'; qs list
[ -z "$(row trigger:blocked:)" ] || fail 'the answered line is still open'
awk -F'\t' -v q="$Q1" '$1 == q && $3 == "done" && $7 == "not now, the team knows" && $9 ~ /^20/ { x = 1 } END { exit !x }' "$B" || fail 'the answered line is not done with the owner'"'"'s words'
# a line no longer raised by a whole call
ln move publish S04 1123456789abcdef 'publishes the ticket of S04' > "$T/L4"; qs raise "$T/L4"
awk -F'\t' '$3 == "done" && index($2, "move:publish") == 1 && $5 ~ /S03/ && $7 == "no longer there" { x = 1 } END { exit !x }' "$B" || fail 'a move no longer raised is not done, no longer there'
[ "$(row '' | grep -c .)" = 1 ] || fail 'more than the one raised line is open'
sh "$QS" backlog > "$T/out" 2>&1 || fail 'queue.sh backlog failed'
[ "$(grep -c '^Q[0-9]' "$T/out")" = 1 ] && grep -q '^Q[0-9].*S04' "$T/out" && grep '^next: ' "$T/out" | grep -q '^next: Q[0-9]* · .*S04.* · done "<words>" · you$' || fail 'queue.sh backlog does not hold the open line, then next:'
QL=$(f move:publish: 1); qs backlog set "$QL" --state aside; sh "$QS" backlog > "$T/out"; grep -q '^next: none' "$T/out" || fail 'with every open line aside no next: is printed'
exit 0
