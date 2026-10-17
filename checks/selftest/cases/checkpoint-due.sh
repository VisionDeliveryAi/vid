#!/bin/sh
# Purpose: selftest case — when a checkpoint is due (v0.9.6.1 spec 3.8, R8;
# §6 case 12). A plan of 1,104 rows. With stacks=1 nothing is ever due, even
# with every row built. With stacks=3 (proved): 367 rows built, nothing is
# due; 368, checkpoint 1 is due (`checkpoint due n=1 built=368 plan=1104`,
# in the status, the report and the progress update). Checkpoint 2 is due
# at 736 and not at 735 whatever checkpoint 1 found (v0.9.7.0.12 3.7, R7:
# at regressions=0 as at regressions=2); once recorded, never a third.
# Recording a checkpoint that is not due is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "checkpoint-due: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"
awk 'BEGIN { for (i = 1; i <= 1104; i++) printf "ROW-%04d | behavior | s | anon | - | x | REQ-001 | tests/invariants/test_all.py\n", i }' > "$T/rows"
awk -v rf="$T/rows" '/^```$/ && !d { while ((getline l < rf) > 0) print l; d = 1 } { print }' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
printf '# Purpose: every row\n' > tests/invariants/test_all.py; commit_all rows
plan 'step S1 | name: a | modules: app/s1 | builds-on: - | rows: ROW-0001..ROW-0367' 'step S1b | name: b | modules: app/s1 | builds-on: - | rows: ROW-0368' \
  'step S2 | name: c | modules: app/s2 | builds-on: - | rows: ROW-0369..ROW-0735' 'step S2b | name: d | modules: app/s2 | builds-on: - | rows: ROW-0736' \
  'step S3 | name: e | modules: app/s3 | builds-on: - | rows: ROW-0737..ROW-1104' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'five steps' --trigger initial --expect 'the steps build in order' > /dev/null
close() { printf 'step-closed step=%s report=x at=%s\n' "$1" "$(utcnow)" >> .vid/metrics-events; }
status() { sh checks/metrics.sh checkpoint 2>&1; }
printf 'stacks=1\n' > .vid/budget
for s in S1 S1b S2 S2b S3; do close "$s"; done
status > "$T/out"; grep -q '^checkpoint due' "$T/out" && fail 'a checkpoint is due with one test environment'
grep -q '^checkpoint none due built=1104 plan=1104 — fewer than two proved test environments' "$T/out" || fail 'the status does not say why none is due'
# three proved environments
grep -v '^step-closed' .vid/metrics-events > "$T/ev" && cat "$T/ev" > .vid/metrics-events
printf 'stacks=3\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
close S1; status > "$T/out"; grep -q '^checkpoint none due built=367 plan=1104' "$T/out" || fail "at 367 of 1,104: $(cat "$T/out")"
close S1b; status > "$T/out"; grep -qx 'checkpoint due n=1 built=368 plan=1104' "$T/out" || fail "at 368 checkpoint 1 is not due: $(cat "$T/out")"
sh checks/metrics.sh > "$T/out" 2>&1; grep -q '^checkpoint due n=1 built=368 plan=1104  #' "$T/out" || fail 'the report does not show the due line'
sh checks/progress.sh > "$T/out" 2>&1; grep -q '^| Tests | .* · checkpoint due n=1 built=368 plan=1104 |$' "$T/out" || fail 'the progress update does not show the due line'
if sh checks/metrics.sh checkpoint --n 2 --to x.checkpoint.xml > "$T/out" 2>&1; then fail 'checkpoint 2 was recorded while checkpoint 1 is due'; fi
# checkpoint 1 found no regression: checkpoint 2 due at 736 all the same
printf 'checkpoint n=1 report=a.checkpoint.xml built=368 regressions=0 base=x at=%s\n' "$(utcnow)" >> .vid/metrics-events
close S2; status > "$T/out"; grep -q '^checkpoint none due built=735 plan=1104 — checkpoint 2 is due at two thirds' "$T/out" || fail "at 735 after no regression: $(cat "$T/out")"
close S2b; status > "$T/out"; grep -qx 'checkpoint due n=2 built=736 plan=1104' "$T/out" || fail "checkpoint 2 is not due after a checkpoint 1 with no regression: $(cat "$T/out")"
# checkpoint 1 found two: due at 736, not at 735
grep -v '^step-closed step=S2\|^step-closed step=S2b\|^step-closed step=S3\|^checkpoint ' .vid/metrics-events > "$T/ev" && cat "$T/ev" > .vid/metrics-events
printf 'checkpoint n=1 report=a.checkpoint.xml built=368 regressions=2 base=x at=%s\n' "$(utcnow)" >> .vid/metrics-events
close S2; status > "$T/out"; grep -q '^checkpoint none due built=735 plan=1104' "$T/out" || fail "at 735: $(cat "$T/out")"
close S2b; status > "$T/out"; grep -qx 'checkpoint due n=2 built=736 plan=1104' "$T/out" || fail "at 736 checkpoint 2 is not due: $(cat "$T/out")"
printf 'checkpoint n=2 report=b.checkpoint.xml built=736 regressions=1 base=x at=%s\n' "$(utcnow)" >> .vid/metrics-events
close S3; status > "$T/out"; grep -q '^checkpoint due' "$T/out" && fail 'a third checkpoint is due'
grep -q 'never a third' "$T/out" || fail 'the status does not say never a third'
exit 0
