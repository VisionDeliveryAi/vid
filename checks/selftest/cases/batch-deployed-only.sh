#!/bin/sh
# Purpose: selftest case — deployed-paid rows run once (v0.9.7.0.12 spec 3.6; R6; §6 E). Under a harness declaring
# deployed-selector:, ROW-004 is a journey row. Refused at the request, naming the row: its group carrying inline
# words; an inline row (ROW-003) in a group with deployed words only. A lawful batch whose ROW-004 group has deployed
# words only: that chunk is deployed-only — its request has no inline selection, its run one deployed pass from the
# batch's export, the tests' image built — and the batch ends green; the claim by batch passes. Under a harness with
# no deployed-selector:, the journey row's group with inline words is accepted, as today. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/batch.sh"
fail() { echo "batch-deployed-only: $*" >&2; cat "$T/req" "$T/wait" "$TD/result" >&2 || true; exit 1; }
PLAIN=$COMPOSEFILE
COMPOSEFILE=$(printf '%s\n' "$PLAIN" | sed 's/^  completed: \[0, 1\]$/&\
  deployed-selector: sel-declared/')
batch_repo "$T/repo"
grep -q '^  deployed-selector: sel-declared$' docker-compose.test.yml || fail 'the harness does not declare deployed-selector:'
awk -F'|' '$1 ~ /^ROW-004 / { $2 = " journey " } { print }' OFS='|' INVENTORY.md > "$T/i" && mv "$T/i" INVENTORY.md; commit_all 'ROW-004 is a journey'
printf 'stacks=2\ntestenv=proved harness=%s\nchunk-seconds=1\n' "$(cksum < docker-compose.test.yml | cut -d' ' -f1)" > .vid/budget
groups "$T/p2" 1 2
nt() { ls .vid/requests 2>/dev/null | grep -c . || true; }
# refused: the journey row with inline words; the inline row with deployed words only
groups "$T/p1" 3 4
if batch; then fail "a journey row's group with inline words was accepted"; fi
grep -q 'ROW-004' "$T/req" && grep -q 'deployed' "$T/req" || fail 'the refusal does not name the journey row'
printf 'ROW-003 | | %s\nROW-004 | | %s\n' "$(w 2 3)" "$(w 2 4)" > "$T/p1"
if batch; then fail 'an inline row with deployed words only was accepted'; fi
grep -q 'ROW-003' "$T/req" || fail 'the refusal does not name the inline row'
[ "$(nt)" -eq 0 ] || fail 'a refused batch left a ticket'
# lawful: ROW-004's chunk deployed-only
printf 'ROW-003 | %s |\nROW-004 | | %s\n' "$(w 2 3)" "$(w 2 4)" > "$T/p1"
batch || fail 'the lawful batch was refused'; TD=.vid/requests/$TK
bwait || fail 'the batch did not end green'
C=$TD/chunks/2
grep -qx 'sel=' "$C/request" && grep -qx 'hasdsel=yes' "$C/request" && grep -qxF "dsel=$(w 2 4)" "$C/request" || fail 'chunk 2 is not deployed-only'
[ "$(grep -c . "$C/receipts")" -eq 1 ] && cut -f2 "$C/receipts" | grep -qx deployed || fail "chunk 2's one receipt is not its deployed pass"
awk -F'|' -v e="/.vid/requests/$TK/export" '$4 ~ /ROW-004/ && substr($3, length($3) - length(e) + 1) == e && $5 ~ /--profile deployed up --build --exit-code-from tests tests/ { b = 1 } END { exit !b }' "$STUB_LOG" || fail "the deployed-only chunk did not build the tests' image from the export"
awk -F'|' '$4 ~ /ROW-004/ && $5 ~ / up --build --exit-code-from/ && $5 !~ /--profile deployed/' "$STUB_LOG" | grep -q . && fail 'the journey row ran an inline pass'

sh checks/metrics.sh claim --batch "$TK" > "$T/req" 2>&1 || fail 'the claim by batch was refused'
# no deployed-selector: the journey row stays inline
printf '%s\n' "$PLAIN" > docker-compose.test.yml; commit_all 'no deployed shape'
groups "$T/p1" 3 4
batch || fail "with no deployed-selector:, a journey row's inline group was refused"
exit 0
