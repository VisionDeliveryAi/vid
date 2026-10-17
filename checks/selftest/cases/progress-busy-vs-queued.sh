#!/bin/sh
# Purpose: selftest case — busy counts only environments held (v0.9.8.1 R35, F-25). A toy develop run, stacks=2: one
# live run folder holding slot 1, one live run folder still waiting for a slot (no slot= yet), one whose process is
# gone, and two tickets queued. Convicts unless the Tests row reads `1 of 2 environments busy · 2 queued`; with
# nothing queued the queue is not shown. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; kill "$LP" 2>/dev/null; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-busy-vs-queued: $*" >&2; grep '^| Tests' "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 2; commit_all rows
plan 'step S1 | name: one | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-002 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one' --trigger initial --expect x > /dev/null
printf 'stacks=2\n' > .vid/budget
sleep 600 & LP=$!
mkdir -p .vid/runs/held .vid/runs/waiting .vid/runs/dead
printf 'pid=%s\nstart=%s\nslot=1\nproject=vid-s1-repo\n' "$LP" "$(date +%s)" > .vid/runs/held/holder
printf 'pid=%s\nstart=%s\nkind=scoped\n' "$LP" "$(date +%s)" > .vid/runs/waiting/holder
printf 'pid=99999999\nstart=%s\nslot=2\n' "$(date +%s)" > .vid/runs/dead/holder
for t in q1 q2; do mkdir -p ".vid/requests/$t"; echo queued > ".vid/requests/$t/state"; done
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep '^| Tests |' "$T/out" | grep -q '| 1 of 2 environments busy · 2 queued ' || fail 'busy is not the held environments, the queue apart'
for t in q1 q2; do echo done > ".vid/requests/$t/state"; done
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep '^| Tests |' "$T/out" | grep -q '| 1 of 2 environments busy · ' && ! grep '^| Tests |' "$T/out" | grep -q 'queued' || fail 'an empty queue is shown'
exit 0
