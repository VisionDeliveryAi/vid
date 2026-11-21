#!/bin/sh
# Purpose: selftest case — the publish warnings, one helper, read by the call's lines (GM-4 K9, J2; queue lane): next.sh holds none
# of the warnings' predicates (the open-ticket limit, the stage ahead of the lowest active stage, the tickets not taken 7 days after
# their creation) and prints, after each publish move it lists, the lines `plan.sh warnings <step>` gives, word for word. On the
# planner's toy in GitHub manual, open-tickets: 1; the skeleton's ticket #1 published and closed, #2 (S02) published, open and
# claimed, #3 (S03) published, open, created long ago and not taken; every stage-1 test accepted in the handed record but two. The
# call's lines list S04 and S05 to publish, each with the helper's lines (limit and not-taken for both, stage-ahead for S05 too);
# with the limit raised and #3 assigned, S04's publish move has no warning line. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-warnings-one: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
# next.sh holds no copy of the warnings: none of their predicates' words, and it reads the helper
NX=$CHECKS/next.sh
for w in 'over open-tickets' 'the lowest active stage' 'not taken 7 days after their creation' 'a stale ticket' 'work spread, the plan fixed early' 'half-built work in a release'; do
  ! grep -q "$w" "$NX" || fail "next.sh still holds a publish warning of its own: \"$w\""; done
grep -q 'plan.sh" warnings' "$NX" || fail 'next.sh does not read the publish warnings from plan.sh warnings'
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/round .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied
printf 'open-tickets: 1\n' > .vid/tw/settings
{ printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-01-01T09:00:00Z\n'
  printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-01-01T09:00:00Z\n'
  printf 'published 3 kind=step step=S03 rows=ROW-006,ROW-007 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-01-01T09:00:00Z\n'; } > .vid/tw/log
printf '# Skeleton ticket S01\n\n## Rows\n\n> %s\n' "$(grep '^ROW-003 ' INVENTORY.md)" > .vid/tw/out/issue-1.md
printf '# Step ticket S02\n\n## Rows\n\n> %s\n' "$(grep '^ROW-001 ' INVENTORY.md)" > .vid/tw/out/issue-2.md
printf '# Step ticket S03\n\n## Rows\n\n> %s\n' "$(grep '^ROW-006 ' INVENTORY.md)" > .vid/tw/out/issue-3.md
sh "$CHECKS/planner.sh" rows > "$T/rows" 2>&1 || fail 'planner.sh rows failed'
awk -F'\t' '$2 == "row" && $5 == 1 && $6 ~ /^(planned|moved|owed)$/ && $1 != "ROW-001" && $1 != "ROW-008" { print "row " $1 " accepted | stand-in: the self-test" }' "$T/rows" > .vid/tw/handed
{ printf 'issue\t2\tticket\tvid: claimed by the team\t2026-01-02T09:00:00Z\n'
  printf 'ticket\t1\tCLOSED\t-\t2026-01-01T09:00:00Z\nticket\t2\tOPEN\t-\t2026-01-01T09:00:00Z\nticket\t3\tOPEN\t-\t2026-01-01T09:00:00Z\n'; } > .vid/round/read
# lines <file>: the call's lines; mine <step> <file>: the warning lines after that step's publish move
lines() { sh "$NX" triggers > "$1" 2> "$T/out" || fail 'next.sh triggers failed'; }
mine() { awk -F'\t' -v s="$1" '$1 == "move" { on = ($2 == "publish" && $3 == s); next } $1 == "warning" && on && $2 == "publish" && $3 == s { print; next } { on = 0 }' "$2"; }
lines "$T/L"
for s in S04 S05; do grep -q "^move${TB}publish${TB}$s${TB}" "$T/L" || { cp "$T/L" "$T/out"; fail "the call's lines list no publish move of $s: the scene is wrong"; }
  RC=0; sh "$CHECKS/plan.sh" warnings "$s" > "$T/h-$s" 2> "$T/out" || RC=$?; [ "$RC" = 0 ] || fail "plan.sh warnings $s exited $RC"
  [ -s "$T/h-$s" ] || fail "plan.sh warnings gives $s no line: the scene is wrong"
  mine "$s" "$T/L" > "$T/n-$s"; cmp -s "$T/h-$s" "$T/n-$s" || { diff "$T/h-$s" "$T/n-$s" > "$T/out" || :; fail "the warnings after $s's publish move are not plan.sh warnings' lines, word for word"; }; done
for k in limit not-taken; do grep -q "^warning${TB}publish${TB}S04${TB}$k${TB}" "$T/n-S04" || fail "S04's publish move lacks its $k warning"; done
grep -q "^warning${TB}publish${TB}S05${TB}stage-ahead${TB}" "$T/n-S05" || fail "S05's publish move lacks its stage-ahead warning"
# none due: the limit raised, #3 assigned
printf 'open-tickets: 9\n' > .vid/tw/settings; sed "s/^ticket${TB}3${TB}OPEN${TB}-${TB}/ticket${TB}3${TB}OPEN${TB}someone${TB}/" .vid/round/read > "$T/rd"; cp "$T/rd" .vid/round/read
lines "$T/L2"; grep -q "^move${TB}publish${TB}S04${TB}" "$T/L2" || fail 'S04 is no longer listed to publish'
mine S04 "$T/L2" > "$T/n2"; [ ! -s "$T/n2" ] || { cp "$T/n2" "$T/out"; fail 'with no warning due, S04 still has a warning line'; }
exit 0
