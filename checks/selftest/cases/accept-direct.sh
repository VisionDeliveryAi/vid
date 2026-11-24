#!/bin/sh
# Purpose: selftest case — the owner's direct call /vid:vid-accept-step <ticket> [<commit>] (GM-4 E13), through its one entry round.sh
# accept, inside the direct call's connect (connect.sh start and end: the lock taken and freed). On GitHub manual's toy and the fake gh
# (fixtures/accept.sh), with own work off and no team ask: with no results it is refused, `no results on main` (FB-3 A1.3), and nothing is
# posted; with results at two commits of main it decides at the newest and posts once, on the ticket, and not again unchanged; at a commit off main with no ask of the team's it is
# refused, `<c12> is not on main`; the team's ask at a commit never fetched, called by its 12 characters, is answered `not on main`;
# once accepted, a call at another commit with no ask posts nothing; the lock is freed after. With the team's unanswered ask at an
# older commit with a head report and a newer head report, a call naming no commit decides the newer (E13's default).
# In GitHub auto it decides the open pull request naming the ticket at its head, posted on the pull request once: a second call, no
# new ask, posts nothing. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/accept.sh"
fail() { echo "accept-direct: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ac_project "$T/p" || fail 'the toy could not be made'; sh "$CHECKS/github.sh" lock-free > /dev/null 2>&1 || fail 'the lock could not be freed'
[ "$(sh "$CHECKS/next.sh" own-work)" = off ] || fail 'own work is not off'
call() { sh "$CHECKS/connect.sh" start > "$T/cs" 2>&1 || { cp "$T/cs" "$T/out"; fail 'the connect did not start'; }; ac_round accept "$@"; cp "$T/out" "$T/acc"
  sh "$CHECKS/connect.sh" end > "$T/out" 2>&1 || fail 'the connect did not end'; cp "$T/acc" "$T/out"; [ -z "$(mn_lock)" ] || fail 'the lock is held after the direct call'; }
c0=$(ac_comments); call "$AC_N"; grep -qxF "refused #$AC_N no results on main; accepted outside ViD: /vid:vid-accept-step $AC_N <commit> accepted \"<your words>\"" "$T/out" || fail 'a call with no results was not refused so'
[ "$(ac_comments)" = "$c0" ] || fail 'a call with no results posted'
ac_red; ac_head "$AC_RED"; ac_head "$AC_C" 1 ROW-001=pass ROW-012=fail:no_page; call "$AC_N"; [ "$RC" = 0 ] || fail "accept exited $RC"
grep -q "^decided #$AC_N $(printf %s "$AC_C" | cut -c1-12) " "$T/out" || fail 'the call did not decide at the newest reported commit'
[ "$(ac_comments)" = $((c0 + 1)) ] && [ "$(ac_last | head -n 1)" = "vid: decision $AC_C" ] || fail 'the decision was not posted once, at the newest reported commit'
call "$AC_N" "$AC_C"; [ "$(ac_comments)" = $((c0 + 1)) ] || fail 'the same decision was posted again'
# a direct call at a commit off main with no ask of the team's: refused, nothing posted
call "$AC_N" "$AC_OFF"; grep -qx "refused #$AC_N $(printf %s "$AC_OFF" | cut -c1-12) is not on main" "$T/out" || fail 'a direct call off main was not refused so'
[ "$(ac_comments)" = $((c0 + 1)) ] || fail 'a direct call off main with no ask posted'
# the team's ask at a commit this machine has never fetched, called by the 12 characters the call's lines show: answered not on main
# (on a second ticket, so this ask, the oldest on it, never fixes the first ticket's first asked commit)
N2=$(gh_issue 'Step S03'); { mn_ticket "$N2" S03 step ROW-006; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N2.md"
printf 'published %s kind=step step=S03 rows=ROW-006 at=2026-11-18T09:00:00Z\n' "$N2" >> .vid/tw/log
Z=0123456789abcdef0123456789abcdef01234567; printf 'vid: decide %s\nby: MR\n' "$Z" > "$T/ask"; gh issue comment "$N2" -R owner/code --body-file "$T/ask" > /dev/null
call "$N2" "$(printf %s "$Z" | cut -c1-12)"; L2=$FAKEGH/issues/$N2/comments/$(ls "$FAKEGH/issues/$N2/comments" | sort -n | tail -n 1)
[ "$(ls "$FAKEGH/issues/$N2/comments" | grep -c .)" = 2 ] && grep -qx "not on main — $Z" "$L2" || { cp "$L2" "$T/out"; fail 'the ask at an unknown commit, called by its 12 characters, was not answered not on main'; }
# accepted at AC_C (a second attempt passing, ViD's review made); a direct call at another commit with no ask then posts nothing
ac_head "$AC_C" 2; ac_grade "$AC_C"; call "$AC_N" "$AC_C"; grep -q "^accepted #$AC_N " "$T/out" || fail 'the ticket was not accepted at AC_C'; c1=$(ac_comments)
call "$AC_N" "$AC_RED"; grep -q "^accepted #$AC_N at $(printf %s "$AC_C" | cut -c1-12); its close runs there" "$T/out" && [ "$(ac_comments)" = "$c1" ] || fail 'a direct call on an accepted ticket with no ask posted'
# E13's default against an older unanswered ask: on a third ticket, the team's ask at $AC_RED (a head report there) and a newer head
# report at $AC_C, no commit given: the newest commit of main with a head report is decided, not the older ask
A0=$AC_N; N3=$(gh_issue 'Step S04'); AC_N=$N3; { mn_ticket "$N3" S04 step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N3.md"
printf 'published %s kind=step step=S04 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$N3" >> .vid/tw/log
ac_red; ac_head "$AC_RED"; ac_ask "$AC_RED"; ac_head "$AC_C" 1 ROW-001=fail:no_digest ROW-012=pass; c3=$(ac_comments); call "$N3"; [ "$RC" = 0 ] || fail "accept on the third ticket exited $RC"
grep -q "^decided #$N3 $(printf %s "$AC_C" | cut -c1-12) " "$T/out" || fail "with an older unanswered ask and a newer head report, no commit given, the newer was not decided: $(head -n 1 "$T/out")"
[ "$(ac_comments)" = $((c3 + 1)) ] && [ "$(ac_last | head -n 1)" = "vid: decision $AC_C" ] || fail 'the decision at the newest reported commit was not posted once on the third ticket'
AC_N=$A0
# GitHub auto: the pull request's head
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-20T09:00:00Z\n' >> .vid/plan/setup
sh "$CHECKS/github.sh" lock-take ac > /dev/null 2>&1 || fail 'no lock in auto'
( cd "$T/dev" && git checkout -q -B "ticket-$AC_N" main && g commit -q --allow-empty -m 'the pull request' && git push -q -f origin "ticket-$AC_N" 2>/dev/null && git checkout -q main ); H=$(git -C "$T/dev" rev-parse "ticket-$AC_N"); h=$(printf %s "$H" | cut -c1-12)
P=$(gh pr create -R owner/code --head "ticket-$AC_N" --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$AC_N")" | sed 's#.*/##')
_i=pr-$P-$h-1; rr_put "$_i" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha' "$H")"; rr_put "$_i" cases-alpha.xml "$(rr_cases ROW-001=pass ROW-012=pass)"; ac_send "$_i"
_i=grade-pr-$P-$h-1; rr_put "$_i" grade.txt "$(printf 'by: GR\ncommit: %s\nROW-001 kept — seen\nROW-012 kept — seen' "$H")"; ac_send "$_i"
ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "accept in GitHub auto exited $RC"; grep -q "^decided $P $h " "$T/out" || fail "in GitHub auto the call did not decide the pull request's head"
head -n 1 "$FAKEGH/prs/$P/comments/$(ls "$FAKEGH/prs/$P/comments" | sort -n | tail -n 1)" | grep -qx "vid: decision $H" || fail 'the decision in GitHub auto is not on the pull request'
ac_round accept "$AC_N"; [ "$RC" = 0 ] || fail "the second call in GitHub auto exited $RC"; [ "$(ls "$FAKEGH/prs/$P/comments" | grep -c .)" = 1 ] || fail 'in GitHub auto a second direct call posted the unchanged decision again'
exit 0
