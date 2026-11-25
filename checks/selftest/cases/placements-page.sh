#!/bin/sh
# Purpose: selftest case — the two readers' findings on the plan page, and the first ratification (FB-4 A1.4). On the planner's toy with
# no reading, the page's "Where the tests go: what two readers found" says not reviewed, and `planner.sh ratify` is refused, naming
# the step left out, with no ticket published. With a result it is not refused, a finding that stands or not; the page shows the
# result's counts, each finding with its better place, the quote, the harm and the second reader's why, and what could not be judged;
# a refuted one is nowhere. The block changed since, the page says how many placements changed. A later ratification is refused for
# no missing reading, nor is a first one with a ticket published, nor a switch's own (VID_CALLER mode or mode-auto: GitHub manual,
# fixtures/manual.sh). Env: CHECKS.
# selftest-limit: 600 s
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "placements-page: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
D=.vid/plan/placement; G=.vid/plan/PLAN-PAGE.md; pt_toy "$T/toy"; rm -rf "$D"; printf 'none\n' > "$T/none"
pl() { RC=0; sh "$CHECKS/planner.sh" "$@" > "$T/out" 2>&1 || RC=$?; }
sec() { awk '/^## Where the tests go: what two readers found$/ { on = 1; next } on && /^## / { exit } on' "$G" > "$T/sec"; cat "$T/sec" > "$T/out"; [ -s "$T/sec" ] || fail 'the page has no section of the two readers'; }
pl review --in "$T/none"; pl page; [ "$RC" = 0 ] || fail 'the page was refused'; sec; grep -q 'not reviewed$' "$T/sec" || fail 'a plan no one read is not said not reviewed'
pl ratify --words 'yes'; [ "$RC" = 1 ] && grep -q 'ratify refused — two readers have not read the placements' "$T/out" || fail 'a first ratification with no reading was not refused'
[ "$(grep -c 'ratify refused' "$T/out")" = 1 ] && [ ! -s .vid/plan/ratified ] || fail 'the refusal names another reason, or recorded a ratification'
# read: a finding that stands, one in part, one refuted
pl placements write "$D"; N=$(sed -n 's/^listed //p' "$T/out")
{ printf 'finding 1 | ROW-017 | in S05 | rule 2 | wrong | better: S04 | quote: "the first words" (PRD.md, REQ-003) | harm: no one can show it\n'
  printf 'finding 2 | ROW-012 | in S02 | rule 1 | doubt | better: S04 | quote: "the second words" (PRD.md, REQ-001) | harm: shown late\nfinding 3 | ROW-006 | in S03 | rule 5 | doubt | better: S01 | quote: "the third words" (PRD.md, REQ-012) | harm: split\n'
  printf 'unjudged ROW-018 | an open question\nplaced right=%s finding=3 unjudged=1\n' $((N - 4)); } > "$D/part-1.reader"
printf 'stands 1 | better: S03 | the deciding words\npartly 2 | better: S04 | half of it\nrefuted 3 | (c) | shown where it stands\n' > "$D/part-1.refuter"
pl placements result "$D"; [ "$RC" = 0 ] || fail 'the result was refused'
pl page; sec
grep -qF -- "- round 1: $N placements read, $((N - 4)) right, 1 could not be judged; findings: 1 stand, 1 stand in part, 1 refuted" "$T/sec" || fail 'the counts are not the result'"'"'s'
grep -F -- '- **ROW-017** in S05' "$T/sec" | grep -F 'better: S03.' | grep -F '"the first words"' | grep -F 'no one can show it' | grep -qF 'the deciding words' || fail 'a finding that stands is not shown whole'
grep -F -- '- **ROW-012** in S02' "$T/sec" | grep -qF 'stands in part' || fail 'a finding that stands in part is not shown'
! grep -q 'the third words' "$G" || fail 'a refuted finding reached the page'
grep -q 'ROW-018: could not be judged: an open question' "$T/sec" || fail 'what could not be judged is not shown'
! grep -q 'changed since' "$T/sec" || fail 'the plan they read is said changed'
pl ratify --words 'yes'; [ "$RC" = 0 ] || fail 'a first ratification was refused with the placements read: a finding refuses nothing'
# changed since, and a later ratification
pt_rs 's/^\(step S02 .*\) ROW-012 /\1 /'; pt_rs 's/^\(step S04 .*rows:\) /\1 ROW-012 /'
pl page; sec; grep -q 'placements changed since the plan they read: 1$' "$T/sec" || fail 'how many placements changed since is not said'
sh "$CHECKS/plan.sh" change rows 'ROW-012 moves' --trigger discovered-dependency --evidence step:S04 --expect 'S04 holds it' > "$T/out" 2>&1 || fail 'the change could not be recorded'
rm -rf "$D"; pl page; pl ratify --words 'again'; [ "$RC" = 0 ] || fail 'a later ratification was refused for the reading'
# a switch's: a ticket published before any ratification
cd "$T"; rm -rf toy; mn_project "$T/man"; rm -rf "$D"
printf 'published 1 kind=step step=S02 rows=ROW-001 at=2026-11-01T09:00:00Z\n' > .vid/tw/log
printf '%s\n' "$AP" > .vid/tw/applied; printf 'github-mode: manual\n' >> .vid/tw/settings; printf 'setup-answered key=github-mode value="manual" words="the toy, answered" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
{ printf '# RUN-STATE\n\n## The plan\n\n```vid-plan\n'; cat "$T/plan.blk"; printf '```\n'; } > .vid/RUN-STATE.md
pl ratify --words 'yes'; ! grep -q 'two readers' "$T/out" || fail 'a switch'"'"'s ratification, a ticket published, was refused for the reading'
: > .vid/tw/log; pl ratify --words 'yes'; grep -q 'two readers' "$T/out" || fail 'a first plan in GitHub manual, no ticket published, is not asked for the reading'
for c in mode mode-auto; do VID_CALLER=$c sh "$CHECKS/planner.sh" ratify --words 'yes' > "$T/out" 2>&1 || :; ! grep -q 'two readers' "$T/out" || fail "a switch's ratification (VID_CALLER=$c), no ticket published, was refused for the reading"; done
# in GitHub manual the plan is of the applied version: the part names its commit, so the readers read that spec, not the folder's
pl placements write "$T/mp" --all; [ "$RC" = 0 ] || fail 'the list was refused in GitHub manual'; A12=$(git rev-parse --short=12 "$AP")
cp "$T/mp/part-1.md" "$T/out"; grep -qF "read each of its files as \`git show $A12:<file>\` gives it" "$T/mp/part-1.md" || fail 'a part in GitHub manual does not name the commit its spec is of'
exit 0
