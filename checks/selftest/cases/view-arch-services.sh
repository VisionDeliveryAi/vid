#!/bin/sh
# Purpose: selftest case — outside services as written (v0.26.10.2 spec R5). The viewer fixture with view_arch.
# Convicts unless now holds the three seam rows, each field by its label and as written, a `match:` field not read,
# and module null where the row names none. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-arch-services: $*" >&2; exit 1; }
view_project "$T/repo"; view_arch 11:40
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
N="$T/out/now.html"
varch "$N" | grep -qF '{"id":"SEAM-001","service":"Pay","purpose":"taking payments","chosen":"D-001","credentials":"held","probe":"probed(2026-01-01)","evidence":"tests/contracts/pay.py + tests/contracts/captured/","quirks":"none yet","module":"app/s1"}' || fail "SEAM-001 is not as written: $(varch "$N" | grep SEAM-001)"
varch "$N" | grep -qF '{"id":"SEAM-002","service":"Mail","purpose":"sending receipts","chosen":"D-404","credentials":"not-yet","probe":"unreachable-risk(no account yet)","evidence":"owed","quirks":"none yet","module":null}' || fail "SEAM-002 is not as written: $(varch "$N" | grep SEAM-002)"
varch "$N" | grep -qF '"id":"SEAM-003",' || fail 'SEAM-003 is missing'
varch "$N" | grep -q mailer && fail 'the match: field was read'
exit 0
