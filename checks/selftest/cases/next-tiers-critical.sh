#!/bin/sh
# Purpose: selftest case — the critical triggers (GM-1 S8, N15). On the planner's toy in GitHub manual, ticket #2 (S02)
# published and claimed (a `vid: claimed` comment in the read), and ROW-001, one of its rows, restated after the applied
# version; issue #7 open and labelled blocked; S02's newest close ask holding an unanswered `twice` item. `next.sh triggers`
# lists, each in the critical tier with its evidence: reset-taken ROW-001 (naming #2 and its claim), blocked #7, and
# close-twice with the item's key. The plan's steps name no lane, and the setup has one, devagent: no team-no-lane. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-tiers-critical: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied
printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-10T09:00:00Z\n' > .vid/tw/log
printf '# Step ticket S02\n\n## Rows\n\n> %s\n> %s\n' "$(grep '^ROW-001 ' INVENTORY.md)" "$(grep '^ROW-005 ' INVENTORY.md)" > .vid/tw/out/issue-2.md
sed 's/^\(ROW-001 .*\)holding only jobs it has not sent before\./\1holding only jobs it has not sent before, newest first./' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md
grep -q 'newest first' INVENTORY.md || fail 'ROW-001 was not restated'
pt_rs 's/ | lane: devagent//'; ! grep -q 'lane:' .vid/RUN-STATE.md || fail "the steps' lanes were not removed"
{ printf 'issue\t2\tticket\tvid: claimed by the team\001a note\t2026-11-11T09:00:00Z\n'
  printf 'issue\t7\tblocked\tQuestion: which feed first?\t2026-11-12T09:00:00Z\n'
  printf 'ticket\t2\tOPEN\t-\t2026-11-10T09:00:00Z\nbody\t2\tTests: ROW-001 and ROW-005.\n'; } > .vid/next/read
mkdir -p .vid/decide/close/S02/1; printf 'asked\t2026-11-12T09:00:00Z\n' > .vid/decide/close/S02/1/ask
printf 'twice ROW-005 now: the feed read failed · before: the feed read failed\n' > .vid/decide/close/S02/1/items
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
grep -q "^trigger${TB}critical${TB}reset-taken${TB}ROW-001${TB}.*#2 (a vid: claimed comment)" "$T/out" || fail 'the reset ROW-001 in the claimed #2 is not critical, with its ticket and claim'
grep -q "^trigger${TB}critical${TB}blocked${TB}#7${TB}label blocked\$" "$T/out" || fail 'the blocked issue #7 is not critical'
grep -q "^trigger${TB}critical${TB}close-twice${TB}close:S02/1:twice:ROW-005${TB}" "$T/out" || fail 'the close-twice item is not critical'
! grep -q "^trigger${TB}[a-z]*${TB}team-no-lane${TB}" "$T/out" || fail 'the one team, whose lane every step with none is, is listed with no lane'
exit 0
