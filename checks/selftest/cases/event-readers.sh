#!/bin/sh
# Purpose: selftest case — the readers of a timed events file (v0.9.5 spec
# 3.11, R11; §7 case 14). A toy repository under `grammar: 0.9.3` with one
# slice's events. Convicts unless `metrics.sh` prints byte-identical output
# over the file written the old way and the same file with ` at=<UTC>` on
# its later lines (an upgraded project: old lines first, then timed ones) —
# the slice's `modules n=3` counting no `at=` token; `records FLAG no-at`
# counts one untimed line written after a timed one; and a line whose free
# text carries `at=` before the helper's own time is not counted, the last
# `at=` token being the time. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
git init -q
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
mkdir -p checks app .vid
cp "$CHECKS/metrics.sh" "$CHECKS/census.sh" "$CHECKS/plan.sh" "$CHECKS/event.sh" "$CHECKS/lawfiles" checks/
printf '.vid/\n' > .gitignore
printf '# toy\n```vid-inventory\ngrammar: 0.9.3\nROW-001 | behavior | REQ-001 | n/a | n/a | one | REQ-001 | owed: prerequisite — x; paid at slice 2\n```\n' > INVENTORY.md
printf '| Module | Responsibility | Owned | Public surface | Dependents |\n|---|---|---|---|---|\n| app/feed | feed | f | `app.feed` | none |\n' > ARCHITECTURE.md
printf '# Purpose: toy\n' > app/main.py
g add -A && g commit -qm root; S0=$(git rev-parse --short=12 HEAD)
printf '| app/search | search | s | `app.search` | none |\n' >> ARCHITECTURE.md; g commit -qam 'seam: search'
S1=$(git rev-parse --short=12 HEAD)
cat > "$T/old" <<EV
slice-open slice=3 sha=$S0
slice-modules slice=3 app/feed app/search app/notify
verdict slice=3 row=ROW-001 result=BREACHED class=product brief=.vid/briefs/3/grader-1.md quoted-at=$S0
verdict slice=3 claimed=4 breached=1
tokens slice=3 phase=build n=1000
tokens slice=3 phase=verdict n=300
paid row=ROW-001 via=ledger
regressions slice=3 n=0
wall-clock slice=3 seconds=7200
ledger-run seconds=40 kind=full report=none status=1 role=close
incident slice=3 the probe said at=noon
failif-amendment n=2
slice-close slice=3 sha=$S1
EV
cp "$T/old" .vid/metrics-events
# the slice's summary exists, so the timed slice-close trips no summary FLAG (3.12) and only the time differs
printf '# Slice summaries\n\n## 2026-09-25T10:13:00Z — slice 3\n\n- **Working now:** the feed\n- **Went back:** nothing\n- **Decided for you:** nothing\n' > .vid/SUMMARY.md
OLD=$(sh checks/metrics.sh 2>/dev/null)
fail() { echo "event-readers: $*" >&2; exit 1; }
printf '%s\n' "$OLD" | grep -q '^progress slice=3 modules n=3 ' || fail 'the old file does not read three modules'
# the same events, the later ones timed as the 0.9.5 writers write them
awk 'NR == 1 { print; next } { print $0 " at=2026-09-25T10:" sprintf("%02d", NR) ":00Z" }' "$T/old" > .vid/metrics-events
NEW=$(sh checks/metrics.sh 2>/dev/null)
[ "$OLD" = "$NEW" ] || { printf '%s\n' "$OLD" > "$T/o"; printf '%s\n' "$NEW" > "$T/n"; diff "$T/o" "$T/n" >&2; fail 'the timed lines change what metrics.sh prints'; }
# an untimed line after the first timed one is counted …
printf 'incident slice=3 a writer that skipped the helper\n' >> .vid/metrics-events
sh checks/metrics.sh 2>/dev/null | grep -qx 'records FLAG no-at n=1  # .*' || fail 'the untimed line was not counted'
# … and a free-text at= before the helper's own time is not
sh checks/event.sh 'incident slice=3 the log says at=2026-01-01T00:00:00Z at noon'
sh checks/event.sh 'incident slice=3 the probe said at=09:00'
sh checks/metrics.sh 2>/dev/null | grep -qx 'records FLAG no-at n=1  # .*' || fail 'a free-text at= confused the last-token rule'
exit 0
