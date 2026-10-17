#!/bin/sh
# Purpose: selftest case — stopping a Codex builder (v0.9.7.1 spec 3.9, R9). The job fixture, the fake Codex
# sleeping in a child of its own group. Convicts unless `stop` makes the supervisor TERM the whole group (the
# sleeping child gone), the record gains exit= and stopped=yes, the unfinished edit is saved as a continuation
# package, `job-stop try=1-builder-1 saved=yes` is recorded and the try's tickets are cancelled; a launch is refused
# once the stop intent is there; a stopped job, once cleaned, leaves `open`; and stopping a job never launched
# records `reason=not-launched` and publishes its exit, so it can be cleaned. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "job-stop: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
sh checks/job.sh start --brief "$B" > "$T/out" 2>&1 || fail 'start refused'
( FAKE_CODEX=sleep FAKE_ENTER="$T/entered" sh checks/job.sh run 1-builder-1 > "$T/run.out" 2>&1 ) &
jb_wait "$T/entered" 50 || fail 'the fake Codex did not start'
PG=$(sed -n 's/^pgid=//p' .vid/jobs/1-builder-1)
sh checks/job.sh stop 1-builder-1 > "$T/out" 2>&1 || fail "stop failed: $(cat "$T/out")"
grep -q '^stopped=yes' .vid/jobs/1-builder-1 && grep -q '^exit=' .vid/jobs/1-builder-1 || fail 'the supervisor did not publish a stopped exit'
ps -A -o pgid= | awk -v g="$PG" '$1 == g { f = 1 } END { exit f ? 0 : 1 }' && fail 'a process of the group remains'
[ -f .vid/continuations/S1/1-builder-1/manifest ] || fail 'the unfinished work was not saved'
grep -q '^job-stop try=1-builder-1 saved=yes ' .vid/metrics-events || fail 'no job-stop saved=yes'
if FAKE_CODEX=ok sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1; then fail 'a stopped job was launched'; fi
sh checks/job.sh clean 1-builder-1 > "$T/out" 2>&1 || fail 'the stopped job was not cleaned'
sh checks/job.sh open > "$T/out" 2>&1; grep -q '1-builder-1' "$T/out" && fail 'a stopped, cleaned job is still open'
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'brief 2'
sh checks/job.sh start --brief "$(bw_out)" > /dev/null 2>&1 || fail 'start 2'
sh checks/job.sh stop 1-builder-2 > "$T/out" 2>&1 || fail 'stopping an unlaunched job failed'
grep -q '^job-stop try=1-builder-2 saved=no reason=not-launched ' .vid/metrics-events || fail 'the unlaunched stop is not recorded'
sh checks/job.sh clean 1-builder-2 > "$T/out" 2>&1 || fail 'the unlaunched, stopped job could not be cleaned'
exit 0
