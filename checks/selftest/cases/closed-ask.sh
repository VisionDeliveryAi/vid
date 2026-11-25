#!/bin/sh
# Purpose: selftest case — a ticket the team's automation closed as completed, asked to be decided (FB-6 A1), in GitHub manual on the toy and
# the fake gh (fixtures/accept.sh). Its ask is shown once with own work off and with it on, and the ticket once as closed; round.sh step
# prints its `decide`; accept decides it, not refused: first `not yet`, whose last line says it is closed, then, asked again, accepted, its
# acceptance on record, the ticket neither reopened nor closed by ViD and nothing but the two decisions posted; then no line says it, its
# issue line is gone from the read and no view more is made of it. A ticket closed by its team with no ask is told with its commands. One
# closed as a duplicate is refused, as one not planned. A view that fails is one unread line, and accept's refusal says so and names no
# command; a ticket accepted or withdrawn is not viewed so. GitHub auto's read holds none of it. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "closed-ask: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TAB=$(printf '\t')
ac_project "$T/p" || fail 'the toy could not be made'; ac_plan || fail 'the plan could not be recorded'; c12=$(printf %.12s "$AC_C")
trig() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; cp "$T/L" "$T/out"; }
n_() { grep -c "$1" "$T/L" || true; }
# views of ticket <n> for its comments and reason
views() { grep -c "^gh issue view $1 .*stateReason" "$FAKEGH/log" || true; }
M=$(gh_issue 'Step S03'); { mn_ticket "$M" S03 step ROW-006; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$M.md"; printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\n' "$M" >> .vid/tw/log
gh issue close "$AC_N" -R owner/code; ac_red; ac_head "$AC_C" 1 ROW-001=pass ROW-012=fail:no_page; ac_ask "$AC_C"; c0=$(ac_comments); gh_wclear
[ "$(sh "$CHECKS/next.sh" own-work)" = off ] || fail 'own work is not off'
for w in off on; do [ $w = off ] || printf 'setup-answered key=own-work value="on" words="yes" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
  trig; [ "$(n_ "^context${TAB}ask${TAB}#$AC_N${TAB}$c12${TAB}/vid:vid-accept-step $AC_N $c12\$")" = 1 ] || fail "own work $w: the ask on the closed ticket is not shown once"
  [ "$(n_ "^context${TAB}closed${TAB}#$AC_N${TAB}closed on GitHub, not accepted — the team asks for its decision, the line above\$")" = 1 ] && [ "$(n_ "^context${TAB}closed$TAB")" = 1 ] || fail "own work $w: the ticket is not told closed once"; done
sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail 'queue.sh status failed'; grep -q '^tickets: open 1 ' "$T/out" && ! grep -q "#$AC_N S02" "$T/out" || fail 'a closed ticket is counted as an open one'
ac_round step; grep -q ' open=1 ' "$T/out" && [ "$RC" = 0 ] && [ "$(grep -c "^decide #$AC_N $AC_C\$" "$T/out")" = 1 ] && ! grep -q '^closed #' "$T/out" || fail 'the closed ticket is not owed its decision once, or is said closed twice'
ac_round accept "$AC_N" "$AC_C"; grep -q "^decided #$AC_N $c12 ticket: not yet" "$T/out" || fail 'the closed ticket was not decided'
[ "$(ac_comments)" = $((c0 + 1)) ] && ac_last > "$T/out" && [ "$(tail -n 1 "$T/out")" = 'this ticket is closed on GitHub and not accepted: ask again here' ] || fail 'the not yet does not end with the line that says it is closed'
ac_round step; ! grep -q "^decide #$AC_N " "$T/out" || fail 'an answered ask is still owed'
trig; [ "$(n_ "^context${TAB}closed${TAB}#$AC_N${TAB}closed on GitHub, not accepted — /vid:vid-tickets reopen #$AC_N \".*/vid:vid-accept-step $AC_N <commit> accepted \"")" = 1 ] && ! grep -q "^context${TAB}closed.*withdraw" "$T/L" || fail 'with no ask owed, the closed ticket is not told with its two commands'
ac_head "$AC_C" 2; ac_grade "$AC_C"; ac_ask "$AC_C"; ac_round accept "$AC_N" "$AC_C"; grep -q "^accepted #$AC_N $c12" "$T/out" || fail 'asked again, it was not accepted'
[ "$(ac_comments)" = $((c0 + 3)) ] && ! ac_last | grep -q 'closed on GitHub' && grep -q "^step-$AC_N-$c12$TAB$AC_N$TAB$AC_C$TAB$AC_C\$" .vid/decide/merges || fail 'its acceptance is not on record, or the accepted answer says it is closed'
! grep -q "issue \(reopen\|close\) $AC_N\$" "$FAKEGH/writes" || { cp "$FAKEGH/writes" "$T/out"; fail 'ViD reopened or closed the ticket'; }
v0=$(views "$AC_N"); trig; ! grep -q "^context${TAB}\(closed\|ask\)${TAB}#$AC_N$TAB" "$T/L" && ! grep -q "^issue${TAB}$AC_N$TAB" .vid/round/read && [ "$(views "$AC_N")" = "$v0" ] || fail 'an accepted ticket is still said, or viewed once more'
# one closed as a duplicate, and a view that fails
gh issue close "$M" -R owner/code --reason duplicate; trig; ! grep -q "^issue${TAB}$M$TAB" .vid/round/read && [ "$(n_ "^context${TAB}closed${TAB}#$M${TAB}closed on GitHub as not planned, not accepted — ")" = 1 ] || fail 'a ticket closed as a duplicate reads as one completed'
ac_round accept "$M" "$AC_C"; grep -q "^refused #$M closed on GitHub before its acceptance: " "$T/out" || fail 'a ticket closed as a duplicate was not refused'
echo COMPLETED > "$FAKEGH/issues/$M/reason"; echo 'gh: 502' > "$FAKEGH/issues/$M/view-fail"; trig; grep -q "^unread${TAB}closed${TAB}$M${TAB}" "$T/L" && ! grep -q "^context${TAB}closed${TAB}#$M$TAB" "$T/L" || fail 'a view that fails is not one unread line'
ac_round accept "$M" "$AC_C"; grep -qx "refused #$M its issue could not be read: try again" "$T/out" || fail 'the refusal after a failed view does not say so alone'
rm "$FAKEGH/issues/$M/view-fail"; printf 'withdrawn %s decision=closed-outside at=2026-11-20T09:00:00Z words="no"\n' "$M" >> .vid/tw/log; v0=$(views "$M"); trig; [ "$(views "$M")" = "$v0" ] && ! grep -q "^context${TAB}closed${TAB}#$M$TAB" "$T/L" || fail 'a withdrawn ticket is viewed or told'
# GitHub auto's read: no line of a closed ticket
sh "$CHECKS/github.sh" round-read > "$T/out" 2>&1 || fail 'round-read failed'; ! grep -q "^issue${TAB}\($AC_N\|$M\)$TAB" "$T/out" && ! grep -q '^unread' "$T/out" || fail "GitHub auto's read holds a closed ticket"
exit 0
