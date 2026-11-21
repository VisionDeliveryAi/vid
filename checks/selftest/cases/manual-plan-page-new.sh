#!/bin/sh
# Purpose: selftest case — what is new since the owner's last call (GM-2 T12). On the toy (fixtures/plan-page.sh) with the fake gh:
# #1 (S01), #2 (S02) and #3 (S03) published, #2 given two units. Call 1: `next.sh read`, the first after the switch, keeps no
# read before it, and the page says it has nothing to compare with. Between the calls #3 is assigned (taken), one of #2's units
# closes, and a question is asked on #2. Call 2: the connect keeps call 1's read whole as .vid/round/read.prev (GM-4 F3, copied here as the connect does); the page's new
# list names exactly those three, and its to-do list holds the question's answer move (answer #2:1, in the §5 form a call hands
# the page). Call 3: the team empties #1's body, which named ROW-003, and adds a tab-indented ROW-012 line to #3's; with the
# two team-change moves the call would hand it, the new list names exactly those two team changes (an emptied body read whole
# is compared, and a body line keeps its text after a tab). Last, with a read before that failed whole (its one line `unread
# round`), the page says it has nothing to compare with, and names no ticket opened. Env: CHECKS.
set -eu
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
news() { grep -o 'data-new="[^"]*"' "$PG" | sed 's/^data-new="//; s/"$//' | sort | paste -sd ',' -; }
# call 1
sh "$CHECKS/next.sh" read > "$T/pw" 2>&1 || fail 'call 1: next.sh read failed'
! grep -q '^unread' .vid/round/read || fail "call 1's read failed in part: $(grep '^unread' .vid/round/read | head -n 1)"
[ ! -f .vid/round/read.prev ] || fail 'the first read after the switch kept a read before it'
cp .vid/round/read "$T/read1"; pp_trig "$T/c1"
pp_write "$T/c1"; [ "$PP_RC" = 0 ] || fail "call 1's write failed ($PP_RC)"
[ "$(news)" = none ] || fail "call 1's new list is '$(news)', not that it has nothing to compare with"
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
[ "$(news)" = "$(printf 'question #%s:1\ntaken #%s\nunit-closed #%s\n' "$B" "$C" "$U1" | sort | paste -sd ',' -)" ] || fail "call 2's new list is '$(news)', not the ticket taken, the unit closed and the question"
grep -q 'data-q="Q[0-9]*"><b>Q[0-9]*</b>: Question: may the limit be twenty?' "$PG" || fail "the to-do list does not hold the question's Q line"
# call 3: #1's body emptied, a tab-indented test added to #3's
: > "$FAKEGH/issues/$A/body"; printf -- '- ROW-006\n\tROW-012\n' > "$FAKEGH/issues/$C/body"
cp .vid/round/read .vid/round/read.prev   # GM-4 F3 (I2): the connect's copy at the call's start
sh "$CHECKS/next.sh" read > "$T/pw" 2>&1 || fail 'call 3: next.sh read failed'
! grep -q "^body	$A	" .vid/round/read && grep -q "^body	$C		ROW-012\$" .vid/round/read || fail "call 3's read does not hold #1's body empty and #3's tab-indented line"
pp_trig "$T/c3"
{ printf 'move\tteam-change\t#%s ROW-003\th-d\ttake in or decline: dropped ROW-003 on #%s\n' "$A" "$A"
  printf 'move\tteam-change\t#%s ROW-012\th-a\ttake in or decline: added ROW-012 on #%s\n' "$C" "$C"; } >> "$T/c3"
pp_write "$T/c3"; [ "$PP_RC" = 0 ] || fail "call 3's write failed ($PP_RC)"
[ "$(news)" = "$(printf 'team-change #%s ROW-003\nteam-change #%s ROW-012\n' "$A" "$C" | sort | paste -sd ',' -)" ] || fail "call 3's new list is '$(news)', not the two team changes"
# a read before that failed whole: nothing to compare with
printf 'unread\tround\t-\tnext-read exited 1: the network is down\n' > .vid/round/read.prev
pp_write "$T/c3"; [ "$PP_RC" = 0 ] || fail "the last write failed ($PP_RC)"
[ "$(news)" = none ] || fail "with the read before failed whole, the new list is '$(news)', not that it has nothing to compare with"
exit 0
