#!/bin/sh
# Purpose: selftest case — one claim over a close batch (v0.9.7.0.12 spec 3.5; R5; §6 D). A checkpoint receipt is the
# population, frozen at the batch's start. A green batch whose phase-1 chunk was retried after a signal: `metrics.sh
# claim --batch <id>` judges each chunk's newest receipts (the retry's), claims the required rows, provisional none,
# ends `claim rows= held= provisional= from=none batch=<id> steps=S2` and writes `step-closed step=S2 report=<the
# newest constituent, a phase-2 chunk's> batch=<id>`. A batch at the same tree adopting every chunk claims too. The population run
# invalidated afterwards: refused, naming it, no step-closed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "claim-batch: $*" >&2; cat "$T/out" "$T/wait" >&2 || true; exit 1; }
batch_repo "$T/repo"
H=$(git rev-parse --short=12 HEAD); P=$H.run-20260101T000000Z-1.checkpoint.xml
RCPT_KIND=checkpoint rcpt "$P" HEAD inline ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed
groups "$T/p1" 3 4; groups "$T/p2" 1 2
sc() { grep -c "^step-closed step=S2 .* batch=$1 " .vid/metrics-events || true; }
STUB_SIGNAL_SEL=$(w 2 3) batch || fail 'the batch was refused'; unset STUB_SIGNAL_SEL; A=$TK
bwait || fail 'the batch did not end green'
[ -d ".vid/requests/$A/chunks/1-retry" ] || fail 'chunk 1 was not retried'
cut -f1 ".vid/requests/$A/frozen/population" | grep -q "/$P$" || fail 'the population was not frozen'
sh checks/metrics.sh claim --batch "$A" > "$T/out" 2>&1 || fail 'the claim by batch was refused'
for r in 1 2 3 4; do grep -q "^claim row=ROW-00$r why=" "$T/out" || fail "ROW-00$r was not claimed"; done
grep -q '^provisional' "$T/out" && fail 'a row is provisional with a population run'
tail -n 1 "$T/out" | grep -qx "claim rows=4 held=0 provisional=0 from=none batch=$A steps=S2" || fail 'the summary line'
SR=$(sed -n "s/^step-closed step=S2 report=\([^ ]*\) batch=$A at=.*/\1/p" .vid/metrics-events)
awk -F'\t' -v r="$SR" '$1 ~ /^[34]$/ && $2 ~ ("/" r "$")' ".vid/requests/$A/receipts" | grep -q . || fail "step-closed does not name a phase-2 constituent: $SR"
cut -f1 ".vid/requests/$A/receipts" | grep -qx 1-retry || fail "the batch's receipts do not name the retry"
# the same tree: every chunk adopted, claimed
batch || fail 'the second batch was refused'; B=$TK; bwait || fail 'the second batch did not end green'
grep -q "^close-batch id=$B chunks=4 retried=0 adopted=4 " .vid/metrics-events || fail 'the second batch did not adopt'
sh checks/metrics.sh claim --batch "$B" > "$T/out" 2>&1 || fail 'the claim over adopted chunks was refused'
[ "$(sc "$B")" -eq 1 ] || fail 'the adopted batch wrote no step-closed'
# the population run invalidated: refused
printf 'invalidated slice=1 report=%s a harness fault at=%s\n' "$P" "$(utcnow)" >> .vid/metrics-events
rc=0; sh checks/metrics.sh claim --batch "$A" > "$T/out" 2>&1 || rc=$?
[ "$rc" -eq 2 ] && grep -q "^claim refused — the batch's population run $P is no longer a valid published receipt" "$T/out" || fail "an invalidated population was not refused ($rc)"
[ "$(sc "$A")" -eq 1 ] || fail 'the refused claim wrote step-closed'
rc=0; sh checks/metrics.sh claim --batch 20000101T000000Z-0000 > "$T/out" 2>&1 || rc=$?
[ "$rc" -eq 2 ] && grep -q 'no close batch' "$T/out" || fail 'a claim over no batch was not refused'
exit 0
