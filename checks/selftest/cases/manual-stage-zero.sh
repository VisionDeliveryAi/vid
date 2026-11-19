#!/bin/sh
# Purpose: selftest case — in GitHub manual stage 0 may hold several steps (GM-1 S4, rule P4). On the planner's toy
# (fixtures/planner-toy.sh) with ROW-006 moved to stage 0 and stage 0 cut in three steps — S01 the skeleton (ROW-003), S06
# (ROW-004) and S07 (ROW-006), each building on the skeleton — committed in a git repository, its applied version that
# commit: `planner.sh check` passes in manual and, in GitHub auto, flags each other stage-0 step and the rows the skeleton
# lacks. In manual: a second skeleton is flagged; a skeleton that builds on a step is flagged; a stage-0 row in no step is
# flagged `place <row> — in no step`, and one in a step of stage 1 is flagged as in a step of another stage. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "manual-stage-zero: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
S01='step S01 | name: save a search | modules: web digest | builds-on: - | rows: ROW-003 | lane: devagent | kind: skeleton'
S06='step S06 | name: confirm and read the first digest | modules: web digest | builds-on: S01 | rows: ROW-004 | lane: devagent'
S07='step S07 | name: the header and footer | modules: web | builds-on: S01 | rows: ROW-006 | lane: devagent'
S03='step S03 | name: the footer, unsubscribe and the mail provider | modules: web mail | builds-on: S01 | rows: ROW-007 ROW-010 ROW-014 ROW-019 RULE-001..RULE-003 HOS-002 HOS-004 SEAM-001 HOS-005 | lane: devagent'
# toy <mode>: stage 0 in three steps, committed, the mode answered, the applied version its commit
toy() { cd "$T"; rm -rf p; pt_toy "$T/p"
  awk '{ print } /^row: ROW-004 -> STAGE-0$/ { print "row: ROW-006 -> STAGE-0" }' STAGES.md > "$T/s" && cat "$T/s" > STAGES.md
  pt_set 'step S01' "$S01"; pt_after 'step S01' "$S07"; pt_after 'step S01' "$S06"; pt_set 'step S03' "$S03"
  git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'stage 0 in three steps'
  printf 'setup-answered key=github-mode value="%s" words="that one" at=2026-11-19T09:00:00Z\n' "$1" >> .vid/plan/setup
  printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
  mkdir -p .vid/tw; git rev-parse HEAD > .vid/tw/applied; }
toy manual; sh "$CHECKS/stages.sh" scope --upto 0 > "$T/out" 2>&1 || true; ok '^ROW-006$'
pt_check; [ "$PT_RC" = 0 ] || fail "in manual three stage-0 steps, one the skeleton, are flagged ($PT_RC)"
toy auto; pt_check; [ "$PT_RC" = 1 ] || fail "in auto three stage-0 steps passed ($PT_RC)"
ok '^skeleton S06 — is in stage 0; stage 0 holds the skeleton alone'; ok '^skeleton S07 — is in stage 0'; ok '^skeleton S01 — lacks ROW-004'
# manual's own flags: one skeleton, building on nothing, every stage-0 row in a stage-0 step
toy manual; pt_set 'step S06' "$(printf %s "$S06" | sed 's/$/ | kind: skeleton/')"; pt_check
[ "$PT_RC" = 1 ] && ok '^skeleton S06 — a second step of kind: skeleton' || fail "a second skeleton passed in manual ($PT_RC)"
toy manual; pt_set 'step S01' "$(printf %s "$S01" | sed 's/builds-on: -/builds-on: S06/')"; pt_check
[ "$PT_RC" = 1 ] && ok '^skeleton S01 — builds on S06' || fail "a skeleton building on a step passed in manual ($PT_RC)"
toy manual; pt_del 'step S07'; pt_check
[ "$PT_RC" = 1 ] && ok '^place ROW-006 — in no step$' || fail "a stage-0 row in no step passed in manual ($PT_RC)"
toy manual; pt_del 'step S07'; pt_set 'step S03' "$(printf %s "$S03" | sed 's/rows: /rows: ROW-006 /')"; pt_check
[ "$PT_RC" = 1 ] && ok '^place ROW-006 — in step S03 of stage 1; its own stage is 0$' || fail "a stage-0 row in a stage-1 step passed in manual ($PT_RC)"
exit 0
