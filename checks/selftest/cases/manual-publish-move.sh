#!/bin/sh
# Purpose: selftest case — the publish move (GM-2 T4, T10; its case manual-publish-move). On the form fixture's toy
# (fixtures/form.sh) in GitHub manual, with no sync line and its plan sitting ended, each call made as /vid next makes it after
# its read (next.sh read, then next-move.sh call with the moves named, under this session's lock): a call with no move keeps
# the listing; `publish S01 "<words>"` writes and posts the skeleton's ticket on the code repository's main; the team then
# merges to main, and `publish S02` goes out on that newer main. With two tickets open (open-tickets: 2) and stage 0 active, the
# listing warns S05's publish past the limit and ahead of the lowest active stage, and `publish S05 "<words>"` is not refused:
# it goes out with the words on its log line, .vid/next/published holds both warnings as the listing showed them with the
# words, the records are saved to the state repository after it, the call's read holds the new ticket's line and its body as
# posted, each move's own replan stage is opened and ended, and its to-do is logged done by the move. Env: CHECKS.
set -eu
unset VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "manual-publish-move: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
TB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
CLAUDE_CODE_SESSION_ID=publish-move-case; export CLAUDE_CODE_SESSION_ID
! grep -q '^sync ' .vid/tw/log 2>/dev/null || fail 'the toy holds a sync line before any move'
printf 'stage name=plan state=end session=S1 at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> .vid/metrics-events
if sh "$CHECKS/plan.sh" gate > /dev/null 2>&1; then fail 'the gate is on with the plan sitting ended'; fi
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
# the page in the viewer's folder under a home of the case's own; a ticket the call posts made now on the fake, as GitHub makes it
HOME=$T/home; export HOME; mkdir -p "$HOME"
made() { for n in $(awk '$1 == "published" { print $2 }' .vid/tw/log 2>/dev/null); do [ -f "$FAKEGH/issues/$n/created" ] || gh_attr "$n" created "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; done; }
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; made; }
pub() { awk -v s="step=$1" '$1 == "published" { for (i = 3; i <= NF; i++) if ($i == s) print }' .vid/tw/log; }
# call 1: the listing, kept
call; [ "$RC" = 0 ] || fail "the call with no move exited $RC"
grep -q "^publish${TB}S01${TB}[0-9a-f]\{40\}\$" .vid/next/moves 2>/dev/null || fail 'the listing kept no publish S01 move in .vid/next/moves'
# call 2: the skeleton
M1=$(git -C "$T/code.git" rev-parse main)
call publish S01 'Yes, publish the skeleton'; [ "$RC" = 0 ] || fail "the call publishing S01 exited $RC"
grep -q '^done publish S01' "$T/out" || fail 'the skeleton publish is not reported done'
L1=$(pub S01); [ -n "$L1" ] || fail 'S01 was not published'
case $L1 in *' kind=skeleton '*) ;; *) fail "S01's ticket is not the skeleton's: $L1" ;; esac
case $L1 in *" base=$M1 "*) ;; *) fail "S01's ticket is not on the code repository's main $M1: $L1" ;; esac
case $L1 in *' words="Yes, publish the skeleton"') ;; *) fail "S01's log line does not end with the owner's words — $L1" ;; esac
grep -q "^sync main=$M1 " .vid/tw/log || fail 'the move made no sync'
# call 3: the team merges; S02 goes out on the newer main
tk_dev 'the team merges a change'; M2=$(git -C "$T/code.git" rev-parse main); [ "$M2" != "$M1" ] || fail 'the merge did not move main'
call publish S02 'Yes, publish S02'; [ "$RC" = 0 ] || fail "the call publishing S02 exited $RC"
L2=$(pub S02); [ -n "$L2" ] || fail 'S02 was not published'
case $L2 in *" base=$M2 "*) ;; *) fail "S02's ticket is not on main as it was at the move ($M2): $L2" ;; esac
# the listing of S05: past the limit and ahead of stage 0
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/next.sh" triggers > "$T/lines" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^warning${TB}publish${TB}S05${TB}limit${TB}" "$T/lines" && grep -q "^warning${TB}publish${TB}S05${TB}stage-ahead${TB}" "$T/lines" || { cp "$T/lines" "$T/out"; fail 'the listing does not warn S05 past the limit and ahead of the lowest active stage'; }
WS=$(awk -F'\t' '$1 == "warning" && $2 == "publish" && $3 == "S05" { printf "%s%s %s", s, $4, $5; s = " | " }' "$T/lines")
# call 4: S05, past both warnings, never refused for them
call publish S05 'Yes, publish S05, past both warnings'; [ "$RC" = 0 ] || fail "the call publishing S05 exited $RC"
grep -q '^done publish S05' "$T/out" || fail 'S05, past its warnings, is not reported done'
L5=$(pub S05); [ -n "$L5" ] || fail 'S05 was not published past its warnings'
N5=$(printf '%s\n' "$L5" | awk '{ print $2 }')
case $L5 in *' words="Yes, publish S05, past both warnings"') ;; *) fail "S05's log line does not end with the owner's words — $L5" ;; esac
awk -F'\t' -v n="$N5" -v w="$WS" '$1 == n && $2 == "S05" && $3 == w && $4 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T/ && $5 == "Yes, publish S05, past both warnings" { f = 1 } END { exit !f }' .vid/next/published 2>/dev/null ||
  { cat .vid/next/published > "$T/out" 2>&1 || :; fail "the warnings shown ($WS) are not kept with the words in .vid/next/published"; }
# the records saved after the post
U=$(gh repo view owner/vid-state --json url --jq .url); git init -q "$T/sr"; git -C "$T/sr" fetch -q "$U" refs/heads/vid-state/records 2>/dev/null || fail 'no records are saved'
git -C "$T/sr" show FETCH_HEAD:tw/log | grep -q "^published $N5 " || fail "the saved records do not hold S05's published line"
git -C "$T/sr" show FETCH_HEAD:next/published | grep -q "^$N5$TB" || fail 'the saved records do not hold the kept warnings'
# the call's read: the new ticket's line, and its body as posted
grep -q "^ticket${TB}$N5${TB}OPEN${TB}-${TB}" .vid/next/read || fail "the call's read holds no ticket line for #$N5"
awk '{ L[NR] = $0 } END { while (NR > 0 && L[NR] == "") NR--; for (i = 1; i <= NR; i++) print L[i] }' "$FAKEGH/issues/$N5/body" > "$T/want"
awk -F'\t' -v n="$N5" '$1 == "body" && $2 == n { print substr($0, length("body") + length(n) + 3) }' .vid/next/read > "$T/got"
cmp -s "$T/want" "$T/got" || { diff "$T/want" "$T/got" > "$T/out" || :; fail "the call's read does not hold #$N5's body as posted"; }
# each move's own stage, opened and ended; none left open
S=$(grep -c '^stage name=replan state=start session=publish-move-case ' .vid/metrics-events || true)
E=$(grep -c '^stage name=replan state=end session=publish-move-case' .vid/metrics-events || true)
[ "$S" = 3 ] && [ "$E" = 3 ] || fail "the three moves opened $S replan stages and ended $E, not 3 and 3"
if sh "$CHECKS/plan.sh" gate > /dev/null 2>&1; then fail 'a stage is left open after the moves'; fi
# the to-do, done by its move
awk -F'\t' '$2 == "done" && $3 == "publish S05" && $5 == "move" { f = 1 } END { exit !f }' .vid/next/todo 2>/dev/null || fail "S05's to-do is not logged done by its move"
exit 0
