#!/bin/sh
# Purpose: selftest case — the important triggers (GM-1 S8, N15). On the planner's toy in GitHub manual, two stage-1
# tickets published 8 days ago and open: #2 (S02) with no claim, assignee or sub-issue, its body naming ROW-012, which its
# writing does not; #3 (S03), taken only by a sub-issue. ROW-021 added to S04 (stage 1, active) after the applied version;
# the setup's teams devagent, the plan's one lane, and mobile, which no step names. `next.sh triggers` lists, each in the
# important tier with its evidence: added-active ROW-021, team-added #2 ROW-012, not-taken #2, and team-no-lane mobile;
# #3 is not listed as not taken, and no lane is critical. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-tiers-important: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
ago() { _s=$(( $(date -u +%s) - $1 * 86400 )); date -u -r "$_s" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "@$_s" '+%Y-%m-%dT%H:%M:%SZ'; }
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied
pt_teams 'devagent | everything | core | 1' 'mobile | the app | core | 1'
D8=$(ago 8); [ -n "$D8" ] || fail 'no date 8 days ago'
{ printf 'published 2 kind=step step=S02 rows=ROW-001,ROW-005 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=%s\n' "$D8"
  printf 'published 3 kind=step step=S03 rows=ROW-006 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=%s\n' "$D8"; } > .vid/tw/log
printf '# Step ticket S02\n\n## Rows\n\n> %s\n> %s\n' "$(grep '^ROW-001 ' INVENTORY.md)" "$(grep '^ROW-005 ' INVENTORY.md)" > .vid/tw/out/issue-2.md
printf '# Step ticket S03\n\n## Rows\n\n> %s\n' "$(grep '^ROW-006 ' INVENTORY.md)" > .vid/tw/out/issue-3.md
pt_rs 's/^\(step S04 .*rows: .*\)RULE-004 /\1RULE-004 ROW-021 /'
pt_after ROW-020 'ROW-021 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day, or a day no digest went out. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
grep -q '^step S04 .*ROW-021' .vid/RUN-STATE.md && grep -q '^ROW-021 ' INVENTORY.md || fail 'ROW-021 did not land'
{ printf 'issue\t2\tticket\ta note\t%s\nissue\t3\tticket\ta note\t%s\nissue\t30\tunit\t-\t%s\n' "$D8" "$D8" "$D8"
  printf 'ticket\t2\tOPEN\t-\t%s\n' "$D8"; printf 'body\t2\t%s\n' '## Tests' '- ROW-001' '- ROW-005' '- ROW-012, ours'
  printf 'ticket\t3\tOPEN\t-\t%s\n' "$D8"; printf 'body\t3\t%s\n' '## Tests' '- ROW-006'
  printf 'sub\t3\t3\t30\tOPEN\t-\tthe footer unit\n'; } > .vid/next/read
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
grep -q "^trigger${TB}important${TB}added-active${TB}ROW-021${TB}" "$T/out" || fail 'the added ROW-021 of the active stage 1 is not important'
grep -q "^trigger${TB}important${TB}team-added${TB}#2 ROW-012${TB}" "$T/out" || fail "the team's ROW-012 on #2 is not important"
grep -q "^trigger${TB}important${TB}not-taken${TB}#2${TB}.*8 days" "$T/out" || fail '#2, 8 days old with no claim, assignee or sub-issue, is not important'
! grep -q "^trigger${TB}[a-z]*${TB}not-taken${TB}#3${TB}" "$T/out" || fail '#3, taken by its sub-issue, is listed as not taken'
grep -q "^trigger${TB}important${TB}team-no-lane${TB}mobile${TB}" "$T/out" || fail 'the team mobile, with no lane in the plan, is not important'
! grep -q "^trigger${TB}critical${TB}lane-gone${TB}" "$T/out" || fail 'a lane the setup gives is read as gone'
exit 0
