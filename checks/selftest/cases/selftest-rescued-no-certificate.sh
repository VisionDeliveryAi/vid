#!/bin/sh
# Purpose: selftest case — a rescued run publishes no certificate (v0.9.8.1 R1). Under the real hook: a law commit
# whose shipped case is on checks/selftest/flaky and fails once, then convicts on its retry, lands, says it was
# rescued and publishes no certificate; the next law commit runs the suite again, and its clean pass publishes one.
# Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/cert.sh"
fail() { echo "selftest-rescued-no-certificate: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ct_repo "$T/main"
printf '# Purpose: the flaky cases\ncases/shipped-one.sh 2026-10-16 a toy reason\n' > checks/selftest/flaky
g add -A && g commit -qm 'the flaky list'
printf 'if [ -f "%s/once" ]; then exit 0; fi; : > "%s/once"; exit 1\n' "$T" "$T" > "$T/hook-in.sh"
ct_row 2; ct_law 'rescued'
[ "$(ct_runs)" -eq 2 ] || fail 'the shipped case was not run, then retried'
grep -q 'rescued by a retry — no certificate published' "$T/out" || fail 'the hook does not say the run was rescued'
C=$(ct_cert); [ -z "$(ls "$C" 2>/dev/null)" ] || fail 'a rescued run published a certificate'
rm -f "$T/hook-in.sh"; ct_row 3; ct_law 'after the rescue'
[ "$(ct_runs)" -eq 3 ] || fail 'the law commit after a rescued run skipped the suite'
[ -n "$(ls "$C" 2>/dev/null)" ] || fail 'a clean pass after the rescue published no certificate'
exit 0
