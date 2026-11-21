#!/bin/sh
# Purpose: selftest case — the copied rules cut (GM-4 F10, next.sh's and the plan page's part): each copy calls its owner.
# next.sh writes no ptr or unptr of its own (writer.sh ptr gives them), no reading of the setup's team lines
# (planner.sh teams), no step's stage rule (planner.sh steps), no close items (queue.sh closes) and no question rule (the
# queue's scan); next-page.sh no team lines and no stage rule of its own. On the planner's toy in GitHub manual, a step's close
# asked twice holds a `twice` item: `queue.sh closes` gives it, read only (no file written), and next.sh triggers raises
# close-twice under that same key; planner.sh teams gives the setup's team, which the triggers name with no team-no-lane
# trigger for it; planner.sh steps gives each step its stage. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-copies-cut: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
# the text: no copy left
N=$CHECKS/next.sh; P=$CHECKS/next-page.sh
! grep -q 'function ptr(' "$N" && ! grep -q 'function unptr(' "$N" || fail 'next.sh writes ptr or unptr again'
! grep -q '/\^team:/' "$N" && ! grep -q '/\^team:/' "$P" || fail 'next.sh or next-page.sh reads the team lines itself'
! grep -q 'function stg(' "$N" && ! grep -q 'function stg(' "$P" || fail 'next.sh or next-page.sh writes the stage rule again'
! grep -q 'function isq(' "$N" || fail 'next.sh writes the question rule again'
! grep -q 'D/close/\$x' "$N" || fail 'next.sh reads the close items itself'
grep -q 'queue.sh" closes' "$N" && grep -q 'planner teams' "$N" && grep -q 'planner steps' "$N" || fail 'next.sh does not call the owners'
# the behaviour, on the toy
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/round; git rev-parse HEAD > .vid/tw/applied; : > .vid/tw/handed; : > .vid/tw/log
printf 'issue\t9\tticket\t-\t2026-11-18T09:00:00Z\n' > .vid/round/read
F=.vid/decide/close/S02/1; mkdir -p "$F"; printf 'asked\n' > "$F/ask"; printf 'twice p2c1 ROW-005 failed again\n' > "$F/items"
find . -type f | sort > "$T/f0"; sh "$CHECKS/queue.sh" closes > "$T/cl" 2> "$T/out" || fail 'queue.sh closes failed'
find . -type f | sort > "$T/f1"; cmp -s "$T/f0" "$T/f1" || fail "queue.sh closes wrote: $(comm -13 "$T/f0" "$T/f1" | paste -sd ' ' -)"
K=$(awk -F'\t' '$1 == "close-twice" { print $2; exit }' "$T/cl"); [ -n "$K" ] || fail "queue.sh closes gives no twice item: $(cat "$T/cl")"
sh "$CHECKS/next.sh" triggers > "$T/tr" 2> "$T/out" || fail 'next.sh triggers failed'
grep -q "^trigger${TB}critical${TB}close-twice${TB}$K${TB}" "$T/tr" || { cat "$T/tr" >&2; fail "close-twice is not raised under the queue's key $K"; }
sh "$CHECKS/planner.sh" teams > "$T/tm" 2> "$T/out" || fail 'planner.sh teams failed'
TM=$(cut -f1 "$T/tm" | head -n 1); [ -n "$TM" ] || fail 'planner.sh teams gives no team'
! grep -q "^trigger${TB}important${TB}team-no-lane${TB}$TM${TB}" "$T/tr" || fail "the toy's team $TM is read as holding no lane"
sh "$CHECKS/planner.sh" steps > "$T/st" 2> "$T/out" || fail 'planner.sh steps failed'
awk -F'\t' '$1 == "S02" && $3 ~ /^[0-9]+$/ { f = 1 } END { exit !f }' "$T/st" || fail "planner.sh steps gives S02 no stage: $(cat "$T/st")"
exit 0
