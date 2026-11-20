#!/bin/sh
# Purpose: selftest case — the warnings on each publishable step (GM-1 S8, N13). On the planner's toy in GitHub manual,
# open-tickets: 1; the skeleton's ticket #1 published and closed, #2 (S02, stage 1) published and open; every stage-1 test
# accepted in the handed record but ROW-001 and ROW-008, and ROW-012, held (held is not accepted).
# `next.sh triggers` lists S03, S04 and S05 as publish moves, each warned past the limit (1 open, 2 with it, over 1); S05
# (stage 2) also warned that stage 1, the lowest active stage, has 3 tests not yet accepted; S03 and S04, of stage 1, are
# not warned for their stage, S04 though its rows now begin with ROW-017, of stage 2: a step's stage is the one most of its
# rows are in. GM-2 §5: a move and its warnings are named by kind and subject, `publish <step>`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-warnings: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied
printf 'open-tickets: 1\n' > .vid/tw/settings
pt_rs 's/^\(step S04 .*rows:\) /\1 ROW-017 /'; grep -q '^step S04 .*rows: ROW-017 ROW-002 ' .vid/RUN-STATE.md || fail "S04's rows do not begin with ROW-017"
{ printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-17T09:00:00Z\n'
  printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-17T09:00:00Z\n'; } > .vid/tw/log
printf '# Skeleton ticket S01\n\n## Rows\n\n> %s\n' "$(grep '^ROW-003 ' INVENTORY.md)" > .vid/tw/out/issue-1.md
printf '# Step ticket S02\n\n## Rows\n\n> %s\n' "$(grep '^ROW-001 ' INVENTORY.md)" > .vid/tw/out/issue-2.md
sh "$CHECKS/planner.sh" rows > "$T/rows" 2>&1 || fail 'planner.sh rows failed'
awk -F'\t' '$2 == "row" && $5 == 1 && $6 ~ /^(planned|moved|owed)$/ && $1 != "ROW-001" && $1 != "ROW-008" { print "row " $1 " accepted | stand-in: the self-test" }' "$T/rows" > .vid/tw/handed
[ "$(grep -c . .vid/tw/handed)" -ge 10 ] || fail 'the stage-1 rows were not accepted'
printf 'row ROW-012 held | stand-in: the self-test\n' >> .vid/tw/handed
{ printf 'issue\t2\tticket\tvid: claimed by the team\t2026-11-18T09:00:00Z\n'
  printf 'ticket\t1\tCLOSED\t-\t2026-11-17T09:00:00Z\nticket\t2\tOPEN\t-\t2026-11-17T09:00:00Z\n'; } > .vid/next/read
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
for s in S03 S04 S05; do k=publish; grep -q "^move${TB}publish${TB}$s${TB}[0-9a-f]\{40\}${TB}" "$T/out" || fail "$s is not a publish move"
  grep -q "^warning${TB}$k${TB}$s${TB}limit${TB}1 open tickets, 2 with this one, over open-tickets: 1${TB}" "$T/out" || fail "$s is not warned past the open-ticket limit"
  if [ "$s" = S05 ]; then grep -q "^warning${TB}$k${TB}S05${TB}stage-ahead${TB}stage 2, ahead of stage 1, the lowest active stage, whose 3 tests are not yet accepted${TB}" "$T/out" || fail 'S05 is not warned that stage 1 has 3 tests not accepted, the held ROW-012 among them'
  else ! grep -q "^warning${TB}$k${TB}$s${TB}stage-ahead${TB}" "$T/out" || fail "$s, of stage 1, is warned for its stage"; fi; done
exit 0
