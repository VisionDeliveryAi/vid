#!/bin/sh
# Purpose: selftest case — a retry that fails again refuses (v0.9.8.1 R1). A listed case that fails every time runs
# exactly twice; the run is refused, says the retry failed, records `selftest-retried … result=failed`, and is not
# marked rescued. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/retry.sh"
fail() { echo "selftest-retry-second-fails: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rt_suite "$T/p"
rt_case cases/a-bad.sh fail; rt_case cases/c-ok.sh ok; rt_list cases/a-bad.sh
rt_run
[ "$RT" -ne 0 ] || fail 'a listed case that failed its retry was let through'
[ "$(rt_ran cases/a-bad.sh)" -eq 2 ] || fail 'the listed case did not run exactly twice'
grep -q 'cases/a-bad.sh FAILED TO CONVICT again on its retry' "$T/out" || fail 'the failed retry is not named'
grep -q '^selftest-retried case=cases/a-bad.sh result=failed at=' .vid/metrics-events || fail 'no selftest-retried result=failed event'
[ ! -f "$T/rescued" ] || fail 'a refused run was marked rescued'
exit 0
