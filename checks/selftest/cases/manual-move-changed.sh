#!/bin/sh
# Purpose: selftest case — a named move checked against the listing first, and again before each later move (GM-2 T10; its
# case manual-move-changed). On the form fixture's toy (fixtures/form.sh) in GitHub manual (open-tickets: 2), each call made as
# /vid next makes it after its read (next.sh read, then next-move.sh call), under this session's lock. After the listing,
# ROW-018 moves from S04 into S03 by a recorded plan change; then `publish S03 "<words>" -- publish S01 "<words>"`: S03,
# whose tests changed since the listing, is shown again with its move line and not done; S01, the next named, is done. Then
# `publish S02 "<words>" -- publish S03 "<words>"`: S02 is done, its ticket added to the call's read, so before S03 the
# check against the records counts it, and S03, past the limit now, is shown again with its limit warning, not done. Named
# once more at the next call, as shown, S03 goes out. No move goes out that was not named. A team addition
# first raised at a call that publishes S04 is still a shown trigger in the lines after the moves; a `done` of S05's publish,
# its move changed since the listing, and a `decline` by kind reaching a subject the listing never showed, are each shown
# again and not done. Named again as just shown, both go through (the to-do logged done, the two subjects
# declined); a done of a critical trigger's to-do (reset-taken, its row reset again since the listing) is shown again, not logged
# done; and a decline after a publish that brings a new subject into its trigger (added-active, stage 2 made active) is shown
# again, nothing declined. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "manual-move-changed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
CLAUDE_CODE_SESSION_ID=move-changed-case; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
# the page in the viewer's folder under a home of the case's own; a ticket the call posts made now on the fake, as GitHub makes it
HOME=$T/home; export HOME; mkdir -p "$HOME"
made() { for n in $(awk '$1 == "published" { print $2 }' .vid/tw/log 2>/dev/null); do [ -f "$FAKEGH/issues/$n/created" ] || gh_attr "$n" created "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; done; }
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; made; }
steps() { awk '$1 == "published" { for (i = 3; i <= NF; i++) if ($i ~ /^step=/) print substr($i, 6) }' .vid/tw/log | paste -sd ' ' -; }
call; [ "$RC" = 0 ] || fail "the call with no move exited $RC"
# S03's tests change after the listing
pt_rs 's/^\(step S03 .*HOS-005\)\( | lane\)/\1 ROW-018\2/; s/^\(step S04 .*ROW-011\) ROW-018/\1/; s/^needs ROW-002 ROW-009 ROW-011 ROW-018 /needs ROW-002 ROW-009 ROW-011 /; s/^\(needs ROW-006 .*HOS-005\) |/\1 ROW-018 |/'
sh "$CHECKS/plan.sh" change other 'ROW-018 moves to S03' --trigger initial --expect 'S03 holds ROW-018' > "$T/out" 2>&1 || fail 'the row move was not recorded'
tw_ratify 'Yes, publish it' || fail 'the plan was not ratified again'
call publish S03 'Yes, publish S03' -- publish S01 'Yes, publish the skeleton'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^again publish S03' "$T/out" || fail 'S03, its tests changed since the listing, is not shown again'
grep -q "^move${TB}publish${TB}S03${TB}.*ROW-018" "$T/out" || fail "S03's move is not shown again with its tests now"
grep -q '^done publish S01' "$T/out" || fail 'S01, named after S03, was not done'
[ "$(steps)" = S01 ] || fail "the tickets published are '$(steps)', not S01 alone"
# two publishes in one call: the second counts the first's ticket against the limit
call publish S02 'Yes, publish S02' -- publish S03 'Yes, publish S03'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^done publish S02' "$T/out" || fail 'S02 was not done'
grep -q '^again publish S03' "$T/out" || fail 'S03, past the limit once S02 is out, is not shown again'
grep -q "^warning${TB}publish${TB}S03${TB}limit${TB}2 open tickets, 3 with this one" "$T/out" || fail "S03 is not shown again with its limit warning counting S02's ticket"
[ "$(steps)" = 'S01 S02' ] || fail "the tickets published are '$(steps)', not S01 and S02"
# named again as shown, it goes out
call publish S03 'Yes, publish S03 past the limit'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^done publish S03' "$T/out" || fail 'S03, named again as last shown, was not done'
[ "$(steps)" = 'S01 S02 S03' ] || fail "the tickets published are '$(steps)', not S01, S02 and S03"
# a trigger first raised at a call that names a move is still shown in the lines after the moves,
# the lines the page is written from: the team adds ROW-017 to S01's issue, and the call publishes S04
N1=$(awk '$1 == "published" { for (i = 3; i <= NF; i++) if ($i == "step=S01") print $2 }' .vid/tw/log)
fm_team_edit "$N1" 's/^The toy team.s own checklist line\.$/&\
- ROW-017/'
call publish S04 'Yes, publish S04'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^done publish S04' "$T/out" || fail 'S04 was not done'
sed -n '/^after the moves:$/,$p' "$T/out" | grep -q "^trigger${TB}important${TB}team-added${TB}#$N1 ROW-017${TB}" || fail "the team's addition, first raised at this call, is not shown in the lines after the moves"
# done and decline are checked against the listing too. S01's ticket turns 8 days old untaken, so
# S05's publish gains a not-taken warning; the team adds ROW-019 too, a subject of team-added the listing never showed
gh_attr "$N1" created "$(date -u -v-8d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '8 days ago' '+%Y-%m-%dT%H:%M:%SZ')"
fm_team_edit "$N1" 's/^- ROW-017$/&\
- ROW-019/'
call done 'publish S05' 'Not this month' -- decline team-added 'We take neither'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^again done publish S05' "$T/out" || fail "done of S05's publish, its move changed since the listing, is not shown again"
awk -F'\t' '$2 == "done" && $3 == "publish S05" { f = 1 } END { exit !f }' .vid/next/todo 2>/dev/null && fail "S05's to-do was logged done though its move changed since the listing"
grep -q '^again decline team-added' "$T/out" || fail 'a decline reaching a subject the listing never showed is not shown again'
[ ! -s .vid/next/declined ] || { cp .vid/next/declined "$T/out"; fail 'a decline reaching a subject the listing never showed was recorded'; }
# named again as just shown, both go through: the to-do logged done, the two subjects declined
call done 'publish S05' 'Not this month' -- decline team-added 'We take neither'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^done done publish S05' "$T/out" && awk -F'\t' '$2 == "done" && $3 == "publish S05" && $5 == "words" { f = 1 } END { exit !f }' .vid/next/todo || fail "done of S05's publish, as just shown, was not logged done"
grep -q '^done decline team-added' "$T/out" || fail 'the decline, as just shown, was not done'
for r in ROW-017 ROW-019; do grep -q "^team-added${TB}#$N1 $r${TB}" .vid/next/declined || { cp .vid/next/declined "$T/out" 2>/dev/null || :; fail "the decline recorded no line for #$N1 $r"; }; done
# done of a critical trigger's to-do, its evidence changed since the listing: the team takes S02's
# ticket, ROW-001 (its test) is reset, the listing shows reset-taken ROW-001; ROW-001 is then reset again
N2=$(awk '$1 == "published" { for (i = 3; i <= NF; i++) if ($i == "step=S02") print $2 }' .vid/tw/log)
gh_attr "$N2" assignees 'the-team-lead'
inv() { awk -v id="$1" -v e="$2" 'index($0, id " | ") == 1 { sub(/ Fails if/, e " Fails if") } { print }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; }
inv ROW-001 ' Reset once.'
call; [ "$RC" = 0 ] || fail "the call exited $RC"
sh "$CHECKS/next.sh" triggers > "$T/lines" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^trigger${TB}critical${TB}reset-taken${TB}ROW-001${TB}" "$T/lines" || { grep '^trigger\|^quiet' "$T/lines" > "$T/out"; fail 'the listing does not show reset-taken ROW-001'; }
inv ROW-001 ' Reset twice.'
call done 'reset-taken ROW-001' 'Handled with the team'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^again done reset-taken ROW-001' "$T/out" || fail "done of reset-taken ROW-001, its evidence changed since the listing, is not shown again"
! awk -F'\t' '$2 == "done" && $3 == "reset-taken ROW-001" { f = 1 } END { exit !f }' .vid/next/todo || fail "reset-taken ROW-001's to-do was logged done on evidence the listing did not show"
# a decline after a move that brings a new subject into its trigger. Two tests are added after the
# applied commit: ROW-801 of stage 1 (active: added-active) and ROW-802 of stage 2 (inactive: counted minor). Publishing S05
# makes stage 2 active, so ROW-802 joins added-active within the call
add() { awk -v from="$1" -v id="$2" 'index($0, from " | ") == 1 { print; l = $0; sub("^" from " ", id " ", l); sub(/ Fails if/, " A test added after the applied version. Fails if", l); print l; next } { print }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md; }
add ROW-001 ROW-801; add ROW-017 ROW-802
call; [ "$RC" = 0 ] || fail "the call exited $RC"
sh "$CHECKS/next.sh" triggers > "$T/lines" 2> "$T/out" || fail 'next.sh triggers failed'
grep -Eq "^(trigger|quiet)${TB}important${TB}added-active${TB}ROW-801${TB}" "$T/lines" && ! grep -Eq "^(trigger|quiet)${TB}[a-z]*${TB}added-active${TB}ROW-802${TB}" "$T/lines" || { grep '^trigger\|^quiet' "$T/lines" > "$T/out"; fail 'the listing does not show ROW-801 added-active and ROW-802 not'; }
call publish S05 'Yes, publish S05' -- decline added-active 'These wait'; [ "$RC" = 0 ] || fail "the call exited $RC"
grep -q '^done publish S05' "$T/out" || fail 'S05 was not published'
grep -q '^again decline added-active' "$T/out" || fail 'the decline, reaching ROW-802 which the publish made active, is not shown again'
! grep -q "^added-active${TB}" .vid/next/declined || { cp .vid/next/declined "$T/out"; fail 'the decline reaching a subject the listing never showed was recorded'; }
exit 0
