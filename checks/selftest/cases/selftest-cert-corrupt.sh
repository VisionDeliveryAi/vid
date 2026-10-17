#!/bin/sh
# Purpose: selftest case — a corrupt certificate is a miss (v0.9.7.3 spec 3.6, R6). After a full pass, the entry is
# overwritten with garbage, then truncated, then made to name another key: each time the next law commit runs the
# whole suite (never skipped), and its pass writes a whole entry again. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/cert.sh"
fail() { echo "selftest-cert-corrupt: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ct_repo "$T/main"; C=$(ct_cert)
ct_row 2; ct_law 'first'; K=$(ls "$C"); [ "$(cat "$C/$K")" = "pass $K" ] || fail 'no whole certificate after the first pass'
n=2
for bad in 'garbage' '' "pass 0000$K"; do
  printf '%s' "$bad" > "$C/$K"; N=$(ct_runs); n=$((n + 1)); ct_row "$n"; ct_law "corrupt: $bad"
  [ "$(ct_runs)" -gt "$N" ] || fail "a corrupt entry ('$bad') skipped the suite"
  grep -q "selftest: ViD's shipped checks unchanged" "$T/out" && fail "a corrupt entry ('$bad') was read as a pass"
  [ "$(cat "$C/$K")" = "pass $K" ] || fail "the pass after a corrupt entry ('$bad') did not write a whole one"
done
exit 0
