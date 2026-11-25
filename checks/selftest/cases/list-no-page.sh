#!/bin/sh
# Purpose: selftest case — the page is gone, and the list is written whole or not at all (FB-5 A1, S4). On the toy of the board
# (fixtures/plan-page.sh), next-page.sh write makes .vid/face/list.json and no page: nothing under the caller's home, no
# plan.html anywhere, and no file of the project but the panel's own (.vid/face: the list, and what
# the planner last gave). A page written before, in the viewer's folder, stays as it was. It
# is in GitHub auto too, and refused outside ticket mode. A sort that cannot be read is refused, the list as it was; a plan that
# cannot be read keeps the plan and the teams last written, with the sort's part fresh, says so among the counts and exits 1;
# `text` is refused in GitHub auto. An unknown verb, and a lines file that is not there, are refused. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; HOME=$T/home; export HOME
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "list-no-page: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
np() { RC=0; sh "$T/ck/next-page.sh" "$@" > "$T/pw" 2>&1 || RC=$?; }
pp_toy "$T/toy"; pp_scene; mkdir -p .vid/decide/queue "$HOME/ViD Viewer/toy"; echo 'a page written before' > "$HOME/ViD Viewer/toy/plan.html"
sums() { find . "$HOME" -type f ! -path './.vid/face/*' -exec cksum {} + | sort; }
sums > "$T/b4"; np write "$T/trig"; [ "$RC" = 0 ] || fail "write failed ($RC)"
[ "$(cat "$T/pw")" = "list $LJ" ] || fail 'it prints more than the list'"'"'s path'
sums > "$T/aft"; cmp -s "$T/b4" "$T/aft" || { diff "$T/b4" "$T/aft" >&2 || :; fail 'something but the list was written'; }
[ "$(cat "$HOME/ViD Viewer/toy/plan.html")" = 'a page written before' ] || fail 'the page written before changed'
! grep -rq 'plan\.html' "$CHECKS/next-page.sh" "$CHECKS/next-move.sh" || fail 'a script still names plan.html'
! grep -qE 'ViD Viewer|<html' "$CHECKS/next-page.sh" || fail 'next-page.sh still makes a page'
# a sort that cannot be read
cp "$LJ" "$T/was"; rm -f "$T/sorted"; np write "$T/trig"
[ "$RC" = 1 ] && grep -q 'the sort could not be read' "$T/pw" && cmp -s "$LJ" "$T/was" || fail "a sort that cannot be read was not refused with the list as it was (exit $RC)"
# a plan that cannot be read
printf 'sorted 2026-11-19T09:00:00Z\nstate sorted\nline changed - -\nwhat A thing moved\n' > "$T/sorted"
rm "$T/ck/planner.sh"; printf '#!/bin/sh\necho broken >&2\nexit 2\n' > "$T/ck/planner.sh"; np write "$T/trig"
[ "$RC" = 1 ] || fail "a plan that cannot be read exits $RC"
pj_is "[d['state'], d['changed']]" '["sorted", ["A thing moved"]]' "the sort's part"
pj_is "[len(cs), len(d['plan']['releases']), d['rest']['counts'][-1]['words']]" '[5, 3, "plan could not be read: the plan and the teams are as last worked out"]' 'the plan last written'
np text "$T/trig"; [ "$RC" = 1 ] && ! grep -q 'S01' "$T/pw" || fail "text with no plan to read exits $RC"
rm "$T/ck/planner.sh"; ln -s "$CHECKS/planner.sh" "$T/ck/planner.sh"
# refusals
np write "$T/no-such"; [ "$RC" = 1 ] || fail "a lines file that is not there was taken (exit $RC)"
np page; [ "$RC" = 2 ] || fail "an unknown verb exits $RC"
sed -i.bak '/github-mode/d' .vid/plan/setup; np write; [ "$RC" = 0 ] || fail "write in GitHub auto failed ($RC)"
np text; [ "$RC" = 1 ] && grep -q "GitHub manual's" "$T/pw" || fail "text was taken in GitHub auto (exit $RC)"
rm .vid/tw/settings; cp "$LJ" "$T/was"; np write; [ "$RC" = 1 ] && grep -q 'no ticket-mode project' "$T/pw" && cmp -s "$LJ" "$T/was" || fail "write outside ticket mode was not refused (exit $RC)"
echo 'list-no-page: ok'
