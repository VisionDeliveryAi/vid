#!/bin/sh
# Purpose: selftest case — the plan page opens offline (GM-2 T12). On the toy call of manual-plan-page (fixtures/plan-page.sh), the
# page `next-page.sh write` makes is one file, alone in its folder beside the viewer's pages: no script, no stylesheet, font or
# image it loads, no `url(` or `@import`, every link a place on the page or GitHub's (the ticket's, a unit's, a pull request's),
# and no other address anywhere in it, a question the team wrote holding markup (a `<script>` element) among the call's
# lines. Env: CHECKS.
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
. "$CHECKS/selftest/fixtures/planner-toy.sh"; . "$CHECKS/selftest/fixtures/plan-page.sh"
fail() { echo "manual-plan-page-offline: $*" >&2; cat "$T/pw" >&2 2>/dev/null; exit 1; }
pp_toy "$T/toy"; pp_scene
printf 'question\t#2:1\tQuestion: <script>x</script>\nmove\tanswer\t#2:1\th-q1\tan answer, or there\n' >> "$T/trig"
pp_write "$T/trig"
[ "$PP_RC" = 0 ] && [ -s "$PG" ] || fail "next-page.sh write made no page ($PP_RC)"
[ "$(find "$(dirname "$PG")" -type f | grep -c .)" = 1 ] || fail "the page is not one file alone: $(find "$(dirname "$PG")" -type f | paste -sd ' ' -)"
for x in '<script' '<link' '<img' '<iframe' '<object' '<embed' 'src=' 'url(' '@import' 'srcset='; do
  grep -qi -- "$x" "$PG" && fail "the page holds $x, something it would load"; done
grep -o 'href="[^"]*"' "$PG" | sed 's/^href="//; s/"$//' > "$T/links"
grep -q '^https://github.com/owner/code/issues/2$' "$T/links" || fail "the page holds no link to the ticket #2"
grep -v -e '^#' -e '^https://github\.com/' "$T/links" > "$T/bad" && fail "a link is neither on the page nor GitHub's: $(head -n 1 "$T/bad")"
grep -oiE '(https?:)?//[A-Za-z0-9.-]+' "$PG" | sed -E 's#^(https?:)?//##' | sort -u > "$T/hosts"
[ "$(paste -sd ' ' - < "$T/hosts")" = github.com ] || fail "the page holds an address but GitHub's: $(grep -vx github.com "$T/hosts" | paste -sd ' ' -)"
exit 0
