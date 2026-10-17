#!/bin/sh
# Purpose: selftest case — the slice against modules and the three
# tripwires (v0.9.3 spec 3.8, 3.13; R7; §7 case 14, the tripwire half). A
# toy repository under `grammar: 0.9.3` with real commits between a
# `slice-open` and a `slice-close`. Convicts unless metrics.sh prints the
# slice's modules and its seam-table changes (the commits touching
# ARCHITECTURE.md between the two shas); `verdict slice=N claimed=80` FLAGs
# `claims-per-slice` and `claimed=40` does not; nine hours of `wall-clock`
# FLAG `wall-per-slice` and two do not; a session-written `stall` FLAGs
# `pass-over-envelope`; a raised budget in .vid/budget silences the claims
# FLAG; and a 0.9.2 block prints none of it. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks app .vid
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/lawfiles" checks/
printf '.vid/\n' > .gitignore
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x; paid at slice 2\n```\n' > INVENTORY.md
printf '| Module | Responsibility | Owned | Public surface | Dependents |\n|---|---|---|---|---|\n| app/feed | feed | f | `app.feed` | none |\n' > ARCHITECTURE.md
printf '# Purpose: toy\n' > app/main.py
g add -A && g commit -qm root; S0=$(git rev-parse --short=12 HEAD)
printf '| app/search | search | s | `app.search` | none |\n' >> ARCHITECTURE.md; g commit -qam 'seam: search'
printf '# Purpose: toy, more\n' >> app/main.py; g commit -qam work
printf '| app/notify | notify | n | `app.notify` | none |\n' >> ARCHITECTURE.md; g commit -qam 'seam: notify'
S1=$(git rev-parse --short=12 HEAD)
cat > .vid/metrics-events <<EV
slice-open slice=3 sha=$S0
slice-modules slice=3 app/feed app/search app/notify
verdict slice=3 claimed=80 breached=4
wall-clock slice=3 seconds=32400
slice-close slice=3 sha=$S1
slice-open slice=4 sha=$S1
verdict slice=4 claimed=40 breached=0
wall-clock slice=4 seconds=7200
stall op=builder-4 elapsed=12000 envelope=10800
EV
OUT=$(sh checks/metrics.sh 2>/dev/null)
fail() { echo "slice-tripwires: $*" >&2; printf '%s\n' "$OUT" | grep -E 'FLAG|modules' >&2; exit 1; }
printf '%s\n' "$OUT" | grep -q '^progress slice=3 modules n=3 seam-changes n=2 ' || fail 'the slice against modules'
printf '%s\n' "$OUT" | grep -q '^progress slice=4 modules n=0 seam-changes n=0 (open)' || fail 'the open slice'
printf '%s\n' "$OUT" | grep -q '^cost FLAG claims-per-slice slice=3 n=80 budget=60' || fail 'claimed=80 did not FLAG'
printf '%s\n' "$OUT" | grep -q 'claims-per-slice slice=4' && fail 'claimed=40 flagged'
printf '%s\n' "$OUT" | grep -q '^cost FLAG wall-per-slice slice=3 hours=9.0 budget=8' || fail 'nine hours did not FLAG'
printf '%s\n' "$OUT" | grep -q 'wall-per-slice slice=4' && fail 'two hours flagged'
printf '%s\n' "$OUT" | grep -q '^cost FLAG pass-over-envelope op=builder-4 ' || fail 'a session-written stall did not FLAG'
printf 'claims-per-slice=100\n' > .vid/budget
OUT=$(sh checks/metrics.sh 2>/dev/null)
printf '%s\n' "$OUT" | grep -q 'claims-per-slice slice=3' && fail 'a raised budget did not silence the claims FLAG'
sed 's/^grammar: 0.9.3$/grammar: 0.9.2/' INVENTORY.md > i && mv i INVENTORY.md
OUT=$(sh checks/metrics.sh 2>/dev/null)
printf '%s\n' "$OUT" | grep -qE 'FLAG (claims|wall|pass-over)|modules n=' && fail 'a 0.9.2 block printed the 0.9.3 lines'
exit 0
