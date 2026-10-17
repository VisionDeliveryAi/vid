#!/bin/sh
# Purpose: selftest case — a builder brief's test locations (v0.9.7.0.7 spec 3.2, R4; §6 B-3). The
# brief-write fixture with bw_builder. Convicts unless section 9 gives, one line per row: ROW-104 the
# lines of its test file holding ROW-104 as a whole id; ROW-120 the surface file's parameter-table
# line naming it (and not the line naming ROW-12, nor would ROW-12 match ROW-120); ROW-105, an owed
# row, `owed`; and a row whose file names it nowhere `none`, with the writer printing `write: 1 rows
# without a test location` and still writing the brief. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/brief-write.sh"
fail() { echo "brief-builder-locations: $*" >&2; cat "$T/wout" >&2 2>/dev/null; exit 1; }
bw_plugin; bw_repo "$T/repo"; bw_builder
sec9() { awk '/^## [0-9]/ { on = ($2 == 9); next } on && NF' "$1"; }
bw_write --role builder --slice 2 --step S2 --rows ROW-104,ROW-120,ROW-105 || fail 'the writer refused the builder brief'
sec9 "$(bw_out)" > "$T/s9"
L104=$(grep -n 'ROW-104' tests/invariants/links.sh | cut -d: -f1 | paste -sd, -)
L120=$(grep -n 'ROW-120' tests/invariants/surfaces.sh | cut -d: -f1 | paste -sd, -)
[ "$(cat "$T/s9")" = "ROW-104 tests/invariants/links.sh:$L104
ROW-120 tests/invariants/surfaces.sh:$L120
ROW-105 owed" ] || fail "section 9 is not the three locations: $(cat "$T/s9")"
grep -q 'rows without a test location' "$T/wout" && fail 'a row with a location was reported'
# the parameter-table line names ROW_104 too: a surface row in the other spelling is found
sed -i.bak 's#ROW-104 | behavior | REQ-004 | anonymous | P03/form | \(.*\) | REQ-004 | tests/invariants/links.sh#ROW-104 | behavior | REQ-004 | anonymous | P03/form | \1 | REQ-004 | tests/invariants/surfaces.sh#' INVENTORY.md && rm -f INVENTORY.md.bak
sed -i.bak 's#^ROW-120 .*#ROW-12 | surface | /x/ | anonymous | P03/form | a row whose id ROW-120 extends | REQ-004 | tests/invariants/surfaces.sh#' INVENTORY.md && rm -f INVENTORY.md.bak
sed -i.bak 's/ROW-104 ROW-120 ROW-105/ROW-104 ROW-12 ROW-105/' .vid/plans/0123456789ab.plan && rm -f .vid/plans/0123456789ab.plan.bak
g commit -qam spellings
bw_write --role builder --slice 2 --step S2 --rows ROW-104,ROW-12 || fail 'the writer refused a brief with a row without a location'
sec9 "$(bw_out)" > "$T/s9"
grep -qx "ROW-104 tests/invariants/surfaces.sh:$(grep -n 'ROW_104' tests/invariants/surfaces.sh | cut -d: -f1)" "$T/s9" || fail "ROW_104's parameter-table line was not found: $(cat "$T/s9")"
grep -qx 'ROW-12 none' "$T/s9" || fail "ROW-12 matched inside ROW-120 or its comment: $(cat "$T/s9")"
grep -qx 'write: 1 rows without a test location' "$T/wout" || fail 'the writer did not report the row without a location'
grep -q '^ViD brief: ok' "$T/wout" || fail 'a row without a location refused the brief'
exit 0
