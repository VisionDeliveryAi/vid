#!/bin/sh
# Purpose: selftest case — only a listed flaky case is retried (v0.9.8.1 R1). A case on checks/selftest/flaky that
# fails once in the suite runs once more, alone: the run passes, names the retry, records `selftest-retried
# case=<path> result=convicts` and marks itself rescued; a case not on the list that fails the same way is never
# retried and the run is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/retry.sh"
fail() { echo "selftest-retry-listed-only: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rt_suite "$T/p"
rt_case cases/a-flaky.sh once; rt_case cases/c-ok.sh ok; rt_list cases/a-flaky.sh
rt_run
[ "$RT" -eq 0 ] || fail 'a listed case that convicts on its retry refused the run'
[ "$(rt_ran cases/a-flaky.sh)" -eq 2 ] || fail 'the listed case was not run exactly twice'
grep -q '^selftest: cases/a-flaky.sh convicts on its retry' "$T/out" || fail 'the retry is not named'
grep -q '^selftest-retried case=cases/a-flaky.sh result=convicts at=' .vid/metrics-events || fail 'no selftest-retried event'
grep -q 'rescued by a retry' "$T/out" && [ -f "$T/rescued" ] || fail 'the run does not say it was rescued'
# a case not on the list is never retried
rm -f "$T"/once.* "$T/rescued"; : > "$T/ran"; rt_case cases/b-plain.sh once
rt_run
[ "$RT" -ne 0 ] || fail 'an unlisted failure was let through'
[ "$(rt_ran cases/b-plain.sh)" -eq 1 ] || fail 'an unlisted case was retried'
[ ! -f "$T/rescued" ] || fail 'a refused run was marked rescued'
exit 0
