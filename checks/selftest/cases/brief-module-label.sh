#!/bin/sh
# Purpose: selftest case — a module label reaches builders only (v0.26.10.2 spec R17b). The brief-write fixture with
# bw_builder, its plan's step S2 naming `tests.invariants` (a dotted form) beside app; ARCHITECTURE.md's row
# tests.invariants is the module tests/invariants. D-310 is labelled only with tests/invariants, D-311 only with
# app/other, a module S2 does not name. Convicts unless the builder's brief for S2 quotes D-310 whole and not D-311,
# and a grader's brief of the same rows quotes neither. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-module-label: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
sed 's/modules: app tests\/invariants\/ |/modules: app tests.invariants |/' .vid/plans/0123456789ab.plan > p.x && mv p.x .vid/plans/0123456789ab.plan
grep -q 'modules: app tests.invariants |' .vid/plans/0123456789ab.plan || fail 'the plan was not rewritten'
cat >> DECISIONS.md <<'DEC'
- **D-310** the ledger reaches the product through its harness entry only | why: one door | enforced: convention | applies-to: tests/invariants
- **D-311** the other module keeps no state | why: restarts | enforced: convention | applies-to: app/other
DEC
g commit -qam 'module-labelled decisions'
mkdir -p .vid/ledger-results; S=$(git rev-parse --short=12 HEAD); printf '<report/>\n' > ".vid/ledger-results/$S.full.xml"
dline() { grep "^- \*\*$1\*\*" DECISIONS.md; }
sec3() { awk '/^## [0-9]/ { on = ($2 == 3); next } on' "$1"; }
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the builder brief'
sec3 "$(bw_out)" > "$T/b"
grep -qxF -- "$(dline D-310)" "$T/b" || fail 'the builder lacks D-310, labelled with its step module'
grep -q '\*\*D-311\*\*' "$T/b" && fail 'a decision labelled for another module reached the builder'
bw_write --role grader --slice 2 --rows ROW-104 --receipt "$S.full.xml" || fail 'the writer refused the grader brief'
sec3 "$(bw_out)" > "$T/g"
grep -q '\*\*D-31[01]\*\*' "$T/g" && fail 'a module-labelled decision reached the grader'
exit 0
