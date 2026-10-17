#!/bin/sh
# Purpose: selftest case — a dead supervisor (v0.9.7.1 spec 3.9, R9). The job fixture. A job record names a live
# process group (a sleeping process in its own session) and its start time, with no supervisor alive. Convicts
# unless `stop` signals the group, confirms it gone, saves the work and records `job-stop … saved=yes`; and, a
# second job whose record lacks the start time, `stop` saves nothing, keeps the worktree and records
# `job-recovery-required try=… reason=no-identity`; and `open` lists jobs not collected and cleaned. Env: CHECKS.
set -eu
T=$(mktemp -d); P2=''; trap '[ -z "$P2" ] || kill -KILL -- "-$P2" 2>/dev/null; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "job-recovery: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
sh checks/job.sh start --brief "$B" > /dev/null 2>&1 || fail 'start'
WT=$(sed -n 's/^worktree=//p' .vid/jobs/1-builder-1); printf 'half\n' >> "$WT/lib/a.txt"
perl -e 'use POSIX (); POSIX::setsid(); exec "sleep", "120"' & P=$!; sleep 0.5
printf 'pgid=%s\npid-start=%s\nsupervisor=999999\nsupervisor-start=never\n' "$P" "$(ps -o lstart= -p $P | sed 's/^ *//')" >> .vid/jobs/1-builder-1
sh checks/job.sh open | grep -q '^job 1-builder-1: process alive' || fail 'open does not list the live job'
sh checks/job.sh stop 1-builder-1 > "$T/out" 2>&1 || fail 'recovery stop failed'
kill -0 "$P" 2>/dev/null && fail 'the group was not stopped'
grep -q '^job-stop try=1-builder-1 saved=yes ' .vid/metrics-events || fail 'no saved job-stop'
[ -f .vid/continuations/S1/1-builder-1/manifest ] || fail 'nothing saved'
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'brief 2'
sh checks/job.sh start --brief "$(bw_out)" > /dev/null 2>&1 || fail 'start 2'
perl -e 'use POSIX (); POSIX::setsid(); exec "sleep", "120"' & P2=$!; sleep 0.5
printf 'pgid=%s\nsupervisor=999999\n' "$P2" >> .vid/jobs/1-builder-2
if sh checks/job.sh stop 1-builder-2 > "$T/out" 2>&1; then fail 'a stop without identity claimed success'; fi
grep -q '^job-recovery-required try=1-builder-2 reason=no-identity ' .vid/metrics-events || fail 'no job-recovery-required'
[ ! -d .vid/continuations/S1/1-builder-2 ] || fail 'a stop without identity saved'
[ -d "$(sed -n 's/^worktree=//p' .vid/jobs/1-builder-2)" ] || fail 'the worktree was not kept'
kill -0 "$P2" || fail 'a process without a confirmed identity was signalled'
exit 0
