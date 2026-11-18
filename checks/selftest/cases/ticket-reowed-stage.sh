#!/bin/sh
# Purpose: selftest case — a ticket of a closed stage closed outside ViD is written again (0.26.10.29.2 R4), checks/writer.sh through
# checks/round.sh on TW's toy and the fake gh. Stage 0 (the skeleton's) closed: its candidate, `stage-closed` line and close record
# planted. A correction ticket of S01 (a landing's row, as ticket-reowed.sh plants it) closed outside: after the round's next, its row
# is in a new S01 ticket. A fix ticket of S01, published by the round, closed outside: after the next, its rows are in a new fix
# ticket, the newest of its fix line, so the close waits on that one. Neither touches the stage's candidate, line or record; the
# step stays closed. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "ticket-reowed-stage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh; R=owner/code
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $1 failed ($RC)"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }
tw_skel || fail 'the skeleton round failed'; M=$(git --git-dir="$T/code.git" rev-parse main); mkdir -p .vid/decide; echo 90 >> .vid/decide/merged-prs; printf '90\t1\t%s\t%s\n' "$M" "$M" >> .vid/decide/merges
sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=29'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
# stage 0 closed: its candidate, line and record
tw_hand "stage-closed 0 | stand-in: RM at $(printf %.12s "$M") candidate 1"; mkdir -p .vid/decide/stage/0/1; printf '%s\n' "$M" > .vid/decide/stage/0/1/commit; : > .vid/decide/stage/0/1/named; : > .vid/decide/stage/0/1/done
rd next; rd step; snap() { { grep -E '^(candidate|stage-closed|closed) ' .vid/tw/handed; find .vid/decide/stage/0 -type f | sort | while IFS= read -r f; do echo "== $f"; cat "$f"; done; } > "$1"; }; snap "$T/before"   # each record's contents too
# a correction ticket of S01 holding a landed row, closed outside: its row goes out again
r1=$(sed -n '/^```vid-plan/,/^```$/p' .vid/RUN-STATE.md | awk -F' [|] ' '$1 == "step S01" { for (i = 2; i <= NF; i++) if ($i ~ /^rows: /) { sub(/^rows: /, "", $i); split($i, a, " "); print a[1] } }')
printf 'landed draft=L1 at=2026-11-10T12:00:00Z ids=%s\n' "$r1" >> .vid/tw/log; N5=$(gh issue create -R $R --title "t S01 fix" --body b --label ticket | sed 's/.*\///')
printf 'published %s kind=step step=S01 rows=%s at=2026-11-10T12:30:00Z\n' "$N5" "$r1" >> .vid/tw/log; printf -- '- stage: 0\n' > ".vid/tw/out/issue-$N5.md"
gh issue close "$N5" -R $R > /dev/null; rd step; ok "^closed-outside $N5 S01\$"; ok '^closed-stage-rows S01 0$'
rd next; N6=$(awk -v n="$N5" '$1 == "published" && $2 != n && / step=S01 / { print $2 }' .vid/tw/log | tail -n 1); [ -n "$N6" ] && [ "$N6" != 1 ] || fail "no new ticket of S01 after the next: $(cat "$T/out")"
awk -v n="$N6" '$1 == "published" && $2 == n' .vid/tw/log | grep -q "rows=$r1\( \|,\)" || fail "the new ticket of S01 does not hold $r1"
grep -q '^closed S01 ' .vid/tw/handed || fail 'the closed stage step was reopened'
# a fix ticket of S01, the stage closed, closed outside: its rows go out in a new fix ticket, the newest of its fix line
tw_hand 'fix ROW-004 | ROW-004: ROW-004 in chromium | close #9 of S01: req-9-p1c1-1'; rd next
F1=$(awk '$1 == "published" && / kind=fix / { print $2 }' .vid/tw/log | tail -n 1); [ -n "$F1" ] || fail "the fix ticket was not published: $(cat "$T/out")"; K=$(awk -v n="$F1" '$1 == "published" && $2 == n' .vid/tw/log | tr ' ' '\n' | sed -n 's/^fix=//p')
gh issue close "$F1" -R $R > /dev/null; rd step; ok "^closed-outside $F1 S01\$"; rd next
F2=$(awk -v k="fix=$K" '$1 == "published" { for (i = 3; i <= NF; i++) if ($i == k) n = $2 } END { print n }' .vid/tw/log); [ -n "$F2" ] && [ "$F2" != "$F1" ] || fail "no new fix ticket of the fix line after the next: $(cat "$T/out")"
awk -v n="$F2" '$1 == "published" && $2 == n' .vid/tw/log | grep -q 'rows=ROW-004 ' || fail 'the new fix ticket does not hold ROW-004'
snap "$T/after"; cmp -s "$T/before" "$T/after" || fail "the closed stage's candidate, line or record changed: $(diff "$T/before" "$T/after")"
exit 0
