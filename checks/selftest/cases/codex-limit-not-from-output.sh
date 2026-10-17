#!/bin/sh
# Purpose: selftest case — a Codex limit is never read from what Codex read (v0.9.7.3 spec 3.9, R9; live run
# 2026-10-13: a builder grepped a test defining _literal_rate_limited_registration and four completed jobs paused
# builders). The job fixture's fake Codex prints a command output, an agent message and a non-fatal error item naming
# rate_limit and a usage limit with a reset time, then turn.completed: the job exits `reason=exit` and builders are
# not paused; the same records then a failing exit whose stderr names no limit: still `reason=exit`, not paused.
# job-codex-limit (a top-level error event) still pauses. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -f "$T/hold"; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "codex-limit-not-from-output: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
sh checks/job.sh start --brief "$B" > /dev/null 2>&1 || fail 'start'
FAKE_CODEX=output sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1 || fail 'run failed'
grep -q '^job-exit try=1-builder-1 exit=0 reason=exit ' .vid/metrics-events || fail "a completed job read a limit from command output: $(grep '^job-exit' .vid/metrics-events)"
grep -q '^builder-tool paused' .vid/metrics-events && fail 'builders were paused by a completed job'
grep -qx 'builder-tool=paused' .vid/budget && fail 'the budget says paused'
grep -q 'Builders are paused' "$T/out" && fail 'the run manager was told builders are paused'
jb_repo "$T/repo2" || fail 'fixture 2'
sh checks/job.sh start --brief "$B" > /dev/null 2>&1 || fail 'start 2'
FAKE_CODEX=output-fail sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1 || true
grep -q '^job-exit try=1-builder-1 exit=2 reason=exit ' .vid/metrics-events || fail "a failed job read a limit from command output: $(grep '^job-exit' .vid/metrics-events)"
grep -q '^builder-tool paused' .vid/metrics-events && fail 'builders were paused by a failed job naming no limit in its failure records'
exit 0
