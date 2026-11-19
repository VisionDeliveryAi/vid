#!/bin/sh
# Purpose: selftest case — in GitHub manual the plan is ratified at the applied version (GM-1 S3, §5's planner lines). On the
# planner's toy (fixtures/planner-toy.sh), committed in a git repository, its applied version the first commit: ratified in
# manual, a change to INVENTORY.md committed after the applied commit leaves `ratified` passing, the hash and the check as
# they were, while `rows --newest` reads the working tree's text and `rows` the applied one; an uncommitted PLAN.md edit
# leaves the hash (PLAN.md is read at HEAD) and a committed one ends the ratification. With .vid/tw/applied empty, or naming
# no commit, every planner subcommand but setup refuses. The same change in GitHub auto ends the ratification. The two kinds
# of flag the switch accepts read `place <row> — in no step` and `place <row> — in step <s> of stage <k>; its own stage is <j>`;
# a row listed on .vid/tw/to-place in that same place is no flag in check, ratify and ratified, and the page lists it as to
# place; listed in the other place it is still flagged; outside manual the same rows give today's class and step flags. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "manual-applied-ratified: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
PS=$CHECKS/planner.sh
pl() { RC=0; sh "$PS" "$@" > "$T/out" 2>&1 || RC=$?; }
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
printf 'none\n' > "$T/none"
# toy <mode>: the toy committed, the mode answered, the applied version its commit
toy() { cd "$T"; rm -rf p; pt_toy "$T/p"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the toy'
  printf 'setup-answered key=github-mode value="%s" words="that one" at=2026-11-19T09:00:00Z\n' "$1" >> .vid/plan/setup
  printf 'setup-answered key=state-repo value="owner/vid-state" words="that one" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
  mkdir -p .vid/tw; git rev-parse HEAD > .vid/tw/applied; }
sitting() { pl review --in "$T/none"; pl page; pl ratify --words "$1"; [ "$RC" = 0 ] || fail "ratify refused: $(cat "$T/out")"; }
restate() { sed 's/Each saved search gets one digest a day/Each saved search gets exactly one digest a day/' INVENTORY.md > "$T/i" && cat "$T/i" > INVENTORY.md; }
# manual: a change after the applied commit keeps the ratification
toy manual; sitting 'Yes, ratified by hand'
H0=$(sh "$PS" hash); pl ratified; [ "$RC" = 0 ] || fail 'ratified fails right after the ratification'
restate; g commit -qam 'ROW-001 restated after the applied commit'
pl ratified; [ "$RC" = 0 ] || fail 'in manual a change after the applied commit ended the ratification'
[ "$(sh "$PS" hash)" = "$H0" ] || fail 'in manual the hash moved with a change after the applied commit'
pl check; [ "$RC" = 0 ] || fail 'in manual the check flags a change after the applied commit'
pl rows; ok '^ROW-001	.*Each saved search gets one digest a day'; no 'exactly one digest'
pl rows --newest; ok '^ROW-001	.*Each saved search gets exactly one digest a day'
# each other spec file read at the applied commit too
for f in PRD.md STAGES.md GRADING-CHECKLIST.md ARCHITECTURE.md; do printf '\nA line added after the applied commit.\n' >> "$f"; g commit -qam "$f changed after the applied commit"
  [ "$(sh "$PS" hash)" = "$H0" ] || fail "in manual the hash moved with a change to $f after the applied commit"
  pl ratified; [ "$RC" = 0 ] || fail "in manual a change to $f after the applied commit ended the ratification"; done
G=tests/invariants/golden/synonyms.golden; head -n 1 "$G" > "$T/g1"; g rm -q "$G"; g commit -qm 'the golden set retired after the applied commit'
pl ratified; [ "$RC" = 0 ] || fail 'in manual a golden set removed after the applied commit ended the ratification'
pl page; grep -qxF "$(cat "$T/g1")" .vid/plan/PLAN-PAGE.md || fail "in manual the page does not show the golden set as the applied commit holds it"
grep -v '| HOS-005 |' INVENTORY.md > "$T/i"; cat "$T/i" > INVENTORY.md
pl ratified; [ "$RC" = 0 ] || fail 'in manual an uncommitted INVENTORY.md edit ended the ratification'; git checkout -q -- INVENTORY.md
# PLAN.md is read at HEAD
printf '\n' >> PLAN.md; [ "$(sh "$PS" hash)" = "$H0" ] || fail 'in manual an uncommitted PLAN.md edit moved the hash'
g commit -qam 'PLAN.md touched'; pl ratified; [ "$RC" != 0 ] || fail 'in manual a committed PLAN.md change kept the ratification'
# no applied commit: refused
for c in hash check rows page ratified counts 'review --in '"$T/none"; do
  : > .vid/tw/applied; pl $c; [ "$RC" != 0 ] || fail "planner.sh $c ran with no applied commit"; ok 'applied'
  echo 0123456789abcdef0123456789abcdef01234567 > .vid/tw/applied; pl $c; [ "$RC" != 0 ] || fail "planner.sh $c ran with an applied line naming no commit"; done
pl rows --newest; [ "$RC" = 0 ] || fail 'rows --newest needs the applied commit'
pl setup slack-channels none --words 'no Slack'; [ "$RC" = 0 ] || fail 'setup needs the applied commit'
# auto: the same change ends the ratification
toy auto; sitting 'Yes'; restate; g commit -qam 'ROW-001 restated'
pl ratified; [ "$RC" != 0 ] || fail 'in auto a change to INVENTORY.md kept the ratification'
# the two kinds of flag the switch accepts, and the rows to place
place() { pt_set 'step S04' 'step S04 | name: limits, backups, failures, the data move and synonyms | modules: digest ingest search | builds-on: S02 S03 | rows: ROW-009 ROW-011 ROW-018 HOS-003 DIF-001 RULE-004 ROW-017 | lane: devagent'
  pt_del 'step S05'; sed 's/^needs ROW-002 /needs /' .vid/RUN-STATE.md > "$T/r" && cat "$T/r" > .vid/RUN-STATE.md
  sh "$CHECKS/plan.sh" change other 'ROW-002 out, ROW-017 into S04' --trigger discovered-dependency --evidence step:S04 --expect 'two rows to place' > "$T/out" 2>&1 || fail 'the plan change was refused'; }
toy auto; place; pl check; [ "$RC" = 1 ] || fail "outside manual the misplaced rows passed ($RC)"
ok '^class ROW-002 — in no step'; ok '^step S04 — its rows are in stages'; no '^place '
toy manual; place; pl check; [ "$RC" = 1 ] || fail "in manual the misplaced rows passed with no to-place list ($RC)"
ok '^place ROW-002 — in no step$'; ok '^place ROW-017 — in step S04 of stage 1; its own stage is 2$'; no '^class ROW-002'; no '^step S04 — its rows are in stages'
printf 'ROW-002\tother-stage\t2026-11-19T09:00:00Z\tplace them later\nROW-017\tno-step\t2026-11-19T09:00:00Z\tplace them later\n' > .vid/tw/to-place
pl check; ok '^place ROW-002 — in no step$'; ok '^place ROW-017 — in step S04'
printf 'ROW-002\tno-step\t2026-11-19T09:00:00Z\tplace them later\nROW-017\tother-stage\t2026-11-19T09:00:00Z\tplace them later\n' > .vid/tw/to-place
pl check; [ "$RC" = 0 ] || fail "in manual the rows to place are still flags ($RC)"
sitting 'Yes, with those two to place'; pl ratified; [ "$RC" = 0 ] || fail 'ratified fails with rows to place'
grep -qi 'to place' .vid/plan/PLAN-PAGE.md || fail 'the page shows no rows to place'
awk '/^## .*[Tt]o place/ { on = 1; next } on && /^## / { exit } on' .vid/plan/PLAN-PAGE.md > "$T/tp"
grep -q 'ROW-002' "$T/tp" && grep -q 'ROW-017' "$T/tp" || fail 'the page'"'"'s rows to place miss a row'
if grep -q '^- place ROW-0' .vid/plan/PLAN-PAGE.md; then fail 'the page lists a row to place as a flag'; fi
exit 0
