#!/bin/sh
# Purpose: selftest case — deferrals as records, edge rows only (v0.9.7.2 spec 3.7, R11). In the hardening step H1:
# a row with no verdict, or KEPT, is refused (grading first); a product breach deferred as kind test is refused; as
# product it writes `deferred row= kind=product why= from= by=`; again is refused while open; --from must name a brief
# or receipt that exists; a row protected after its placement is refused. `defer-resolved` by a commit or by a
# verdict's brief records a disposition only: the row stays not KEPT until a fresh verdict. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "defer-edge-only: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
rcpt r1 HEAD inline ROW-010=passed ROW-011=passed
df() { sh checks/metrics.sh defer "$@" > "$T/out" 2>&1; }
if df --kind product --row ROW-010 --why 'edge' --from receipt:r1; then fail 'a row with no verdict was deferred'; fi
grep -q 'no eligible BREACHED verdict' "$T/out" || fail 'the refusal does not send it to grading'
verdict ROW-010 KEPT; if df --kind product --row ROW-010 --why 'edge' --from receipt:r1; then fail 'a KEPT row was deferred'; fi
verdict ROW-010 BREACHED product
if df --kind test --row ROW-010 --why 'edge' --from receipt:r1; then fail 'a product breach was deferred as a test finding'; fi
if df --kind product --row ROW-010 --why 'edge' --from receipt:nosuch; then fail 'a receipt that does not exist was named'; fi
if df --kind product --row ROW-010 --why 'edge' --from brief:.vid/briefs/1/nosuch.md#ROW-010; then fail 'a brief that does not exist was named'; fi
df --kind product --row ROW-010 --why 'an empty-export edge case' --from receipt:r1 || fail 'the edge deferral was refused'
grep -q '^deferred row=ROW-010 kind=product why="an empty-export edge case" from=receipt:r1 by=develop at=' .vid/metrics-events || fail 'the deferral event'
if df --kind product --row ROW-010 --why 'again' --from receipt:r1; then fail 'an open deferral was deferred again'; fi
verdict ROW-011 BREACHED product; derive ROW-011 REQ-002; commit_all 'ROW-011 protected'
if df --kind product --row ROW-011 --why 'edge' --from receipt:r1; then fail 'a protected row was deferred'; fi
grep -q 'protected' "$T/out" || fail 'the refusal does not say protected'
if sh checks/metrics.sh defer-resolved --row ROW-010 --by nosuchthing > "$T/out" 2>&1; then fail 'resolved by nothing'; fi
sh checks/metrics.sh defer-resolved --row ROW-010 --by .vid/briefs/1/grader-1.md > "$T/out" 2>&1 || fail 'resolution by a verdict brief was refused'
grep -q '^deferred-resolved row=ROW-010 by=verdict:.vid/briefs/1/grader-1.md at=' .vid/metrics-events || fail 'the resolution event'
ss H1 > "$T/out"; grep -q '^not-kept step=H1 row=ROW-010' "$T/out" || fail 'a resolution made the row KEPT'
if sh checks/metrics.sh defer-resolved --row ROW-010 --by HEAD > "$T/out" 2>&1; then fail 'a closed deferral was resolved again'; fi
exit 0
