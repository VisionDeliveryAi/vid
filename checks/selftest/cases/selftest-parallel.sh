#!/bin/sh
# Purpose: selftest case — the parallel runner judges as the serial one (selftest-parallel). A toy suite of one case
# that convicts and one that fails to convict, run with VID_SELFTEST_WORKERS=1 (one after another) and =4 (side by
# side): each case runs once in each, the two outputs are the same lines in the same order, and both runs are
# refused with the same exit status. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/retry.sh"
fail() { echo "selftest-parallel: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rt_suite "$T/p"
rt_case cases/a-ok.sh ok; rt_case cases/b-bad.sh fail
R1=0; VID_SELFTEST_WORKERS=1 sh checks/selftest/run.sh > "$T/out1" 2>&1 || R1=$?
[ "$(rt_ran cases/a-ok.sh)" -eq 1 ] && [ "$(rt_ran cases/b-bad.sh)" -eq 1 ] || fail 'the serial run did not run each case once'
: > "$T/ran"
R4=0; VID_SELFTEST_WORKERS=4 sh checks/selftest/run.sh > "$T/out4" 2>&1 || R4=$?
[ "$(rt_ran cases/a-ok.sh)" -eq 1 ] && [ "$(rt_ran cases/b-bad.sh)" -eq 1 ] || fail 'the parallel run did not run each case once'
cat "$T/out1" "$T/out4" > "$T/out"
grep -qx 'selftest: a-ok convicts' "$T/out1" && grep -q '^selftest: b-bad FAILED TO CONVICT' "$T/out1" || fail 'the serial verdicts are not the planted ones'
cmp -s "$T/out1" "$T/out4" || fail 'the parallel output differs from the serial one'
[ "$R1" -ne 0 ] && [ "$R1" -eq "$R4" ] || fail "the exit statuses differ or pass: serial $R1, parallel $R4"
exit 0
