#!/bin/sh
# Purpose: selftest case — a first post in GitHub manual that cannot be the form filled in, or has no owner's words, is
# refused with nothing posted; outside manual nothing changes; the setup asks the form's keys (GM-2 T3, §5 "The settings",
# T10's spec repository; its case manual-form-refusals). The setup: planner.sh setup takes issue-form (a path in ViD's
# repository, never one from the top, with .., or one of the export's own files), issue-parent (an issue number, or none) and
# plan-page (artifact, a link, or none), and refuses anything else. On the form fixture's toy (fixtures/form.sh), S02's ticket
# written in manual: tw-post with a form holding an unknown placeholder ({owner};
# {owner_name} and {tests2}, whole lines outside the placeholders' letters), with a form lacking
# {fakes}, and with no --words, each refuses, naming it, and writes nothing to GitHub and no published line; with the form
# whole and the words given it goes out. Outside manual, with no issue-form: set, a post without words is today's: ViD's part 1
# as the body, no form= and no words= on its line, no form record (GM-4 F6: the form comes from the setup alone, so a post with
# no issue-form: is part 1 in either mode, never refused for it; GM-4 K1: --words is taken in either mode). The switch
# (fixtures/manual.sh's toy, those three keys unanswered) asks issue-form, issue-parent and plan-page; answered, it makes the
# missing spec repository private (`spec-repo <name> created`) and pushes nothing to it. Env: CHECKS.
set -eu
unset CLAUDE_CODE_SESSION_ID VID_CALLER 2>/dev/null || true
T=$(mktemp -d); T0=$T; trap 'rm -rf "$T0"' EXIT
. "$CHECKS/selftest/fixtures/form.sh"
fail() { echo "manual-form-refusals: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
fm_toy "$T/toy" || fail 'the toy could not be made'
PS=$CHECKS/planner.sh
# the setup keys
su() { sh "$PS" setup "$1" "$2" --words 'the toy owner, answering' > "$T/out" 2>&1; }
for v in /forms/issue.md ../issue.md forms/../x.md forms/ PRD.md TEST-DIFFERENCES.md design 'two words.md'; do ! su issue-form "$v" || fail "issue-form $v was taken"; done
su issue-form forms/issue.md || fail 'a good issue-form was refused'; grep -qx 'issue-form: forms/issue.md' .vid/tw/settings || fail 'issue-form was not written'
for v in abc 12x -3 '#4'; do ! su issue-parent "$v" || fail "issue-parent $v was taken"; done
su issue-parent none || fail 'issue-parent none was refused'; su issue-parent "$FM_P" || fail 'an issue-parent number was refused'
grep -qx "issue-parent: $FM_P" .vid/tw/settings || fail 'issue-parent was not written'
for v in maybe yes 'http://claude.ai/x'; do ! su plan-page "$v" || fail "plan-page $v was taken"; done
for v in none 'https://claude.ai/artifact/AbCdEf0123456789' artifact; do su plan-page "$v" || fail "plan-page $v was refused"; done
grep -qx 'plan-page: artifact' .vid/tw/settings || fail 'plan-page was not written'
for k in issue-form issue-parent plan-page; do grep -q "^setup-answered key=$k " .vid/plan/setup || fail "no setup-answered line for $k"; done
# the refusals, each with nothing posted
fm_prep S02 || { cp "$T/post" "$T/out"; fail "S02's ticket could not be written"; }
post() { gh_wclear; RC=0; sh "$CHECKS/github.sh" tw-post "$@" "$FM_F" > "$T/out" 2>&1 || RC=$?; }
none() { [ "$RC" = 1 ] || fail "$1: tw-post exited $RC, not 1"; grep -q -- "$2" "$T/out" || fail "$1: the refusal does not name $2"
  [ ! -s "$FAKEGH/writes" ] || { cp "$FAKEGH/writes" "$T/out"; fail "$1: something was written to GitHub"; }
  ! grep -q '^published ' .vid/tw/log || fail "$1: a published line was written"; [ ! -d .vid/tw/form ] || fail "$1: a form record was written"; }
cp forms/issue.md "$T/form"; printf '{owner}\n' >> forms/issue.md; g commit -qam 'the form, an unknown placeholder'
fm_prep S02 || { cp "$T/post" "$T/out"; fail "S02's ticket could not be written again"; }
post --words 'Yes, publish S02'; none 'an unknown placeholder' '{owner}'
for u in '{owner_name}' '{tests2}'; do { cat "$T/form"; printf '%s\n' "$u"; } > forms/issue.md; g commit -qam "the form, an unknown placeholder $u"
  fm_prep S02 || { cp "$T/post" "$T/out"; fail "S02's ticket could not be written for $u"; }
  post --words 'Yes, publish S02'; none "the unknown placeholder $u" "$u"; done
grep -v '^{fakes}$' "$T/form" > forms/issue.md; g commit -qam 'the form, without its fakes line'
fm_prep S02 || { cp "$T/post" "$T/out"; fail "S02's ticket could not be written a third time"; }
post --words 'Yes, publish S02'; none 'a form without {fakes}' '{fakes}'
cp "$T/form" forms/issue.md; g commit -qam 'the form, whole'
fm_prep S02 || { cp "$T/post" "$T/out"; fail "S02's ticket could not be written a fourth time"; }
post; none 'no words' 'words'
post --words 'Yes, publish S02'; [ "$RC" = 0 ] || fail "with the form whole and the words given, the post was refused ($RC)"
grep -q '^published .* words="Yes, publish S02"$' .vid/tw/log || fail 'the post in manual did not record the words'
# outside manual, today's post
printf 'setup-answered key=github-mode value="auto" words="back to auto" at=2026-11-19T10:00:00Z\n' >> .vid/plan/setup
grep -v '^issue-form:' .vid/tw/settings > "$T/s" && cat "$T/s" > .vid/tw/settings   # today's setup: no form (GM-4 F6)
tw_ratify 'Yes, publish it' || fail 'the plan could not be ratified again in auto'
sh "$CHECKS/github.sh" spec-export > "$T/out" 2>&1 && sh "$CHECKS/github.sh" tw-sync >> "$T/out" 2>&1 && sh "$CHECKS/plan.sh" start S03 >> "$T/out" 2>&1 || fail 'S03 was not prepared in auto'
FM_F=$(sh "$CHECKS/writer.sh" write step S03 2> "$T/out") || fail "S03's ticket was not written in auto"
sh "$CHECKS/github.sh" tw-post "$FM_F" > "$T/out" 2>&1 || fail 'outside manual the post was refused'
N=$(sed -n 's/^ViD github: published ticket #\([0-9]*\).*/\1/p' "$T/out"); [ -n "$N" ] || fail 'outside manual no ticket number was printed'
head -n 1 "$FAKEGH/issues/$N/body" | grep -qE "^Ticket #$N, part 1 of [0-9]+, writing [0-9a-f]+\.\$" || fail "outside manual the body is not ViD's part 1"
L=$(awk -v n="$N" '$1 == "published" && $2 == n' .vid/tw/log); case "$L" in *' form='*|*' words='*) fail "outside manual the published line changed: $L" ;; esac
[ ! -f ".vid/tw/form/issue-$N" ] && [ ! -f ".vid/tw/body/issue-$N" ] || fail 'outside manual a form or body record was written'
# the switch asks the form's keys, then makes the missing spec repository and exports nothing
T=$T0/m; mkdir "$T"   # a fake GitHub of its own
. "$CHECKS/selftest/fixtures/manual.sh"
mn_project "$T/p"
for k in issue-form issue-parent plan-page; do grep -v "^$k:" .vid/tw/settings > "$T/s" || :; cat "$T/s" > .vid/tw/settings; grep -v "key=$k " .vid/plan/setup > "$T/s" || :; cat "$T/s" > .vid/plan/setup; done
N1=$(gh_issue 'Skeleton'); mn_ticket "$N1" S01 skeleton ROW-003 ROW-004 > "$T/t1"; gh_writing "$N1" "$T/t1" body 2; printf '%s S01\n' "$N1" > "$T/register"; gh_wclear
rm -rf "$FAKEGH/repos/owner%code-spec"
mn_switch --applied "$AP" --words 'yes, ratify'; cp "$T/mo" "$T/out"
[ "$MN_RC" = 3 ] || fail "with the form's keys unanswered the switch exited $MN_RC, not 3"
for k in issue-form issue-parent plan-page; do grep -qx "ask $k" "$T/mo" || fail "the switch did not ask $k"; done
[ ! -s "$FAKEGH/writes" ] || fail 'the switch wrote before the keys were answered'
su issue-form forms/issue.md && su issue-parent none && su plan-page none || fail "the form's keys were refused"
mn_switch --applied "$AP" --words 'yes, ratify'; cp "$T/mo" "$T/out"
[ "$MN_RC" = 0 ] || fail "with the form's keys answered the switch exited $MN_RC"
grep -q '^spec-repo owner/code-spec created ' .vid/tw/log || fail 'the switch did not make the missing spec repository'
[ "$(gh repo view owner/code-spec --json isPrivate --jq .isPrivate)" = true ] || fail 'the spec repository is not private'
! grep -q '^owner/code-spec push' "$FAKEGH/writes" || fail 'the switch exported to the spec repository'
! grep -q '^owner/code ' "$FAKEGH/writes" || fail 'the switch wrote to the code repository'
exit 0
