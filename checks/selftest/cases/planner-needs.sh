#!/bin/sh
# Purpose: selftest case — every row's needs, written down and held (v0.26.10.12.3.1 R10). On
# the planner's toy (fixtures/planner-toy.sh, a needs line per step) the plan is clean, and so is a row needing a step
# its step reaches through a chain (ROW-017 in S05 needs S01, by S02). Flagged `needs`, each by name: a row of a step in
# no needs line; a row in two; a needs id of a transition, of a record and of no row; a needed step that is no step, the
# row's own, or of a later stage; a row whose step does not build on its needed step, and the same with only a dashed
# link. plan.sh takes the needs lines (ticket mode). A recorded split that moves rows keeps the ratification while
# their needs hold; one that moves ROW-018 (needing S03) into a step not built on S03 ends `ratified`, and the recorded
# change that builds it on S03 brings it back. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-needs: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
clean() { pt_check; [ "$PT_RC" -eq 0 ] || fail "$1 is flagged"; }
nd() { pt_rs "s/^needs ROW-017 | .*/needs ROW-017 | $1/"; }   # ROW-017's needs, in S05 (stage 2, builds on S02)
fresh; clean 'the toy'; sh "$CHECKS/plan.sh" check > "$T/out" 2>&1 || fail 'plan.sh refuses the needs lines'
nd S01; clean 'a need reached through a chain'
fresh; pt_rs '/^needs ROW-017 /d'; pt_check; pt_has 'needs ROW-017 — in step S05, and in no needs line'
fresh; pt_after 'step S05' 'needs ROW-017 | -'; pt_check; pt_has 'needs ROW-017 — in two needs lines'
fresh; pt_after 'step S05' 'needs ROW-004-T1 DIF-003 ROW-099 | -'; pt_check
pt_has 'needs ROW-004-T1 — a transition; its journey stands for it'; pt_has 'needs DIF-003 — a record'; pt_has 'needs ROW-099 — no row of the inventory'
fresh; nd S09; pt_check; pt_has 'needs ROW-017 — needs S09, which is no step'
fresh; nd S05; pt_check; pt_has 'needs ROW-017 — needs S05, its own step'
fresh; pt_rs 's/^\(needs ROW-002 .*\)| -$/\1| S05/'; pt_check; pt_has 'needs ROW-002 — needs S05, a step of stage 2, later than its own stage 1'
fresh; nd S03; pt_check; pt_has 'needs ROW-017 — ROW-017 in S05 needs S03, which S05 does not build on'
grep -q 'only a dashed link' "$T/out" && fail 'a step with no fakes: is said to have a dashed link'
pt_rs 's/^\(step S05 .*\)$/\1 | fakes: S03/'; pt_check; pt_has 'needs ROW-017 — ROW-017 in S05 needs S03, which S05 does not build on; only a dashed link'
# a recorded split: kept while the needs hold, ended when one does not
pl() { sh "$CHECKS/planner.sh" "$@" > "$T/out" 2>&1; }
ch() { sh "$CHECKS/plan.sh" change "$@" > "$T/out" 2>&1 || fail "plan.sh change $1 was refused"; }
printf 'none\n' > "$T/none"
fresh; pt_rs 's/^needs ROW-002 ROW-009 ROW-011 ROW-018 /needs ROW-002 ROW-009 ROW-011 /'; pt_after 'step S05' 'needs ROW-018 | S03'; pt_record
pl review --in "$T/none"; pl page; pl ratify --words 'yes' || fail 'the toy with ROW-018 needing S03 was refused'
S4='step S04 | name: limits and backups | modules: digest ingest | builds-on: S02 S03 | rows: ROW-002 ROW-009 ROW-011 HOS-003'
pt_set 'step S04' "$S4 ROW-018 | lane: devagent"; pt_after 'step S04' 'step S06 | name: the data move | modules: digest | builds-on: S02 S03 | rows: DIF-001 RULE-004 | lane: devagent'
ch split 'S04 in two' --trigger discovered-dependency --evidence step:S04 --expect 'two smaller tickets'; pl ratified || fail 'a recorded split whose needs hold ends the ratification'
pt_set 'step S04' "$S4 DIF-001 RULE-004 | lane: devagent"; pt_set 'step S06' 'step S06 | name: the failure log | modules: digest | builds-on: S02 | rows: ROW-018 | lane: devagent'
ch rows 'ROW-018 to S06' --trigger discovered-dependency --evidence step:S06 --expect 'the log alone'
if pl ratified; then fail 'ratified holds with ROW-018 in a step not built on S03'; fi; grep -q 'needs ROW-018 — ROW-018 in S06 needs S03' "$T/out" || fail 'the broken need is not named'
pt_set 'step S06' 'step S06 | name: the failure log | modules: digest | builds-on: S02 S03 | rows: ROW-018 | lane: devagent'
ch other 'S06 builds on S03' --trigger discovered-dependency --evidence step:S06 --expect 'ROW-018 can pass'; pl ratified || fail 'the recorded fix does not bring the ratification back'
exit 0
