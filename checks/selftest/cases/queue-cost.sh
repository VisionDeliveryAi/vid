#!/bin/sh
# Purpose: selftest case — a ticket's cost (v0.26.10.26.3, R2), `checks/queue.sh cost` on TW's toy from records made by hand. A step
# of two tickets: one accepted at its third head with one held row (a journey's transition) and rows held after its acceptance, at
# its head and a later one, left out, a row held before it at its head counted; its first decision by its rows as
# published (an amendment dropped one since) and by its head (another head's decision in the same second apart); its first decision 0 of 2; the other still open. A step C3 closed (7.1's line), timed by the passed stage-c3 event of the
# stage folder whose ask names its issue, not a failed one; a ticket accepted after that close. A step reopened since its close
# (no handed `closed` line) reads open; a ticket accepted with no accepted-at line reads unknown. `cost <step>` prints that step
# alone; the rounds line. And decide.sh writes accepted-at once a ticket (decide-rows). Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "queue-cost: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; QS=$CHECKS/queue.sh; D=.vid/decide; mkdir -p "$D/stage/1/1" "$D/stage/1/2" .vid/results
is() { grep -qxF -- "$1" "$T/out" || fail "no line: $1"; }
cat > .vid/tw/log <<'L'
published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 at=2026-11-09T08:00:00Z
published 2 kind=step step=S02 rows=ROW-001,ROW-005 at=2026-11-09T09:00:00Z
published 3 kind=step step=S03 rows=ROW-006 at=2026-11-09T09:00:00Z
published 5 kind=fix step=S02 rows=ROW-008 at=2026-11-09T10:00:00Z
published 6 kind=fix step=S03 rows=ROW-007 at=2026-11-09T10:20:00Z
amended 2 kind=step step=S02 rows=ROW-001 at=2026-11-09T10:40:00Z
published 7 kind=step step=S04 rows=ROW-002 at=2026-11-09T08:00:00Z
L
L() { printf '2026-11-09T%s:00Z\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" >> "$D/log"; }
h1=111111111111; h2=222222222222; h3=333333333333; h4=444444444444; h5=555555555555; h6=666666666666; h7=777777777777; h8=888888888888; h9=999999999999
L 08:30 20 $h8 ROW-003 accepted; L 08:30 20 $h8 ROW-004 accepted
L 09:30 30 $h1 ROW-001 failing; L 09:30 30 $h1 ROW-005-T1 accepted; L 09:30 30 $h1 ROW-005-T2 held
L 09:40 40 $h6 ROW-006 accepted
L 10:00 30 $h2 ROW-001 failing; L 10:00 30 $h2 ROW-005-T1 accepted; L 10:00 30 $h2 ROW-005-T2 accepted
L 10:30 31 $h5 ROW-008 failing; L 10:30 31 $h1 ROW-008 accepted; L 10:50 41 $h7 ROW-007 accepted; L 08:40 42 $h9 ROW-002 accepted
L 11:00 30 $h3 ROW-001 accepted; L 11:00 30 $h3 ROW-005-T1 accepted; L 11:00 30 $h3 ROW-005-T2 accepted
L 10:45 30 $h3 ROW-001 held; L 11:30 30 $h3 ROW-009 held; L 12:00 30 $h4 ROW-001 held
printf '20 1 %s at=2026-11-09T08:30:00Z\n30 2 %s at=2026-11-09T11:00:00Z\n40 3 %s at=2026-11-09T09:40:00Z\n41 6 %s at=2026-11-09T10:50:00Z\n' $h8 $h3 $h6 $h7 > "$D/accepted-at"
for x in "31 5 $h5" "42 7 $h9"; do set -- $x; printf 'ticket %s, pull request %s, head %s0000\n' "$2" "$1" "$3" > .vid/results/pr-$1-$3.txt; done
printf 'vid: decision %s0000\nticket: not yet\n' $h5 > "$D/pr-31-$h5.txt"; printf 'vid: decision %s0000\nticket: accepted\n' $h9 > "$D/pr-42-$h9.txt"
# S03 closed by C3 on issue 50 (stage 1's ask 2 names it); a failed C3 of ask 1 first. S01 closed at 08:50, then reopened (no line)
printf 'issue\t49\n' > "$D/stage/1/1/ask"; printf 'issue\t50\n' > "$D/stage/1/2/ask"; echo 'closed S03 | stand-in: C3 #50 at abcdef123456' >> .vid/tw/handed
cat >> .vid/metrics-events <<'L'
close-closed step=S01 issue=9 commit=x at=2026-11-09T08:50:00Z
stage-c3 stage=1 ask=1 result=failed at=2026-11-09T10:00:00Z
stage-c3 stage=1 ask=2 result=passed at=2026-11-09T10:10:00Z
close-closed step=S03 issue=8 commit=x at=2026-11-09T12:00:00Z
L
printf 'a\nb\nc\n' > "$D/accepted-log"
sh "$QS" cost > "$T/out" 2>&1 || fail 'cost failed'
is '  S01 #1 skeleton · published to accepted 0 h 30 m · heads 1 · accepted at the first decision 2 of 2 · held 0 · accepted to closed open'
is '  S02 #2 step · published to accepted 2 h 0 m · heads 3 · accepted at the first decision 0 of 2 · held 2 · accepted to closed open'
is '  S02 #5 fix · published to accepted not yet · heads 2 · accepted at the first decision 0 of 1 · held 0 · accepted to closed open'
is '  S03 #3 step · published to accepted 0 h 40 m · heads 1 · accepted at the first decision 1 of 1 · held 0 · accepted to closed 0 h 30 m'
is '  S03 #6 fix · published to accepted 0 h 30 m · heads 1 · accepted at the first decision 1 of 1 · held 0 · accepted to closed after the close'
is '  S04 #7 step · published to accepted unknown · heads 1 · accepted at the first decision 1 of 1 · held 0 · accepted to closed open'
is 'ViD · rounds 3'
awk '/^S0[0-9]$/ { print }' "$T/out" | paste -sd ' ' - | grep -qx 'S01 S02 S03 S04' || fail 'the tickets are not grouped under their steps'
sh "$QS" cost S03 > "$T/out" 2>&1; [ "$(grep -c '^  S' "$T/out")" = 2 ] && is 'S03' || fail 'cost S03 printed other steps'
# a C3 line naming no stage folder: closed, its time unknown
sed 's/C3 #50/C3 #51/' .vid/tw/handed > "$T/h" && cat "$T/h" > .vid/tw/handed; sh "$QS" cost S03 > "$T/out" 2>&1
is '  S03 #3 step · published to accepted 0 h 40 m · heads 1 · accepted at the first decision 1 of 1 · held 0 · accepted to closed unknown'
: > "$D/accepted-log"; sh "$QS" cost S03 > "$T/out" 2>&1; [ "$(grep -c '^ViD' "$T/out")" = 1 ] && [ "$(tail -n 1 "$T/out")" = 'ViD · rounds 0' ] || fail "no rounds: $(tail -n 2 "$T/out")"
exit 0
