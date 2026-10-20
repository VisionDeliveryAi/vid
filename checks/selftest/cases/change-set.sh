#!/bin/sh
# Purpose: selftest case — the change set since the last full pass (v0.26.10.7 spec R4; §5 change-set). The toy
# two-stage product (fixtures/stages.sh), stage 1 current, with a module table (app/notes, app/signin) whose files cite
# REQ-002 and REQ-001. Since the base: a change to app/notes brings in ROW-002, KEPT and citing REQ-002, and not
# ROW-001; a changed test brings in its row (test_a.py: ROW-001) and a changed RULE test its row (RULE-001); HOS-002,
# protecting REQ-001, follows ROW-001; a row born owed since the base (ROW-007) is in it; a later-phase row's and a
# stage-2 row's changed tests (ROW-005, ROW-004, HOS-001) bring nothing. `change-set rows=5`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'set +e; rm -rf "$T" 2>/dev/null' EXIT
. "$CHECKS/selftest/fixtures/stages.sh"
fail() { echo "change-set: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
st_close_repo "$T/repo"
mkdir -p app/notes app/signin
printf '# Purpose: notes — REQ-002\n' > app/notes/n.py; printf '# Purpose: signing in — REQ-001\n' > app/signin/s.py
printf '# Architecture\n\n| Module | Purpose | Seam | Owner | Dependents |\n|---|---|---|---|---|\n| app/notes | notes | - | - | none |\n| app/signin | signing in | - | - | none |\n' > ARCHITECTURE.md
g add -A && g commit -qm 'two modules'
BASE=$(git rev-parse --short=12 HEAD)
st_keep ROW-001 ROW-002
sh checks/metrics.sh change-set --base "$BASE" > "$T/out" 2>&1
grep -qx 'change-set rows=0' "$T/out" || fail 'the change set is not empty at its base'
printf '# a change to notes\n' >> app/notes/n.py; g commit -qam 'a notes change'
sh checks/metrics.sh change-set --base "$BASE" > "$T/out" 2>&1
grep -qx 'ROW-002' "$T/out" || fail 'a module change does not bring in the KEPT row citing it (ROW-002)'
grep -qx 'ROW-001' "$T/out" && fail 'a module change brought in a row it does not cite (ROW-001)'
for f in a rule d e hos1; do printf '# changed\n' >> "tests/invariants/test_$f.py"; done
awk '/^```$/ && !d { print "ROW-007 | behavior | REQ-002 | anonymous | n/a | a note reaches the mailbox | REQ-002 | owed: paid by /vid deploy gate 2 — one real mail"; d = 1 } { print }' INVENTORY.md > inv && mv inv INVENTORY.md
g commit -qam 'tests changed; a row born owed'
sh checks/metrics.sh change-set --base "$BASE" > "$T/out" 2>&1
for r in ROW-001 ROW-002 ROW-007 RULE-001 HOS-002; do grep -qx "$r" "$T/out" || fail "$r is not in the change set"; done
for r in ROW-004 ROW-005 HOS-001 ROW-003 ROW-006; do grep -qx "$r" "$T/out" && fail "$r (a later stage or phase, or unchanged) is in the change set"; done
grep -qx 'change-set rows=5' "$T/out" || fail 'the count is not 5'
exit 0
