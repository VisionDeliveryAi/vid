#!/bin/sh
# Purpose: selftest case — court runtime is measured, then budgeted
# (v0.9.3 spec 3.13, R17; §7 case 14, the court half). A toy repository
# under `grammar: 0.9.3`; a stub `date` on PATH makes every `date +%s` 400
# seconds later than the last. Convicts unless `inventory.sh --report`
# appends `court name=inventory seconds=400`, metrics.sh prints the slice's
# court seconds and `cost FLAG court-over-budget court=inventory` above the
# 300-second default, a raised `court-seconds` in .vid/budget silences it,
# metrics' own reading records no court event, and a 0.9.2 block records
# nothing. Env: CHECKS.
set -eu
ATRE='at=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'   # v0.9.5 3.11: every event line ends ` at=<UTC>`
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
mkdir -p checks/extractors .vid "$T/bin"
printf '#!/bin/sh\n# Purpose: fixture extractor — keeps the census active\necho "inactive fixture"\n' > checks/extractors/vacuity.ledger.sh
cp "$CHECKS/inventory.sh" "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '# toy\n```vid-placement\napp\n```\n' > CLAUDE.md
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x; paid at slice 2\n```\n' > INVENTORY.md
REAL=$(command -v date)
cat > "$T/bin/date" <<STUB
#!/bin/sh
if [ "\$1" = +%s ]; then n=\$(cat "$T/clock" 2>/dev/null || echo 1000000); n=\$((n + 400)); echo \$n > "$T/clock"; echo \$n; else exec $REAL "\$@"; fi
STUB
chmod +x "$T/bin/date"
printf 'slice-open slice=2 sha=x\n' > .vid/metrics-events
PATH="$T/bin:$PATH" sh checks/inventory.sh --report >/dev/null
fail() { echo "court-timing: $*" >&2; cat .vid/metrics-events >&2; exit 1; }
grep -qxE "court name=inventory seconds=400 $ATRE" .vid/metrics-events || fail 'the inventory court recorded no 400-second event'
OUT=$(sh checks/metrics.sh 2>/dev/null)
printf '%s\n' "$OUT" | grep -q '^cost slice=2 courts seconds=400 inventory=400' || fail 'the slice court seconds'
printf '%s\n' "$OUT" | grep -q '^cost FLAG court-over-budget court=inventory seconds=400 budget=300' || fail 'no court-over-budget FLAG'
[ "$(grep -c '^court ' .vid/metrics-events)" -eq 1 ] || fail "metrics' own census reading recorded a court event"
printf 'court-seconds=500\n' > .vid/budget
sh checks/metrics.sh 2>/dev/null | grep -q 'court-over-budget' && fail 'a raised budget did not silence the FLAG'
sed 's/^grammar: 0.9.3$/grammar: 0.9.2/' INVENTORY.md > i && mv i INVENTORY.md; : > .vid/metrics-events
PATH="$T/bin:$PATH" sh checks/inventory.sh --report >/dev/null
[ ! -s .vid/metrics-events ] || fail 'a 0.9.2 block recorded a court event'
exit 0
