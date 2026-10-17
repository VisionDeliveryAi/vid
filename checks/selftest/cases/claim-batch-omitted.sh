#!/bin/sh
# Purpose: selftest case — a claim by batch leaves nothing out (v0.9.7.0.12 spec 3.5; R5; §6 D). A batch that ended
# red at phase 1: the claim is refused naming the failed row and the chunks not run. A green batch whose chunk has
# lost its receipts: refused `not-run chunk=<n>`. A chunk receipt naming another tree: refused `mixed tree`. Each
# refusal exits 2 and writes no step-closed. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "claim-batch-omitted: $*" >&2; cat "$T/out" >&2 || true; exit 1; }
batch_repo "$T/repo"
groups "$T/p1" 3 4; groups "$T/p2" 1 2
refused() { rc=0; sh checks/metrics.sh claim --batch "$TK" > "$T/out" 2>&1 || rc=$?; [ "$rc" -eq 2 ] && grep -q '^claim refused' "$T/out" || fail "$1 was not refused ($rc)"; }
# red at phase 1
printf '%s failed\n' "$(w 2 3)" > "$T/st"; STUB_STATUSES="$T/st" batch || fail 'the red batch was refused'; unset STUB_STATUSES
bwait && fail 'the red batch ended green'
refused 'a red batch'
grep -qF "failed row=ROW-003 case=$(w 2 3)" "$T/out" && grep -q '^not-run chunk=3 — no receipt' "$T/out" || fail 'the red row and the chunk not run are not named'
# a chunk without its receipts
printf '# b\n' > app/s3/b.py; commit_all b
batch || fail 'the batch was refused'; bwait || fail 'the batch did not end green'
mv ".vid/requests/$TK/chunks/2/receipts" "$T/r2"
refused 'a chunk without receipts'
grep -q '^not-run chunk=2 — no receipt' "$T/out" || fail 'the chunk without receipts is not named'
mv "$T/r2" ".vid/requests/$TK/chunks/2/receipts"
# a receipt of another tree
R=$(cut -f1 ".vid/requests/$TK/chunks/4/receipts" | sed 's#.*/##')
sed "s/^tree=.*/tree=$(git rev-parse 'HEAD~1^{tree}')/" ".vid/ledger-results/$R.tree" > "$T/t" && mv "$T/t" ".vid/ledger-results/$R.tree"
refused 'a mixed tree'
grep -q "^mixed tree chunk=4 report=$R" "$T/out" || fail 'the mixed tree is not named'
grep -q '^step-closed step=S2 ' .vid/metrics-events && fail 'a refused claim wrote step-closed'
exit 0
