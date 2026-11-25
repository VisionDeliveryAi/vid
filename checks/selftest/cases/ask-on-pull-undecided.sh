#!/bin/sh
# Purpose: selftest case — an ask on a step's own pull request that is not decided, or not put on record, in GitHub manual (FB-5 B1.5, B1.6), on the
# fake gh (fixtures/ask-pull.sh); one decided and recorded is case ask-on-pull's.
# C: accepted at a head and merged at another, merged off main, asked at an older head, open or merged at another with no decision, and accepted at the
#    head then decided at a commit of main: said at each call, nothing on record, nothing posted. An ask whose pull request is closed unmerged, or
#    whose ticket is withdrawn, leaves the record and is said no more.
# D: another open pull request of the ticket itself or of a piece, a draft too: said, nothing decided unasked; the owner's command decides; the
#    record at the merge waits for it too, and the owner's command with no commit makes it. A piece's pull request is one `context unit-ask` line and no reply. An ask on the ticket at the same head has a reply of its own.
# Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
B=$(mktemp -d); trap 'rm -rf "$B"' EXIT; TAB=$(printf '\t')
HOME=$B/home; export HOME; mkdir -p "$HOME"
fail() { echo "ask-on-pull-undecided: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# toy <name>: a project of its own, entered, with no new lock to take
toy() { T=$B/$1; mkdir -p "$T"; . "$CHECKS/selftest/fixtures/ask-pull.sh"; ac_project "$T/p" || fail "the toy $1 could not be made"; c0=$(ac_comments); }
body() { printf 'ticket: #%s\n\n%s' "$1" "${2:-Decisions: none}"; }
nstep() { ac_round step; [ "$RC" = 0 ] || fail "$1: the step exited $RC"; }
acc() { ac_round accept "$@"; [ "$RC" = 0 ] || fail "accept $* exited $RC"; }
merges() { cat .vid/decide/merges 2>/dev/null | grep -c "^step-$AC_N-" || true; }

# C
toy c; ap_pull own "$(body "$AC_N")"; P=$AP_P; H1=$AP_H; h1=$AP_h; ap_rep "$P" "$H1"; ac_grade "$H1"; ap_ask "$P" "$H1"; nstep 'c asked'; acc "$AC_N" "$H1"; grep -q "^decided #$AC_N $h1 ticket: accepted" "$T/out" || fail 'it was not accepted at its head'
ap_push own; H2=$AP_H; ap_squash "$P"; for k in 1 2; do nstep "c $k"; [ "$(grep -c "^undecided #$AC_N $h1 — .*$(printf %.12s "$H2")" "$T/out")" = 1 ] && [ "$(merges)" = 0 ] || fail "call $k: another head merged is not said, or is on record"; done
[ "$(ap_replies "$P")" = 1 ] && [ "$(ac_comments)" = "$c0" ] || fail 'another head merged posted'
# merged off main, on a second ticket
N2=$(gh_issue 'Step S03'); AC_N=$N2; { mn_ticket "$N2" S03 step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N2.md"; printf 'published %s kind=step step=S03 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$N2" >> .vid/tw/log
ap_pull off "$(body "$N2")"; P=$AP_P; H=$AP_H; h=$AP_h; ap_rep "$P" "$H"; ac_grade "$H"; ap_ask "$P" "$H"; nstep 'c off'; acc "$N2" "$H"; grep -q "^decided #$N2 $h ticket: accepted" "$T/out" || fail 'the second ticket was not accepted at its head'
echo "$AC_OFF" > "$FAKEGH/prs/$P/merge"; echo "$H" > "$FAKEGH/prs/$P/headoid"; echo MERGED > "$FAKEGH/prs/$P/state"
for k in 1 2; do nstep "c off $k"; [ "$(grep -c "^undecided #$N2 $h — .*main" "$T/out")" = 1 ] && [ "$(merges)" = 0 ] || fail "call $k: a merge off main is not said, or is on record"; done
# asked, then pushed: an older head, said at each call; asked again at the newest it is owed
N3=$(gh_issue 'Step S04'); AC_N=$N3; { mn_ticket "$N3" S04 step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$N3.md"; printf 'published %s kind=step step=S04 rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$N3" >> .vid/tw/log
ap_pull older "$(body "$N3")"; P=$AP_P; H1=$AP_H; h1=$AP_h; ap_rep "$P" "$H1"; ap_ask "$P" "$H1"; ap_push older; for k in 1 2; do nstep "c older $k"; [ "$(grep -c "^undecided #$N3 $h1 — " "$T/out")" = 1 ] && ! grep -q "^decide #$N3" "$T/out" || fail "call $k: an ask at an older head is not said, or is owed"; done
acc "$N3" "$H1"; grep -q "^undecided #$N3 $h1 — " "$T/out" && [ "$(ap_replies "$P")" = 0 ] || fail 'the owner'"'"'s command at an older head decided it'
ap_ask "$P" "$AP_H"; nstep 'c newest'; grep -qx "decide #$N3 $AP_H" "$T/out" && ! grep -q "^undecided #$N3" "$T/out" || fail 'asked again at the newest head it is not owed'

# never decided, and merged at another head (the older ask above's kind, merged): said at each call
tkt() { AC_N=$(gh_issue "Step $1"); { mn_ticket "$AC_N" "$1" step ROW-001 ROW-012; printf '\n## Engines\n\n- primary: alpha\n'; } > ".vid/tw/out/issue-$AC_N.md"; printf 'published %s kind=step step=%s rows=ROW-001,ROW-012 at=2026-11-18T09:00:00Z\n' "$AC_N" "$1" >> .vid/tw/log; }
tkt S05; ap_pull never "$(body "$AC_N")"; P=$AP_P; H1=$AP_H; h1=$AP_h; ap_ask "$P" "$H1"; ap_push never; H2=$AP_H; ap_squash "$P"
for k in 1 2; do nstep "c never $k"; [ "$(grep -c "^undecided #$AC_N $h1 — .* at an older head; it was merged at $(printf %.12s "$H2")" "$T/out")" = 1 ] && ! grep -q "^decide #$AC_N" "$T/out" && [ "$(merges)" = 0 ] || fail "call $k: an ask at an older head, merged at another, is not said"; done
[ "$(ap_replies "$P")" = 0 ] || fail 'it posted'
# accepted at the head, then decided at a commit of main, then merged
tkt S06; ap_pull since "$(body "$AC_N")"; P=$AP_P; H=$AP_H; h=$AP_h; ap_rep "$P" "$H"; ac_grade "$H"; ap_ask "$P" "$H"; nstep 'c since'; acc "$AC_N" "$H"; grep -q "^decided #$AC_N $h ticket: accepted" "$T/out" || fail 'it was not accepted at its head'
tk_dev 'a main commit'; X=$(git -C "$T/dev" rev-parse HEAD); ac_head "$X" 1 ROW-001=pass ROW-012=fail:no_page; ac_ask "$X"; acc "$AC_N" "$X"; grep -q "^decided #$AC_N $(printf %.12s "$X") ticket: not yet" "$T/out" || fail 'it was not decided not yet at the commit of main'
ap_squash "$P"; for k in 1 2; do nstep "c since $k"; [ "$(grep -c "^undecided #$AC_N $h — .*decided since at $(printf %.12s "$X")" "$T/out")" = 1 ] && [ "$(merges)" = 0 ] || fail "call $k: a later decision at main is not said, or it is on record"; done
# closed unmerged, and its ticket withdrawn: the line leaves the record, and nothing is said of it
tkt S07; ap_pull gone "$(body "$AC_N")"; P=$AP_P; ap_ask "$P" "$AP_H"; nstep 'c gone'; grep -q "^$P$TAB$AC_N$TAB" .vid/decide/pr-asks || fail 'the ask is not on record'
gh pr close "$P" -R owner/code; nstep 'c gone, closed'; ! grep -q "^$P$TAB" .vid/decide/pr-asks && ! grep -q "^\(decide\|undecided\) #$AC_N " "$T/out" || fail 'the ask of a pull request closed unmerged stands, or is said'
tkt S08; ap_pull drawn "$(body "$AC_N")"; P=$AP_P; ap_ask "$P" "$AP_H"; ap_merge "$P"; nstep 'c drawn'; grep -q "^$P$TAB$AC_N$TAB" .vid/decide/pr-asks || fail 'the merged ask is not on record'
printf 'withdrawn %s decision=owner at=2026-11-20T09:00:00Z\n' "$AC_N" >> .vid/tw/log; nstep 'c drawn, withdrawn'; ! grep -q "^$P$TAB" .vid/decide/pr-asks && ! grep -q "^\(decide\|undecided\) #$AC_N " "$T/out" || fail 'the ask of a withdrawn ticket stands, or is said'

# D
toy d; K=$(ap_child "$AC_N"); ap_pull own "$(body "$AC_N")"; P=$AP_P; H=$AP_H; h=$AP_h; ap_rep "$P" "$H"; ac_grade "$H"; ap_ask "$P" "$H"
ap_pull piece "$(body "$K")"; Q=$AP_P; qh=$AP_h; ap_ask "$Q" "$AP_H"; echo true > "$FAKEGH/prs/$Q/draft"
for k in 1 2; do nstep "d $k"; grep -q "^undecided #$AC_N $h — .*#$Q" "$T/out" && ! grep -q '^decide ' "$T/out" || fail "call $k: with a piece's draft open it is not said, or is decided unasked"
  if [ "$k" = 1 ]; then grep -q "^context unit-ask #$Q $K $qh" "$T/out"; else ! grep -q '^context unit-ask' "$T/out"; fi || fail "call $k: the piece's ask is not one line, once"; done
printf 'vid: decide %s\nby: A. Person\n' "$H" > "$T/ask"; gh issue comment "$AC_N" -R owner/code --body-file "$T/ask" > /dev/null   # the same head, on the ticket too
acc "$AC_N" "$H"; grep -q "^decided #$AC_N $h ticket: accepted" "$T/out" || fail 'the owner'"'"'s command did not decide it'
[ "$(ap_replies "$P")" = 1 ] && [ "$(ap_replies "$AC_N")" = 1 ] && [ "$(ap_replies "$Q")" = 0 ] && ac_last | grep -qx 'ticket: accepted' || fail 'each ask has not its one reply, or the piece has one'
ap_squash "$P"; nstep 'd merged'; [ "$(merges)" = 0 ] && grep -q "^undecided #$AC_N $h — .*#$Q" "$T/out" || fail 'accepted with another of its pull requests open, unasked'
# another that names the ticket itself, the piece's closed: the same
gh pr close "$Q" -R owner/code; ap_pull same "$(body "$AC_N")"; S=$AP_P; nstep 'd same'; [ "$(merges)" = 0 ] && grep -q "^undecided #$AC_N $h — .*#$S" "$T/out" || fail 'accepted with another pull request of the ticket itself open, unasked'
M=$AP_M; gh pr close "$S" -R owner/code; nstep 'd closed'; grep -q "^accepted #$AC_N $(printf %.12s "$M")" "$T/out" && [ "$(merges)" = 1 ] && [ "$(ap_replies "$Q")" = 0 ] || fail 'with it closed, the acceptance is not recorded'
# an ask with another of the ticket's own open: none is owed; merged with it open, the owner's command with no commit records it, posting nothing
tkt S09; ap_pull first "$(body "$AC_N")"; P=$AP_P; H=$AP_H; h=$AP_h; ap_rep "$P" "$H"; ac_grade "$H"; ap_ask "$P" "$H"; ap_pull second "$(body "$AC_N")"; S=$AP_P
nstep 'd two'; grep -q "^undecided #$AC_N $h — .*#$S" "$T/out" && ! grep -q "^decide #$AC_N" "$T/out" || fail 'with another pull request of the ticket itself open, it is decided unasked'
acc "$AC_N" "$H"; grep -q "^decided #$AC_N $h ticket: accepted" "$T/out" || fail 'the owner'"'"'s command did not decide it'; ap_squash "$P"; M=$AP_M; nstep 'd two merged'; [ "$(merges)" = 0 ] || fail 'it is on record unasked'
c0=$(ac_comments); S0=$(git ls-remote "$(mn_state)" | grep -v vid-state/lock | sort | git hash-object --stdin); acc "$AC_N"; grep -q "^accepted #$AC_N $(printf %.12s "$M"), the merge of pull request #$P" "$T/out" || fail 'the owner'"'"'s command with no commit did not record it'
[ "$(merges)" = 1 ] && [ "$(ac_comments)" = "$c0" ] && [ "$(ap_replies "$P")" = 1 ] || fail 'it is not on record once, or it posted'
S1=$(git ls-remote "$(mn_state)" | grep -v vid-state/lock | sort | git hash-object --stdin); [ "$S0" != "$S1" ] || fail 'the records were not saved'
echo 'ask-on-pull-undecided: ok'
