#!/bin/sh
# Purpose: selftest case — the setup's teams and the plan's lanes (v0.26.10.12.3.1 R1, R2).
# On the planner's toy (fixtures/planner-toy.sh): with no .vid/tw/settings, with stage 2's settings (repo:, spec-repo:,
# labels-prefix:, open-tickets:) and no team: line, and with the default team line, the one lane is devagent — a step
# `lane: india-1` is flagged `lane`, `lane: devagent` and `lane: -` are clean. Two teams of three (india, usa) give six
# lanes: every step in india-2 is clean, `lane: india-4` is flagged naming the six, a step with no lane is flagged. A
# team: line out of form is flagged `setup`: people 0, a kind but strict or core, a name twice, no name, a name with a
# hyphen, a line of three fields. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "planner-setup: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
fresh() { cd "$T"; rm -rf toy; pt_toy "$T/toy"; }
clean() { pt_check; [ "$PT_RC" -eq 0 ] || fail "$1 is flagged"; }
lane() { pt_rs "s/^\(step $1 .*\)| lane: [^|]*/\1| lane: $2 /"; }
one() { # <what>: the one lane devagent
  clean "$1, the toy"; lane S02 india-1; pt_check; pt_has 'lane S02 — lane india-1 is no lane of the setup (devagent)'
  lane S02 -; clean "$1, a step with lane: -"; lane S02 devagent; clean "$1, lane: devagent"; }
fresh; [ ! -f .vid/tw/settings ] || fail 'the toy has a settings file'; one 'no settings'
fresh; mkdir -p .vid/tw; printf 'repo: toy/jobdigest\nspec-repo: toy/jobdigest-spec\nlabels-prefix:\nopen-tickets: 2\n' > .vid/tw/settings; one "stage 2's settings"
fresh; pt_teams 'devagent | the whole product | core | 1'; one 'the default team line'
# two teams of three: six lanes
SIX='india-1, india-2, india-3, usa-1, usa-2, usa-3'
fresh; pt_teams 'india | stages 0 and 1 | strict | 3' 'usa | the data pipeline | core | 3'; pt_check
for s in S01 S02 S03 S04 S05; do pt_has "lane $s — lane devagent is no lane of the setup ($SIX)"; done
pt_rs 's/lane: devagent/lane: india-2/'; clean 'every step in india-2'
lane S04 india-4; pt_check; pt_has "lane S04 — lane india-4 is no lane of the setup ($SIX)"
lane S04 usa-3; lane S03 -; pt_check; pt_has "lane S03 — no lane; with 6 lanes every step names one ($SIX)"
pt_rs 's/^\(step S03 .*\)| lane: - $/\1/'; pt_check; pt_has 'lane S03 — no lane; with 6 lanes'
[ "$(grep -c . "$T/out")" = 1 ] || fail 'a step with no lane gives more than its one flag'
# team lines out of form
bad() { fresh; pt_teams "$1"; pt_check; pt_has "setup \"team: $1\" — $2"; }
bad 'india | stages 0 and 1 | strict | 0' 'people "0" is not a whole number of 1 or more'
bad 'india | stages 0 and 1 | loose | 3' '"loose" is not strict or core'
bad '| stages 0 and 1 | strict | 3' 'no name'
bad 'in-dia | stages 0 and 1 | strict | 3' 'the name in-dia is not lower-case letters and digits'
bad 'india | stages 0 and 1 | strict' 'not team: <name> | <area> | strict or core | <people>'
fresh; pt_teams 'india | stages 0 and 1 | strict | 1' 'india | the data pipeline | core | 2'; pt_check
pt_has 'setup "team: india | the data pipeline | core | 2" — the name india is used twice'
pt_has 'lane S02 — lane devagent is no lane of the setup (india)'
exit 0
