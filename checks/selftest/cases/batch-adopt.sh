#!/bin/sh
# Purpose: selftest case — a new batch at the same tree adopts the green chunks of an earlier one whose groups are
# identical (v0.9.7.0.12 spec 3.4; R4; §6 B). A green batch of four chunks; a second at the same tree with the same
# groups adopts all four and runs none (`adopted=4`, each chunk line naming the first batch's chunk); a third at
# the same tree with one group's words changed runs that chunk alone and adopts three, naming the first batch's
# chunks (an adopted chunk's own source); after a commit, a fourth adopts none. The freeze (close-rows) is reused
# at the same tree while nothing it reads has changed — the second and third batches' records say `frozen=reused
# from <the batch before>`; a receipt published meanwhile, or a new tree, makes it computed again. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-adopt: $*" >&2; cat "$T/req" "$T/wait" "$TD/result" >&2 || true; exit 1; }
batch_repo "$T/repo"
groups "$T/p1" 3 4; groups "$T/p2" 1 2
go() { batch || fail 'a batch was refused'; TD=.vid/requests/$TK; bwait || fail "batch $TK did not end green"; }
runs() { grep -c "^ledger-run .* request=$TK/" .vid/metrics-events || true; }
ev() { grep "^close-batch id=$TK " .vid/metrics-events; }
go; A=$TK
[ "$(runs)" -eq 4 ] && ev | grep -q ' adopted=0 ' || fail 'the first batch did not run its four chunks'
# the same tree, the same groups: all adopted
go
[ "$(runs)" -eq 0 ] || fail "the second batch ran $(runs) chunks"
ev | grep -q ' chunks=4 retried=0 adopted=4 ' || fail "the second batch: $(ev)"
grep -qx "frozen=reused from $A" "$TD/batch" || fail "the second batch did not reuse the first's freeze: $(grep '^frozen=' "$TD/batch")"; B2=$TK
for n in 1 2 3 4; do grep -q "^chunk $n phase=[12] green adopted=$A/[1-4] report=" "$TD/result" || fail "chunk $n is not adopted from $A"; done
# one group changed: that chunk runs, three adopted from the first batch
printf 'ROW-001 | %s |\nROW-002 | %s %s |\n' "$(w 1 1)" "$(w 1 2)" "$(w 1 1)" > "$T/p2"
go
[ "$(runs)" -eq 1 ] || fail "the third batch ran $(runs) chunks"
ev | grep -q ' chunks=4 retried=0 adopted=3 ' || fail "the third batch: $(ev)"
[ "$(grep -c " adopted=$A/" "$TD/result")" -eq 3 ] || fail 'the adopted chunks do not name the first batch'
grep -qx "frozen=reused from $B2" "$TD/batch" || fail "the third batch did not reuse the freeze: $(grep '^frozen=' "$TD/batch")"
awk -F'\t' '$3 == "run"' "$TD/layout" | grep -q . && [ "$(cat "$TD/chunks/$(awk -F'\t' '$3 == "run" { print $1 }' "$TD/layout")/rows")" = ROW-002 ] || fail 'the chunk run is not the changed group'
# a receipt published meanwhile at the same tree: the freeze is computed again
rcpt r9 HEAD inline ROW-003=passed
go; grep -qx 'frozen=computed' "$TD/batch" || fail "a batch after a new receipt reused the freeze: $(grep '^frozen=' "$TD/batch")"
# a new tree: none adopted
printf '# b\n' > app/s3/b.py; commit_all b
go
[ "$(runs)" -eq 4 ] && ev | grep -q ' adopted=0 ' || fail 'a batch at a new tree adopted a chunk'
grep -qx 'frozen=computed' "$TD/batch" || fail 'a batch at a new tree reused a freeze'
exit 0
