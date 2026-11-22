#!/bin/sh
# Purpose: selftest case — FB-1 C1: the old `team` mode is retired. On GitHub manual's toy (fixtures/manual.sh), every setup key
# answered but github-mode, each toy with a fake GitHub of its own: `planner.sh setup github-mode team` is refused, naming GitHub manual and GitHub auto, and records
# nothing. With a plan written (RUN-STATE's plan block, PLAN.md at HEAD) and no mode answered, `mode.sh manual --applied <the
# plan's commit> --words` ratifies the plan in those words and records manual. A project recorded `team` (an old answer) is
# refused by `connect.sh start` with no lock taken, `mode.sh auto` from it is refused naming /vid mode manual, and
# `mode.sh manual` moves it over, recording from=team. No shipped script, skill or README offers GitHub team: every line naming
# it says it is retired. Env: CHECKS.
set -eu
unset VID_CALLER CLAUDE_CODE_SESSION_ID GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE 2>/dev/null || true
TT=$(mktemp -d); trap 'rm -rf "$TT"' EXIT; T=$TT/a; mkdir -p "$T"   # each toy its own fake GitHub, so no records cross
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "team-retired: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
run() { RC=0; "$@" > "$T/out" 2>&1 || RC=$?; }
gm() { sed -n 's/^setup-answered key=github-mode value="\([a-z]*\)".*/\1/p' .vid/plan/setup | tail -n 1; }
plan() { { printf 'mode: tickets\nplan: required\nrun: waiting\n\n## The plan\n\n```vid-plan\n'; cat "$T/plan.blk"; printf '```\n'; } > .vid/RUN-STATE.md; }
mn_project "$T/p"; plan; gh repo create owner/vid-state --private > /dev/null 2>&1 || :
# no new team
run sh "$CHECKS/planner.sh" setup github-mode team --words 'our own people work them'
[ "$RC" != 0 ] || fail 'setup github-mode team was taken'
grep -qF "GitHub team is retired: a team of people works the tickets in GitHub manual (/vid mode manual); ViD's own DevAgent, in GitHub auto" "$T/out" || fail 'the refusal does not point to GitHub manual and GitHub auto'
[ -z "$(gm)" ] || fail "the refused answer was recorded: $(gm)"
# a fresh project, a plan written, no mode answered: the switch ratifies and records manual
run sh "$CHECKS/mode.sh" manual --applied "$AP" --review "$T/review" --words 'yes, our people work the tickets'
[ "$RC" = 0 ] || fail "the switch on a fresh project exited $RC"
grep -qx 'mode: GitHub manual, recorded' "$T/out" || fail 'the switch did not record GitHub manual'
[ "$(gm)" = manual ] || fail "the mode recorded is '$(gm)', not manual"
sh "$CHECKS/planner.sh" ratified > "$T/out" 2>&1 || fail 'the plan is not ratified after the switch'
grep -q '^ratified .*words=yes, our people work the tickets$' .vid/plan/ratified || fail "the ratification is not in the owner's words"
# a project recorded team: stopped and pointed over
T=$TT/b; mkdir -p "$T"; mn_project "$T/q"; plan; gh repo create owner/vid-state --private > /dev/null 2>&1 || :
printf 'setup-answered key=github-mode value="team" words="an outside team" at=2026-11-03T09:30:00Z\n' >> .vid/plan/setup
run sh "$CHECKS/connect.sh" start
[ "$RC" = 1 ] || fail "a project recorded team got past connect.sh start ($RC)"
grep -qxF 'connect mode: this project is recorded in GitHub team, which is retired: /vid mode manual moves it to GitHub manual; no lock is held' "$T/out" || fail 'the start does not point a team project to /vid mode manual'
[ -z "$(mn_lock)" ] || fail 'the refused start took the lock'
run sh "$CHECKS/mode.sh" auto --words 'go auto'
[ "$RC" != 0 ] && grep -qF '/vid mode manual' "$T/out" || fail "/vid mode auto from team was not refused naming /vid mode manual ($RC)"
[ "$(gm)" = team ] || fail 'the refused switch to auto changed the mode'
run sh "$CHECKS/mode.sh" manual --applied "$AP" --review "$T/review" --words 'yes, move it to manual'
[ "$RC" = 0 ] || fail "/vid mode manual from team exited $RC"
[ "$(gm)" = manual ] || fail "after /vid mode manual from team the mode is '$(gm)'"
grep -q '^mode name=manual from=team ' .vid/metrics-events || fail 'the switch did not record from=team'
# the names: no shipped script, skill or README offers GitHub team
R=$CHECKS/..
for f in "$CHECKS"/*.sh "$CHECKS"/lib/*.sh; do b=${f#"$R"/}
  grep -inE 'github[ -]team|github-mode:? *team|value="team"' "$f" | grep -iv 'retired' > "$T/out" && fail "$b offers GitHub team (above)"; done
[ -d "$R/skills" ] && [ -f "$R/README.md" ] || { echo 'needs skills/ and README.md beside checks/'; exit 77; }
for f in "$R"/skills/*/SKILL.md "$R/README.md"; do b=${f#"$R"/}
  grep -inE 'github[ -]team|github-mode:? *team|value="team"' "$f" | grep -iv 'retired' > "$T/out" && fail "$b offers GitHub team (above)"; done
echo 'team-retired: ok'
