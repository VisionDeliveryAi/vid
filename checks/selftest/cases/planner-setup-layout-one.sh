#!/bin/sh
# Purpose: selftest case — one repository in the setup (GM-4 K13's setup keys, J4, J5: P-15). On the planner's toy, `planner.sh
# setup layout one` is accepted, written with its setup-answered line; the private spec repository is still asked with one
# repository (check flags `setup spec-repo` until it is answered), and /vid mode's setup step asks it too (`ask spec-repo`, exit
# 3). `setup spec-path <folder>` writes spec-path: (a plain path in the code repository; `..`, a leading or trailing / and an
# empty part refused, exit 2, nothing written); `setup spec-stamp <file>` writes spec-stamp:, a file named from the folder, and
# `none` writes no key; neither key is flagged unanswered. The plan page's setup says one repository, the folder (docs/specs, the
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
pl check; ok '^setup spec-repo — no answer of the owner'"'"'s is recorded'; no '^setup spec-path'; no '^setup spec-stamp'
# the folder: a plain path, refused otherwise with nothing written
cp .vid/tw/settings "$T/s0"
for v in '../up' '/abs/vid' 'up/vid/' 'up//vid' 'up/./vid'; do pl setup spec-path "$v" --words 'there'; [ "$RC" = 2 ] || fail "setup spec-path '$v' was taken ($RC)"; done
cmp -s .vid/tw/settings "$T/s0" || fail 'a refused spec-path changed the settings'
page; grep -qF 'docs/specs' "$T/pg" || fail "the page does not name the default folder docs/specs: $(cat "$T/pg")"
pl setup spec-path upstream/vid --words 'under upstream/vid'; [ "$RC" = 0 ] && grep -qx 'spec-path: upstream/vid' .vid/tw/settings || fail "setup spec-path upstream/vid failed ($RC)"
grep -q '^setup-answered key=spec-path value="upstream/vid" ' .vid/plan/setup || fail 'no setup-answered line for spec-path'
for v in '../STAMP' '/STAMP' 'a/../STAMP'; do pl setup spec-stamp "$v" --words 'that'; [ "$RC" = 2 ] || fail "setup spec-stamp '$v' was taken ($RC)"; done
pl setup spec-stamp STAMP --words 'the STAMP file'; [ "$RC" = 0 ] && grep -qx 'spec-stamp: STAMP' .vid/tw/settings || fail "setup spec-stamp STAMP failed ($RC)"
pl setup spec-repo owner/code-spec --words 'that spec repository'; [ "$RC" = 0 ] || fail "setup spec-repo failed ($RC)"
pl check; no '^setup spec-repo'
page; for w in 'one repository' 'upstream/vid' 'STAMP' 'owner/code-spec' 'vid-spec-publish'; do grep -qF "$w" "$T/pg" || fail "the page's setup does not say $w: $(cat "$T/pg")"; done
! grep -qF "gate stays shut" "$T/pg" || fail 'the page still says the writer'"'"'s gate stays shut with one repository'
pl setup spec-stamp none --words 'no stamp'; [ "$RC" = 0 ] && ! grep -q '^spec-stamp:' .vid/tw/settings || fail "setup spec-stamp none left a key ($RC)"
# /vid mode asks the spec repository with one repository too
cd /; mn_project "$T/m"; sed 's/^layout: separate$/layout: one/' .vid/tw/settings > "$T/st"; cp "$T/st" .vid/tw/settings; grep -v 'key=spec-repo ' .vid/plan/setup > "$T/su"; cp "$T/su" .vid/plan/setup
RC=0; sh "$CHECKS/mode.sh" manual > "$T/out" 2>&1 || RC=$?
[ "$RC" = 3 ] || fail "/vid mode with the spec repository unanswered exited $RC, not 3"; ok '^ask spec-repo$'
echo 'planner-setup-layout-one: ok'
