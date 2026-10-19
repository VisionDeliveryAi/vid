#!/bin/sh
# Purpose: selftest case — an older viewer folder (v0.26.10.2 spec R8, R13). The viewer fixture with view_arch. A
# first run, then its folder made as the previous view.sh leaves one: no blob of the new kinds (arch, base, seam,
# dec2), no history, no data entries (its code hash differed), and each DECISIONS.md blob cached as the old kind
# dec, without enforced. Convicts unless the next run reads the services and the stack (not "not recorded") and
# every technical decision carries its enforced: as written. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-old-cache: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the first run failed: $(cat "$T/r")"
B="${T:?}/out/.cache/blob"; rm -rf "${T:?}/out/.cache/hist" "${T:?}/out/.cache/data"; mkdir "$T/out/.cache/data"
for f in "$B"/*.dec2; do awk -F'\t' -v OFS='\t' '{ NF = 6; print }' "$f" > "${f%.dec2}.dec"; done
for f in "$B"/*.arch "$B"/*.base "$B"/*.seam "$B"/*.dec2; do [ -f "$f" ] && rm -f "$f"; done
ls "$B"/*.dec >/dev/null 2>&1 || fail 'no old decisions cache was planted'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the second run failed: $(cat "$T/r")"
N="$T/out/now.html"
varch "$N" | grep -qF '{"id":"SEAM-001",' || fail "the services are not read through an older folder: $(varch "$N" | tail -n 1)"
varch "$N" | grep -q '"part":"services"\|"part":"stack"' && fail 'services or the stack read as not recorded'
vdata "$N" | grep -qF '{"id":"D-001","what":"Prices are held in pence","why":"no rounding","appliesTo":"REQ-001","scope":null,"enforced":"convention",' || fail "D-001 lacks its enforced: $(vdata "$N" | grep -F '"id":"D-001"')"
exit 0
