#!/bin/sh
# Purpose: selftest case — the courts side by side refuse exactly what the
# serial hook refused (v0.9.5 spec 3.8, R8; §7 case 9). Stub courts (a
# refusal toggled per court) under the real hook and under the 0.9.4 serial
# hook (fixtures/pre-commit-serial): over a commit where every court passes
# and one where each court in turn refuses, both hooks agree. Then: two
# failing courts are both printed and named; a quick-gate refusal comes
# before any lane starts; a court whose job dies before writing its status
# is a failure. Last, with the real harness court, a commit whose only fault
# is an UNTRACKED test file carrying a forbidden harness token is refused
# by both hooks. v0.9.6.2 (3.4, R4; §6 case 16): inventory and census
# failing together are named apart in hook-times' by=. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
SERIAL="$CHECKS/selftest/fixtures/pre-commit-serial"
fail() { echo "hook-parallel: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
# the PRD memo is cleared before every run: the stub PRD court reads a toggle outside the memo's key
verdict() { rm -rf "$(git rev-parse --git-path vid-memo)"; if sh "$1" > "$T/out" 2>&1; then echo pass; else echo refused; fi; }
stage one
[ "$(verdict checks/hooks/pre-commit)" = pass ] && [ "$(verdict "$SERIAL")" = pass ] || fail 'the all-pass commit'
for c in placement conformance imports seams inventory census design-cite prd harness; do
  rm -f .fail/*; : > ".fail/$c"
  P=$(verdict checks/hooks/pre-commit); Q=$(verdict "$SERIAL")
  [ "$P" = refused ] && [ "$Q" = refused ] || fail "a refusal by $c: side by side $P, serial $Q"
done
rm -f .fail/*
# two failing courts, both printed and named
: > .fail/inventory; : > .fail/prd
rm -rf "$(git rev-parse --git-path vid-memo)"; sh checks/hooks/pre-commit > "$T/out" 2>&1 && fail 'two failing courts passed'
grep -q 'inventory refuses' "$T/out" && grep -q 'prd refuses' "$T/out" || fail 'not both failing courts printed'
grep -q 'refused by: inventory prd' "$T/out" || fail 'not both failing courts named'
# v0.9.6.2 (3.4): two courts failing together are both named in by=, inventory and census apart
rm -f .fail/*; : > .fail/inventory; : > .fail/census
rm -rf "$(git rev-parse --git-path vid-memo)"; sh checks/hooks/pre-commit > "$T/out" 2>&1 && fail 'inventory and census failing passed'
tail -n 1 .vid/hook-times | grep -q ' by=inventory,census at=' || fail 'hook-times does not name inventory and census apart'
# a quick-gate refusal: no lane starts
rm -f .fail/* .ran/*; : > .fail/seams
rm -rf "$(git rev-parse --git-path vid-memo)"; sh checks/hooks/pre-commit > "$T/out" 2>&1 && fail 'a quick-gate refusal passed'
for c in inventory census design-cite prd harness; do [ ! -f ".ran/$c" ] || fail "the lane $c started after a quick-gate refusal"; done
[ -f .ran/placement ] && [ -f .ran/conformance ] && [ -f .ran/imports ] || fail 'the quick gate did not run side by side'
# a job that dies before its status file: a failure
rm -f .fail/* .ran/*
cp checks/design-cite.sh "$T/dc.keep"
printf '#!/bin/sh\n# Purpose: stub court that kills its own job\nkill -9 $PPID\nexit 0\n' > checks/design-cite.sh
g add checks/design-cite.sh; g commit -qm 'a court whose job dies'   # committed, so the working-tree rule holds
stage three
rm -rf "$(git rev-parse --git-path vid-memo)"; sh checks/hooks/pre-commit > "$T/out" 2>&1 && fail 'a court with no status file passed'
grep -q 'refused by: design-cite' "$T/out" || fail 'the court with no status file was not named'
# the named case: an untracked test file with a forbidden token, the real harness court
mkdir -p "$T/h" && cd "$T/h"
. "$CHECKS/selftest/fixtures/stub-courts.sh"
cp "$CHECKS/harness.sh" checks/harness.sh
mkdir -p tests/invariants
printf 'x-vid-harness:\n  product: product\n  forbidden: live_server\nservices:\n  product:\n    build:\n      context: .\n    image: toy:test\n  tests:\n    image: runner:1\n' > docker-compose.test.yml
g add -A && g commit -qm 'the real harness court'
stage two
[ "$(verdict checks/hooks/pre-commit)" = pass ] || fail 'the clean harness commit was refused'
printf 'from runner import live_server\n' > tests/invariants/test_untracked.py
P=$(verdict checks/hooks/pre-commit); Q=$(verdict "$SERIAL")
[ "$P" = refused ] && [ "$Q" = refused ] || fail "the untracked forbidden token: side by side $P, serial $Q"
exit 0
