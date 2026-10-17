#!/bin/sh
# Purpose: selftest case — a checkpoint runs beside the build (v0.9.6.1 spec
# 3.8, R8; §6 case 14). Three proved environments; a checkpoint (`sh
# checks/test.sh --role checkpoint -- <selection>`) holds slot 1. While it
# runs: `plan.sh start` admits a step, a selected close runs to its end in
# another slot, and its claim closes S1 — none waits for it. Then the
# checkpoint publishes <head>.run-<id>.checkpoint.xml (kind=checkpoint), its
# failing row reads red, `metrics.sh checkpoint --n 1` records it with the
# row a regression, the row is required at the next close (set 4), and rule
# B refuses a step building on S1. With one environment a checkpoint is
# refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -f "$T/hold"; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
fail() { echo "checkpoint-nonblocking: $*" >&2; cat "$T/out" "$T/cp" >&2 2>/dev/null; exit 1; }
plan_repo "$T/repo"; rows s1 1 1; rows s3 3 3; rows s4 4 4
export VID_REQUEST=selftest-direct   # v0.9.7.0.2: the runner's own test calls it directly, as the test manager does
# ROW-001 cites the file the compose stub's report names
sed 's#^\(ROW-001 | .*\) | tests/invariants/test_s1.py$#\1 | tests/invariants/t.py#' INVENTORY.md > "$T/inv" && cat "$T/inv" > INVENTORY.md
printf '# Purpose: the stub report'"'"'s file\n' > tests/invariants/t.py; commit_all rows
plan 'step S1 | name: first | modules: app/s1 | builds-on: - | rows: ROW-001' 'step S3 | name: third | modules: app/s3 | builds-on: - | rows: ROW-003' \
  'step S4 | name: fourth | modules: app/s3 | builds-on: S1 | rows: ROW-004' "shared: $PLANS_SHARED"
sh checks/plan.sh change create 'three steps' --trigger initial --expect 'the steps build in order' > /dev/null
printf 'stacks=1\n' > .vid/budget
if sh checks/test.sh --role checkpoint -- every built row > "$T/out" 2>&1; then fail 'a checkpoint ran with one environment'; fi
grep -q 'two or more proved test environments' "$T/out" || fail 'the one-environment refusal does not say why'
[ "$(nruns)" -eq 0 ] || fail 'the refused checkpoint left a run folder'
printf 'stacks=3\ntestenv=proved harness=%s\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
sh checks/plan.sh start S1 > /dev/null
H=$(git rev-parse --short=12 HEAD)
touch "$T/hold"
( STUB_HOLD="$T/hold" STUB_ENTER="$T/entered" STUB_CASE=failed sh checks/test.sh --role checkpoint -- every built row > "$T/cp" 2>&1 ) & P=$!
waitfor "$T/entered" || fail 'the checkpoint never reached its up'
grep -q 'kind=checkpoint' .vid/runs/*/holder || fail 'the checkpoint'"'"'s run folder does not say so'
sh checks/test.sh --role close -- the S1 rows > "$T/out" 2>&1 || fail 'a selected close waited for or was refused beside the checkpoint'
grep -q '|vid-s2-repo|' "$STUB_LOG" || fail 'the close did not take another slot'
mkdir -p .vid/close; : > .vid/close/1.rows
sh checks/metrics.sh claim --to ".vid/ledger-results/$H.close.xml" --steps S1 > "$T/out" 2>&1 || fail 'the claim was refused beside the checkpoint'
grep -qx 'claim row=ROW-001 why=unverdicted' "$T/out" || fail 'the claim did not claim ROW-001'
sh checks/plan.sh start S3 > "$T/out" 2>&1 || fail 'an admission waited for or was refused beside the checkpoint'
grep -q 'admitted S3' "$T/out" || fail 'S3 was not admitted'
[ -d "$T/hold" ] || [ -f "$T/hold" ] || fail 'the checkpoint ended early'
rm -f "$T/hold"; wait "$P" || true
R=$(kept | grep '\.checkpoint\.xml$' || true)
printf '%s\n' "$R" | grep -qE "^$H\.run-[0-9]{8}T[0-9]{6}Z-[0-9]+\.checkpoint\.xml\$" || fail "the checkpoint receipt: $R"
cmp -s ".vid/ledger-results/$H.checkpoint.xml" ".vid/ledger-results/$R" || fail 'no copy <head>.checkpoint.xml'
grep -qE "^ledger-run seconds=[0-9]+ kind=checkpoint report=$R status=0 role=checkpoint " .vid/metrics-events || fail 'no kind=checkpoint event'
[ "$(state ROW-001)" = red ] || fail "the checkpoint's failing row is not red: $(state ROW-001)"
sh checks/metrics.sh checkpoint --n 1 --to ".vid/ledger-results/$H.checkpoint.xml" > "$T/out" 2>&1 || fail 'the checkpoint could not be recorded'
grep -qx 'regression row=ROW-001' "$T/out" || fail 'ROW-001 is not a regression'
grep -qE "^checkpoint n=1 report=$R built=1 regressions=1 base=$H at=" .vid/metrics-events || fail 'the checkpoint record'
sh checks/metrics.sh close-rows --steps S3 > "$T/out" 2>&1 || fail 'close-rows refused'
grep -qx 'required row=ROW-001 sets=4 step=S1 phase=1' "$T/out" || fail 'the red row is not required at the next close'
if sh checks/plan.sh start S4 > "$T/out" 2>&1; then fail 'a step building on S1 was admitted over its red row'; fi
grep -q 'S4 builds on S1, which is not passing: ROW-001 red' "$T/out" || fail 'the refusal does not name the red row'
exit 0
