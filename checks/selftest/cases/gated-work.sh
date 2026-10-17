#!/bin/sh
# Purpose: selftest case — work a question gates is flagged (v0.9.5 spec
# 3.1, R1; §7 case 24). Planted events: Q1 gating ROW-004 and ROW-005 asked
# then answered, Q2 gating all remaining work still open. Convicts unless
# `metrics.sh` prints `question FLAG gated-work q=1 row=ROW-004` for a
# `paid` event inside Q1's window and `q=2 row=ROW-009` for a KEPT verdict
# after Q2 was asked, and nothing for a row paid after Q1's answer or a row
# Q1 does not gate. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks .vid
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-004 | behavior | REQ-004 | n/a | n/a | four | REQ-004 | owed: prerequisite — x\n```\n' > INVENTORY.md
cat > .vid/metrics-events <<'EV'
question n=1 state=asked gates=ROW-004,ROW-005 at=2026-09-25T10:00:00Z
paid row=ROW-004 via=ledger at=2026-09-25T10:30:00Z
paid row=ROW-006 via=ledger at=2026-09-25T10:40:00Z
question n=1 state=answered at=2026-09-25T11:00:00Z
paid row=ROW-005 via=ledger at=2026-09-25T11:30:00Z
question n=2 state=asked gates=all at=2026-09-25T12:00:00Z
verdict slice=2 row=ROW-009 result=KEPT class=product brief=b quoted-at=x at=2026-09-25T12:30:00Z
verdict slice=2 row=ROW-010 result=BREACHED class=product brief=b quoted-at=x at=2026-09-25T12:40:00Z
EV
OUT=$(sh checks/metrics.sh 2>/dev/null)
fail() { echo "gated-work: $*" >&2; printf '%s\n' "$OUT" | grep 'question' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^question FLAG gated-work q=1 row=ROW-004 ' || fail 'a paid gated row inside the window was not flagged'
printf '%s\n' "$OUT" | grep -q '^question FLAG gated-work q=2 row=ROW-009 ' || fail 'a KEPT row under an all-gating question was not flagged'
printf '%s\n' "$OUT" | grep -q 'row=ROW-005' && fail 'a row paid after the answer was flagged'
printf '%s\n' "$OUT" | grep -q 'row=ROW-006' && fail 'a row the question does not gate was flagged'
printf '%s\n' "$OUT" | grep -q 'row=ROW-010' && fail 'a BREACHED verdict was flagged'
[ "$(printf '%s\n' "$OUT" | grep -c '^question FLAG')" -eq 2 ] || fail 'not exactly two FLAGs'
exit 0
