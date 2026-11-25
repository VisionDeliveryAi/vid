#!/bin/sh
# Purpose: selftest case — an ask on a step's own pull request in GitHub manual (FB-5 B1.4 to B1.6), on the fake gh (fixtures/ask-pull.sh).
# A: an ask with no report at the head is refused and posts nothing; with a row failing, `not yet` once on that pull request and nothing on
#    the ticket; ViD's review at the head takes that pull request as the ticket's; its request goes on the ticket too, once; the description's Decisions section is read;
#    accepted there, nothing is on record; other work merged, then the pull request by squash: the next call records the acceptance at its merge,
#    the head and the merge's commit, posting nothing; the step's close asks the head's accepted cases.
# B: asked and merged by a merge commit before any call, closing the issue: owed, not told as closed early; with the label on the closed
#    issue, not yet; asked again without it, accepted and recorded in the same act, once. An older merged one, and an ask on it, is left alone. A head of no report at its merge is refused.
# An accepted ticket's ask is answered there. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
B=$(mktemp -d); trap 'rm -rf "$B"' EXIT; TAB=$(printf '\t')
HOME=$B/home; export HOME; mkdir -p "$HOME"
fail() { echo "ask-on-pull: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# toy <name>: a project of its own, entered, with no new lock to take
toy() { T=$B/$1; mkdir -p "$T"; . "$CHECKS/selftest/fixtures/ask-pull.sh"; ac_project "$T/p" || fail "the toy $1 could not be made"; c0=$(ac_comments); }
body() { printf 'ticket: #%s\n\n%s' "$1" "${2:-Decisions: none}"; }
nstep() { ac_round step; [ "$RC" = 0 ] || fail "$1: the step exited $RC"; }
acc() { ac_round accept "$@"; [ "$RC" = 0 ] || fail "accept $* exited $RC"; }
merges() { cat .vid/decide/merges 2>/dev/null | grep -c "^step-$AC_N-" || true; }

# A
toy a; ap_pull own "$(body "$AC_N" 'No section.')"; P=$AP_P; H=$AP_H; h=$AP_h; ap_ask "$P" "$(printf %.10s "$H")"
nstep 'a first'; grep -qx "decide #$AC_N $H" "$T/out" && ! grep -q '^context unit-ask' "$T/out" || fail 'the ask on the own pull request is not owed'
grep -qx "$P${TAB}$AC_N${TAB}$H" .vid/decide/pr-asks || fail 'the ask is not on record'
sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'; grep -qx "context${TAB}ask${TAB}#$AC_N${TAB}$h${TAB}/vid:vid-accept-step $AC_N $h" "$T/L" || { cp "$T/L" "$T/out"; fail 'the call does not list it'; }
# asked on the ticket too, at another commit: the call lists each with its own; that comment then taken away
ac_ask "$AC_C"; ac_round read; sh "$CHECKS/next.sh" triggers > "$T/L" 2> "$T/out" || fail 'next.sh triggers failed'
for x in "$(printf %.12s "$AC_C")" "$h"; do [ "$(grep -c "^context${TAB}ask${TAB}#$AC_N${TAB}$x${TAB}/vid:vid-accept-step $AC_N $x\$" "$T/L")" = 1 ] || { grep '^context' "$T/L" > "$T/out"; fail "the call does not list the ask at $x once"; }; done
rm "$FAKEGH/issues/$AC_N/comments/$(ls "$FAKEGH/issues/$AC_N/comments" | sort -n | tail -n 1)"
acc "$AC_N" "$H"; grep -qx "refused #$AC_N no results at $h, the head of pull request #$P" "$T/out" && [ "$(ap_replies "$P")" = 0 ] && [ "$(ac_comments)" = "$c0" ] || fail 'with no report at the head it was not refused, or it posted'
ap_rep "$P" "$H" 1 ROW-001=pass ROW-012=fail:no_page; acc "$AC_N" "$h"; grep -q "^decided #$AC_N $h ticket: not yet" "$T/out" || fail 'with a row failing it was not decided not yet'
[ "$(ap_replies "$P")" = 1 ] && [ "$(ap_lastp "$P" | head -n 1)" = "vid: decision $H" ] && [ "$(ac_comments)" = "$c0" ] || fail 'the reply is not once, on that pull request alone'
ap_lastp "$P" | grep -qx "no Decisions section — #$P" || fail 'the description of the pull request asked on was not read for its Decisions section'
nstep 'a answered'; ! grep -q '^decide ' "$T/out" || fail 'the answered ask is still owed'
printf 'ticket: #%s\n\nDecisions: none\n' "$AC_N" > "$FAKEGH/prs/$P/body"; ap_rep "$P" "$H" 2 ROW-001=pass ROW-001_more=pass ROW-012=pass; ap_ask "$P" "$H"
# ViD's review of the ticket, at the head: that pull request is the ticket's
acc "$AC_N" "$H"; grep -qx "review #$AC_N $h" "$T/out" && [ "$(ap_replies "$P")" = 1 ] || fail 'the review was not asked before the decision'
CLAUDE_PLUGIN_ROOT=$(cd "$CHECKS/.." && pwd); export CLAUDE_PLUGIN_ROOT
if [ -f "$CLAUDE_PLUGIN_ROOT/skills/vid-accept-step/passes/review.md" ]; then sh "$CHECKS/review.sh" prepare "step-$AC_N" "$h" > "$T/out" 2>&1 && grep -q '^brief ' "$T/out" && cut -f1,2 ".vid/round/review/step-$AC_N-$h/prs" | grep -qx "$P$TAB$AC_N" || fail 'the review at the head does not read that pull request'; fi
ac_grade "$H" 'ROW-001 breached test — nothing checks the empty list' 'ROW-012 kept — seen'; ac_sort "$H" 'ROW-001 test it — a test of the empty list — ROW-001 breached test — nothing checks the empty list'
acc "$AC_N" "$H"; [ "$(ap_replies "$P")" = 2 ] && ap_lastp "$P" | grep -q '^request ROW-001 — a test of the empty list' || fail 'the request is not in the decision there'
[ "$(ac_comments)" = $((c0 + 1)) ] && [ "$(ap_replies "$AC_N")" = 0 ] && [ "$(ac_last | grep -c .)" = 1 ] && ac_last | grep -q '^request ROW-001 — a test of the empty list' || fail 'the request is not once on the ticket, alone'
ap_ask "$P" "$H"; acc "$AC_N" "$H"; grep -q "^decided #$AC_N $h ticket: accepted" "$T/out" && [ "$(ap_replies "$P")" = 3 ] && [ "$(ac_comments)" = $((c0 + 1)) ] || fail 'it was not accepted on that pull request'
! grep -q '^accepted ' "$T/out" && [ "$(merges)" = 0 ] && ! grep -q "^row ROW-001 accepted" .vid/tw/handed 2>/dev/null && ! grep -q " $AC_N " .vid/decide/accepted-at || fail 'an acceptance is on record before the merge'
nstep 'a waits'; [ "$(merges)" = 0 ] || fail 'a call recorded it before the merge'
tk_dev 'other work'; ap_squash "$P"; M=$AP_M; nstep 'a merged'; grep -q "^accepted #$AC_N $(printf %.12s "$M")" "$T/out" || fail 'the acceptance is not recorded at its merge'
grep -qx "step-$AC_N-$h$TAB$AC_N$TAB$H$TAB$M" .vid/decide/merges && grep -q '^row ROW-001 accepted' .vid/tw/handed && grep -q "^step-$AC_N $AC_N $h at=" .vid/decide/accepted-at || { cat .vid/decide/merges .vid/tw/handed > "$T/out"; fail 'the record does not hold the head and the merge'; }
[ "$(ap_replies "$P")" = 3 ] && [ "$(ac_comments)" = $((c0 + 1)) ] || fail 'the record posted'; nstep 'a after'; [ "$(merges)" = 1 ] && ! grep -q '^accepted \|^decide \|^undecided ' "$T/out" || fail 'it was recorded twice, or still said'
[ ! -s .vid/decide/pr-asks ] || { cp .vid/decide/pr-asks "$T/out"; fail 'an ask whose ticket is accepted still stands'; }
# the close asks the accepted head's cases, though that head is no ancestor of the squash
mkdir -p .vid/decide/close/S02/1; printf 'issue\t900\ncommit\t%s\nasked\t2026-11-19T09:00:00Z\nchunk\tp1c1\talpha\tROW-001\n' "$M" > .vid/decide/close/S02/1/ask
ap_rep "$P" "$H" 3 ROW-001=pass ROW-001_more=pass ROW-012=pass; rr_put "pr-$P-$h-3" cases-alpha.xml "$(rr_cases ROW-001=pass ROW-001_more=pass ROW-012=pass)"; ac_send "pr-$P-$h-3"
rr_put req-900-p1c1-1 results.txt "$(printf 'by: A. Person\ncommit: %s' "$M")"; rr_put req-900-p1c1-1 all.xml "$(rr_cases ROW-001=pass)"; ac_send req-900-p1c1-1; sh "$CHECKS/github.sh" results-fetch > "$T/out" 2>&1 || fail 'results-fetch failed'
sh "$CHECKS/results.sh" close --step S02 > "$T/out" 2>&1 || fail 'the close could not be read'; grep -q "^row${TAB}p1c1${TAB}alpha${TAB}ROW-001${TAB}not run" "$T/out" || fail 'the close asks fewer of the accepted row after a squash'
rm -rf .vid/decide/close   # made up: its ask is no issue of the fake's, and a step goes on to act on it
# an accepted ticket's ask, on another own pull request: answered there, nothing decided again
ap_pull later "$(body "$AC_N")"; ap_ask "$AP_P" "$AP_H"; nstep 'a later'; grep -qx "decide #$AC_N $AP_H" "$T/out" || fail 'an accepted ticket'"'"'s ask on its pull request is not owed an answer'
acc "$AC_N" "$AP_H"; [ "$(ap_replies "$AP_P")" = 1 ] && ap_lastp "$AP_P" | grep -q "^ticket: accepted at $(printf %.12s "$M")" && [ "$(merges)" = 1 ] || fail 'it was not answered there as accepted'
nstep 'a later, answered'; ! grep -q '^decide ' "$T/out" && [ ! -s .vid/decide/pr-asks ] || fail 'the answered ask still stands'

# B
toy b; ap_pull old "$(body "$AC_N")"; OP=$AP_P; OH=$AP_H; ap_merge "$OP"; nstep 'b old'; grep -q "^unit-merged $OP $AC_N" "$T/out" || fail 'the older merge is not recorded'
ap_rep "$OP" "$OH"; ap_ask "$OP" "$OH"; nstep 'b old asked'; ! grep -q '^decide \|^undecided ' "$T/out" && [ ! -s .vid/decide/pr-asks ] || fail 'an older merged pull request'"'"'s ask was read'
acc "$AC_N" "$OH"; grep -q "^refused #$AC_N .* is not on main" "$T/out" && [ "$(ap_replies "$OP")" = 0 ] || fail 'an older merged one was decided'
ap_pull own "$(printf 'ticket: #%s\n\nCloses #%s\n\nDecisions: none' "$AC_N" "$AC_N")"; P=$AP_P; H=$AP_H; h=$AP_h; ap_rep "$P" "$H"; ac_grade "$H"; ap_ask "$P" "$H"; ap_merge "$P"; M=$AP_M
[ "$(cat "$FAKEGH/issues/$AC_N/state")" = CLOSED ] || fail 'the toy did not close the issue'; echo team:blocked > "$FAKEGH/issues/$AC_N/labels"
nstep 'b merged'; grep -qx "decide #$AC_N $H" "$T/out" || fail 'an ask merged before the call is not owed'; ! grep -q "^closed #$AC_N" "$T/out" || fail 'a ticket whose ask stands is told as closed early'
acc "$AC_N" "$H"; grep -q "^decided #$AC_N $h ticket: not yet" "$T/out" && ap_lastp "$P" | grep -qx 'ROW-001 question open' && [ "$(merges)" = 0 ] || fail 'a closed ticket under the label was accepted'
rm "$FAKEGH/issues/$AC_N/labels"; ap_ask "$P" "$H"; nstep 'b again'; grep -qx "decide #$AC_N $H" "$T/out" || fail 'asked again on the merged pull request, it is not owed'
acc "$AC_N" "$H"; grep -q "^decided #$AC_N $h ticket: accepted" "$T/out" && grep -q "^accepted #$AC_N $(printf %.12s "$M")" "$T/out" || fail 'it was not accepted and recorded in the same act'
grep -qx "step-$AC_N-$h$TAB$AC_N$TAB$H$TAB$M" .vid/decide/merges && [ "$(ap_replies "$P")" = 2 ] && [ "$(ac_comments)" = "$c0" ] || fail 'the record is not at the merge commit, or a reply is elsewhere'
nstep 'b after'; [ "$(merges)" = 1 ] && ! grep -q "^decide \|^accepted \|^closed #" "$T/out" || fail 'it was said or recorded again'
echo 'ask-on-pull: ok'
