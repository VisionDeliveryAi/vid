#!/bin/sh
# Purpose: selftest case — a close batch packs its groups into chunks by recorded seconds and ends with its record
# (v0.9.7.0.12 spec 3.2, 3.10; R2, R10; §6 B). A receipt records ROW-001 at 400 s and ROW-002 at 200 s; ROW-003 and
# ROW-004 have none, so each counts as the median seconds per word, 300. At chunk-seconds=500 each phase's groups,
# in order, make two chunks (phase 1: 300, 300; phase 2: 400, 200); at 700 one chunk a phase (600, 600); with no
# chunk-seconds in the budget, 1200. The batch record names the chunk-seconds and the slots; the batch ends with
# `close-batch id= chunks= retried= adopted= stacks-max= wall= chunk-seconds-sum= load-start= load-end= at=`, and the
# result's second line carries the same counts. Each chunk size runs in a repository of its own (a batch's receipts
# are the next batch's history). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-chunks: $*" >&2; cat "$T/req" "$T/wait" "$TD/result" 2>/dev/null >&2; exit 1; }
groups "$T/p1" 3 4; groups "$T/p2" 1 2
home() { cd "$T"; batch_repo "$T/$1"
  rcpt r2 HEAD inline ROW-001=passed ROW-002=passed
  awk '{ if ($2 ~ /ROW-001/) $4 = 400; else if ($2 ~ /ROW-002/) $4 = 200; print }' .vid/ledger-results/r2.cases > "$T/c" && mv "$T/c" .vid/ledger-results/r2.cases; }
cs() { sed '/^chunk-seconds=/d' .vid/budget > "$T/b"; [ -z "$1" ] || echo "chunk-seconds=$1" >> "$T/b"; mv "$T/b" .vid/budget; }
layout() { awk -F'\t' '{ printf "%s%s:%s:%s", (n++ ? " " : ""), $2, $3, $4 }' "$TD/layout"; }
home h500; cs 500
batch || fail 'the batch was refused'; TD=.vid/requests/$TK
bwait || fail 'the batch at 500 did not end green'
[ "$(layout)" = '1:run:300 1:run:300 2:run:400 2:run:200' ] || fail "chunk-seconds=500 packed $(layout)"
[ "$(cat "$TD/chunks/1/rows")" = ROW-003 ] && [ "$(cat "$TD/chunks/3/rows")" = ROW-001 ] || fail 'the groups were not packed in order'
grep -qx 'chunk-seconds=500' "$TD/batch" && grep -qx 'stacks=2' "$TD/batch" || fail "the batch record: $(cat "$TD/batch")"
grep -qx 'cases=300' "$TD/chunks/1/request" && grep -qx 'cases=400' "$TD/chunks/3/request" || fail 'a chunk request does not carry its seconds'
E=$(grep "^close-batch id=$TK " .vid/metrics-events) || fail 'no close-batch event'
[ "$(echo "$E" | grep -c .)" -eq 1 ] || fail 'more than one close-batch event'
for f in chunks=4 retried=0 adopted=0; do case " $E " in *" $f "*) ;; *) fail "close-batch lacks $f: $E" ;; esac; done
echo "$E" | grep -Eq ' stacks-max=[12] wall=[0-9]+ chunk-seconds-sum=[0-9]+ load-start=[0-9.]+ load-end=[0-9.]+ at=[0-9TZ:-]+$' || fail "close-batch fields: $E"
sed -n 2p "$TD/result" | grep -Eq '^chunks 4 retried=0 adopted=0 stacks-max=[12] wall=[0-9]+ chunk-seconds-sum=[0-9]+$' || fail 'the result does not carry the counts'
home h700; cs 700
batch || fail 'the second batch was refused'; TD=.vid/requests/$TK
bwait || fail 'the batch at 700 did not end green'
[ "$(layout)" = '1:run:600 2:run:600' ] || fail "chunk-seconds=700 packed $(layout)"
[ "$(cat "$TD/chunks/1/rows" | paste -sd , -)" = ROW-003,ROW-004 ] || fail 'phase 1 is not one chunk'
grep -q "^close-batch id=$TK chunks=2 retried=0 adopted=0 " .vid/metrics-events || fail 'the second close-batch event'
home h0; cs ''
batch || fail 'the third batch was refused'; TD=.vid/requests/$TK
bwait || fail 'the batch at the default did not end green'
grep -qx 'chunk-seconds=1200' "$TD/batch" && [ "$(layout)" = '1:run:600 2:run:600' ] || fail "the default chunk-seconds: $(layout)"
exit 0
