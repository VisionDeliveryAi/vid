#!/bin/sh
# Purpose: selftest case — a step is closed at its current rows (0.26.10.29.2, R9). On the planner's toy in ticket mode,
# stage 0's candidate named: S01, S02 and S03 closed, every row they hold accepted; a recorded change moves ROW-002 from
# S04 into the closed S02, where it has no handed state. S04, which builds on S02, is refused by rule B naming ROW-002
# (it was admitted on S02's closed line alone); under breadth first the graded gate refuses it too, S02 not closed at
# its current rows. Once ROW-002 is accepted, S04 is admitted. Rule B's other alternative stands: S04 admitted with no
# closed line on S02 or S03 while every row they hold is owed, held, paid or a known limit. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "replan-closed-rows: $*" >&2; sed 's/^/    /' "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
P=$CHECKS/plan.sh; st() { RC=0; sh "$P" start "$1" > "$T/out" 2>&1 || RC=$?; }
hand() { mkdir -p .vid/tw; for l; do printf '%s | stand-in: the self-test\n' "$l" >> .vid/tw/handed; done; }
acc() { sh "$P" parse | awk -F'\t' -v s=" $* " -v st="$ST" '$1 == "row" && index(s, " " $3 " ") { print "row " $2 " " st " | stand-in: the self-test" }' >> .vid/tw/handed; }
toy() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; sed 's/^stage: 0$/stage: 1/' .vid/RUN-STATE.md > R.x && cat R.x > .vid/RUN-STATE.md; rm R.x
  hand 'candidate 0' 'staged 0'; }
toy; hand 'closed S01' 'closed S02' 'closed S03'; ST=accepted acc S01 S02 S03
pt_rs 's/^\(step S02 .* RULE-005\) |/\1 ROW-002 |/; s/^\(step S04 .*rows: \)ROW-002 /\1/'
sh "$P" change rows 'ROW-002 moves into S02' --trigger discovered-dependency --evidence step:S02 --expect 'S02 holds the cap' > "$T/out" 2>&1 || fail 'the change was refused'
st S04; [ "$RC" = 1 ] || fail "S04 was admitted while S02, which it builds on, holds ROW-002 with no handed state (exit $RC)"
grep -q 'rule B (tickets)' "$T/out" && grep -q 'S04 builds on S02, which is closed, but its rows ROW-002 are not' "$T/out" || fail 'the refusal does not name rule B, S02 and ROW-002'
cp -R .vid "$T/vid0"; cp -R "$CHECKS" checks   # breadth first derives the protected rows by checks/inventory.sh at the home
sh "$P" strategy breadth-first --by owner --words 'breadth first' > "$T/out" 2>&1 || fail 'breadth first was not set'
st S04; [ "$RC" = 1 ] && grep -q 'the graded gate' "$T/out" && grep -q 'S02 is not closed at its current rows: 1 rows (ROW-002)' "$T/out" || fail "the graded gate did not hold S04 on S02's new row (exit $RC)"
hand 'row ROW-002 accepted'; st S04; [ "$RC" = 0 ] || fail "under breadth first the graded gate still refused S04 once S02's rows are all accepted (exit $RC)"
rm -rf .vid && cp -R "$T/vid0" .vid
hand 'row ROW-002 accepted'; st S04; [ "$RC" = 0 ] || fail "S04 was refused once S02's rows are all accepted (exit $RC)"
# rule B's other alternative: no closed line, every row owed, held, paid or a known limit
toy; hand 'closed S01'; ST=accepted acc S01; ST=owed acc S02 S03; sed 's/^row ROW-005 owed /row ROW-005 held /; s/^row ROW-008 owed /row ROW-008 paid /; s/^row ROW-012 owed /row ROW-012 known-limit /' .vid/tw/handed > H.x && cat H.x > .vid/tw/handed; rm H.x
st S04; [ "$RC" = 0 ] || fail "S04 was refused while S02's and S03's rows are all owed, held, paid or known limits, with no closed line (exit $RC)"
exit 0
