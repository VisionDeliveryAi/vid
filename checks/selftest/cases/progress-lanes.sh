#!/bin/sh
# Purpose: selftest case — the progress table counts started steps by lane
# (v0.9.7.0.9 spec 3.6, R9). The plan-run fixture. With four steps — S1
# `lane: builder`, S2 `lane: orchestrator (one configuration line)`, S3 no
# lane, S4 `lane: builder` — and step-starts for S1, S2 and S3 only, the
# Builders row of `sh checks/progress.sh` ends `lanes: builder 2 · run
# manager 1`: the unstarted step is not counted, the absent lane is a
# builder's. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-lanes: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 4; rows s3 5 6; rows s4 7 8; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001 ROW-002 | lane: builder' \
  'step S2 | name: second | modules: app/s2 | builds-on: - | rows: ROW-003 ROW-004 | lane: orchestrator (one configuration line)' \
  'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-005 ROW-006' \
  'step S4 | name: fourth | modules: app/s4 | builds-on: - | rows: ROW-007 ROW-008 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'four steps' --trigger initial --expect 'it builds' > "$T/out" 2>&1 || fail 'the plan was refused'
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed'
grep -q '^| Builders | none yet · lanes: builder 0 · run manager 0 |$' "$T/out" || fail "no started step is not 0 and 0: $(grep Builders "$T/out")"
for s in S1 S2 S3; do sh checks/plan.sh start $s > "$T/out" 2>&1 || fail "plan.sh start $s was refused"; done
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed'
grep -q '^| Builders | none yet · lanes: builder 2 · run manager 1 |$' "$T/out" || fail "the lanes are not builder 2 · run manager 1: $(grep Builders "$T/out")"
exit 0
