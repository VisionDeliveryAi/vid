#!/bin/sh
# Purpose: selftest case — the progress update's fixed table (v0.9.6 spec
# 3.15, R15; §7 case 33). A toy develop run whose commits are 12 h old:
# with one receipt the table's rows (v0.9.7.0.7: Builders after Tests; v0.9.7.2: eleven — Done named Passing, Debt and Builders at once added) print in order and the estimate
# says "no estimate yet"; with two receipts passing nothing, "no estimate:
# no rows turned green"; with receipts 10 h, 5 h and 1 h ago passing 0, 2
# and 4 of 8 rows, a range from the two windows (4 rows left at 0.7 and 0.4
# rows/hour: 6.0–10.0 h); with every row passing but one owed-now row,
# Left counts "blocked: 1" (never nothing left), the event's rows-left is
# 1 and the headline says nothing is left to turn green (v0.9.7.2: then its debt); steps show by their plain names, never row ids. --record
# appends to .vid/PROGRESS.md and writes the `progress` event. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-table: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ago() { awk -v e="$(( $(date +%s) - $1 ))" 'BEGIN { d = int(e / 86400); s = e - d * 86400; z = d + 719468; era = int(z / 146097); doe = z - era * 146097
  yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365); y = yoe + era * 400; doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
  mp = int((5 * doy + 2) / 153); dd = doy - int((153 * mp + 2) / 5) + 1; m = mp + (mp < 10 ? 3 : -9); if (m <= 2) y++
  printf "%04d-%02d-%02dT%02d:%02d:%02dZ\n", y, m, dd, int(s / 3600), int((s % 3600) / 60), s % 60 }'; }
OLD=$(ago 43200 | sed 's/Z$/+0000/'); export GIT_COMMITTER_DATE="$OLD" GIT_AUTHOR_DATE="$OLD"
plan_repo "$T/repo"; rows s1 1 4; rows s2 5 8; commit_all rows
# develop began 11 h ago; an earlier receipt (init's red gate, 20 h ago) is not develop's first
sed "s/^\(stage name=develop state=start .*\) at=.*/\1 at=$(ago 39600)/" .vid/metrics-events > x && mv x .vid/metrics-events
plan 'step S1 | name: tenants and feeds | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004 | lane: orchestrator (one configuration line)' \
  'step S2 | name: the candidate account | modules: app/s2 | builds-on: - | rows: ROW-005..ROW-008 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'two steps' --trigger initial --expect 'the steps build in order' > /dev/null
# rcpt_at <name> <seconds ago> <ROW=status …>: a receipt published that long ago
rcpt_at() { _n=$1; _a=$2; shift 2; rcpt "$_n" HEAD inline "$@"; sed "s/\\(report=$_n status=0 tree=x run=$_n\\) at=.*/\\1 at=$(ago "$_a")/" .vid/metrics-events > x && mv x .vid/metrics-events; }
rows_in() { sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress.sh failed'; }
rcpt_at r0 72000 ROW-001=failed
rows_in
# v0.9.7.2 (R12, R15): Done is named Passing; the Debt and Builders-at-once rows are fixed too; v0.9.8 (R13): Test state after Tests (Rows passing shows once a step's rows are seen passing)
[ "$(sed -n '5,$p' "$T/out" | grep '^| ' | cut -d'|' -f2 | sed 's/^ //; s/ $//' | grep -vx 'Rows passing' | tr '\n' ',')" = 'Passing,Debt,Now,Left,Tests,Test state,Builders,Builders at once,Your questions,Estimate,Plan changes since the last update,Now (the build'"'"'s own words),' ] || fail 'the table rows are not the fixed twelve, in order'
grep -q '^| Estimate | no estimate yet' "$T/out" || fail 'one receipt did not say no estimate yet'
grep -q 'ROW-' "$T/out" && fail 'a row id reached the table'
grep -q 'tenants and feeds' "$T/out" || fail 'steps are not shown by name'
rcpt_at r1 36000 ROW-001=failed
rows_in; grep -q '^| Estimate | no estimate: no rows turned green in the last 3 h' "$T/out" || fail 'a flat rate did not say no rows turned green'
rcpt_at r2 18000 ROW-001=failed ROW-002=failed
rcpt_at r3 18000 ROW-001=passed ROW-002=passed
rcpt_at r4 3600 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed
rows_in; grep -q '^| Estimate | 6.0–10.0 h to the last row passing, at 0.4–0.7 rows/hour' "$T/out" || fail 'the range from two windows is not 6.0–10.0 h'
grep -q 'Not included: the slice-close full runs and grading' "$T/out" || fail 'the estimate does not say what it leaves out'
# every row passing but one owed-now row
sed 's/^\(ROW-008 | .* | \)tests\/invariants\/test_s2.py$/\1owed: prerequisite — the mail seam/' INVENTORY.md > x && mv x INVENTORY.md
commit_all 'ROW-008 owed'
rcpt_at r5 60 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-005=passed ROW-006=passed ROW-007=passed
rows_in
grep '^| Left |' "$T/out" | grep -q 'blocked: 1' || fail 'Left does not show blocked: 1'
grep '^| Left |' "$T/out" | grep -q '0 rows not yet passing' || fail 'Left miscounts the rows not yet passing'
sh checks/progress.sh --record > "$T/out" 2>&1 || fail '--record failed'
grep -q '^## .* — progress (session)' .vid/PROGRESS.md || fail 'PROGRESS.md did not get the table'
tail -n 1 .vid/metrics-events | grep -qE '^progress trigger=session by=session rows-passing=7 rows-left=1 estimate=' || { tail -n 1 .vid/metrics-events >&2; fail 'the progress event is not in its form'; }
grep -qx 'repo: 7 of 8 rows passing · step 2 of 2 · nothing left to turn green · debt 7' "$T/out" || fail 'the headline is not in its form'
exit 0
