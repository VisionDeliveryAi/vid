#!/bin/sh
# Purpose: selftest case — section 5's history (v0.9.7.1 spec 3.2b, R2). The brief-write fixture with bw_builder
# and bw_return (receipts GREEN and RED, RED published last). Convicts unless a builder brief's section 5 says
# "history: results on earlier trees; not evidence for this brief; run your rows first" and gives each case's
# newest result — ROW-101's case failed on RED, ROW-102's passed on RED, each with its receipt and `tree=` — and
# no line names the unpublished STRAY; after RED is invalidated, both pass on GREEN; after GREEN's frozen rows
# (.rows) name only ROW-102, ROW-101 reads `not run`; a failure carries its first message line, joined across a
# report naming cases by class and .cases naming them by path. The check says ok on each. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-states: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder; bw_return || fail 'the fixture brief was refused'
TR=$(git rev-parse 'HEAD^{tree}' | cut -c1-12)
c1='tests/invariants/links.sh::test_row101[ROW-101]'; c2='tests/invariants/links.sh::test_row102[ROW-102]'
sec5() { awk '/^## [0-9]/ { on = ($2 == 5); next } on' "$1"; }
# RED's report names its cases by class (tests.invariants.links::…), as some producers do; .cases by path
printf '<testsuite><testcase classname="tests.invariants.links" name="test_row101[ROW-101]"><failure message="boom: the link is gone">x</failure></testcase><testcase classname="tests.invariants.links" name="test_row102[ROW-102]"/></testsuite>\n' > ".vid/ledger-results/$RED"
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || fail 'the second brief was refused'
B=$(bw_out); grep -q '^ViD brief: ok' "$T/wout" || fail 'the check did not say ok'
sec5 "$B" | grep -qx 'history: results on earlier trees; not evidence for this brief; run your rows first' || fail 'no history label'
sec5 "$B" | grep -qF "ROW-101 $c1 failed $RED tree=$TR — boom: the link is gone" || fail "ROW-101 is not failed on RED with its first message: $(sec5 "$B")"
sec5 "$B" | grep -qxF "ROW-102 $c2 passed $RED tree=$TR" || fail "ROW-102 is not passed on RED: $(sec5 "$B")"
sec5 "$B" | grep -qF "$STRAY" && fail 'an unpublished receipt reached the history'
printf 'invalidated slice=1 report=%s toy at=2026-10-02T12:00:00Z\n' "$RED" >> .vid/metrics-events
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || fail 'the third brief was refused'
B=$(bw_out)
sec5 "$B" | grep -qxF "ROW-101 $c1 passed $GREEN tree=$TR" || fail "after the invalidation ROW-101 is not passed on GREEN: $(sec5 "$B")"
printf 'ROW-102\n' > .vid/ledger-results/$GREEN.rows
bw_write --role builder --slice 1 --step S1 --rows ROW-101,ROW-102 || fail 'the fourth brief was refused'
B=$(bw_out)
sec5 "$B" | grep -qx 'ROW-101 not run' || fail "a receipt credited ROW-101 outside its frozen rows: $(sec5 "$B")"
sec5 "$B" | grep -qxF "ROW-102 $c2 passed $GREEN tree=$TR" || fail 'ROW-102 lost its credited result'
exit 0
