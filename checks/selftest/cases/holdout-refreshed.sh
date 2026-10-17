#!/bin/sh
# Purpose: selftest case — fresh grading data (v0.9.8 spec 3.5, R9). A fixture whose Provenance: header says
# `regression` (a grader's case once used to fix the product) and that names ROW-201 is listed under the grader brief's
# `### Regression cases`, with the instruction to grade on fresh cases; a hand-authored fixture naming ROW-201, and a
# regression fixture naming only ROW-202, are not; a brief for ROW-202 alone lists the latter, and a brief for a row
# none names says none. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
. "$CHECKS/selftest/fixtures/authority.sh"
fail() { echo "holdout-refreshed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
au_repo "$T/repo"; au_more
mkdir -p tests/fixtures
printf '# Provenance: regression — the grader'"'"'s counterexample of ROW-201, used by the fix at abc123\nlink-created-6d23h59m\n' > tests/fixtures/expiry-edge.txt
printf '# Provenance: hand-authored\nROW-201 a fresh link\n' > tests/fixtures/fresh.txt
printf '# Provenance: regression — the grader'"'"'s case of ROW_202, used by the fix at def456\ncode-5chars\n' > tests/fixtures/short-code.txt
g add -A && g commit -qm fixtures
mkdir -p .vid/ledger-results; printf '<report/>\n' > .vid/ledger-results/r.xml
w() { CLAUDE_PLUGIN_ROOT=$P sh checks/brief.sh write --role grader --slice 1 --rows "$1" --receipt r.xml > "$T/out" 2>&1 || fail "the grader brief for $1 was refused"; sed -n 's/^ViD brief write: //p' "$T/out" | head -n 1; }
sec() { awk '/^### Regression cases/ { on = 1; next } on && /^###? / { exit } on' "$1"; }
sec "$(w ROW-201)" > "$T/s"
grep -qx 'tests/fixtures/expiry-edge.txt — ROW-201' "$T/s" || fail 'the regression fixture naming ROW-201 is not listed'
grep -q 'grade on fresh cases' "$T/s" || fail 'the section does not ask for fresh cases'
grep -q 'fresh.txt\|short-code.txt' "$T/s" && fail 'a hand-authored fixture or another row'"'"'s regression is listed'
sec "$(w ROW-202)" | grep -qx 'tests/fixtures/short-code.txt — ROW-202' || fail 'the regression fixture naming ROW_202 is not listed for ROW-202'
[ "$(sec "$(w ROW-205)" | grep -v '^$')" = none ] || fail 'a row no regression names does not say none'
exit 0
