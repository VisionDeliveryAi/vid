#!/bin/sh
# Purpose: selftest case — a ticket closed outside ViD (v0.26.10.27.3, STAGE-8-1B-SPEC.md R1), checks/round.sh and checks/github.sh on
# the toy and the fake gh. A published ticket whose issue reads CLOSED with no merge is withdrawn closed-outside once, its line and
# event; one merged with no decision (merged-prs, not merges), its issue closed, is not; nor one whose merge only GitHub's search
# finds; nor one still OPEN though missing from a read; an open pull request of a withdrawn ticket gets its one comment and no
# decision. The tickets are planted as the round publishes them (a `published` line, an issue labelled ticket). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "ticket-outside: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
tw_hand 'candidate 1'
# tk <step> <rows>: a ticket as the round publishes one; prints its number
tk() { n=$(gh issue create -R $R --title "t $1" --body b --label ticket | sed 's/.*\///'); printf 'published %s kind=step step=%s rows=%s at=2026-11-10T10:00:00Z\n' "$n" "$1" "$2" >> .vid/tw/log; echo "$n"; }
W=$T/w; git clone -q "$T/code.git" "$W" 2>/dev/null
br() { git -C "$W" checkout -q -B "$1" origin/main 2>/dev/null; git -C "$W" -c user.name=a -c user.email=a@b commit -q --allow-empty -m "$1"; git -C "$W" push -q -f origin "$1"; git -C "$W" rev-parse HEAD; }
pr() { gh pr create -R $R --head "$1" --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$2")" | sed 's/.*\///'; }
# a ticket closed on GitHub with no merge: withdrawn closed-outside, once, its line and event
A=$(tk S02 ROW-001); gh issue close "$A" -R $R > /dev/null; rd step; ok "^closed-outside $A S02\$"
grep -q "^withdrawn $A decision=closed-outside at=" .vid/tw/log || fail 'no withdrawn line'; grep -q "^ticket issue=$A state=closed-outside" .vid/metrics-events || fail 'no event'
rd step; no "^closed-outside $A"; [ "$(grep -c "^withdrawn $A " .vid/tw/log)" = 1 ] || fail 'withdrawn twice'
# merged with no decision (merged-prs alone), its issue then closed: not withdrawn
B=$(tk S03 ROW-007); HB=$(br tk-b); PB=$(pr tk-b "$B"); gh pr ready "$PB" -R $R; gh pr merge "$PB" -R $R --merge --match-head-commit "$HB" --body m > /dev/null
gh issue close "$B" -R $R > /dev/null; rd step; ok "^merged $PB, no decision"; no "^closed-outside $B"; ! grep -q "^withdrawn $B " .vid/tw/log || fail 'a merged ticket withdrawn'
grep -qx "$PB" .vid/decide/merged-prs && ! grep -q "	$B	" .vid/decide/merges 2>/dev/null || fail 'the merge not in merged-prs alone'
# a merge only GitHub's search finds (tw-outside called as the round calls it): recorded, not withdrawn
C=$(tk S04 ROW-002); HC=$(br tk-c); PC=$(pr tk-c "$C"); gh pr ready "$PC" -R $R; gh pr merge "$PC" -R $R --merge --match-head-commit "$HC" --body m > /dev/null; gh issue close "$C" -R $R > /dev/null
sh "$GS" tw-outside "$C" > "$T/out" 2>&1 || fail "tw-outside failed: $(cat "$T/out")"; ok "^merged $C $PC\$"; grep -q "^$C	$PC$" .vid/decide/merged-tickets || fail 'the search merge not recorded'; ! grep -q "^withdrawn $C " .vid/tw/log || fail 'a merged ticket withdrawn'
# missing from a read but OPEN: nothing withdrawn
E=$(tk S05 ROW-017); sh "$GS" tw-outside "$E" > "$T/out" 2>&1 || fail "tw-outside failed: $(cat "$T/out")"; [ ! -s "$T/out" ] || fail "an open ticket answered: $(cat "$T/out")"; ! grep -q "^withdrawn $E " .vid/tw/log || fail 'an open ticket withdrawn'
# an open pull request of a ticket closed outside: one comment, no decision
G=$(tk S06 ROW-006); HG=$(br tk-g); PG=$(pr tk-g "$G"); gh pr ready "$PG" -R $R; printf 'vid: decide %s\nby: MR\n' "$HG" > "$T/c"; gh pr comment "$PG" -R $R --body-file "$T/c" > /dev/null
gh issue close "$G" -R $R > /dev/null; rd step; ok "^closed-outside $G S06\$"; no "^decided $PG"
grep -rqx "vid: ticket #$G was closed outside ViD and is withdrawn; its rows come in a new ticket." "$T/gh/prs/$PG/comments" || fail 'no comment on its pull request'
k=$(ls "$T/gh/prs/$PG/comments" | grep -c .); rd step; no "^decided $PG"; [ "$(ls "$T/gh/prs/$PG/comments" | grep -c .)" = "$k" ] || fail 'commented twice'
VID_WAIT_MAX=3 VID_WAIT_TICK=1 sh "$CHECKS/round.sh" wait > "$T/out" 2>&1 || true; ok '^timeout$'   # its pull request's ask wakes nothing
exit 0
