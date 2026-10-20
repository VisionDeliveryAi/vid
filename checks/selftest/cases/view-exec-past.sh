#!/bin/sh
# Purpose: selftest case — execution now only, economics from what was recorded by T (v0.26.10.6 spec R14). The viewer
# fixture (a checkpoint at 11:20) with, planted after it: a return naming ROW-001 (kept at 10:45) accepted at 11:40 (its agent-returned and build-cost), a
# Codex job started at 11:00 and exited at 11:30 with its events file, and a request whose image build failed (no pass).
# Convicts unless the checkpoint's snapshot has `execution` null and its economics holds none of the three — the
# return is not among ROW-001's tries, the job has no usage entry, no build-failed pass — while now holds all three,
# and every snapshot passes the contract's check. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-exec-past: $*" >&2; exit 1; }
view_project "$T/repo"
mkdir -p .vid/briefs/1 .vid/jobs .vid/requests/20260101T110000Z-eeee
printf 'brief: .vid/briefs/1/builder-50.md\nROW-001 | pass | r2\n' > .vid/briefs/1/builder-50.return.md; vev 11:40 'agent-returned role=builder n=50 try=1-builder-50'; vev 11:40 'build-cost role=builder slice=1 step=S1 brief=.vid/briefs/1/builder-50.md rows=1 rows-passed=1 peak=5 total=9 before-change=unknown'
printf 'step=S2\ntry=1-builder-51\nbrief=.vid/briefs/1/builder-51.md\nmodel=default\neffort=default\n' > .vid/jobs/1-builder-51
printf '{"type":"turn.completed","usage":{"input_tokens":100,"cached_input_tokens":40,"output_tokens":7}}\n' > .vid/jobs/1-builder-51.events
vev 11:00 'job-start try=1-builder-51 step=S2'; vev 11:30 'job-exit try=1-builder-51 exit=0 reason=exit'
printf 'type=iterate\nrole=builder\nrows=1\ncreated=1767265200\n' > .vid/requests/20260101T110000Z-eeee/request; printf 'done\n' > .vid/requests/20260101T110000Z-eeee/state; : > .vid/requests/20260101T110000Z-eeee/build-failed
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
P="$T/out/20260101T112000Z-checkpoint.html"; N="$T/out/now.html"
[ -f "$P" ] || fail "no checkpoint snapshot: $(ls "$T/out")"
vdata "$P" | grep -qx '"execution":null,' || fail "the past snapshot's execution is not null"
vel "$N" '"execution":{' >/dev/null || fail "now has no execution"
vel "$P" '{"row":"ROW-001","kept":' | grep -o '{"row":"ROW-001","kept":[^]]*]' | grep -qF '1-builder-50' && fail 'the past snapshot counts a return accepted after its time'
vel "$N" '{"row":"ROW-001","kept":' | grep -o '{"row":"ROW-001","kept":[^]]*]' | grep -qF '"try":"1-builder-50"' || fail "now does not count the return among ROW-001's tries"
vel "$P" '"agent":"codex:1-builder-51"' && fail 'the past snapshot reads a job that exited after its time'
vel "$N" '"agent":"codex:1-builder-51"' | grep -qF '"kind":"kinds","input":60,"cacheRead":40,"cacheWrite":0,"cacheWrite1h":0,"output":7' || fail "now does not read the job's events: $(vel "$N" '"agent":"codex:1-builder-51"')"
vel "$P" '"outcome":"build-failed"' && fail 'the past snapshot holds a build-failed pass'
vel "$N" '{"ticket":"20260101T110000Z-eeee"' | grep -qF '"outcome":"build-failed"' || fail 'now does not hold the build-failed request'
for f in "$T"/out/*.html; do sh "$VIEWER_SH" --check "$f" > "$T/c" 2>&1 || fail "$(basename "$f") fails the check: $(head -5 "$T/c")"; done
exit 0
