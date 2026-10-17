#!/bin/sh
# Purpose: selftest case — a builder brief's decisions, the safe rule (v0.9.7.0.7 spec 3.2, R5; §6
# B-2). The brief-write fixture with bw_builder; the brief is ROW-104 (marker P03/form, item REQ-004).
# Convicts unless section 3 keeps: a line citing no ROW-/REQ- id and naming no screen code (D-001);
# a line citing a briefed id whole even when it names another step's screen (D-203: P01, REQ-004);
# an id-free line naming the step's screen (D-201: P03) and one naming it with another (D-204: P01
# and P03); a --decisions id that names another screen (D-202). And drops: an id-free line naming
# only another screen (D-202, without --decisions); a line citing an id not briefed (D-004: REQ-024).
# Whole lines, why: included. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-builder-decisions: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
dline() { grep "^- \*\*$1\*\*" DECISIONS.md; }
sec3() { awk '/^## [0-9]/ { on = ($2 == 3); next } on' "$1"; }
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the builder brief'
sec3 "$(bw_out)" > "$T/s3"
for d in D-001 D-203 D-201 D-204; do grep -qxF -- "$(dline $d)" "$T/s3" || fail "section 3 lacks $d whole"; done
grep -q 'D-202' "$T/s3" && fail 'an id-free line naming only another screen (P01) stayed'
grep -q 'D-004' "$T/s3" && fail 'a line citing an id not briefed (REQ-024) stayed'
bw_write --role builder --slice 2 --step S2 --rows ROW-104 --decisions D-202 || fail 'the writer refused --decisions D-202'
sec3 "$(bw_out)" | grep -qxF -- "$(dline D-202)" || fail 'a --decisions id was dropped by the screen narrowing'
exit 0
