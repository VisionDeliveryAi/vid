#!/bin/sh
# Purpose: selftest case — a raised ceiling survives the next merge (0.26.10.29.2, R10). On the results reader's made-up
# reports: .vid/budget at stacks=2 and a recorded raise to unverified-rows=150 (a `plan-change what=other` naming it);
# `results.sh declare` on a head report declaring the same 2 environments leaves the budget as it was, raise and every
# other line; a head report declaring 3 environments re-measures: stacks=3 and unverified-rows=180 (60 × 3), the other
# line kept. 02 environments against stacks=2, and 1 against a budget with no stacks= line, change
# nothing; 03 writes stacks=3. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/results-reports.sh"
fail() { echo "results-declare-raise: $*" >&2; sed 's/^/    /' "$T/out" .vid/budget >&2 2>/dev/null; exit 1; }
R=$CHECKS/results.sh; rr_project
rep() { rr_put "$1" results.txt "$(printf 'by: TM\ncommit: %s\nengines: alpha\nenvironments: %s' "$2" "$3")"; rr_put "$1" cases-alpha.xml "$(rr_cases ROW-009=pass)"; rr_send "$1"; }
printf 'stacks=2\nunverified-rows=150\nother=1\n' > .vid/budget
printf 'plan-change what=other hash=0123456789ab decision=d1 why="S04 whole; unverified-rows=150" at=2026-11-03T10:00:00Z\n' > .vid/metrics-events
cp .vid/budget "$T/before"
rep "pr-2-$RR_H12-1" "$RR_H" 2; sh "$R" declare --pr 2 --head "$RR_H" > "$T/out" 2>&1 || fail 'declare failed'
grep -q '^declared engines=alpha environments=2' "$T/out" || fail 'the report was not declared'
cmp -s .vid/budget "$T/before" || fail 'a merge declaring the same 2 environments changed the budget, the raise to 150 lost'
H2=$(printf %s "$RR_H2" | cut -c1-12); rep "pr-7-$H2-1" "$RR_H2" 3; sh "$R" declare --pr 7 --head "$RR_H2" > "$T/out" 2>&1 || fail 'declare failed'
grep -qx 'stacks=3' .vid/budget && grep -qx 'unverified-rows=180' .vid/budget || fail 'a merge declaring 3 environments did not re-measure to stacks=3 and unverified-rows=180'
[ "$(grep -c '^stacks=' .vid/budget)" = 1 ] && [ "$(grep -c '^unverified-rows=' .vid/budget)" = 1 ] && grep -qx 'other=1' .vid/budget || fail 'the re-measured budget is not one stacks= line, one unverified-rows= line and the rest kept'
# the count read as a number (02 is 2), and a budget with no stacks= line read as one environment
printf 'stacks=2\nunverified-rows=150\nother=1\n' > .vid/budget; cp .vid/budget "$T/before"
rep "pr-8-$RR_H12-1" "$RR_H" 02; sh "$R" declare --pr 8 --head "$RR_H" > "$T/out" 2>&1 || fail 'declare failed'
cmp -s .vid/budget "$T/before" || fail 'a report declaring 02 environments against stacks=2 changed the budget, the raise lost'
printf 'unverified-rows=150\nother=1\n' > .vid/budget; cp .vid/budget "$T/before"
rep "pr-9-$RR_H12-1" "$RR_H" 1; sh "$R" declare --pr 9 --head "$RR_H" > "$T/out" 2>&1 || fail 'declare failed'
cmp -s .vid/budget "$T/before" || fail 'a report declaring 1 environment against a budget with no stacks= line changed it, the raise lost'
printf 'stacks=2\nunverified-rows=150\n' > .vid/budget; rep "pr-10-$RR_H12-1" "$RR_H" 03; sh "$R" declare --pr 10 --head "$RR_H" > "$T/out" 2>&1 || fail 'declare failed'
grep -qx 'stacks=3' .vid/budget && grep -qx 'unverified-rows=180' .vid/budget || fail 'a report declaring 03 environments did not write stacks=3 and unverified-rows=180'
exit 0
