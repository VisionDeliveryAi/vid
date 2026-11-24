#!/bin/sh
# Purpose: selftest case — a STAGES.md the stage court refuses is never ratified (FB-3 C2). On the planner's toy
# (fixtures/planner-toy.sh), a row: line placing a hostility row: in GitHub auto, with the file on disk, and in GitHub manual, with
# the applied commit's, `planner.sh check` flags `stages STAGES.md — <the court's reason>`, the page shows it and `ratify` is refused
# and records nothing; the line gone (in GitHub manual the applied commit moved to one without it), check is clean and the plan is
# ratified; after that, the line back, `ratified` fails. `stages.sh check --work` reads the files on disk where `check` reads the
# index, and refuses the same line; STAGE-0 gone from HEAD's cut is refused staged and taken by `--work`. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fail() { echo "planner-stage-court: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
pl() { sh "$CHECKS/planner.sh" "$@" > "$T/out" 2>&1; }
bad() { awk '{ print } /^row: ROW-004 -> STAGE-0$/ { print "row: HOS-001 -> STAGE-2" }' STAGES.md > S.x && mv S.x STAGES.md; grep -q '^row: HOS-001' STAGES.md || fail 'the bad line did not land'; }
good() { grep -v '^row: HOS-001' STAGES.md > S.x && mv S.x STAGES.md; }
FL='stages STAGES.md — row: HOS-001 is no ROW or census row of the inventory'
flagged() { if pl check; then fail "planner.sh check prints clean on a STAGES.md the court refuses ($1)"; fi; grep -qF "$FL" "$T/out" || fail "no flag names the court's reason ($1)"
  pl page || fail "the page could not be written ($1)"; grep -qF "$FL" .vid/plan/PLAN-PAGE.md || fail "the page does not show the court's refusal ($1)"
  pl review --in "$T/none"; if pl ratify --words 'yes'; then fail "a STAGES.md the court refuses was ratified ($1)"; fi
  grep -qF 'a check flag is open: stages STAGES.md' "$T/out" || fail "the ratification's refusal does not name the flag ($1)"; [ ! -s .vid/plan/ratified ] || fail "the refused ratification wrote .vid/plan/ratified ($1)"; }
clean() { pl check || fail "check is not clean with the line gone ($1)"; pl page || fail "the page could not be written ($1)"; pl review --in "$T/none" || fail "the review was refused ($1)"; pl ratify --words 'yes' || fail "the good plan was not ratified ($1)"; pl ratified || fail "the good plan does not stand ratified ($1)"; }
printf 'none\n' > "$T/none"
pt_toy "$T/auto"; bad; flagged 'GitHub auto'; good; clean 'GitHub auto'
bad; if pl ratified; then fail 'a ratified plan stands with a STAGES.md the court refuses (GitHub auto)'; fi

pt_toy "$T/man"; bad; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the spec, its cut refused'; mkdir -p .vid/tw
{ printf 'setup-answered key=state-repo value="the toy" words="the toy, answered" at=2026-11-03T09:00:00Z\n'; printf 'setup-answered key=github-mode value="manual" words="the toy, manual" at=2026-11-03T09:00:01Z\n'; } >> .vid/plan/setup
git rev-parse HEAD > .vid/tw/applied
good; g commit -qam 'the cut, fixed'; flagged 'GitHub manual, the applied commit'
git rev-parse HEAD > .vid/tw/applied; clean 'GitHub manual'

# the court itself: check reads the index, check --work the files on disk
bad; sh "$CHECKS/stages.sh" check > "$T/out" 2>&1 || fail 'check did not read the index'
if sh "$CHECKS/stages.sh" check --work > "$T/out" 2>/dev/null; then fail 'check --work passed a refused file on disk'; fi
grep -qx 'STAGES  row: HOS-001 is no ROW or census row of the inventory' "$T/out" || fail 'check --work does not print the court'"'"'s line'
good; sh "$CHECKS/stages.sh" check --work > "$T/out" 2>&1 || fail 'check --work refused a file that holds'
if sh "$CHECKS/stages.sh" check --nosuch > "$T/out" 2>&1; then fail 'an unknown argument of check was taken'; fi
# HEAD's cut with STAGE-0, the disk's without: refused staged, taken by --work, which compares no commit with the one before it
git show HEAD:STAGES.md | grep -q '^STAGE-0 ' || fail "HEAD's cut holds no STAGE-0"; grep -v -e '^STAGE-0 ' -e 'STAGE-0$' STAGES.md > S.x && mv S.x STAGES.md; git add STAGES.md
if sh "$CHECKS/stages.sh" check > "$T/out" 2>&1; then fail 'check took STAGE-0 removed, staged'; fi; grep -q '^STAGES  STAGE-0 is removed from STAGES.md' "$T/out" || fail "check's refusal does not name STAGE-0"
sh "$CHECKS/stages.sh" check --work > "$T/out" 2>&1 || fail 'check --work refused STAGE-0 removed on disk'
echo 'planner-stage-court: ok'
