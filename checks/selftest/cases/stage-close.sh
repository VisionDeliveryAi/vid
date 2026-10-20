#!/bin/sh
# Purpose: selftest case — a stage closes on stages 1 to N alone (v0.26.10.5 spec R8; §5 stage-close). The toy
# two-stage product (fixtures/stages.sh) with a deploy-owed stage-1 row (ROW-007) and stage 2's REQ-004 cited by no
# code (coverage debt of a later stage). With every stage-1 obligation passing in the full run, its rows KEPT, its
# probe and rule case passing, and stage 2's ROW-004 red: `stage-close --stage 1` is ready, ROW-007 listed as deploy
# debt (gate 2 and what it observes), not required, and a question gating only a stage-2 row doesn't block. Unmet,
# each alone: a red stage-1 row; a red stage-1 HOS probe; a failing stage-1 RULE case with the census clean; a
# to-confirm stage-1 row; an open question gating a stage-1 row. Stage 2, with ROW-004 red and REQ-004 uncited: unmet,
# both named. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "stage-close: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
st_close_repo "$T/r"
awk '/^hostility \| HOS-001 /{ print "ROW-007 | behavior | REQ-002 | anonymous | n/a | the saved-note mail arrives | REQ-002 | owed: paid by /vid deploy gate 2 — the mail provider delivers it" } { print }' INVENTORY.md > INVENTORY.x && mv INVENTORY.x INVENTORY.md
printf '# Purpose: toy app — REQ-001 REQ-002 REQ-003 REQ-005\n' > app/main.py
g add -A && g commit -qm 'a deploy-owed row; REQ-004 not yet built'
st_keep ROW-001 ROW-002; cp .vid/metrics-events "$T/ev0"
close1() { cp "$T/ev0" .vid/metrics-events; for _l in "$@"; do printf '%s at=2026-10-20T00:00:05Z\n' "$_l" >> .vid/metrics-events; done; sh checks/metrics.sh stage-close --stage 1 > "$T/out" 2>&1 || fail 'stage-close exited non-zero'; }
# ready
st_rcpt ROW-004=failed ROW-005=failed
close1 'question n=1 state=asked gates=ROW-004'
grep -qx 'stage-close 1 ready rows=3 debt=1' "$T/out" || fail 'stages 1 to 1 hold and the close is not ready rows=3 debt=1'
grep -qx 'debt ROW-007 gate 2 — the mail provider delivers it' "$T/out" || fail 'the deploy-owed row is not listed as debt with what it needs'
# unmet, each alone
st_rcpt ROW-001=failed ROW-004=failed; close1
grep -q '^unmet ROW-001: red' "$T/out" && grep -q '^stage-close 1 unmet=' "$T/out" || fail 'a red stage-1 row did not leave the close unmet'
st_rcpt HOS-002=failed ROW-004=failed; close1
grep -q '^unmet HOS-002: not green' "$T/out" && grep -q '^stage-close 1 unmet=' "$T/out" || fail 'a red stage-1 probe did not leave the close unmet'
st_rcpt RULE-001=failed ROW-004=failed
sh checks/census.sh > /dev/null 2>&1 || fail 'the census is not clean in the fixture'
close1
grep -q '^unmet RULE-001: not green' "$T/out" && grep -q '^stage-close 1 unmet=' "$T/out" || fail 'a failing stage-1 rule case with a clean census did not leave the close unmet'
st_rcpt ROW-004=failed
close1 "law-changed row=ROW-002 sha=$(git rev-parse --short=12 HEAD) item=REQ-002"
grep -q '^unmet ROW-002: to confirm' "$T/out" || fail 'a to-confirm stage-1 row did not leave the close unmet'
close1 'question n=2 state=asked gates=ROW-004,ROW-001'
grep -q '^unmet open question Q2 gates ROW-001' "$T/out" || fail 'an open question gating a stage-1 row did not leave the close unmet'
close1 'question n=2 state=asked gates=ROW-001' 'question n=2 state=answered'
grep -q '^stage-close 1 ready' "$T/out" || fail 'an answered question still blocked the close'
# stage 2: its red row and its coverage debt
sh checks/metrics.sh stage-close --stage 2 > "$T/out" 2>&1 || true
grep -q '^unmet ROW-004: red' "$T/out" && grep -q '^unmet coverage: not clean for stages 1 to 2' "$T/out" || fail 'stage 2 does not name its red row and its coverage'
exit 0
