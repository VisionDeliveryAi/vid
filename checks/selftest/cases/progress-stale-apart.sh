#!/bin/sh
# Purpose: selftest case — stale apart from red, and out of the rate (v0.9.8.1 R8, F-6). A toy develop run, four rows:
# a receipt 6 h ago passing none, one 5 h ago passing all four; then, now, a test edit to the lines naming ROW-001 and
# ROW-002. Convicts unless Left counts 2 rows stale apart from red (0 red), and (before v0.26.10.3) the rate's last-3-h window read 0
# rows, not −2: the two stale rows are left out of both ends. v0.9.8.1 (R37): then ROW-003 amended: 3 not re-run, 0 red.
# v0.26.10.3 (R7): stale rows leave the estimate — with only they left it says "nothing left to build" and "Not in the
# estimate: <n> to re-run; of the passing, <k> to confirm" (k 1 once ROW-004 is to confirm). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "progress-stale-apart: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
ago() { awk -v e="$(( $(date +%s) - $1 ))" 'BEGIN { d = int(e / 86400); s = e - d * 86400; z = d + 719468; era = int(z / 146097); doe = z - era * 146097
  yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365); y = yoe + era * 400; doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
  mp = int((5 * doy + 2) / 153); dd = doy - int((153 * mp + 2) / 5) + 1; m = mp + (mp < 10 ? 3 : -9); if (m <= 2) y++
  printf "%04d-%02d-%02dT%02d:%02d:%02dZ\n", y, m, dd, int(s / 3600), int((s % 3600) / 60), s % 60 }'; }
OLD=$(ago 43200 | sed 's/Z$/+0000/'); export GIT_COMMITTER_DATE="$OLD" GIT_AUTHOR_DATE="$OLD"
plan_repo "$T/repo"; rows s1 1 4
sed 's/^def test_\([0-9]\)()/def test_00\1()/' tests/invariants/test_s1.py > x && mv x tests/invariants/test_s1.py   # named as the receipts name the cases
commit_all rows
sed "s/^\(stage name=develop state=start .*\) at=.*/\1 at=$(ago 39600)/" .vid/metrics-events > x && mv x .vid/metrics-events
plan 'step S1 | name: tenants | modules: app/s1 | builds-on: - | rows: ROW-001..ROW-004 | lane: builder' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'one step' --trigger initial --expect 'it builds' > /dev/null
rcpt_at() { _n=$1; _a=$2; shift 2; rcpt "$_n" HEAD inline "$@"; sed "s/\\(report=$_n status=0 tree=x run=$_n\\) at=.*/\\1 at=$(ago "$_a")/" .vid/metrics-events > x && mv x .vid/metrics-events; }
rcpt_at r0 21600 ROW-001=failed
rcpt_at r1 18000 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed
unset GIT_COMMITTER_DATE GIT_AUTHOR_DATE
sed 's/^def test_001(): pass  # ROW-001$/def test_001(): assert True  # ROW-001/; s/^def test_002(): pass  # ROW-002$/def test_002(): assert True  # ROW-002/' tests/invariants/test_s1.py > x && mv x tests/invariants/test_s1.py
commit_all 'a test edit for ROW-001 and ROW-002'
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed'
grep '^| Left |' "$T/out" | grep -q '(0 red, 2 not re-run since a rule or test change, ' || fail "Left counts stale rows as red: $(grep '^| Left |' "$T/out")"
grep '^| Estimate |' "$T/out" | grep -q '| nothing left to build\. .* Not in the estimate: 2 to re-run; of the passing, 0 to confirm\. |$' || fail "only stale rows left is not 'nothing left to build' with the left-out line: $(grep '^| Estimate |' "$T/out")"
# v0.9.8.1 (R37): an amended row (post-commit's `amended`) is stale too — apart from red, out of the rate
printf 'amended row=ROW-003 sha=%s by=obligation at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(ago 60)" >> .vid/metrics-events
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed after the amendment'
grep '^| Left |' "$T/out" | grep -q '(0 red, 3 not re-run since a rule or test change, ' || fail "an amended row is not counted apart from red: $(grep '^| Left |' "$T/out")"
grep '^| Estimate |' "$T/out" | grep -q '| nothing left to build\. .* Not in the estimate: 3 to re-run; of the passing, 0 to confirm\. |$' || fail "the amended row is priced as build work: $(grep '^| Estimate |' "$T/out")"
# v0.26.10.3 (R7): a passing row to confirm is named in the left-out line, never priced
printf 'law-changed row=ROW-004 sha=%s item=REQ-001 at=%s\n' "$(git rev-parse --short=12 HEAD)" "$(ago 30)" >> .vid/metrics-events
sh checks/progress.sh > "$T/out" 2>&1 || fail 'progress failed after the law change'
grep '^| Estimate |' "$T/out" | grep -q 'Not in the estimate: 3 to re-run; of the passing, 1 to confirm\. |$' || fail "the passing row to confirm is not named: $(grep '^| Estimate |' "$T/out")"
exit 0
