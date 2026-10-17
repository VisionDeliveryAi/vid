#!/bin/sh
# Purpose: selftest case — the supervisor runs a Codex builder to its end (v0.9.7.1 spec 3.9, R9). The job fixture
# with the fake Codex (ok). Convicts unless `run` prints `job 1-builder-1 exit=0 return=<the brief's return path>`;
# the record gains pgid, pid-start, the supervisor and exit=0; `job-exit try=1-builder-1 exit=0 reason=exit` is
# recorded; the events file holds Codex's JSON; `return … --agent codex:1-builder-1` says ok and records `build-cost
# … peak=unknown total=4000 before-change=unknown tool=codex`; `run` refuses a second launch; and `status` reports the
# process exited, the return present and collected. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/job.sh"
fail() { echo "job-run: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
jb_repo "$T/repo" || fail 'fixture'
sh checks/job.sh start --brief "$B" > "$T/out" 2>&1 || fail 'start refused'
RET=$(sed -n 's/^return: //p' "$B")
FAKE_CODEX=ok sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1 || fail 'run failed'
grep -qx "job 1-builder-1 exit=0 return=$RET" "$T/out" || fail "the line is not the job's: $(cat "$T/out")"
J=.vid/jobs/1-builder-1; for k in pgid pid-start supervisor exit; do grep -q "^$k=" "$J" || fail "the record lacks $k="; done
grep -q '^job-exit try=1-builder-1 exit=0 reason=exit ' .vid/metrics-events || fail 'no job-exit event'
grep -q '"turn.completed"' .vid/jobs/1-builder-1.events || fail 'the events file is not Codex'"'"'s JSON'
sh checks/brief.sh return "$RET" --agent codex:1-builder-1 > "$T/out" 2>&1 || fail 'the Codex return was refused'
grep -q '^build-cost role=builder .* peak=unknown total=4000 before-change=unknown tool=codex model=default effort=default ' .vid/metrics-events || fail "the Codex cost is not read from its events: $(grep '^build-cost' .vid/metrics-events)"
if FAKE_CODEX=ok sh checks/job.sh run 1-builder-1 > "$T/out" 2>&1; then fail 'a second launch was taken'; fi
sh checks/job.sh status 1-builder-1 > "$T/out" 2>&1 || fail 'status failed'
grep -q 'process exited 0 · return present · collected yes · cleaned no' "$T/out" || fail "status: $(cat "$T/out")"
sh checks/job.sh clean 1-builder-1 > "$T/out" 2>&1 || fail 'clean failed'
grep -q '^job-cleaned try=1-builder-1 ' .vid/metrics-events || fail 'no job-cleaned'
[ -z "$(sh checks/job.sh open)" ] || fail 'a collected and cleaned job is still open'
exit 0
