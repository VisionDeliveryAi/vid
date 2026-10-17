#!/bin/sh
# Purpose: selftest case — no case inherits the caller's VID_ settings (v0.9.8.1 R2). A toy suite whose one case
# fails when VID_ROLE or VID_REQUEST is set: run.sh, called with VID_ROLE=fix and VID_REQUEST=x (a law commit's
# hook, made with VID_ROLE=fix), passes; refusal-record's protected-path step failed that way every time. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/retry.sh"
fail() { echo "selftest-env-clean: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
rt_suite "$T/p"
printf '#!/bin/sh\n# Purpose: a toy case\n[ -z "${VID_ROLE:-}" ] && [ -z "${VID_REQUEST:-}" ]\n' > checks/selftest/cases/env.sh
RT=0; VID_ROLE=fix VID_REQUEST=x sh checks/selftest/run.sh > "$T/out" 2>&1 || RT=$?
[ "$RT" -eq 0 ] || fail "a case inherited the caller's VID_ settings"
exit 0
