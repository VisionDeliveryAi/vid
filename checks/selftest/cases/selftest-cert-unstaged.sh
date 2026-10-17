#!/bin/sh
# Purpose: selftest case — no certificate for code that was never staged (v0.9.7.3 spec 3.6, R6). A law commit whose
# suite run sees checks/ changed on disk during the run (a fix written but not staged) passes, and publishes no
# certificate: every file under checks/ on disk must still equal the index when the pass is published. An untracked
# file appearing under checks/ during the run likewise. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/cert.sh"
fail() { echo "selftest-cert-unstaged: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ct_repo "$T/main"; C=$(ct_cert)
printf 'printf "# a fix, unstaged\\n" >> "%s/main/checks/seams.sh"\n' "$T" > "$T/hook-in.sh"
ct_row 2; ct_law 'checks/ edited during the run'
[ -z "$(ls "$C" 2>/dev/null)" ] || fail 'a certificate was published while checks/ on disk differed from the index'
git checkout -q checks/seams.sh
printf 'printf "# new\\n" > "%s/main/checks/extra.sh"\n' "$T" > "$T/hook-in.sh"
ct_row 3; ct_law 'an untracked file under checks/'
[ -z "$(ls "$C" 2>/dev/null)" ] || fail 'a certificate was published with an untracked file under checks/'
rm -f checks/extra.sh "$T/hook-in.sh"
ct_row 4; ct_law 'clean'
[ -n "$(ls "$C" 2>/dev/null)" ] || fail 'a clean pass published nothing'
exit 0
