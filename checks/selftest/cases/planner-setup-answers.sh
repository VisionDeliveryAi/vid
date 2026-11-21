#!/bin/sh
# Purpose: selftest case — setup answers recorded (v0.26.10.26.7, R11, W-13), checks/planner.sh setup and check on the planner's toy.
# Defaults written with no setup-answered line (.vid/plan/setup) raise one `setup` flag a key (layout, team, split, repo, spec-repo, github-mode) before the first
# ratify, and ratify refuses; `setup` writes each key with the owner's words and a setup-answered line; "not yet" writes no repository key;
# settings holding layout one (accepted again, GM-4 J5: planner-setup-layout-one) still ask the spec repository, ViD's private
# one being asked in both layouts; the first team answer replaces a written default; an unknown key and a wrong
# answer are refused, a wrong github-mode answer among them (v0.26.10.28.8, R3). Once all are answered, ratify passes. An existing ratified plan with no setup-answered lines lands a
# draft. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID 2>/dev/null || true
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/tw-toy.sh"
fail() { echo "planner-setup-answers: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
PS=$CHECKS/planner.sh; ok() { grep -q -- "$1" "$T/out" || fail "no line: $1"; }; no() { ! grep -q -- "$1" "$T/out" || fail "a line: $1"; }
pl() { RC=0; sh "$PS" "$@" > "$T/out" 2>&1 || RC=$?; }
noev() { rm -f .vid/plan/setup; }
pt_toy "$T/p"; noev; mkdir -p .vid/tw; printf 'layout: separate\nrepo: owner/code\nspec-repo: owner/code-spec\nsplit: journey\nteam: devagent | the whole product | core | 1\n' > .vid/tw/settings
pl check; [ "$RC" = 1 ] || fail "defaults with no answers passed the check ($RC)"; for k in layout team split repo spec-repo github-mode; do ok "^setup $k — no answer of the owner's is recorded"; done
printf 'none\n' > "$T/none"; sh "$PS" review --in "$T/none" > /dev/null; sh "$PS" page > /dev/null 2>&1; pl ratify --words 'Yes'; [ "$RC" = 1 ] && ok 'ratify refused — a check flag is open: setup layout' || fail "ratify passed with the setup unanswered ($RC)"
pl setup colour blue --words 'blue'; [ "$RC" = 2 ] || fail 'an unknown key was taken'; pl setup layout both --words 'both'; [ "$RC" = 2 ] || fail 'a wrong layout was taken'; pl setup split fine; [ "$RC" = 2 ] || fail 'an answer with no words was taken'; pl setup github-mode both --words 'both'; [ "$RC" = 2 ] || fail 'a wrong github-mode answer was taken'
pl setup layout separate --words 'two repositories'; [ "$RC" = 0 ] || fail "setup layout failed ($RC)"; grep -qx 'layout: separate' .vid/tw/settings && [ "$(grep -c '^layout:' .vid/tw/settings)" = 1 ] || fail "layout: $(grep '^layout' .vid/tw/settings)"
grep -q '^setup-answered key=layout value="separate" words="two repositories" at=' .vid/plan/setup || fail 'no setup-answered line'
grep -qx 'labels-prefix:' .vid/tw/settings || fail 'no labels-prefix: line written with the setup'   # the walk: the writer refuses without it
# settings holding layout one: the spec repository still asked (GM-4 J5)
sed 's/^layout: separate$/layout: one/' .vid/tw/settings > "$T/st"; cat "$T/st" > .vid/tw/settings; printf 'setup-answered key=layout value="one" words="one repository, please" at=2026-11-03T09:00:00Z\n' >> .vid/plan/setup
pl check; no '^setup layout'; ok '^setup spec-repo'; ok '^setup team'
pl setup spec-repo owner/code-spec --words 'that spec repository'; [ "$RC" = 0 ] || fail "setup spec-repo failed ($RC)"
pl setup team 'web | the pages | strict | 2' --words 'a web team of two'; [ "$(grep -c '^team:' .vid/tw/settings)" = 1 ] && grep -qx 'team: web | the pages | strict | 2' .vid/tw/settings || fail "the first team answer did not replace the default: $(grep '^team' .vid/tw/settings)"
pl setup team 'devagent | the whole product | core | 1' --words 'and DevAgent'; [ "$(grep -c '^team:' .vid/tw/settings)" = 2 ] || fail 'a second team answer replaced the first'
grep -q '^repo: owner/code' .vid/tw/settings || fail 'no written repo default'; pl setup repo 'not yet' --words 'not yet'; ! grep -q '^repo:' .vid/tw/settings || fail '"not yet" wrote a repo key'
pl setup split journey --words 'by journey'; pl check; ok '^setup github-mode'; pl setup github-mode auto --words 'your own DevAgent'; [ "$RC" = 0 ] && grep -qx 'github-mode: auto' .vid/tw/settings || fail "setup github-mode failed ($RC)"; pl check; no '^setup '
{ grep -v '^team: web ' .vid/tw/settings || true; } > "$T/st"; cat "$T/st" > .vid/tw/settings   # one lane again, for the ratify
sh "$PS" page > /dev/null 2>&1; pl ratify --words 'Yes, all answered'; [ "$RC" = 0 ] || fail "ratify refused once every setup answer is recorded ($RC)"
# an existing ratified plan, no setup-answered events: a draft lands
cd /; tw_toy "$T/toy"; noev; tw_skel || fail "the skeleton round failed: $(cat "$T/werr" 2>/dev/null | tail -n 2)"
sh "$PS" check > "$T/out" 2>&1 || fail 'a ratified plan is flagged for its setup'; no '^setup '
sed 's/^| web | the pages |/| web | the pages and the operator pages |/' ARCHITECTURE.md > "$T/a"; cp "$T/a" ARCHITECTURE.md
RC=0; printf 'none\n' > "$T/rv"; sh "$CHECKS/land.sh" draft --review "$T/rv" --why 'the module table' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the draft was refused ($RC)"
RC=0; sh "$CHECKS/land.sh" 1 --words 'Yes, the module table' > "$T/out" 2>&1 || RC=$?; [ "$RC" = 0 ] || fail "the landing was refused ($RC)"; ok '^landed 1 at '
echo 'planner-setup-answers: ok'
