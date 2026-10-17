#!/bin/sh
# Purpose: selftest case — metrics.sh must emit the five groups as COUNTS,
# never scores: no percent sign, no index/score/confidence token, no
# target=; the uncalibrated metrics (miss rate, owed count) carry their
# report-only marking and no threshold; the population=1 flag (F7) and the
# Fail-if-amendment count (F9) fire on seeded data. A score-rendered
# metric is the known-bad fixture this case rejects.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks tests/invariants app .vid
cp "$CHECKS/census.sh" checks/census.sh
cp "$CHECKS/metrics.sh" checks/metrics.sh
cp "$CHECKS/lawfiles" checks/lawfiles
touch tests/invariants/test_rule921.py
cat > INVENTORY.md <<'EOF'
# toy
```vid-inventory
ROW-001 | surface | / | anonymous | n/a | home renders | REQ-001 | owed: scaffold
ROW-002 | behavior | REQ-002 | n/a | n/a | the deployed worker consumes the schedule | REQ-002 | owed: paid by /vid deploy gate 2 — a digest arrives from staging
rule | RULE-921 | seeded one-site rule | printf 'site-a\n' | T1 | tests/invariants/test_rule921.py
seam | SEAM-921 | somefeed | listings feed | chosen: D-001 | credentials: never | probe: owed | evidence: owed | quirks: none yet | match: somefeed.io
```
EOF
printf '# Purpose: toy\n' > app/x.py
git add -A && git -c user.email=vid@selftest -c user.name=vid commit -qm root
printf '# Purpose: toy2\n' > app/y.py
git add app/y.py && git -c user.email=vid@selftest -c user.name=vid commit -qm work
cat > .vid/metrics-events <<'EOF'
verdict slice=1 claimed=12 breached=3
re-verdict slice=1 round=2 breached=1
attempts row=ROW-001 n=1
attempts row=ROW-002 n=2
reverted row=ROW-002
regressions slice=1 n=0
tokens slice=1 phase=build n=100000
tokens slice=1 phase=verdict n=40000
tokens slice=1 phase=fix n=30000
tokens slice=1 phase=re-verdict n=15000
tokens slice=1 phase=review n=8000
paid row=ROW-001 via=ledger
paid row=ROW-002 via=ledger
rows-paid slice=1 n=12
owed-close slice=1 n=5
wall-clock slice=1 seconds=3600
ledger-run seconds=180
incident slice=1 docker restart mid-suite
agent-death slice=1 builder-3
stall op=ledger elapsed=2400 envelope=1200
failif-amendment n=1
EOF
OUT=$(sh checks/metrics.sh) || exit 1
# the five groups are present
for g in progress honesty evidence cost friction; do
  printf '%s\n' "$OUT" | grep -q "^$g " || exit 1
done
# counts, never scores: no percent sign, no score/index/confidence, no target=
printf '%s\n' "$OUT" | grep -qF '%' && exit 1
printf '%s\n' "$OUT" | grep -qiE '\b(score|index|confidence)\b' && exit 1
printf '%s\n' "$OUT" | grep -qF 'target=' && exit 1
# calibration discipline: the uncalibrated metrics report only, no threshold
printf '%s\n' "$OUT" | grep -E 'verdict claimed=' | grep -q 'uncalibrated' || exit 1
printf '%s\n' "$OUT" | grep -E 'owed-now=' | grep -q 'uncalibrated' || exit 1
# the two new tripwires fire on seeded data
printf '%s\n' "$OUT" | grep -q 'FLAG population=1 rule=RULE-921' || exit 1
printf '%s\n' "$OUT" | grep -q 'failif-amendments n=1' || exit 1
# the review phase (v0.9.1 3.2) is reported in the cost line, beside the four develop phases
printf '%s\n' "$OUT" | grep -q 'cost slice=1 tokens build=100000 verdict=40000 fix=30000 re-verdict=15000 review=8000 ' || exit 1
# the proof-channel tripwire (v0.9.1 3.6): a deploy-owed row paid by a sandbox channel flags; paid by deploy it does not
printf '%s\n' "$OUT" | grep -q 'honesty FLAG sandbox-proof row=ROW-002 via=ledger' || exit 1
printf '%s\n' "$OUT" | grep -q 'honesty paid rows=2 deploy-owed-paid-by-sandbox=1' || exit 1
sed -i.bak 's/^paid row=ROW-002 via=ledger$/paid row=ROW-002 via=deploy/' .vid/metrics-events && rm -f .vid/metrics-events.bak
sh checks/metrics.sh | grep -q 'FLAG sandbox-proof' && exit 1
sh checks/metrics.sh | grep -q 'honesty paid rows=2 deploy-owed-paid-by-sandbox=0' || exit 1
# stalls from the watchdog substrate are counted
printf '%s\n' "$OUT" | grep -q 'stalls-detected=1' || exit 1
# --slice filtering still emits a well-formed block
sh checks/metrics.sh --slice 1 >/dev/null || exit 1
exit 0
