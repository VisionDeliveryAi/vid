#!/bin/sh
# Purpose: selftest case — an outside service the developers can reach (`place: dev`) is an ordinary test of its step (FB-4
# A2, planner.sh), on the planner's toy (fixtures/planner-toy.sh) with SEAM-003, `credentials: held`. With the field its mark is
# `service`, it is planned to its step's stage and the check is clean; without it its line of the rows table is what it was,
# mark `seam`, deploy-owed. A `service` row in the skeleton, or in no step, is flagged. The page's notes list the seams that are
# staging only because no credentials were held, and no other; never a flag. The same in GitHub manual. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-place-dev: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
B='seam | SEAM-003 | the synonym service | looking up the other names of an occupation | chosen: D-003 | credentials: held | probe: owed | evidence: owed | quirks: none yet'
# toy <folder> <place field> <step, or none>
toy() { cd "$T"; pt_toy "$T/$1"; pt_after SEAM-002 "$B$2"
  case $3 in S05) pt_rs 's/rows: ROW-017 |/rows: ROW-017 SEAM-003 |/; s/^needs ROW-017 | -$/needs ROW-017 SEAM-003 | -/' ;; S01) pt_rs 's/rows: ROW-003 ROW-004 |/rows: ROW-003 ROW-004 SEAM-003 |/; s/^needs ROW-003 ROW-004 | -$/needs ROW-003 ROW-004 SEAM-003 | -/' ;; esac; }
row() { sh "$CHECKS/planner.sh" rows 2>/dev/null | grep "^SEAM-003" > "$T/row" || :; }
TAB=$(printf '\t')
toy a ' | place: dev' S05; pt_check; [ "$PT_RC" = 0 ] || fail "the plan is flagged ($PT_RC)"; row
printf 'SEAM-003\trow\t\t\t2\tplanned\tservice\tlooking up the other names of an occupation\twhat the promise says is not what is observed\tplanned to stage 2\tservice: the synonym service · chosen: D-003 · credentials: held · probe: owed · evidence: owed · quirks: none yet · place: dev\t-\n' > "$T/want"
cmp -s "$T/want" "$T/row" || { cat "$T/row" > "$T/out"; fail 'the row is not an ordinary one, mark service, planned to stage 2'; }
# without the field: as before, its step's stage apart
toy b '' S05; pt_check; [ "$PT_RC" = 0 ] || fail "without the field the plan is flagged ($PT_RC)"; row
printf 'SEAM-003\trow\t\t\t2\towed\tseam\tlooking up the other names of an occupation\twhat the promise says is not what is observed\tdeploy-owed: staging, in stage 2\tservice: the synonym service · chosen: D-003 · credentials: held · probe: owed · evidence: owed · quirks: none yet\t-\n' > "$T/want"
cmp -s "$T/want" "$T/row" || { cat "$T/row" > "$T/out"; fail 'without the field the row is not as before'; }
# the note: SEAM-002 alone (SEAM-001's probe is owed, SEAM-003 is held), on the page alone
sh "$CHECKS/planner.sh" page > "$T/out" 2>&1 || fail 'page failed'; awk '/^## Notes/ { on = 1; next } on && /^## / { exit } on' .vid/plan/PLAN-PAGE.md > "$T/out"
[ "$(grep -c 'if the developers can reach one, say so: it goes with the step that builds it' "$T/out")" = 1 ] || fail 'the note is not there once'
grep 'if the developers can reach one' "$T/out" | grep -q '^- SEAM-002: ' || fail 'the note does not list SEAM-002 alone'
pt_set SEAM-002 'seam | SEAM-002 | the first job feed | scheduled read of the partner'"'"'s active jobs | chosen: D-002 | credentials: not-yet | probe: unreachable-risk(the partner has no test access) | evidence: owed | quirks: none yet'
sh "$CHECKS/planner.sh" page > "$T/out" 2>&1 || fail 'page failed'; ! grep -q 'if the developers can reach one' .vid/plan/PLAN-PAGE.md || fail 'a seam staging for another reason is in the note'
# the skeleton, and no step
toy c ' | place: dev' S01; pt_check; pt_has 'skeleton S01 — its row SEAM-003 is'; [ "$PT_RC" = 1 ] || fail 'a service row in the skeleton passed'
toy d ' | place: dev' none; pt_check; pt_has 'class SEAM-003 — in no step'
# GitHub manual
toy e ' | place: dev' S05; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec'; mkdir -p .vid/tw; git rev-parse HEAD > .vid/tw/applied
printf 'setup-answered key=github-mode value="manual" words="that one" at=2026-11-19T09:00:00Z\nsetup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
pt_check; [ "$PT_RC" = 0 ] || fail "in manual the plan is flagged ($PT_RC)"; row; grep -q "^SEAM-003${TAB}row${TAB}${TAB}${TAB}2${TAB}planned${TAB}service${TAB}" "$T/row" || fail 'in manual the mark is not service'
exit 0
