#!/bin/sh
# Purpose: selftest case — dashed links and steps with no rows (v0.26.10.12.3.1 R2). On the
# planner's toy (fixtures/planner-toy.sh) a step's `fakes:` naming no step, the step itself, or a step it also builds
# on is flagged `step`; a dashed link to an earlier step it does not build on, or to a later step (it holds nothing),
# and `fakes: -` are clean, and plan.sh check takes each in ticket mode. A step with `rows: -` is flagged as before:
# planner.sh's `holds no row` and plan.sh's refusal of `-` as no row id; an empty rows: is `form <s> — no rows:`.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-links: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
fk() { pt_rs "s/^\(step $1 .*\)\$/\1 | fakes: $2/"; }
clean() { pt_check; [ "$PT_RC" -eq 0 ] || fail "$1 is flagged"
  sh "$CHECKS/plan.sh" check > "$T/out" 2>&1 || fail "plan.sh refuses $1"; }
fresh; fk S05 S09; pt_check; pt_has 'step S05 — fakes S09, which is no step'
fresh; fk S05 S05; pt_check; pt_has 'step S05 — fakes itself'
fresh; fk S04 'S03 S02'; pt_check; pt_has 'step S04 — fakes S03, which it also builds on'; pt_has 'step S04 — fakes S02, which it also builds on'
fresh; fk S05 S03; clean 'a dashed link to an earlier step it does not build on'
fresh; fk S03 S05; clean 'a dashed link to a later step'
fresh; fk S02 -; clean 'fakes: -'
# a step with no rows stays refused
fresh; pt_rs 's/^\(step S05 .*\)rows: ROW-017/\1rows: -/'; pt_check; pt_has 'step S05 — holds no row'
RC=0; sh "$CHECKS/plan.sh" check > "$T/out" 2>&1 || RC=$?; [ "$RC" != 0 ] && grep -q "'-' is neither a ROW id nor a range" "$T/out" || fail 'plan.sh takes rows: -'
fresh; pt_rs 's/^\(step S05 .*\)rows: ROW-017/\1rows:/'; pt_check; pt_has 'form S05 — no rows:'
exit 0
