#!/bin/sh
# Purpose: selftest case — a step refused for its stage waits for a stage change, not a main change (low-1, R3), checks/round.sh on the
# writer's toy and the fake gh. Stage 0 closed with its candidate staged, and `held-after: 0`: next refuses S02, S03 and S04 for their
# stage. The fake remote's main moves to a new commit, so the round's own tw-sync logs it: the next next tries none of them again
# (no plan.sh start, no new `refused phase=admission by=stage` event), and the status still counts them waiting. A PRD.md change
# alone: next tries them again. FB-8 E1: a handed line of another word (a row's state, an engine's split), or the label of a candidate, staged or
# setup-hold line alone, tries none of them again; a new line of one of the three tries each once. The `held-after:` line removed:
# next tries them again, and S02 is admitted. Env: CHECKS.
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
# FB-8 E1: the handed record's lines: only the three the stage admission reads try a step again, and never by their label
rd next; E1=$(ev); H=.vid/tw/handed
hd() { printf '%s | stand-in: the self-test, %s\n' "$1" "${2:-one}" >> "$H"; }
hd 'row ROW-004 accepted'; hd 'engine-split ROW-004'; rd next; [ "$(ev)" = "$E1" ] || fail "a row's state and an engine's split on the handed record tried a step refused for its stage again: $(($(ev) - E1)) new stage refusals"; no '^refused start'
for x in 'candidate 7' 'staged 0000000' 'setup-hold on'; do
  hd "$x"; rd next; for s in S02 S03 S04; do ok "^refused start $s: .*holds rows outside stages"; done; E2=$(ev); [ "$E2" -gt "$E1" ] || fail "a new line '$x' did not try the steps again"; E1=$E2
  rd next; [ "$(ev)" = "$E1" ] || fail "an unchanged round tried a refused step again after '$x'"; done
sed '/^candidate 7/s/ one$/ two/; /^staged 0000000/s/ one$/ two/; /^setup-hold on/s/ one$/ two/' "$H" > "$T/h" && cat "$T/h" > "$H"; grep -c ' two$' "$H" | grep -qx 3 || fail 'the labels did not change'
rd next; [ "$(ev)" = "$E1" ] || fail 'the label of a candidate, staged or setup-hold line alone tried a step again'
# the hold removed: tried again, and S02 admitted
grep -v '^held-after:' .vid/RUN-STATE.md > "$T/rs" && cat "$T/rs" > .vid/RUN-STATE.md
rd next; ok '^published '; grep -q '^step-start .*step=S02 ' .vid/metrics-events || fail 'S02 was not tried again once the hold was removed'
echo 'round-stage-hold: ok'
