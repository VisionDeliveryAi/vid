#!/bin/sh
# Purpose: selftest case — a protected row's owed hostility (v0.9.7.2 spec 3.6, R9; rehearsal R-4). ROW-002 derives
# from the Tier-0 REQ-002. S1 closed and every row KEPT is closed and graded but not done: first no sibling at all
# (`owed-hostility … by=REQ-002`), then a sibling HOS-001 whose test is owed, then one cited without proved-red (both
# `by=HOS-001`); once the probe is materialised and proved red, S1 is done. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "done-hostility-owed: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
derive ROW-002 REQ-002; commit_all protected
bf_on > /dev/null; bf_plan "$S1L" "$S2L" > /dev/null
sh checks/plan.sh start S1 > /dev/null; close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null; keepall ROW-001 ROW-002 ROW-003 ROW-004
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* closed=yes graded=yes done=no ' "$T/out" || fail 'S1 is done with no sibling for REQ-002'
grep -q '^owed-hostility step=S1 row=ROW-002 by=REQ-002' "$T/out" || fail 'the missing sibling is not named'
hostile HOS-001 REQ-002 'owed: prerequisite — the probe needs the tenant fixture'; commit_all 'the sibling, owed'
ss S1 > "$T/out"; grep -q '^owed-hostility step=S1 row=ROW-002 by=HOS-001' "$T/out" || fail 'the owed probe is not named'
grep -q 'done=no' "$T/out" || fail 'S1 is done with its probe owed'
printf '# Purpose: the probe\ndef test_h(): pass  # HOS-001 REQ-002\n' > tests/invariants/test_hos.py
sed 's#owed: prerequisite — the probe needs the tenant fixture#tests/invariants/test_hos.py#' INVENTORY.md > x && mv x INVENTORY.md; commit_all 'the probe, not yet red'
ss S1 > "$T/out"; grep -q '^owed-hostility step=S1 row=ROW-002 by=HOS-001' "$T/out" || fail 'a probe never proved red counts as paid'
PR=$(git rev-parse --short=12 HEAD); sed 's#| tests/invariants/test_hos.py$#| tests/invariants/test_hos.py | proved-red: '"$PR"'#' INVENTORY.md > x && mv x INVENTORY.md; commit_all 'proved red'
ss S1 > "$T/out"; grep -q '^step-state step=S1 .* done=yes ' "$T/out" || fail 'S1 is not done with its probe proved red'
grep -q '^owed-hostility' "$T/out" && fail 'an obligation is still named'
exit 0
