#!/bin/sh
# Purpose: selftest case — a stage owes a walk for its own screens (FB-7 C1), walk.sh owed on the writer's toy, stage 1's candidate with
# its staging run passed. A screen a later stage's row alone cites, its canvas drawn, and no journey in the stage: no walk, W1 recorded
# none with today's words (owed, before). A row of stages up to 1 that cites a screen, or a journey of the stage's own: the walk is
# owed. No row of the inventory cites a screen: the look at design/screens stays, a canvas owes the walk and none owes none. In GitHub
# manual the same, read at the applied commit: a pending row that cites a screen owes nothing. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME; mkdir -p "$HOME"
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "walk-own-screens: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
tw_toy "$T/toy"; WS=$CHECKS/walk.sh; mkdir -p .vid/round .vid/decide design/screens; cp INVENTORY.md "$T/inv0"
X=$(git --git-dir="$T/code.git" rev-parse main); K=.vid/decide/stage/1/1; mkdir -p "$K/cs"
printf 'issue\t9\ncommit\t%s\nasked\t2026-11-09T11:00:00Z\n' "$X" > "$K/ask"; echo "$X" > "$K/commit"; : > "$K/cs/passed"
# inv <row>=<state>…: the toy's inventory with each row's screen cell set; nojourney: ROW-005, stage 1's journey, a behaviour row
inv() { cp "$T/inv0" "$T/i"; for a in "$@"; do r=${a%%=*}; s=${a#*=}; awk -F'|' -v OFS='|' -v r="$r" -v s=" $s " '{ k = $1; gsub(/[ \t]/, "", k) } k == r { $5 = s } { print }' "$T/i" > "$T/i2"; mv "$T/i2" "$T/i"; done; cat "$T/i" > INVENTORY.md; }
nojourney() { sed 's/^ROW-005 | journey | ingest |/ROW-005 | behavior | REQ-001 |/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; }
owes() { rm -rf "$K/w1"; sh "$WS" owed > "$T/out" 2>&1 || fail "$1: owed failed"; grep -qx 'walk 1' "$T/out" || fail "$1: no walk is owed"; [ ! -f "$K/w1/none" ] || fail "$1: W1 is recorded none"; }
none() { rm -rf "$K/w1"; sh "$WS" owed > "$T/out" 2>&1 || fail "$1: owed failed"; ! grep -q '^walk 1' "$T/out" || fail "$1: a walk is owed"; [ "$(cat "$K/w1/none" 2>/dev/null)" = 'no walk: this stage has no screens and no journey' ] || fail "$1: W1's none: $(cat "$K/w1/none" 2>/dev/null)"; }
[ "$(sh "$CHECKS/planner.sh" rows 2>/dev/null | awk -F'\t' '$1 == "ROW-017" || $1 == "ROW-001" { print $1 "=" $5 }' | paste -sd ' ' -)" = 'ROW-001=1 ROW-017=2' ] || fail 'the toy places its rows otherwise'
# a later stage's screen alone
echo '<html>results</html>' > 'design/screens/S05 results.dc.html'; inv ROW-003=n/a ROW-017=S05/results; nojourney
none 'a screen a later stage alone cites'
# a row of stages up to 1 that cites one: stage 1's own, or stage 0's
inv ROW-003=n/a ROW-017=S05/results ROW-001=S05/results; nojourney; owes "a screen a row of the stage cites"
inv ROW-017=S05/results; nojourney; owes 'a screen an earlier stage cites'
# the stage's own journey, with a later stage's screen
inv ROW-003=n/a ROW-017=S05/results; owes "the stage's own journey"
# no row cites a screen at all: the look at design/screens stays
inv ROW-003=n/a; nojourney; owes 'a canvas, and no row citing a screen'
rm -rf design/screens; none 'no canvas, and no row citing a screen'
# GitHub manual: the applied commit's inventory is read, a pending row's screen owes nothing
mkdir -p design/screens; echo '<html>results</html>' > 'design/screens/S05 results.dc.html'; inv ROW-003=n/a ROW-017=S05/results; nojourney; g add INVENTORY.md; g commit -qm 'the screen is a later stage'"'"'s'
printf 'setup-answered key=github-mode value="manual" words="manual, the self-test" at=2026-11-09T09:00:00Z\n' >> .vid/plan/setup; git rev-parse HEAD > .vid/tw/applied
none 'GitHub manual, a screen a later stage alone cites'
inv ROW-003=n/a ROW-017=S05/results ROW-001=S05/results; nojourney; none 'GitHub manual, a pending screen of the stage'
g add INVENTORY.md; g commit -qm 'the stage cites the screen'; git rev-parse HEAD > .vid/tw/applied; owes 'GitHub manual, a screen a row of the stage cites'
exit 0
