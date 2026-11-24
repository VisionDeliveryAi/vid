#!/bin/sh
# Purpose: selftest case — a decision beside a bad report branch (FB-3 A2), on GitHub manual's toy and the fake gh (fixtures/accept.sh):
# another ticket's report branch made from the code, with no folder of its own, stops nothing, and the ticket is accepted with no word
# of it. A ticket whose only report at the commit is such a branch is refused, with one `report left out — vid-results/<id>: <why>` line
# after it, nothing posted and nothing counted. A decision that reads `not yet` names each left-out branch of the ticket, of a
# sub-issue of it and of its pull request, by the number in its id, and no other's; one that reads `accepted` names none. In GitHub
# auto a left-out `red-<ticket>-…` and `pr-<p>-…` are named in the pull request's `not yet`, another ticket's not. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "accept-skipped-report: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'
# bad <id>: a branch of that report's name holding the code and no folder of its own
bad() { ( cd "$T/dev" && git checkout -q -B "bad-$1" main && echo code > app.py && git add app.py && g commit -q -m "$1" && git push -q -f "$T/code.git" "HEAD:refs/heads/vid-results/$1" && git checkout -q -f main ); }
bad red-99-1; ac_good "$AC_C"; c12=$(printf %s "$AC_C" | cut -c1-12)
# its own only report at another commit of main is bad: refused, the line said, nothing posted, nothing counted
tk_dev 'a later commit'; L=$(git -C "$T/dev" rev-parse HEAD); l12=$(printf %s "$L" | cut -c1-12); bad "step-$AC_N-$l12-1"; c0=$(ac_comments)
ac_round accept "$AC_N" "$L"; grep -q "^refused #$AC_N no .* at $l12" "$T/out" && grep -qx "report left out — vid-results/step-$AC_N-$l12-1: it has no folder step-$AC_N-$l12-1" "$T/out" || fail "a ticket whose report is left out: exit $RC"
! grep -q 'red-99-1' "$T/out" && [ "$(ac_comments)" = "$c0" ] && [ ! -s .vid/decide/counts ] || fail 'a left-out report posted, counted, or named another ticket'"'"'s'
# another ticket's bad branch, and its own at another commit: accepted, no line of either
ac_round accept "$AC_N" "$AC_C"; [ "$RC" = 0 ] && grep -q "^accepted #$AC_N $c12" "$T/out" || fail "with another ticket's bad branch the ticket was not accepted: exit $RC"
ac_last > "$T/out"; ! grep -q 'left out' "$T/out" || fail 'an accepted decision names a left-out branch'
# a second ticket with a failing row: its not yet names its own, its sub-issue's and its pull request's left-out branches, no other's
N2=$(gh_issue 'Step S03'); AC_N=$N2; { mn_ticket "$N2" S03 step ROW-006; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N2.md"
printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\n' "$N2" >> .vid/tw/log; K=$(gh_issue 'a part of it'); echo "$N2" > "$FAKEGH/issues/$K/parent"
ac_unit part "$(printf 'ticket: #%s\n\nDecisions: none' "$K")"; m12=$(printf %s "$AC_M" | cut -c1-12); ac_head "$AC_M" 1 ROW-006=fail:no\ list
bad "red-$N2-1"; bad "red-$K-1"; bad "pr-$AC_P-aaaaaaaaaaaa-1"
ac_round accept "$N2" "$AC_M"; [ "$RC" = 0 ] && grep -q "^decided #$N2 $m12 ticket: not yet" "$T/out" || fail "the second ticket: exit $RC"
ac_last > "$T/out"; for i in "red-$N2-1" "red-$K-1" "pr-$AC_P-aaaaaaaaaaaa-1"; do [ "$(grep -cx "report left out — vid-results/$i: it has no folder $i" "$T/out")" = 1 ] || fail "the not yet does not name $i once"; done
[ "$(grep -c '^report left out' "$T/out")" = 3 ] || fail "the not yet names another ticket's branch"
# GitHub auto: the same for the ticket's red and its pull request's own
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
( cd "$T/dev" && git checkout -q -B "ticket-$N2" main && g commit -q --allow-empty -m 'the pull request' && git push -q -f origin "ticket-$N2" 2>/dev/null && git checkout -q main ); H=$(git -C "$T/dev" rev-parse "ticket-$N2"); h=$(printf %s "$H" | cut -c1-12)
P=$(gh pr create -R owner/code --head "ticket-$N2" --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$N2")" | sed 's#.*/##'); bad "pr-$P-$h-1"
ac_round accept "$N2"; [ "$RC" = 0 ] && grep -q "^decided $P $h ticket: not yet" "$T/out" || fail "in GitHub auto: exit $RC"
cat "$FAKEGH/prs/$P/comments/$(ls "$FAKEGH/prs/$P/comments" | sort -n | tail -n 1)" > "$T/out"
for i in "red-$N2-1" "pr-$P-$h-1"; do grep -qx "report left out — vid-results/$i: it has no folder $i" "$T/out" || fail "in GitHub auto the not yet does not name $i"; done
[ "$(grep -c '^report left out' "$T/out")" = 2 ] || fail "in GitHub auto the not yet names another's branch"
exit 0
