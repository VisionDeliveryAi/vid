#!/bin/sh
# Purpose: selftest case — the authority flag clears (v0.9.8 spec 3.3, R6; amendment 3). A flagged row (A-001
# restated) is cleared by `brief.sh authority --kept ROW-201`, which records `authority-kept row=ROW-201 sha=<HEAD>`; a
# later change flags it again; the row's own amendment (`amended … by=obligation` at a later commit) clears it; a later
# change again, then an edit in the row's test file that names only ROW-202 leaves it flagged (a shared file's edit
# for another row), and an edit to a line naming ROW-201 clears it; a later change again, then a commit changing the
# row's INVENTORY line clears it. A review attestation is no baseline: the events file holding one changes nothing.
# v0.26.10.3 (R3): a row to confirm (`law-changed`, no resolution) stays listed after edits to its INVENTORY line and
# its test lines; `authority --kept` resolves it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "authority-changed-cleared: $*" >&2; exit 1; }
au_repo "$T/repo"; cp "$CHECKS/inventory.sh" checks/; g add -A && g commit -qm inventory; au_stamp
au_prd 'three days' > PRD.md; g commit -qam 'A-001 restated'
[ "$(au_flags)" = 'ROW-201 A-001' ] || fail "not flagged: '$(au_flags)'"
sh checks/brief.sh authority --kept ROW-201 > /dev/null || fail 'authority --kept refused'
grep -qE "^authority-kept row=ROW-201 sha=$(git rev-parse --short=12 HEAD) at=" .vid/metrics-events || fail 'no authority-kept event at HEAD'
[ -z "$(au_flags)" ] || fail "the kept row is still flagged: '$(au_flags)'"
au_prd 'two days' > PRD.md; g commit -qam 'A-001 again'
[ "$(au_flags)" = 'ROW-201 A-001' ] || fail "the next change does not flag: '$(au_flags)'"
g commit -q --allow-empty -m 'the row amended'
printf 'amended row=ROW-201 sha=%s by=obligation at=2026-10-10T00:00:00Z\n' "$(git rev-parse --short=12 HEAD)" >> .vid/metrics-events
[ -z "$(au_flags)" ] || fail "the row's own amendment did not clear it: '$(au_flags)'"
au_prd 'one day' > PRD.md; g commit -qam 'A-001 once more'
[ "$(au_flags)" = 'ROW-201 A-001' ] || fail "the change after the amendment does not flag: '$(au_flags)'"
printf 'test-reviewed row=ROW-201 result=accept round=1 kind=review commit=%s at=2026-10-11T00:00:00Z\n' "$(git rev-parse --short=12 HEAD)" >> .vid/metrics-events
[ "$(au_flags)" = 'ROW-201 A-001' ] || fail "a review attestation cleared the flag: '$(au_flags)'"
sed 's/^test_ROW_202() { :; }$/test_ROW_202() { : ROW-202 revisited; }/' tests/invariants/links.sh > x && mv x tests/invariants/links.sh; g commit -qam 'ROW-202 revisited'
[ "$(au_flags)" = 'ROW-201 A-001' ] || fail "an edit for another row in the same file cleared it: '$(au_flags)'"
sed 's/^test_ROW_201() { :; }$/test_ROW_201() { : revisited; }/' tests/invariants/links.sh > x && mv x tests/invariants/links.sh; g commit -qam 'ROW-201 revisited'
[ -z "$(au_flags)" ] || fail "an edit to a line naming the row did not clear it: '$(au_flags)'"
au_prd 'twelve hours' > PRD.md; g commit -qam 'A-001 a fourth time'
[ "$(au_flags)" = 'ROW-201 A-001' ] || fail "the change after the test's does not flag: '$(au_flags)'"
sed 's/a link refuses after seven days/a link refuses once its lifetime ends/' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'the row restated'
[ -z "$(au_flags)" ] || fail "a change to the row's line did not clear it: '$(au_flags)'"
# v0.26.10.3 (R3): the baseline clears R6's own flag, never a row to confirm
cp "$CHECKS/metrics.sh" checks/; g add -A && g commit -qm 'the to-confirm reader'
L=$(git rev-parse --short=12 HEAD)
printf 'law-changed row=ROW-201 sha=%s item=REQ-001 at=2026-10-19T00:00:00Z\n' "$L" >> .vid/metrics-events
[ "$(au_flags)" = 'ROW-201 REQ-001 to-confirm=yes' ] || fail "the row to confirm is not listed: '$(au_flags)'"
sed 's/a link refuses once its lifetime ends/a link refuses as soon as its lifetime ends/' INVENTORY.md > i && mv i INVENTORY.md; g commit -qam 'the row restated again'
[ "$(au_flags)" = 'ROW-201 REQ-001 to-confirm=yes' ] || fail "a change to the row's line took the row to confirm off: '$(au_flags)'"
sed 's/^test_ROW_201() { : revisited; }$/test_ROW_201() { : revisited twice; }/' tests/invariants/links.sh > x && mv x tests/invariants/links.sh; g commit -qam 'ROW-201 revisited twice'
[ "$(au_flags)" = 'ROW-201 REQ-001 to-confirm=yes' ] || fail "an edit to its test lines took the row to confirm off: '$(au_flags)'"
sh checks/brief.sh authority --kept ROW-201 > /dev/null || fail 'authority --kept refused the row to confirm'
[ -z "$(au_flags)" ] || fail "authority --kept did not resolve the row to confirm: '$(au_flags)'"
exit 0
