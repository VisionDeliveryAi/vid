#!/bin/sh
# Purpose: selftest case — the seam row's module: field changes no court (v0.26.10.2 spec R17d). A toy INVENTORY.md
# with one owed seam, written once with `| module: app/pay` and once without. Convicts unless checks/seams.sh refuses
# the staged client line in both, naming the row, and checks/inventory.sh prints the same and exits the same in
# both. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "seam-module-field: $*" >&2; exit 1; }
for v in with without; do
  mkdir -p "$T/$v"; cd "$T/$v"; git init -q
  f=''; [ "$v" = with ] && f=' | module: app/pay'
  printf '# toy\n```vid-inventory\nseam | SEAM-901 | examplepay | card charges | chosen: D-001 | credentials: not-yet | probe: owed | evidence: owed | quirks: none yet%s | match: examplepay\n```\n' "$f" > INVENTORY.md
  mkdir -p app; printf '# Purpose: client\nimport examplepay\n' > app/pay.py; git add -A
  if sh "$CHECKS/seams.sh" > "$T/$v.seams" 2>&1; then fail "seams.sh passed owed client code ($v the field)"; fi
  grep -q 'SEAM-901' "$T/$v.seams" || fail "seams.sh does not name the row ($v the field): $(cat "$T/$v.seams")"
  set +e; sh "$CHECKS/inventory.sh" > "$T/$v.inv" 2>&1; echo $? > "$T/$v.st"; set -e
done
cmp -s "$T/with.st" "$T/without.st" || fail 'inventory.sh exits differently with the field'
cmp -s "$T/with.inv" "$T/without.inv" || fail "inventory.sh prints differently with the field: $(diff "$T/with.inv" "$T/without.inv")"
exit 0
