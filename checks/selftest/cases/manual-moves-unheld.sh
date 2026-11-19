#!/bin/sh
# Purpose: selftest case — the plan holds no ticket back in GitHub manual (GM-1 S4). On the planner's toy in GitHub
# manual, S05 (stage 2) made to build on the skeleton S01 (stage 0), whose ticket #1 is published and open, with an
# open-ticket limit of 1 already reached: `next.sh triggers` lists S05 as a publish move, as it does S02, S03 and S04,
# each "listed; done from phase 2", and never S01, which is published. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "manual-moves-unheld: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied
pt_rs 's/^\(step S05 .*builds-on:\) S02 /\1 S01 /'; grep -q '^step S05 .*builds-on: S01 ' .vid/RUN-STATE.md || fail 'S05 does not build on S01'
printf 'open-tickets: 1\n' > .vid/tw/settings
printf 'published 1 kind=skeleton step=S01 rows=ROW-003,ROW-004 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-18T09:00:00Z\n' > .vid/tw/log
printf '# Skeleton ticket S01\n\n## Rows\n\n> %s\n' "$(grep '^ROW-003 ' INVENTORY.md)" > .vid/tw/out/issue-1.md
printf 'ticket\t1\tOPEN\t-\t2026-11-18T09:00:00Z\nbody\t1\tThe skeleton: ROW-003 and ROW-004.\n' > .vid/next/read
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
for s in S02 S03 S04 S05; do grep -q "^move${TB}[0-9]*${TB}publish${TB}$s${TB}listed; done from phase 2\$" "$T/out" || fail "$s is not listed as publishable"; done
! grep -q "^move${TB}[0-9]*${TB}publish${TB}S01${TB}" "$T/out" || fail 'S01, already published, is listed as a publish move'
exit 0
