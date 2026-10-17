#!/bin/sh
# Purpose: selftest case — labels by role (v0.9.7.3 spec 3.2, R2). The brief-write fixture with bw_builder; briefs of
# ROW-104 (marker P03/form). A line labelled with the briefed row (D-301) or its screen code (D-302) reaches the
# builder, the fixer and the grader — the grader its rule only, the line up to ' | why:'; a `scope: project` line
# (D-305) reaches the builder only. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-labels-roles: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
cat >> DECISIONS.md <<'DEC'
- **D-301** deletion answers in one sentence | why: one voice | enforced: convention | applies-to: ROW-104
- **D-302** the form keeps its labels above the fields | why: scanning | enforced: convention | applies-to: P03
- **D-305** every page carries the product name | why: one brand | enforced: convention | scope: project
DEC
g commit -qam 'labelled decisions'
mkdir -p .vid/ledger-results; S=$(git rev-parse --short=12 HEAD); printf '<report/>\n' > ".vid/ledger-results/$S.full.xml"
dline() { grep "^- \*\*$1\*\*" DECISIONS.md; }
rule() { l=$(dline "$1"); printf '%s\n' "${l%% | why:*}"; }
sec3() { awk '/^## [0-9]/ { on = ($2 == 3); next } on' "$1"; }
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the builder brief'
sec3 "$(bw_out)" > "$T/b"
for d in D-301 D-302 D-305; do grep -qxF -- "$(dline $d)" "$T/b" || fail "the builder lacks $d"; done
bw_write --role fixer --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the fixer brief'
sec3 "$(bw_out)" > "$T/f"
for d in D-301 D-302; do grep -qxF -- "$(dline $d)" "$T/f" || fail "the fixer lacks $d"; done
grep -q '\*\*D-305\*\*' "$T/f" && fail 'a scope: project line reached the fixer'
bw_write --role grader --slice 2 --rows ROW-104 --receipt "$S.full.xml" || fail 'the writer refused the grader brief'
sec3 "$(bw_out)" > "$T/g"
for d in D-301 D-302; do grep -qxF -- "$(rule $d)" "$T/g" || fail "the grader lacks $d's rule"; done
grep -q 'applies-to:\|why:' "$T/g" && fail 'the grader got more than the rule'
grep -q '\*\*D-305\*\*' "$T/g" && fail 'a scope: project line reached the grader'
exit 0
