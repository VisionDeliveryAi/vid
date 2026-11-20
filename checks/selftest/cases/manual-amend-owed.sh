#!/bin/sh
# Purpose: selftest case — in GitHub manual an amendment is owed only when the plan's rows for a ticket differ from its log line's
# rows, never for its writer's wording alone (GM-2 T5; its case manual-amend-owed); and lane B's review: /vid mode manual makes an
# empty .vid/tw/handed when it has none, so writer.sh due runs on a switched project. On GitHub manual's toy project
# (fixtures/manual.sh), #1 (S01) and #2 (S02) published by hand, each ticket written in an older writer's form (fixtures/manual.sh's
# mn_ticket: its own header and asks, its rows quoted), S02's holding every row S02 has in the plan, and taken over by the switch.
# After the switch: .vid/tw/handed exists; writer.sh due owes nothing; next.sh triggers prints no `unread due` line and no amend or
# withdraw move. ROW-002 then moves from S04 into S02 by a recorded plan change: due owes `amend 2` alone, and triggers lists the
# move `amend #2`. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "manual-amend-owed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
mn_project "$T/p"
R2=$(sed -n 's/^step S02 .*| rows: \([^|]*[^| ]\) *|.*/\1/p' "$T/plan.blk"); [ -n "$R2" ] || fail "S02's rows could not be read from the toy's plan"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" comments 2
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step $R2 > "$T/t2"; gh_writing "$N2" "$T/t2" comments 2
printf '%s S01\n%s S02\n' "$N1" "$N2" > "$T/register"; gh_wclear
mn_switch --applied "$AP" --words 'yes, ratify the taken-over plan'; cp "$T/mo" "$T/out"
[ "$MN_RC" = 0 ] || fail "the switch exited $MN_RC"
[ -f .vid/tw/handed ] || fail 'the switch left no .vid/tw/handed'
sh "$CHECKS/writer.sh" due > "$T/due" 2>&1 || { cp "$T/due" "$T/out"; fail 'writer.sh due failed on the switched project'; }
[ ! -s "$T/due" ] || { cp "$T/due" "$T/out"; fail "due owes something for tickets whose rows are unchanged: $(paste -sd ';' "$T/due")"; }
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
! grep -q "^unread${TB}due" "$T/tr" || { grep "^unread${TB}due" "$T/tr" > "$T/out"; fail 'triggers says writer.sh due did not run'; }
! grep -qE "^move${TB}(amend|withdraw)${TB}" "$T/tr" || { grep '^move' "$T/tr" > "$T/out"; fail 'an amend or withdraw move is listed for unchanged rows'; }
# a row added to S02
pt_rs 's/^\(step S04 .*rows:.*\) ROW-002 /\1 /'; pt_rs 's/^\(step S02 .*rows:\) /\1 ROW-002 /'
sh "$CHECKS/plan.sh" change rows 'S02 takes ROW-002' --trigger owner-answer --evidence "ticket:$N2" --expect 'S02 gains a test' > "$T/out" 2>&1 || fail 'the plan change was refused'
sh "$CHECKS/writer.sh" due > "$T/due" 2>&1 || { cp "$T/due" "$T/out"; fail 'writer.sh due failed after the change'; }
[ "$(cat "$T/due")" = "amend $N2" ] || { cp "$T/due" "$T/out"; fail "due does not owe amend $N2 alone once its step gained a row"; }
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed after the change'
grep -q "^move${TB}amend${TB}#$N2${TB}" "$T/tr" || { grep '^move\|^unread' "$T/tr" > "$T/out"; fail "triggers lists no amend #$N2 move"; }
exit 0
