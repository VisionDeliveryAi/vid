#!/bin/sh
# Purpose: selftest case — a ticket's `run` names a real folder (v0.9.8.1 R45, F-37). While a held request runs, its
# ticket's `run` names its run folder, which exists with its holder; once the run has ended and its folder is
# removed, `run` is gone with it — it never names a folder that is not there. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "ticket-run-folder-exists: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
touch "$T/hold"; export STUB_HOLD="$T/hold" STUB_ENTER="$T/entered"
sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'the run file' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
A=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); TD=.vid/requests/$A; waitfor "$T/entered" || fail 'the request did not start'
[ -s "$TD/run" ] || fail 'a running ticket has no run file'
R=$(cat "$TD/run"); [ -d "$R" ] && [ -f "$R/holder" ] || fail "the run file names a folder that is not there: $R"
rm -f "$T/hold"
VID_WAIT_MAX=60 sh checks/test.sh wait "$A" > "$T/out" 2>&1 || fail 'the run did not end green'
_i=0; while kill -0 "$(cat "$TD/supervisor" 2>/dev/null || echo 0)" 2>/dev/null && [ "$_i" -lt 30 ]; do sleep 1; _i=$((_i + 1)); done
[ ! -d "$R" ] || fail 'the run folder outlived its run'
[ ! -e "$TD/run" ] || [ -d "$(cat "$TD/run")" ] || fail 'the run file names a removed folder'
exit 0
