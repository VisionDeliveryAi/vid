#!/bin/sh
# Purpose: selftest case — a reached ticket and a fix ticket of an open stage, closed outside ViD, are written again (0.26.10.29.2 R4),
# checks/writer.sh through checks/round.sh on TW's toy and the fake gh. The skeleton merged, S01 not closed. A ruling reaches ROW-003:
# the round publishes its reached ticket; closed outside, the ruling is pending again, and after the next its row is in a new
# ticket that lists the ruling. A fix line of ROW-004, accepted on the fix ticket's pull request that never merged: the round
# publishes it; closed outside, after the next its row is in a new fix ticket, the newest of its fix line. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "ticket-reowed-fix: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1 failed ($RC)"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
tw_skel || fail 'the skeleton round failed'; M=$(git --git-dir="$T/code.git" rev-parse main); mkdir -p .vid/decide; echo 90 >> .vid/decide/merged-prs; printf '90\t1\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
grep -v '^closed S01 ' .vid/tw/handed > "$T/h"; cat "$T/h" > .vid/tw/handed; tw_hand 'candidate 1'
pub() { awk -v x="$1" '$1 == "published" && index($0, x) { n = $2 } END { print n }' .vid/tw/log; }
# owedc: close.sh owed with stage 0's candidate line set aside, so S01's own close is read (the close-wait Fail-ifs); mg <p> <n>: a merge planted
owedc() { cp .vid/tw/handed "$T/hs"; grep -v '^candidate 0 ' "$T/hs" > .vid/tw/handed; sh "$CHECKS/close.sh" owed > "$T/out" 2>&1; cat "$T/hs" > .vid/tw/handed; }
no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }; mg() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$M" "$M" >> .vid/decide/merges; echo "$1" >> .vid/decide/merged-prs; }
# a reached ticket, closed outside: the ruling pending again, then its row in a new ticket listing it
tw_hand 'reached ROW-003 REQ-001'; rd next; R1=$(pub ' kind=reached '); [ -n "$R1" ] || fail "the reached ticket was not published: $(cat "$T/out")"
gh issue close "$R1" -R $R > /dev/null; rd step; ok "^closed-outside $R1 S01\$"; owedc; no '^close S01$'   # not asked again without the ruling's work
sh "$CHECKS/writer.sh" pending > "$T/out" 2>&1; ok '^ROW-003 S01$'
rd next; R2=$(awk -v n="$R1" '$1 == "published" && $2 != n && (/ kind=reached .*rows=ROW-003[ ,]/ || / reached=([^ ]*,)?ROW-003[ ,]/) { m = $2 } END { print m }' .vid/tw/log)
[ -n "$R2" ] || fail "ROW-003 is in no new ticket after the next: $(cat "$T/out")"; sh "$CHECKS/writer.sh" pending > "$T/out" 2>&1; [ ! -s "$T/out" ] || fail "the ruling is still pending: $(cat "$T/out")"
owedc; no '^close S01$'; mg 91 "$R2"; owedc; ok '^close S01$'   # the close waits for the new reached ticket's merge, then is asked
# a fix ticket whose row was accepted on its pull request that never merged, closed outside: its row in a new fix ticket
tw_hand 'fix ROW-004 | ROW-004: ROW-004 in chromium | close #9 of S01: req-9-p1c1-1'; rd next; F1=$(pub ' kind=fix '); [ -n "$F1" ] || fail "the fix ticket was not published: $(cat "$T/out")"
K=$(awk -v n="$F1" '$1 == "published" && $2 == n' .vid/tw/log | tr ' ' '\n' | sed -n 's/^fix=//p')
# S01's close, done, red on the fix line: it waits for that line's ticket to merge
mkdir -p .vid/decide/close/S01/1; printf 'issue\t92\ncommit\t%s\nasked\t2026-11-10T11:00:00Z\n' "$M" > .vid/decide/close/S01/1/ask; : > .vid/decide/close/S01/1/done; printf '%s\tROW-004\n' "$K" > .vid/decide/close/S01/1/fixes
Wd=$T/w; git clone -q "$T/code.git" "$Wd" 2>/dev/null; git -C "$Wd" checkout -q -B fx origin/main 2>/dev/null; git -C "$Wd" -c user.name=a -c user.email=a@b commit -q --allow-empty -m fx; git -C "$Wd" push -q -f origin fx
gh pr create -R $R --head fx --base main --title t --body "$(printf 'ticket: #%s\n\nDecisions: none' "$F1")" > /dev/null; tw_hand 'row ROW-004 accepted'
gh issue close "$F1" -R $R > /dev/null; rd step; ok "^closed-outside $F1 S01\$"; rd next
F2=$(awk -v k="fix=$K" '$1 == "published" { for (i = 3; i <= NF; i++) if ($i == k) n = $2 } END { print n }' .vid/tw/log); [ -n "$F2" ] && [ "$F2" != "$F1" ] || fail "no new fix ticket of the fix line after the next: $(cat "$T/out")"
awk -v n="$F2" '$1 == "published" && $2 == n' .vid/tw/log | grep -q 'rows=ROW-004 ' || fail 'the new fix ticket does not hold ROW-004'
owedc; no '^close S01$'; mg 93 "$F2"; owedc; ok '^close S01$'   # it waits on the new fix ticket, never on the closed one
exit 0
