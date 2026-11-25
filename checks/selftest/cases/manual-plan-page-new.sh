#!/bin/sh
# Purpose: selftest case — what is new since the owner's last call, on each card (GM-2 T12; FB-5 A1: in the owner's list). On the toy
# (fixtures/plan-page.sh) with the fake gh: #1 (S01), #2 (S02) and #3 (S03) published, #2 given two units. Call 1: `next.sh read`,
# the first after the switch, keeps no read before it, and no card says anything is new. Between the calls #3 is assigned (taken), one
# of #2's units closes, and a question is asked on #2. Call 2: the connect keeps call 1's read whole as .vid/round/read.prev (GM-4 F3,
# copied here as the connect does); #3's card says it was taken, #2's that a piece is done, and that a question waits. Call 3: the team
# empties #1's body, which named ROW-003, and adds a tab-indented ROW-012 line to #3's; with the two team-change moves the call would
# hand on, #1's card says a test dropped and #3's a test added by the team, and none is new (an emptied body read whole is compared, and a
# body line keeps its text after a tab). Call 4: a ticket sent, one closed, a
# piece given, a pull request opened and one of a piece merged are each said, and a ticket the read holds an unread line of is left
# out. Last, with a read before that failed whole (its one line `unread round`), no card says
# anything is new. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "manual-plan-page-new: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
pp_toy "$T/toy"; tk_code; gh_fake
printf -- '- ROW-003\n' > "$T/ba"; printf -- '- ROW-006\n' > "$T/bc"
A=$(gh_issue 'Skeleton' "$T/ba"); B=$(gh_issue 'Step S02'); C=$(gh_issue 'Step S03' "$T/bc"); U1=$(gh_issue 'Unit one'); U2=$(gh_issue 'Unit two')
gh_sub "$B" "$U1"; gh_sub "$B" "$U2"
{ printf 'published %s kind=skeleton step=S01 rows=ROW-003,ROW-004 at=2026-11-10T09:00:00Z words="go"\n' "$A"
  printf 'published %s kind=step step=S02 rows=ROW-001 at=2026-11-10T09:00:00Z words="go"\n' "$B"
  printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-10T09:00:00Z words="go"\n' "$C"; } > .vid/tw/log
news() { pj "'|'.join(x['id'] + ': ' + n for x in cs for n in x['notes'])"; }
# call 1
sh "$CHECKS/next.sh" read > "$T/pw" 2>&1 || fail 'call 1: next.sh read failed'
! grep -q '^unread' .vid/round/read || fail "call 1's read failed in part: $(grep '^unread' .vid/round/read | head -n 1)"
[ ! -f .vid/round/read.prev ] || fail 'the first read after the switch kept a read before it'
cp .vid/round/read "$T/read1"; pp_trig "$T/c1"
pp_write "$T/c1"; [ "$PP_RC" = 0 ] || fail "call 1's write failed ($PP_RC)"
[ -z "$(news)" ] || fail "call 1's cards say '$(news)', with nothing to compare with"
# between the calls
gh_attr "$C" assignees bo; gh_attr "$U1" state CLOSED
gh issue comment "$B" -R owner/code --body 'Question: may the limit be twenty?' > /dev/null
# call 2
cp .vid/round/read .vid/round/read.prev   # GM-4 F3 (I2): the connect keeps the call before's read at a call's start
sh "$CHECKS/next.sh" read > "$T/pw" 2>&1 || fail 'call 2: next.sh read failed'
cmp -s "$T/read1" .vid/round/read.prev || fail "next.sh read moved the read before (.vid/round/read.prev), the connect's alone"
cmp -s "$T/read1" .vid/round/read && fail "call 2's read is call 1's"
pp_trig "$T/c2"
# GM-4 F4: the question is the owner's queue's (every question the owner's), its Q line made by the queue's scan
grep -qx 'owner-questions: all' .vid/tw/settings 2>/dev/null || printf 'owner-questions: all\n' >> .vid/tw/settings
sh "$CHECKS/queue.sh" sync > "$T/pw" 2>&1 || fail 'call 2: queue.sh sync failed'
pp_write "$T/c2"; [ "$PP_RC" = 0 ] || fail "call 2's write failed ($PP_RC)"
W="S02: 1 question of the team waits for an answer|S02: Since your last call: 1 piece done|S03: Since your last call: taken"
[ "$(news)" = "$W" ] || fail "call 2's cards say '$(news)', not the question, the piece done and the ticket taken"
# call 3: #1's body emptied, a tab-indented test added to #3's
: > "$FAKEGH/issues/$A/body"; printf -- '- ROW-006\n\tROW-012\n' > "$FAKEGH/issues/$C/body"
cp .vid/round/read .vid/round/read.prev   # GM-4 F3 (I2): the connect's copy at the call's start
sh "$CHECKS/next.sh" read > "$T/pw" 2>&1 || fail 'call 3: next.sh read failed'
! grep -q "^body	$A	" .vid/round/read && grep -q "^body	$C		ROW-012\$" .vid/round/read || fail "call 3's read does not hold #1's body empty and #3's tab-indented line"
pp_trig "$T/c3"
{ printf 'move\tteam-change\t#%s ROW-003\th-d\ttake in or decline: dropped ROW-003 on #%s\n' "$A" "$A"
  printf 'move\tteam-change\t#%s ROW-012\th-a\ttake in or decline: added ROW-012 on #%s\n' "$C" "$C"; } >> "$T/c3"
pp_write "$T/c3"; [ "$PP_RC" = 0 ] || fail "call 3's write failed ($PP_RC)"
W="S01: 1 test dropped by the team|S02: 1 question of the team waits for an answer|S03: 1 test added by the team"
[ "$(news)" = "$W" ] || fail "call 3's cards say '$(news)', not the two team changes, and the question still"
# call 4: #2 closed, given a piece, one of its pieces' pull requests merged; a pull request of #3 opened; #96 (S04) sent; #1 closed, but
# the read holds an unread line of it, so it is left out
cp "$T/c3" "$T/c4"; cp .vid/round/read .vid/round/read.prev
sed -i.bak "s/^ticket	$B	OPEN/ticket	$B	CLOSED/; s/^ticket	$A	OPEN/ticket	$A	CLOSED/" .vid/round/read
{ printf 'sub\t%s\t%s\t97\tOPEN\t-\tUnit three\n' "$B" "$B"; printf 'merged\t22\t%s\tabc\tabc\t-\n' "$U1"; printf 'open\t21\t%s\tabd\tfalse\t-\t0\t0\t2026-11-18T09:00:00Z\t-\n' "$C"
  printf 'ticket\t96\tOPEN\t-\t2026-11-18T09:00:00Z\n'; printf 'unread\tbody\t%s\tthe network\n' "$A"; } >> .vid/round/read
printf 'published 96 kind=step step=S04 rows=ROW-002 at=2026-11-18T09:00:00Z words="go"\n' >> .vid/tw/log
pp_write "$T/c4"; [ "$PP_RC" = 0 ] || fail "call 4's write failed ($PP_RC)"
[ "$(news | tr '|' '\n' | grep 'Since your last call')" = "$(printf '%s\n' 'S02: Since your last call: closed, 1 piece given, pull request #22 merged' 'S03: Since your last call: pull request #21 opened' 'S04: Since your last call: opened')" ] || fail "call 4's cards say '$(news)', not what is new, the ticket read in part left out"
cp .vid/round/read.prev .vid/round/read; sed -i.bak '/^published 96 /d' .vid/tw/log
# a read before that failed whole: nothing to compare with
printf 'unread\tround\t-\tnext-read exited 1: the network is down\n' > .vid/round/read.prev
pp_write "$T/c3"; [ "$PP_RC" = 0 ] || fail "the last write failed ($PP_RC)"
[ "$(news)" = "$W" ] || fail "with the read before failed whole, the cards say '$(news)': something new, with nothing to compare with"
echo 'manual-plan-page-new: ok'
