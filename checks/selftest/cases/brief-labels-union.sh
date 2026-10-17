#!/bin/sh
# Purpose: selftest case — a label adds a match and never removes today's (v0.9.7.3 spec 3.2, R2), both directions.
# The brief-write fixture with bw_builder; the builder brief is ROW-104. Kept, whatever their labels: D-203, which
# cites REQ-004 in its text though labelled with ROW-101 (today's id join); D-304, labelled with ROW-101 only, when
# --decisions names it; D-001, unlabelled and citing no id (the safe rule). Gone: D-304 without --decisions, and D-309,
# labelled with ROW-101's DIF id and naming no screen — a no-id decision labelled outside the brief no longer reaches
# every builder brief. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-labels-union: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
sed 's#^\(- \*\*D-203\*\* .*\)$#\1 | applies-to: ROW-101#' DECISIONS.md > x && mv x DECISIONS.md
printf -- '- **D-304** codes are lower case | why: readable | enforced: convention | applies-to: ROW-101\n- **D-309** the golden create page ignores whitespace | why: the divergence | enforced: convention | applies-to: DIF-002\n' >> DECISIONS.md
sed 's#^\(ROW-101 | .* | tests/invariants/links.sh\)$#\1 | divergence: DIF-002#' INVENTORY.md > x && mv x INVENTORY.md
g commit -qam 'labels outside the brief'
dline() { grep "^- \*\*$1\*\*" DECISIONS.md; }
sec3() { awk '/^## [0-9]/ { on = ($2 == 3); next } on' "$1"; }
bw_write --role builder --slice 2 --step S2 --rows ROW-104 || fail 'the writer refused the builder brief'
sec3 "$(bw_out)" > "$T/s3"
grep -qxF -- "$(dline D-203)" "$T/s3" || fail 'a line the id join quotes today was lost to its label'
grep -qxF -- "$(dline D-001)" "$T/s3" || fail 'an unlabelled no-id line left the safe rule'
grep -q '\*\*D-304\*\*\|\*\*D-309\*\*' "$T/s3" && fail 'a no-id line labelled outside the brief still reaches it'
bw_write --role builder --slice 2 --step S2 --rows ROW-104 --decisions D-304 || fail 'the writer refused --decisions D-304'
sec3 "$(bw_out)" | grep -qxF -- "$(dline D-304)" || fail 'a --decisions id was dropped for its label'
exit 0
