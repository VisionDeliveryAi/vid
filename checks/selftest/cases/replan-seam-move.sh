#!/bin/sh
# Purpose: selftest case — an outside service's stage follows the plan, so no re-plan reading compares it as a row's own
# (FB-4 A2, replan.sh and next.sh). On the form fixture's toy (fixtures/form.sh) with SEAM-003 in S04 (stage 1), in GitHub
# manual: a candidate moving it into S05 (stage 2) breaks no rule, though the to-place list once accepted it in another
# stage's step. A re-cut committed by hand then moves S04's four ROW- rows to stage 2, and SEAM-003 with its step:
# `next.sh pending` and the re-plan's scope name the rows as moved, never SEAM-003. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "replan-seam-move: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; TAB=$(printf '\t')
fm_toy "$T/toy" || fail 'the toy could not be made'
pt_after SEAM-002 'seam | SEAM-003 | the synonym service | looking up the other names of an occupation | chosen: D-003 | credentials: not-yet | probe: unreachable-risk(credentials not-yet) | evidence: owed | quirks: none yet'
pt_rs 's/ RULE-004 |/ RULE-004 SEAM-003 |/'; grep -q '^step S04 .*SEAM-003' .vid/RUN-STATE.md && grep -q '^needs .*SEAM-003' .vid/RUN-STATE.md || fail 'the toy holds no SEAM-003 in S04'
g commit -qam 'a third outside service'; git rev-parse HEAD > .vid/tw/applied; pt_record; sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'
sh "$CHECKS/planner.sh" check > "$T/out" 2>&1 || fail 'the plan is flagged'
stg() { sh "$CHECKS/planner.sh" rows "$@" 2>/dev/null | awk -F'\t' '$1 == "SEAM-003" { print $5 }'; }
[ "$(stg)" = 1 ] || fail "in S04 its stage is $(stg)"
blk() { awk '/^## The plan/ { s = 1; next } s && /^```vid-plan[ \t]*$/ { b = 1; next } b && /^```[ \t]*$/ { exit } b' .vid/RUN-STATE.md; }
mkdir -p "$T/c"; blk | sed -e 's/ SEAM-003 | lane/ | lane/' -e 's/ SEAM-003 | -$/ | -/' -e 's/rows: ROW-017 |/rows: ROW-017 SEAM-003 |/' -e 's/^needs ROW-017 |/needs ROW-017 SEAM-003 |/' > "$T/c/block"
for s in S04 S05; do printf '%s\tscope-change\tcommit:%s\tthe service goes with the step that first builds against it\n' "$s" "$(git rev-parse --short HEAD)" >> "$T/c/changes"; done
chk() { RC=0; sh "$CHECKS/replan.sh" check "$T/c/block" > "$T/out" 2>&1 || RC=$?; [ "$RC" -le 1 ] || fail "replan.sh check could not run ($RC)"; }
chk; no 'SEAM-003'; no '^rule-'
printf 'SEAM-003\tother-stage\t2026-11-03T09:00:00Z\tLeave it where it stands\n' > .vid/tw/to-place; chk; no '^rule-4 SEAM-003'
rm .vid/tw/to-place
# the re-cut: S04's ROW- rows to stage 2, its seam's stage with them
awk '{ print } /^row: ROW-004 -> STAGE-0/ { for (i = 1; i <= 4; i++) print "row: " substr("ROW-002ROW-009ROW-011ROW-018", 7 * i - 6, 7) " -> STAGE-2" }' STAGES.md > "$T/st" && cat "$T/st" > STAGES.md; g commit -qam 'the re-cut'
[ "$(stg --at HEAD)" = 2 ] && [ "$(stg)" = 1 ] || fail "its stage at the applied commit is $(stg), at HEAD $(stg --at HEAD)"
sh "$CHECKS/next.sh" pending > "$T/out" 2>&1 || fail 'next.sh pending failed'; ok "^pending${TAB}moved-stage${TAB}ROW-002\$"; no 'SEAM-003'
sh "$CHECKS/next.sh" read > "$T/out" 2>&1 || fail 'next.sh read failed'; sh "$CHECKS/replan.sh" scope > "$T/out" 2>&1 || fail 'replan.sh scope failed'
ok "^moved-stage${TAB}ROW-002${TAB}1${TAB}2\$"; no "moved-stage${TAB}SEAM-003"
exit 0
