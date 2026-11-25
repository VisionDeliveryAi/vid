#!/bin/sh
# Purpose: selftest case — DevAgent's quiet wait (FB-8 E4), devagent/dev-manager/dm.sh next --wait on the fake gh, on shortened times. With
# nothing, or with a ticket that waits, is blocked or left, it reads again at each tick and returns at its time, never before, with next's
# own lines; with a line that calls for work it returns at once, and within a tick of one that comes; at a vid-silent line too, once while it stands; a read that fails is tried again, and
# the last one failing is its failure; with no repo: in the note it is refused at once. next without it reads once and prints its lines as before.
# Its time is 540 seconds and its tick 60, and vid-devagent's conversation waits by it alone. Skips where devagent/ or skills/ is absent. Env: CHECKS.
set -eu
[ -d "$CHECKS/../devagent" ] && [ -d "$CHECKS/../skills" ] || { echo 'needs devagent/ and skills/'; exit 77; }
DM=$(cd "$CHECKS/.." && pwd -P)/devagent/dev-manager/dm.sh; SK=$CHECKS/../skills/vid-devagent/SKILL.md
T=$(mktemp -d); K=''; trap '[ -z "$K" ] || wait "$K" 2>/dev/null || true; rm -rf "$T"' EXIT
HOME=$T/home; mkdir -p "$HOME"; export HOME
. "$CHECKS/selftest/fixtures/tickets.sh"
fail() { echo "dm-next-wait: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
{ git init -q --bare "$T/code.git"; git -C "$T/code.git" symbolic-ref HEAD refs/heads/main; git init -q "$T/s"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m base; git -C "$T/s" push -q "$T/code.git" HEAD:refs/heads/main; }
gh_fake; W=$T/work; mkdir -p "$W/tickets"; DM_WORK=$W; export DM_WORK
printf 'repo: owner/code\nlabels-prefix: \nwork: %s\ntime-limit: 3600\nagent-time-limit: 600\nagent-turn-limit: 40\nagents: conversation\n' "$W" > "$W/dm-note.txt"
g() { gh "$@" > /dev/null; }
# the fake gh, its issue lists counted, and failing while $T/gh-down stands
mv "$T/bin/gh" "$T/bin/gh.real" 2>/dev/null || fail 'the fake gh is not where the case looks'
printf '#!/bin/sh\n[ "$1 $2" != "issue list" ] || echo read >> "%s/reads"\n[ "$1 $2" != "issue list" ] || [ ! -f "%s/gh-down" ] || { echo "no network" >&2; exit 1; }\nexec "%s/bin/gh.real" "$@"\n' "$T" "$T" "$T" > "$T/bin/gh"; chmod +x "$T/bin/gh"
# nw <tick> <time>: next --wait, its seconds in SEC, its reads in RD
nw() { : > "$T/reads"; s=$(date +%s); RC=0; DM_TICK=$1 DM_NEXT=$2 sh "$DM" next --wait > "$T/out" 2> "$T/err" || RC=$?; SEC=$(($(date +%s) - s)); RD=$(grep -c . "$T/reads" || true); }
# nothing to do: at its time, never before, reading at each tick
nw 2 6; [ "$RC" = 0 ] && [ "$(cat "$T/out")" = none ] || fail "with no line ($RC)"; [ "$SEC" -ge 6 ] || fail "it returned after $SEC s of 6 with nothing to do"; [ "$RD" -ge 3 ] || fail "it read $RD times in 6 s at a tick of 2"
g issue create -R owner/code --title t1 --body x --label ticket; g issue edit 1 -R owner/code --add-label blocked; g issue create -R owner/code --title t2 --body x --label ticket; echo 'left: twice' > "$W/tickets/2.txt"
printf 'close: S01\n\n- chunk p1c1, alpha: ROW-001\n' > "$T/b"; g issue create -R owner/code --title run --body-file "$T/b" --label run; printf 'vid: reported p1c1-1\n' > "$T/b"; g issue comment 3 -R owner/code --body-file "$T/b"
nw 2 5; [ "$RC" = 0 ] && [ "$(cat "$T/out")" = 'wait 3
blocked 1
left 2' ] || fail "with lines that wait ($RC)"; [ "$SEC" -ge 5 ] || fail "it returned after $SEC s of 5 with lines that wait alone"
# next without it: one read, its lines, at once
: > "$T/reads"; s=$(date +%s); DM_TICK=5 DM_NEXT=20 sh "$DM" next > "$T/o2" 2>&1 || fail 'next'; [ $(($(date +%s) - s)) -le 4 ] && [ "$(grep -c . "$T/reads")" = 1 ] && cmp -s "$T/o2" "$T/out" || fail 'next without --wait changed'
# a `vid-silent` line not said yet: the wait returns at it, once while it stands; answered, and silent again at a later ask, once more; another ticket's, once too
ago() { _e=$(($(date +%s) - $1 * 60 - 5)); date -u -r "$_e" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "@$_e" '+%Y-%m-%dT%H:%M:%SZ'; }
ask() { printf '%s\n' "$2" > "$T/b.$1"; mkdir -p "$T/gh/prs/$1/cat"; ago "$3" > "$T/gh/prs/$1/cat/$(($(ls "$T/gh/prs/$1/comments" 2>/dev/null | wc -l) + 1))"; g pr comment "$1" -R owner/code --body-file "$T/b.$1"; }
tk() { n=$(gh issue create -R owner/code --title s --body x --label ticket); n=${n##*/}; printf 'vid: claimed\nby: DM\n' > "$T/b"; g issue comment "$n" -R owner/code --body-file "$T/b"; git -C "$T/s" checkout -q -B "t-$n"; git -C "$T/s" -c user.email=a@b -c user.name=a commit -q --allow-empty -m "t$n"; git -C "$T/s" push -q "$T/code.git" "t-$n"; H=$(git -C "$T/s" rev-parse HEAD); p=$(gh pr create -R owner/code --head "t-$n" --base main --title x --body "ticket: #$n"); p=${p##*/}; }
tk; A=$n; PA=$p; HA=$H; ask "$PA" "vid: decide $HA" 5; ( sleep 3; ago 41 > "$T/gh/prs/$PA/cat/1" ) & K=$!; nw 1 60; wait "$K" || true; K=''
[ "$RC" = 0 ] && grep -qx "vid-silent $A 41" "$T/out" && grep -qx "wait $A" "$T/out" && [ "$SEC" -le 15 ] || fail "with a silence that came ($RC, $SEC s)"
nw 2 5; [ "$RC" = 0 ] && grep -q "^vid-silent $A " "$T/out" && [ "$SEC" -ge 5 ] || fail "it returned again for a silence said, after $SEC s of 5"
ask "$PA" "vid: decision $HA
ticket: not yet
ROW-001 held, a limit" 10; nw 1 3; [ "$RC" = 0 ] && ! grep -q '^vid-silent' "$T/out" && [ "$SEC" -ge 3 ] || fail "answered ($RC, $SEC s)"
ask "$PA" "vid: decide $HA" 35; nw 1 60; [ "$RC" = 0 ] && grep -q "^vid-silent $A " "$T/out" && [ "$SEC" -le 10 ] || fail "silent again at a later ask ($RC, $SEC s)"
tk; ask "$p" "vid: decide $H" 50; nw 1 60; [ "$RC" = 0 ] && grep -q "^vid-silent $n " "$T/out" && [ "$SEC" -le 10 ] || fail "another ticket's silence ($RC, $SEC s)"
nw 1 3; [ "$SEC" -ge 3 ] || fail "it returned again for two silences said, after $SEC s of 3"; [ ! -e "$W/dm-report.txt" ] || fail "the wait wrote dm-report.txt: $(cat "$W/dm-report.txt")"
# the last read failing is a failure; one that fails and comes back is not
touch "$T/gh-down"; nw 1 3; [ "$RC" = 1 ] && [ ! -s "$T/out" ] && [ "$SEC" -ge 3 ] || fail "with no read that worked ($RC, $SEC s)"; rm -f "$T/gh-down"
# a line that comes, after a read that failed: within a tick of it
touch "$T/gh-down"; ( sleep 2; rm -f "$T/gh-down"; sleep 1; gh issue create -R owner/code --title t4 --body x --label ticket > /dev/null 2>&1 ) & K=$!
nw 2 60; wait "$K" || true; K=''
[ "$RC" = 0 ] && grep -q '^claim ' "$T/out" && grep -qx 'wait 3' "$T/out" || fail "with a line that came ($RC)"; [ "$SEC" -le 15 ] || fail "it returned $SEC s after it began, with work after 3 s"
# a line already there: at once
nw 60 540; [ "$RC" = 0 ] && grep -q '^claim ' "$T/out" && [ "$SEC" -le 5 ] && [ "$RD" = 1 ] || fail "with work already there ($RC, $SEC s, $RD reads)"
# no repo: refused at once
cp "$W/dm-note.txt" "$T/n"; grep -v '^repo:' "$T/n" > "$W/dm-note.txt"; nw 2 60; [ "$RC" = 1 ] && [ "$SEC" -le 5 ] && grep -q 'no repo:' "$T/err" || fail "with no repo: in the note ($RC, $SEC s)"; cp "$T/n" "$W/dm-note.txt"
# its own times, and the skill's wait
grep -qF '${DM_NEXT:-540}' "$DM" && grep -qF 'dm.sh next --wait' "$DM" || fail "dm.sh's wait is not 540 s, or its head does not say next --wait"
grep -F 'devagent/dev-manager/dm.sh" next --wait' "$SK" | grep -qF '`vid-silent` line not said yet' && grep -qF 'devagent/dev-manager/dm.sh" next --wait' "$SK" && ! grep -qi 'wait 5 minutes' "$SK" || fail "vid-devagent's conversation does not wait by next --wait alone"
grep -F 'dm.sh" next --wait' "$SK" | grep -qF '600000' || fail "vid-devagent does not give next --wait's Bash timeout"
echo 'dm-next-wait: ok'
