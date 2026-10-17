#!/bin/sh
# Purpose: selftest case — the before-state of a claim by batch (v0.9.7.0.12 spec 3.5; R5; §6 D). ROW-001 is KEPT and
# passed on S1's close receipt. A batch closing S2 claimed with no --from claims ROW-001 re-paid; with --from that
# receipt it does not. A later batch claimed --from the earlier batch reads the before-state as of that batch's last
# publication: ROW-001 is not claimed re-paid. A --from that is neither a receipt nor a batch is refused. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "claim-batch-from: $*" >&2; cat "$T/out" >&2 || true; exit 1; }
batch_repo "$T/repo"
H=$(git rev-parse --short=12 HEAD)
printf 'verdict slice=1 row=ROW-001 result=KEPT class=product brief=b1 quoted-at=%s at=%s\n' "$H" "$(utcnow)" >> .vid/metrics-events
groups "$T/p1" 3 4; groups "$T/p2" 1 2
claim() { sh checks/metrics.sh claim --batch "$@" > "$T/out" 2>&1 || fail "the claim $* was refused"; }
batch || fail 'the first batch was refused'; A=$TK; bwait || fail 'the first batch did not end green'
claim "$A"
grep -qx 'claim row=ROW-001 why=re-paid' "$T/out" || fail 'with no --from, the KEPT row is not claimed re-paid'
claim "$A" --from .vid/ledger-results/r1
grep -q 'row=ROW-001' "$T/out" && fail 'the KEPT row passed on --from was claimed'
grep -qx 'claim row=ROW-003 why=unverdicted' "$T/out" && tail -n 1 "$T/out" | grep -q ' from=.vid/ledger-results/r1 ' || fail 'the claim --from a receipt'
# a later batch, --from the earlier one
printf '# b\n' > app/s3/b.py; commit_all b
batch || fail 'the second batch was refused'; B=$TK; bwait || fail 'the second batch did not end green'
claim "$B" --from "$A"
grep -q 'row=ROW-001' "$T/out" && fail 'the KEPT row passed in the earlier batch was claimed'
tail -n 1 "$T/out" | grep -q " from=$A batch=$B " || fail 'the summary does not name the earlier batch'
rc=0; sh checks/metrics.sh claim --batch "$B" --from 20000101T000000Z-0000 > "$T/out" 2>&1 || rc=$?
[ "$rc" -eq 2 ] && grep -q 'neither a receipt nor a close batch' "$T/out" || fail "a --from naming nothing was not refused ($rc)"
exit 0
