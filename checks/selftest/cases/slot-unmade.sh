#!/bin/sh
# Purpose: selftest case — a free slot the host folder cannot make ends the try with no admission (FB-2 C2's ruling: in
# take_slot, a failed mkdir with no folder there is no admission to make, never a look again). The gated-run fixture, one slot,
# none held; the slot's path stack.1 is a plain file, so its mkdir fails and no folder is there. A queued request (a builder's,
# its queue bound short) must stay `queued` with its holders file written, the admission lock freed and no slot folder made, and
# must end inside its bound refused, naming every slot held. Without the ruling's line the try looks again for ever, holding the
# admission lock, and the request neither writes its holders file nor ends. Env: CHECKS.
set -eu
T=$(mktemp -d); TD=''
# the request's own processes, read from its own folder, are stopped when the case ends: a try that hangs must not outlive it
stopit() { [ -n "$TD" ] || return 0; for f in pid watcher supervisor; do p=$(cat "$TD/$f" 2>/dev/null || true); case $p in ''|*[!0-9]*) ;; *) kill "$p" 2>/dev/null || true ;; esac; done; }
trap 'set +e; stopit; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
fail() { echo "slot-unmade: $*" >&2; cat "$T/out" >&2 2>/dev/null; cat "$TD/log" >&2 2>/dev/null; exit 1; }
gated_repo "$T/repo"; gate_on
H=$T/run/vid-host; mkdir -p "$H"; : > "$H/stack.1"   # the slot's path, a plain file: its mkdir fails, and no folder is there
VID_REQUEST_QUEUE=8 sh checks/test.sh request --type iterate --role builder --try t1 --rows ROW-001 --why 'the slot cannot be made' -- tests/a > "$T/out" 2>&1 || fail 'the request was refused'
B=$(sed -n 's/^next: sh checks\/test.sh wait //p' "$T/out"); [ -n "$B" ] || fail 'the request named no ticket'; TD=.vid/requests/$B
waitfor "$TD/holders" 6 || fail 'the try did not end: no holders file was written while the slot could not be made'
[ "$(cat "$TD/state")" = queued ] || fail "the request is $(cat "$TD/state"), not queued, after a try with no admission"
[ ! -e "$H/admit.lock" ] && [ ! -L "$H/admit.lock" ] || fail 'the admission lock was not freed after the try'
[ -f "$H/stack.1" ] && [ ! -d "$H/stack.1" ] || fail 'the slot was taken'
ls -d "$H"/stack.* | grep -qvx "$H/stack.1" && fail 'a slot folder was made'
RC=0; VID_WAIT_MAX=40 sh checks/test.sh wait "$B" > "$T/out" 2>&1 || RC=$?
[ "$RC" != 0 ] || fail 'the request ended admitted, with no slot made'
case $(cat "$TD/state") in queued|running) fail "the request is $(cat "$TD/state") past its queue bound: the try hangs" ;; esac
grep -q 'every slot is held' "$TD/log" || fail 'the request did not end refused, naming every slot held'
grep -q 'tests/a' "$STUB_LOG" 2>/dev/null && fail 'the request reached the harness'
exit 0
