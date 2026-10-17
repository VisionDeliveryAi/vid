#!/bin/sh
# Purpose: selftest case — a proof goes stale when its test changes (v0.9.8 spec 3.2, R13; amendment 3): evidence.sh's
# block rule at row grain. A proof of ROW-201 recorded with its helper stays proven=yes when a line of ROW-202's block in the
# same file changes; it reads stale when a line of ROW-201's block changes (one not naming the row, between its first
# line and ROW-202's), when its own named line changes, when a line naming it in another block changes (as the evidence
# reader: a changed line naming the row), when the helper it read changes, or when its obligation changes. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "test-state-stale-on-edit: $*" >&2; exit 1; }
au_repo "$T/repo"; printf '# Purpose: a shared helper\nfresh() { :; }\n' > tests/invariants/helpers.sh
printf '# Purpose: toy ledger\ntest_ROW_201() {\n  limit=7\n}\ntest_ROW_202() {\n  width=6\n  # unlike ROW-201, no clock\n}\n' > tests/invariants/links.sh; au_stamp; au_ts
printf 'ROW-201\tpass\tr\nROW-202\tpass\tr\n' > "$T/states"; VID_EVIDENCE_STATES=$T/states; export VID_EVIDENCE_STATES
au_attest test-proven ROW-201 proven tests/invariants/helpers.sh
B=$(git rev-parse HEAD)
rv() { au_state ROW-201 | sed 's/.* proven=\([^ ]*\).*/\1/'; }
[ "$(rv)" = yes ] || fail "the fresh proof is $(rv)"
sed 's/^  width=6$/  width=8/' tests/invariants/links.sh > x && mv x tests/invariants/links.sh; g commit -qam 'ROW-202 block edited'
[ "$(rv)" = yes ] || fail "an edit to another row's block staled it: $(au_state ROW-201)"
sed 's/^  limit=7$/  limit=5/' tests/invariants/links.sh > x && mv x tests/invariants/links.sh; g commit -qam 'ROW-201 block edited'
[ "$(rv)" = stale ] || fail "an edit inside its own block left it $(rv)"
au_state ROW-201 | grep -q 'proof-stale="test tests/invariants/links.sh"' || fail "the reason does not name the test: $(au_state ROW-201)"
g reset -q --hard "$B"
sed 's/^test_ROW_201() {$/test_ROW_201() { # the lifetime/' tests/invariants/links.sh > x && mv x tests/invariants/links.sh; g commit -qam 'ROW-201 line edited'
[ "$(rv)" = stale ] || fail "an edit to its own named line left it $(rv)"
g reset -q --hard "$B"
sed 's/^  # unlike ROW-201, no clock$/  # unlike ROW-201, no clock at all/' tests/invariants/links.sh > x && mv x tests/invariants/links.sh; g commit -qam 'a line naming ROW-201 in another block'
[ "$(rv)" = stale ] || fail "an edit to a line naming the row, outside its block, left it $(rv)"
g reset -q --hard "$B"
printf 'fresh2() { :; }\n' >> tests/invariants/helpers.sh; g commit -qam 'helper edited'
[ "$(rv)" = stale ] || fail "an edit to its helper left it $(rv)"
g reset -q --hard "$B"
sed 's/a link refuses after seven days/a link refuses after six days/' INVENTORY.md > x && mv x INVENTORY.md; g commit -qam 'obligation edited'
[ "$(rv)" = stale ] || fail "an obligation edit left it $(rv)"
exit 0
