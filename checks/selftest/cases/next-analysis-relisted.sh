#!/bin/sh
# Purpose: selftest case — the analysis's own instruction works first time (the GM-4 proof's D3). The call that runs
# `planning-analysis` printed its listing before the conversation ran the analysis, so that listing still offers the move as it
# stood before the new proposal, and `/vid next implement-replan "<words>"`, as the analysis tells the owner, was shown again
# once, "changed since the listing". vid-next's call, after the analysis and before vid-connect's end, makes the call's listing
# again from the new proposal (`next-move.sh call` with no move). On the re-plan toy (fixtures/manual.sh's mn_replan_toy):
# `planning-analysis` checked, the analysis written, then the listing made again: its implement-replan line names the proposal
# its page shows (.vid/next/proposal/hash, on REPLAN-PAGE.html), and the next call's `implement-replan "<words>"` is not shown
# again but done. Reads skills/vid-next for its half; that half is skipped in a project's layout. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "next-analysis-relisted: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the skill's half: after the analysis, the listing made again before the end
SK=$CHECKS/../skills/vid-next/SKILL.md
if [ -f "$SK" ]; then tr '\n' ' ' < "$SK" | tr -s ' ' > "$T/sk"
  grep -qF 'then the call'"'"'s listing made again from the new proposal: `sh "${CLAUDE_PLUGIN_ROOT}/checks/next-move.sh" call`, with no move' "$T/sk" ||
    fail 'vid-next does not make the call'"'"'s listing again after the analysis'; fi
mn_replan_toy "$T/toy" || { cp "$T/mr" "$T/out"; fail 'the re-plan toy could not be made'; }
CLAUDE_CODE_SESSION_ID=analysis-relisted-case; export CLAUDE_CODE_SESSION_ID
sh "$CHECKS/github.sh" lock-take > "$T/out" 2>&1 || fail 'the lock could not be taken'
HOME=$T/home; export HOME; mkdir -p "$HOME"
call() { sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; RC=0; sh "$CHECKS/next-move.sh" call "$@" > "$T/out" 2>&1 || RC=$?; }
call; [ "$RC" = 0 ] || fail "the first listing exited $RC"
call planning-analysis
[ "$RC" = 0 ] && grep -q '^checked planning-analysis -' "$T/out" || fail 'planning-analysis was not checked'
cp "$T/out" "$T/before"
# the analysis (the vid-replan skill's), as manual-replan-moves writes it
C=$T/cand; mkdir -p "$C"; printf 'none\n' > "$C/review"
awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md |
  sed -e 's/^\(step S02 .*rows:\) /\1 ROW-021 /' -e 's/^\(step S03 .*\) ROW-019 /\1 /' -e 's/^\(step S04 .*rows:\) ROW-002 \(.*\) HOS-003 /\1 \2 /' -e 's/^\(step S05 .*rows: ROW-017\)/\1 ROW-002 HOS-003/' \
    -e 's/^needs ROW-001 /needs ROW-021 ROW-001 /' -e 's/^\(needs .*\) ROW-019 /\1 /' -e 's/^needs ROW-002 \(.*\) HOS-003 /needs \1 /' -e 's/^needs ROW-017 /needs ROW-017 ROW-002 HOS-003 /' > "$C/block"
S=$(git rev-parse --short HEAD); for s in S02 S03 S04 S05; do printf '%s\tscope-change\tcommit:%s\tthe landed changes placed\n' "$s" "$S"; done > "$C/changes"
pt_placed "$C/placement"; sh "$CHECKS/replan.sh" analyse --candidate "$C" > "$T/out" 2>&1 || fail 'the analysis was refused'
PH=$(cat .vid/next/proposal/hash); [ -n "$PH" ] || fail 'the analysis wrote no proposal hash'
grep -q "$PH" .vid/pages/REPLAN-PAGE.html || fail 'the proposal page does not show its proposal: the scene is wrong'
# the call's listing made again from the new proposal (vid-next, after the analysis)
call; [ "$RC" = 0 ] || fail "the listing made again exited $RC"
grep "implement-replan" "$T/out" | grep -q "applies the analysis's proposal $PH" || fail "the listing made again does not offer implement-replan with the proposal its page shows ($PH)"
# the analysis's own instruction, the next call
call implement-replan 'Yes, apply the re-plan as its page shows' --review "$T/mrv"
! grep -q '^again implement-replan' "$T/out" || fail 'implement-replan, named as the analysis said, was shown again'
grep -q '^done implement-replan' "$T/out" || fail 'implement-replan, named as the analysis said, was not done'
echo 'next-analysis-relisted: ok'
