#!/bin/sh
# Purpose: selftest case — a retry is by the exact path from checks/selftest/ (v0.9.8.1 R1). With cases/x/same.sh
# listed, a failing cases/y/same.sh (the same file name) is not retried; nor is a case listed by its bare file name or
# by a path that is not its own. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/retry.sh"
fail() { echo "selftest-retry-exact-path: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rt_suite "$T/p"
rt_case cases/x/same.sh ok; rt_case cases/y/same.sh once; rt_list cases/x/same.sh
rt_run
[ "$RT" -ne 0 ] || fail 'a case sharing a listed case'"'"'s file name was let through'
[ "$(rt_ran cases/y/same.sh)" -eq 1 ] || fail 'a case was retried by its file name'
rm -f "$T"/once.*; : > "$T/ran"; printf '# Purpose: the flaky cases\nsame.sh 2026-10-16 bare\ncases/same.sh 2026-10-16 wrong folder\n' > checks/selftest/flaky
rt_run
[ "$RT" -ne 0 ] && [ "$(rt_ran cases/y/same.sh)" -eq 1 ] || fail 'a case was retried by a path that is not its own'
rm -f "$T"/once.*; : > "$T/ran"; rt_list cases/y/same.sh
rt_run
[ "$RT" -eq 0 ] && [ "$(rt_ran cases/y/same.sh)" -eq 2 ] || fail 'the case listed by its own path was not retried'
exit 0
