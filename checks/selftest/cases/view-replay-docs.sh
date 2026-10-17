#!/bin/sh
# Purpose: selftest case — the documents at each moment (v0.9.7.4 spec 3.2, R3). The viewer fixture. Convicts
# unless each snapshot reads the documents at its own commit: at the first ratification A-001 answers "Pounds." and
# no promise exists (INVENTORY.md is not yet written); at the second A-001 reads "Pounds and pence." and is
# amended; from setup on the seven promises, D-001 and the two screens appear; and a requirement and a promise
# added after the checkpoint (REQ-003, ROW-008) appear at now only. Env: CHECKS.
set -eu
[ -f "$CHECKS/../viewer/view.sh" ] || exit 0   # the viewer ships in the plugin, not in a project's checks/
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/viewer.sh"
fail() { echo "view-replay-docs: $*" >&2; exit 1; }
view_project "$T/repo"
awk '/^INV-001 \| invariant/ { print "REQ-003 | functional | T1 | A shopper sees the total. | fail-if: no total is shown | phase: pilot | feature: FEAT-01 | plain: A shopper sees the total" } { print }' PRD.md > PRD.x && mv PRD.x PRD.md
awk '/^```$/ && !d { print "ROW-008 | behavior | /cart | shopper | - | The cart shows its total | REQ-003 | tests/invariants/test_s1.py"; d = 1 } { print }' INVENTORY.md > I.x && mv I.x INVENTORY.md
g add -A; vcommit 11:40 'the total'
vview . --out "$T/out" > "$T/r" 2>&1 || fail "the run failed: $(cat "$T/r")"
d() { vdata "$T/out/$1.html"; }
d 20260101T091000Z-prd-ratified | grep -q '{"id":"A-001","amended":false,"tier":"human","date":"2026-01-01","q":"Which currency?","a":"Pounds\.",' || fail 'the first ratification does not read A-001 as first written'
d 20260101T091000Z-prd-ratified | grep -q '"promises":\[\]' || fail 'promises exist before INVENTORY.md does'
d 20260101T092000Z-prd-ratified | grep -q '{"id":"A-001","amended":true,.*"a":"Pounds and pence\."' || fail 'the final ratification does not read the amended A-001'
d 20260101T100000Z-setup-done > "$T/s"; for x in '"id":"ROW-007"' '"id":"D-001"' '"screen":"P01","state":"empty"'; do grep -q "$x" "$T/s" || fail "setup lacks $x"; done
for f in 20260101T112000Z-checkpoint 20260101T105000Z-slice-closed; do if d "$f" | grep -q 'REQ-003\|ROW-008'; then fail "$f reads a document from after its commit"; fi; done
d now | grep -q '"id":"ROW-008"' || fail 'now lacks ROW-008'
d now | grep -q '"id":"REQ-003"' || fail 'now lacks REQ-003'
exit 0
