#!/bin/sh
# Purpose: selftest case — core weak tests (v0.9.7.2 spec 3.6, R10). Under breadth first a test-class BREACHED on a
# feature-step row can't be deferred — refused, saying it goes to a test-author pass at once; on a hardening-step row
# it may wait (the deferral is recorded). Where ViD's skills sit beside checks/, vid-verify routes it so. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "core-test-breach: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
rcpt r1 HEAD inline ROW-002=passed ROW-010=passed
verdict ROW-002 BREACHED test; verdict ROW-010 BREACHED test
if sh checks/metrics.sh defer --kind test --row ROW-002 --why 'weak' --from receipt:r1 > "$T/out" 2>&1; then fail 'a core weak test was deferred'; fi
grep -q 'goes to a test-author pass at once, never deferred' "$T/out" || fail 'the refusal does not route it'
sh checks/metrics.sh defer --kind test --row ROW-010 --why 'weak edge test' --from receipt:r1 > "$T/out" 2>&1 || fail 'an edge weak test could not wait'
grep -q '^deferred row=ROW-010 kind=test ' .vid/metrics-events || fail 'no deferral recorded'
V="$CHECKS/../skills/vid-verify/SKILL.md"
if [ -f "$V" ]; then tr '\n' ' ' < "$V" | tr -s ' ' | grep -qF 'a test-class BREACHED on a feature-step row goes to a test-author pass at once' || fail 'vid-verify does not route a core weak test at once'; fi
exit 0
