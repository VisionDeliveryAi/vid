#!/bin/sh
# Purpose: selftest case — draining hardening (v0.9.7.2 spec 3.10, R14). Under breadth first, while a feature step is
# not done progress shows no Hardening row; once every feature step is done it says `hardening: <n> rows in <k>
# steps`. Where ViD's skills sit beside checks/, vid-develop admits hardening steps next then, and before that only
# into an idle slot with no feature step admissible. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/gated-run.sh"
. "$CHECKS/selftest/fixtures/plan-run.sh"
. "$CHECKS/selftest/fixtures/breadth.sh"
fail() { echo "hardening-next: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
bf_repo "$T/repo"
bf_on > /dev/null; bf_plan "$S1L" "$S2L" "$H1L" > /dev/null
sh checks/plan.sh start S1 > /dev/null; close S1 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed > /dev/null; keepall ROW-001 ROW-002 ROW-003 ROW-004
sh checks/progress.sh > "$T/out" 2>&1; grep -q '^| Hardening |' "$T/out" && fail 'hardening shown with S2 not done'
sh checks/plan.sh start S2 > /dev/null
close S2 ROW-001=passed ROW-002=passed ROW-003=passed ROW-004=passed ROW-005=passed ROW-006=passed ROW-007=passed ROW-008=passed > /dev/null; keepall ROW-005 ROW-006 ROW-007 ROW-008
sh checks/progress.sh > "$T/out" 2>&1; grep -qxF '| Hardening | 4 rows in 1 steps |' "$T/out" || fail "the hardening line: $(grep '^| Hardening' "$T/out")"
D="$CHECKS/../skills/vid-develop/SKILL.md"
if [ -f "$D" ]; then tr '\n' ' ' < "$D" | tr -s ' ' | grep -qF 'Once every feature step is done, the next steps admitted are hardening steps' || fail 'vid-develop does not drain hardening'; fi
exit 0
