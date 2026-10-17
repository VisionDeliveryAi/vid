#!/bin/sh
# Purpose: selftest case — a pass must be shown passing by its receipt (v0.9.7.0.7 spec 3.3, R7; §6
# C-3). The brief-write fixture with bw_builder and bw_return. Convicts unless `sh checks/brief.sh
# return` refuses ROW-101 | pass on: the RED receipt (its case failed); the STRAY receipt (present,
# never published by a ledger-run event); a receipt an `invalidated` event names; and a receipt that
# runs none of the row's cases — and accepts it on GREEN (the control). v0.9.7.0.11 (3.1, R1): GREEN
# with a `.rows` sidecar that leaves ROW-101 out (its request was frozen with ROW-102 only) is refused
# as running none of the row's cases: the hand-back credits through the credit function. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-return-receipt: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
RF=.vid/briefs/1/builder-1.return.md
blk() { printf 'brief: .vid/briefs/1/builder-1.md\nagent: a1\nbranch: b\ncommit: %s\nROW-101 | pass | %s\nROW-102 | not | none | not built\n' "$(git rev-parse HEAD)" "$1" > "$RF"; }
refused() { blk "$1"; if sh checks/brief.sh return "$RF" > "$T/out" 2>&1; then fail "a pass on $2 was accepted"; fi
  grep -qF "line 5: ROW-101" "$T/out" && grep -qF -- "$3" "$T/out" || fail "the refusal for $2 does not name line 5 and say: $3"; }
refused "$RED" 'a receipt where its case failed' 'does not show the row passing'
refused "$STRAY" 'a receipt never published' 'is not a valid receipt'
S=${GREEN%%.*}; cp .vid/ledger-results/$GREEN .vid/ledger-results/$S.run-OTHER.xml; cp .vid/ledger-results/$GREEN.tree .vid/ledger-results/$S.run-OTHER.xml.tree
printf 'case tests/invariants/links.sh::test_row103[ROW-103] passed 0.1\n' > .vid/ledger-results/$S.run-OTHER.xml.cases
printf 'ledger-run seconds=3 kind=scoped report=%s.run-OTHER.xml status=0 role=builder at=2026-10-02T11:01:00Z\n' "$S" >> .vid/metrics-events
refused "$S.run-OTHER.xml" 'a receipt running none of its cases' 'runs none of the row'"'"'s cases'
printf 'ROW-102\n' > .vid/ledger-results/$GREEN.rows
refused "$GREEN" 'a receipt whose frozen rows leave the row out' 'runs none of the row'"'"'s cases'
rm -f .vid/ledger-results/$GREEN.rows
blk "$GREEN"; sh checks/brief.sh return "$RF" > "$T/out" 2>&1 || fail 'a pass on GREEN was refused'
printf 'invalidated slice=1 report=%s a harness fault\n' "$GREEN" >> .vid/metrics-events
refused "$GREEN" 'an invalidated receipt' 'is not a valid receipt'
exit 0
