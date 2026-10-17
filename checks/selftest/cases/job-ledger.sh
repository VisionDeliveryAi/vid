#!/bin/sh
# Purpose: selftest case — one shared test ledger (v0.9.7.1 spec 3.9, R9; owner 2026-10-12, the 22:32 collision).
# The job fixture. Convicts unless `run` refuses to launch when the worktree's home doesn't resolve to the run's
# (its .vid/home removed), naming home-of, and launches nothing; and `status` reports a ticket carrying the try
# under the worktree's own .vid/requests/ as a `coordination fault`, recorded once as an incident. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "job-ledger: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
mv .vid/RUN-STATE.md "$T/rs"
sh checks/job.sh start --brief "$B" > /dev/null 2>&1 || fail 'start'
WT=$(sed -n 's/^worktree=//p' .vid/jobs/1-builder-1); rm -f "$WT/.vid/home"
if FAKE_CODEX=ok sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1; then fail 'a job whose ledger is not the run'"'"'s launched'; fi
grep -q 'home-of' "$T/out" || fail 'the refusal does not name home-of'
grep -q '^pgid=' .vid/jobs/1-builder-1 && fail 'something was launched'
mv "$T/rs" .vid/RUN-STATE.md
mkdir -p "$WT/.vid/requests/20990101T000000Z-dddd"; printf 'type=iterate\nrole=builder\ntry=1-builder-1\n' > "$WT/.vid/requests/20990101T000000Z-dddd/request"
sh checks/job.sh status 1-builder-1 > "$T/out" 2>&1 || fail 'status failed'
grep -q '^coordination fault: 1-builder-1' "$T/out" || fail 'the stray ticket is not a coordination fault'
sh checks/job.sh status 1-builder-1 > /dev/null 2>&1
[ "$(grep -c '^incident .*coordination-fault' .vid/metrics-events)" = 1 ] || fail 'the incident is not recorded once'
exit 0
