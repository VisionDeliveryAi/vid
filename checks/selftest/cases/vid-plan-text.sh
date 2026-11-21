#!/bin/sh
# Purpose: selftest case — vid-plan's own words (low-1; GM-4 J5, P-15). R1 as GM-4 J5 makes it: the setup question offers
# `layout: separate` and `layout: one`, says in a plain sentence that with one repository ViD's own publish into the folder comes
# with `vid-spec-publish`, asks the spec repository in both layouts, and names the folder's default, docs/specs. R5: the review section states the round cap (at most
# 3 rounds a sitting, fewer when the count does not fall) and that once they close PL fixes nothing more on its own. A text
# check; skips where skills/ is absent. Env: CHECKS.
set -eu
VP=$CHECKS/../skills/vid-plan/SKILL.md
[ -f "$VP" ] || { echo 'needs skills/vid-plan/'; exit 77; }
fail() { echo "vid-plan-text: $*" >&2; exit 1; }
# R1: the setup question, from its bullet to the next one
Q=$(awk '/^ *- \*\*Where the code lives and the specs go\.\*\*/ { on = 1 } on && /^ *- \*\*The teams\.\*\*/ { exit } on' "$VP" | tr '\n' ' ' | tr -s ' ')
[ -n "$Q" ] || fail 'no setup question "Where the code lives and the specs go"'
printf '%s' "$Q" | grep -qF '`layout: separate`' || fail 'the setup question does not offer layout: separate'
printf '%s' "$Q" | grep -qF '`layout: one`' || fail 'the setup question does not offer layout: one'
printf '%s' "$Q" | grep -qF "With one repository, ViD's own publish into the folder comes with \`vid-spec-publish\`" || fail 'the setup question does not say that with one repository the publish into the folder comes with vid-spec-publish'
printf '%s' "$Q" | grep -qF '`spec-repo:` in both layouts' || fail 'the setup question does not ask the spec repository in both layouts'
printf '%s' "$Q" | grep -qF '`spec-path: <folder>` (default `docs/specs`)' || fail 'the setup question does not name the folder and its default, docs/specs'
! printf '%s' "$Q" | grep -qF 'is not in this version' || fail 'the setup question still says one repository is not in this version'
# R5: the review section, from its heading to the next
R=$(awk '/^## The review$/ { on = 1; next } on && /^## / { exit } on' "$VP" | tr '\n' ' ' | tr -s ' ')
[ -n "$R" ] || fail 'no section "The review"'
printf '%s' "$R" | grep -qF 'At most 3 rounds of review a sitting, fewer when the count does not fall' || fail 'the review section does not state the round cap'
printf '%s' "$R" | grep -qF 'Once they close, PL fixes nothing more on its own' || fail 'the review section does not say PL fixes nothing more once the rounds close'
echo 'vid-plan-text: ok'
