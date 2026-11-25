#!/bin/sh
# Purpose: selftest case — an outside service (a seam) is of its step's stage (FB-4 A2, planner.sh), on the planner's toy
# (fixtures/planner-toy.sh) with a third seam, SEAM-003. In S05, whose one other row is of stage 2, the check is clean, its
# stage is 2 and the page says so; in S04 (stage 1) it is of stage 1; in no step it is flagged, and reads 1; in a step of
# seams alone it stays 1; in the skeleton it is flagged; a `moved:` line stands, checked against 1 as before. In GitHub
# manual no `place` line names it, and a step with a published ticket gives its seam the stage that ticket's header names; in a
# step of rows of two stages the seam is of the stage most of them are in; and seams moved to another stage never make the step's.
# Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-seam-stage: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
SM='seam | SEAM-003 | the synonym service | looking up the other names of an occupation | chosen: D-003 | credentials: held | probe: owed | evidence: owed | quirks: none yet'
# toy <step, or none>: the toy with SEAM-003 in that step
toy() { cd "$T"; TN=$((${TN:-0} + 1)); pt_toy "$T/p$TN"; pt_after SEAM-002 "$SM"
  [ "$1" = none ] || pt_rs "s/^\(step $1 .*rows: [^|]*[^| ]\) |/\1 SEAM-003 |/; s/^needs ROW-017 | -\$/needs ROW-017 | -\nneeds SEAM-003 | -/"
  [ "$1" = none ] || grep -q "^step $1 .*SEAM-003" .vid/RUN-STATE.md || fail "the toy's $1 does not hold SEAM-003"
  grep -q '^needs SEAM-003' .vid/RUN-STATE.md || [ "$1" = none ] || { awk '{ print } /^needs ROW-017 / { print "needs SEAM-003 | -" }' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x; }; }
stg() { sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' -v r="$1" '$1 == r { print $5 }'; }
toy S05; pt_check; [ "$PT_RC" = 0 ] || fail "a seam in the stage 2 step that first builds against it is flagged ($PT_RC)"
[ "$(stg SEAM-003)" = 2 ] || fail "in S05 its stage is $(stg SEAM-003), not 2"; [ "$(stg SEAM-001)$(stg SEAM-002)" = 11 ] || fail "the stage 1 steps' seams: $(stg SEAM-001) $(stg SEAM-002)"
sh "$CHECKS/planner.sh" rows | awk -F'\t' '$1 == "SEAM-003" { print $10 }' | grep -qx 'deploy-owed: staging, in stage 2' || fail 'its class text does not name stage 2'
sh "$CHECKS/planner.sh" page > /dev/null 2>&1; awk '/^## Stage / { s = $3 } /SEAM-003/ { print s }' .vid/plan/PLAN-PAGE.md | grep -qx 2 || fail 'the page does not show it in stage 2'
toy S04; pt_check; [ "$PT_RC" = 0 ] && [ "$(stg SEAM-003)" = 1 ] || fail "in S04 ($PT_RC) its stage is $(stg SEAM-003), not 1"
toy none; pt_check; pt_has 'class SEAM-003 — in no step'; [ "$(stg SEAM-003)" = 1 ] || fail "in no step its stage is $(stg SEAM-003)"
toy S05; pt_rs 's/ SEAM-003 | lane/ | lane/'; awk '{ print } /^step S02 / { print "step S06 | name: the synonym service | modules: search | builds-on: S02 | rows: SEAM-003 | lane: devagent" }' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x
pt_check; [ "$PT_RC" = 0 ] && [ "$(stg SEAM-003)" = 1 ] || fail "in a step of seams alone ($PT_RC) its stage is $(stg SEAM-003), not 1"
toy S01; pt_check; [ "$PT_RC" = 1 ] || fail 'a seam in the skeleton passed'; pt_has 'skeleton S01 — its row SEAM-003 is deploy-owed or a seam'
toy S05; pt_after 'standing work' 'SEAM-003 | moved: STAGE-2 A-001'; pt_check; [ "$PT_RC" = 0 ] && [ "$(stg SEAM-003)" = 2 ] || fail "moved to its step's stage ($PT_RC) its stage is $(stg SEAM-003)"
toy S04; pt_after 'standing work' 'SEAM-003 | moved: STAGE-2 A-001'; pt_check; pt_has 'step S04 — its rows are in stages 1 and 2'
toy S05; pt_after 'standing work' 'SEAM-003 | moved: STAGE-1 A-001'; pt_check; pt_has 'moved SEAM-003 — STAGE-1 is not later than its stage 1'
# GitHub manual: no place line; a published ticket's header gives its step's stage, its seam's with it
man() { toy "$1"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
  printf 'setup-answered key=github-mode value="manual" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
  mkdir -p .vid/tw/out; git rev-parse HEAD > .vid/tw/applied; }
man S05; pt_check; no '^place SEAM-003'; [ "$PT_RC" = 0 ] && [ "$(stg SEAM-003)" = 2 ] || fail "in manual ($PT_RC) its stage is $(stg SEAM-003)"
man S05; printf 'published 7 kind=step step=S04 rows=ROW-002 at=2026-11-19T10:00:00Z\n' > .vid/tw/log; printf '# t\n\n## Header\n\n- kind: step\n- stage: 2, Synonym-aware search\n' > .vid/tw/out/issue-7.md
pt_rs 's/ SEAM-003 | lane/ | lane/; s/^\(step S04 .*\) RULE-004 |/\1 RULE-004 SEAM-003 |/'; pt_check; no '^place SEAM-003'; [ "$(stg SEAM-003)" = 2 ] || fail "in a step whose ticket is of stage 2 its stage is $(stg SEAM-003)"
# most of the step's other rows: S04 holding ROW-017 (stage 2) too stays of stage 1, its seam with it
man S04; pt_del 'step S05'; pt_rs 's/^\(step S04 .*rows:\) /\1 ROW-017 /'; pt_check; [ "$(stg SEAM-003)" = 1 ] || fail "in a step of seven stage 1 rows and one of stage 2 its stage is $(stg SEAM-003)"
pt_has 'place ROW-017 — in step S04 of stage 1; its own stage is 2'; no '^place SEAM-003'
# without the seams: two seams moved to stage 2 beside one stage 1 row leave the step in stage 1
man none; pt_after SEAM-003 "$(echo "$SM" | sed 's/SEAM-003/SEAM-004/')"; pt_after 'standing work' 'SEAM-004 | moved: STAGE-2 A-001'; pt_after 'standing work' 'SEAM-003 | moved: STAGE-2 A-001'
pt_rs 's/^\(step S04 .*\) ROW-018 /\1 /'; awk '{ print } /^step S04 / { print "step S06 | name: the failure log | modules: digest | builds-on: S02 | rows: ROW-018 SEAM-003 SEAM-004 | lane: devagent" } /^needs ROW-017 / { print "needs SEAM-003 SEAM-004 | -" }' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md && rm R.x
g commit -qam 'two seams moved'; git rev-parse HEAD > .vid/tw/applied; pt_check; no '^place ROW-018'; pt_has 'place SEAM-003 — in step S06 of stage 1; its own stage is 2'; pt_has 'place SEAM-004 — in step S06 of stage 1; its own stage is 2'
toy S04; [ "$(stg SEAM-003)" = 1 ] || fail 'in auto the same step gives it stage 1'
exit 0
