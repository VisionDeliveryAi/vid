#!/bin/sh
# Purpose: selftest case — a builder brief quotes a decision by its label (v0.9.7.3 spec 3.2, R2). The brief-write
# fixture with bw_builder; the brief is ROW-104 (marker P03/form, item REQ-004, rule RULE-001, divergence DIF-001).
# Each decision below cites no id in its text. Convicts unless section 3 keeps the lines labelled `applies-to:` the
# briefed row (D-301), its screen code (D-302), its rule row by the RULE join (D-303), its DIF id (D-307) and a
# `scope: project` line naming no screen (D-305); and drops one labelled with a row outside the brief (D-304, which
# the safe rule kept while unlabelled), one labelled with another DIF (D-308), and a `scope: project` line naming
# only another step's screen (D-306: P01, today's screen narrowing). Whole lines. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-labels: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
sed 's#^\(ROW-104 | .* | tests/invariants/links.sh\)$#\1 | divergence: DIF-001#' INVENTORY.md > x && mv x INVENTORY.md
cat >> DECISIONS.md <<'DEC'
- **D-301** deletion answers in one sentence | why: one voice | enforced: convention | applies-to: ROW-104
- **D-302** the form keeps its labels above the fields | why: scanning | enforced: convention | applies-to: P03
- **D-303** the token comparison is constant-time | why: no timing leak | enforced: convention | applies-to: RULE-001
- **D-304** codes are lower case | why: readable | enforced: convention | applies-to: ROW-101
- **D-305** every page carries the product name | why: one brand | enforced: convention | scope: project
- **D-306** the P01 header is bold | why: one layout | enforced: convention | scope: project
- **D-307** the golden deletion page is compared byte for byte | why: the divergence is paid | enforced: convention | applies-to: DIF-001
- **D-308** the golden create page ignores whitespace | why: another divergence | enforced: convention | applies-to: DIF-002
DEC
g commit -qam 'labelled decisions'
dline() { grep "^- \*\*$1\*\*" DECISIONS.md; }
sec3() { awk '/^## [0-9]/ { on = ($2 == 3); next } on' "$1"; }
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the builder brief'
sec3 "$(bw_out)" > "$T/s3"
for d in D-301 D-302 D-303 D-305 D-307; do grep -qxF -- "$(dline $d)" "$T/s3" || fail "section 3 lacks $d whole"; done
for d in D-304 D-306 D-308; do grep -q "\*\*$d\*\*" "$T/s3" && fail "section 3 keeps $d, labelled outside the brief"; done
exit 0
