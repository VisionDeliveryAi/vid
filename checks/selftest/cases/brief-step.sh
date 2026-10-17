#!/bin/sh
# Purpose: selftest case — builder briefs name their step; test-author
# briefs are outside the rules (v0.9.6 spec 3.2, R2, R6; §7 case 22).
# Under a recorded plan: a builder brief without `step:`, one naming an
# unknown step, and one whose `## 1` rows are not all its step's are each
# refused by the brief check. Two test-author briefs for rows of two
# unstarted 40-row steps, under the default ceiling of 60 and with their
# prerequisite red, are both checked ok — and no step starts (no
# `step-start` event). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "brief-step: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; rows s2 3 42; rows s3 43 82; commit_all rows
plan 'step S1 | name: base | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: orchestrator (one configuration line)' \
  'step S2 | name: second | modules: app/s2 | builds-on: S1 | rows: ROW-003..ROW-042 | lane: builder' \
  'step S3 | name: third | modules: app/s3 | builds-on: S1 | rows: ROW-043..ROW-082 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'three steps' --trigger initial --expect 'the steps build in order' > /dev/null
rcpt r1 HEAD inline ROW-001=passed ROW-002=failed
chk() { if sh checks/brief.sh "$1" > "$T/out" 2>&1; then fail "accepted: $2"; fi; grep -qF -- "$3" "$T/out" || fail "the refusal of $2 does not say: $3"; }
brief .vid/briefs/1/builder-1.md builder - ROW-003; chk .vid/briefs/1/builder-1.md 'no step:' 'names its step in the header'
brief .vid/briefs/1/builder-2.md builder S9 ROW-003; chk .vid/briefs/1/builder-2.md 'an unknown step' 'step S9, which is no step of the plan'
brief .vid/briefs/1/builder-3.md builder S2 ROW-003 ROW-043; chk .vid/briefs/1/builder-3.md 'a row outside its step' 'not all rows of step S2: ROW-043'
brief .vid/briefs/1/test-author-1.md test-author - ROW-003 ROW-004
brief .vid/briefs/1/test-author-2.md test-author - ROW-043 ROW-044
sh checks/brief.sh .vid/briefs/1/test-author-1.md > "$T/out" 2>&1 || fail 'a test-author brief for an unstarted step was refused'
sh checks/brief.sh .vid/briefs/1/test-author-2.md > "$T/out" 2>&1 || fail 'the second test-author brief was refused'
grep -q '^step-start' .vid/metrics-events && fail 'a test-author brief started a step'
exit 0
