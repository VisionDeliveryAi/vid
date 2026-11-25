#!/bin/sh
# Purpose: selftest case — the list is data alone (GM-2 T12; FB-5 A1: the page gone). On the toy call of manual-plan-page
# (fixtures/plan-page.sh), the list `next-page.sh write` makes is one file of valid JSON, beside what the planner last gave (.vid/face/plan.cache),
# with no temporary file left; every address in it is GitHub's (the ticket's, a pull request's) but words of a person's, which stay words: an item of the
# backlog, a title and a name holding markup, a quote and a backslash are read back as they were written. Env: CHECKS.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'needs python3 to read the JSON'; exit 77; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "manual-plan-page-offline: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
pp_toy "$T/toy"; pp_scene
mkdir -p .vid/decide/queue; printf 'Q1\tk1\tto do\tyou\tQuestion: <script>x</script> "a" \\ b\tanswer\t-\t2026-11-18T09:00:00Z\t-\n' > .vid/decide/queue/backlog
printf '%s\n' 'sorted 2026-11-19T09:00:00Z' 'state sorted' 'line todo 1.1 Q1' 'title A <b>"bold"</b> \ title' 'do Say' 'what It' 'ask Which?' 'choice Yes' 'then Next' 'name ana Ana "<i>" B.' > "$T/sorted"
pp_write "$T/trig"
[ "$PP_RC" = 0 ] && [ -s "$LJ" ] || fail "next-page.sh write made no list ($PP_RC)"
[ "$(find .vid/face -type f | sort | paste -sd ' ' -)" = "$LJ .vid/face/plan.cache" ] || fail "more than the list and the planner's own is in .vid/face: $(find .vid/face -type f | paste -sd ' ' -)"
pj_is "d['rest']['holds'][0]['words']" 'Question: <script>x</script> "a" \ b' "the item's words"
pj_is "d['todo'][0]['title']" 'A <b>"bold"</b> \ title' "the line's title"
pj_is "c('S02')['who']" 'Ana "<i>" B.' "the name of who has S02"
grep -oE 'https?://[A-Za-z0-9.-]+' "$LJ" | sort -u > "$T/hosts"
[ "$(paste -sd ' ' - < "$T/hosts")" = https://github.com ] || fail "the list holds an address but GitHub's: $(paste -sd ' ' - < "$T/hosts")"
echo 'manual-plan-page-offline: ok'
