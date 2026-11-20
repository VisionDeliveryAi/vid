#!/bin/sh
# Purpose: selftest case — the minor triggers (GM-1 S8, N15). On the planner's toy in GitHub manual, ticket #4 (S04)
# published and open, holding ROW-017 (stage 2) first, then ROW-002 and ROW-018 (stage 1), so of stage 1, the stage most
# of its rows are in; after the applied version REQ-011's fail-if is changed, reaching ROW-018,
# ROW-021, of REQ-003 and so of stage 2, which has no open ticket, is added to S05, and ROW-022, of stage 1, to S04.
# `next.sh triggers` lists, each in the minor tier with its evidence: reached-open ROW-018 (naming #4) and added-inactive
# ROW-021; and ROW-022, of the active stage 1, as important added-active. GM-2 T9: a minor trigger is only counted, its line
# `quiet minor … minor`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "next-tiers-minor: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
TB=$(printf '\t')
pt_toy "$T/toy"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'
printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
mkdir -p .vid/tw/out .vid/next; git rev-parse HEAD > .vid/tw/applied
printf 'published 4 kind=step step=S04 rows=ROW-017,ROW-002,ROW-018 plan=p1 base=b1 export=e1 parts=1 taken-over=comments at=2026-11-17T09:00:00Z\n' > .vid/tw/log
printf '# Step ticket S04\n\n## Rows\n\n> %s\n> %s\n> %s\n' "$(grep '^ROW-017 ' INVENTORY.md)" "$(grep '^ROW-002 ' INVENTORY.md)" "$(grep '^ROW-018 ' INVENTORY.md)" > .vid/tw/out/issue-4.md
sed 's/fail-if: a day of failed sends leaves no operator-visible trace/fail-if: a day of failed sends leaves no operator-visible trace within the hour/' PRD.md > "$T/p" && cat "$T/p" > PRD.md
pt_rs 's/^\(step S05 .*rows: ROW-017\) /\1 ROW-021 /'
pt_after ROW-020 'ROW-021 | behavior | REQ-003 | anonymous | n/a | A search for a job title finds the same job under its common short name. Fails if a golden-set query by short name misses a must-appear job. | REQ-003 | owed: spec-only — first stage | origin: REQ-003'
pt_rs 's/^\(step S04 .*rows: .*\)RULE-004 /\1RULE-004 ROW-022 /'
pt_after ROW-021 'ROW-022 | behavior | REQ-001 | anonymous | n/a | A saved search shows the day its last digest went out. Fails if a saved search shows no day, or a day no digest went out. | REQ-001 | owed: spec-only — first stage | origin: REQ-001'
grep -q 'within the hour' PRD.md && grep -q '^step S05 .*ROW-017 ROW-021 ' .vid/RUN-STATE.md && grep -q '^ROW-021 ' INVENTORY.md && grep -q '^step S04 .*ROW-022' .vid/RUN-STATE.md && grep -q '^ROW-022 ' INVENTORY.md || fail 'the changes did not land'
{ printf 'issue\t4\tticket\tvid: claimed by the team\t2026-11-18T09:00:00Z\n'
  printf 'ticket\t4\tOPEN\t-\t2026-11-17T09:00:00Z\n'; printf 'body\t4\t%s\n' '## Tests' '- ROW-017' '- ROW-002' '- ROW-018'; } > .vid/next/read
sh "$CHECKS/next.sh" triggers > "$T/out" 2>&1 || fail 'next.sh triggers failed'
grep -q "^quiet${TB}minor${TB}reached-open${TB}ROW-018${TB}.*#4.*${TB}minor\$" "$T/out" || fail 'the reached ROW-018 in the open #4 is not minor'
grep -q "^quiet${TB}minor${TB}added-inactive${TB}ROW-021${TB}.*${TB}minor\$" "$T/out" || fail 'the added ROW-021 of stage 2, with no open ticket, is not minor'
grep -q "^trigger${TB}important${TB}added-active${TB}ROW-022${TB}" "$T/out" || fail "the added ROW-022 of stage 1, #4's stage by most of its rows, is not important"
exit 0
