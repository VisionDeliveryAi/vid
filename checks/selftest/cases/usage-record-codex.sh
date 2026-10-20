#!/bin/sh
# Purpose: selftest case — a Codex job's usage in four kinds (v0.26.10.6 spec R17b). The job fixture with the fake
# Codex (ok: two turns, 1000 then 3000 input of which 0 then 2000 cached, 5 output each). Convicts unless `run`
# writes `job-exit` and then `usage agent=codex:1-builder-1 session=- tool=codex model=default effort=default
# calls=unknown input=2000 cache-read=2000 cache-write=0 cache-write-1h=0 output=10 scope=agent` — Codex's cached
# input taken out of its input, never counted twice. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "usage-record-codex: $*" >&2; cat "$T/out" >&2 2>/dev/null; grep -E '^(job-exit|usage) ' .vid/metrics-events >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
sh checks/job.sh start --brief "$B" > "$T/out" 2>&1 || fail 'start refused'
FAKE_CODEX=ok sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1 || fail 'run failed'
L=$(grep -nE '^(job-exit|usage) ' .vid/metrics-events)
printf '%s\n' "$L" | sed -n 1p | grep -q ':job-exit try=1-builder-1 ' || fail 'job-exit is not written before usage'
printf '%s\n' "$L" | sed -n 2p | grep -qE ':usage agent=codex:1-builder-1 session=- tool=codex model=default effort=default calls=unknown input=2000 cache-read=2000 cache-write=0 cache-write-1h=0 output=10 scope=agent at=[0-9TZ:-]+$' || fail "the usage record is not the events' sums: $L"
[ "$(grep -c '^usage ' .vid/metrics-events)" -eq 1 ] || fail 'not exactly one usage record'
exit 0
