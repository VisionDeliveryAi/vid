#!/bin/sh
# Purpose: selftest case — admission plans the current stage only (v0.26.10.5 spec R6, R7; §5 plan-stage-admission).
# A gated toy run of two stages (fixtures/stages.sh) at `stage: 1`: a step of stage-1 rows is admitted; a step
# holding a stage-2 row (ROW-004) is refused, naming it, and `refused … by=stage` is recorded; recording a
# pull-forward (its plan change, decision and event) admits nothing more — still refused. At `stage: 2` the same
# step is admitted. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "plan-stage-admission: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"
cp "$CHECKS/stages.sh" checks/
st_files; commit_all 'the toy product'
printf 'stage: 1\n' >> .vid/RUN-STATE.md
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002' \
     'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-004' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'stage 1 first' > "$T/out" 2>&1 || fail 'the plan was not recorded'
sh checks/plan.sh start S1 > "$T/out" 2>&1 || fail 'a step of stage-1 rows was refused'
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'a step holding a stage-2 row was admitted in stage 1'; fi
grep -q 'S2 holds rows outside stages 1 to 1 (the current stage): ROW-004' "$T/out" || fail 'the refusal does not name ROW-004'
grep -q '^refused phase=admission by=stage .* step=S2 ' .vid/metrics-events || fail 'no refused … by=stage event'
# a pull-forward recorded: the plan change, the decision and the event — no exception follows
sh checks/plan.sh change rows 'the share check is needed by S1' --trigger discovered-dependency --evidence step:S1 --expect 'the minimum piece only' > "$T/out" 2>&1 || fail 'the pull-forward plan change was refused'
printf 'pull-forward step=S1 decision=D-001 at=%s\n' "$(utcnow)" >> .vid/metrics-events
if sh checks/plan.sh start S2 > "$T/out" 2>&1; then fail 'a pull-forward admitted a stage-2 row'; fi
grep -q 'ROW-004' "$T/out" || fail 'the second refusal does not name ROW-004'
# the next stage: its steps are admitted
sed 's/^stage: 1$/stage: 2/' .vid/RUN-STATE.md > .vid/rs && mv .vid/rs .vid/RUN-STATE.md
sh checks/plan.sh start S2 > "$T/out" 2>&1 || fail 'at stage 2 the stage-2 step was refused'
exit 0
