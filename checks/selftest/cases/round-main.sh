#!/bin/sh
# Purpose: selftest case — the round notices main appear (v0.26.10.28.2, R4, F-002), checks/round.sh on the ticket writer's toy and the fake gh. The code
# repository holds a branch but no main: next refuses the skeleton under main=absent, once, and the next next does not try it again. A failed read of main
# changes nothing. Main is created: the round's ordinary wait ends `new`, the step prints `main-changed`, and next publishes the skeleton on main's commit.
# vid-run's table runs next on it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-main: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; GS=$CHECKS/github.sh
git init -q --bare "$T/e.git"; git -C "$T/e.git" symbolic-ref HEAD refs/heads/main; echo "$T/e.git" > "$T/gh/remote"
git clone -q "$T/e.git" "$T/d" 2>/dev/null; git -C "$T/d" checkout -q -b other; git -C "$T/d" -c user.name=a -c user.email=a@b commit -q --allow-empty -m x; git -C "$T/d" push -q origin other 2>/dev/null
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; }; ok() { grep -q "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q "$1" "$T/out" || fail "a line: $1"; }
sh "$GS" spec-setup > "$T/out" 2>&1 || fail 'spec-setup failed'; sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$GS" lock-take t > "$T/out" 2>&1 || fail 'no lock'
# heads but no main: the skeleton refused once, and not tried again while nothing changes
rd next; [ "$RC" = 0 ] || fail "next failed: $RC"; ok '^refused new skeleton'; no '^published'; grep -q '^sync main=absent ' .vid/tw/log || fail 'the sync is not main=absent'
rd step; [ "$RC" = 0 ] || fail "the first step failed: $RC"; no '^main-changed'
rd next; no '^refused new skeleton'; no '^published'
# a failed read of main: nothing changes
mv "$T/e.git" "$T/e.away"; rd step; [ "$RC" = 0 ] || fail "a step on a failed read failed: $RC"; no '^main-changed'; [ ! -f .vid/round/code-url ] || fail 'a failed read kept its address'; mv "$T/e.away" "$T/e.git"
rd step; no '^main-changed'
# the address kept is the configured repository's: one kept for another is read again
printf 'owner/other %s\n' "$T/nowhere.git" > .vid/round/code-url; rd step; no '^main-changed'; grep -q "^owner/code $T/e.git\$" .vid/round/code-url || fail "the address kept: $(cat .vid/round/code-url)"
# main created: the wait ends new, the step says main-changed, next publishes
git -C "$T/d" checkout -q -b main; git -C "$T/d" -c user.name=a -c user.email=a@b commit -q --allow-empty -m 'the first commit'; git -C "$T/d" push -q origin main 2>/dev/null; MC=$(git -C "$T/d" rev-parse HEAD)
RC=0; VID_WAIT_TICK=1 VID_WAIT_MAX=5 sh "$CHECKS/round.sh" wait > "$T/out" 2>&1 || RC=$?; grep -qx new "$T/out" || fail "the wait did not notice main: $(cat "$T/out")"
rd step; [ "$RC" = 0 ] || fail "the step failed: $RC"; ok '^main-changed$'; no '^idle$'; grep -q '^round-main-changed ' .vid/metrics-events || fail 'no round-main-changed event'
rd next; ok '^published '; grep -q " base=$MC " .vid/tw/out/skeleton-*.meta || fail "the skeleton's base is not main's commit: $(cat .vid/tw/out/skeleton-*.meta | head -n 1)"
rd step; no '^main-changed'
grep -q '^| `main-changed` (v0.26.10.28.2) | .*`sh checks/round.sh next` now' "$CHECKS/../skills/vid-run/SKILL.md" 2>/dev/null || [ ! -d "$CHECKS/../skills" ] || fail "vid-run's table does not run next on main-changed"
echo 'round-main: ok'
