#!/bin/sh
# Purpose: selftest case — the GitHub mode moves only through /vid mode (GM-1 S1, §5's setup keys). On the planner's toy
# (fixtures/planner-toy.sh), committed in a git repository: a bare `planner.sh setup github-mode manual` is refused, naming
# /vid mode, and records nothing; the same call marked as /vid mode's (VID_CALLER=mode) passes; a change away from manual is
# refused bare and passes marked; github-mode team is refused, bare or marked, and records nothing (FB-1 C1: retired). `state-repo` takes owner/name and never the
# code repository or the spec repository (nor may those become it); `slack-channels` takes names, comma-separated, or none.
# Before a first ratification, in GitHub manual the setup flags name state-repo when it has no answer; under /vid mode's
# mark github-mode is not flagged (the switch records it last); outside manual state-repo is not asked. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "mode-setup-guard: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/planner-toy.sh"
g() { git -c user.email=vid@selftest -c user.name=vid "$@"; }
PS=$CHECKS/planner.sh
pl() { RC=0; sh "$PS" "$@" > "$T/out" 2>&1 || RC=$?; }
mpl() { RC=0; VID_CALLER=mode sh "$PS" "$@" > "$T/out" 2>&1 || RC=$?; }
ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
last() { sed -n 's/^setup-answered key=github-mode value="\([a-z]*\)".*/\1/p' .vid/plan/setup | tail -n 1; }
pt_toy "$T/p"; git init -q; printf '.vid/\n' > .gitignore; g add -A; g commit -qm 'the toy'
mkdir -p .vid/tw; git rev-parse HEAD > .vid/tw/applied; printf 'repo: owner/code\nspec-repo: owner/code-spec\nlabels-prefix:\n' > .vid/tw/settings
# into manual: only /vid mode's call
n0=$(grep -c . .vid/plan/setup)
pl setup github-mode manual --words 'by hand'; [ "$RC" != 0 ] || fail 'a bare setup github-mode manual was taken'
ok '/vid mode'; [ "$(grep -c . .vid/plan/setup)" = "$n0" ] || fail 'the refused call recorded an answer'; ! grep -q '^github-mode: manual' .vid/tw/settings || fail 'the refused call wrote the key'
mpl setup github-mode manual --words 'by hand, from now on'; [ "$RC" = 0 ] || fail "/vid mode's setup github-mode manual was refused ($RC)"
[ "$(last)" = manual ] && grep -qx 'github-mode: manual' .vid/tw/settings || fail 'manual was not recorded'
# out of manual: only /vid mode's call
for v in auto team; do pl setup github-mode "$v" --words 'back'; [ "$RC" != 0 ] || fail "a bare change from manual to $v was taken"; ok '/vid mode'; [ "$(last)" = manual ] || fail "the refused change to $v was recorded"; done
mpl setup github-mode auto --words 'DevAgent again'; [ "$RC" = 0 ] && [ "$(last)" = auto ] || fail "/vid mode's change to auto was refused ($RC)"
# FB-1 C1: team is retired, bare or marked
pl setup github-mode team --words 'an outside team'; [ "$RC" != 0 ] && [ "$(last)" = auto ] || fail "a change from auto to team was taken ($RC)"; ok 'GitHub team is retired'
mpl setup github-mode team --words 'an outside team'; [ "$RC" != 0 ] && [ "$(last)" = auto ] || fail "/vid mode's change to team was taken ($RC)"; ok 'GitHub team is retired'
# state-repo: owner/name, never the code repository or the spec repository
for v in owner/code owner/code-spec 'two words' noslash; do pl setup state-repo "$v" --words 'that one'; [ "$RC" != 0 ] || fail "state-repo $v was taken"; done
! grep -q '^state-repo:' .vid/tw/settings || fail 'a refused state-repo was written'
pl setup state-repo owner/vid-state --words 'a private one for ViD'; [ "$RC" = 0 ] || fail "a good state-repo was refused ($RC)"
grep -qx 'state-repo: owner/vid-state' .vid/tw/settings && grep -q '^setup-answered key=state-repo value="owner/vid-state" ' .vid/plan/setup || fail 'state-repo not recorded'
pl setup repo owner/vid-state --words 'the same'; [ "$RC" != 0 ] || fail 'repo equal to state-repo was taken'
pl setup spec-repo owner/vid-state --words 'the same'; [ "$RC" != 0 ] || fail 'spec-repo equal to state-repo was taken'
# slack-channels: names, comma-separated, or none
pl setup slack-channels none --words 'no Slack'; [ "$RC" = 0 ] && grep -qx 'slack-channels: none' .vid/tw/settings || fail "slack-channels none ($RC)"
pl setup slack-channels 'team-build,team-qa' --words 'those two'; [ "$RC" = 0 ] && grep -qx 'slack-channels: team-build,team-qa' .vid/tw/settings || fail "slack-channels names ($RC)"
pl setup slack-channels 'two words' --words 'that'; [ "$RC" != 0 ] || fail 'a channel list with a space in a name was taken'
pl setup slack-channels '' --words 'nothing'; [ "$RC" != 0 ] || fail 'an empty channel list was taken'
# the setup flags before a first ratification
grep -v -e '^setup-answered key=state-repo ' -e '^setup-answered key=github-mode ' .vid/plan/setup > "$T/s" || true; cat "$T/s" > .vid/plan/setup
printf 'setup-answered key=github-mode value="manual" words="by hand" at=2026-11-19T09:00:00Z\n' >> .vid/plan/setup
pl check; ok '^setup state-repo — '; no '^setup github-mode'
cat "$T/s" > .vid/plan/setup
mpl check; ok '^setup state-repo — '; no '^setup github-mode'
pl check; ok '^setup github-mode — '; no '^setup state-repo'
exit 0
