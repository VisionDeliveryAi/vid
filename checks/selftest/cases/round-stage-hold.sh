#!/bin/sh
# Purpose: selftest case — a step refused for its stage waits for a stage change, not a main change (low-1, R3), checks/round.sh on the
# writer's toy and the fake gh. Stage 0 closed with its candidate staged, and `held-after: 0`: next refuses S02, S03 and S04 for their
# stage. The fake remote's main moves to a new commit, so the round's own tw-sync logs it: the next next tries none of them again
# (no plan.sh start, no new `refused phase=admission by=stage` event), and the status still counts them waiting. A PRD.md change
# alone: next tries them again. The `held-after:` line removed: next tries them again, and S02 is admitted. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "round-stage-hold: $*" >&2; sed 's/^/    /' "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; tw_skel || fail "the skeleton round failed: $(cat "$T/werr" "$T/sk" 2>/dev/null | tail -n 3)"
mkdir -p checks; cp "$CHECKS/stages.sh" "$CHECKS/prd.sh" checks/   # the stage rule reads them at the home
rd() { RC=0; sh "$CHECKS/round.sh" "$@" > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "round.sh $* failed: $RC"; }
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
ev() { grep -c '^refused phase=admission by=stage ' .vid/metrics-events || true; }
sh "$CHECKS/event.sh" 'stage name=run state=start session=t records=33'; sh "$CHECKS/github.sh" lock-take t > "$T/out" 2>&1 || fail 'no lock'
awk '{ print } /^stage: 0$/ { print "held-after: 0" }' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md; grep -qx 'held-after: 0' .vid/RUN-STATE.md || fail 'no held-after line'
# the hold: the three stage-1 steps refused for their stage
rd next; for s in S02 S03 S04; do ok "^refused start $s: .*holds rows outside stages"; done; no '^published'; E1=$(ev); [ "$E1" -ge 3 ] || fail "$E1 stage refusals, not 3"
rd next; [ "$(ev)" = "$E1" ] || fail 'an unchanged round tried a refused step again'; no '^refused start'
# main moves: the round's own tw-sync logs it, and no step refused for its stage is tried again
( cd "$T/dev" && g commit -q --allow-empty -m 'main moves' && git push -q origin main 2>/dev/null ); MC=$(git --git-dir="$T/code.git" rev-parse main)
rd next; grep -q "^sync main=$MC " .vid/tw/log || fail "the round's tw-sync did not log the new main: $(grep '^sync main=' .vid/tw/log | tail -n 1)"
[ "$(ev)" = "$E1" ] || fail "a main change tried a step refused for its stage again: $(($(ev) - E1)) new stage refusals"; no '^refused start'
sh "$CHECKS/queue.sh" status > "$T/out" 2>&1 || fail 'the status failed'; ok 'steps waiting S02 S03 S04'
# a PRD.md change alone: tried again
cp PRD.md "$T/prd"; printf '\n<!-- the self-test: a PRD.md change alone -->\n' >> PRD.md
rd next; ok '^refused start S02: .*holds rows outside stages'; E2=$(ev); [ "$E2" -gt "$E1" ] || fail 'a PRD.md change did not try the steps again'
cp "$T/prd" PRD.md; rd next; E1=$(ev)
# the hold removed: tried again, and S02 admitted
grep -v '^held-after:' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
rd next; ok '^published '; grep -q '^step-start .*step=S02 ' .vid/metrics-events || fail 'S02 was not tried again once the hold was removed'
echo 'round-stage-hold: ok'
