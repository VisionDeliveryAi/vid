#!/bin/sh
# Purpose: selftest case — the re-take, /vid mode manual run in GitHub manual (GM-1 S2, its case mode-retake). After a switch with
# tickets #1 and #2: a new ticket #3 is published by hand and added to the register, #2 is amended by hand (its earlier writing's
# comments marked replaced), and #1 is dropped from the register, while the plan changes. The re-take takes #3 over, brings #2 to its
# newest writing (an `amended` line), lists #1 and keeps it, and records the plan change as a scope-change with its evidence
# commit:<HEAD>, in .vid/plans/decisions/. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "mode-retake: $*" >&2; cat "$T/mo" >&2 2>/dev/null; exit 1; }
mn_project "$T/p"
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2
N2=$(gh_issue 'Step S02'); mn_ticket "$N2" S02 step ROW-001 > "$T/t2"; gh_writing "$N2" "$T/t2" comments 2
N4=$(gh_issue 'Step S04'); mn_ticket "$N4" S04 step ROW-009 > "$T/t4"; gh_writing "$N4" "$T/t4" body 2; printf 'The team adds a line.\n' >> "$FAKEGH/issues/$N4/body"
printf '%s S01\n%s S02\n%s S04\n' "$N1" "$N2" "$N4" > "$T/register"
mn_switch --applied "$AP" --words 'yes, ratify'
[ "$MN_RC" = 0 ] || fail "the first switch exited $MN_RC"
N3=$(gh_issue 'Step S03'); mn_ticket "$N3" S03 step ROW-006 > "$T/t3"; gh_writing "$N3" "$T/t3" comments 2
gh_replaced "$N2"; mn_ticket "$N2" S02 step ROW-001 ROW-005 > "$T/t2b"; gh_writing "$N2" "$T/t2b" comments 2
cp ".vid/tw/out/issue-$N4.md" "$T/t4rec"; printf 'And another, after the switch.\n' >> "$FAKEGH/issues/$N4/body"
printf '%s S02\n%s S03\n%s S04\n' "$N2" "$N3" "$N4" > "$T/register"
sed 's/^step S05 | name: synonym-aware search/step S05 | name: synonym-aware search, its own step/' "$T/plan.blk" > "$T/b" && mv "$T/b" "$T/plan.blk"
mn_switch --words 'yes, the re-take'
[ "$MN_RC" = 0 ] || fail "the re-take exited $MN_RC"
grep -qx 'mode: GitHub manual, re-taken' "$T/mo" || fail 'the call did not say it re-took stock'
grep -q "^published $N3 .* taken-over=" .vid/tw/log && cmp -s ".vid/tw/out/issue-$N3.md" "$T/t3" || fail "the new register ticket #$N3 is not taken over"
grep -q "^amended $N2 .* taken-over=" .vid/tw/log && cmp -s ".vid/tw/out/issue-$N2.md" "$T/t2b" || fail "#$N2 is not brought to its newest writing"
grep -q "^newer $N2 " "$T/mo" || fail "#$N2's newer writing is not listed"
grep -q "^newer $N4 " "$T/mo" && fail "#$N4, taken from its edited body, was re-taken with no newer writing"
cmp -s ".vid/tw/out/issue-$N4.md" "$T/t4rec" && ! grep -q "^amended $N4 " .vid/tw/log || fail "#$N4's recorded writing was replaced by its body as it stands"
grep -qx "kept $N1 not in the register" "$T/mo" || fail "#$N1, dropped from the register, is not listed as kept"
cmp -s ".vid/tw/out/issue-$N1.md" "$T/t1" && grep -q "^published $N1 " .vid/tw/log || fail "#$N1's record was not kept"
D=$(grep '^plan-change ' .vid/metrics-events | tail -n 1 | sed -n 's/.* decision=\([^ ]*\) .*/\1/p'); [ -n "$D" ] || fail 'no plan change names its decision'
grep -qx 'trigger=scope-change' ".vid/plans/decisions/$D.why" && grep -qx "evidence=commit:$(git rev-parse HEAD)" ".vid/plans/decisions/$D.why" || { cat ".vid/plans/decisions/$D.why" >&2; fail "the re-take's plan change is not a scope-change with its evidence"; }
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || { cat "$T/out" >&2; fail 'the changed plan is not ratified after the re-take'; }
echo 'mode-retake: ok'
