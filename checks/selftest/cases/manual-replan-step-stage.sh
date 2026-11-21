#!/bin/sh
# Purpose: selftest case — the re-plan's check reads a step's stage from the planner (GM-4 F10: no rule another script owns is
# written again). On the form fixture's toy (fixtures/form.sh), S02 posted as ticket N (its header: stage 1). A re-cut committed
# by hand moves S02's seven ROW- rows to stage 2, so most of S02's rows are of stage 2 at HEAD while the planner keeps S02 in stage 1,
# the stage its published ticket's header names. ROW-018 (stage 1), held as other-stage by the to-place list, moved from S04 into
# S02: S02 is of ROW-018's stage, so the check prints no rule-4 breach for it; and replan.sh holds no step-stage rule of its own.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "manual-replan-step-stage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
fm_post S02 || { cp "$T/post" "$T/out"; fail 'S02 was not posted in manual'; }
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
# the re-cut: S02's seven ROW- rows to stage 2, more than its stage-1 rows
awk '{ print } /^row: ROW-004 -> STAGE-0/ { print "row: ROW-001 -> STAGE-2"; print "row: ROW-005 -> STAGE-2"; print "row: ROW-008 -> STAGE-2"; print "row: ROW-012 -> STAGE-2"; print "row: ROW-013 -> STAGE-2"; print "row: ROW-015 -> STAGE-2"; print "row: ROW-016 -> STAGE-2" }' STAGES.md > "$T/st" && cat "$T/st" > STAGES.md
git -c user.email=vid@selftest -c user.name=vid commit -qam 'the re-cut: S02'"'"'s ROW- rows to stage 2'
sh "$CHECKS/planner.sh" steps > "$T/ps" 2> "$T/out" || fail 'planner.sh steps failed'
awk -F'\t' '$1 == "S02" && $3 == 1 { f = 1 } END { exit !f }' "$T/ps" || { cp "$T/ps" "$T/out"; fail 'the planner does not keep S02 in stage 1, its ticket'"'"'s'; }
# ROW-018, other-stage on the to-place list, from S04 into S02
mkdir -p "$T/c"; blk | sed -e 's/^\(step S04 .*\) ROW-018 /\1 /' -e 's/^\(step S02 .*rows:\) /\1 ROW-018 /' > "$T/c/block"
for s in S02 S04; do printf '%s\tscope-change\tcommit:%s\tthe step takes its rows as the toy plans them\n' "$s" "$(git rev-parse --short HEAD)" >> "$T/c/changes"; done
printf 'ROW-018\tother-stage\t2026-11-03T09:00:00Z\tLeave it where it stands\n' > .vid/tw/to-place
RC=0; sh "$CHECKS/replan.sh" check "$T/c/block" > "$T/out" 2>&1 || RC=$?
[ "$RC" -le 1 ] || fail "replan.sh check could not run ($RC)"
! grep -q '^rule-4 ROW-018 ' "$T/out" || fail 'ROW-018, into a step of its own stage as the planner reads it, is a rule-4 breach'
! grep -n 'function ostage' "$CHECKS/replan.sh" > "$T/out" || fail 'replan.sh computes a step'"'"'s stage itself (ostage)'
exit 0
