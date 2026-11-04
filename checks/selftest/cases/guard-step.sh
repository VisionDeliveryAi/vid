#!/bin/sh
# Purpose: selftest case — no product code before a step since develop's stage start (v0.26.10.24 R4). A gated develop
# run with a plan, under the real hook, placement app/. At the home app/x.py is refused, naming plan.sh start; after
# `plan.sh start S1-step` it passes. A takeover (a second develop start) refuses it again; `start` on the started step
# writes step-resumed, and it passes. A step-start in the same second as, but before, the develop start in the file
# refuses it. Session S2 and no session are refused as S1. A builder's checkout passes; `mode: tickets` passes, and
# `start` on a started step writes nothing there. Env: CHECKS.
set -eu
unset VID_ROLE
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "guard-step: $*" >&2; cat "$T/out" .vid/metrics-events >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2
printf '# Law\n\n```vid-placement\napp/\n```\n' > CLAUDE.md
mkdir -p checks/hooks
for c in placement conformance; do printf '#!/bin/sh\n# Purpose: stub court %s\nexit 0\n' "$c" > "checks/$c.sh"; done
cp "$CHECKS/hooks/pre-commit" checks/hooks/pre-commit; printf '# stub lawfiles\n' > checks/lawfiles
commit_all 'the hook and the law'
plan 'step S1-step | name: first | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'the plan' --trigger initial --expect 'it builds' > /dev/null
hook() { rm -rf "$(git rev-parse --git-path vid-memo)"; R=0; sh checks/hooks/pre-commit > "$T/out" 2>&1 || R=$?; }
try() { printf '# Purpose: x\n' > app/x.py; g add app/x.py; hook; g rm -q --cached app/x.py; rm -f app/x.py; }
refused() { try; [ "$R" -eq 1 ] || fail "app/x.py was not refused: $1"; }
passes() { try; [ "$R" -eq 0 ] || fail "app/x.py was refused: $1"; }
export CLAUDE_CODE_SESSION_ID=S1
refused 'no step started'
grep -q 'no step started since its stage start: app/x.py (and 0 more)' "$T/out" && grep -q 'sh checks/plan.sh start <id>' "$T/out" || fail 'the refusal does not name the path and plan.sh start'
grep -q '^refused phase=pre-commit by=no-plan-step ' .vid/metrics-events || fail 'no refused event by=no-plan-step'
sh checks/plan.sh start S1-step > "$T/out" 2>&1 || fail 'the step was not admitted'
grep -q '^step-start step=S1-step ' .vid/metrics-events || fail 'no step-start'
passes 'the step started'
printf 'stage name=develop state=start session=S1 records=29 at=%s\n' "$(utcnow)" >> .vid/metrics-events
refused 'a takeover, no step since'
sh checks/plan.sh start S1-step > "$T/out" 2>&1 || fail 'the started step was not admitted'
[ "$(grep -c '^step-start ' .vid/metrics-events)" -eq 1 ] || fail 'a second step-start was written'
grep -qE '^step-resumed step=S1-step plan=[0-9a-f]{12} at=' .vid/metrics-events || fail 'no step-resumed'
passes 'the step resumed'
A=$(utcnow); printf 'step-start step=S2 plan=x at=%s\nstage name=develop state=start session=S1 records=29 at=%s\n' "$A" "$A" >> .vid/metrics-events
refused 'a step-start in the same second, before the develop start in the file'
CLAUDE_CODE_SESSION_ID=S2; refused 'another session'
unset CLAUDE_CODE_SESSION_ID; refused 'no session'
export CLAUDE_CODE_SESSION_ID=S1
g worktree add -q "$T/wt" -b builder
( cd "$T/wt"; mkdir -p .vid; printf '%s\n' "$T/repo" > .vid/home
  printf '# Purpose: x\n' > app/x.py; g add app/x.py; sh checks/hooks/pre-commit > "$T/out" 2>&1 ) || fail "a builder's checkout was refused"
awk '{ print } /^plan: required$/ { print "mode: tickets" }' .vid/RUN-STATE.md > "$T/rs"; cp "$T/rs" .vid/RUN-STATE.md
passes 'mode: tickets'
printf 'stage name=plan state=start session=S1 at=%s\n' "$(utcnow)" >> .vid/metrics-events
N=$(grep -c '^step-resumed ' .vid/metrics-events)
sh checks/plan.sh start S1-step > "$T/out" 2>&1 || fail 'the started step was not admitted in ticket mode'
grep -q 'already started' "$T/out" || fail 'plan.sh start did not read a started step in ticket mode'
[ "$(grep -c '^step-resumed ' .vid/metrics-events)" -eq "$N" ] || fail 'step-resumed was written in ticket mode'
exit 0
