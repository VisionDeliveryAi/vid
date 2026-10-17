#!/bin/sh
# Purpose: selftest case — Codex runs out (v0.9.7.1 spec 3.9, R9; owner 2026-10-11). The job fixture, the fake
# Codex exiting with its usage-limit error. Convicts unless the exit is `job-exit … reason=codex-limit`; the
# unfinished work is saved; a queued ticket of the try is cancelled; builder-tool becomes `paused` with
# `builder-tool paused reason=codex-limit reset=3:05_PM`; the run manager's line says Builders are paused; no
# builder is spawned on either tool (a Codex job refused, a builder brief refused); and only after `tool claude
# --by owner` a builder brief is written again. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -f "$T/hold"; rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "job-codex-limit: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
sh checks/job.sh start --brief "$B" > /dev/null 2>&1 || fail 'start'
mkdir -p .vid/requests/20990101T000000Z-cccc; printf 'type=iterate\nrole=builder\ntry=1-builder-1\n' > .vid/requests/20990101T000000Z-cccc/request; echo queued > .vid/requests/20990101T000000Z-cccc/state
FAKE_CODEX=limit sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1 || fail 'run failed'
grep -q '^job-exit try=1-builder-1 exit=1 reason=codex-limit ' .vid/metrics-events || fail 'the exit is not codex-limit'
[ -f .vid/continuations/S1/1-builder-1/manifest ] || fail 'the work was not saved'
[ -f .vid/requests/20990101T000000Z-cccc/cancel ] || fail 'the try'"'"'s ticket was not cancelled'
grep -qx 'builder-tool=paused' .vid/budget || fail 'builders are not paused'
grep -q '^builder-tool paused reason=codex-limit reset=3:05_PM ' .vid/metrics-events || fail "no paused event with the reset: $(grep 'builder-tool paused' .vid/metrics-events)"
grep -q 'Builders are paused' "$T/out" || fail 'the run manager is not told'
bw_write --role builder --slice 1 --step S1 --rows ROW-101 && fail 'a builder was briefed while paused'
grep -q 'builders are paused' "$T/wout" || fail 'the brief refusal does not say paused'
sh checks/job.sh tool claude --by owner > /dev/null || fail 'the owner'"'"'s switch failed'
bw_write --role builder --slice 1 --step S1 --rows ROW-101 || fail 'no builder brief after the owner'"'"'s word'
exit 0
