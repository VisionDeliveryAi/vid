#!/bin/sh
# Purpose: selftest case — a step's lane gives its reason (v0.9.7.0.9 spec
# 3.6, R7). The plan-run fixture. `plan.sh check` and `plan.sh change`
# refuse a bare `lane: orchestrator`, naming the step and the one edit —
# `step S2: lane orchestrator needs its reason — lane: orchestrator
# (<why>)` — and an empty reason and an unknown lane likewise; a change so
# refused records no plan-change. `lane: builder`, an absent lane (read as
# builder) and `lane: orchestrator (<why>)` pass, and the reader keeps the
# lane as written (`plan.sh parse`). A plan under way with a bare
# orchestrator lane is refused at its next check. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "plan-lane-reason: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; rows s3 5 6; commit_all rows
S1='step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 | lane: builder'
S3='step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-005 ROW-006'
SH="shared: $PLANS_SHARED"
refused() { # <lane text> <the refusal's words>
  plan "$S1" "step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003 ROW-004 | lane: $1" "$S3" "$SH"
  N0=$(grep -c '^plan-change ' .vid/metrics-events || true)
  if sh checks/plan.sh check > "$T/out" 2>&1; then fail "check passed lane: $1"; fi
  grep -qF "$2" "$T/out" || fail "check's refusal of lane: $1 does not say '$2'"
  if sh checks/plan.sh change create 'the plan' --trigger initial --expect 'it builds' > "$T/out" 2>&1; then fail "change accepted lane: $1"; fi
  grep -qF "$2" "$T/out" || fail "change's refusal of lane: $1 does not say '$2'"
  [ "$(grep -c '^plan-change ' .vid/metrics-events || true)" -eq "$N0" ] || fail "a refused change of lane: $1 recorded a plan-change"
}
refused 'orchestrator' 'step S2: lane orchestrator needs its reason — lane: orchestrator (<why>)'
refused 'orchestrator ()' 'step S2: lane orchestrator needs its reason — lane: orchestrator (<why>)'
refused 'orchestrator (  )' 'step S2: lane orchestrator needs its reason — lane: orchestrator (<why>)'
refused 'myself' "step S2: lane 'myself' is neither builder nor orchestrator (<why>)"
# the three forms that pass; the reader keeps the lane as written
plan "$S1" 'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003 ROW-004 | lane: orchestrator (resolving a merge)' "$S3" "$SH"
sh checks/plan.sh check > "$T/out" 2>&1 || fail 'check refused builder, an absent lane and orchestrator with a reason'
sh checks/plan.sh change create 'the plan' --trigger initial --expect 'it builds' > "$T/out" 2>&1 || fail 'change refused the three lanes that pass'
sh checks/plan.sh parse > "$T/out" 2>&1 || fail 'parse failed'
grep -qx "$(printf 'step\tS2\tsecond\tapp/s2\t-\torchestrator (resolving a merge)\t-')" "$T/out" || fail 'the reader did not keep the lane as written'
grep -qx "$(printf 'step\tS3\tthird\tapp/s3\t-\t-\t-')" "$T/out" || fail 'an absent lane is not read as -'
# a plan under way with a bare orchestrator: refused at its next check, the fix named
plan "$S1" 'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003 ROW-004 | lane: orchestrator' "$S3" "$SH"
if sh checks/plan.sh check > "$T/out" 2>&1; then fail 'a plan under way with a bare orchestrator lane passed its next check'; fi
grep -qF 'lane: orchestrator (<why>)' "$T/out" || fail 'the refusal does not name the edit'
exit 0
