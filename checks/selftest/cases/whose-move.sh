#!/bin/sh
# Purpose: selftest case — one alarm: what the dev side owes, and since when (FB-7 B1), checks/round.sh in GitHub auto on the ticket writer's toy
# and the fake gh. With no sign for quiet-hours (1 by default) and an item owed, `flag devagent-quiet <items>: no sign since <UTC>`, once, and one
# `waits on:` line in the status while it stands. Owed: a ticket, claimed or not, but one blocked, left, merged, asked and not decided, or
# decided with its open rows all held; a run with a chunk not read and with no open question, one chunk of it read or not; a grade or an okay
# not read, not settled and not with the owner. A sign of each kind clears it: a claim, a pull request, its head, its draft state, a comment,
# a report; a comment of ViD's, or an issue closed, is none. Nothing owed starts the hour
# again; a sign younger than the hour flags nothing. No call more; no ticket-quiet; none in GitHub manual. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "${T:?}"' EXIT
HOME=$T/home; mkdir -p "$HOME"; GIT_CONFIG_GLOBAL=$T/gitconfig; export HOME GIT_CONFIG_GLOBAL; git config --global user.name a; git config --global user.email a@b
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "whose-move: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat .vid/round/dev >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; st() { rd step; [ "$RC" = 0 ] || fail "the step failed: $RC"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
rd next; grep -q '^published 1$' "$T/out" || fail 'next'; st
OLD=2020-01-01T00:00:00Z
# back [<UTC>]: the dev side's last sign set to then, what it owes and its signs as they are
back() { [ -f .vid/round/dev ] || fail 'no record of the dev side'"'"'s last sign, .vid/round/dev'; awk -F'\t' -v OFS='\t' -v u="${1:-$OLD}" 'NR == 1 { $1 = u } { print }' .vid/round/dev > "$T/dv"; cat "$T/dv" > .vid/round/dev; }
noflag() { grep -v '^devagent-quiet ' .vid/decide/flags > "$T/fl" || true; cat "$T/fl" > .vid/decide/flags; }
# owes <items>: at a step with the last sign old, the flag names them; none: no flag. No flag stands at the start
owes() { noflag; back; st
  if [ -n "$1" ]; then grep -qx "flag devagent-quiet $1: no sign since $OLD" "$T/out" || fail "owed $1: not flagged so${2:+ ($2)}"; else ! grep -q '^flag devagent-quiet' "$T/out" || fail "nothing owed, flagged${2:+ ($2)}"; fi; }
# sign <what>: the last sign old before it, that act is one at the next step, and clears the flag; nosign: it is none
sign() { st; [ "$(head -n 1 .vid/round/dev | cut -f1)" != "$OLD" ] && ! grep -q '^devagent-quiet ' .vid/decide/flags || fail "no sign: $1"; back; }
nosign() { st; [ "$(head -n 1 .vid/round/dev | cut -f1)" = "$OLD" ] && grep -q '^devagent-quiet ' .vid/decide/flags || fail "a sign: $1"; }
say() { printf '%s\nby: DM\n' "$2" > "$T/c"; gh issue comment "$1" -R $R --body-file "$T/c" > /dev/null; }
psay() { printf '%s\nby: DM\n' "$2" > "$T/c"; gh pr comment "$1" -R $R --body-file "$T/c" > /dev/null; }
blk() { gh issue edit "$1" -R $R --add-label blocked > /dev/null; }; unblk() { gh issue edit "$1" -R $R --remove-label blocked > /dev/null; }
utc() { date -u -r "$1" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "@$1" '+%Y-%m-%dT%H:%M:%SZ'; }
# unclaimed; once; the hour; the status
owes '#1' 'a ticket not claimed'; st; ! grep -q '^flag devagent-quiet' "$T/out" || fail 'said twice'
sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail 'status'; grep -qE '^waits on: the dev side, #1: no sign for [0-9]+ h [0-9]+ m$' "$T/out" || fail 'the status has no waits on: line'
! grep -q 'ticket-quiet' .vid/decide/flags || fail 'ticket-quiet is raised'
say 1 'vid: claimed'; sign 'a claim'; sh "$CHECKS/queue.sh" status > "$T/out" 2>&1; ! grep -q '^waits on:' "$T/out" || fail 'the status still waits on the dev side'
U=$(utc $(($(date +%s) - 3300))); back "$U"; st; ! grep -q '^flag devagent-quiet' "$T/out" || fail 'flagged before the hour'
U=$(utc $(($(date +%s) - 3700))); back "$U"; st; grep -qx "flag devagent-quiet #1: no sign since $U" "$T/out" || fail 'not flagged after the hour, with quiet-hours not set'
owes '#1' 'a claimed ticket'
# the signs; ViD's own are none
printf 'RM: the answer\n' > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; printf 'vid: again p1c1\nby: RM\n' > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; nosign "ViD's own comments"
X=$(gh issue create -R $R --title 'x' --body x | sed 's#.*/##'); say "$X" 'DM: a note'; sign 'a comment'; gh issue close "$X" -R $R > /dev/null; nosign 'an issue closed'
W=$T/w; git clone -q "$T/code.git" "$W" 2>/dev/null; git -C "$W" checkout -q -b ticket-1; push() { git -C "$W" commit -q --allow-empty -m "$1"; git -C "$W" push -q origin ticket-1 2>/dev/null; }; push t
P=$(gh pr create -R $R --head ticket-1 --base main --draft --title t --body "$(printf 'ticket: #1\n\nDecisions: none')" | sed 's/.*\///'); sign 'a pull request'
k=$(ls "$T/gh/issues/1/comments" | sort -n | head -n 1); printf 'DM: a claim taken back\nby: DM\n' > "$T/gh/issues/1/comments/$k"; sign 'a comment edited'
push t2; sign 'a new head'; if [ "$(cat "$T/gh/prs/$P/draft")" = true ]; then echo false > "$T/gh/prs/$P/draft"; else echo true > "$T/gh/prs/$P/draft"; fi; sign 'its draft state'; echo false > "$T/gh/prs/$P/draft"
git -C "$W" push -q origin HEAD:refs/heads/vid-results/req-1-p1c1-1 2>/dev/null; sign 'a report'
# ViD's move: an ask not decided, then its decision; a decision whose open rows are all held
H=$(git -C "$W" rev-parse HEAD); h=$(printf %.12s "$H"); psay "$P" "vid: decide $H"; st; grep -q "^decided $P " "$T/out" || fail 'not decided'
st; owes '#1' 'decided, not yet'
KR=.vid/decide/pr-$P-$h; cp "$KR.rows" "$T/rows"; rows() { awk -F'\t' -v OFS='\t' "$1"' { print }' "$T/rows" > "$KR.rows"; printf 'vid: decision %s\nticket: not yet\n' "$H" > "$KR.txt"; }
rows '{ $3 = (NR == 1) ? "held" : "accepted" }'; owes '' 'its open rows all held'
rows '{ $3 = (NR == 1) ? "held" : "its state stands" }'; owes '' 'one held, the rest standing as they are'
rows '{ $3 = (NR == 1) ? "held" : (NR == 2) ? "failing" : "accepted" }'; owes '#1' 'one held and one failing'
rows '{ $3 = (NR == 1) ? "held" : "accepted" }'; echo 'decisions missing — x' >> "$KR.txt"; owes '#1' 'held, and its decisions missing'
rows '{ $3 = "accepted" }'; owes '#1' 'accepted, not merged'; cp "$T/rows" "$KR.rows"
# the owner's: blocked, on the ticket or on its pull request; left
blk 1; owes '' 'a ticket blocked'; unblk 1; owes '#1'
printf 'blocked\n' > "$T/gh/prs/$P/labels"; owes '' 'its pull request blocked'; : > "$T/gh/prs/$P/labels"
printf 'DM: left: no account\n' > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; st; owes '' 'a ticket left'
printf "vid: reopened at the owner's word\n" > "$T/c"; gh issue comment 1 -R $R --body-file "$T/c" > /dev/null; owes '#1' 'a ticket taken up again'
# nothing owed starts the hour again: the first step at which something is owed flags nothing
blk 1; back; st; unblk 1; st; ! grep -q '^flag devagent-quiet' "$T/out" || fail 'flagged at once for what was only now owed'
blk 1
# runs, grades and okays ViD asked, by ViD's own records, every state at one step: stage 9's candidates 1 to 12
iss() { n=$(gh issue create -R $R --title "$1" --body x --label "$1" | sed 's#.*/##'); echo "asked $n close step=S01 commit=x at=2026-11-20T00:00:00Z" >> .vid/tw/log; echo "$n"; }
# made <path under stage 9> <label>: an ask of an issue there, its number
made() { f=.vid/decide/stage/9/$1; mkdir -p "${f%/*}"; i=$(iss "$2"); printf 'issue\t%s\ncommit\tx\n' "$i" > "$f"; echo "$i"; }
S9=.vid/decide/stage/9; mk() { printf '%s' "${2:-}" > "$S9/$1"; }
A=$(made 1/cs/ask run)                                                    # no chunk read: owed
B=$(made 2/cr/ask run); printf 'c1|green|1||\nc2|absent|||\n' > "$S9/2/cr/chunks"; say "$B" 'vid: reported c1-1'   # one read, one owed: owed
C=$(made 3/cp/ask run); printf 'c1|red|1| alpha:ROW-001|\nc2|incomplete|1|| ROW-002\n' > "$S9/3/cp/chunks"   # one to run again: owed
L=$(made 4/cp/ask run); printf 'c2|incomplete|1|| ROW-002\n' > "$S9/4/cp/chunks"; echo 'lost c2 ROW-002 #1' > "$S9/4/cp/items"   # with the owner
x=$(made 5/cs/ask run); printf 'c1|red|1| alpha:ROW-001|\nc2|green|1||\n' > "$S9/5/cs/chunks"
x=$(made 6/cs/ask run); mk 6/cs/done; x=$(made 7/cs/ask run); mk 7/cs/passed; x=$(made 8/cs/ask run); mk 8/cs/withdrawn; x=$(made 9/cs/ask run); mk 9/withdrawn
BL=$(made 10/cs/ask run); blk "$BL"
G=$(made 1/s1ask grade); x=$(made 2/s1ask grade); mk 2/s1done; x=$(made 3/s1ask grade); mk 3/s1withdrawn
made 12/ask run > /dev/null; mk 12/done; LG=$(made 12/s1ask grade); echo 'lost s1 #1' > "$S9/12/items"                     # its grade with the owner
O=$(made 1/d1/ask deploy); x=$(made 2/d1/ask deploy); mk 2/d1/closed withdrawn; x=$(made 3/rh/ask deploy); mk 3/rh/passed
LO=$(made 4/d2/ask deploy); echo "failed d2 at migrate #$((LO * 1000 + 2))" > "$S9/4/d2/items"; RC2=$(made 7/d2/ask deploy); mk 7/d2/passed; mk 7/d2/recovery-asked; x=$(made 8/d2/ask deploy); mk 8/d2/passed; x=$(made 9/d2/ask deploy); mk 9/d2/passed; mk 9/d2/recovery-asked; mk 9/d2/closed recovered   # a recovery asked after it passed: owed
DN=$(made 5/dn-staging/ask deploy); x=$(made 6/dn-staging/ask deploy); mk 6/dn-staging/done
Z=$(iss grade); mkdir -p ".vid/decide/grade/$Z"; printf 'issue\t%s\ncommit\tx\n' "$Z" > ".vid/decide/grade/$Z/ask"; : > ".vid/decide/grade/$Z/done"
set_() { printf '%s\n' "$@" | sort -n | sed 's/^/#/' | paste -sd, -; }
st; owes "$(set_ "$A" "$B" "$C" "$G" "$O" "$RC2" "$DN")" 'runs, grades and okays'
# the owner answers again, a run is unblocked, a ticket is owed too; the flag that stands is not said again when what is owed changes
printf '2026-11-20T00:00:00Z\tclose:stage-9/4/cp:lost:c2:1\tagain\t\towner\n' >> .vid/decide/queue/answers; unblk "$BL"; unblk 1; owes "$(set_ 1 "$A" "$B" "$C" "$L" "$BL" "$G" "$O" "$RC2" "$DN")" 'after the answer'
mk 1/s1done; mk 1/cs/done; st; ! grep -q '^flag devagent-quiet' "$T/out" || fail 'said again when an item left'
grep -qx "devagent-quiet $(set_ 1 "$B" "$C" "$L" "$BL" "$O" "$RC2" "$DN")" .vid/decide/flags && [ "$(grep -c '^devagent-quiet ' .vid/decide/flags)" = 1 ] || fail "the standing flag keeps its first items: $(grep devagent-quiet .vid/decide/flags)"
sh "$CHECKS/queue.sh" status > "$T/out" 2>&1; grep -q "^waits on: the dev side, $(set_ 1 "$B" "$C" "$L" "$BL" "$O" "$RC2" "$DN"): no sign for " "$T/out" || fail 'the status does not name what is owed now'
# no call more than the round's read makes
: > "$T/gh/log"; sh "$GS" round-read > /dev/null; n0=$(grep -cE '^(pr|issue) list' "$T/gh/log" || true); : > "$T/gh/log"; st; [ "$(grep -cE '^(pr|issue) list' "$T/gh/log" || true)" -le "$n0" ] || fail 'the alarm makes a call'
# GitHub manual raises none
noflag; back; VID_CALLER=mode rd step; ! grep -q 'devagent-quiet' "$T/out" && ! grep -q 'devagent-quiet' .vid/decide/flags || fail 'GitHub manual raised it'
if [ -d "$CHECKS/../skills/vid-run" ]; then F=$CHECKS/../skills/vid-run/SKILL.md
  grep -q '^| `flag devagent-quiet <items>: no sign since <UTC>` (FB-7 B1) | Tell the owner once, in one line: `No sign from the dev side since <UTC>: it owes <items>\. Start it with /vid:vid-devagent <job note> in a new conversation in its work folder, or in the background with dm\.sh up <job note>, or check that it runs\.` It stops nothing |$' "$F" || fail "vid-run's table has no such devagent-quiet row"
  grep -qF 'Of anything asked of the dev side, say *asked*, never *told* or *under way*, until a sign after it.' "$F" || fail "vid-run does not say how to speak of what is asked"; fi
echo 'whose-move: ok'
