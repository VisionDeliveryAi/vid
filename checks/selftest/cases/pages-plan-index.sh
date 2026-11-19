#!/bin/sh
# Purpose: selftest case — the plan's page joins the index (usability, B7), and the two skill sentences (B7, B11). On
# the pages' toy with a plan page as `planner.sh page` leaves it (.vid/plan/PLAN-PAGE.md rendered by page.sh, the
# stand-in here): `pages.sh plan` writes the plan's index line and prints its page line and the words on publishing;
# with the html removed, as after a restore, it renders the saved markdown again; with neither, one line and exit 0;
# .vid/plan/ is the same throughout. Where skills/ is there: vid-plan's sentence on the page sends publishing through
# `pages.sh plan`, the rest of the skill byte for byte as before; vid-view has the section "One document as a page",
# which runs `pages.sh` by the plugin's path and does what its lines say, the rest byte for byte as before (0.26.11.1.3 lane B:
# the pins moved three lines down, past R2's WSL notice in step 0). Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail() { echo "pages-plan-index: $*" >&2; cat "$T/out" >&2 2>/dev/null; exit 1; }
. "$CHECKS/selftest/fixtures/pages-toy.sh"
S=$CHECKS/pages.sh
pg_toy "$T/toy"; H=$(pwd -P)
printf '# The plan: JobDigest\n\n## The plan\n\n- S01 the skeleton\n' > .vid/plan/PLAN-PAGE.md
sh "$CHECKS/page.sh" .vid/plan/PLAN-PAGE.md > /dev/null
plansum() { find .vid/plan -type f | LC_ALL=C sort | while IFS= read -r f; do printf '%s %s\n' "$(cksum < "$f")" "$f"; done; }
plansum > "$T/p0"
sh "$S" plan > "$T/out" 2>&1 || fail 'plan failed'
grep -qxF "page: The plan: JobDigest | $H/.vid/pages/PLAN-PAGE.html | -" "$T/out" || fail 'no page line for the plan'
grep -qF 'May ViD put this project' "$T/out" || fail 'the words on publishing are not printed'
grep -qxF "$(printf 'plan\tThe plan: JobDigest\t%s/.vid/pages/PLAN-PAGE.html\t-\t-' "$H")" .vid/pages/index || fail "the index does not name the plan's page"
# the html lost, as after a restore: rendered again from the saved markdown
rm .vid/pages/PLAN-PAGE.html
sh "$S" plan > "$T/out" 2>&1 || fail 'plan after a restore failed'
[ -f .vid/pages/PLAN-PAGE.html ] && grep -q '^plan	' .vid/pages/index || fail 'the plan page is not made again from its markdown'
grep -qF 'S01 the skeleton' .vid/pages/PLAN-PAGE.html || fail 'the page made again is not the plan'
plansum > "$T/p1"; cmp -s "$T/p0" "$T/p1" || fail '.vid/plan/ changed'
# neither: one line, exit 0, and the index no longer names it
rm .vid/pages/PLAN-PAGE.html; mv .vid/plan/PLAN-PAGE.md "$T/pp"
sh "$S" plan > "$T/out" 2>&1 || fail 'no plan page fails the call'
[ "$(grep -c . "$T/out")" = 1 ] || fail 'no plan page is not one line'
grep -q '^plan	' .vid/pages/index 2>/dev/null && fail 'the index names a plan page that is gone'
# the two skill sentences
K=$CHECKS/../skills; [ -d "$K/vid-plan" ] && [ -d "$K/vid-view" ] || { echo 'needs skills/'; exit 77; }
P=$K/vid-plan/SKILL.md
[ "$(sed -n '1,259p' "$P" | cksum)" = '938262299 24000' ] && [ "$(sed -n '265,$p' "$P" | cksum)" = '2320923771 1199' ] || fail "vid-plan changed outside its sentence on the page"
sed -n '260,264p' "$P" | tr '\n' ' ' > "$T/s"
grep -qF 'sh "${CLAUDE_PLUGIN_ROOT}/checks/pages.sh" plan' "$T/s" && grep -qF 'do what its lines say' "$T/s" || fail "vid-plan's sentence does not send the page through pages.sh plan"
grep -qiE 'publish it|private artifact' "$T/s" && fail 'vid-plan still tells the session to publish by itself'
V=$K/vid-view/SKILL.md
[ "$(awk '/^## One document as a page$/ { on = 1; next } on && /^## / { on = 0 } !on' "$V" | cksum)" = '575796771 2884' ] || fail "vid-view changed outside its new section"
awk '/^## One document as a page$/ { on = 1; next } on && /^## / { exit } on' "$V" | tr '\n' ' ' > "$T/v"
[ -s "$T/v" ] || fail 'vid-view has no section "One document as a page"'
grep -qF 'sh "${CLAUDE_PLUGIN_ROOT}/checks/pages.sh"' "$T/v" && grep -qF 'do what its printed lines say' "$T/v" || fail 'the section does not run pages.sh and do what it says'
for w in prd foundation tests stages findings plan book all; do grep -qF "\`$w\`" "$T/v" || fail "the section does not name $w"; done
grep -qiE 'publish it|private artifact' "$T/v" && fail 'the section tells the session to publish by itself'
exit 0
