#!/bin/sh
# Purpose: selftest case — one repository in the setup (GM-4 K13's setup keys, J4: P-15; FB-3 B2). On the planner's toy, `planner.sh
# setup layout one` is accepted, written with its setup-answered line; the private spec repository is GitHub auto's alone: no
# `setup spec-repo` flag while the mode is unanswered or manual, one in auto until it is answered; `/vid mode manual` asks none, and with
# one repository the old spec repository may become the state repository, in manual and before the switch to it; `/vid mode auto` asks it again (`ask spec-repo`, exit 3) while the
# key is dropped or names the state repository. `setup spec-path <folder>` writes spec-path: (a plain path in the code repository; `..`, a leading or trailing / and an
# empty part refused, exit 2, nothing written); `setup spec-stamp <file>` writes spec-stamp:, a file named from the folder, and
# `none` writes no key; `setup spec-publish hand|vid` (FB-3 B1) writes spec-publish:, any other value refused (exit 2, nothing
# written), and the page says with `hand` that the team publishes; none of these keys is flagged unanswered. The plan page's setup says one repository, the folder (docs/specs, the
# default, while spec-path: is missing), the stamp, the spec repository, and that ViD's own publish into the folder is
# vid-spec-publish's. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/tickets.sh"; . "$CHECKS/selftest/fixtures/manual.sh"
fail() { echo "planner-setup-layout-one: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
PS=$CHECKS/planner.sh; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
pl() { RC=0; sh "$PS" "$@" > "$T/out" 2>&1 || RC=$?; }
page() { sh "$PS" page > /dev/null 2>&1 || :; awk '/^## The setup/ { on = 1 } on && /^\| Team/ { exit } on' .vid/plan/PLAN-PAGE.md | tr '\n' ' ' > "$T/pg"; }
pt_toy "$T/p"; rm -f .vid/plan/setup; mkdir -p .vid/tw; printf 'repo: owner/code\nsplit: journey\nteam: devagent | the whole product | core | 1\n' > .vid/tw/settings
pl setup layout one --words 'one repository, the specs in a folder'; [ "$RC" = 0 ] || fail "setup layout one was refused ($RC)"
grep -qx 'layout: one' .vid/tw/settings && grep -q '^setup-answered key=layout value="one" words="one repository, the specs in a folder" at=' .vid/plan/setup || fail 'layout one was not written with its setup-answered line'
pl check; no '^setup spec-repo'; no '^setup spec-path'; no '^setup spec-stamp'
cp .vid/plan/setup "$T/su0"; pl setup github-mode auto --words 'DevAgent'; pl check; ok '^setup spec-repo — no answer of the owner'"'"'s is recorded'
sed 's/key=github-mode value="auto"/key=github-mode value="manual"/' .vid/plan/setup > "$T/su"; cat "$T/su" > .vid/plan/setup; pl check; no '^setup spec-repo'
git init -q; echo '.vid/' > .gitignore; g add -A; g commit -qm 'the spec'; git rev-parse HEAD > .vid/tw/applied   # manual's page reads the applied version
page; grep -qF 'kept in this project' "$T/pg" && ! grep -qF 'The spec repository' "$T/pg" || fail "in manual the page does not say the export is kept in the project: $(cat "$T/pg")"
! grep -q 'Still to ask[^;]*spec-repo' "$T/pg" || fail "in manual the page says spec-repo is still to ask: $(cat "$T/pg")"
rm -f .vid/tw/applied; cat "$T/su0" > .vid/plan/setup; grep -v '^github-mode:' .vid/tw/settings > "$T/st"; cat "$T/st" > .vid/tw/settings
# the folder: a plain path, refused otherwise with nothing written
cp .vid/tw/settings "$T/s0"
for v in '../up' '/abs/vid' 'up/vid/' 'up//vid' 'up/./vid'; do pl setup spec-path "$v" --words 'there'; [ "$RC" = 2 ] || fail "setup spec-path '$v' was taken ($RC)"; done
cmp -s .vid/tw/settings "$T/s0" || fail 'a refused spec-path changed the settings'
page; grep -qF 'docs/specs' "$T/pg" || fail "the page does not name the default folder docs/specs: $(cat "$T/pg")"
pl setup spec-path upstream/vid --words 'under upstream/vid'; [ "$RC" = 0 ] && grep -qx 'spec-path: upstream/vid' .vid/tw/settings || fail "setup spec-path upstream/vid failed ($RC)"
grep -q '^setup-answered key=spec-path value="upstream/vid" ' .vid/plan/setup || fail 'no setup-answered line for spec-path'
for v in '../STAMP' '/STAMP' 'a/../STAMP'; do pl setup spec-stamp "$v" --words 'that'; [ "$RC" = 2 ] || fail "setup spec-stamp '$v' was taken ($RC)"; done
pl setup spec-stamp STAMP --words 'the STAMP file'; [ "$RC" = 0 ] && grep -qx 'spec-stamp: STAMP' .vid/tw/settings || fail "setup spec-stamp STAMP failed ($RC)"
# FB-3 B1: who publishes the folder
cp .vid/tw/settings "$T/s0"; pl setup spec-publish team --words 'the team'; [ "$RC" = 2 ] && cmp -s .vid/tw/settings "$T/s0" || fail "setup spec-publish team was taken ($RC)"
pl setup spec-publish hand --words 'we publish it'; [ "$RC" = 0 ] && grep -qx 'spec-publish: hand' .vid/tw/settings && grep -q '^setup-answered key=spec-publish value="hand" words="we publish it" at=' .vid/plan/setup || fail "setup spec-publish hand failed ($RC)"
page; grep -qF 'by its own process' "$T/pg" || fail "the page does not say the team publishes by its own process: $(cat "$T/pg")"
pl setup spec-publish vid --words 'ViD does'; [ "$RC" = 0 ] && grep -qx 'spec-publish: vid' .vid/tw/settings || fail "setup spec-publish vid failed ($RC)"
pl setup spec-repo owner/code-spec --words 'that spec repository'; [ "$RC" = 0 ] || fail "setup spec-repo failed ($RC)"
pl check; no '^setup spec-repo'; no '^setup spec-publish'
page; for w in 'one repository' 'upstream/vid' 'STAMP' 'owner/code-spec' 'vid-spec-publish'; do grep -qF "$w" "$T/pg" || fail "the page's setup does not say $w: $(cat "$T/pg")"; done
! grep -qF "gate stays shut" "$T/pg" || fail 'the page still says the writer'"'"'s gate stays shut with one repository'
pl setup spec-stamp none --words 'no stamp'; [ "$RC" = 0 ] && ! grep -q '^spec-stamp:' .vid/tw/settings || fail "setup spec-stamp none left a key ($RC)"
# /vid mode manual asks no spec repository with one repository; in manual the state repository may take its name; /vid mode auto asks it
cd /; mn_project "$T/m"; sed 's/^layout: separate$/layout: one/' .vid/tw/settings > "$T/st"; cp "$T/st" .vid/tw/settings; grep -v 'key=spec-repo \|key=state-repo ' .vid/plan/setup > "$T/su"; cp "$T/su" .vid/plan/setup
RC=0; sh "$CHECKS/mode.sh" manual > "$T/out" 2>&1 || RC=$?
[ "$RC" = 3 ] || fail "/vid mode with the state repository unanswered exited $RC, not 3"; ok '^ask state-repo$'; no '^ask spec-repo$'
printf 'setup-answered key=github-mode value="manual" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
pl setup state-repo owner/code-spec --words 'the old spec repository'; [ "$RC" = 0 ] && grep -qx 'state-repo: owner/code-spec' .vid/tw/settings || fail "in manual with one repository the old spec repository was not taken as the state repository ($RC)"
pl setup state-repo owner/code --words 'the code'; [ "$RC" = 2 ] || fail "the code repository was taken as the state repository ($RC)"
printf 'setup-answered key=spec-repo value="owner/code-spec" words="the toy" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
RC=0; sh "$CHECKS/mode.sh" auto > "$T/out" 2>&1 || RC=$?
[ "$RC" = 3 ] || fail "/vid mode auto with spec-repo: naming the state repository exited $RC, not 3"; ok '^ask spec-repo$'
grep -v '^spec-repo:' .vid/tw/settings > "$T/st"; cp "$T/st" .vid/tw/settings; RC=0; sh "$CHECKS/mode.sh" auto > "$T/out" 2>&1 || RC=$?
[ "$RC" = 3 ] || fail "/vid mode auto with spec-repo: dropped exited $RC, not 3"; ok '^ask spec-repo$'
# in GitHub auto, before the switch to manual asks it, the old spec repository is taken with one repository; with two it never is
sed 's/key=github-mode value="manual"/key=github-mode value="auto"/' .vid/plan/setup > "$T/su"; cp "$T/su" .vid/plan/setup; echo 'spec-repo: owner/code-spec' >> .vid/tw/settings
pl setup state-repo owner/code-spec --words 'that one'; [ "$RC" = 0 ] || fail "in GitHub auto with one repository the old spec repository was not taken as the state repository ($RC)"
sed 's/^layout: one$/layout: separate/' .vid/tw/settings > "$T/st"; cp "$T/st" .vid/tw/settings; pl setup state-repo owner/code-spec --words 'that one'; [ "$RC" = 2 ] || fail "with two repositories the spec repository was taken as the state repository ($RC)"
echo 'planner-setup-layout-one: ok'
