#!/bin/sh
# Purpose: selftest case — the publish warnings, one helper (GM-4 K9, J2): `plan.sh warnings <step>…` prints, read only, GM M12's
# lines in next.sh's form, with next.sh's predicates. On the planner's toy in GitHub manual, open-tickets: 1; the skeleton's
# ticket #1 published and closed, #2 (S02, stage 1) published, open and claimed, #3 (S03) published, open, created long ago and
# not taken; every stage-1 test accepted in the handed record but ROW-001 and ROW-008, and ROW-012 held. S04 and S05 each get the
# limit warning (2 open, 3 with it, over 1) and the not-taken one (#3); S05, of stage 2, also stage-ahead (stage 1's 3 tests not
# yet accepted); S04, of stage 1, no stage-ahead. The lines are the ones next.sh triggers gives the same moves, word for word, and
# the helper writes nothing. With the limit raised and #3 assigned, S04 has none: exit 0, no line. In GitHub auto a ticket's
# stage is its step's, and the lines stand. A step the plan lacks is refused, exit 1. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "plan-warnings: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
W() { RC=0; sh "$CHECKS/plan.sh" warnings "$@" > "$T/out" 2> "$T/err" || RC=$?; }
snap() { { find .vid -type f | sort | while read -r f; do cksum "$f"; done; cksum .git/index; } > "$1"; }
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
printf 'row ROW-012 held | stand-in: the self-test\n' >> .vid/tw/handed
{ printf 'issue\t2\tticket\tvid: claimed by the team\t2026-01-02T09:00:00Z\n'
  printf 'ticket\t1\tCLOSED\t-\t2026-01-01T09:00:00Z\nticket\t2\tOPEN\t-\t2026-01-01T09:00:00Z\nticket\t3\tOPEN\t-\t2026-01-01T09:00:00Z\n'; } > .vid/round/read
# the lines next.sh gives the same moves
sh "$CHECKS/next.sh" triggers > "$T/tr" 2>&1 || { cat "$T/tr" >&2; fail 'next.sh triggers failed'; }
for s in S04 S05; do grep "^warning${TB}publish${TB}$s${TB}" "$T/tr" > "$T/nx-$s" || :; [ -s "$T/nx-$s" ] || fail "next.sh gives $s no warning: the scene is wrong"; done
snap "$T/s0"
W S04 S05; [ "$RC" = 0 ] || { cat "$T/err" >&2; fail "plan.sh warnings S04 S05 exited $RC"; }
snap "$T/s1"; cmp -s "$T/s0" "$T/s1" || fail 'plan.sh warnings wrote a file (.vid or the index)'
grep -v "^warning${TB}" "$T/out" > "$T/other" || :; [ ! -s "$T/other" ] || fail "plan.sh warnings printed a line not a warning: $(head -n 1 "$T/other")"
cat "$T/nx-S04" "$T/nx-S05" > "$T/nx"; cmp -s "$T/out" "$T/nx" || { diff "$T/nx" "$T/out" >&2 || :; fail "the helper's lines are not next.sh's, word for word"; }
for s in S04 S05; do grep -q "^warning${TB}publish${TB}$s${TB}limit${TB}2 open tickets, 3 with this one, over open-tickets: 1${TB}work spread, the plan fixed early$" "$T/out" || fail "$s is not warned past the open-ticket limit"
  grep -q "^warning${TB}publish${TB}$s${TB}not-taken${TB}1 published tickets not taken 7 days after their creation: #3${TB}a stale ticket$" "$T/out" || fail "$s is not warned that #3 is not taken"; done
grep -q "^warning${TB}publish${TB}S05${TB}stage-ahead${TB}stage 2, ahead of stage 1, the lowest active stage, whose 3 tests are not yet accepted${TB}half-built work in a release, lost learning$" "$T/out" || fail 'S05 is not warned that stage 1 has 3 tests not accepted'
! grep -q "^warning${TB}publish${TB}S04${TB}stage-ahead" "$T/out" || fail 'S04, of stage 1, is warned for its stage'
# none: the limit raised, #3 assigned
printf 'open-tickets: 9\n' > .vid/tw/settings; sed "s/^ticket${TB}3${TB}OPEN${TB}-${TB}/ticket${TB}3${TB}OPEN${TB}someone${TB}/" .vid/round/read > "$T/rd"; cp "$T/rd" .vid/round/read
W S04; [ "$RC" = 0 ] && [ ! -s "$T/out" ] || fail "with no warning due S04 printed lines or exited $RC"
# GitHub auto: a ticket's stage is its step's
printf 'open-tickets: 1\n' > .vid/tw/settings; grep -v 'key=github-mode' .vid/plan/setup > "$T/su"; cp "$T/su" .vid/plan/setup
W S05; [ "$RC" = 0 ] || fail "in GitHub auto plan.sh warnings S05 exited $RC"
grep -q "^warning${TB}publish${TB}S05${TB}limit${TB}2 open tickets, 3 with this one, over open-tickets: 1${TB}" "$T/out" || fail 'in GitHub auto S05 is not warned past the limit'
grep -q "^warning${TB}publish${TB}S05${TB}stage-ahead${TB}stage 2, ahead of stage 1, the lowest active stage, whose 3 tests are not yet accepted${TB}" "$T/out" || fail 'in GitHub auto S05 is not warned for its stage'
W S99; [ "$RC" = 1 ] && [ ! -s "$T/out" ] && grep -q 'no step S99' "$T/err" || fail "a step the plan lacks was not refused ($RC)"
echo 'plan-warnings: ok'
