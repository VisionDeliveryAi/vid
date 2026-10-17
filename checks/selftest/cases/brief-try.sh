#!/bin/sh
# Purpose: selftest case — the attempt id (v0.9.7.1 spec 3.2a, R2). The brief-write fixture with bw_builder.
# Convicts unless a builder brief's header carries `try: 2-builder-1`, `branch: vid/2-builder-1` and `return:
# <the run's home, absolute>/.vid/briefs/2/builder-1.return.md`; the next builder brief of the slice is
# `2-builder-2`; a fixer brief carries `try: 2-fixer-1`; a grader brief carries none; and each write records
# `brief-written path=<brief> role=<role> try=<try|-> bytes=<the file's size>`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-try: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'a builder brief was refused'
B=$(bw_out)
grep -qx 'try: 2-builder-1' "$B" || fail 'no try: 2-builder-1 in the header'
grep -qx 'branch: vid/2-builder-1' "$B" || fail 'no branch: vid/2-builder-1'
grep -qx "return: $(pwd -P)/.vid/briefs/2/builder-1.return.md" "$B" || fail "the return path is not the home's, absolute: $(grep '^return:' "$B")"
[ "$(sed -n 's/^try: //p' "$B")" = "$(head -n 12 "$B" | sed -n 's/^try: //p')" ] || fail 'try: is not in the header'
grep -qx "brief-written path=$B role=builder try=2-builder-1 bytes=$(wc -c < "$B" | tr -d ' ') at=.*" .vid/metrics-events || grep -q "^brief-written path=$B role=builder try=2-builder-1 bytes=$(wc -c < "$B" | tr -d ' ') at=" .vid/metrics-events || fail "no brief-written event with the file's size: $(grep '^brief-written' .vid/metrics-events)"
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'a second builder brief was refused'
grep -qx 'try: 2-builder-2' "$(bw_out)" || fail 'the second brief is not 2-builder-2'
bw_write --role fixer --slice 2 --step S2 --rows ROW-104 || fail 'a fixer brief was refused'
grep -qx 'try: 2-fixer-1' "$(bw_out)" || fail 'the fixer brief has no try: 2-fixer-1'
mkdir -p .vid/ledger-results; printf '<report/>\n' > .vid/ledger-results/r.xml
bw_write --role grader --slice 2 --rows ROW-104 --receipt r.xml || fail 'a grader brief was refused'
G=$(bw_out); grep -q '^try:\|^branch:\|^return:' "$G" && fail 'a grader brief carries an attempt id'
grep -q "^brief-written path=$G role=grader try=- bytes=" .vid/metrics-events || fail 'the grader brief has no brief-written event'
exit 0
